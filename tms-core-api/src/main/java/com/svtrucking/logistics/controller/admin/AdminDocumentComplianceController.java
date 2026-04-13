package com.svtrucking.logistics.controller.admin;

import com.svtrucking.logistics.core.ApiResponse;
import com.svtrucking.logistics.model.Driver;
import com.svtrucking.logistics.model.DriverDocument;
import com.svtrucking.logistics.repository.DriverDocumentRepository;
import java.time.LocalDate;
import java.time.temporal.ChronoUnit;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

/**
 * Admin endpoints for cross-driver document compliance reporting.
 * Surfaces expiring/expired docs across ALL drivers and categories.
 */
@RestController
@RequestMapping("/api/admin/document-compliance")
@CrossOrigin(origins = "*")
@RequiredArgsConstructor
@Slf4j
public class AdminDocumentComplianceController {

  private final DriverDocumentRepository driverDocumentRepository;

  // ─── DTOs ────────────────────────────────────────────────────────────────────

  public record ExpiringDocumentDto(
      Long documentId,
      Long driverId,
      String driverName,
      String driverPhone,
      String documentName,
      String category,
      String expiryDate,
      Long daysUntilExpiry,
      String status,
      boolean isRequired) {
  }

  public record ComplianceSummaryDto(
      long totalDocuments,
      long expired,
      long expiringSoon30Days,
      long active,
      double overallCompliancePct) {
  }

  // ─── Endpoints ───────────────────────────────────────────────────────────────

  /**
   * All documents expiring within {@code days} days across all drivers +
   * categories.
   * GET /api/admin/document-compliance/expiring?days=30
   */
  @GetMapping("/expiring")
  @PreAuthorize("hasAnyAuthority('ROLE_ADMIN','ROLE_SUPERADMIN','ROLE_SAFETY','all_functions')")
  public ResponseEntity<ApiResponse<Page<ExpiringDocumentDto>>> expiring(
      @RequestParam(defaultValue = "30") int days,
      Pageable pageable) {

    LocalDate today = LocalDate.now();
    LocalDate horizon = today.plusDays(days);

    Page<ExpiringDocumentDto> result = driverDocumentRepository
        .findAllExpiring(today, horizon, pageable)
        .map(this::toDto);
    return ResponseEntity.ok(new ApiResponse<>(true, "Expiring documents", result));
  }

  /**
   * All expired documents across all drivers + categories.
   * GET /api/admin/document-compliance/expired
   */
  @GetMapping("/expired")
  @PreAuthorize("hasAnyAuthority('ROLE_ADMIN','ROLE_SUPERADMIN','ROLE_SAFETY','all_functions')")
  public ResponseEntity<ApiResponse<Page<ExpiringDocumentDto>>> expired(Pageable pageable) {

    Page<ExpiringDocumentDto> result = driverDocumentRepository
        .findAllExpired(LocalDate.now(), pageable)
        .map(this::toDto);
    return ResponseEntity.ok(new ApiResponse<>(true, "Expired documents", result));
  }

  /**
   * Overall compliance summary.
   * GET /api/admin/document-compliance/summary
   */
  @GetMapping("/summary")
  @PreAuthorize("hasAnyAuthority('ROLE_ADMIN','ROLE_SUPERADMIN','ROLE_SAFETY','all_functions')")
  public ResponseEntity<ApiResponse<ComplianceSummaryDto>> summary() {

    LocalDate today = LocalDate.now();
    LocalDate soonHorizon = today.plusDays(30);

    long total = driverDocumentRepository.count();
    long expired = driverDocumentRepository.countAllExpired(today);
    long expiringSoon = driverDocumentRepository.countAllExpiring(today, soonHorizon);
    long active = Math.max(0, total - expired - expiringSoon);
    double compliancePct = total == 0 ? 100.0 : Math.round((double) active / total * 1000.0) / 10.0;

    return ResponseEntity.ok(new ApiResponse<>(true, "Compliance summary",
        new ComplianceSummaryDto(total, expired, expiringSoon, active, compliancePct)));
  }

  // ─── Helpers ─────────────────────────────────────────────────────────────────

  private ExpiringDocumentDto toDto(DriverDocument doc) {
    Driver driver = doc.getDriver();
    String driverName = resolveDriverName(driver);
    LocalDate expiry = doc.getExpiryDate();
    LocalDate today = LocalDate.now();
    Long days = expiry != null ? ChronoUnit.DAYS.between(today, expiry) : null;
    String status = resolveStatus(expiry, today);

    return new ExpiringDocumentDto(
        doc.getId(),
        driver != null ? driver.getId() : null,
        driverName,
        driver != null ? driver.getPhone() : null,
        doc.getName(),
        doc.getCategory(),
        expiry != null ? expiry.toString() : null,
        days,
        status,
        Boolean.TRUE.equals(doc.getIsRequired()));
  }

  private String resolveDriverName(Driver driver) {
    if (driver == null)
      return null;
    String first = driver.getFirstName() != null ? driver.getFirstName().trim() : "";
    String last = driver.getLastName() != null ? driver.getLastName().trim() : "";
    String full = (first + " " + last).trim();
    return full.isEmpty() ? driver.getPhone() : full;
  }

  private String resolveStatus(LocalDate expiry, LocalDate today) {
    if (expiry == null)
      return "ACTIVE";
    if (expiry.isBefore(today))
      return "EXPIRED";
    if (!expiry.isAfter(today.plusDays(30)))
      return "EXPIRING_SOON";
    return "ACTIVE";
  }
}
