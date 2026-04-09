package com.svtrucking.logistics.dto.assignment;

import lombok.Data;

@Data
public class AssignmentResponse {
    private Long id;
    private Long driverId;
    private String driverFullName;
    private String driverFirstName;
    private String driverLastName;
    private String driverLicenseNumber;
    private Long vehicleId;
    private String truckPlate;
    private String truckModel;
    private String assignedAt;
    private String assignedBy;
    private String reason;
    private boolean active;
    private String revokedAt;
    private String revokedBy;
    private String revokeReason;
    private Long version; // For optimistic locking UI feedback

    public AssignmentResponse(
            Long id,
            Long driverId,
            String driverFullName,
            String driverFirstName,
            String driverLastName,
            String driverLicenseNumber,
            Long vehicleId,
            String truckPlate,
            String truckModel,
            String assignedAt,
            String assignedBy,
            String reason,
            boolean active,
            String revokedAt,
            String revokedBy,
            String revokeReason,
            Long version) {
        this.id = id;
        this.driverId = driverId;
        this.driverFullName = driverFullName;
        this.driverFirstName = driverFirstName;
        this.driverLastName = driverLastName;
        this.driverLicenseNumber = driverLicenseNumber;
        this.vehicleId = vehicleId;
        this.truckPlate = truckPlate;
        this.truckModel = truckModel;
        this.assignedAt = assignedAt;
        this.assignedBy = assignedBy;
        this.reason = reason;
        this.active = active;
        this.revokedAt = revokedAt;
        this.revokedBy = revokedBy;
        this.revokeReason = revokeReason;
        this.version = version;
    }
}
