package com.svtrucking.logistics.service;

import com.svtrucking.logistics.enums.Priority;
import com.svtrucking.logistics.enums.WorkOrderType;
import com.svtrucking.logistics.model.PMSchedule;
import com.svtrucking.logistics.model.Vehicle;
import com.svtrucking.logistics.model.WorkOrder;
import com.svtrucking.logistics.repository.PMScheduleRepository;
import com.svtrucking.logistics.repository.VehicleRepository;
import com.svtrucking.logistics.repository.WorkOrderRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;

@Service
@RequiredArgsConstructor
@Slf4j
public class PMSchedulerService {

  private final PMScheduleRepository pmScheduleRepository;
  private final WorkOrderRepository workOrderRepository;
  private final VehicleRepository vehicleRepository;

  /**
   * Daily job to check for due PM schedules and auto-create work orders
   * Runs every day at 1:00 AM
   */
  @Scheduled(cron = "0 0 1 * * *")
  @Transactional
  public void checkAndCreateDuePMWorkOrders() {
    log.info("Starting daily PM schedule check...");

    try {
      List<WorkOrder> createdWorkOrders = new ArrayList<>();

      // Check date-based PM schedules
      LocalDate today = LocalDate.now();
      List<PMSchedule> overdueByDate = pmScheduleRepository.findOverdueByDate(today);
      log.info("Found {} date-based PM schedules due", overdueByDate.size());

      for (PMSchedule pmSchedule : overdueByDate) {
        WorkOrder workOrder = createWorkOrderFromPMSchedule(pmSchedule);
        if (workOrder != null) {
          createdWorkOrders.add(workOrder);
        }
      }

      // Check kilometer-based PM schedules
      List<PMSchedule> overdueByKm = pmScheduleRepository.findOverdueByKilometer();
      log.info("Found {} kilometer-based PM schedules due", overdueByKm.size());

      for (PMSchedule pmSchedule : overdueByKm) {
        WorkOrder workOrder = createWorkOrderFromPMSchedule(pmSchedule);
        if (workOrder != null) {
          createdWorkOrders.add(workOrder);
        }
      }

      log.info("Daily PM check completed. Created {} work orders.", createdWorkOrders.size());

      if (!createdWorkOrders.isEmpty()) {
        // TODO: Send notification to dispatchers/maintenance supervisors
        log.info(
            "Work orders created: {}",
            createdWorkOrders.stream().map(WorkOrder::getWoNumber).toList());
      }

    } catch (Exception e) {
      log.error("Error during PM schedule check", e);
    }
  }

  /**
   * Manually trigger PM schedule check (for testing or on-demand)
   */
  @Transactional
  public List<WorkOrder> triggerManualPMCheck() {
    log.info("Manual PM schedule check triggered");

    List<WorkOrder> createdWorkOrders = new ArrayList<>();
    LocalDate today = LocalDate.now();

    List<PMSchedule> overdueByDate = pmScheduleRepository.findOverdueByDate(today);
    List<PMSchedule> overdueByKm = pmScheduleRepository.findOverdueByKilometer();

    List<PMSchedule> allOverdue = new ArrayList<>();
    allOverdue.addAll(overdueByDate);
    allOverdue.addAll(overdueByKm);

    for (PMSchedule pmSchedule : allOverdue) {
      WorkOrder workOrder = createWorkOrderFromPMSchedule(pmSchedule);
      if (workOrder != null) {
        createdWorkOrders.add(workOrder);
      }
    }

    log.info("Manual PM check completed. Created {} work orders.", createdWorkOrders.size());
    return createdWorkOrders;
  }

  private WorkOrder createWorkOrderFromPMSchedule(PMSchedule pmSchedule) {
    try {
      Vehicle vehicle = null;

      // Get vehicle from PM schedule or find first vehicle of that type
      if (pmSchedule.getVehicle() != null) {
        vehicle = pmSchedule.getVehicle();
      } else if (pmSchedule.getVehicleType() != null) {
        vehicle =
            vehicleRepository
                .findAll()
                .stream()
                .filter(v -> v.getType().equals(pmSchedule.getVehicleType()))
                .findFirst()
                .orElse(null);
      }

      if (vehicle == null) {
        log.warn(
            "Cannot create work order for PM schedule {}: No vehicle found",
            pmSchedule.getId());
        return null;
      }

      // Check if work order already exists for this PM schedule
      boolean existingWoExists =
          workOrderRepository
              .findAll()
              .stream()
              .anyMatch(
                  wo ->
                      wo.getPmSchedule() != null
                          && wo.getPmSchedule().getId().equals(pmSchedule.getId())
                          && (wo.getStatus().name().equals("OPEN")
                              || wo.getStatus().name().equals("IN_PROGRESS")));

      if (existingWoExists) {
        log.info(
            "Work order already exists for PM schedule {}, skipping", pmSchedule.getId());
        return null;
      }

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
      log.info(
          "Auto-created work order {} for PM schedule {} ({})",
          savedWorkOrder.getWoNumber(),
          pmSchedule.getId(),
          pmSchedule.getPmName());

      return savedWorkOrder;

    } catch (Exception e) {
      log.error("Error creating work order for PM schedule {}", pmSchedule.getId(), e);
      return null;
    }
  }

  /**
   * Get upcoming PMs due in next N days
   */
  @Transactional(readOnly = true)
  public List<PMSchedule> getUpcomingPMs(int daysAhead) {
    LocalDate startDate = LocalDate.now();
    LocalDate endDate = startDate.plusDays(daysAhead);

    return pmScheduleRepository.findDueSoonByDate(startDate, endDate);
  }
}
