// dto/LiveDriverDto.java
package com.svtrucking.logistics.dto;

import java.time.Instant;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@Builder
@AllArgsConstructor
@NoArgsConstructor
public class LiveDriverDto {
  private Long driverId;
  private String driverName;
  private String driverPhone;

  private Double latitude;
  private Double longitude;
  private Double speed; // km/h
  private Double heading; // degrees
  private Integer batteryLevel; // 0..100
  private String locationName;
  private String geocodeStatus;
  private Boolean online;

  private Long dispatchId; // optional
  private String vehiclePlate; // optional

  private Instant updatedAt; // server "last_seen"
  private Long lastSeenEpochMs; // for UI freshness diagnostics
  private Long lastSeenSeconds; // age from server now
  private Long ingestLagSeconds; // server-now minus latest event time
  private String source; // ANDROID_NATIVE / etc.
}
