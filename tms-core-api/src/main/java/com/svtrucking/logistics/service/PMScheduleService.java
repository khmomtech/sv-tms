package com.svtrucking.logistics.service;

import com.svtrucking.logistics.dto.PMScheduleDto;
import com.svtrucking.logistics.dto.WorkOrderDto;
import com.svtrucking.logistics.enums.PMTriggerType;
import com.svtrucking.logistics.enums.Priority;
import com.svtrucking.logistics.enums.WorkOrderType;
import com.svtrucking.logistics.exception.ResourceNotFoundException;
import com.svtrucking.logistics.model.*;
import com.svtrucking.logistics.repository.*;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.List;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
@Slf4j
public class PMScheduleService {

  private final PMScheduleRepository pmScheduleRepository;
  private final VehicleRepository vehicleRepository;
  private final MaintenanceTaskTypeRepository maintenanceTaskTypeRepository;
  private final UserRepository userRepository;
  private final WorkOrderRepository workOrderRepository;
  private final PMScheduleHistoryRepository pmScheduleHistoryRepository;

  @Transactional(readOnly = true)
  public Page<PMScheduleDto> getAllSchedules(Boolean active, Pageable pageable) {
    if (active == null) {
      return pmScheduleRepository.findByIsDeletedFalse(pageable).map(PMScheduleDto::fromEntity);
    }
    return pmScheduleRepository.findByActiveAndIsDeletedFalse(active, pageable).map(PMScheduleDto::fromEntity);
  }

  @Transactional(readOnly = true)
  public List<PMScheduleDto> getSchedulesByVehicle(Long vehicleId) {
    return pmScheduleRepository
        .findByVehicleIdAndActiveAndIsDeletedFalse(vehicleId, true)
        .stream()
        .map(PMScheduleDto::fromEntity)
        .collect(Collectors.toList());
  }

  @Transactional(readOnly = true)
  public List<PMScheduleDto> getSchedulesByVehicleType(String vehicleType) {
    return pmScheduleRepository
        .findByVehicleTypeAndActiveAndIsDeletedFalse(vehicleType, true)
        .stream()
        .map(PMScheduleDto::fromEntity)
        .collect(Collectors.toList());
  }

  @Transactional(readOnly = true)
  public List<PMScheduleDto> getOverdueSchedules() {
    LocalDate today = LocalDate.now();
    List<PMSchedule> overdueByDate = pmScheduleRepository.findOverdueByDate(today);
    List<PMSchedule> overdueByKm = pmScheduleRepository.findOverdueByKilometer();

    List<PMSchedule> allOverdue =
        java.util.stream.Stream.concat(overdueByDate.stream(), overdueByKm.stream())
            .distinct()
            .collect(Collectors.toList());

    return allOverdue.stream().map(PMScheduleDto::fromEntity).collect(Collectors.toList());
  }

  @Transactional(readOnly = true)
  public List<PMScheduleDto> getDueSoonSchedules(int daysAhead) {
    LocalDate startDate = LocalDate.now();
    LocalDate endDate = startDate.plusDays(daysAhead);

    return pmScheduleRepository.findDueSoonByDate(startDate, endDate).stream()
        .map(PMScheduleDto::fromEntity)
        .collect(Collectors.toList());
  }

  @Transactional(readOnly = true)
  public PMScheduleDto getScheduleById(Long id) {
    PMSchedule schedule =
        pmScheduleRepository
            .findById(id)
            .orElseThrow(() -> new ResourceNotFoundException("PM schedule not found with id: " + id));
    return PMScheduleDto.fromEntity(schedule);
  }

  @Transactional
  public PMScheduleDto createSchedule(PMScheduleDto dto, Long createdById) {
    log.info("Creating PM schedule: {}", dto.getPmName());

    User createdBy =
        userRepository
            .findById(createdById)
            .orElseThrow(() -> new RuntimeException("User not found with id: " + createdById));

    PMSchedule schedule = dto.toEntity();
    schedule.setCreatedBy(createdBy);

    // Link to vehicle if provided
    if (dto.getVehicleId() != null) {
      Vehicle vehicle =
          vehicleRepository
              .findById(dto.getVehicleId())
              .orElseThrow(
                  () -> new RuntimeException("Vehicle not found with id: " + dto.getVehicleId()));
      schedule.setVehicle(vehicle);
    }

    // Link to maintenance task type if provided
    if (dto.getMaintenanceTaskTypeId() != null) {
      MaintenanceTaskType taskType =
          maintenanceTaskTypeRepository
              .findById(dto.getMaintenanceTaskTypeId())
              .orElseThrow(
                  () ->
                      new RuntimeException(
                          "Maintenance task type not found with id: "
                              + dto.getMaintenanceTaskTypeId()));
      schedule.setMaintenanceTaskType(taskType);
    }

    PMSchedule savedSchedule = pmScheduleRepository.save(schedule);
    log.info("Created PM schedule with ID: {}", savedSchedule.getId());

    return PMScheduleDto.fromEntity(savedSchedule);
  }

