package com.svtrucking.logistics.dto.requests;

import lombok.Getter;
import lombok.Setter;

@Getter
@Setter
public class LocationUpdateRequestDto {
  private Long driverId;
  private Double latitude;
  private Double longitude;
}
