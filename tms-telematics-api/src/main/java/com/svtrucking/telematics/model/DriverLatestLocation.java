package com.svtrucking.telematics.model;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Index;
import jakarta.persistence.PrePersist;
import jakarta.persistence.PreUpdate;
import jakarta.persistence.Table;
import jakarta.persistence.Transient;
import java.sql.Timestamp;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.EqualsAndHashCode;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;
import lombok.ToString;
import org.hibernate.annotations.ColumnDefault;
import org.hibernate.annotations.DynamicUpdate;

/**
 * Telematics-local version of DriverLatestLocation.
 * All foreign-key entity references removed — uses plain Long driverId.
 */
@Entity
@Table(name = "driver_latest_location", indexes = {
        @Index(name = "idx_dll_online", columnList = "is_online"),
        @Index(name = "idx_dll_last_seen", columnList = "last_seen"),
        @Index(name = "idx_dll_online_lastseen", columnList = "is_online,last_seen")
})
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder(toBuilder = true)
@EqualsAndHashCode(of = "driverId")
@ToString
@DynamicUpdate
public class DriverLatestLocation {

    @Id
    @Column(name = "driver_id", nullable = false)
    private Long driverId;

    @Column(name = "latitude", nullable = false)
    private double latitude;

    @Column(name = "longitude", nullable = false)
    private double longitude;

    @Column(name = "speed")
    private Double speed;

    @Column(name = "heading")
    private Double heading;

    @Column(name = "dispatch_id")
    private Long dispatchId;

    @Column(name = "last_seen")
    private Timestamp lastSeen;

    @Column(name = "last_received_at")
    private Timestamp lastReceivedAt;

    @Column(name = "last_event_time")
    private Timestamp lastEventTime;

    @Column(name = "is_online")
    private Boolean isOnline;

    @Column(name = "ws_connected", nullable = false)
    @ColumnDefault("0")
    private boolean wsConnected;

    @Column(name = "battery_level")
    private Integer batteryLevel;

    @Column(name = "location_name", length = 255)
    private String locationName;

    @Column(name = "source", length = 32)
    private String source;

    @Column(name = "version")
    private Long version;

    @Column(name = "accuracy_meters")
    private Double accuracyMeters;

    @Column(name = "location_source", length = 16)
    private String locationSource;

    @Column(name = "net_type", length = 16)
    private String netType;

    @PrePersist
    public void prePersist() {
        long now = System.currentTimeMillis();
        if (Double.isNaN(latitude) || Double.isInfinite(latitude))
            latitude = 0d;
        if (Double.isNaN(longitude) || Double.isInfinite(longitude))
            longitude = 0d;
        if (latitude > 90d)
            latitude = 90d;
        else if (latitude < -90d)
            latitude = -90d;
        if (longitude > 180d)
            longitude = 180d;
        else if (longitude < -180d)
            longitude = -180d;
        if (this.lastSeen == null)
            this.lastSeen = new Timestamp(now);
        if (this.lastReceivedAt == null)
            this.lastReceivedAt = this.lastSeen;
        if (this.lastEventTime == null)
            this.lastEventTime = this.lastSeen;
        if (this.isOnline == null)
            this.isOnline = Boolean.TRUE;
    }

    @PreUpdate
    public void preUpdate() {
        if (this.lastSeen == null)
            this.lastSeen = new Timestamp(System.currentTimeMillis());
        if (this.lastReceivedAt == null)
            this.lastReceivedAt = this.lastSeen;
    }

    public void touchOnline() {
        this.isOnline = Boolean.TRUE;
        Timestamp now = new Timestamp(System.currentTimeMillis());
        this.lastSeen = now;
        this.lastReceivedAt = now;
    }

    @Transient
    public boolean isStale(long thresholdMs) {
        if (this.lastSeen == null)
            return true;
        return System.currentTimeMillis() - this.lastSeen.getTime() > thresholdMs;
    }
}
