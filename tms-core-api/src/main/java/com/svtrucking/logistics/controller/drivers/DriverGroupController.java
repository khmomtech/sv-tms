package com.svtrucking.logistics.controller.drivers;

import com.svtrucking.logistics.core.ApiResponse;
import com.svtrucking.logistics.model.DriverGroup;
import com.svtrucking.logistics.repository.DriverGroupRepository;
import java.util.List;
import java.util.Optional;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.server.ResponseStatusException;
import org.springframework.http.HttpStatus;

@RestController
@RequestMapping("/api/admin/driver-groups")
public class DriverGroupController {

  private final DriverGroupRepository driverGroupRepository;

  public DriverGroupController(DriverGroupRepository driverGroupRepository) {
    this.driverGroupRepository = driverGroupRepository;
  }

  @GetMapping
  @PreAuthorize("@authorizationService.hasPermission(T(com.svtrucking.logistics.security.PermissionNames).DRIVER_MANAGE) "
      + "or @authorizationService.hasPermission(T(com.svtrucking.logistics.security.PermissionNames).DRIVER_VIEW_ALL)")
  public ApiResponse<List<DriverGroup>> listActive() {
    List<DriverGroup> groups = driverGroupRepository.findByActiveTrueOrderByNameAsc();
    return ApiResponse.success("Driver groups fetched", groups);
  }

  @PostMapping
  @PreAuthorize("@authorizationService.hasPermission(T(com.svtrucking.logistics.security.PermissionNames).DRIVER_MANAGE)")
  public ApiResponse<DriverGroup> create(@RequestBody DriverGroupRequest request) {
    DriverGroup group =
        DriverGroup.builder()
            .name(request.name())
            .code(request.code())
            .description(request.description())
            .active(Optional.ofNullable(request.active()).orElse(true))
            .build();
    return ApiResponse.success("Driver group created", driverGroupRepository.save(group));
  }

  @PutMapping("/{id}")
  @PreAuthorize("@authorizationService.hasPermission(T(com.svtrucking.logistics.security.PermissionNames).DRIVER_MANAGE)")
  public ApiResponse<DriverGroup> update(
      @PathVariable Long id, @RequestBody DriverGroupRequest request) {
    DriverGroup group =
        driverGroupRepository
            .findById(id)
            .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Group not found"));
    if (request.name() != null) group.setName(request.name());
    if (request.code() != null) group.setCode(request.code());
    if (request.description() != null) group.setDescription(request.description());
    if (request.active() != null) group.setActive(request.active());
    return ApiResponse.success("Driver group updated", driverGroupRepository.save(group));
  }

  @DeleteMapping("/{id}")
  @PreAuthorize("@authorizationService.hasPermission(T(com.svtrucking.logistics.security.PermissionNames).DRIVER_MANAGE)")
  public ApiResponse<String> delete(@PathVariable Long id) {
    if (!driverGroupRepository.existsById(id)) {
      throw new ResponseStatusException(HttpStatus.NOT_FOUND, "Group not found");
    }
    driverGroupRepository.deleteById(id);
    return ApiResponse.success("Driver group deleted");
  }

  public record DriverGroupRequest(String name, String code, String description, Boolean active) {}
}
