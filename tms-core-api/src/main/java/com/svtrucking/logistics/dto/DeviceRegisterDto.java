package com.svtrucking.logistics.dto;

import com.svtrucking.logistics.enums.DeviceStatus;
import com.svtrucking.logistics.model.DeviceRegister;
import jakarta.persistence.EntityNotFoundException;
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

  //  Convert from Entity
  public static DeviceRegisterDto fromEntity(DeviceRegister device) {
    if (device == null) return null;

    String driverName = null;
    try {
      if (device.getDriver() != null) {
        driverName = device.getDriver().getFullName();
      }
    } catch (EntityNotFoundException | org.hibernate.ObjectNotFoundException ex) {
      driverName = "Driver not found";
    }

    return DeviceRegisterDto.builder()
        .id(device.getId())
        .driverId(device.getDriver() != null ? device.getDriver().getId() : null)
        .driverName(driverName)
        .deviceId(device.getDeviceId())
        .deviceName(device.getDeviceName())
        .os(device.getOs())
        .version(device.getVersion())
        .appVersion(device.getAppVersion())
        .manufacturer(device.getManufacturer())
        .model(device.getModel())
        .ipAddress(device.getIpAddress())
        .location(device.getLocation())
        .status(device.getStatus())
        .registeredAt(device.getRegisteredAt())
        .approvedBy(device.getApprovedBy())
        .statusUpdatedAt(device.getStatusUpdatedAt())
        .build();
  }

  //  Convert to entity (use with caution if not setting all fields)
  public static DeviceRegister toEntity(DeviceRegisterDto dto) {
    if (dto == null) return null;
    return DeviceRegister.builder()
        .id(dto.getId())
        .deviceId(dto.getDeviceId())
        .deviceName(dto.getDeviceName())
        .os(dto.getOs())
        .version(dto.getVersion())
        .appVersion(dto.getAppVersion())
        .manufacturer(dto.getManufacturer())
        .model(dto.getModel())
        .ipAddress(dto.getIpAddress())
        .location(dto.getLocation())
        .status(dto.getStatus())
        .registeredAt(dto.getRegisteredAt())
        .approvedBy(dto.getApprovedBy())
        .statusUpdatedAt(dto.getStatusUpdatedAt())
        .build();
  }
}
