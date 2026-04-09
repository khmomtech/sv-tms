package com.svtrucking.logistics.controller.admin;

import com.svtrucking.logistics.core.ApiResponse;
import com.svtrucking.logistics.dto.StaffMemberDto;
import com.svtrucking.logistics.security.PermissionNames;
import com.svtrucking.logistics.service.StaffMemberService;
import java.time.Instant;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/admin/staff")
@RequiredArgsConstructor
public class StaffMemberController {

  private final StaffMemberService staffService;

  @GetMapping
  @PreAuthorize(
      "@authorizationService.hasPermission('" + PermissionNames.USER_READ + "')"
          + " or @authorizationService.hasPermission('" + PermissionNames.ADMIN_USER_READ + "')"
          + " or @authorizationService.hasPermission('" + PermissionNames.ADMIN_READ + "')"
          + " or @authorizationService.hasPermission('" + PermissionNames.ALL_FUNCTIONS + "')")
  public ResponseEntity<ApiResponse<Page<StaffMemberDto>>> list(
      @RequestParam(required = false) String search,
      @RequestParam(required = false) Boolean active,
      Pageable pageable) {
    Page<StaffMemberDto> data = staffService.list(search, active, pageable);
    return ResponseEntity.ok(new ApiResponse<>(true, "Staff loaded", data, null, Instant.now()));
  }

  @GetMapping("/{id}")
  @PreAuthorize(
      "@authorizationService.hasPermission('" + PermissionNames.USER_READ + "')"
          + " or @authorizationService.hasPermission('" + PermissionNames.ADMIN_USER_READ + "')"
          + " or @authorizationService.hasPermission('" + PermissionNames.ADMIN_READ + "')"
          + " or @authorizationService.hasPermission('" + PermissionNames.ALL_FUNCTIONS + "')")
  public ResponseEntity<ApiResponse<StaffMemberDto>> get(@PathVariable Long id) {
    return ResponseEntity.ok(new ApiResponse<>(true, "Staff", staffService.get(id), null, Instant.now()));
  }

  @PostMapping
  @PreAuthorize("@authorizationService.hasPermission('" + PermissionNames.USER_CREATE + "')")
  public ResponseEntity<ApiResponse<StaffMemberDto>> create(@RequestBody StaffMemberDto dto) {
    StaffMemberDto created = staffService.create(dto);
    return ResponseEntity.status(HttpStatus.CREATED)
        .body(new ApiResponse<>(true, "Staff created", created, null, Instant.now()));
  }

  @PutMapping("/{id}")
  @PreAuthorize("@authorizationService.hasPermission('" + PermissionNames.USER_UPDATE + "')")
  public ResponseEntity<ApiResponse<StaffMemberDto>> update(
      @PathVariable Long id, @RequestBody StaffMemberDto dto) {
    StaffMemberDto updated = staffService.update(id, dto);
    return ResponseEntity.ok(new ApiResponse<>(true, "Staff updated", updated, null, Instant.now()));
  }

  @DeleteMapping("/{id}")
  @PreAuthorize("@authorizationService.hasPermission('" + PermissionNames.USER_DELETE + "')")
  public ResponseEntity<ApiResponse<Void>> deactivate(@PathVariable Long id) {
    staffService.deactivate(id);
    return ResponseEntity.ok(new ApiResponse<>(true, "Staff deactivated", null, null, Instant.now()));
  }
}
