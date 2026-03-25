package com.svtrucking.logistics.dto.request;

import com.svtrucking.logistics.enums.TruckSize;
import com.svtrucking.logistics.enums.VehicleStatus;
import com.svtrucking.logistics.enums.VehicleType;
import io.swagger.v3.oas.annotations.media.Schema;
import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.Digits;
import jakarta.validation.constraints.Future;
import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.PastOrPresent;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Size;
import java.math.BigDecimal;
import java.time.LocalDate;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

/**
 * Request DTO for creating a new vehicle.
 * Includes Bean Validation annotations for input validation.
 */
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
@Schema(description = "Request to create a new vehicle")
public class VehicleCreateRequest {

  @NotBlank(message = "License plate is required")
  @Size(min = 2, max = 20, message = "License plate must be between 2 and 20 characters")
  @Pattern(regexp = "^[A-Z0-9\\-]+$", message = "License plate must contain only uppercase letters, numbers, and hyphens")
  @Schema(description = "Vehicle license plate number", example = "1A-1234")
  private String licensePlate;

  @Size(max = 100, message = "Model must be less than 100 characters")
  @Schema(description = "Vehicle model", example = "Hino 500 Series")
  private String model;

  @Size(max = 100, message = "Manufacturer must be less than 100 characters")
  @Schema(description = "Vehicle manufacturer", example = "Hino")
  private String manufacturer;

  @NotNull(message = "Vehicle type is required")
  @Schema(description = "Type of vehicle", example = "TRUCK")
  private VehicleType type;

  @Schema(description = "Current vehicle status", example = "AVAILABLE")
  private VehicleStatus status;

  @DecimalMin(value = "0.0", message = "Mileage must be positive")
  @Digits(integer = 10, fraction = 2, message = "Mileage must have maximum 10 integer digits and 2 decimal places")
  @Schema(description = "Current vehicle mileage in kilometers", example = "150000.50")
  private BigDecimal mileage;

  @DecimalMin(value = "0.0", message = "Fuel consumption must be positive")
  @Digits(integer = 5, fraction = 2, message = "Fuel consumption must have maximum 5 integer digits and 2 decimal places")
  @Schema(description = "Average fuel consumption in liters per 100km", example = "25.50")
  private BigDecimal fuelConsumption;

  @PastOrPresent(message = "Last inspection date cannot be in the future")
  @Schema(description = "Date of last vehicle inspection", example = "2024-11-01")
  private LocalDate lastInspectionDate;

  @PastOrPresent(message = "Last service date cannot be in the future")
  @Schema(description = "Date of last service/maintenance", example = "2024-10-15")
  private LocalDate lastServiceDate;

  @Future(message = "Next service due must be in the future")
  @Schema(description = "Date when next service is due", example = "2025-04-15")
  private LocalDate nextServiceDue;

  @Min(value = 1980, message = "Year must be 1980 or later")
  @Max(value = 2030, message = "Year must be 2030 or earlier")
  @Schema(description = "Vehicle manufacturing year", example = "2020")
  private Integer yearMade;

  @Schema(description = "Truck size category (for trucks only)", example = "MEDIUM")
  private TruckSize truckSize;

  @Min(value = 0, message = "Pallet capacity must be non-negative")
  @Max(value = 100, message = "Pallet capacity must be 100 or less")
  @Schema(description = "Maximum pallet capacity (for trucks)", example = "24")
  private Integer qtyPalletsCapacity;

  @Size(max = 100, message = "Assigned zone must be less than 100 characters")
  @Schema(description = "Assigned operational zone", example = "Phnom Penh")
  private String assignedZone;

  @Size(max = 50, message = "GPS device ID must be less than 50 characters")
  @Schema(description = "GPS tracking device identifier", example = "GPS-12345")
  private String gpsDeviceId;

  @Size(max = 500, message = "Remarks must be less than 500 characters")
  @Schema(description = "Additional remarks or notes", example = "Recently serviced, good condition")
  private String remarks;

  @Schema(description = "ID of parent vehicle/truck (for trailers)", example = "42")
  private Long parentVehicleId;
}
