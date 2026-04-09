package com.svtrucking.logistics.model;

import com.svtrucking.logistics.enums.DeviceStatus;
import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.ManyToOne;
import jakarta.persistence.Table;
import java.time.LocalDateTime;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;
import jakarta.persistence.FetchType;
import jakarta.persistence.PrePersist;
import jakarta.persistence.PreUpdate;
import jakarta.persistence.UniqueConstraint;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
@Entity
@Table(
    name = "device_registered",
    uniqueConstraints = {@UniqueConstraint(columnNames = {"driver_id", "device_id"})})
public class DeviceRegister {

  @Id
  @GeneratedValue(strategy = GenerationType.IDENTITY)
  private Long id;

  /** Link to the driver this device belongs to */
  @ManyToOne(fetch = FetchType.LAZY)
  @JoinColumn(name = "driver_id", nullable = false)
  private Driver driver;

  /** Unique device identifier (e.g., Android ID or UUID) */
  @Column(name = "device_id", nullable = false)
  private String deviceId;

  /** Display name of the device (e.g., 'Samsung A13') */
  @Column(name = "device_name")
  private String deviceName;

  /** OS name: Android, iOS, etc. */
  @Column(name = "os")
  private String os;

  /** OS version or app version (e.g., '13', '1.0.2') */
  @Column(name = "version")
  private String version;

  /** Extended app version for validation or debugging (optional) */
  @Column(name = "app_version")
  private String appVersion;

  /** Device manufacturer (e.g., Samsung, Apple) */
  @Column(name = "manufacturer")
  private String manufacturer;

  /** Device model (e.g., SM-A135F) */
  @Column(name = "model")
  private String model;

  /** Client IP address at registration time */
  @Column(name = "ip_address")
  private String ipAddress;

  /** Optional location string or geocode info */
  @Column(name = "location")
  private String location;

  /** Status of the device (PENDING, APPROVED, BLOCKED, etc.) */
  @Enumerated(EnumType.STRING)
  @Column(name = "status", nullable = false)
  @Builder.Default
  private DeviceStatus status = DeviceStatus.PENDING;

  /** Timestamp of registration */
  @Column(name = "registered_at", nullable = false)
  private LocalDateTime registeredAt;

  /** Admin username who approved/updated this device (optional audit field) */
  @Column(name = "approved_by")
  private String approvedBy;

  /** Timestamp when device status was last updated */
  @Column(name = "status_updated_at")
  private LocalDateTime statusUpdatedAt;

  /** ⏳ Ensure `registeredAt` is never null when persisting */
  @PrePersist
  public void prePersist() {
    if (registeredAt == null) {
      registeredAt = LocalDateTime.now();
    }
    if (statusUpdatedAt == null) {
      statusUpdatedAt = LocalDateTime.now();
    }
  }

  /** ⏱ Auto-update statusUpdatedAt whenever entity is updated */
  @PreUpdate
  public void preUpdate() {
    statusUpdatedAt = LocalDateTime.now();
  }
}
