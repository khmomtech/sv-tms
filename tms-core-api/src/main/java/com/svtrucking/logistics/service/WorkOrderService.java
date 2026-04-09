package com.svtrucking.logistics.service;

import com.svtrucking.logistics.dto.WorkOrderDto;
import com.svtrucking.logistics.dto.WorkOrderPartDto;
import com.svtrucking.logistics.dto.WorkOrderPhotoDto;
import com.svtrucking.logistics.dto.WorkOrderTaskDto;
import com.svtrucking.logistics.enums.Priority;
import com.svtrucking.logistics.enums.MaintenanceRequestStatus;
import com.svtrucking.logistics.enums.RepairType;
import com.svtrucking.logistics.enums.WorkOrderStatus;
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

import java.time.LocalDateTime;
import java.util.List;

@Service
@RequiredArgsConstructor
@Slf4j
public class WorkOrderService {

  private final WorkOrderRepository workOrderRepository;
  private final VehicleRepository vehicleRepository;
  private final UserRepository userRepository;
  private final DriverIssueRepository driverIssueRepository;
  private final PMScheduleRepository pmScheduleRepository;
  private final WorkOrderTaskRepository workOrderTaskRepository;
  private final WorkOrderPartRepository workOrderPartRepository;
  private final WorkOrderPhotoRepository workOrderPhotoRepository;
  private final PartsMasterRepository partsMasterRepository;
  private final MaintenanceRequestRepository maintenanceRequestRepository;
  private final VendorQuotationRepository vendorQuotationRepository;
  private final InvoiceRepository invoiceRepository;

  /**
   * Generates a unique work order number in format: WO-YYYY-XXXXX
   */
  private synchronized String generateWorkOrderNumber() {
    int year = LocalDateTime.now().getYear();
    String yearPrefix = "WO-" + year + "-%";
    Integer maxNumber = workOrderRepository.findMaxWoNumberForYear(yearPrefix);
    int nextNumber = (maxNumber == null) ? 1 : maxNumber + 1;
    return String.format("WO-%d-%05d", year, nextNumber);
  }

  @Transactional(readOnly = true)
  public Page<WorkOrderDto> getAllWorkOrders(Pageable pageable) {
    return workOrderRepository
        .findByIsDeletedFalse(pageable)
        .map(wo -> hydrateStandardFields(WorkOrderDto.fromEntity(wo)));
  }

  @Transactional(readOnly = true)
  public Page<WorkOrderDto> filterWorkOrders(
      WorkOrderStatus status,
      WorkOrderType type,
      Priority priority,
      Long vehicleId,
      Long technicianId,
      LocalDateTime scheduledAfter,
      LocalDateTime scheduledBefore,
      Pageable pageable) {
    return workOrderRepository
        .filterWorkOrders(
            status, type, priority, vehicleId, technicianId, scheduledAfter, scheduledBefore, pageable)
        .map(wo -> hydrateStandardFields(WorkOrderDto.fromEntity(wo)));
  }

  @Transactional(readOnly = true)
  public List<WorkOrderDto> getUrgentWorkOrders() {
    return workOrderRepository.findUrgentWorkOrders().stream()
        .map(WorkOrderDto::fromEntity)
        .toList();
  }

  @Transactional(readOnly = true)
  public List<WorkOrderDto> getPendingApproval() {
    return workOrderRepository.findPendingApproval().stream()
        .map(wo -> WorkOrderDto.fromEntity(wo, true))
        .toList();
  }

  @Transactional(readOnly = true)
  public WorkOrderDto getWorkOrderById(Long id) {
    WorkOrder workOrder =
        workOrderRepository
            .findById(id)
            .orElseThrow(() -> new ResourceNotFoundException("Work order not found with id: " + id));
    return hydrateStandardFields(WorkOrderDto.fromEntity(workOrder, true));
  }

