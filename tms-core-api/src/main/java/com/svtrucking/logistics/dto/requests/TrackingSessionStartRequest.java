package com.svtrucking.logistics.dto.requests;

import jakarta.validation.constraints.NotBlank;
import lombok.Getter;
import lombok.Setter;

@Getter
@Setter
public class TrackingSessionStartRequest {
  @NotBlank private String deviceId;
  private String appVersion;
  private String platform;
}
