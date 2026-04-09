package com.svtrucking.logistics.dto;

import com.svtrucking.logistics.model.VehicleFuelLog;
import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;
import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class VehicleFuelLogDto {

  private Long id;

  @NotNull(message = "Vehicle ID is required")
  private Long vehicleId;

  private String vehiclePlate;

  private LocalDate filledAt;

  @DecimalMin(value = "0.0", message = "Odometer must be positive")
  private BigDecimal odometerKm;

  @DecimalMin(value = "0.0", message = "Liters must be positive")
  private BigDecimal liters;

  @DecimalMin(value = "0.0", message = "Amount must be positive")
  private BigDecimal amount;

  @Size(max = 120)
  private String station;

  private String notes;

  private Long createdById;

  private String createdByName;

  private LocalDateTime createdAt;

  private LocalDateTime updatedAt;

  public static VehicleFuelLogDto fromEntity(VehicleFuelLog entity) {
    if (entity == null) return null;
    return VehicleFuelLogDto.builder()
        .id(entity.getId())
        .vehicleId(entity.getVehicle() != null ? entity.getVehicle().getId() : null)
        .vehiclePlate(entity.getVehicle() != null ? entity.getVehicle().getLicensePlate() : null)
        .filledAt(entity.getFilledAt())
        .odometerKm(entity.getOdometerKm())
        .liters(entity.getLiters())
        .amount(entity.getAmount())
        .station(entity.getStation())
        .notes(entity.getNotes())
        .createdById(entity.getCreatedBy() != null ? entity.getCreatedBy().getId() : null)
        .createdByName(entity.getCreatedBy() != null ? entity.getCreatedBy().getUsername() : null)
        .createdAt(entity.getCreatedAt())
        .updatedAt(entity.getUpdatedAt())
        .build();
  }
}