  @Transactional
  public WorkOrderDto createWorkOrder(WorkOrderDto dto, Long createdById) {
    log.info("Creating work order: {} for vehicle: {}", dto.getTitle(), dto.getVehicleId());

    // SV Standard enforcement for REPAIR/EMERGENCY types created via generic endpoint.
    if ((dto.getType() == WorkOrderType.REPAIR || dto.getType() == WorkOrderType.EMERGENCY)
        && dto.getMaintenanceRequestId() == null) {
      throw new IllegalStateException("Work orders of type REPAIR/EMERGENCY require an approved Maintenance Request.");
    }

    Vehicle vehicle =
        vehicleRepository
            .findById(dto.getVehicleId())
            .orElseThrow(
                () -> new RuntimeException("Vehicle not found with id: " + dto.getVehicleId()));

    MaintenanceRequest mr = null;
    if (dto.getMaintenanceRequestId() != null) {
      mr =
          maintenanceRequestRepository
              .findById(dto.getMaintenanceRequestId())
              .orElseThrow(
                  () ->
                      new ResourceNotFoundException(
                          "Maintenance request not found with id: " + dto.getMaintenanceRequestId()));
      if (mr.getStatus() != MaintenanceRequestStatus.APPROVED) {
        throw new IllegalStateException("Maintenance request must be APPROVED before creating a work order.");
      }
    }

    WorkOrder workOrder =
        WorkOrder.builder()
            .vehicle(vehicle)
            .maintenanceRequest(mr)
            .type(dto.getType())
            .priority(dto.getPriority())
            .status(WorkOrderStatus.OPEN)
            .title(dto.getTitle())
            .description(dto.getDescription())
            .repairType(dto.getRepairType())
            .scheduledDate(dto.getScheduledDate())
            .estimatedCost(dto.getEstimatedCost() != null ? java.math.BigDecimal.valueOf(dto.getEstimatedCost()) : null)
            .requiresApproval(false)
            .approved(false)
            .isDeleted(false)
            .build();

    // Generate WO number
    workOrder.setWoNumber(generateWorkOrderNumber());

    // Link to driver issue if provided
    if (dto.getDriverIssueId() != null) {
      DriverIssue issue =
          driverIssueRepository
              .findById(dto.getDriverIssueId())
              .orElseThrow(
                  () ->
                      new RuntimeException(
                          "Driver issue not found with id: " + dto.getDriverIssueId()));
      workOrder.setDriverIssue(issue);
    }

    // Link to PM schedule if provided
    if (dto.getPmScheduleId() != null) {
      PMSchedule pmSchedule =
          pmScheduleRepository
              .findById(dto.getPmScheduleId())
              .orElseThrow(
                  () ->
                      new RuntimeException("PM schedule not found with id: " + dto.getPmScheduleId()));
      workOrder.setPmSchedule(pmSchedule);
    }

    // Assign technician if provided
    if (dto.getAssignedTechnicianId() != null) {
      User technician =
          userRepository
              .findById(dto.getAssignedTechnicianId())
              .orElseThrow(
                  () ->
                      new RuntimeException(
                          "Technician not found with id: " + dto.getAssignedTechnicianId()));
      workOrder.setAssignedTechnician(technician);
      workOrder.setStatus(WorkOrderStatus.IN_PROGRESS);
    }

    WorkOrder savedWorkOrder = workOrderRepository.save(workOrder);
    log.info("Created work order with WO#: {}", savedWorkOrder.getWoNumber());

    return hydrateStandardFields(WorkOrderDto.fromEntity(savedWorkOrder, true));
  }

  @Transactional
  public WorkOrderDto updateWorkOrder(Long id, WorkOrderDto dto, Long userId) {
    WorkOrder workOrder = getActiveWorkOrder(id);

    if (dto.getTitle() != null) workOrder.setTitle(dto.getTitle());
    if (dto.getDescription() != null) workOrder.setDescription(dto.getDescription());
    if (dto.getPriority() != null) workOrder.setPriority(dto.getPriority());
    if (dto.getType() != null) workOrder.setType(dto.getType());
    if (dto.getRepairType() != null) workOrder.setRepairType(dto.getRepairType());
    if (dto.getScheduledDate() != null) workOrder.setScheduledDate(dto.getScheduledDate());
    if (dto.getEstimatedCost() != null) {
      workOrder.setEstimatedCost(java.math.BigDecimal.valueOf(dto.getEstimatedCost()));
    }
    workOrder.setUpdatedAt(LocalDateTime.now());

    WorkOrder saved = workOrderRepository.save(workOrder);
    return hydrateStandardFields(WorkOrderDto.fromEntity(saved, true));
  }

