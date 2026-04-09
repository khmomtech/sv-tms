package com.svtrucking.telematics.model;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.PrePersist;
import jakarta.persistence.PreUpdate;
import jakarta.persistence.Table;
import java.time.LocalDateTime;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

/**
 * Telematics-local version of LocationHistory.
 * 
 * @ManyToOne Driver and @ManyToOne Dispatch removed — plain Long ids used
 *            instead.
 */
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
@Entity
@Table(name = "location_history")
public class LocationHistory {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "driver_id", nullable = false)
    private Long driverId;

    @Column(name = "dispatch_id")
    private Long dispatchId;

    @Column(nullable = false)
    private Double latitude;

    @Column(nullable = false)
    private Double longitude;

    @Column(name = "location_name", length = 512)
    private String locationName;

    @Column(name = "event_time", nullable = false, updatable = false)
    private LocalDateTime eventTime;

    @Column(nullable = false, updatable = false)
    private LocalDateTime timestamp;

    @Column(name = "updated_at")
    private LocalDateTime updatedAt;

    @Builder.Default
    @Column(name = "is_online", nullable = false)
    private Boolean isOnline = Boolean.FALSE;

    @Column(name = "speed")
    private Double speed;

    @Column(name = "battery_level")
    private Integer batteryLevel;

    @Column(name = "source", length = 50)
    private String source;

    @Column(name = "heading")
    private Double heading;

    @Column(name = "accuracy_meters")
    private Double accuracyMeters;

    @Column(name = "location_source", length = 16)
    private String locationSource;

    @Column(name = "net_type", length = 16)
    private String netType;

    @Column(name = "app_version_code")
    private Long appVersionCode;

    @Column(name = "point_id", length = 64)
    private String pointId;

    @Column(name = "seq")
    private Long seq;

    @Column(name = "session_id", length = 64)
    private String sessionId;

    @PrePersist
    protected void onCreate() {
        LocalDateTime now = LocalDateTime.now();
        if (this.eventTime == null) {
            this.eventTime = (this.timestamp != null) ? this.timestamp : now;
        }
        if (this.timestamp == null) {
            this.timestamp = this.eventTime;
        }
        this.updatedAt = now;
    }

    @PreUpdate
    protected void onUpdate() {
        this.updatedAt = LocalDateTime.now();
    }
}
