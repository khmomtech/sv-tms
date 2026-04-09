package com.svtrucking.logistics.controller;

import com.svtrucking.logistics.core.ApiResponse;
import com.svtrucking.logistics.model.PartnerAdmin;
import com.svtrucking.logistics.service.PartnerAdminService;
import java.util.List;
import lombok.Data;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

/**
 * Alias controller for vendor admins (formerly partner admins).
 * Exposes /api/vendor-admins while delegating to PartnerAdminService for now.
 */
@RestController
@RequestMapping("/api/vendor-admins")
@RequiredArgsConstructor
public class VendorAdminController {

  private final PartnerAdminService partnerAdminService;

  @GetMapping("/company/{companyId}")
  @PreAuthorize("hasAnyRole('SUPERADMIN', 'ADMIN', 'PARTNER_ADMIN')")
  public ResponseEntity<ApiResponse<List<PartnerAdmin>>> getAdminsByCompany(
      @PathVariable Long companyId) {
    List<PartnerAdmin> admins = partnerAdminService.getAdminsByCompany(companyId);
    return ResponseEntity.ok(new ApiResponse<>(true, "Vendor admins retrieved successfully", admins));
  }

  @GetMapping("/user/{userId}")
  @PreAuthorize("hasAnyRole('SUPERADMIN', 'ADMIN', 'PARTNER_ADMIN')")
  public ResponseEntity<ApiResponse<List<PartnerAdmin>>> getCompaniesByUser(
      @PathVariable Long userId) {
    List<PartnerAdmin> companies = partnerAdminService.getCompaniesByUser(userId);
    return ResponseEntity.ok(new ApiResponse<>(true, "Vendor companies retrieved successfully", companies));
  }

  @GetMapping("/company/{companyId}/primary")
  @PreAuthorize("hasAnyRole('SUPERADMIN', 'ADMIN', 'PARTNER_ADMIN')")
  public ResponseEntity<ApiResponse<PartnerAdmin>> getPrimaryAdmin(@PathVariable Long companyId) {
    PartnerAdmin primary = partnerAdminService.getPrimaryAdmin(companyId);
    return ResponseEntity.ok(new ApiResponse<>(true, "Primary admin retrieved successfully", primary));
  }

  @PostMapping
  @PreAuthorize("hasAnyRole('SUPERADMIN', 'ADMIN')")
  public ResponseEntity<ApiResponse<PartnerAdmin>> assignAdmin(
      @RequestBody AssignAdminRequest request) {
    PartnerAdmin admin =
        partnerAdminService.assignAdminToCompany(
            request.getUserId(), request.getCompanyId(), request.getIsPrimary(), "system");
    return ResponseEntity.status(HttpStatus.CREATED)
        .body(new ApiResponse<>(true, "Admin assigned to vendor company successfully", admin));
  }

  @PatchMapping("/{adminId}/permissions")
  @PreAuthorize("hasAnyRole('SUPERADMIN', 'ADMIN')")
  public ResponseEntity<ApiResponse<PartnerAdmin>> updatePermissions(
      @PathVariable Long adminId, @RequestBody UpdatePermissionsRequest request) {
    PartnerAdmin updated =
        partnerAdminService.updatePermissions(
            adminId,
            request.getCanManageDrivers(),
            request.getCanManageCustomers(),
            request.getCanViewReports(),
            request.getCanManageSettings(),
            request.getIsPrimary());
    return ResponseEntity.ok(new ApiResponse<>(true, "Permissions updated successfully", updated));
  }

  @DeleteMapping("/{adminId}")
  @PreAuthorize("hasAnyRole('SUPERADMIN', 'ADMIN')")
  public ResponseEntity<ApiResponse<Void>> removeAdmin(@PathVariable Long adminId) {
    partnerAdminService.removeAdminFromCompany(adminId);
    return ResponseEntity.ok(new ApiResponse<>(true, "Admin removed successfully"));
  }

  @GetMapping("/user/{userId}/companies/{companyId}/can-manage-drivers")
  @PreAuthorize("hasAnyRole('SUPERADMIN', 'ADMIN', 'PARTNER_ADMIN')")
  public ResponseEntity<ApiResponse<Boolean>> canManageDrivers(
      @PathVariable Long userId, @PathVariable Long companyId) {
    boolean can = partnerAdminService.canManageDrivers(userId, companyId);
    return ResponseEntity.ok(new ApiResponse<>(true, "Permission checked", can));
  }

  @GetMapping("/user/{userId}/managed-companies")
  @PreAuthorize("hasAnyRole('SUPERADMIN', 'ADMIN', 'PARTNER_ADMIN')")
  public ResponseEntity<ApiResponse<List<Long>>> getManagedCompanies(@PathVariable Long userId) {
    List<Long> companyIds = partnerAdminService.getManagedCompanyIds(userId);
    return ResponseEntity.ok(new ApiResponse<>(true, "Managed companies retrieved", companyIds));
  }

  // DTO classes (duplicated for clarity; can be extracted if needed)
  @Data
  public static class AssignAdminRequest {
    private Long userId;
    private Long companyId;
    private Boolean isPrimary;
  }

  @Data
  public static class UpdatePermissionsRequest {
    private Boolean canManageDrivers;
    private Boolean canManageCustomers;
    private Boolean canViewReports;
    private Boolean canManageSettings;
    private Boolean isPrimary;
  }
}