  @Transactional
  public WorkOrderDto addTaskToWorkOrder(Long workOrderId, WorkOrderTaskDto taskDto) {
    log.info("Adding task to work order: {}", workOrderId);

    WorkOrder workOrder = getActiveWorkOrder(workOrderId);
    if (taskDto.getWorkOrderId() != null && !taskDto.getWorkOrderId().equals(workOrderId)) {
      throw new IllegalArgumentException("Work order ID in request does not match URL.");
    }

    WorkOrderTask task =
        WorkOrderTask.builder()
            .workOrder(workOrder)
            .category(taskDto.getTaskName())
            .description(taskDto.getDescription())
            .estimatedHours(taskDto.getEstimatedHours())
            .actualHours(taskDto.getActualHours())
            .notes(taskDto.getNotes())
            .diagnosisResult(taskDto.getDiagnosisResult())
            .actionsTaken(taskDto.getActionsTaken())
            .build();

    if (taskDto.getAssignedTechnicianId() != null) {
      User technician =
          userRepository
              .findById(taskDto.getAssignedTechnicianId())
              .orElseThrow(
                  () ->
                      new RuntimeException(
                          "Technician not found with id: " + taskDto.getAssignedTechnicianId()));
      task.setAssignedTechnician(technician);
    }

    if (taskDto.getEstimatedHours() != null && taskDto.getEstimatedHours() < 0) {
      throw new IllegalArgumentException("Estimated hours must be greater than or equal to 0.");
    }
    if (taskDto.getActualHours() != null && taskDto.getActualHours() < 0) {
      throw new IllegalArgumentException("Actual hours must be greater than or equal to 0.");
    }

    normalizeTaskStatus(task, taskDto.getStatus(), taskDto.getStartedAt(), taskDto.getCompletedAt());

    if (task.getStatus() == com.svtrucking.logistics.enums.TaskStatus.IN_PROGRESS
        && workOrder.getStatus() == WorkOrderStatus.OPEN) {
      workOrder.setStatus(WorkOrderStatus.IN_PROGRESS);
      if (workOrder.getStartedAt() == null) {
        workOrder.setStartedAt(LocalDateTime.now());
      }
    }

    workOrder.addTask(task);
    workOrderRepository.save(workOrder);

    return hydrateStandardFields(WorkOrderDto.fromEntity(workOrder, true));
  }

  @Transactional
  public WorkOrderDto updateWorkOrderTask(Long workOrderId, Long taskId, WorkOrderTaskDto taskDto) {
    getActiveWorkOrder(workOrderId);
    WorkOrderTask task =
        workOrderTaskRepository
            .findByIdAndWorkOrderId(taskId, workOrderId)
            .orElseThrow(
                () ->
                    new ResourceNotFoundException(
                        "Task not found with id: " + taskId + " for work order: " + workOrderId));

    if (taskDto.getTaskName() != null) task.setTaskName(taskDto.getTaskName());
    if (taskDto.getDescription() != null) task.setDescription(taskDto.getDescription());
    if (taskDto.getEstimatedHours() != null) {
      if (taskDto.getEstimatedHours() < 0) {
        throw new IllegalArgumentException("Estimated hours must be greater than or equal to 0.");
      }
      task.setEstimatedHours(taskDto.getEstimatedHours());
    }
    if (taskDto.getActualHours() != null) {
      if (taskDto.getActualHours() < 0) {
        throw new IllegalArgumentException("Actual hours must be greater than or equal to 0.");
      }
      task.setActualHours(taskDto.getActualHours());
    }
    if (taskDto.getNotes() != null) task.setNotes(taskDto.getNotes());
    if (taskDto.getDiagnosisResult() != null) task.setDiagnosisResult(taskDto.getDiagnosisResult());
    if (taskDto.getActionsTaken() != null) task.setActionsTaken(taskDto.getActionsTaken());

    if (taskDto.getAssignedTechnicianId() != null) {
      User technician =
          userRepository
              .findById(taskDto.getAssignedTechnicianId())
              .orElseThrow(
                  () ->
                      new RuntimeException(
                          "Technician not found with id: " + taskDto.getAssignedTechnicianId()));
      task.setAssignedTechnician(technician);
    }

    normalizeTaskStatus(task, taskDto.getStatus(), taskDto.getStartedAt(), taskDto.getCompletedAt());

    workOrderTaskRepository.save(task);
    WorkOrder workOrder = getActiveWorkOrder(workOrderId);
    return hydrateStandardFields(WorkOrderDto.fromEntity(workOrder, true));
  }

