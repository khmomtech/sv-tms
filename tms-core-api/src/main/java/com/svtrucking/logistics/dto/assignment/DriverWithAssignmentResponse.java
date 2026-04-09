package com.svtrucking.logistics.dto.assignment;

import lombok.AllArgsConstructor;
import lombok.Data;

@Data
@AllArgsConstructor
public class DriverWithAssignmentResponse {
    private Long driverId;
    private String driverName;
    private String licenseNumber;
    private Long assignedVehicleId; // nullable
    private String vehiclePlate; // nullable
    private Boolean activeAssignment;
}
