package com.svtrucking.devicegateway.telemetry;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import jakarta.persistence.UniqueConstraint;
import java.time.Instant;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Entity
@Table(
    name = "telemetry_point",
    uniqueConstraints = {
        @UniqueConstraint(name = "uk_telemetry_device_sequence", columnNames = {"device_id", "sequence_number"})
    }
)
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class TelemetryPoint {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "device_id", nullable = false)
    private String deviceId;

    @Column(name = "sequence_number", nullable = false)
    private Long sequenceNumber;

    @Column(name = "driver_id")
    private Long driverId;

    @Column(name = "received_at", nullable = false)
    private Instant receivedAt;

    @Column(name = "recorded_at", nullable = false)
    private Instant recordedAt;

    @Column(name = "latitude")
    private Double latitude;

    @Column(name = "longitude")
    private Double longitude;

    @Column(name = "accuracy")
    private Double accuracy;

    @Enumerated(EnumType.STRING)
    @Column(name = "publish_status", nullable = false)
    @Builder.Default
    private TelemetryPublishStatus publishStatus = TelemetryPublishStatus.PENDING;

    @Column(name = "publish_attempts", nullable = false)
    @Builder.Default
    private Integer publishAttempts = 0;

    @Column(name = "published_at")
    private Instant publishedAt;

    @Column(name = "last_publish_error", length = 1000)
    private String lastPublishError;
}
