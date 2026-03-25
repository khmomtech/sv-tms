package com.svtrucking.logistics.dto;

import com.svtrucking.logistics.enums.DeviceStatus;
import java.time.LocalDateTime;
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
public class DeviceRegisterDto {

  private Long id;
  private Long driverId;
  private String driverName;
  private String deviceId;
  private String deviceName;
  private String os;
  private String version;
  private String appVersion;
  private String manufacturer;
  private String model;
  private String ipAddress;
  private String location;
  private DeviceStatus status;
  private LocalDateTime registeredAt;
  private String approvedBy;
  private LocalDateTime statusUpdatedAt;
}
