package com.svtrucking.logistics.dto;

import com.svtrucking.logistics.model.DispatchStop;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;
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
public class DispatchStopDto {
  private Long id;
  private Integer stopSequence;
  private String locationName;
  private String address;
  private String coordinates;
  private LocalDateTime arrivalTime;
  private LocalDateTime departureTime;
  private Boolean isCompleted;

  public static DispatchStopDto fromEntity(DispatchStop stop) {
    String locationName = stop.getLocationName();
    if ((locationName == null || locationName.isBlank()) && stop.getAddress() != null) {
      locationName = stop.getAddress();
    }
    return DispatchStopDto.builder()
        .id(stop.getId())
        .stopSequence(stop.getStopSequence())
        .locationName(locationName)
        .address(stop.getAddress())
        .coordinates(stop.getCoordinates())
        .arrivalTime(stop.getArrivalTime())
        .departureTime(stop.getDepartureTime())
        .isCompleted(stop.getIsCompleted())
        .build();
  }

  public static DispatchStopDto fromOrderStopDto(OrderStopDto stop) {
    if (stop == null) return null;

    CustomerAddressDto address = stop.getAddress();
    String coords = null;
    if (address != null) {
      coords = address.getLatitude() + "," + address.getLongitude();
    }
    String locationName =
        address != null
            ? address.getName()
            : (stop.getType() != null ? stop.getType().name() : null);

    return DispatchStopDto.builder()
        .id(stop.getId())
        .stopSequence(stop.getSequence())
        .locationName(locationName)
        .address(buildAddressLine(address))
        .coordinates(coords)
        .arrivalTime(stop.getArrivalTime())
        .departureTime(stop.getDepartureTime())
        .isCompleted(false)
        .build();
  }

  private static String buildAddressLine(CustomerAddressDto address) {
    if (address == null) return null;
    List<String> parts = new ArrayList<>();
    if (address.getAddress() != null && !address.getAddress().isBlank()) {
      parts.add(address.getAddress());
    }
    if (address.getCity() != null && !address.getCity().isBlank()) {
      parts.add(address.getCity());
    }
    if (address.getCountry() != null && !address.getCountry().isBlank()) {
      parts.add(address.getCountry());
    }
    return parts.isEmpty() ? null : String.join(", ", parts);
  }
}
