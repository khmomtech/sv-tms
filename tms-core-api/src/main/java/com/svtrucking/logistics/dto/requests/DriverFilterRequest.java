package com.svtrucking.logistics.dto.requests;

import com.svtrucking.logistics.enums.DriverStatus;
import com.svtrucking.logistics.enums.VehicleType;
import lombok.Getter;
import lombok.Setter;

@Getter
@Setter
public class DriverFilterRequest {
  private String query;
  private Boolean isActive;
  private Integer minRating;
  private Integer maxRating;
  private String zone;
  private VehicleType vehicleType;
  private DriverStatus status;
  private Boolean isPartner;
}
