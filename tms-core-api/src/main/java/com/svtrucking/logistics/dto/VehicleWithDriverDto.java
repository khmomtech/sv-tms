// VehicleWithDriverDto.java
package com.svtrucking.logistics.dto;

import lombok.Builder;
import lombok.Data;

@Data
@Builder
public class VehicleWithDriverDto {
  private Long vehicleId;
  private String vehiclePlateNumber;
  private Long driverId;
  private String driverName;
  private String driverPhone;
}
