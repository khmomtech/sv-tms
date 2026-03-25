package com.svtrucking.telematics.model;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.Index;
import jakarta.persistence.PrePersist;
import jakarta.persistence.Table;
import java.time.LocalDateTime;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

/**
 * Persistent record of a spoofing-detection alert.
 * Implements the TODO stubs in tms-backend DriverLocationController:466-468.
 */
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
@Entity
@Table(name = "spoofing_alerts", indexes = {
        @Index(name = "idx_sa_driver", columnList = "driver_id"),
        @Index(name = "idx_sa_created", columnList = "created_at"),
        @Index(name = "idx_sa_session", columnList = "session_id"),
        @Index(name = "idx_sa_type", columnList = "alert_type")
})
public class SpoofingAlert {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "driver_id", nullable = false)
    private Long driverId;

    @Column(name = "dispatch_id")
    private Long dispatchId;

    @Column(name = "session_id", length = 64)
    private String sessionId;

    /** e.g. "IMPOSSIBLE_SPEED", "TELEPORT", "MOCK_LOCATION" */
    @Column(name = "alert_type", nullable = false, length = 64)
    private String alertType;

    @Column(name = "latitude")
    private Double latitude;

    @Column(name = "longitude")
    private Double longitude;

    @Column(name = "speed_kmh")
    private Double speedKmh;

    @Column(name = "distance_meters")
    private Double distanceMeters;

    @Column(name = "time_delta_ms")
    private Long timeDeltaMs;

    @Column(name = "detail", length = 1024)
    private String detail;

    @Column(name = "device_id", length = 128)
    private String deviceId;

    @Column(name = "created_at", nullable = false, updatable = false)
    private LocalDateTime createdAt;

    @PrePersist
    void onCreate() {
        if (this.createdAt == null)
            this.createdAt = LocalDateTime.now();
    }
}
