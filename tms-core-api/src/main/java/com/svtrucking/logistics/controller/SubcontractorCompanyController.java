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
import org.springframework.web.bind.annotation.*;

/**
 * Alias endpoints for subcontractors (synonym of vendors/partners).
 * Maps to the same service layer as PartnerCompanyController while exposing /api/subcontractors paths.
 */
@RestController
@RequestMapping("/api/subcontractors")
@RequiredArgsConstructor
public class SubcontractorCompanyController {

  private final PartnerCompanyService partnerCompanyService;

  @GetMapping
  @PreAuthorize("hasAnyRole('SUPERADMIN', 'ADMIN', 'MANAGER')")
  public ResponseEntity<ApiResponse<List<PartnerCompany>>> getAll() {
    List<PartnerCompany> list = partnerCompanyService.getAllPartners();
    return ResponseEntity.ok(new ApiResponse<>(true, "Subcontractors retrieved successfully", list));
  }

  @GetMapping("/active")
  @PreAuthorize("hasAnyRole('SUPERADMIN', 'ADMIN', 'MANAGER')")
  public ResponseEntity<ApiResponse<List<PartnerCompany>>> getActive() {
    List<PartnerCompany> list = partnerCompanyService.getActivePartners();
    return ResponseEntity.ok(new ApiResponse<>(true, "Active subcontractors retrieved successfully", list));
  }

  @GetMapping("/type/{type}")
  @PreAuthorize("hasAnyRole('SUPERADMIN', 'ADMIN', 'MANAGER')")
  public ResponseEntity<ApiResponse<List<PartnerCompany>>> getByType(@PathVariable PartnershipType type) {
    List<PartnerCompany> list = partnerCompanyService.getPartnersByType(type);
    return ResponseEntity.ok(new ApiResponse<>(true, "Subcontractors retrieved successfully", list));
  }

  @GetMapping("/{id}")
  @PreAuthorize("hasAnyRole('SUPERADMIN', 'ADMIN', 'MANAGER', 'PARTNER_ADMIN')")
  public ResponseEntity<ApiResponse<PartnerCompany>> getById(@PathVariable Long id) {
    PartnerCompany item = partnerCompanyService.getPartnerById(id);
    return ResponseEntity.ok(new ApiResponse<>(true, "Subcontractor retrieved successfully", item));
  }

  @GetMapping("/code/{code}")
  @PreAuthorize("hasAnyRole('SUPERADMIN', 'ADMIN', 'MANAGER')")
  public ResponseEntity<ApiResponse<PartnerCompany>> getByCode(@PathVariable String code) {
    PartnerCompany item = partnerCompanyService.getPartnerByCode(code);
    return ResponseEntity.ok(new ApiResponse<>(true, "Subcontractor retrieved successfully", item));
  }

  @PostMapping
  @PreAuthorize("hasAnyRole('SUPERADMIN', 'ADMIN')")
  public ResponseEntity<ApiResponse<PartnerCompany>> create(@Valid @RequestBody PartnerCompany body) {
    if (body.getCompanyCode() == null || body.getCompanyCode().isEmpty()) {
      body.setCompanyCode(partnerCompanyService.generateCompanyCode());
    }
    PartnerCompany created = partnerCompanyService.createPartner(body);
    return ResponseEntity.status(HttpStatus.CREATED)
        .body(new ApiResponse<>(true, "Subcontractor created successfully", created));
  }

  @PutMapping("/{id}")
  @PreAuthorize("hasAnyRole('SUPERADMIN', 'ADMIN')")
  public ResponseEntity<ApiResponse<PartnerCompany>> update(
      @PathVariable Long id, @Valid @RequestBody PartnerCompany body) {
    PartnerCompany updated = partnerCompanyService.updatePartner(id, body);
    return ResponseEntity.ok(new ApiResponse<>(true, "Subcontractor updated successfully", updated));
  }

  @DeleteMapping("/{id}")
  @PreAuthorize("hasRole('SUPERADMIN')")
  public ResponseEntity<ApiResponse<Void>> delete(@PathVariable Long id) {
    partnerCompanyService.deletePartner(id);
    return ResponseEntity.ok(new ApiResponse<>(true, "Subcontractor deleted successfully"));
  }

  @PatchMapping("/{id}/deactivate")
  @PreAuthorize("hasAnyRole('SUPERADMIN', 'ADMIN')")
  public ResponseEntity<ApiResponse<Void>> deactivate(@PathVariable Long id) {
    partnerCompanyService.deactivatePartner(id);
    return ResponseEntity.ok(new ApiResponse<>(true, "Subcontractor deactivated successfully"));
  }

  @GetMapping("/search")
  @PreAuthorize("hasAnyRole('SUPERADMIN', 'ADMIN', 'MANAGER')")
  public ResponseEntity<ApiResponse<List<PartnerCompany>>> search(@RequestParam String query) {
    List<PartnerCompany> list = partnerCompanyService.searchPartners(query);
    return ResponseEntity.ok(new ApiResponse<>(true, "Search completed successfully", list));
  }

  @GetMapping("/generate-code")
  @PreAuthorize("hasAnyRole('SUPERADMIN', 'ADMIN')")
  public ResponseEntity<ApiResponse<String>> generateCode() {
    String code = partnerCompanyService.generateCompanyCode();
    return ResponseEntity.ok(new ApiResponse<>(true, "Company code generated", code));
  }
}
