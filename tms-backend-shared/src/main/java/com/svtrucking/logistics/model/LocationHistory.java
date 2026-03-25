package com.svtrucking.logistics.model;

import com.fasterxml.jackson.annotation.JsonIgnore;
import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.FetchType;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.ManyToOne;
import jakarta.persistence.PrePersist;
import jakarta.persistence.PreUpdate;
import jakarta.persistence.Table;
import java.time.LocalDateTime;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

/**
 * Entity representing the historical GPS location of a driver.
 */
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
@Entity
@Table(name = "location_history")
@JsonIgnoreProperties({"hibernateLazyInitializer", "handler"})
public class LocationHistory {

  @Id
  @GeneratedValue(strategy = GenerationType.IDENTITY)
  private Long id;

  @ManyToOne(fetch = FetchType.LAZY)
  @JoinColumn(name = "driver_id", nullable = false)
  @JsonIgnore
  private Driver driver;

  @ManyToOne(fetch = FetchType.LAZY, optional = true)
  @JoinColumn(name = "dispatch_id", nullable = true)
  @JsonIgnore
  private Dispatch dispatch;

  @Column(nullable = false)
  private Double latitude;

  @Column(nullable = false)
  private Double longitude;

  @Column(name = "location_name", length = 512)
  private String locationName;

  @Column(name = "event_time", nullable = false, updatable = false)
  private LocalDateTime eventTime;

  @Column(nullable = false, updatable = false)
  private LocalDateTime timestamp;

  @Column(name = "updated_at")
  private LocalDateTime updatedAt;

  @Builder.Default
  @Column(name = "is_online", nullable = false)
  private Boolean isOnline = Boolean.FALSE;

  @Column(name = "speed")
  private Double speed;

  @Column(name = "battery_level")
  private Integer batteryLevel;

  @Column(name = "source", length = 50)
  private String source;

  @Column(name = "heading")
  private Double heading;

  @Column(name = "accuracy_meters")
  private Double accuracyMeters;

  @Column(name = "location_source", length = 16)
  private String locationSource;

  @Column(name = "net_type", length = 16)
  private String netType;

  @Column(name = "app_version_code")
  private Long appVersionCode;

  @Column(name = "point_id", length = 64)
  private String pointId;

  @Column(name = "seq")
  private Long seq;

  @Column(name = "session_id", length = 64)
  private String sessionId;

  @PrePersist
  protected void onCreate() {
    LocalDateTime now = LocalDateTime.now();
    if (this.eventTime == null) {
      this.eventTime = (this.timestamp != null) ? this.timestamp : now;
    }
    if (this.timestamp == null) {
      this.timestamp = this.eventTime;
    }
    this.updatedAt = now;
  }

  @PreUpdate
  protected void onUpdate() {
    this.updatedAt = LocalDateTime.now();
  }
}
