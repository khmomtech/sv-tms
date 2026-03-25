package com.svtrucking.logistics.dto.requests;

import jakarta.validation.constraints.NotBlank;
import lombok.Data;

/** Request DTO for approving a device via driver login. */
@Data
public class DeviceApprovalRequest {

  @NotBlank(message = "Username is required")
  private String username;

  @NotBlank(message = "Password is required")
  private String password;

  @NotBlank(message = "Device ID is required")
  private String deviceId;

  @NotBlank(message = "Device name is required")
  private String deviceName;

  @NotBlank(message = "Operating system is required")
  private String os;

  @NotBlank(message = "Version is required")
  private String version;

  // 🔄 Optional: Extended metadata (for logging, auditing, analytics)
  private String appVersion;
  private String manufacturer;
  private String model;
  private String ipAddress;
  private String location;
}
