package com.svtrucking.logistics.dto.requests;

import lombok.Data;

@Data
public class DeviceTokenRequest {
  private Long driverId;
  private String deviceToken;
}
