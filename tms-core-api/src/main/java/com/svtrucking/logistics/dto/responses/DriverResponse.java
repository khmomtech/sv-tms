package com.svtrucking.logistics.dto.responses;

import com.fasterxml.jackson.annotation.JsonInclude;
import com.svtrucking.logistics.dto.VehicleDto;
import com.svtrucking.logistics.enums.DriverStatus;
import com.svtrucking.logistics.enums.VehicleType;
import com.svtrucking.logistics.model.Driver;
import com.svtrucking.logistics.utils.AssetUrlHelper;
import io.swagger.v3.oas.annotations.media.Schema;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDate;
import java.time.LocalDateTime;

/**
 * Response DTO for driver details.
 * Used for GET /api/admin/drivers/{id} endpoint.
 * Provides complete driver information including assigned vehicle.
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
@JsonInclude(JsonInclude.Include.NON_NULL)
@Schema(description = "Complete driver information response")
public class DriverResponse {

    @Schema(description = "Driver ID", example = "1")
    private Long id;

    @Schema(description = "Driver's first name", example = "John")
    private String firstName;

    @Schema(description = "Driver's last name", example = "Doe")
    private String lastName;

    @Schema(description = "Full name (computed)", example = "John Doe")
    private String fullName;

    @Schema(description = "Driver's phone number", example = "+1234567890")
    private String phone;

    @Schema(description = "Driver's license number", example = "DL123456")
    private String licenseNumber;

    @Schema(description = "Driver rating (0.0 - 5.0)", example = "4.5")
    private Double rating;

    @Schema(description = "Driver status", example = "ACTIVE")
    private DriverStatus status;

    @Schema(description = "Is driver active?", example = "true")
    private Boolean isActive;

    @Schema(description = "Assigned zone", example = "Zone A")
    private String zone;

    @Schema(description = "Vehicle type preference", example = "TRUCK")
    private VehicleType vehicleType;

    @Schema(description = "Is partner driver?", example = "false")
    private Boolean isPartner;

    @Schema(description = "Partner company name (if partner driver)")
    private String partnerCompany;

    @Schema(description = "Profile picture URL")
    private String profilePicture;

    @Schema(description = "Currently assigned vehicle")
    private VehicleDto assignedVehicle;

    @Schema(description = "Last seen timestamp")
    private LocalDateTime lastSeenAt;

    @Schema(description = "Device token for push notifications")
    private String deviceToken;

    @Schema(description = "Employee ID (if driver is also employee)")
    private Long employeeId;

    @Schema(description = "User account ID")
    private Long userId;

    @Schema(description = "Username")
    private String username;

    @Schema(description = "ID Card expiry date")
    private LocalDate idCardExpiry;

    @Schema(description = "Driver group ID")
    private Long driverGroupId;

    @Schema(description = "Driver group name")
    private String driverGroupName;

    /**
     * Converts Driver entity to DriverResponse DTO.
     */
    public static DriverResponse fromEntity(Driver driver) {
        if (driver == null) {
            return null;
        }

        return DriverResponse.builder()
                .id(driver.getId())
                .firstName(driver.getFirstName())
                .lastName(driver.getLastName())
                .fullName(driver.getFullName())
                .phone(driver.getPhone())
                .licenseNumber(driver.getLicenseNumber())
                .rating(driver.getRating())
                .status(driver.getStatus())
                .isActive(driver.getIsActive())
                .zone(driver.getZone())
                .vehicleType(driver.getVehicleType())
                .isPartner(driver.isPartner())
                .partnerCompany(driver.getPartnerCompanyEntity() != null ? 
                    driver.getPartnerCompanyEntity().getCompanyName() : null)
                .profilePicture(AssetUrlHelper.toAbsoluteUrl(driver.getProfilePicture()))
                .idCardExpiry(driver.getIdCardExpiry())
                .driverGroupId(driver.getDriverGroup() != null ? driver.getDriverGroup().getId() : null)
                .driverGroupName(driver.getDriverGroup() != null ? driver.getDriverGroup().getName() : null)
                .assignedVehicle(driver.getAssignedVehicle() != null ? 
                    VehicleDto.fromEntity(driver.getAssignedVehicle()) : null)
                .lastSeenAt(driver.getLastSeenAt())
                .deviceToken(driver.getDeviceToken())
                .employeeId(driver.getEmployee() != null ? driver.getEmployee().getId() : null)
                .userId(driver.getUser() != null ? driver.getUser().getId() : null)
                .username(driver.getUser() != null ? driver.getUser().getUsername() : null)
                .build();
    }
}
