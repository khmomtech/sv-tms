package com.svtrucking.logistics.dto.responses;

import com.fasterxml.jackson.annotation.JsonInclude;
import com.svtrucking.logistics.enums.DriverStatus;
import com.svtrucking.logistics.enums.VehicleType;
import com.svtrucking.logistics.model.Driver;
import com.svtrucking.logistics.utils.AssetUrlHelper;
import io.swagger.v3.oas.annotations.media.Schema;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;

/**
 * Response DTO for driver search results.
 * Used for search and filter endpoints.
 * Includes vehicle information relevant for dispatch/assignment.
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
@JsonInclude(JsonInclude.Include.NON_NULL)
@Schema(description = "Driver search result with vehicle info")
public class DriverSearchResponse {

    @Schema(description = "Driver ID", example = "1")
    private Long id;

    @Schema(description = "Full name", example = "John Doe")
    private String fullName;

    @Schema(description = "Phone number", example = "+1234567890")
    private String phone;

    @Schema(description = "License number", example = "DL123456")
    private String licenseNumber;

    @Schema(description = "Driver rating (0.0 - 5.0)", example = "4.5")
    private Double rating;

    @Schema(description = "Driver status", example = "ACTIVE")
    private DriverStatus status;

    @Schema(description = "Is active?", example = "true")
    private Boolean isActive;

    @Schema(description = "Assigned zone", example = "Zone A")
    private String zone;

    @Schema(description = "Vehicle type preference", example = "TRUCK")
    private VehicleType vehicleType;

    @Schema(description = "Is partner driver?", example = "false")
    private Boolean isPartner;

    @Schema(description = "Last seen timestamp")
    private LocalDateTime lastSeenAt;

    @Schema(description = "Assigned vehicle ID")
    private Long assignedVehicleId;

    @Schema(description = "Assigned vehicle license plate")
    private String assignedVehiclePlate;

    @Schema(description = "Profile picture URL")
    private String profilePicture;

    /**
     * Converts Driver entity to DriverSearchResponse DTO.
     * Includes vehicle details for dispatch/assignment.
     */
    public static DriverSearchResponse fromEntity(Driver driver) {
        if (driver == null) {
            return null;
        }

        return DriverSearchResponse.builder()
                .id(driver.getId())
                .fullName(driver.getFullName())
                .phone(driver.getPhone())
                .licenseNumber(driver.getLicenseNumber())
                .rating(driver.getRating())
                .status(driver.getStatus())
                .isActive(driver.getIsActive())
                .zone(driver.getZone())
                .vehicleType(driver.getVehicleType())
                .isPartner(driver.isPartner())
                .lastSeenAt(driver.getLastSeenAt())
                .assignedVehicleId(driver.getAssignedVehicle() != null ? 
                    driver.getAssignedVehicle().getId() : null)
                .assignedVehiclePlate(driver.getAssignedVehicle() != null ? 
                    driver.getAssignedVehicle().getLicensePlate() : null)
                .profilePicture(AssetUrlHelper.toAbsoluteUrl(driver.getProfilePicture()))
                .build();
    }
}
