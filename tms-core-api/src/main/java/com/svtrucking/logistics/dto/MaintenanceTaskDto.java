package com.svtrucking.logistics.dto;

import com.svtrucking.logistics.enums.MaintenanceStatus;
import com.svtrucking.logistics.model.MaintenanceTask;
import java.time.LocalDateTime;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class MaintenanceTaskDto {
  private Long id;
  private String title;
  private String description;

  private LocalDateTime dueDate;
  private LocalDateTime completedAt;
  private MaintenanceStatus status;

  private Long taskTypeId;
  private String taskTypeName;

  private Long vehicleId;
  private String vehicleName;

  private Long createdBy;
  private String createdByUsername;

  private LocalDateTime createdDate;
  private LocalDateTime updatedDate;

  public static MaintenanceTaskDto fromEntity(MaintenanceTask task) {
    if (task == null) return null;

    return MaintenanceTaskDto.builder()
        .id(task.getId())
        .title(task.getTitle())
        .description(task.getDescription())
        .dueDate(task.getDueDate())
        .completedAt(task.getCompletedAt())
        .status(task.getStatus())
        .taskTypeId(task.getTaskType() != null ? task.getTaskType().getId() : null)
        .taskTypeName(task.getTaskType() != null ? task.getTaskType().getName() : null)
        .vehicleId(task.getVehicle() != null ? task.getVehicle().getId() : null)
        .vehicleName(task.getVehicle() != null ? task.getVehicle().getLicensePlate() : null)
        .createdBy(task.getCreatedBy() != null ? task.getCreatedBy().getId() : null)
        .createdByUsername(task.getCreatedBy() != null ? task.getCreatedBy().getUsername() : null)
        .createdDate(task.getCreatedDate())
        .updatedDate(task.getUpdatedDate())
        .build();
  }
}