  @Transactional
  public WorkOrderDto deleteWorkOrderTask(Long workOrderId, Long taskId) {
    getActiveWorkOrder(workOrderId);
    WorkOrderTask task =
        workOrderTaskRepository
            .findByIdAndWorkOrderId(taskId, workOrderId)
            .orElseThrow(
                () ->
                    new ResourceNotFoundException(
                        "Task not found with id: " + taskId + " for work order: " + workOrderId));
    if (workOrderPartRepository.existsByTaskId(taskId) || workOrderPhotoRepository.existsByTaskId(taskId)) {
      throw new IllegalArgumentException("Task cannot be deleted while parts or photos are linked. Remove them first.");
    }
    workOrderTaskRepository.delete(task);
    WorkOrder workOrder = getActiveWorkOrder(workOrderId);
    return hydrateStandardFields(WorkOrderDto.fromEntity(workOrder, true));
  }

  @Transactional
  public WorkOrderDto addPartToWorkOrder(Long workOrderId, WorkOrderPartDto partDto, Long userId) {
    log.info("Adding part to work order: {}", workOrderId);

    WorkOrder workOrder = getActiveWorkOrder(workOrderId);
    if (partDto.getWorkOrderId() != null && !partDto.getWorkOrderId().equals(workOrderId)) {
      throw new IllegalArgumentException("Work order ID in request does not match URL.");
    }

    PartsMaster part =
        partsMasterRepository
            .findById(partDto.getPartId())
            .orElseThrow(() -> new RuntimeException("Part not found with id: " + partDto.getPartId()));

    WorkOrderTask task = null;
    if (partDto.getTaskId() != null) {
      task =
          workOrderTaskRepository
              .findByIdAndWorkOrderId(partDto.getTaskId(), workOrderId)
              .orElseThrow(
                  () ->
                      new ResourceNotFoundException(
                          "Task not found with id: " + partDto.getTaskId() + " for work order: " + workOrderId));
    }

    User addedBy = null;
    if (userId != null) {
      addedBy =
          userRepository
              .findById(userId)
              .orElseThrow(() -> new RuntimeException("User not found with id: " + userId));
    }

    WorkOrderPart woPart =
        WorkOrderPart.builder()
            .workOrder(workOrder)
            .task(task)
            .part(part)
            .quantity(partDto.getQuantity() != null ? partDto.getQuantity().intValue() : 1)
            .unitCost(partDto.getUnitPrice() != null ? java.math.BigDecimal.valueOf(partDto.getUnitPrice()) : part.getUnitPrice())
            .notes(partDto.getNotes())
            .addedBy(addedBy)
            .build();

    workOrder.getParts().add(woPart);

    // Update total cost
    recalculatePartsCost(workOrder);

    workOrderRepository.save(workOrder);

    return hydrateStandardFields(WorkOrderDto.fromEntity(workOrder, true));
  }

