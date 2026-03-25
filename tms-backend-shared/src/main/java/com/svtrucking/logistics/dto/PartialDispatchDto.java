package com.svtrucking.logistics.dto;

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
public class PartialDispatchDto {
  private Long id;
  private String routeCode;
  private String tripType;
  private String status;

  private LocationPoint pickup;
  private LocationPoint dropoff;

  @Getter
  @Setter
  @NoArgsConstructor
  @AllArgsConstructor
  @Builder
  public static class LocationPoint {
    private String locationName;
    private Double lat;
    private Double lng;
  }
}
