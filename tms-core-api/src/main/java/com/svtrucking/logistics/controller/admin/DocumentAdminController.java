package com.svtrucking.logistics.controller.admin;

import com.svtrucking.logistics.core.ApiResponse;
import com.svtrucking.logistics.dto.VehicleDocumentDto;
import com.svtrucking.logistics.dto.VehicleDocumentRequest;
import com.svtrucking.logistics.security.AuthenticatedUserUtil;
import com.svtrucking.logistics.security.PermissionNames;
import com.svtrucking.logistics.service.DocumentAdminService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import java.time.LocalDate;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Sort;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/admin/documents")
@Tag(name = "Fleet Management - Vehicle Documents", description = "Create / update / delete vehicle documents")
@RequiredArgsConstructor
@Slf4j
public class DocumentAdminController {

  private final DocumentAdminService documentAdminService;
  private final AuthenticatedUserUtil authenticatedUserUtil;

  @PostMapping
  @PreAuthorize("@authorizationService.hasPermission('" + PermissionNames.VEHICLE_UPDATE + "')")
  @Operation(summary = "Add a document for a vehicle")
  public ResponseEntity<ApiResponse<VehicleDocumentDto>> createDocument(@RequestBody VehicleDocumentRequest request) {
    String username = authenticatedUserUtil.getCurrentUser().getUsername();
    VehicleDocumentDto created = documentAdminService.createDocument(request, username);
    return ResponseEntity.status(HttpStatus.CREATED).body(ApiResponse.ok("Document created successfully", created));
  }

  @PutMapping("/{id}")
  @PreAuthorize("@authorizationService.hasPermission('" + PermissionNames.VEHICLE_UPDATE + "')")
  @Operation(summary = "Update a vehicle document")
  public ResponseEntity<ApiResponse<VehicleDocumentDto>> updateDocument(
      @PathVariable Long id, @RequestBody VehicleDocumentRequest request) {
    String username = authenticatedUserUtil.getCurrentUser().getUsername();
    VehicleDocumentDto updated = documentAdminService.updateDocument(id, request, username);
    return ResponseEntity.ok(ApiResponse.ok("Document updated successfully", updated));
  }

  @DeleteMapping("/{id}")
  @PreAuthorize("@authorizationService.hasPermission('" + PermissionNames.VEHICLE_UPDATE + "')")
  @Operation(summary = "Delete a vehicle document")
  public ResponseEntity<ApiResponse<String>> deleteDocument(@PathVariable Long id) {
    documentAdminService.deleteDocument(id);
    return ResponseEntity.ok(ApiResponse.success("Document deleted successfully"));
  }

  @GetMapping("/report")
  @PreAuthorize("@authorizationService.hasPermission('" + PermissionNames.VEHICLE_READ + "')")
  @Operation(summary = "Vehicle document report list with date filtering")
  public ResponseEntity<ApiResponse<Page<VehicleDocumentDto>>> report(
      @RequestParam(required = false) String dateField,
      @RequestParam(required = false) LocalDate from,
      @RequestParam(required = false) LocalDate to,
      @RequestParam(required = false) Long vehicleId,
      @RequestParam(required = false) String documentType,
      @RequestParam(required = false) String search,
      @RequestParam(defaultValue = "0") int page,
      @RequestParam(defaultValue = "20") int size) {
    var pageable = PageRequest.of(page, size, Sort.by("updatedAt").descending());
    Page<VehicleDocumentDto> result =
        documentAdminService.report(dateField, from, to, vehicleId, documentType, search, pageable);
    return ResponseEntity.ok(ApiResponse.ok("Vehicle document report", result));
  }
}
