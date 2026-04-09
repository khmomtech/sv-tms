package com.svtrucking.logistics.dto;

import com.fasterxml.jackson.annotation.JsonInclude;
import com.svtrucking.logistics.enums.AssignmentType;
import com.svtrucking.logistics.model.Driver;
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
@JsonInclude(JsonInclude.Include.NON_NULL)
public class DriverCurrentAssignmentDto {
  private Long driverId;
  private VehicleDto permanentVehicle;
  private VehicleDto temporaryVehicle;
  private LocalDateTime temporaryExpiry;
  private Long remainingMinutes; // minutes until expiry when temporary active
  private AssignmentType effectiveType; // TEMPORARY if override active else PERMANENT
  private VehicleDto effectiveVehicle;

  public static DriverCurrentAssignmentDto fromDriver(Driver driver) {
    if (driver == null) return null;
    var now = LocalDateTime.now();
    var permanentVehicle = driver.getAssignedVehicle();
    var currentVehicleDriver = driver.getCurrentVehicleDriverAssignment();
    var currentAssignedVehicle = driver.getCurrentAssignedVehicle();

    boolean tempActive = driver.getTempAssignedVehicle() != null &&
      (driver.getTempAssignmentExpiry() == null || driver.getTempAssignmentExpiry().isAfter(now));
    Long remaining = null;
    if (tempActive && driver.getTempAssignmentExpiry() != null) {
      remaining = java.time.Duration.between(now, driver.getTempAssignmentExpiry()).toMinutes();
      if (remaining != null && remaining < 0) remaining = 0L;
    }

    AssignmentType effectiveType = AssignmentType.PERMANENT;
    if (tempActive) {
      effectiveType = AssignmentType.TEMPORARY;
    } else if (currentVehicleDriver != null) {
      effectiveType = AssignmentType.PERMANENT;
    }

    return DriverCurrentAssignmentDto.builder()
        .driverId(driver.getId())
        .permanentVehicle(VehicleDto.fromEntity(permanentVehicle))
        .temporaryVehicle(VehicleDto.fromEntity(tempActive ? driver.getTempAssignedVehicle() : null))
        .temporaryExpiry(tempActive ? driver.getTempAssignmentExpiry() : null)
        .remainingMinutes(remaining)
        .effectiveType(effectiveType)
        .effectiveVehicle(VehicleDto.fromEntity(currentAssignedVehicle))
        .build();
  }
}
