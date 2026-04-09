package com.svtrucking.logistics.controller;

import com.svtrucking.logistics.core.ApiResponse;
import com.svtrucking.logistics.enums.PartnershipType;
import com.svtrucking.logistics.model.PartnerCompany;
import com.svtrucking.logistics.security.PermissionNames;
import com.svtrucking.logistics.service.PartnerCompanyService;
import jakarta.validation.Valid;
import java.util.List;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

/**
 * Backward-compatible alias endpoints for vendors (formerly partners).
 * Maps to the same service layer as PartnerCompanyController while exposing /api/vendors paths.
 */
@RestController
@RequestMapping("/api/vendors")
@RequiredArgsConstructor
public class VendorCompanyController {

  private final PartnerCompanyService partnerCompanyService;
  @GetMapping
  @PreAuthorize("@authorizationService.hasPermission('" + PermissionNames.VENDOR_READ + "')")
  public ResponseEntity<ApiResponse<List<PartnerCompany>>> getAllVendors() {
    List<PartnerCompany> vendors = partnerCompanyService.getAllPartners();
    return ResponseEntity.ok(new ApiResponse<>(true, "Vendors retrieved successfully", vendors));
  }

  @GetMapping("/active")
  @PreAuthorize("@authorizationService.hasPermission('" + PermissionNames.VENDOR_READ + "')")
  public ResponseEntity<ApiResponse<List<PartnerCompany>>> getActiveVendors() {
    List<PartnerCompany> vendors = partnerCompanyService.getActivePartners();
    return ResponseEntity.ok(new ApiResponse<>(true, "Active vendors retrieved successfully", vendors));
  }

  @GetMapping("/type/{type}")
  @PreAuthorize("@authorizationService.hasPermission('" + PermissionNames.VENDOR_READ + "')")
  public ResponseEntity<ApiResponse<List<PartnerCompany>>> getVendorsByType(
      @PathVariable PartnershipType type) {
    List<PartnerCompany> vendors = partnerCompanyService.getPartnersByType(type);
    return ResponseEntity.ok(new ApiResponse<>(true, "Vendors retrieved successfully", vendors));
  }

  @GetMapping("/{id}")
  @PreAuthorize("@authorizationService.hasPermission('" + PermissionNames.VENDOR_READ + "')")
  public ResponseEntity<ApiResponse<PartnerCompany>> getVendorById(@PathVariable Long id) {
    PartnerCompany vendor = partnerCompanyService.getPartnerById(id);
    return ResponseEntity.ok(new ApiResponse<>(true, "Vendor retrieved successfully", vendor));
  }

  @GetMapping("/code/{code}")
  @PreAuthorize("@authorizationService.hasPermission('" + PermissionNames.VENDOR_READ + "')")
  public ResponseEntity<ApiResponse<PartnerCompany>> getVendorByCode(@PathVariable String code) {
    PartnerCompany vendor = partnerCompanyService.getPartnerByCode(code);
    return ResponseEntity.ok(new ApiResponse<>(true, "Vendor retrieved successfully", vendor));
  }

  @PostMapping
  @PreAuthorize("@authorizationService.hasPermission('" + PermissionNames.VENDOR_CREATE + "')")
  public ResponseEntity<ApiResponse<PartnerCompany>> createVendor(
      @Valid @RequestBody PartnerCompany vendor) {
    if (vendor.getCompanyCode() == null || vendor.getCompanyCode().isEmpty()) {
      vendor.setCompanyCode(partnerCompanyService.generateCompanyCode());
    }
    PartnerCompany created = partnerCompanyService.createPartner(vendor);
    return ResponseEntity.status(HttpStatus.CREATED)
        .body(new ApiResponse<>(true, "Vendor created successfully", created));
  }

  @GetMapping("/license/{license}/exists")
  @PreAuthorize("@authorizationService.hasPermission('" + PermissionNames.VENDOR_READ + "')")
  public ResponseEntity<ApiResponse<Boolean>> licenseExists(@PathVariable String license) {
    boolean exists = false;
    if (license != null && !license.isBlank()) {
      exists = partnerCompanyService
          .getAllPartners()
          .stream()
          .anyMatch(p -> p.getBusinessLicense() != null && p.getBusinessLicense().equalsIgnoreCase(license));
    }
    return ResponseEntity.ok(new ApiResponse<>(true, "License existence checked", exists));
  }

  @PutMapping("/{id}")
  @PreAuthorize("@authorizationService.hasPermission('" + PermissionNames.VENDOR_UPDATE + "')")
  public ResponseEntity<ApiResponse<PartnerCompany>> updateVendor(
      @PathVariable Long id, @Valid @RequestBody PartnerCompany vendor) {
    PartnerCompany updated = partnerCompanyService.updatePartner(id, vendor);
    return ResponseEntity.ok(new ApiResponse<>(true, "Vendor updated successfully", updated));
  }

  @DeleteMapping("/{id}")
  @PreAuthorize("@authorizationService.hasPermission('" + PermissionNames.VENDOR_DELETE + "')")
  public ResponseEntity<ApiResponse<Void>> deleteVendor(@PathVariable Long id) {
    partnerCompanyService.deletePartner(id);
    return ResponseEntity.ok(new ApiResponse<>(true, "Vendor deleted successfully"));
  }

  @PatchMapping("/{id}/deactivate")
  @PreAuthorize("@authorizationService.hasPermission('" + PermissionNames.VENDOR_UPDATE + "')")
  public ResponseEntity<ApiResponse<Void>> deactivateVendor(@PathVariable Long id) {
    partnerCompanyService.deactivatePartner(id);
    return ResponseEntity.ok(new ApiResponse<>(true, "Vendor deactivated successfully"));
  }

  @GetMapping("/search")
  @PreAuthorize("@authorizationService.hasPermission('" + PermissionNames.VENDOR_READ + "')")
  public ResponseEntity<ApiResponse<List<PartnerCompany>>> searchVendors(@RequestParam String query) {
    List<PartnerCompany> vendors = partnerCompanyService.searchPartners(query);
    return ResponseEntity.ok(new ApiResponse<>(true, "Search completed successfully", vendors));
  }

  @GetMapping("/generate-code")
  @PreAuthorize("@authorizationService.hasPermission('" + PermissionNames.VENDOR_CREATE + "')")
  public ResponseEntity<ApiResponse<String>> generateVendorCompanyCode() {
    String code = partnerCompanyService.generateCompanyCode();
    return ResponseEntity.ok(new ApiResponse<>(true, "Company code generated", code));
  }
}
