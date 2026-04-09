package com.svtrucking.logistics.controller;

import com.svtrucking.logistics.dto.WorkOrderDto;
import com.svtrucking.logistics.dto.WorkOrderPartDto;
import com.svtrucking.logistics.dto.WorkOrderPhotoDto;
import com.svtrucking.logistics.dto.WorkOrderTaskDto;
import com.svtrucking.logistics.enums.Priority;
import com.svtrucking.logistics.enums.WorkOrderStatus;
import com.svtrucking.logistics.enums.WorkOrderType;
import com.svtrucking.logistics.service.WorkOrderService;
import com.svtrucking.logistics.repository.UserRepository;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDateTime;
import java.util.List;

@RestController
@RequestMapping("/api")
@RequiredArgsConstructor
public class WorkOrderController {

  private final WorkOrderService workOrderService;
  private final UserRepository userRepository;

  @GetMapping("/admin/work-orders")
  @PreAuthorize("hasAnyAuthority('ROLE_ADMIN','ROLE_SUPERADMIN','ROLE_MANAGER','ROLE_DISPATCHER','all_functions')")
  public ResponseEntity<Page<WorkOrderDto>> getAllWorkOrders(Pageable pageable) {
    return ResponseEntity.ok(workOrderService.getAllWorkOrders(pageable));
  }

