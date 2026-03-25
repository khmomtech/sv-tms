package com.svtrucking.logistics.controller.admin;

import com.svtrucking.logistics.core.ApiResponse;
import com.svtrucking.logistics.dto.MechanicDto;
import com.svtrucking.logistics.exception.ResourceNotFoundException;
import com.svtrucking.logistics.model.Mechanic;
import com.svtrucking.logistics.repository.MechanicRepository;
import com.svtrucking.logistics.repository.UserRepository;
import com.svtrucking.logistics.security.PermissionNames;
import java.time.Instant;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/admin/maintenance/mechanics")
@RequiredArgsConstructor
public class MechanicController {

  private final MechanicRepository mechanicRepository;
  private final UserRepository userRepository;
  private final com.svtrucking.logistics.repository.StaffMemberRepository staffRepository;

  @GetMapping
  @PreAuthorize("@authorizationService.hasPermission('" + PermissionNames.MAINTENANCE_READ + "')")
  public ResponseEntity<ApiResponse<Page<MechanicDto>>> list(
      @RequestParam(required = false) String search,
      @RequestParam(required = false) Boolean active,
      Pageable pageable) {
    String q = (search == null || search.isBlank()) ? null : search.trim();
    Page<MechanicDto> data = mechanicRepository.search(q, active, pageable).map(MechanicDto::fromEntity);
    return ResponseEntity.ok(new ApiResponse<>(true, "Mechanics loaded", data, null, Instant.now()));
  }

  @PostMapping
  @PreAuthorize("@authorizationService.hasPermission('" + PermissionNames.MAINTENANCE_READ + "')")
  public ResponseEntity<ApiResponse<MechanicDto>> create(@RequestBody MechanicDto dto) {
    Mechanic m = new Mechanic();
    if (dto.getUserId() != null) {
      m.setUser(userRepository.findById(dto.getUserId()).orElse(null));
    }
    if (dto.getStaffId() != null) {
      m.setStaffMember(staffRepository.findById(dto.getStaffId()).orElse(null));
    }
    m.setFullName(dto.getFullName());
    m.setPhone(dto.getPhone());
    m.setActive(dto.getActive() != null ? dto.getActive() : true);
    Mechanic saved = mechanicRepository.save(m);
    return ResponseEntity.status(HttpStatus.CREATED)
        .body(new ApiResponse<>(true, "Mechanic created", MechanicDto.fromEntity(saved), null, Instant.now()));
  }

  @PutMapping("/{id}")
  @PreAuthorize("@authorizationService.hasPermission('" + PermissionNames.MAINTENANCE_READ + "')")
  public ResponseEntity<ApiResponse<MechanicDto>> update(@PathVariable Long id, @RequestBody MechanicDto dto) {
    Mechanic m =
        mechanicRepository.findById(id).orElseThrow(() -> new ResourceNotFoundException("Mechanic not found: " + id));
    if (dto.getUserId() != null) {
      m.setUser(userRepository.findById(dto.getUserId()).orElse(null));
    }
    if (dto.getStaffId() != null) {
      m.setStaffMember(staffRepository.findById(dto.getStaffId()).orElse(null));
    }
    if (dto.getFullName() != null) m.setFullName(dto.getFullName());
    m.setPhone(dto.getPhone());
    if (dto.getActive() != null) m.setActive(dto.getActive());
    Mechanic saved = mechanicRepository.save(m);
    return ResponseEntity.ok(new ApiResponse<>(true, "Mechanic updated", MechanicDto.fromEntity(saved), null, Instant.now()));
  }

  @DeleteMapping("/{id}")
  @PreAuthorize("@authorizationService.hasPermission('" + PermissionNames.MAINTENANCE_READ + "')")
  public ResponseEntity<ApiResponse<Void>> delete(@PathVariable Long id) {
    Mechanic m =
        mechanicRepository.findById(id).orElseThrow(() -> new ResourceNotFoundException("Mechanic not found: " + id));
    m.setActive(false);
    mechanicRepository.save(m);
    return ResponseEntity.ok(new ApiResponse<>(true, "Mechanic deactivated", null, null, Instant.now()));
  }
}
