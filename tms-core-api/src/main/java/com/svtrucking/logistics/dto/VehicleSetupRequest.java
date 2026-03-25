package com.svtrucking.logistics.dto;

import com.svtrucking.logistics.enums.TruckSize;
import com.svtrucking.logistics.enums.VehicleType;
import com.svtrucking.logistics.enums.VehicleOwnership;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;
import java.util.List;

/**
 * Request DTO for complete vehicle master setup
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class VehicleSetupRequest {

    // Basic Vehicle Information
    private String licensePlate;
    private String vin;
    private String model;
    private String manufacturer;
    private Integer yearMade;
    private VehicleType type;
    private VehicleOwnership ownership;
    private TruckSize truckSize;

    // Capacity Information
    private BigDecimal maxWeight;
    private BigDecimal maxVolume;
    private BigDecimal fuelConsumption;
    private BigDecimal mileage;
    private Integer qtyPalletsCapacity;

    // Operational Information
    private String assignedZone;
    private String requiredLicenseClass;
    private String gpsDeviceId;
    private String remarks;

    // Documents
    private List<VehicleDocumentRequest> documents;

    // Maintenance Policy
    private MaintenancePolicyRequest maintenancePolicy;
}
