package com.svtrucking.logistics.controller.admin;

import com.svtrucking.logistics.core.ApiResponse;
import com.svtrucking.logistics.dto.EmployeeDto;
import com.svtrucking.logistics.model.Employee;
import com.svtrucking.logistics.repository.UserRepository;
import com.svtrucking.logistics.security.PermissionNames;
import com.svtrucking.logistics.service.EmployeeService;
import java.time.Instant;
import java.util.Optional;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/admin/employees")
@RequiredArgsConstructor
public class EmployeeController {

  private final EmployeeService employeeService;
  private final UserRepository userRepository;

  @GetMapping
  @PreAuthorize(
      "@authorizationService.hasPermission('" + PermissionNames.USER_READ + "')"
          + " or @authorizationService.hasPermission('" + PermissionNames.ADMIN_USER_READ + "')"
          + " or @authorizationService.hasPermission('" + PermissionNames.ADMIN_READ + "')"
          + " or @authorizationService.hasPermission('" + PermissionNames.ALL_FUNCTIONS + "')")
  public ResponseEntity<ApiResponse<Page<EmployeeDto>>> list(
      @RequestParam(required = false) String search, Pageable pageable) {
    Page<EmployeeDto> data =
        employeeService.search(search, pageable).map(EmployeeDto::fromEntity);
    return ResponseEntity.ok(new ApiResponse<>(true, "Employees loaded", data, null, Instant.now()));
  }

  @GetMapping("/{id}")
  @PreAuthorize(
      "@authorizationService.hasPermission('" + PermissionNames.USER_READ + "')"
          + " or @authorizationService.hasPermission('" + PermissionNames.ADMIN_USER_READ + "')"
          + " or @authorizationService.hasPermission('" + PermissionNames.ADMIN_READ + "')"
          + " or @authorizationService.hasPermission('" + PermissionNames.ALL_FUNCTIONS + "')")
  public ResponseEntity<ApiResponse<EmployeeDto>> get(@PathVariable Long id) {
    Optional<Employee> employee = employeeService.getEmployeeById(id);
    return employee
        .map(e -> ResponseEntity.ok(new ApiResponse<>(true, "Employee", EmployeeDto.fromEntity(e), null, Instant.now())))
        .orElseGet(() -> ResponseEntity.status(HttpStatus.NOT_FOUND)
            .body(new ApiResponse<>(false, "Employee not found", null, null, Instant.now())));
  }

  @PostMapping
  @PreAuthorize(
      "@authorizationService.hasPermission('" + PermissionNames.USER_CREATE + "')"
          + " or @authorizationService.hasPermission('" + PermissionNames.ADMIN_READ + "')"
          + " or @authorizationService.hasPermission('" + PermissionNames.ALL_FUNCTIONS + "')")
  public ResponseEntity<ApiResponse<EmployeeDto>> create(@RequestBody EmployeeDto dto) {
    Employee employee = EmployeeDto.toEntity(dto);
    if (dto.getUserId() != null) {
      employee.setUser(userRepository.findById(dto.getUserId()).orElse(null));
    }
    Employee created = employeeService.addEmployee(employee);
    return ResponseEntity.status(HttpStatus.CREATED)
        .body(new ApiResponse<>(true, "Employee created", EmployeeDto.fromEntity(created), null, Instant.now()));
  }

  @PutMapping("/{id}")
  @PreAuthorize(
      "@authorizationService.hasPermission('" + PermissionNames.USER_UPDATE + "')"
          + " or @authorizationService.hasPermission('" + PermissionNames.ADMIN_READ + "')"
          + " or @authorizationService.hasPermission('" + PermissionNames.ALL_FUNCTIONS + "')")
  public ResponseEntity<ApiResponse<EmployeeDto>> update(
      @PathVariable Long id, @RequestBody EmployeeDto dto) {
    Employee employee = EmployeeDto.toEntity(dto);
    if (dto.getUserId() != null) {
      employee.setUser(userRepository.findById(dto.getUserId()).orElse(null));
    }
    Employee updated = employeeService.updateEmployee(id, employee);
    return ResponseEntity.ok(new ApiResponse<>(true, "Employee updated", EmployeeDto.fromEntity(updated), null, Instant.now()));
  }

  @DeleteMapping("/{id}")
  @PreAuthorize(
      "@authorizationService.hasPermission('" + PermissionNames.USER_DELETE + "')"
          + " or @authorizationService.hasPermission('" + PermissionNames.ADMIN_READ + "')"
          + " or @authorizationService.hasPermission('" + PermissionNames.ALL_FUNCTIONS + "')")
  public ResponseEntity<ApiResponse<Void>> delete(@PathVariable Long id) {
    employeeService.deleteEmployee(id);
    return ResponseEntity.ok(new ApiResponse<>(true, "Employee deleted", null, null, Instant.now()));
  }
}
