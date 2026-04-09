package com.svtrucking.logistics.dto;

import com.svtrucking.logistics.enums.PMTriggerType;
import com.svtrucking.logistics.model.PMSchedule;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;
import java.time.LocalDate;

@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class PMScheduleDto {

  private Long id;

  @NotBlank(message = "PM name is required")
  @Size(max = 200, message = "PM name cannot exceed 200 characters")
  private String pmName;

  @Size(max = 1000, message = "Description cannot exceed 1000 characters")
  private String description;

  private Long vehicleId;

  private String vehiclePlate;

  @Size(max = 50, message = "Vehicle type cannot exceed 50 characters")
  private String vehicleType;

  @NotNull(message = "Trigger type is required")
  private PMTriggerType triggerType;

  @Min(value = 1, message = "Interval kilometers must be at least 1")
  private Integer intervalKm;

  @Min(value = 1, message = "Interval days must be at least 1")
  private Integer intervalDays;

  @Min(value = 1, message = "Interval engine hours must be at least 1")
  private Integer intervalEngineHours;

  private Integer nextDueKm;

  private LocalDate nextDueDate;

  private Integer nextDueEngineHours;

  private Integer lastPerformedKm;

  private LocalDate lastPerformedDate;

  private Integer lastPerformedEngineHours;

  private Boolean active;

  private Long maintenanceTaskTypeId;

  private String maintenanceTaskTypeName;

  private Long createdById;

  private String createdByName;

  // Computed fields
  private Boolean isDueNow;
  private Boolean isDueSoon;

  public static PMScheduleDto fromEntity(PMSchedule entity) {
    return fromEntity(entity, null, null, null);
  }

  public static PMScheduleDto fromEntity(
      PMSchedule entity, Integer currentKm, LocalDate currentDate, Integer currentEngineHours) {
    if (entity == null) return null;

    var dto =
        PMScheduleDto.builder()
            .id(entity.getId())
            .pmName(entity.getPmName())
            .description(entity.getDescription())
            .vehicleId(entity.getVehicle() != null ? entity.getVehicle().getId() : null)
            .vehiclePlate(entity.getVehicle() != null ? entity.getVehicle().getLicensePlate() : null)
            .vehicleType(entity.getVehicleType())
            .triggerType(entity.getTriggerType())
            .intervalKm(entity.getIntervalKm())
            .intervalDays(entity.getIntervalDays())
            .intervalEngineHours(entity.getIntervalEngineHours())
            .nextDueKm(entity.getNextDueKm())
            .nextDueDate(entity.getNextDueDate())
            .nextDueEngineHours(entity.getNextDueEngineHours())
            .lastPerformedKm(entity.getLastPerformedKm())
            .lastPerformedDate(entity.getLastPerformedDate())
            .lastPerformedEngineHours(entity.getLastPerformedEngineHours())
            .active(entity.getActive())
            .maintenanceTaskTypeId(
                entity.getMaintenanceTaskType() != null
                    ? entity.getMaintenanceTaskType().getId()
                    : null)
            .maintenanceTaskTypeName(
                entity.getMaintenanceTaskType() != null
                    ? entity.getMaintenanceTaskType().getName()
                    : null)
            .createdById(entity.getCreatedBy() != null ? entity.getCreatedBy().getId() : null)
            .createdByName(
                entity.getCreatedBy() != null ? entity.getCreatedBy().getUsername() : null)
            .build();

    // Compute due status if vehicle data provided
    if (currentKm != null || currentDate != null || currentEngineHours != null) {
      dto.setIsDueNow(entity.isDue(currentKm, currentDate, currentEngineHours));
      dto.setIsDueSoon(entity.isDueSoon(currentKm, currentDate, currentEngineHours));
    }

    return dto;
  }

  public PMSchedule toEntity() {
    return PMSchedule.builder()
        .id(this.id)
        .scheduleName(this.pmName)
        .description(this.description)
        .vehicleType(this.vehicleType)
        .triggerType(this.triggerType)
        .triggerInterval(this.intervalKm != null ? this.intervalKm : (this.intervalDays != null ? this.intervalDays : this.intervalEngineHours))
        .nextDueKm(this.nextDueKm)
        .nextDueDate(this.nextDueDate)
        .nextDueEngineHours(this.nextDueEngineHours)
        .lastPerformedKm(this.lastPerformedKm)
        .lastPerformedEngineHours(this.lastPerformedEngineHours)
        .active(this.active != null ? this.active : true)
        .isDeleted(false)
        .build();
  }
}
