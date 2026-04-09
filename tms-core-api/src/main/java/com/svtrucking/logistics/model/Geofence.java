package com.svtrucking.logistics.model;

import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;
import org.hibernate.annotations.CreationTimestamp;
import org.hibernate.annotations.UpdateTimestamp;

import java.time.LocalDateTime;

@Entity
@Table(name = "geofences", indexes = {
        @Index(name = "idx_geofences_company_id", columnList = "company_id"),
        @Index(name = "idx_geofences_active", columnList = "active"),
})
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class Geofence {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "company_id", nullable = false)
    private Long companyId;

    @Column(nullable = false, length = 255)
    private String name;

    @Column(columnDefinition = "TEXT")
    private String description;

    @Column(nullable = false, length = 20)
    @Enumerated(EnumType.STRING)
    private GeofenceType type;

    @Column(name = "center_latitude")
    private Double centerLatitude;

    @Column(name = "center_longitude")
    private Double centerLongitude;

    @Column(name = "radius_meters")
    private Double radiusMeters;

    @Column(name = "geo_json_coordinates", columnDefinition = "TEXT")
    private String geoJsonCoordinates;

    @Column(name = "alert_type", nullable = false, length = 10)
    @Enumerated(EnumType.STRING)
    @Builder.Default
    private AlertType alertType = AlertType.NONE;

    @Column(name = "speed_limit_kmh")
    private Integer speedLimitKmh;

    @Column(nullable = false)
    @Builder.Default
    private Boolean active = true;

    /** JSON array stored as text, e.g. ["warehouse","restricted"] */
    @Column(columnDefinition = "TEXT")
    private String tags;

    @Column(name = "created_by", length = 255)
    private String createdBy;

    @CreationTimestamp
    @Column(name = "created_at", nullable = false, updatable = false)
    private LocalDateTime createdAt;

    @UpdateTimestamp
    @Column(name = "updated_at", nullable = false)
    private LocalDateTime updatedAt;

    public enum GeofenceType {
        CIRCLE, POLYGON, LINEAR
    }

    public enum AlertType {
        ENTER, EXIT, BOTH, NONE
    }
}
