package com.svtrucking.logistics.dto;

import com.fasterxml.jackson.annotation.JsonInclude;
import com.svtrucking.logistics.model.DriverLatestLocation;
import java.time.Instant;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder(toBuilder = true)
@JsonInclude(JsonInclude.Include.NON_NULL)
public class DriverLatestLocationDto {

  private Long driverId;
  private Double latitude;
  private Double longitude;
  private Double speed;
  private Double heading;
  private Long dispatchId;
  private Instant lastSeen;

  private Integer batteryLevel;
  private String source;
  private String locationName;
  private Boolean isOnline;
  private Boolean wsConnected;

  private Double accuracyMeters;
  private String netType;
  private String locationSource;

  private Long version;

  public static DriverLatestLocationDto from(DriverLatestLocation e) {
    if (e == null) return null;
    return DriverLatestLocationDto.builder()
        .driverId(e.getDriverId())
        .latitude(e.getLatitude())
        .longitude(e.getLongitude())
        .speed(e.getSpeed())
        .heading(e.getHeading())
        .dispatchId(e.getDispatchId())
        .lastSeen(e.getLastSeen() != null ? e.getLastSeen().toInstant() : null)
        .batteryLevel(e.getBatteryLevel())
        .source(e.getSource())
        .locationName(e.getLocationName())
        .isOnline(Boolean.TRUE.equals(e.getIsOnline()))
        .wsConnected(e.isWsConnected())
        .accuracyMeters(e.getAccuracyMeters())
        .netType(e.getNetType())
        .locationSource(e.getLocationSource())
        .version(e.getVersion())
        .build();
  }

  public DriverLatestLocation toEntity() {
    return DriverLatestLocation.builder()
        .driverId(driverId)
        .latitude(latitude != null ? latitude : 0d)
        .longitude(longitude != null ? longitude : 0d)
        .speed(speed)
        .heading(heading)
        .dispatchId(dispatchId)
        .lastSeen(lastSeen != null ? java.sql.Timestamp.from(lastSeen) : null)
        .batteryLevel(batteryLevel)
        .source(source)
        .locationName(locationName)
        .isOnline(Boolean.TRUE.equals(isOnline))
        .wsConnected(Boolean.TRUE.equals(wsConnected))
        .accuracyMeters(accuracyMeters)
        .netType(netType)
        .locationSource(locationSource)
        .version(version)
        .build();
  }
}
