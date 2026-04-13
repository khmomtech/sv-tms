package com.svtrucking.telematics.dto;

import java.time.Instant;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class DriverTelemetryDiagnosticDto {
    private Long driverId;
    private String driverName;
    private String driverPhone;
    private String vehiclePlate;
    private String status;
    private String reasonCode;
    private Boolean online;
    private Instant lastReceivedAt;
    private Instant lastEventAt;
    private Long receivedAgeSeconds;
    private Long eventAgeSeconds;
    private Long ingestLagSeconds;
    private Boolean activeSession;
    private Instant sessionExpiresAt;
    private Instant sessionLastSeenAt;
    private String sessionDeviceId;
    private Double latitude;
    private Double longitude;
    private String source;
}