  @GetMapping("/admin/work-orders/filter")
  @PreAuthorize("hasAnyAuthority('ROLE_ADMIN','ROLE_SUPERADMIN','ROLE_MANAGER','ROLE_DISPATCHER','all_functions')")
  public ResponseEntity<Page<WorkOrderDto>> filterWorkOrders(
      @RequestParam(required = false) WorkOrderStatus status,
      @RequestParam(required = false) WorkOrderType type,
      @RequestParam(required = false) Priority priority,
      @RequestParam(required = false) Long vehicleId,
      @RequestParam(required = false) Long technicianId,
      @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE_TIME) LocalDateTime scheduledAfter,
      @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE_TIME) LocalDateTime scheduledBefore,
      Pageable pageable) {
    return ResponseEntity.ok(
        workOrderService.filterWorkOrders(
            status, type, priority, vehicleId, technicianId, scheduledAfter, scheduledBefore, pageable));
  }

  @GetMapping("/admin/work-orders/urgent")
  @PreAuthorize("hasAnyAuthority('ROLE_ADMIN','ROLE_SUPERADMIN','ROLE_MANAGER','ROLE_DISPATCHER','all_functions')")
  public ResponseEntity<List<WorkOrderDto>> getUrgentWorkOrders() {
    return ResponseEntity.ok(workOrderService.getUrgentWorkOrders());
  }

  @GetMapping("/admin/work-orders/pending-approval")
  @PreAuthorize("hasAnyAuthority('ROLE_ADMIN','ROLE_SUPERADMIN','ROLE_MANAGER','all_functions')")
  public ResponseEntity<List<WorkOrderDto>> getPendingApproval() {
    return ResponseEntity.ok(workOrderService.getPendingApproval());
  }

  @GetMapping("/admin/work-orders/{id}")
  @PreAuthorize("hasAnyAuthority('ROLE_ADMIN','ROLE_SUPERADMIN','ROLE_MANAGER','ROLE_DISPATCHER','ROLE_TECHNICIAN','all_functions')")
  public ResponseEntity<WorkOrderDto> getWorkOrderById(@PathVariable Long id) {
    return ResponseEntity.ok(workOrderService.getWorkOrderById(id));
  }

  @GetMapping("/technician/work-orders/{id}")
  @PreAuthorize("hasRole('TECHNICIAN')")
  public ResponseEntity<WorkOrderDto> getTechnicianWorkOrder(@PathVariable Long id) {
    return ResponseEntity.ok(workOrderService.getWorkOrderById(id));
  }

  @PostMapping("/admin/work-orders")
  @PreAuthorize("hasAnyAuthority('ROLE_ADMIN','ROLE_SUPERADMIN','ROLE_MANAGER','ROLE_DISPATCHER','all_functions')")
  public ResponseEntity<WorkOrderDto> createWorkOrder(
      @Valid @RequestBody WorkOrderDto workOrderDto, Authentication authentication) {
    Long userId = getUserIdFromAuth(authentication);
    WorkOrderDto created = workOrderService.createWorkOrder(workOrderDto, userId);
    return ResponseEntity.status(HttpStatus.CREATED).body(created);
  }

  @PutMapping("/admin/work-orders/{id}")
  @PreAuthorize("hasAnyAuthority('ROLE_ADMIN','ROLE_SUPERADMIN','ROLE_MANAGER','ROLE_DISPATCHER','all_functions')")
  public ResponseEntity<WorkOrderDto> updateWorkOrder(
      @PathVariable Long id, @RequestBody WorkOrderDto workOrderDto, Authentication authentication) {
    Long userId = getUserIdFromAuth(authentication);
    WorkOrderDto updated = workOrderService.updateWorkOrder(id, workOrderDto, userId);
    return ResponseEntity.ok(updated);
  }

  @PostMapping("/admin/work-orders/{id}/tasks")
  @PreAuthorize("hasAnyAuthority('ROLE_ADMIN','ROLE_SUPERADMIN','ROLE_MANAGER','ROLE_DISPATCHER','all_functions')")
  public ResponseEntity<WorkOrderDto> addTask(
      @PathVariable Long id, @Valid @RequestBody WorkOrderTaskDto taskDto) {
    return ResponseEntity.ok(workOrderService.addTaskToWorkOrder(id, taskDto));
  }

  @PutMapping("/admin/work-orders/{id}/tasks/{taskId}")
  @PreAuthorize("hasAnyAuthority('ROLE_ADMIN','ROLE_SUPERADMIN','ROLE_MANAGER','ROLE_DISPATCHER','all_functions')")
  public ResponseEntity<WorkOrderDto> updateTask(
      @PathVariable Long id,
      @PathVariable Long taskId,
      @RequestBody WorkOrderTaskDto taskDto) {
    return ResponseEntity.ok(workOrderService.updateWorkOrderTask(id, taskId, taskDto));
  }

  @DeleteMapping("/admin/work-orders/{id}/tasks/{taskId}")
  @PreAuthorize("hasAnyAuthority('ROLE_ADMIN','ROLE_SUPERADMIN','ROLE_MANAGER','ROLE_DISPATCHER','all_functions')")
  public ResponseEntity<WorkOrderDto> deleteTask(
      @PathVariable Long id, @PathVariable Long taskId) {
    return ResponseEntity.ok(workOrderService.deleteWorkOrderTask(id, taskId));
  }

  @PostMapping("/admin/work-orders/{id}/parts")
  @PreAuthorize("hasAnyAuthority('ROLE_ADMIN','ROLE_SUPERADMIN','ROLE_MANAGER','ROLE_TECHNICIAN','all_functions')")
  public ResponseEntity<WorkOrderDto> addPart(
      @PathVariable Long id, @Valid @RequestBody WorkOrderPartDto partDto, Authentication authentication) {
    Long userId = getUserIdFromAuth(authentication);
    return ResponseEntity.ok(workOrderService.addPartToWorkOrder(id, partDto, userId));
  }

  @DeleteMapping("/admin/work-orders/{id}/parts/{partId}")
  @PreAuthorize("hasAnyAuthority('ROLE_ADMIN','ROLE_SUPERADMIN','ROLE_MANAGER','ROLE_TECHNICIAN','all_functions')")
  public ResponseEntity<WorkOrderDto> deletePart(
      @PathVariable Long id, @PathVariable Long partId) {
    return ResponseEntity.ok(workOrderService.deleteWorkOrderPart(id, partId));
  }

  @PostMapping("/admin/work-orders/{id}/photos")
  @PreAuthorize("hasAnyAuthority('ROLE_ADMIN','ROLE_SUPERADMIN','ROLE_MANAGER','ROLE_TECHNICIAN','all_functions')")
  public ResponseEntity<WorkOrderDto> addPhoto(
      @PathVariable Long id, @Valid @RequestBody WorkOrderPhotoDto photoDto, Authentication authentication) {
    Long userId = getUserIdFromAuth(authentication);
    return ResponseEntity.ok(workOrderService.addPhotoToWorkOrder(id, photoDto, userId));
  }

  @DeleteMapping("/admin/work-orders/{id}/photos/{photoId}")
  @PreAuthorize("hasAnyAuthority('ROLE_ADMIN','ROLE_SUPERADMIN','ROLE_MANAGER','ROLE_TECHNICIAN','all_functions')")
  public ResponseEntity<WorkOrderDto> deletePhoto(
      @PathVariable Long id, @PathVariable Long photoId) {
    return ResponseEntity.ok(workOrderService.deleteWorkOrderPhoto(id, photoId));
  }

  @PatchMapping("/admin/work-orders/{id}/status")
  @PreAuthorize("hasAnyAuthority('ROLE_ADMIN','ROLE_SUPERADMIN','ROLE_MANAGER','ROLE_DISPATCHER','all_functions')")
  public ResponseEntity<WorkOrderDto> updateStatus(
      @PathVariable Long id,
      @RequestParam WorkOrderStatus status,
      Authentication authentication) {
    Long userId = getUserIdFromAuth(authentication);
    return ResponseEntity.ok(workOrderService.updateStatus(id, status, userId));
  }

  @PatchMapping("/technician/work-orders/{id}/status")
  @PreAuthorize("hasRole('TECHNICIAN')")
  public ResponseEntity<WorkOrderDto> technicianUpdateStatus(
      @PathVariable Long id,
      @RequestParam WorkOrderStatus status,
      Authentication authentication) {
    Long userId = getUserIdFromAuth(authentication);
    return ResponseEntity.ok(workOrderService.updateStatus(id, status, userId));
  }

  @PostMapping("/admin/work-orders/{id}/approve")
  @PreAuthorize("hasAnyAuthority('ROLE_ADMIN','ROLE_SUPERADMIN','ROLE_MANAGER','all_functions')")
  public ResponseEntity<WorkOrderDto> approveWorkOrder(
      @PathVariable Long id, Authentication authentication) {
    Long userId = getUserIdFromAuth(authentication);
    return ResponseEntity.ok(workOrderService.approveWorkOrder(id, userId));
  }

  @DeleteMapping("/admin/work-orders/{id}")
  @PreAuthorize("hasAnyAuthority('ROLE_ADMIN','ROLE_SUPERADMIN','ROLE_MANAGER','all_functions')")
  public ResponseEntity<Void> deleteWorkOrder(@PathVariable Long id) {
    workOrderService.deleteWorkOrder(id);
    return ResponseEntity.noContent().build();
  }

  @GetMapping("/admin/work-orders/stats/by-status")
  @PreAuthorize("hasAnyAuthority('ROLE_ADMIN','ROLE_SUPERADMIN','ROLE_MANAGER','ROLE_DISPATCHER','all_functions')")
  public ResponseEntity<Long> countByStatus(@RequestParam WorkOrderStatus status) {
    return ResponseEntity.ok(workOrderService.countByStatus(status));
  }

  @GetMapping("/admin/work-orders/stats/by-type")
  @PreAuthorize("hasAnyAuthority('ROLE_ADMIN','ROLE_SUPERADMIN','ROLE_MANAGER','ROLE_DISPATCHER','all_functions')")
  public ResponseEntity<Long> countByType(@RequestParam WorkOrderType type) {
    return ResponseEntity.ok(workOrderService.countByType(type));
  }

  private Long getUserIdFromAuth(Authentication authentication) {
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