  @Transactional
  public PMScheduleDto updateSchedule(Long id, PMScheduleDto dto) {
    log.info("Updating PM schedule: {}", id);

    PMSchedule schedule =
        pmScheduleRepository
            .findById(id)
            .orElseThrow(() -> new ResourceNotFoundException("PM schedule not found with id: " + id));

    schedule.setPmName(dto.getPmName());
    schedule.setDescription(dto.getDescription());
    schedule.setTriggerType(dto.getTriggerType());
    schedule.setIntervalKm(dto.getIntervalKm());
    schedule.setIntervalDays(dto.getIntervalDays());
    schedule.setIntervalEngineHours(dto.getIntervalEngineHours());
    schedule.setNextDueKm(dto.getNextDueKm());
    schedule.setNextDueDate(dto.getNextDueDate());
    schedule.setNextDueEngineHours(dto.getNextDueEngineHours());
    schedule.setActive(dto.getActive());

    PMSchedule updatedSchedule = pmScheduleRepository.save(schedule);
    return PMScheduleDto.fromEntity(updatedSchedule);
  }

  @Transactional
  public WorkOrderDto createWorkOrderFromPM(Long pmScheduleId, Long createdById) {
    log.info("Creating work order from PM schedule: {}", pmScheduleId);

    PMSchedule pmSchedule =
        pmScheduleRepository
            .findById(pmScheduleId)
            .orElseThrow(
                () -> new ResourceNotFoundException("PM schedule not found with id: " + pmScheduleId));

    Vehicle vehicle =
        pmSchedule.getVehicle() != null
            ? pmSchedule.getVehicle()
            : vehicleRepository
                .findAll()
                .stream()
                .filter(v -> v.getType().equals(pmSchedule.getVehicleType()))
                .findFirst()
                .orElseThrow(
                    () ->
                        new RuntimeException(
                            "No vehicle found for type: " + pmSchedule.getVehicleType()));

    WorkOrder workOrder =
        WorkOrder.builder()
            .vehicle(vehicle)
            .type(WorkOrderType.PREVENTIVE)
            .priority(Priority.NORMAL)
            .title(pmSchedule.getPmName())
            .description(pmSchedule.getDescription())
            .scheduledDate(LocalDateTime.now())
            .pmSchedule(pmSchedule)
            .requiresApproval(false)
            .approved(true)
            .isDeleted(false)
            .build();

    // WO number generated automatically in @PrePersist

    WorkOrder savedWorkOrder = workOrderRepository.save(workOrder);
    log.info("Created work order {} from PM schedule {}", savedWorkOrder.getWoNumber(), pmScheduleId);

    return WorkOrderDto.fromEntity(savedWorkOrder, true);
  }

  @Transactional
  public void recordPMCompletion(Long pmScheduleId, Long workOrderId, Integer performedAtKm, LocalDate performedDate, Integer performedEngineHours) {
    log.info("Recording PM completion for schedule: {}", pmScheduleId);

    PMSchedule schedule =
        pmScheduleRepository
            .findById(pmScheduleId)
            .orElseThrow(
                () -> new ResourceNotFoundException("PM schedule not found with id: " + pmScheduleId));

    WorkOrder workOrder =
        workOrderRepository
            .findById(workOrderId)
            .orElseThrow(() -> new RuntimeException("Work order not found with id: " + workOrderId));

    // Create history record
    PMScheduleHistory history =
        PMScheduleHistory.builder()
            .pmSchedule(schedule)
            .workOrder(workOrder)
            .vehicle(schedule.getVehicle())
            .performedAt(LocalDateTime.now())
            .performedKm(performedAtKm)
            .performedEngineHours(performedEngineHours)
            .build();

    pmScheduleHistoryRepository.save(history);

    // Update PM schedule next due
    schedule.setLastPerformedKm(performedAtKm);
    schedule.setLastPerformedDate(performedDate);
    schedule.setLastPerformedEngineHours(performedEngineHours);

    if (schedule.getTriggerType() == PMTriggerType.KILOMETER && schedule.getIntervalKm() != null) {
      schedule.setNextDueKm(performedAtKm + schedule.getIntervalKm());
    } else if (schedule.getTriggerType() == PMTriggerType.DATE && schedule.getIntervalDays() != null) {
      schedule.setNextDueDate(performedDate.plusDays(schedule.getIntervalDays()));
    } else if (schedule.getTriggerType() == PMTriggerType.ENGINE_HOUR && schedule.getIntervalEngineHours() != null) {
      schedule.setNextDueEngineHours(performedEngineHours + schedule.getIntervalEngineHours());
    }

    pmScheduleRepository.save(schedule);
    log.info("Updated PM schedule next due dates for schedule: {}", pmScheduleId);
  }

  @Transactional
  public void deactivateSchedule(Long id) {
    log.info("Deactivating PM schedule: {}", id);

    PMSchedule schedule =
        pmScheduleRepository
            .findById(id)
            .orElseThrow(() -> new ResourceNotFoundException("PM schedule not found with id: " + id));

    schedule.setActive(false);
    pmScheduleRepository.save(schedule);
  }

  @Transactional
  public void deleteSchedule(Long id) {
    log.info("Soft deleting PM schedule: {}", id);

    PMSchedule schedule =
        pmScheduleRepository
            .findById(id)
            .orElseThrow(() -> new ResourceNotFoundException("PM schedule not found with id: " + id));

    schedule.setIsDeleted(true);
    pmScheduleRepository.save(schedule);
  }
}
