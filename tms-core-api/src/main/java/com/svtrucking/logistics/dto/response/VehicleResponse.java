package com.svtrucking.logistics.dto.response;

import com.fasterxml.jackson.annotation.JsonInclude;
import com.svtrucking.logistics.dto.DriverSimpleDto;
import com.svtrucking.logistics.enums.TruckSize;
import com.svtrucking.logistics.enums.VehicleStatus;
import com.svtrucking.logistics.enums.VehicleType;
import com.svtrucking.logistics.model.Vehicle;
import io.swagger.v3.oas.annotations.media.Schema;
import java.math.BigDecimal;
import java.time.LocalDate;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

/**
 * Response DTO for vehicle data.
 * Includes all vehicle information including assigned driver.
 */
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
@JsonInclude(JsonInclude.Include.NON_NULL)
@Schema(description = "Vehicle information response")
public class VehicleResponse {

  @Schema(description = "Vehicle unique identifier", example = "123")
  private Long id;

  @Schema(description = "Vehicle license plate number", example = "1A-1234")
  private String licensePlate;

  @Schema(description = "Vehicle model", example = "Hino 500 Series")
  private String model;

  @Schema(description = "Vehicle manufacturer", example = "Hino")
  private String manufacturer;

  @Schema(description = "Type of vehicle", example = "TRUCK")
  private VehicleType type;

  @Schema(description = "Current vehicle status", example = "AVAILABLE")
  private VehicleStatus status;

  @Schema(description = "Current vehicle mileage in kilometers", example = "150000.50")
  private BigDecimal mileage;

  @Schema(description = "Average fuel consumption in liters per 100km", example = "25.50")
  private BigDecimal fuelConsumption;

  @Schema(description = "Date of last vehicle inspection", example = "2024-11-01")
  private LocalDate lastInspectionDate;

  @Schema(description = "Date of last service/maintenance", example = "2024-10-15")
  private LocalDate lastServiceDate;

  @Schema(description = "Date when next service is due", example = "2025-04-15")
  private LocalDate nextServiceDue;

  @Schema(description = "Vehicle manufacturing year", example = "2020")
  private Integer yearMade;

  @Schema(description = "Truck size category", example = "MEDIUM")
  private TruckSize truckSize;

  @Schema(description = "Maximum pallet capacity", example = "24")
  private Integer qtyPalletsCapacity;

  @Schema(description = "Assigned operational zone", example = "Phnom Penh")
  private String assignedZone;

  @Schema(description = "Available routes (comma-separated)", example = "Route A,Route B")
  private String availableRoutes;

  @Schema(description = "Restricted routes (comma-separated)", example = "Route C")
  private String unavailableRoutes;

  @Schema(description = "GPS tracking device identifier", example = "GPS-12345")
  private String gpsDeviceId;

  @Schema(description = "Additional remarks or notes", example = "Recently serviced")
  private String remarks;

  @Schema(description = "Currently assigned driver information")
  private DriverSimpleDto assignedDriver;

  @Schema(description = "ID of parent vehicle/truck (for trailers)", example = "42")
  private Long parentVehicleId;

  /**
   * Convert entity to response DTO.
   */
  public static VehicleResponse fromEntity(Vehicle vehicle) {
    if (vehicle == null) return null;

    return VehicleResponse.builder()
        .id(vehicle.getId())
        .licensePlate(vehicle.getLicensePlate())
        .model(vehicle.getModel())
        .manufacturer(vehicle.getManufacturer())
        .type(vehicle.getType())
        .status(vehicle.getStatus())
        .mileage(vehicle.getMileage())
        .fuelConsumption(vehicle.getFuelConsumption())
        .lastInspectionDate(vehicle.getLastInspectionDate())
        .lastServiceDate(vehicle.getLastServiceDate())
        .nextServiceDue(vehicle.getNextServiceDue())
        .yearMade(vehicle.getYearMade())
        .truckSize(vehicle.getTruckSize())
        .qtyPalletsCapacity(vehicle.getQtyPalletsCapacity())
        .assignedZone(vehicle.getAssignedZone())
        .availableRoutes(vehicle.getRoutes() != null ? vehicle.getRoutes().stream()
            .filter(r -> r.getAvailability() == com.svtrucking.logistics.enums.RouteAvailability.AVAILABLE)
            .map(r -> r.getRouteName())
            .collect(java.util.stream.Collectors.joining(",")) : null)
        .unavailableRoutes(vehicle.getRoutes() != null ? vehicle.getRoutes().stream()
            .filter(r -> r.getAvailability() == com.svtrucking.logistics.enums.RouteAvailability.RESTRICTED)
            .map(r -> r.getRouteName())
            .collect(java.util.stream.Collectors.joining(",")) : null)
        .gpsDeviceId(vehicle.getGpsDeviceId())
        .remarks(vehicle.getRemarks())
        .assignedDriver(
            vehicle.getCurrentAssignedDriver() != null
                ? DriverSimpleDto.fromEntity(vehicle.getCurrentAssignedDriver())
                : null)
        .parentVehicleId(
            vehicle.getParentVehicle() != null ? vehicle.getParentVehicle().getId() : null)
        .build();
  }
}
