package com.svtrucking.logistics.controller;

import com.svtrucking.logistics.model.AuditTrail;
import com.svtrucking.logistics.service.AuditTrailService;
import java.time.LocalDateTime;
import java.util.List;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/admin/audit-trails")
@CrossOrigin(origins = "*")
public class AuditTrailController {

  private final AuditTrailService auditTrailService;

  public AuditTrailController(AuditTrailService auditTrailService) {
    this.auditTrailService = auditTrailService;
  }

  @GetMapping
  @PreAuthorize("@authorizationService.hasPermission('audit:read')")
  public ResponseEntity<List<AuditTrail>> getAllAuditTrails() {
    List<AuditTrail> auditTrails = auditTrailService.getAllAuditTrails();
    return ResponseEntity.ok(auditTrails);
  }

  @GetMapping("/user/{userId}")
  @PreAuthorize("@authorizationService.hasPermission('audit:read')")
  public ResponseEntity<List<AuditTrail>> getAuditTrailsByUser(@PathVariable Long userId) {
    List<AuditTrail> auditTrails = auditTrailService.getAuditTrailsByUser(userId);
    return ResponseEntity.ok(auditTrails);
  }

  @GetMapping("/username/{username}")
  @PreAuthorize("@authorizationService.hasPermission('audit:read')")
  public ResponseEntity<List<AuditTrail>> getAuditTrailsByUsername(@PathVariable String username) {
    List<AuditTrail> auditTrails = auditTrailService.getAuditTrailsByUsername(username);
    return ResponseEntity.ok(auditTrails);
  }

  @GetMapping("/action/{action}")
  @PreAuthorize("@authorizationService.hasPermission('audit:read')")
  public ResponseEntity<List<AuditTrail>> getAuditTrailsByAction(@PathVariable String action) {
    List<AuditTrail> auditTrails = auditTrailService.getAuditTrailsByAction(action);
    return ResponseEntity.ok(auditTrails);
  }

  @GetMapping("/resource/{resourceType}")
  @PreAuthorize("@authorizationService.hasPermission('audit:read')")
  public ResponseEntity<List<AuditTrail>> getAuditTrailsByResourceType(
      @PathVariable String resourceType) {
    List<AuditTrail> auditTrails = auditTrailService.getAuditTrailsByResourceType(resourceType);
    return ResponseEntity.ok(auditTrails);
  }

  @GetMapping("/date-range")
  @PreAuthorize("@authorizationService.hasPermission('audit:read')")
  public ResponseEntity<List<AuditTrail>> getAuditTrailsByDateRange(
      @RequestParam("startDate") String startDate, @RequestParam("endDate") String endDate) {
    LocalDateTime start = LocalDateTime.parse(startDate);
    LocalDateTime end = LocalDateTime.parse(endDate);
    List<AuditTrail> auditTrails = auditTrailService.getAuditTrailsByDateRange(start, end);
    return ResponseEntity.ok(auditTrails);
  }

  @GetMapping("/user/{username}/action/{action}")
  @PreAuthorize("@authorizationService.hasPermission('audit:read')")
  public ResponseEntity<List<AuditTrail>> getAuditTrailsByUsernameAndAction(
      @PathVariable String username, @PathVariable String action) {
    List<AuditTrail> auditTrails =
        auditTrailService.getAuditTrailsByUsernameAndAction(username, action);
    return ResponseEntity.ok(auditTrails);
  }

  @PostMapping
  @PreAuthorize("@authorizationService.hasPermission('audit:create')")
  public ResponseEntity<AuditTrail> createAuditTrail(@RequestBody AuditTrail auditTrail) {
    AuditTrail createdAuditTrail = auditTrailService.createAuditTrail(auditTrail);
    return ResponseEntity.ok(createdAuditTrail);
  }

  @DeleteMapping("/{id}")
  @PreAuthorize("@authorizationService.hasPermission('audit:delete')")
  public ResponseEntity<Void> deleteAuditTrail(@PathVariable Long id) {
    auditTrailService.deleteAuditTrail(id);
    return ResponseEntity.ok().build();
  }
}
