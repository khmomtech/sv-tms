package com.svtrucking.logistics.identity.domain;

import com.svtrucking.logistics.enums.DriverStatus;
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
import java.time.LocalDateTime;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

/**
 * Minimal driver profile needed by the Safety service.
 *
 * <p>Separates driver identity from TMS dispatch/order concepts.
 */
@Entity
@Table(
    name = "drivers",
    indexes = {
      @Index(name = "idx_driver_user", columnList = "user_id"),
      @Index(name = "idx_driver_status", columnList = "status")
    })
@Getter
@Setter
@NoArgsConstructor
public class DriverProfile {

  @Id
  @GeneratedValue(strategy = GenerationType.IDENTITY)
  private Long id;

  @Column(name = "user_id", unique = true)
  private Long userId;

  @Column(name = "name", length = 255)
  private String name;

  @Column(name = "phone", length = 50)
  private String phone;

  @Enumerated(EnumType.STRING)
  @Column(name = "status", length = 16)
  private DriverStatus status;

  @Column(name = "is_active")
  private Boolean active;

  @Column(name = "created_at", updatable = false)
  private LocalDateTime createdAt;

  @Column(name = "updated_at")
  private LocalDateTime updatedAt;

  @PrePersist
  public void onCreate() {
    LocalDateTime now = LocalDateTime.now();
    this.createdAt = now;
    this.updatedAt = now;
    if (this.active == null) {
      this.active = Boolean.TRUE;
    }
    if (this.status == null) {
      this.status = DriverStatus.ONLINE;
    }
  }

  @PreUpdate
  public void onUpdate() {
    this.updatedAt = LocalDateTime.now();
  }
}

