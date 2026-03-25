package com.svtrucking.logistics.controller;

import com.svtrucking.logistics.dto.WorkOrderDto;
import com.svtrucking.logistics.dto.WorkOrderTaskDto;
import com.svtrucking.logistics.enums.TaskStatus;
import com.svtrucking.logistics.enums.WorkOrderStatus;
import com.svtrucking.logistics.model.WorkOrderTask;
import com.svtrucking.logistics.repository.WorkOrderTaskRepository;
import com.svtrucking.logistics.repository.UserRepository;
import com.svtrucking.logistics.service.WorkOrderService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDateTime;
import java.util.List;
import java.util.stream.Collectors;

@RestController
@RequestMapping("/api/technician")
@RequiredArgsConstructor
@PreAuthorize("hasRole('TECHNICIAN')")
public class TechnicianController {

  private final WorkOrderService workOrderService;
  private final WorkOrderTaskRepository workOrderTaskRepository;
  private final UserRepository userRepository;

  @GetMapping("/work-orders")
  public ResponseEntity<List<WorkOrderDto>> getMyWorkOrders(Authentication authentication) {
    Long technicianId = getUserIdFromAuth(authentication);
    // Get work orders assigned to this technician
    List<WorkOrderDto> myWorkOrders =
        workOrderService.getAllWorkOrders(org.springframework.data.domain.Pageable.unpaged())
            .getContent()
            .stream()
            .filter(wo -> wo.getAssignedTechnicianId() != null && wo.getAssignedTechnicianId().equals(technicianId))
            .collect(Collectors.toList());
    return ResponseEntity.ok(myWorkOrders);
  }

  @GetMapping("/tasks")
  public ResponseEntity<List<WorkOrderTaskDto>> getMyTasks(Authentication authentication) {
    Long technicianId = getUserIdFromAuth(authentication);
    List<WorkOrderTask> tasks = workOrderTaskRepository.findByAssignedTechnicianId(technicianId);
    return ResponseEntity.ok(
        tasks.stream().map(WorkOrderTaskDto::fromEntity).collect(Collectors.toList()));
  }

  @GetMapping("/tasks/pending")
  public ResponseEntity<List<WorkOrderTaskDto>> getMyPendingTasks(
      Authentication authentication) {
    Long technicianId = getUserIdFromAuth(authentication);
    List<WorkOrderTask> tasks =
        workOrderTaskRepository.findTechnicianPendingTasks(technicianId);
    return ResponseEntity.ok(
        tasks.stream().map(WorkOrderTaskDto::fromEntity).collect(Collectors.toList()));
  }

  @PatchMapping("/tasks/{taskId}/status")
  public ResponseEntity<WorkOrderTaskDto> updateTaskStatus(
      @PathVariable Long taskId, @RequestParam TaskStatus status) {
    WorkOrderTask task =
        workOrderTaskRepository
            .findById(taskId)
            .orElseThrow(() -> new RuntimeException("Task not found with id: " + taskId));

    task.setStatus(status);
    if (status == TaskStatus.COMPLETED) {
      task.setCompletedAt(LocalDateTime.now());
    }

    WorkOrderTask updated = workOrderTaskRepository.save(task);
    return ResponseEntity.ok(WorkOrderTaskDto.fromEntity(updated));
  }

  @PatchMapping("/tasks/{taskId}/hours")
  public ResponseEntity<WorkOrderTaskDto> updateTaskHours(
      @PathVariable Long taskId, @RequestParam Double actualHours) {
    WorkOrderTask task =
        workOrderTaskRepository
            .findById(taskId)
            .orElseThrow(() -> new RuntimeException("Task not found with id: " + taskId));

    task.setActualHours(actualHours);
    WorkOrderTask updated = workOrderTaskRepository.save(task);
    return ResponseEntity.ok(WorkOrderTaskDto.fromEntity(updated));
  }

  @PatchMapping("/work-orders/{woId}/status")
  public ResponseEntity<WorkOrderDto> updateMyWorkOrderStatus(
      @PathVariable Long woId,
      @RequestParam WorkOrderStatus status,
      Authentication authentication) {
    Long technicianId = getUserIdFromAuth(authentication);
    return ResponseEntity.ok(workOrderService.updateStatus(woId, status, technicianId));
  }

  @GetMapping("/work-orders/{woId}")
  public ResponseEntity<WorkOrderDto> getMyWorkOrderDetails(@PathVariable Long woId) {
    return ResponseEntity.ok(workOrderService.getWorkOrderById(woId));
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
