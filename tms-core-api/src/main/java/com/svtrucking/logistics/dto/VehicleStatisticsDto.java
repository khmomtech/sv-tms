package com.svtrucking.logistics.dto;

import java.math.BigDecimal;
import java.util.Map;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

/**
 * DTO for vehicle fleet statistics and analytics
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class VehicleStatisticsDto {
  
  // Overall statistics
  private Long totalVehicles;
  private Long availableVehicles;
  private Long inUseVehicles;
  private Long maintenanceVehicles;
  private Long outOfServiceVehicles;
  
  // Assignment statistics
  private Long assignedVehicles;
  private Long unassignedVehicles;
  private Double assignmentRate; // Percentage of vehicles assigned
  
  // Service statistics
  private Long vehiclesRequiringService;
  private Long vehiclesDueForInspection;
  
  // Fleet composition
  private Map<String, Long> vehiclesByStatus;
  private Map<String, Long> vehiclesByType;
  private Map<String, Long> vehiclesByTruckSize;
  private Map<String, Long> vehiclesByZone;
  
  // Fleet health
  private BigDecimal averageMileage;
  private BigDecimal averageFuelConsumption;
  private Integer averageVehicleAge;
  
  // GPS tracking
  private Long vehiclesWithGPS;
  private Long vehiclesWithoutGPS;
  
  // Trailer statistics
  private Long totalTrailers;
  private Long assignedTrailers;
}
