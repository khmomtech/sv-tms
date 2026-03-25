package com.svtrucking.logistics.controller;

import com.svtrucking.logistics.core.ApiResponse;
import com.svtrucking.logistics.dto.FailureCodeDto;
import com.svtrucking.logistics.security.PermissionNames;
import com.svtrucking.logistics.service.FailureCodeService;
import java.time.Instant;
import java.util.List;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping({"/api/admin/maintenance/failure-codes", "/api/maintenance/failure-codes"})
@RequiredArgsConstructor
public class FailureCodeController {

  private final FailureCodeService failureCodeService;

  @GetMapping
  @PreAuthorize("@authorizationService.hasPermission('" + PermissionNames.MAINTENANCE_READ + "')")
  public ResponseEntity<ApiResponse<Page<FailureCodeDto>>> list(
      @RequestParam(required = false) Boolean active, Pageable pageable) {
    Page<FailureCodeDto> data = failureCodeService.list(active, pageable);
    return ResponseEntity.ok(new ApiResponse<>(true, "Failure codes loaded", data, null, Instant.now()));
  }

  @GetMapping("/active")
  @PreAuthorize("@authorizationService.hasPermission('" + PermissionNames.MAINTENANCE_READ + "')")
  public ResponseEntity<ApiResponse<List<FailureCodeDto>>> listActive() {
    List<FailureCodeDto> data = failureCodeService.listActive();
    return ResponseEntity.ok(new ApiResponse<>(true, "Active failure codes", data, null, Instant.now()));
  }

  @GetMapping("/{id}")
  @PreAuthorize("@authorizationService.hasPermission('" + PermissionNames.MAINTENANCE_READ + "')")
  public ResponseEntity<ApiResponse<FailureCodeDto>> get(@PathVariable Long id) {
    return ResponseEntity.ok(
        new ApiResponse<>(true, "Failure code", failureCodeService.get(id), null, Instant.now()));
  }

  @PostMapping
  @PreAuthorize("@authorizationService.hasPermission('" + PermissionNames.MAINTENANCE_READ + "')")
  public ResponseEntity<ApiResponse<FailureCodeDto>> create(@RequestBody FailureCodeDto dto) {
    FailureCodeDto created = failureCodeService.create(dto);
    return ResponseEntity.status(HttpStatus.CREATED)
        .body(new ApiResponse<>(true, "Failure code created", created, null, Instant.now()));
  }

  @PutMapping("/{id}")
  @PreAuthorize("@authorizationService.hasPermission('" + PermissionNames.MAINTENANCE_READ + "')")
  public ResponseEntity<ApiResponse<FailureCodeDto>> update(
      @PathVariable Long id, @RequestBody FailureCodeDto dto) {
    FailureCodeDto updated = failureCodeService.update(id, dto);
    return ResponseEntity.ok(
        new ApiResponse<>(true, "Failure code updated", updated, null, Instant.now()));
  }

  @PostMapping("/{id}/deactivate")
  @PreAuthorize("@authorizationService.hasPermission('" + PermissionNames.MAINTENANCE_READ + "')")
  public ResponseEntity<ApiResponse<Void>> deactivate(@PathVariable Long id) {
    failureCodeService.deactivate(id);
    return ResponseEntity.ok(new ApiResponse<>(true, "Failure code deactivated", null, null, Instant.now()));
  }
}
