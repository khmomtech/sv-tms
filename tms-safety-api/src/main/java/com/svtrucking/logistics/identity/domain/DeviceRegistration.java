package com.svtrucking.logistics.identity.domain;

import com.svtrucking.logistics.enums.DeviceStatus;
import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.Index;
import jakarta.persistence.PrePersist;
import jakarta.persistence.PreUpdate;
import jakarta.persistence.Table;
import jakarta.persistence.UniqueConstraint;
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
@Entity
@Table(
    name = "device_registered",
    uniqueConstraints = {@UniqueConstraint(columnNames = {"driver_id", "device_id"})},
    indexes = {
      @Index(name = "idx_device_driver", columnList = "driver_id"),
      @Index(name = "idx_device_status", columnList = "status")
    })
public class DeviceRegistration {

  @Id
  @GeneratedValue(strategy = GenerationType.IDENTITY)
  private Long id;

  @Column(name = "driver_id", nullable = false)
  private Long driverId;

  @Column(name = "device_id", nullable = false, length = 128)
  private String deviceId;

  @Column(name = "device_name", length = 255)
  private String deviceName;

  @Column(name = "os", length = 50)
  private String os;

  @Column(name = "version", length = 50)
  private String version;

  @Column(name = "app_version", length = 50)
  private String appVersion;

  @Column(name = "manufacturer", length = 50)
  private String manufacturer;

  @Column(name = "model", length = 50)
  private String model;

  @Column(name = "ip_address", length = 64)
  private String ipAddress;

  @Column(name = "location", length = 255)
  private String location;

  @Enumerated(EnumType.STRING)
  @Column(name = "status", nullable = false, length = 20)
  @Builder.Default
  private DeviceStatus status = DeviceStatus.PENDING;

  @Column(name = "registered_at", nullable = false)
  private LocalDateTime registeredAt;

  @Column(name = "approved_by", length = 100)
  private String approvedBy;

  @Column(name = "status_updated_at")
  private LocalDateTime statusUpdatedAt;

  @PrePersist
  public void prePersist() {
    LocalDateTime now = LocalDateTime.now();
    if (registeredAt == null) {
      registeredAt = now;
    }
    if (statusUpdatedAt == null) {
      statusUpdatedAt = now;
    }
  }

  @PreUpdate
  public void preUpdate() {
    statusUpdatedAt = LocalDateTime.now();
  }
}

