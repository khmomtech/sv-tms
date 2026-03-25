package com.svtrucking.logistics.dto;

import com.fasterxml.jackson.annotation.JsonInclude;
import com.svtrucking.logistics.model.LocationHistory;
import java.time.LocalDateTime;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

/** Data Transfer Object for sending location history data to frontend/clients. */
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
@JsonInclude(JsonInclude.Include.NON_NULL)
public class LocationHistoryDto {

  private Long id;
  private Long driverId;
  private Long dispatchId;
  private Double latitude;
  private Double longitude;

  /** Human-readable location name. */
  private String locationName;

  private LocalDateTime timestamp;
  private LocalDateTime lastUpdated;
  private Boolean isOnline;

  /** Battery percent, speed in km/h, and source label. */
  private Integer batteryLevel;

  private Double speed;
  private String source;

  /** Optional dispatch summary used in tracking UI. */
  private PartialDispatchDto dispatch;

  /** Convert from entity to DTO. */
  public static LocationHistoryDto fromEntity(LocationHistory location) {
    if (location == null) return null;

    return LocationHistoryDto.builder()
        .id(location.getId())
        .driverId(location.getDriver() != null ? location.getDriver().getId() : null)
        .dispatchId(location.getDispatch() != null ? location.getDispatch().getId() : null)
        .latitude(location.getLatitude())
        .longitude(location.getLongitude())
        .locationName(location.getLocationName())
        .timestamp(location.getTimestamp())
        .lastUpdated(location.getUpdatedAt())
        .isOnline(location.getIsOnline())
        .batteryLevel(location.getBatteryLevel())
        .speed(location.getSpeed())
        .source(location.getSource())
        .dispatch(buildPartialDispatch(location))
        .build();
  }

  /** Build lightweight dispatch info for client-side tracking map. */
  private static PartialDispatchDto buildPartialDispatch(LocationHistory location) {
    if (location.getDispatch() == null || location.getDispatch().getTransportOrder() == null) {
      return null;
    }

    var dispatch = location.getDispatch();
    var order = dispatch.getTransportOrder();

    return PartialDispatchDto.builder()
        .id(dispatch.getId())
        .routeCode(dispatch.getRouteCode())
        .tripType(dispatch.getTripType())
        .status(dispatch.getStatus() != null ? dispatch.getStatus().name() : null)
        .pickup(
            order.getPickupAddress() != null
                ? PartialDispatchDto.LocationPoint.builder()
                    .locationName(order.getPickupAddress().getName())
                    .lat(order.getPickupAddress().getLatitude())
                    .lng(order.getPickupAddress().getLongitude())
                    .build()
                : null)
        .dropoff(
            order.getDropAddress() != null
                ? PartialDispatchDto.LocationPoint.builder()
                    .locationName(order.getDropAddress().getName())
                    .lat(order.getDropAddress().getLatitude())
                    .lng(order.getDropAddress().getLongitude())
                    .build()
                : null)
        .build();
  }
}
