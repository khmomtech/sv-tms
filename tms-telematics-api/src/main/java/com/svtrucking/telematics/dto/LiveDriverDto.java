package com.svtrucking.telematics.dto;

import java.time.Instant;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@Builder
@AllArgsConstructor
@NoArgsConstructor
public class LiveDriverDto {
    private Long driverId;
    private String driverName;
    private String driverPhone;

    private Double latitude;
    private Double longitude;
    private Double speed;
    private Double heading;
    private Integer batteryLevel;
    private String locationName;
    private Boolean online;

    private Long dispatchId;
    private String vehiclePlate;

    private Instant updatedAt;
    private Long lastSeenEpochMs;
    private Long lastSeenSeconds;
    private Long ingestLagSeconds;
    private String source;
}
