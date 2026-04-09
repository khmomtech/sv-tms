package com.svtrucking.logistics.controller.drivers;

import com.svtrucking.logistics.core.ApiResponse;
import com.svtrucking.logistics.dto.DriverCurrentAssignmentDto;
import com.svtrucking.logistics.dto.DriverDto;
import com.svtrucking.logistics.model.Driver;
import com.svtrucking.logistics.model.DriverDocument;
import com.svtrucking.logistics.repository.DriverDocumentRepository;
import com.svtrucking.logistics.repository.DriverRepository;
import java.time.LocalDate;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

/**
 * Driver self-service endpoints: profile, id-card, and assignment lookup.
 */
@RestController
@RequestMapping("/api/driver")
@CrossOrigin(origins = "*")
@RequiredArgsConstructor
@Slf4j
public class DriverSelfAssignmentController {

  private final DriverRepository driverRepository;
  private final DriverDocumentRepository driverDocumentRepository;

  // ── /me/profile ──────────────────────────────────────────────────────────────

  @GetMapping("/me/profile")
  @PreAuthorize("hasAnyAuthority('ROLE_DRIVER','ROLE_ADMIN','ROLE_SUPERADMIN')")
  public ResponseEntity<ApiResponse<DriverDto>> myProfile(Authentication auth) {
    try {
      Driver driver = resolveFromAuth(auth);
      driver = driverRepository.findByIdWithVehicles(driver.getId())
          .orElseThrow(() -> new RuntimeException("Driver not found"));
      DriverDto dto = DriverDto.fromEntity(driver, false, true);
      if (dto.getLatitude() == null) dto.setLatitude(0.0);
      if (dto.getLongitude() == null) dto.setLongitude(0.0);
      return ResponseEntity.ok(ApiResponse.success("Profile fetched", dto));
    } catch (Exception e) {
      log.error("Failed to fetch self profile for {}: {}", auth.getName(), e.getMessage(), e);
      return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
          .body(new ApiResponse<>(false, "Failed to fetch profile"));
    }
  }

  // ── /me/id-card ───────────────────────────────────────────────────────────────

  @GetMapping("/me/id-card")
  @PreAuthorize("hasAnyAuthority('ROLE_DRIVER','ROLE_ADMIN','ROLE_SUPERADMIN')")
  public ResponseEntity<ApiResponse<Map<String, Object>>> myIdCard(Authentication auth) {
    try {
      Driver driver = resolveFromAuth(auth);

      // Prefer a dedicated id_card or passport document; fall back to driver.idCardExpiry
      List<DriverDocument> idDocs = driverDocumentRepository.findByDriverIdAndCategory(driver.getId(), "id_card");
      if (idDocs.isEmpty()) {
        idDocs = driverDocumentRepository.findByDriverIdAndCategory(driver.getId(), "passport");
      }

      Map<String, Object> data = new LinkedHashMap<>();
      if (!idDocs.isEmpty()) {
        DriverDocument doc = idDocs.get(0);
        data.put("idCardNumber", doc.getLicenseNumber());
        data.put("issuedDate", doc.getIssueDate() != null ? doc.getIssueDate().toString() : null);
        data.put("expiryDate", doc.getExpiryDate() != null ? doc.getExpiryDate().toString() : null);
        data.put("status", resolveIdCardStatus(doc.getExpiryDate()));
      } else {
        // Minimal fallback from Driver entity
        data.put("idCardNumber", null);
        data.put("issuedDate", null);
        LocalDate expiry = driver.getIdCardExpiry();
        data.put("expiryDate", expiry != null ? expiry.toString() : null);
        data.put("status", resolveIdCardStatus(expiry));
      }
      return ResponseEntity.ok(ApiResponse.success("ID card fetched", data));
    } catch (Exception e) {
      log.error("Failed to fetch id-card for {}: {}", auth.getName(), e.getMessage(), e);
      return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
          .body(new ApiResponse<>(false, "Failed to fetch id-card"));
    }
  }

  // ── /current-assignment (JWT) ─────────────────────────────────────────────────

  @GetMapping("/current-assignment")
  @PreAuthorize("hasAnyAuthority('ROLE_DRIVER','ROLE_ADMIN','ROLE_SUPERADMIN')")
  public ResponseEntity<ApiResponse<DriverCurrentAssignmentDto>> currentAssignment(Authentication auth) {
    Driver driver = resolveFromAuth(auth);
    driver = driverRepository.findByIdWithVehicles(driver.getId())
        .orElseThrow(() -> new RuntimeException("Driver not found"));
    var dto = DriverCurrentAssignmentDto.fromDriver(driver);
    return ResponseEntity.ok(ApiResponse.success("Fetched current assignment", dto));
  }

  // ── /{driverId}/current-assignment ───────────────────────────────────────────

  @GetMapping("/{driverId}/current-assignment")
  @PreAuthorize("hasAnyAuthority('ROLE_DRIVER','ROLE_ADMIN','ROLE_SUPERADMIN')")
  public ResponseEntity<ApiResponse<DriverCurrentAssignmentDto>> currentAssignmentById(
      @PathVariable Long driverId) {
    Driver driver = driverRepository.findByIdWithVehicles(driverId)
        .orElseThrow(() -> new RuntimeException("Driver not found: " + driverId));
    var dto = DriverCurrentAssignmentDto.fromDriver(driver);
    return ResponseEntity.ok(ApiResponse.success("Fetched current assignment", dto));
  }

  // ── helpers ───────────────────────────────────────────────────────────────────

  private Driver resolveFromAuth(Authentication auth) {
    return driverRepository.findByUsername(auth.getName())
        .orElseThrow(() -> new RuntimeException("Driver not found for user: " + auth.getName()));
  }

  private String resolveIdCardStatus(LocalDate expiryDate) {
    if (expiryDate == null) return "unknown";
    return LocalDate.now().isAfter(expiryDate) ? "expired" : "valid";
  }
}
