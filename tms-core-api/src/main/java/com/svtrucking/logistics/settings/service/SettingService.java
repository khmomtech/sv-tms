package com.svtrucking.logistics.settings.service;

import com.svtrucking.logistics.settings.dto.SettingReadResponse;
import com.svtrucking.logistics.settings.dto.SettingWriteRequest;
import com.svtrucking.logistics.settings.entity.SettingAudit;
import com.svtrucking.logistics.settings.entity.SettingDef;
import com.svtrucking.logistics.settings.entity.SettingValue;
import com.svtrucking.logistics.settings.enums.SettingScope;
import com.svtrucking.logistics.settings.enums.SettingType;
import com.svtrucking.logistics.settings.event.SettingChangedEvent;
import com.svtrucking.logistics.settings.repository.SettingAuditRepository;
import com.svtrucking.logistics.settings.repository.SettingDefRepository;
import com.svtrucking.logistics.settings.repository.SettingValueRepository;
import java.time.Instant;
import java.util.ArrayList;
import java.util.List;
import java.util.NoSuchElementException;
import java.util.Optional;
import org.springframework.cache.annotation.CacheEvict;
import org.springframework.cache.annotation.Cacheable;
import org.springframework.context.ApplicationEventPublisher;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
public class SettingService {

  private final SettingDefRepository defRepo;
  private final SettingValueRepository valRepo;
  private final SettingAuditRepository auditRepo;
  private final SettingCrypto crypto;
  private final DriverAppPolicyGuard driverAppPolicyGuard;
  private final ApplicationEventPublisher publisher;

  public SettingService(
      SettingDefRepository defRepo,
      SettingValueRepository valRepo,
      SettingAuditRepository auditRepo,
      SettingCrypto crypto,
      DriverAppPolicyGuard driverAppPolicyGuard,
      ApplicationEventPublisher publisher) {
    this.defRepo = defRepo;
    this.valRepo = valRepo;
    this.auditRepo = auditRepo;
    this.crypto = crypto;
    this.driverAppPolicyGuard = driverAppPolicyGuard;
    this.publisher = publisher;
  }

  // ---------- READ ----------

  @Transactional(readOnly = true)
  @Cacheable(
      value = "settings",
      key =
          "#groupCode + '|' + #keyCode + '|' + #scope + '|' + (#scopeRef == null ? '' : #scopeRef)")
  public Object getValue(String groupCode, String keyCode, String scope, String scopeRef) {
    SettingDef def =
        defRepo
            .findByGroupCodeAndKeyCode(groupCode, keyCode)
            .orElseThrow(
                () ->
                    new NoSuchElementException("Setting not found: " + groupCode + "." + keyCode));

    SettingScope s = parseScope(scope);
    Optional<SettingValue> latest =
        valRepo.findTopByDef_IdAndScopeAndScopeRefOrderByVersionDesc(def.getId(), s, scopeRef);

    String stored = latest.map(SettingValue::getValueText).orElse(def.getDefaultValue());
    if (stored == null) return null;

    String plain = def.getType() == SettingType.PASSWORD ? crypto.decrypt(stored) : stored;
    return SettingTypeCoercion.coerceForRead(def, plain);
  }

  // ---------- WRITE ----------

  @Transactional
  @CacheEvict(value = "settings", allEntries = true)
  public SettingReadResponse upsert(SettingWriteRequest req, String actor) {
    if (req.reason() == null || req.reason().isBlank()) {
      throw new IllegalArgumentException("Reason is required for audit");
    }

    SettingDef def =
        defRepo
            .findByGroupCodeAndKeyCode(req.groupCode(), req.keyCode())
            .orElseThrow(
                () ->
                    new NoSuchElementException(
                        "Setting not found: " + req.groupCode() + "." + req.keyCode()));

    // validate + serialize
    SettingTypeCoercion.validate(def, req.value());
    driverAppPolicyGuard.validate(def, req.value());
    String serialized = SettingTypeCoercion.serialize(def, req.value());
    String toStore =
        def.getType() == SettingType.PASSWORD ? crypto.encrypt(serialized) : serialized;

    SettingScope s = parseScope(req.scope());
    Optional<SettingValue> last =
        valRepo.findTopByDef_IdAndScopeAndScopeRefOrderByVersionDesc(
            def.getId(), s, req.scopeRef());
    int nextVer = last.map(v -> v.getVersion() + 1).orElse(1);

    Instant now = Instant.now();

    // save value
    SettingValue sv =
        SettingValue.builder()
            .def(def)
            .scope(s)
            .scopeRef(req.scopeRef())
            .valueText(toStore)
            .version(nextVer)
            .updatedBy(actor)
            .updatedAt(now)
            .build();
    valRepo.save(sv);

    // audit
    SettingAudit audit =
        SettingAudit.builder()
            .def(def)
            .scope(s)
            .scopeRef(req.scopeRef())
            .oldValue(last.map(SettingValue::getValueText).orElse(null))
            .newValue(toStore)
            .updatedBy(actor)
            .updatedAt(now)
            .reason(req.reason())
            .build();
    auditRepo.save(audit);

    // publish event
    publisher.publishEvent(
        new SettingChangedEvent(this, req.groupCode(), req.keyCode(), s.name(), req.scopeRef()));

    Object valueOut =
        def.getType() == SettingType.PASSWORD
            ? "*****MASKED*****"
            : SettingTypeCoercion.coerceForRead(def, serialized);

    return new SettingReadResponse(
        def.getGroup().getCode(),
        def.getKeyCode(),
        def.getType().name(),
        valueOut,
        s.name(),
        req.scopeRef(),
        nextVer,
        actor,
        sv.getUpdatedAt().toString());
  }

  // ---------- LIST GROUP ----------

  @Transactional(readOnly = true)
  public List<SettingReadResponse> listGroupValues(
      String groupCode, String scope, String scopeRef, boolean includeSecrets) {
    var defs =
        defRepo.findAll().stream().filter(d -> d.getGroup().getCode().equals(groupCode)).toList();

    List<SettingReadResponse> out = new ArrayList<>();
    SettingScope s = parseScope(scope);

    for (SettingDef def : defs) {
      Optional<SettingValue> latest =
          valRepo.findTopByDef_IdAndScopeAndScopeRefOrderByVersionDesc(def.getId(), s, scopeRef);

      String stored = latest.map(SettingValue::getValueText).orElse(def.getDefaultValue());
      String plain =
          (def.getType() == SettingType.PASSWORD && stored != null)
              ? (includeSecrets ? crypto.decrypt(stored) : null)
              : stored;

      Object value =
          (def.getType() == SettingType.PASSWORD && !includeSecrets)
              ? "*****MASKED*****"
              : SettingTypeCoercion.coerceForRead(def, plain);

      out.add(
          new SettingReadResponse(
              def.getGroup().getCode(),
              def.getKeyCode(),
              def.getType().name(),
              value,
              s.name(),
              scopeRef,
              latest.map(SettingValue::getVersion).orElse(0),
              latest.map(SettingValue::getUpdatedBy).orElse("default"),
              latest.map(v -> v.getUpdatedAt().toString()).orElse(null)));
    }
    return out;
  }

  // ---------- Helpers ----------

  private SettingScope parseScope(String s) {
    if (s == null) return SettingScope.GLOBAL;
    return SettingScope.valueOf(s.toUpperCase());
  }

  private String currentUsername() {
    Authentication a = SecurityContextHolder.getContext().getAuthentication();
    return a != null ? a.getName() : "system";
  }
}
