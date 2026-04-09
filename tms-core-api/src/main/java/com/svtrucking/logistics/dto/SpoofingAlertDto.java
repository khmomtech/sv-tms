package com.svtrucking.logistics.dto;

import lombok.Data;
import java.time.Instant;

/**
 * DTO for location spoofing alerts from mobile apps
 */
@Data
public class SpoofingAlertDto {
    private Long driverId;
    private Double latitude;
    private Double longitude;
    private Instant timestamp;
    private String reason;
    private Boolean isMocked;
    private Double accuracy;
    private Double speed;
    private Double heading;
}
