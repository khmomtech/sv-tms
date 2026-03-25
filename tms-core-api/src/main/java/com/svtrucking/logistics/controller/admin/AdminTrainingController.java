package com.svtrucking.logistics.controller.admin;

import com.svtrucking.logistics.core.ApiResponse;
import com.svtrucking.logistics.model.DriverDocument;
import com.svtrucking.logistics.model.Driver;
import com.svtrucking.logistics.repository.DriverDocumentRepository;
import java.time.LocalDate;
import java.time.temporal.ChronoUnit;
import java.util.List;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Sort;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

/**
 * Admin read-only endpoints for driver training records.
 * Training records are driver documents with category = 'training'.
 * No new DB entity is introduced — this controller surfaces the existing
 * DriverDocument data in a training-specific, analytics-friendly shape.
 */
@RestController
@RequestMapping("/api/admin/training-records")
@CrossOrigin(origins = "*")
@RequiredArgsConstructor
@Slf4j
public class AdminTrainingController {

  private static final String TRAINING_CATEGORY = "training";

  private final DriverDocumentRepository driverDocumentRepository;

  // ─── DTOs ────────────────────────────────────────────────────────────────────

  /**
   * Flat projection of a training record enriched with computed expiry status.
   */
  public record TrainingRecordDto(
      Long id,
      Long driverId,
      String driverName,
      String driverPhone,
      String trainingName,
      String description,
      String expiryDate,
      Long daysUntilExpiry,
      String status, // ACTIVE | EXPIRING_SOON | EXPIRED
      boolean isRequired,
      String createdAt,
      String updatedAt) {
  }

  public record TrainingSummaryDto(
      long total,
      long active,
      long expiringSoon,
      long expired,
      double compliancePercent) {
  }

  // ─── Endpoints ───────────────────────────────────────────────────────────────

  /**
   * Paginated list of all training records, with optional search.
   * GET /api/admin/training-records?search=&page=0&size=20
   */
  @GetMapping
  @PreAuthorize("hasAnyAuthority('ROLE_ADMIN','ROLE_SUPERADMIN','ROLE_SAFETY','all_functions')")
  public ResponseEntity<ApiResponse<Page<TrainingRecordDto>>> list(
      @RequestParam(required = false, defaultValue = "") String search,
      @RequestParam(defaultValue = "0") int page,
      @RequestParam(defaultValue = "20") int size) {

    log.info("GET /api/admin/training-records search='{}' page={} size={}", search, page, size);

    var pageable = PageRequest.of(page, size, Sort.by("expiryDate").ascending());
    Page<DriverDocument> docs = driverDocumentRepository.searchByCategory(
        TRAINING_CATEGORY, search.isBlank() ? null : search, pageable);

    Page<TrainingRecordDto> result = docs.map(this::toDto);
    return ResponseEntity.ok(new ApiResponse<>(true, "Training records", result));
  }

  /**
   * Training records expiring within {@code days} days (default 30).
   * GET /api/admin/training-records/expiring?days=30
   */
  @GetMapping("/expiring")
  @PreAuthorize("hasAnyAuthority('ROLE_ADMIN','ROLE_SUPERADMIN','ROLE_SAFETY','all_functions')")
  public ResponseEntity<ApiResponse<List<TrainingRecordDto>>> expiring(
      @RequestParam(defaultValue = "30") int days) {

    LocalDate today = LocalDate.now();
    LocalDate horizon = today.plusDays(days);

    List<DriverDocument> docs = driverDocumentRepository
        .findExpiringByCategory(TRAINING_CATEGORY, today, horizon);

    List<TrainingRecordDto> result = docs.stream().map(this::toDto).toList();
    return ResponseEntity.ok(new ApiResponse<>(true, "Expiring training records", result));
  }

  /**
   * Aggregate summary: total, active, expiring-soon, expired, compliance %.
   * GET /api/admin/training-records/summary
   */
  @GetMapping("/summary")
  @PreAuthorize("hasAnyAuthority('ROLE_ADMIN','ROLE_SUPERADMIN','ROLE_SAFETY','all_functions')")
  public ResponseEntity<ApiResponse<TrainingSummaryDto>> summary() {

    LocalDate today = LocalDate.now();
    LocalDate soonHorizon = today.plusDays(30);

    long total = driverDocumentRepository.countByCategory(TRAINING_CATEGORY);
    long expired = driverDocumentRepository.countExpiredByCategory(TRAINING_CATEGORY, today);
    long expiringSoon = driverDocumentRepository.countExpiringByCategory(TRAINING_CATEGORY, today, soonHorizon);
    long active = total - expired - expiringSoon;
    if (active < 0)
      active = 0;

    double compliancePct = total == 0 ? 100.0 : Math.round((double) active / total * 1000.0) / 10.0;

    TrainingSummaryDto dto = new TrainingSummaryDto(
        total, active, expiringSoon, expired, compliancePct);

    return ResponseEntity.ok(new ApiResponse<>(true, "Training summary", dto));
  }

  // ─── Helpers ─────────────────────────────────────────────────────────────────

  private TrainingRecordDto toDto(DriverDocument doc) {
    Driver driver = doc.getDriver();
    String driverName = resolveDriverName(driver);
    String driverPhone = driver != null ? driver.getPhone() : null;

    LocalDate expiry = doc.getExpiryDate();
    LocalDate today = LocalDate.now();
    Long daysUntilExpiry = expiry != null ? ChronoUnit.DAYS.between(today, expiry) : null;
    String status = resolveStatus(expiry, today);

    return new TrainingRecordDto(
        doc.getId(),
        driver != null ? driver.getId() : null,
        driverName,
        driverPhone,
        doc.getName(),
        doc.getDescription(),
        expiry != null ? expiry.toString() : null,
        daysUntilExpiry,
        status,
        Boolean.TRUE.equals(doc.getIsRequired()),
        doc.getCreatedAt() != null ? doc.getCreatedAt().toString() : null,
        doc.getUpdatedAt() != null ? doc.getUpdatedAt().toString() : null);
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
