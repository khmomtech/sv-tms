package com.svtrucking.logistics.dto.response;

import com.svtrucking.logistics.enums.DispatchStatus;
import com.svtrucking.logistics.model.Dispatch;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;

/**
 * Lightweight Response DTO for Dispatch entity - list view.
 * Used for dispatch lists (GET /dispatches) to reduce payload size.
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class DispatchListResponse {
    
    private Long id;
    private String routeCode;
    private LocalDateTime startTime;
    private LocalDateTime estimatedArrival;
    private DispatchStatus status;
    private String tripType;
    
    // Minimal Transport Order details
    private String orderReference;
    private String customerName;
    
    // Minimal Driver details
    private Long driverId;
    private String driverName;
    
    // Minimal Vehicle details
    private String vehicleLicensePlate;
    
    private LocalDateTime createdDate;

    /**
     * Converts Dispatch entity to lightweight DispatchListResponse DTO.
     */
    public static DispatchListResponse fromEntity(Dispatch dispatch) {
        if (dispatch == null) {
            return null;
        }

        return DispatchListResponse.builder()
                .id(dispatch.getId())
                .routeCode(dispatch.getRouteCode())
                .startTime(dispatch.getStartTime())
                .estimatedArrival(dispatch.getEstimatedArrival())
                .status(dispatch.getStatus())
                .tripType(dispatch.getTripType())
                .orderReference(dispatch.getTransportOrder() != null ? 
                        dispatch.getTransportOrder().getOrderReference() : null)
                .customerName(dispatch.getTransportOrder() != null && 
                        dispatch.getTransportOrder().getCustomer() != null ?
                        dispatch.getTransportOrder().getCustomer().getName() : null)
                .driverId(dispatch.getDriver() != null ? dispatch.getDriver().getId() : null)
                .driverName(dispatch.getDriver() != null ? dispatch.getDriver().getFullName() : null)
                .vehicleLicensePlate(dispatch.getVehicle() != null ? 
                        dispatch.getVehicle().getLicensePlate() : null)
                .createdDate(dispatch.getCreatedDate())
                .build();
    }
}
