package com.svtrucking.logistics.dto;

import com.fasterxml.jackson.annotation.JsonInclude;
import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import com.svtrucking.logistics.dto.VehicleDocumentDto;
import com.svtrucking.logistics.enums.TruckSize;
import com.svtrucking.logistics.enums.VehicleStatus;
import com.svtrucking.logistics.enums.VehicleType;
import com.svtrucking.logistics.enums.VehicleOwnership;
import com.svtrucking.logistics.model.Vehicle;
import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.Date;
import java.util.List;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;
import org.hibernate.Hibernate;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
@JsonInclude(JsonInclude.Include.NON_NULL) //  Only include non-null fields in API JSON
@JsonIgnoreProperties(ignoreUnknown = true)
public class VehicleDto {

  private Long id;

  private String licensePlate;
  private String vin;
  private String model;
  private String manufacturer;

  private VehicleType type;
  private VehicleOwnership ownership;
  private VehicleStatus status;

  private BigDecimal mileage;
  private BigDecimal fuelConsumption;
  private BigDecimal maxWeight;
  private BigDecimal maxVolume;

  private Date lastInspectionDate;
  private Date lastServiceDate;
  private Date nextServiceDue;

  private Integer yearMade;
  private TruckSize truckSize;
  private Integer qtyPalletsCapacity;

  private String assignedZone;
  private String availableRoutes;
  private String unavailableRoutes;

  private String gpsDeviceId;
  private String remarks;

  private DriverSimpleDto assignedDriver;
  private Long parentVehicleId; // Self-reference (e.g., trailer -> truck)
  private List<VehicleDocumentDto> documents;

  //  Entity → DTO
  public static VehicleDto fromEntity(Vehicle vehicle) {
    if (vehicle == null) return null;

    String availableRoutes = null;
    String unavailableRoutes = null;
    List<VehicleDocumentDto> documents = null;
    try {
      if (Hibernate.isInitialized(vehicle.getRoutes()) && vehicle.getRoutes() != null) {
        availableRoutes = vehicle.getRoutes().stream()
            .filter(r -> r.getAvailability() == com.svtrucking.logistics.enums.RouteAvailability.AVAILABLE)
            .map(r -> r.getRouteName())
            .collect(java.util.stream.Collectors.joining(","));
        unavailableRoutes = vehicle.getRoutes().stream()
            .filter(r -> r.getAvailability() == com.svtrucking.logistics.enums.RouteAvailability.RESTRICTED)
            .map(r -> r.getRouteName())
            .collect(java.util.stream.Collectors.joining(","));
      }
    } catch (Exception ignored) {
      // Avoid failing DTO mapping due to lazy loading
    }

    try {
      if (Hibernate.isInitialized(vehicle.getDocuments()) && vehicle.getDocuments() != null) {
        documents = vehicle.getDocuments().stream()
            .map(VehicleDocumentDto::fromEntity)
            .collect(java.util.stream.Collectors.toList());
      }
    } catch (Exception ignored) {
      // Avoid failing DTO mapping due to lazy loading
    }

    return VehicleDto.builder()
      .id(vehicle.getId())
      .licensePlate(vehicle.getLicensePlate())
      .vin(vehicle.getVin())
      .model(vehicle.getModel())
      .manufacturer(vehicle.getManufacturer())
      .type(vehicle.getType())
      .ownership(vehicle.getOwnership())
      .status(vehicle.getStatus())
      .mileage(vehicle.getMileage())
      .fuelConsumption(vehicle.getFuelConsumption())
      .maxWeight(vehicle.getMaxWeight())
      .maxVolume(vehicle.getMaxVolume())
      .lastInspectionDate(toDate(vehicle.getLastInspectionDate()))
      .lastServiceDate(toDate(vehicle.getLastServiceDate()))
      .nextServiceDue(toDate(vehicle.getNextServiceDue()))
      .yearMade(vehicle.getYearMade())
      .truckSize(vehicle.getTruckSize())
      .qtyPalletsCapacity(vehicle.getQtyPalletsCapacity())
      .assignedZone(vehicle.getAssignedZone())
      .availableRoutes(availableRoutes)
      .unavailableRoutes(unavailableRoutes)
      .gpsDeviceId(vehicle.getGpsDeviceId())
      .remarks(vehicle.getRemarks())
      .assignedDriver(
        vehicle.getCurrentAssignedDriver() != null
          ? DriverSimpleDto.fromEntity(vehicle.getCurrentAssignedDriver())
          : null)
      .parentVehicleId(
        vehicle.getParentVehicle() != null ? vehicle.getParentVehicle().getId() : null)
      .documents(documents)
      .build();
  }

  //  DTO → Entity (basic mapper)
  public static Vehicle toEntity(VehicleDto dto) {
    if (dto == null) return null;

    return Vehicle.builder()
        .id(dto.getId())
        .licensePlate(dto.getLicensePlate())
        .vin(dto.getVin())
        .model(dto.getModel())
        .manufacturer(dto.getManufacturer())
        .type(dto.getType())
        .ownership(dto.getOwnership())
        .status(dto.getStatus())
        .mileage(dto.getMileage())
        .fuelConsumption(dto.getFuelConsumption())
        .maxWeight(dto.getMaxWeight())
        .maxVolume(dto.getMaxVolume())
        .lastInspectionDate(toLocalDate(dto.getLastInspectionDate()))
        .lastServiceDate(toLocalDate(dto.getLastServiceDate()))
        .nextServiceDue(toLocalDate(dto.getNextServiceDue()))
        .yearMade(dto.getYearMade())
        .truckSize(dto.getTruckSize())
        .qtyPalletsCapacity(dto.getQtyPalletsCapacity())
        .assignedZone(dto.getAssignedZone())
        // Routes will be handled separately via VehicleRoute entities
        .gpsDeviceId(dto.getGpsDeviceId())
        .remarks(dto.getRemarks())
        .build();
  }

  // 📅 LocalDate → java.util.Date
  private static Date toDate(LocalDate localDate) {
    return localDate != null ? java.sql.Date.valueOf(localDate) : null;
  }

  // 📅 java.util.Date → LocalDate
  private static LocalDate toLocalDate(Date date) {
    return date != null ? new java.sql.Date(date.getTime()).toLocalDate() : null;
  }
}
