package com.svtrucking.logistics.controller;

import com.svtrucking.logistics.dto.PMScheduleDto;
import com.svtrucking.logistics.dto.WorkOrderDto;
import com.svtrucking.logistics.repository.UserRepository;
import com.svtrucking.logistics.service.PMScheduleService;
import com.svtrucking.logistics.service.PMSchedulerService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDate;
import java.util.List;

@RestController
@RequestMapping("/api/admin/pm-schedules")
@RequiredArgsConstructor
@PreAuthorize("hasAnyAuthority('ROLE_ADMIN','ROLE_SUPERADMIN','ROLE_MANAGER','ROLE_DISPATCHER','all_functions')")
public class PMScheduleController {

  private final PMScheduleService pmScheduleService;
  private final PMSchedulerService pmSchedulerService;
  private final UserRepository userRepository;

  @GetMapping
  public ResponseEntity<Page<PMScheduleDto>> getAllSchedules(
      @RequestParam(required = false) Boolean active, Pageable pageable) {
    return ResponseEntity.ok(pmScheduleService.getAllSchedules(active, pageable));
  }

  @GetMapping("/vehicle/{vehicleId}")
  public ResponseEntity<List<PMScheduleDto>> getSchedulesByVehicle(@PathVariable Long vehicleId) {
    return ResponseEntity.ok(pmScheduleService.getSchedulesByVehicle(vehicleId));
  }

  @GetMapping("/vehicle-type/{vehicleType}")
  public ResponseEntity<List<PMScheduleDto>> getSchedulesByVehicleType(
      @PathVariable String vehicleType) {
    return ResponseEntity.ok(pmScheduleService.getSchedulesByVehicleType(vehicleType));
  }

  @GetMapping("/overdue")
  public ResponseEntity<List<PMScheduleDto>> getOverdueSchedules() {
    return ResponseEntity.ok(pmScheduleService.getOverdueSchedules());
  }

  @GetMapping("/due-soon")
  public ResponseEntity<List<PMScheduleDto>> getDueSoonSchedules(
      @RequestParam(defaultValue = "7") int daysAhead) {
    return ResponseEntity.ok(pmScheduleService.getDueSoonSchedules(daysAhead));
  }

  @GetMapping("/{id}")
  public ResponseEntity<PMScheduleDto> getScheduleById(@PathVariable Long id) {
    return ResponseEntity.ok(pmScheduleService.getScheduleById(id));
  }

  @PostMapping
  @PreAuthorize("hasAnyRole('ADMIN', 'MANAGER')")
  public ResponseEntity<PMScheduleDto> createSchedule(
      @Valid @RequestBody PMScheduleDto scheduleDto, Authentication authentication) {
    Long userId = getUserIdFromAuth(authentication);
    PMScheduleDto created = pmScheduleService.createSchedule(scheduleDto, userId);
    return ResponseEntity.status(HttpStatus.CREATED).body(created);
  }

  @PutMapping("/{id}")
  @PreAuthorize("hasAnyRole('ADMIN', 'MANAGER')")
  public ResponseEntity<PMScheduleDto> updateSchedule(
      @PathVariable Long id, @Valid @RequestBody PMScheduleDto scheduleDto) {
    return ResponseEntity.ok(pmScheduleService.updateSchedule(id, scheduleDto));
  }

  @PostMapping("/{id}/create-work-order")
  @PreAuthorize("hasAnyRole('ADMIN', 'MANAGER', 'DISPATCHER')")
  public ResponseEntity<WorkOrderDto> createWorkOrderFromPM(
      @PathVariable Long id, Authentication authentication) {
    Long userId = getUserIdFromAuth(authentication);
    WorkOrderDto created = pmScheduleService.createWorkOrderFromPM(id, userId);
    return ResponseEntity.status(HttpStatus.CREATED).body(created);
  }

  @PostMapping("/{id}/record-completion")
  @PreAuthorize("hasAnyRole('ADMIN', 'MANAGER')")
  public ResponseEntity<Void> recordPMCompletion(
      @PathVariable Long id,
      @RequestParam Long workOrderId,
      @RequestParam(required = false) Integer performedAtKm,
      @RequestParam(required = false) LocalDate performedDate,
      @RequestParam(required = false) Integer performedEngineHours) {
    pmScheduleService.recordPMCompletion(
        id, workOrderId, performedAtKm, performedDate, performedEngineHours);
    return ResponseEntity.ok().build();
  }

  @PatchMapping("/{id}/deactivate")
  @PreAuthorize("hasAnyRole('ADMIN', 'MANAGER')")
  public ResponseEntity<Void> deactivateSchedule(@PathVariable Long id) {
    pmScheduleService.deactivateSchedule(id);
    return ResponseEntity.noContent().build();
  }

  @DeleteMapping("/{id}")
  @PreAuthorize("hasRole('ADMIN')")
  public ResponseEntity<Void> deleteSchedule(@PathVariable Long id) {
    pmScheduleService.deleteSchedule(id);
    return ResponseEntity.noContent().build();
  }

  @PostMapping("/trigger-check")
  @PreAuthorize("hasRole('ADMIN')")
  public ResponseEntity<List<WorkOrderDto>> triggerManualPMCheck() {
    List<com.svtrucking.logistics.model.WorkOrder> workOrders = pmSchedulerService.triggerManualPMCheck();
    List<WorkOrderDto> dtos =
        workOrders.stream().map(wo -> WorkOrderDto.fromEntity(wo, true)).toList();
    return ResponseEntity.ok(dtos);
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
