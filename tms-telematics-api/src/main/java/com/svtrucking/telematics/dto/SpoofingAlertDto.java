package com.svtrucking.telematics.dto;

import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import jakarta.validation.constraints.NotNull;
import java.time.Instant;
import lombok.Data;

@Data
@JsonIgnoreProperties(ignoreUnknown = true)
public class SpoofingAlertDto {

    @NotNull
    private Long driverId;

    private Long dispatchId;
    private String sessionId;
    private String deviceId;

    private Double latitude;
    private Double longitude;
    private Instant timestamp;

    private String reason;
    private String alertType;

    private Boolean isMocked;
    private Double accuracy;
    private Double speed;
    private Double heading;

    private Double distanceMeters;
    private Long timeDeltaMs;
    private String detail;
}
