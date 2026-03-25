package com.svtrucking.telematics.dto;

import com.svtrucking.telematics.model.LocationHistory;
import java.time.LocalDateTime;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@Builder
@AllArgsConstructor
@NoArgsConstructor
public class LocationHistoryDto {
    private Long id;
    private Long driverId;
    private Long dispatchId;
    private Double latitude;
    private Double longitude;
    private String locationName;
    private LocalDateTime timestamp;
    private LocalDateTime eventTime;
    private Boolean isOnline;
    private Integer batteryLevel;
    private Double speed;
    private Double heading;
    private String source;
    private String locationSource;
    private String sessionId;
    private Long seq;

    public static LocationHistoryDto from(LocationHistory lh) {
        return LocationHistoryDto.builder()
                .id(lh.getId())
                .driverId(lh.getDriverId())
                .dispatchId(lh.getDispatchId())
                .latitude(lh.getLatitude())
                .longitude(lh.getLongitude())
                .locationName(lh.getLocationName())
                .timestamp(lh.getTimestamp())
                .eventTime(lh.getEventTime())
                .isOnline(lh.getIsOnline())
                .batteryLevel(lh.getBatteryLevel())
                .speed(lh.getSpeed())
                .heading(lh.getHeading())
                .source(lh.getSource())
                .locationSource(lh.getLocationSource())
                .sessionId(lh.getSessionId())
                .seq(lh.getSeq())
                .build();
    }
}
