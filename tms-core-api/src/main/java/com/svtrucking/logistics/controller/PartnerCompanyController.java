package com.svtrucking.logistics.controller;

import com.svtrucking.logistics.core.ApiResponse;
import com.svtrucking.logistics.enums.PartnershipType;
import com.svtrucking.logistics.model.PartnerCompany;
import com.svtrucking.logistics.service.PartnerCompanyService;
import jakarta.validation.Valid;
import java.util.List;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PatchMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

/**
 * REST API for managing partner companies
 */
@RestController
@RequestMapping("/api/partners")
@RequiredArgsConstructor
public class PartnerCompanyController {

  private final PartnerCompanyService partnerCompanyService;

  @GetMapping
  @PreAuthorize("hasAnyRole('SUPERADMIN', 'ADMIN', 'MANAGER')")
  public ResponseEntity<ApiResponse<List<PartnerCompany>>> getAllPartners() {
    List<PartnerCompany> partners = partnerCompanyService.getAllPartners();
    return ResponseEntity.ok(new ApiResponse<>(true, "Partners retrieved successfully", partners));
  }

  @GetMapping("/active")
  @PreAuthorize("hasAnyRole('SUPERADMIN', 'ADMIN', 'MANAGER')")
  public ResponseEntity<ApiResponse<List<PartnerCompany>>> getActivePartners() {
    List<PartnerCompany> partners = partnerCompanyService.getActivePartners();
    return ResponseEntity.ok(new ApiResponse<>(true, "Active partners retrieved successfully", partners));
  }

  @GetMapping("/type/{type}")
  @PreAuthorize("hasAnyRole('SUPERADMIN', 'ADMIN', 'MANAGER')")
  public ResponseEntity<ApiResponse<List<PartnerCompany>>> getPartnersByType(
      @PathVariable PartnershipType type) {
    List<PartnerCompany> partners = partnerCompanyService.getPartnersByType(type);
    return ResponseEntity.ok(new ApiResponse<>(true, "Partners retrieved successfully", partners));
  }

  @GetMapping("/{id}")
  @PreAuthorize("hasAnyRole('SUPERADMIN', 'ADMIN', 'MANAGER', 'PARTNER_ADMIN')")
  public ResponseEntity<ApiResponse<PartnerCompany>> getPartnerById(@PathVariable Long id) {
    PartnerCompany partner = partnerCompanyService.getPartnerById(id);
    return ResponseEntity.ok(new ApiResponse<>(true, "Partner retrieved successfully", partner));
  }

  @GetMapping("/code/{code}")
  @PreAuthorize("hasAnyRole('SUPERADMIN', 'ADMIN', 'MANAGER')")
  public ResponseEntity<ApiResponse<PartnerCompany>> getPartnerByCode(@PathVariable String code) {
    PartnerCompany partner = partnerCompanyService.getPartnerByCode(code);
    return ResponseEntity.ok(new ApiResponse<>(true, "Partner retrieved successfully", partner));
  }

  @PostMapping
  @PreAuthorize("hasAnyRole('SUPERADMIN', 'ADMIN')")
  public ResponseEntity<ApiResponse<PartnerCompany>> createPartner(
      @Valid @RequestBody PartnerCompany partner) {
    // Auto-generate company code if not provided
    if (partner.getCompanyCode() == null || partner.getCompanyCode().isEmpty()) {
      partner.setCompanyCode(partnerCompanyService.generateCompanyCode());
    }

    PartnerCompany created = partnerCompanyService.createPartner(partner);
    return ResponseEntity.status(HttpStatus.CREATED)
        .body(new ApiResponse<>(true, "Partner created successfully", created));
  }

  @PutMapping("/{id}")
  @PreAuthorize("hasAnyRole('SUPERADMIN', 'ADMIN')")
  public ResponseEntity<ApiResponse<PartnerCompany>> updatePartner(
      @PathVariable Long id, @Valid @RequestBody PartnerCompany partner) {
    PartnerCompany updated = partnerCompanyService.updatePartner(id, partner);
    return ResponseEntity.ok(new ApiResponse<>(true, "Partner updated successfully", updated));
  }

  @DeleteMapping("/{id}")
  @PreAuthorize("hasRole('SUPERADMIN')")
  public ResponseEntity<ApiResponse<Void>> deletePartner(@PathVariable Long id) {
    partnerCompanyService.deletePartner(id);
    return ResponseEntity.ok(new ApiResponse<>(true, "Partner deleted successfully"));
  }

  @PatchMapping("/{id}/deactivate")
  @PreAuthorize("hasAnyRole('SUPERADMIN', 'ADMIN')")
  public ResponseEntity<ApiResponse<Void>> deactivatePartner(@PathVariable Long id) {
    partnerCompanyService.deactivatePartner(id);
    return ResponseEntity.ok(new ApiResponse<>(true, "Partner deactivated successfully"));
  }

  @GetMapping("/search")
  @PreAuthorize("hasAnyRole('SUPERADMIN', 'ADMIN', 'MANAGER')")
  public ResponseEntity<ApiResponse<List<PartnerCompany>>> searchPartners(
      @RequestParam String query) {
    List<PartnerCompany> partners = partnerCompanyService.searchPartners(query);
    return ResponseEntity.ok(new ApiResponse<>(true, "Search completed successfully", partners));
  }

  @GetMapping("/generate-code")
  @PreAuthorize("hasAnyRole('SUPERADMIN', 'ADMIN')")
  public ResponseEntity<ApiResponse<String>> generateCompanyCode() {
    String code = partnerCompanyService.generateCompanyCode();
    return ResponseEntity.ok(new ApiResponse<>(true, "Company code generated", code));
  }
}
