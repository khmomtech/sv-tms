package com.svtrucking.logistics.dto;

import com.svtrucking.logistics.enums.TaskStatus;
import com.svtrucking.logistics.model.WorkOrderTask;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;
import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import java.time.LocalDateTime;

@Data
@JsonIgnoreProperties(ignoreUnknown = true)
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class WorkOrderTaskDto {

  private Long id;

  @NotNull(message = "Work order ID is required")
  private Long workOrderId;

  @NotBlank(message = "Task name is required")
  @Size(max = 200, message = "Task name cannot exceed 200 characters")
  private String taskName;

  @Size(max = 1000, message = "Description cannot exceed 1000 characters")
  private String description;

  private TaskStatus status;

  private Long assignedTechnicianId;

  private String assignedTechnicianName;

  @Min(value = 0, message = "Estimated hours must be positive")
  private Double estimatedHours;

  @Min(value = 0, message = "Actual hours must be positive")
  private Double actualHours;

  private String diagnosisResult;

  private String actionsTaken;

  private LocalDateTime completedAt;

  private LocalDateTime startedAt;

  private LocalDateTime updatedAt;

  @Size(max = 1000, message = "Notes cannot exceed 1000 characters")
  private String notes;

  public static WorkOrderTaskDto fromEntity(WorkOrderTask entity) {
    if (entity == null) return null;

    return WorkOrderTaskDto.builder()
        .id(entity.getId())
        .workOrderId(entity.getWorkOrder() != null ? entity.getWorkOrder().getId() : null)
        .taskName(entity.getTaskName())
        .description(entity.getDescription())
        .status(entity.getStatus())
        .assignedTechnicianId(
            entity.getAssignedTechnician() != null ? entity.getAssignedTechnician().getId() : null)
        .assignedTechnicianName(
            entity.getAssignedTechnician() != null
                ? entity.getAssignedTechnician().getUsername()
                : null)
        .estimatedHours(entity.getEstimatedHours())
        .actualHours(entity.getActualHours())
        .diagnosisResult(entity.getDiagnosisResult())
        .actionsTaken(entity.getActionsTaken())
        .completedAt(entity.getCompletedAt())
        .startedAt(entity.getStartedAt())
        .updatedAt(entity.getUpdatedAt())
        .notes(entity.getNotes())
        .build();
  }
}
