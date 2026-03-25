package com.svtrucking.logistics.controller;

import com.svtrucking.logistics.core.ApiResponse;
import com.svtrucking.logistics.model.PartnerAdmin;
import com.svtrucking.logistics.service.PartnerAdminService;
import com.svtrucking.logistics.security.PermissionNames;
import java.util.List;
import lombok.Data;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

/**
 * REST API for managing partner admin assignments
 */
@RestController
@RequestMapping("/api/partner-admins")
@RequiredArgsConstructor
public class PartnerAdminController {

  private final PartnerAdminService partnerAdminService;
  @GetMapping("/company/{companyId}")
  @PreAuthorize("@authorizationService.hasPermission('" + PermissionNames.PARTNER_READ + "')")
  public ResponseEntity<ApiResponse<List<PartnerAdmin>>> getAdminsByCompany(
      @PathVariable Long companyId) {
    List<PartnerAdmin> admins = partnerAdminService.getAdminsByCompany(companyId);
    return ResponseEntity.ok(new ApiResponse<>(true, "Partner admins retrieved successfully", admins));
  }

  @GetMapping("/user/{userId}")
  @PreAuthorize("@authorizationService.hasPermission('" + PermissionNames.PARTNER_READ + "')")
  public ResponseEntity<ApiResponse<List<PartnerAdmin>>> getCompaniesByUser(
      @PathVariable Long userId) {
    List<PartnerAdmin> companies = partnerAdminService.getCompaniesByUser(userId);
    return ResponseEntity.ok(new ApiResponse<>(true, "Partner companies retrieved successfully", companies));
  }

  @GetMapping("/company/{companyId}/primary")
  @PreAuthorize("@authorizationService.hasPermission('" + PermissionNames.PARTNER_READ + "')")
  public ResponseEntity<ApiResponse<PartnerAdmin>> getPrimaryAdmin(@PathVariable Long companyId) {
    PartnerAdmin primary = partnerAdminService.getPrimaryAdmin(companyId);
    return ResponseEntity.ok(new ApiResponse<>(true, "Primary admin retrieved successfully", primary));
  }

  @PostMapping
  @PreAuthorize("@authorizationService.hasPermission('" + PermissionNames.PARTNER_CREATE + "')")
  public ResponseEntity<ApiResponse<PartnerAdmin>> assignAdmin(
      @RequestBody AssignAdminRequest request) {
    PartnerAdmin admin =
        partnerAdminService.assignAdminToCompany(
            request.getUserId(), request.getCompanyId(), request.getIsPrimary(), "system");
    return ResponseEntity.status(HttpStatus.CREATED)
        .body(new ApiResponse<>(true, "Admin assigned to company successfully", admin));
  }

  @PatchMapping("/{adminId}/permissions")
  @PreAuthorize("@authorizationService.hasPermission('" + PermissionNames.PARTNER_UPDATE + "')")
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
  @PreAuthorize("@authorizationService.hasPermission('" + PermissionNames.PARTNER_DELETE + "')")
  public ResponseEntity<ApiResponse<Void>> removeAdmin(@PathVariable Long adminId) {
    partnerAdminService.removeAdminFromCompany(adminId);
    return ResponseEntity.ok(new ApiResponse<>(true, "Admin removed successfully"));
  }

  @GetMapping("/user/{userId}/companies/{companyId}/can-manage-drivers")
  @PreAuthorize("@authorizationService.hasPermission('" + PermissionNames.PARTNER_READ + "')")
  public ResponseEntity<ApiResponse<Boolean>> canManageDrivers(
      @PathVariable Long userId, @PathVariable Long companyId) {
    boolean can = partnerAdminService.canManageDrivers(userId, companyId);
    return ResponseEntity.ok(new ApiResponse<>(true, "Permission checked", can));
  }

  @GetMapping("/user/{userId}/managed-companies")
  @PreAuthorize("@authorizationService.hasPermission('" + PermissionNames.PARTNER_READ + "')")
  public ResponseEntity<ApiResponse<List<Long>>> getManagedCompanies(@PathVariable Long userId) {
    List<Long> companyIds = partnerAdminService.getManagedCompanyIds(userId);
    return ResponseEntity.ok(new ApiResponse<>(true, "Managed companies retrieved", companyIds));
  }

  // DTO classes
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
