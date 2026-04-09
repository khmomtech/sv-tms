package com.svtrucking.logistics.dto.requests;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import lombok.Getter;
import lombok.Setter;

/**
 * Typed request for planning a dispatch trip, replacing loose Map parsing in
 * the controller.
 */
@Getter
@Setter
public class PlanTripRequest {

    @NotNull
    private Long orderId;
    @NotBlank
    private String tripType;
    @NotNull
    private Long vehicleId;
    /**
     * ISO datetime expected (UTC or with offset). Kept as String to preserve client
     * format.
     */
    @NotBlank
    private String scheduleTime;
    @NotBlank
    private String estimatedDrop;

    private String manualRouteCode;
}
