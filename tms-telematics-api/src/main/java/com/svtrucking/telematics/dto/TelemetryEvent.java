package com.svtrucking.telematics.dto;

import com.fasterxml.jackson.annotation.JsonFormat;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.Instant;

/**
 * Canonical telemetry event sent from device gateway to the event stream.
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class TelemetryEvent {

    private Long driverId;
    private String dispatchId;

    private Double latitude;
    private Double longitude;
    private Double speed;
    private Double heading;
    private Integer batteryLevel;

    private String source;
    private String locationName;
    private Double accuracyMeters;
    private String locationSource;
    private String netType;

    private String pointId;
    private String sessionId;
    private String seq;

    @JsonFormat(shape = JsonFormat.Shape.STRING)
    private Instant eventTime;

    @JsonFormat(shape = JsonFormat.Shape.STRING)
    private Instant receivedAt;

    private String rawPayload;
}
