package com.svtrucking.logistics.dto;

import com.svtrucking.logistics.enums.Priority;
import com.svtrucking.logistics.enums.RepairType;
import com.svtrucking.logistics.enums.WorkOrderStatus;
import com.svtrucking.logistics.enums.WorkOrderType;
import com.svtrucking.logistics.model.WorkOrder;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;
import java.time.LocalDateTime;
import java.util.List;
import java.util.stream.Collectors;
import java.util.Map;

@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class WorkOrderDto {

  private Long id;

  private String woNumber;

  @NotNull(message = "Vehicle ID is required")
  private Long vehicleId;

  private String vehiclePlate;

  @NotNull(message = "Work order type is required")
  private WorkOrderType type;

  @NotNull(message = "Priority is required")
  private Priority priority;

  private WorkOrderStatus status;

  @NotBlank(message = "Title is required")
  @Size(max = 300, message = "Title cannot exceed 300 characters")
  private String title;

  @Size(max = 2000, message = "Description cannot exceed 2000 characters")
  private String description;

  private LocalDateTime createdAt;

  private Long assignedTechnicianId;

  private String assignedTechnicianName;

  private LocalDateTime scheduledDate;

  private LocalDateTime completedAt;

  private Double estimatedCost;

  private Double actualCost;

  private Double laborCost;

  private Double partsCost;

  @Size(max = 1000, message = "Notes cannot exceed 1000 characters")
  private String notes;

  private Boolean requiresApproval;

  private Boolean approved;

  private Long approvedById;

  private String approvedByName;

  private LocalDateTime approvedAt;

    private Object approvedBy;

  private Long maintenanceTaskId;

  private String maintenanceTaskName;

  private Long driverIssueId;

  private Long pmScheduleId;

  private List<WorkOrderTaskDto> tasks;

  private List<WorkOrderPhotoDto> photos;

  private List<WorkOrderPartDto> parts;

  // Summary fields
  private Integer totalTasks;
  private Integer completedTasks;
  private Double totalPartsCost;

  // -----------------------------
  // SV Standard fields
  // -----------------------------
  private Long maintenanceRequestId;
  private String maintenanceRequestNumber;
  private RepairType repairType;
  private Long failureCodeId;
  private String failureCode;
  private String failureCodeDescription;
  private VendorQuotationDto vendorQuotation;
  private InvoiceDto invoice;

  public static WorkOrderDto fromEntity(WorkOrder entity) {
    return fromEntity(entity, false);
  }

  public static WorkOrderDto fromEntity(WorkOrder entity, boolean includeDetails) {
    if (entity == null) return null;

    var dto =
        WorkOrderDto.builder()
            .id(entity.getId())
            .woNumber(entity.getWoNumber())
            .vehicleId(entity.getVehicle() != null ? entity.getVehicle().getId() : null)
            .vehiclePlate(entity.getVehicle() != null ? entity.getVehicle().getLicensePlate() : null)
            .type(entity.getType())
            .priority(entity.getPriority())
            .status(entity.getStatus())
            .title(entity.getTitle())
            .description(entity.getDescription())
            .createdAt(entity.getCreatedAt())
            .assignedTechnicianId(
                entity.getAssignedTechnician() != null
                    ? entity.getAssignedTechnician().getId()
                    : null)
            .assignedTechnicianName(
                entity.getAssignedTechnician() != null
                    ? entity.getAssignedTechnician().getUsername()
                    : null)
            .scheduledDate(entity.getScheduledDate())
            .completedAt(entity.getCompletedAt())
            .estimatedCost(entity.getEstimatedCost() != null ? entity.getEstimatedCost().doubleValue() : null)
            .actualCost(entity.getActualCost() != null ? entity.getActualCost().doubleValue() : null)
            .laborCost(entity.getLaborCost() != null ? entity.getLaborCost().doubleValue() : null)
            .partsCost(entity.getPartsCost() != null ? entity.getPartsCost().doubleValue() : null)
            .notes(entity.getNotes())
            .requiresApproval(entity.getRequiresApproval())
            .approved(entity.getApproved())
            .approvedById(entity.getApprovedBy() != null ? entity.getApprovedBy().getId() : null)
            .approvedByName(
                entity.getApprovedBy() != null ? entity.getApprovedBy().getUsername() : null)
            .approvedAt(entity.getApprovedAt())
            .maintenanceTaskId(
                entity.getMaintenanceTask() != null ? entity.getMaintenanceTask().getId() : null)
            .maintenanceTaskName(
                entity.getMaintenanceTask() != null
                    ? entity.getMaintenanceTask().getName()
                    : null)
            .driverIssueId(
                entity.getDriverIssue() != null ? entity.getDriverIssue().getId() : null)
            .pmScheduleId(entity.getPmSchedule() != null ? entity.getPmSchedule().getId() : null)
            .maintenanceRequestId(
                entity.getMaintenanceRequest() != null ? entity.getMaintenanceRequest().getId() : null)
            .maintenanceRequestNumber(
                entity.getMaintenanceRequest() != null ? entity.getMaintenanceRequest().getMrNumber() : null)
            .repairType(entity.getRepairType())
            .failureCodeId(
                entity.getMaintenanceRequest() != null && entity.getMaintenanceRequest().getFailureCode() != null
                    ? entity.getMaintenanceRequest().getFailureCode().getId()
                    : null)
            .failureCode(
                entity.getMaintenanceRequest() != null && entity.getMaintenanceRequest().getFailureCode() != null
                    ? entity.getMaintenanceRequest().getFailureCode().getCode()
                    : null)
            .failureCodeDescription(
                entity.getMaintenanceRequest() != null && entity.getMaintenanceRequest().getFailureCode() != null
                    ? entity.getMaintenanceRequest().getFailureCode().getDescription()
                    : null)
            .build();

    if (entity.getApprovedBy() != null) {
      dto.setApprovedBy(Map.of("id", entity.getApprovedBy().getId(), "username", entity.getApprovedBy().getUsername()));
    }

    if (includeDetails) {
      dto.setTasks(
          entity.getTasks() != null
              ? entity.getTasks().stream()
                  .map(WorkOrderTaskDto::fromEntity)
                  .collect(Collectors.toList())
              : null);
      dto.setPhotos(
          entity.getPhotos() != null
              ? entity.getPhotos().stream()
                  .map(WorkOrderPhotoDto::fromEntity)
                  .collect(Collectors.toList())
              : null);
      dto.setParts(
          entity.getParts() != null
              ? entity.getParts().stream()
                  .map(WorkOrderPartDto::fromEntity)
                  .collect(Collectors.toList())
              : null);
    }

    // Summary fields
    if (entity.getTasks() != null) {
      dto.setTotalTasks(entity.getTasks().size());
      dto.setCompletedTasks(
          (int)
              entity.getTasks().stream()
                  .filter(t -> "COMPLETED".equals(t.getStatus().name()))
                  .count());
    }

    if (entity.getParts() != null) {
      dto.setTotalPartsCost(entity.getParts().stream()
          .mapToDouble(p -> p.getTotalCost() != null ? p.getTotalCost().doubleValue() : 0.0)
          .sum());
    }

    return dto;
  }
}
