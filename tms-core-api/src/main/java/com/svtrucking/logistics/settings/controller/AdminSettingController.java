package com.svtrucking.logistics.settings.controller;

import com.svtrucking.logistics.settings.dto.SettingBulkWriteRequest;
import com.svtrucking.logistics.settings.dto.SettingReadResponse;
import com.svtrucking.logistics.settings.dto.SettingWriteRequest;
import com.svtrucking.logistics.settings.entity.SettingAudit;
import com.svtrucking.logistics.settings.repository.SettingAuditRepository;
import com.svtrucking.logistics.settings.service.SettingImportExportService;
import com.svtrucking.logistics.settings.service.SettingService;
import java.util.List;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/admin/settings")
public class AdminSettingController {

  private final SettingService settingService;
  private final SettingImportExportService importExportService;
  private final SettingAuditRepository auditRepository;

  public AdminSettingController(
      SettingService settingService,
      SettingImportExportService importExportService,
      SettingAuditRepository auditRepository) {
    this.settingService = settingService;
    this.importExportService = importExportService;
    this.auditRepository = auditRepository;
  }

  // ---------- READ ONE ----------
  @GetMapping("/value")
  @PreAuthorize("hasAnyRole('ADMIN','SUPER_ADMIN','SYSTEM_ADMIN','OPS_MANAGER')")
  public Object getValue(
      @RequestParam String groupCode,
      @RequestParam String keyCode,
      @RequestParam(defaultValue = "GLOBAL") String scope,
      @RequestParam(required = false) String scopeRef) {
    return settingService.getValue(groupCode, keyCode, scope, scopeRef);
  }

  // ---------- LIST GROUP ----------
  @GetMapping("/values")
  @PreAuthorize("hasAnyRole('ADMIN','SUPER_ADMIN','SYSTEM_ADMIN','OPS_MANAGER')")
  public List<SettingReadResponse> listValues(
      @RequestParam String groupCode,
      @RequestParam(defaultValue = "GLOBAL") String scope,
      @RequestParam(required = false) String scopeRef,
      @RequestParam(defaultValue = "false") boolean includeSecrets) {
    return settingService.listGroupValues(groupCode, scope, scopeRef, includeSecrets);
  }

  // ---------- UPSERT ONE ----------
  @PostMapping("/value")
  @PreAuthorize("hasAnyRole('ADMIN','SUPER_ADMIN','SYSTEM_ADMIN','OPS_MANAGER')")
  public SettingReadResponse upsert(@RequestBody SettingWriteRequest req) {
    return settingService.upsert(req, currentUsername());
  }

  // ---------- BULK UPSERT ----------
  @PostMapping("/bulk")
  @PreAuthorize("hasAnyRole('ADMIN','SUPER_ADMIN','SYSTEM_ADMIN','OPS_MANAGER')")
  public List<SettingReadResponse> bulk(@RequestBody SettingBulkWriteRequest req) {
    if (req.dryRun()) {
      // Dry-run: return echo of requests as placeholders; real app could also validate each
      return req.items().stream()
          .map(
              i ->
                  new SettingReadResponse(
                      i.groupCode(),
                      i.keyCode(),
                      null,
                      null,
                      i.scope(),
                      i.scopeRef(),
                      null,
                      null,
                      null))
          .toList();
    }
    String actor = currentUsername();
    return req.items().stream().map(i -> settingService.upsert(i, actor)).toList();
  }

  // ---------- AUDIT LOG ----------
  /**
   * Returns a paged audit log of all setting changes, optionally filtered by group/key.
   * Matches the call made by Angular {@code SettingsService.audit()}.
   */
  @GetMapping("/audit")
  @PreAuthorize("hasAnyRole('ADMIN','SUPER_ADMIN','SYSTEM_ADMIN','OPS_MANAGER')")
  public Page<SettingAudit> audit(
      @RequestParam(required = false) String groupCode,
      @RequestParam(required = false) String keyCode,
      @RequestParam(defaultValue = "0")  int page,
      @RequestParam(defaultValue = "20") int size) {
    PageRequest pr = PageRequest.of(Math.max(page, 0), Math.min(Math.max(size, 1), 100));
    if (groupCode != null && !groupCode.isBlank() && keyCode != null && !keyCode.isBlank()) {
      return auditRepository.findByGroupAndKey(groupCode.trim(), keyCode.trim(), pr);
    }
    if (groupCode != null && !groupCode.isBlank()) {
      return auditRepository.findByGroupCode(groupCode.trim(), pr);
    }
    return auditRepository.findAllByOrderByUpdatedAtDesc(pr);
  }

  // ---------- IMPORT (JSON) ----------
  // Send raw JSON bytes (Content-Type: application/octet-stream)
  // Body example:
  // {
  //   "system.core": {"appName": "SV TMS"},
  //   "security.auth": {"jwt.expMinutes": 60}
  // }
  @PostMapping(value = "/import", consumes = MediaType.APPLICATION_OCTET_STREAM_VALUE)
  @PreAuthorize("hasRole('SUPER_ADMIN')")
  public ResponseEntity<List<SettingWriteRequest>> importJson(
      @RequestBody byte[] file,
      @RequestParam(defaultValue = "GLOBAL") String scope,
      @RequestParam(required = false) String scopeRef,
      @RequestParam(defaultValue = "false") boolean apply) {
    var items = importExportService.parseFlatJson(file, scope, scopeRef, true);
    if (!apply) return ResponseEntity.ok(items); // dry-run only
    String actor = currentUsername();
    items.forEach(i -> settingService.upsert(i, actor));
    return ResponseEntity.ok(items);
  }

  // ---------- helper ----------
  private String currentUsername() {
    Authentication a = SecurityContextHolder.getContext().getAuthentication();
    return a != null ? a.getName() : "system";
  }
}
