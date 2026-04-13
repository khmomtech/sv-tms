package com.svtrucking.logistics.dto;

import java.time.Instant;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class DriverOperationsDiagnosticDto {
  private Long driverId;
  private String driverName;
  private String driverPhone;
  private String vehiclePlate;
  private String state;
  private String reasonCode;
  private String recommendedAction;
  private Boolean online;
  private Boolean activeTrackingSession;
  private Integer activeSessionCount;
  private Boolean validCoordinates;
  private Instant lastLocationAt;
  private Long lastLocationAgeSeconds;
  private Instant sessionLastSeenAt;
  private Long sessionLastSeenAgeSeconds;
  private Instant sessionExpiresAt;
  private String sessionDeviceId;
  private Double latitude;
  private Double longitude;
  private String source;
}