  @Transactional
  public WorkOrderDto deleteWorkOrderPart(Long workOrderId, Long partId) {
    getActiveWorkOrder(workOrderId);
    WorkOrderPart part =
        workOrderPartRepository
            .findByIdAndWorkOrderId(partId, workOrderId)
            .orElseThrow(
                () ->
                    new ResourceNotFoundException(
                        "Part not found with id: " + partId + " for work order: " + workOrderId));
    workOrderPartRepository.delete(part);
    WorkOrder workOrder = getActiveWorkOrder(workOrderId);
    recalculatePartsCost(workOrder);
    workOrderRepository.save(workOrder);
    return hydrateStandardFields(WorkOrderDto.fromEntity(workOrder, true));
  }

  @Transactional
  public WorkOrderDto addPhotoToWorkOrder(Long workOrderId, WorkOrderPhotoDto photoDto, Long userId) {
    WorkOrder workOrder = getActiveWorkOrder(workOrderId);
    if (photoDto.getWorkOrderId() != null && !photoDto.getWorkOrderId().equals(workOrderId)) {
      throw new IllegalArgumentException("Work order ID in request does not match URL.");
    }

    WorkOrderTask task = null;
    if (photoDto.getTaskId() != null) {
      task =
          workOrderTaskRepository
              .findByIdAndWorkOrderId(photoDto.getTaskId(), workOrderId)
              .orElseThrow(
                  () ->
                      new ResourceNotFoundException(
                          "Task not found with id: " + photoDto.getTaskId() + " for work order: " + workOrderId));
    }

    User uploader = null;
    if (userId != null) {
      uploader =
          userRepository
              .findById(userId)
              .orElseThrow(() -> new RuntimeException("User not found with id: " + userId));
    }

    WorkOrderPhoto photo =
        WorkOrderPhoto.builder()
            .workOrder(workOrder)
            .task(task)
            .photoUrl(photoDto.getPhotoUrl())
            .photoType(photoDto.getPhotoType())
            .description(photoDto.getDescription())
            .uploadedBy(uploader)
            .build();

    workOrder.getPhotos().add(photo);
    workOrderRepository.save(workOrder);
    return hydrateStandardFields(WorkOrderDto.fromEntity(workOrder, true));
  }

  @Transactional
  public WorkOrderDto deleteWorkOrderPhoto(Long workOrderId, Long photoId) {
    getActiveWorkOrder(workOrderId);
    WorkOrderPhoto photo =
        workOrderPhotoRepository
            .findByIdAndWorkOrderId(photoId, workOrderId)
            .orElseThrow(
                () ->
                    new ResourceNotFoundException(
                        "Photo not found with id: " + photoId + " for work order: " + workOrderId));
    workOrderPhotoRepository.delete(photo);
    WorkOrder workOrder = getActiveWorkOrder(workOrderId);
    return hydrateStandardFields(WorkOrderDto.fromEntity(workOrder, true));
  }

  @Transactional
  public WorkOrderDto updateStatus(Long workOrderId, WorkOrderStatus newStatus, Long userId) {
    log.info("Updating work order {} status to: {}", workOrderId, newStatus);

    WorkOrder workOrder = getActiveWorkOrder(workOrderId);

    workOrder.setStatus(newStatus);

    if (newStatus == WorkOrderStatus.COMPLETED) {
      workOrder.setCompletedAt(LocalDateTime.now());

      // Update PM schedule if linked
      if (workOrder.getPmSchedule() != null) {
        PMSchedule pmSchedule = workOrder.getPmSchedule();
        // PM schedule update logic handled by PMScheduleService
      }
    }

    WorkOrder updatedWorkOrder = workOrderRepository.save(workOrder);
    return hydrateStandardFields(WorkOrderDto.fromEntity(updatedWorkOrder, true));
  }

  @Transactional
  public WorkOrderDto approveWorkOrder(Long workOrderId, Long approvedById) {
    log.info("Approving work order: {} by user: {}", workOrderId, approvedById);

    WorkOrder workOrder = getActiveWorkOrder(workOrderId);

    User approver =
        userRepository
            .findById(approvedById)
            .orElseThrow(() -> new RuntimeException("Approver not found with id: " + approvedById));

    workOrder.setApproved(true);
    workOrder.setApprovedBy(approver);
    workOrder.setApprovedAt(LocalDateTime.now());

    WorkOrder updatedWorkOrder = workOrderRepository.save(workOrder);
    return WorkOrderDto.fromEntity(updatedWorkOrder, true);
  }

