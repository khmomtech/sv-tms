package com.svtrucking.logistics.service;

import com.svtrucking.logistics.model.AuditTrail;
import com.svtrucking.logistics.repository.AuditTrailRepository;
import java.time.LocalDateTime;
import java.util.List;
import org.springframework.stereotype.Service;

@Service
public class AuditTrailService {

  private final AuditTrailRepository auditTrailRepository;

  // Allow disabling automatic initialization during special runs (e.g. OpenAPI export)
  @org.springframework.beans.factory.annotation.Value("${app.init-audit:true}")
  private boolean initAudit;

  public AuditTrailService(AuditTrailRepository auditTrailRepository) {
    this.auditTrailRepository = auditTrailRepository;
  }

  // Initialize audit trails after the application is ready to avoid startup-time DB access
  @org.springframework.context.event.EventListener(
      org.springframework.boot.context.event.ApplicationReadyEvent.class)
  public void onApplicationReady() {
    if (initAudit) {
      initializeDefaultAuditTrails();
    }
  }

  private void initializeDefaultAuditTrails() {
    // Initialize with a system startup audit trail if none exist
    if (auditTrailRepository.count() == 0) {
      AuditTrail systemStartup = new AuditTrail();
      systemStartup.setAction("SYSTEM_STARTUP");
      systemStartup.setTimestamp(LocalDateTime.now());
      systemStartup.setDetails("Application started");
      auditTrailRepository.save(systemStartup);
    }
  }

  public List<AuditTrail> getAllAuditTrails() {
    return auditTrailRepository.findAll();
  }

  public List<AuditTrail> getAuditTrailsByUser(Long userId) {
    return auditTrailRepository.findByUserIdOrderByTimestampDesc(userId);
  }

  public List<AuditTrail> getAuditTrailsByUsername(String username) {
    return auditTrailRepository.findByUsernameOrderByTimestampDesc(username);
  }

  public List<AuditTrail> getAuditTrailsByAction(String action) {
    return auditTrailRepository.findByActionOrderByTimestampDesc(action);
  }

  public List<AuditTrail> getAuditTrailsByResourceType(String resourceType) {
    return auditTrailRepository.findByResourceTypeOrderByTimestampDesc(resourceType);
  }

  public List<AuditTrail> getAuditTrailsByDateRange(
      LocalDateTime startDate, LocalDateTime endDate) {
    return auditTrailRepository.findByTimestampBetweenOrderByTimestampDesc(startDate, endDate);
  }

  public List<AuditTrail> getAuditTrailsByUsernameAndAction(String username, String action) {
    return auditTrailRepository.findByUsernameAndActionOrderByTimestampDesc(username, action);
  }

  public AuditTrail createAuditTrail(AuditTrail auditTrail) {
    auditTrail.setTimestamp(LocalDateTime.now());
    return auditTrailRepository.save(auditTrail);
  }

  public AuditTrail createAuditTrail(
      Long userId,
      String username,
      String action,
      String resourceType,
      Long resourceId,
      String resourceName,
      String details,
      String ipAddress,
      String userAgent) {
    AuditTrail auditTrail = new AuditTrail();
    auditTrail.setUserId(userId);
    auditTrail.setUsername(username);
    auditTrail.setAction(action);
    auditTrail.setResourceType(resourceType);
    auditTrail.setResourceId(resourceId);
    auditTrail.setResourceName(resourceName);
    auditTrail.setDetails(details);
    auditTrail.setIpAddress(ipAddress);
    auditTrail.setUserAgent(userAgent);
    auditTrail.setTimestamp(LocalDateTime.now());

    return auditTrailRepository.save(auditTrail);
  }

  public void deleteAuditTrail(Long id) {
    auditTrailRepository.deleteById(id);
  }

  public void deleteAuditTrailsByUser(Long userId) {
    List<AuditTrail> userAuditTrails =
        auditTrailRepository.findByUserIdOrderByTimestampDesc(userId);
    auditTrailRepository.deleteAll(userAuditTrails);
  }
}
