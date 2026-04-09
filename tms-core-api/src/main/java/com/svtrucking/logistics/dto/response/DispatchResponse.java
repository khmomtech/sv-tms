package com.svtrucking.logistics.dto.response;

import com.svtrucking.logistics.enums.DispatchStatus;
import com.svtrucking.logistics.model.Dispatch;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;

/**
 * Response DTO for Dispatch entity - full details.
 * Used for single dispatch retrieval (GET /dispatches/{id}).
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class DispatchResponse {
    
    private Long id;
    private String routeCode;
    private LocalDateTime startTime;
    private LocalDateTime estimatedArrival;
    private DispatchStatus status;
    private String tripType;
    private String cancelReason;
    
    // Transport Order details
    private Long transportOrderId;
    private String orderReference;
    private String customerName;
    
    // Driver details
    private Long driverId;
    private String driverName;
    private String driverPhone;
    
    // Vehicle details
    private Long vehicleId;
    private String vehicleLicensePlate;
    private String vehicleType;
    
    // Metadata
    private String createdByUsername;
    private LocalDateTime createdDate;
    private LocalDateTime updatedDate;

    /**
     * Converts Dispatch entity to DispatchResponse DTO with full details.
     */
    public static DispatchResponse fromEntity(Dispatch dispatch) {
        if (dispatch == null) {
            return null;
        }

        return DispatchResponse.builder()
                .id(dispatch.getId())
                .routeCode(dispatch.getRouteCode())
                .startTime(dispatch.getStartTime())
                .estimatedArrival(dispatch.getEstimatedArrival())
                .status(dispatch.getStatus())
                .tripType(dispatch.getTripType())
                .cancelReason(dispatch.getCancelReason())
                .transportOrderId(dispatch.getTransportOrder() != null ? 
                        dispatch.getTransportOrder().getId() : null)
                .orderReference(dispatch.getTransportOrder() != null ? 
                        dispatch.getTransportOrder().getOrderReference() : null)
                .customerName(dispatch.getTransportOrder() != null && 
                        dispatch.getTransportOrder().getCustomer() != null ?
                        dispatch.getTransportOrder().getCustomer().getName() : null)
                .driverId(dispatch.getDriver() != null ? dispatch.getDriver().getId() : null)
                .driverName(dispatch.getDriver() != null ? dispatch.getDriver().getFullName() : null)
                .driverPhone(dispatch.getDriver() != null ? dispatch.getDriver().getPhone() : null)
                .vehicleId(dispatch.getVehicle() != null ? dispatch.getVehicle().getId() : null)
                .vehicleLicensePlate(dispatch.getVehicle() != null ? 
                        dispatch.getVehicle().getLicensePlate() : null)
                .vehicleType(dispatch.getVehicle() != null && dispatch.getVehicle().getType() != null ? 
                        dispatch.getVehicle().getType().name() : null)
                .createdByUsername(dispatch.getCreatedBy() != null ? 
                        dispatch.getCreatedBy().getUsername() : null)
                .createdDate(dispatch.getCreatedDate())
                .updatedDate(dispatch.getUpdatedDate())
                .build();
    }
}
