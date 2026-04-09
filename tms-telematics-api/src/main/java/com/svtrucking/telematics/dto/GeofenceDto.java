package com.svtrucking.telematics.dto;

import com.svtrucking.telematics.model.Geofence;
import java.math.BigDecimal;
import java.time.LocalDateTime;
import lombok.Builder;
import lombok.Value;

/** Read-only response DTO for a single geofence. */
@Value
@Builder
public class GeofenceDto {

    Long id;
    Long companyId;
    String name;
    String description;
    String type;
    BigDecimal centerLatitude;
    BigDecimal centerLongitude;
    BigDecimal radiusMeters;
    String geoJsonCoordinates;
    String alertType;
    Integer speedLimitKmh;
    boolean active;
    String tags;
    String createdBy;
    LocalDateTime createdAt;
    LocalDateTime updatedAt;

    public static GeofenceDto from(Geofence g) {
        return GeofenceDto.builder()
                .id(g.getId())
                .companyId(g.getCompanyId())
                .name(g.getName())
                .description(g.getDescription())
                .type(g.getType().name())
                .centerLatitude(g.getCenterLatitude())
                .centerLongitude(g.getCenterLongitude())
                .radiusMeters(g.getRadiusMeters())
                .geoJsonCoordinates(g.getGeoJsonCoordinates())
                .alertType(g.getAlertType().name())
                .speedLimitKmh(g.getSpeedLimitKmh())
                .active(g.isActive())
                .tags(g.getTags())
                .createdBy(g.getCreatedBy())
                .createdAt(g.getCreatedAt())
                .updatedAt(g.getUpdatedAt())
                .build();
    }
}