  @Transactional
  public void deleteWorkOrder(Long workOrderId) {
    log.info("Soft deleting work order: {}", workOrderId);

    WorkOrder workOrder =
        workOrderRepository
            .findById(workOrderId)
            .orElseThrow(() -> new ResourceNotFoundException("Work order not found with id: " + workOrderId));

    workOrder.setIsDeleted(true);
    workOrderRepository.save(workOrder);
  }

  @Transactional(readOnly = true)
  public Long countByStatus(WorkOrderStatus status) {
    return workOrderRepository.countByStatusAndIsDeletedFalse(status);
  }

  @Transactional(readOnly = true)
  public Long countByType(WorkOrderType type) {
    return workOrderRepository.countByTypeAndIsDeletedFalse(type);
  }

  private WorkOrder getActiveWorkOrder(Long workOrderId) {
    WorkOrder workOrder =
        workOrderRepository
            .findById(workOrderId)
            .orElseThrow(
                () -> new ResourceNotFoundException("Work order not found with id: " + workOrderId));
    if (Boolean.TRUE.equals(workOrder.getIsDeleted())) {
      throw new IllegalArgumentException("Work order has been deleted.");
    }
    return workOrder;
  }

  private void normalizeTaskStatus(
      WorkOrderTask task,
      com.svtrucking.logistics.enums.TaskStatus status,
      LocalDateTime startedAt,
      LocalDateTime completedAt) {
    if (status != null) {
      task.setStatus(status);
    }
    if (task.getStatus() == null) {
      task.setStatus(com.svtrucking.logistics.enums.TaskStatus.OPEN);
    }
    if (startedAt != null) {
      task.setStartedAt(startedAt);
    }
    if (completedAt != null) {
      task.setCompletedAt(completedAt);
    }

    com.svtrucking.logistics.enums.TaskStatus finalStatus = task.getStatus();
    if (finalStatus == com.svtrucking.logistics.enums.TaskStatus.OPEN) {
      task.setStartedAt(null);
      task.setCompletedAt(null);
      return;
    }
    if (finalStatus == com.svtrucking.logistics.enums.TaskStatus.IN_PROGRESS) {
      if (task.getStartedAt() == null) {
        task.setStartedAt(LocalDateTime.now());
      }
      task.setCompletedAt(null);
      return;
    }
    if (finalStatus == com.svtrucking.logistics.enums.TaskStatus.COMPLETED) {
      if (task.getStartedAt() == null) {
        task.setStartedAt(LocalDateTime.now());
      }
      if (task.getCompletedAt() == null) {
        task.setCompletedAt(LocalDateTime.now());
      }
      return;
    }
    task.setCompletedAt(null);
  }

  private void recalculatePartsCost(WorkOrder workOrder) {
    List<WorkOrderPart> parts = workOrderPartRepository.findByWorkOrderId(workOrder.getId());
    java.math.BigDecimal totalPartsCost =
        parts.stream()
            .map(WorkOrderPart::getTotalCost)
            .filter(java.util.Objects::nonNull)
            .reduce(java.math.BigDecimal.ZERO, java.math.BigDecimal::add);
    workOrder.setPartsCost(totalPartsCost);
    workOrder.calculateTotalCost();
  }

  private WorkOrderDto hydrateStandardFields(WorkOrderDto dto) {
    if (dto == null || dto.getId() == null) return dto;
    Long workOrderId = dto.getId();
    vendorQuotationRepository.findByWorkOrderId(workOrderId).ifPresent(q -> dto.setVendorQuotation(com.svtrucking.logistics.dto.VendorQuotationDto.fromEntity(q)));
    invoiceRepository.findByWorkOrderId(workOrderId).ifPresent(inv -> dto.setInvoice(com.svtrucking.logistics.dto.InvoiceDto.fromEntity(inv)));
    return dto;
  }
}
