package com.svtrucking.telematics.model;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.PrePersist;
import jakarta.persistence.PreUpdate;
import jakarta.persistence.Table;
import java.math.BigDecimal;
import java.time.LocalDateTime;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
@Entity
@Table(name = "geofences")
public class Geofence {

    public enum Type {
        CIRCLE, POLYGON, LINEAR
    }

    public enum AlertType {
        ENTER, EXIT, BOTH, NONE
    }

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "company_id", nullable = false)
    private Long companyId;

    @Column(name = "name", nullable = false, length = 255)
    private String name;

    @Column(name = "description", columnDefinition = "TEXT")
    private String description;

    @Enumerated(EnumType.STRING)
    @Column(name = "type", nullable = false, length = 20)
    private Type type;

    @Column(name = "center_latitude", precision = 10, scale = 7)
    private BigDecimal centerLatitude;

    @Column(name = "center_longitude", precision = 11, scale = 7)
    private BigDecimal centerLongitude;

    @Column(name = "radius_meters", precision = 10, scale = 2)
    private BigDecimal radiusMeters;

    @Column(name = "geo_json_coordinates", columnDefinition = "TEXT")
    private String geoJsonCoordinates;

    @Enumerated(EnumType.STRING)
    @Builder.Default
    @Column(name = "alert_type", nullable = false, length = 10)
    private AlertType alertType = AlertType.NONE;

    @Column(name = "speed_limit_kmh")
    private Integer speedLimitKmh;

    @Builder.Default
    @Column(name = "active", nullable = false)
    private boolean active = true;

    @Column(name = "tags", columnDefinition = "TEXT")
    private String tags;

    @Column(name = "created_by", length = 255)
    private String createdBy;

    @Column(name = "created_at", nullable = false, updatable = false)
    private LocalDateTime createdAt;

    @Column(name = "updated_at", nullable = false)
    private LocalDateTime updatedAt;

    @PrePersist
    void onCreate() {
        LocalDateTime now = LocalDateTime.now();
        createdAt = now;
        updatedAt = now;
    }

    @PreUpdate
    void onUpdate() {
        updatedAt = LocalDateTime.now();
    }
}
