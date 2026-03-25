package com.svtrucking.logistics.controller;

import com.svtrucking.logistics.core.ApiResponse;
import com.svtrucking.logistics.dto.MaintenanceRequestDto;
import com.svtrucking.logistics.enums.MaintenanceRequestStatus;
import com.svtrucking.logistics.repository.UserRepository;
import com.svtrucking.logistics.security.PermissionNames;
import com.svtrucking.logistics.service.MaintenanceRequestService;
import java.time.Instant;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping({
    "/api/admin/maintenance/requests",
    "/api/admin/maintenance-requests",
    "/api/maintenance/requests"
})
@RequiredArgsConstructor
public class MaintenanceRequestController {

  private final MaintenanceRequestService maintenanceRequestService;
  private final UserRepository userRepository;

  @GetMapping
  @PreAuthorize("@authorizationService.hasPermission('" + PermissionNames.MAINTENANCE_READ + "')")
  public ResponseEntity<ApiResponse<Page<MaintenanceRequestDto>>> list(
      @RequestParam(required = false) String search,
      @RequestParam(required = false) MaintenanceRequestStatus status,
      @RequestParam(required = false) Long vehicleId,
      @RequestParam(required = false) Long failureCodeId,
      Pageable pageable) {
    Page<MaintenanceRequestDto> data =
        maintenanceRequestService.search(search, status, vehicleId, failureCodeId, pageable);
    return ResponseEntity.ok(new ApiResponse<>(true, "Maintenance requests loaded", data, null, Instant.now()));
  }

  @GetMapping("/{id}")
  @PreAuthorize("@authorizationService.hasPermission('" + PermissionNames.MAINTENANCE_READ + "')")
  public ResponseEntity<ApiResponse<MaintenanceRequestDto>> get(@PathVariable Long id) {
    return ResponseEntity.ok(new ApiResponse<>(true, "Maintenance request", maintenanceRequestService.getById(id), null, Instant.now()));
  }

  @PostMapping
  @PreAuthorize("@authorizationService.hasPermission('" + PermissionNames.MAINTENANCE_READ + "')")
  public ResponseEntity<ApiResponse<MaintenanceRequestDto>> create(
      @RequestBody MaintenanceRequestDto dto, Authentication authentication) {
    Long userId = resolveUserId(authentication);
    MaintenanceRequestDto created = maintenanceRequestService.create(dto, userId);
    return ResponseEntity.status(HttpStatus.CREATED)
        .body(new ApiResponse<>(true, "Maintenance request created", created, null, Instant.now()));
  }

  @PutMapping("/{id}")
  @PreAuthorize("@authorizationService.hasPermission('" + PermissionNames.MAINTENANCE_READ + "')")
  public ResponseEntity<ApiResponse<MaintenanceRequestDto>> update(
      @PathVariable Long id, @RequestBody MaintenanceRequestDto dto) {
    return ResponseEntity.ok(new ApiResponse<>(true, "Maintenance request updated", maintenanceRequestService.update(id, dto), null, Instant.now()));
  }

  @PostMapping("/{id}/approve")
  @PreAuthorize("@authorizationService.hasPermission('" + PermissionNames.MAINTENANCE_READ + "')")
  public ResponseEntity<ApiResponse<MaintenanceRequestDto>> approve(
      @PathVariable Long id,
      @RequestParam(required = false) String remarks,
      Authentication authentication) {
    Long userId = resolveUserId(authentication);
    return ResponseEntity.ok(new ApiResponse<>(true, "Maintenance request approved", maintenanceRequestService.approve(id, userId, remarks), null, Instant.now()));
  }

  @PostMapping("/{id}/reject")
  @PreAuthorize("@authorizationService.hasPermission('" + PermissionNames.MAINTENANCE_READ + "')")
  public ResponseEntity<ApiResponse<MaintenanceRequestDto>> reject(
      @PathVariable Long id,
      @RequestParam(required = false) String reason,
      Authentication authentication) {
    Long userId = resolveUserId(authentication);
    return ResponseEntity.ok(new ApiResponse<>(true, "Maintenance request rejected", maintenanceRequestService.reject(id, userId, reason), null, Instant.now()));
  }

  @DeleteMapping("/{id}")
  @PreAuthorize("@authorizationService.hasPermission('" + PermissionNames.MAINTENANCE_READ + "')")
  public ResponseEntity<ApiResponse<Void>> delete(@PathVariable Long id) {
    maintenanceRequestService.delete(id);
    return ResponseEntity.ok(new ApiResponse<>(true, "Maintenance request deleted", null, null, Instant.now()));
  }

  private Long resolveUserId(Authentication authentication) {
    if (authentication == null) return null;
    Object principal = authentication.getPrincipal();
    if (principal instanceof org.springframework.security.core.userdetails.UserDetails ud) {
      return userRepository.findByUsername(ud.getUsername()).map(u -> u.getId()).orElse(null);
    }
    if (principal instanceof String s) {
      return userRepository.findByUsername(s).map(u -> u.getId()).orElse(null);
    }
    return null;
  }
}
