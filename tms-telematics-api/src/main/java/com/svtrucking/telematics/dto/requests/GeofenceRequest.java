package com.svtrucking.telematics.dto.requests;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import java.math.BigDecimal;
import lombok.Data;

/** Request body for creating or updating a geofence. */
@Data
public class GeofenceRequest {

    @NotNull
    private Long partnerCompanyId;

    @NotBlank
    private String name;

    private String description;

    @NotBlank
    private String type; // CIRCLE | POLYGON | LINEAR

    private BigDecimal centerLatitude;
    private BigDecimal centerLongitude;
    private BigDecimal radiusMeters;
    private String geoJsonCoordinates;
    private String alertType; // ENTER | EXIT | BOTH | NONE — defaults to NONE
    private Integer speedLimitKmh;
    private Boolean active;
    private String tags;
}
