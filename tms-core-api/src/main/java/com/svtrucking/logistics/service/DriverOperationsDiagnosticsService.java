package com.svtrucking.logistics.service;

import com.svtrucking.logistics.dto.DriverOperationsDiagnosticDto;
import com.svtrucking.logistics.model.Driver;
import com.svtrucking.logistics.model.DriverLatestLocation;
import com.svtrucking.logistics.model.DriverTrackingSession;
import com.svtrucking.logistics.repository.DriverLatestLocationRepository;
import com.svtrucking.logistics.repository.DriverRepository;
import com.svtrucking.logistics.repository.DriverTrackingSessionRepository;
import java.time.Instant;
import java.time.LocalDateTime;
import java.time.ZoneOffset;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.List;
import java.util.Map;
import java.util.function.Function;
import java.util.stream.Collectors;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
@RequiredArgsConstructor
public class DriverOperationsDiagnosticsService {

  private static final long LIVE_WINDOW_SECONDS = 120L;
  private static final long SESSION_STALE_SECONDS = 300L;

  private final DriverRepository driverRepository;
  private final DriverLatestLocationRepository driverLatestLocationRepository;
  private final DriverTrackingSessionRepository driverTrackingSessionRepository;

  @Transactional(readOnly = true)
  public List<DriverOperationsDiagnosticDto> listDiagnostics(Boolean onlyProblematic) {
    List<Driver> drivers = driverRepository.findAll();
    Map<Long, DriverLatestLocation> latestByDriver =
        driverLatestLocationRepository.findAllLive().stream()
            .collect(Collectors.toMap(DriverLatestLocation::getDriverId, Function.identity()));
    Map<Long, List<DriverTrackingSession>> activeSessionsByDriver =
        driverTrackingSessionRepository.findByRevokedAtIsNullOrderByLastSeenDesc().stream()
            .collect(Collectors.groupingBy(s -> s.getDriver().getId()));

    List<DriverOperationsDiagnosticDto> out = new ArrayList<>(drivers.size());
    for (Driver driver : drivers) {
      DriverLatestLocation latest = latestByDriver.get(driver.getId());
      List<DriverTrackingSession> activeSessions =
          activeSessionsByDriver.getOrDefault(driver.getId(), List.of());
      out.add(buildDiagnostic(driver, latest, activeSessions));
    }

    return out.stream()
        .filter(dto -> !Boolean.TRUE.equals(onlyProblematic) || isProblematic(dto))
        .sorted(
            Comparator.comparing((DriverOperationsDiagnosticDto dto) -> problemRank(dto.getState()))
                .thenComparing(
                    dto -> dto.getLastLocationAgeSeconds() != null ? dto.getLastLocationAgeSeconds() : Long.MAX_VALUE)
                .thenComparing(DriverOperationsDiagnosticDto::getDriverId))
        .collect(Collectors.toList());
  }

  private DriverOperationsDiagnosticDto buildDiagnostic(
      Driver driver, DriverLatestLocation latest, List<DriverTrackingSession> activeSessions) {
    DriverTrackingSession primarySession =
        activeSessions.stream()
            .max(Comparator.comparing(DriverTrackingSession::getLastSeen, Comparator.nullsLast(Comparator.naturalOrder())))
            .orElse(null);

    Instant now = Instant.now();
    Instant lastLocationAt = latest != null && latest.getLastSeen() != null ? latest.getLastSeen().toInstant() : null;
    Long lastLocationAgeSeconds = ageSeconds(lastLocationAt, now);
    Instant sessionLastSeenAt = toInstant(primarySession != null ? primarySession.getLastSeen() : null);
    Long sessionLastSeenAgeSeconds = ageSeconds(sessionLastSeenAt, now);
    Instant sessionExpiresAt = toInstant(primarySession != null ? primarySession.getExpiresAt() : null);

    boolean hasActiveSession = primarySession != null;
    boolean hasValidCoordinates = latest != null && hasRenderableCoordinates(latest.getLatitude(), latest.getLongitude());
    boolean liveLocation = lastLocationAgeSeconds != null && lastLocationAgeSeconds <= LIVE_WINDOW_SECONDS;
    boolean recentSession = sessionLastSeenAgeSeconds != null && sessionLastSeenAgeSeconds <= SESSION_STALE_SECONDS;

    String state;
    String reasonCode;
    String recommendedAction;
    boolean online;

    if (liveLocation && hasValidCoordinates) {
      state = "LIVE";
      reasonCode = "LIVE_LOCATION";
      recommendedAction = "MONITOR";
      online = true;
    } else if (liveLocation) {
      state = "NO_GPS";
      reasonCode = "INVALID_COORDINATES";
      recommendedAction = "CHECK_GPS_OR_PERMISSIONS";
      online = true;
    } else if (hasActiveSession && recentSession) {
      state = "OFFLINE_APP";
      reasonCode = "SESSION_ALIVE_NO_RECENT_LOCATION";
      recommendedAction = "CONTACT_DRIVER_AND_OPEN_APP";
      online = false;
    } else if (hasActiveSession) {
      state = "STALE_SESSION";
      reasonCode = "TRACKING_SESSION_STALE";
      recommendedAction = "REVOKE_AND_RELOGIN";
      online = false;
    } else {
      state = "LOGGED_OUT";
      reasonCode = "NO_ACTIVE_TRACKING_SESSION";
      recommendedAction = "LOGIN_AND_START_TRACKING";
      online = false;
    }

    String vehiclePlate = null;
    if (driver.getCurrentAssignedVehicle() != null) {
      vehiclePlate = driver.getCurrentAssignedVehicle().getLicensePlate();
    }

    return DriverOperationsDiagnosticDto.builder()
        .driverId(driver.getId())
        .driverName(driver.getName() != null && !driver.getName().isBlank() ? driver.getName() : driver.getFullName())
        .driverPhone(driver.getPhone())
        .vehiclePlate(vehiclePlate)
        .state(state)
        .reasonCode(reasonCode)
        .recommendedAction(recommendedAction)
        .online(online)
        .activeTrackingSession(hasActiveSession)
        .activeSessionCount(activeSessions.size())
        .validCoordinates(hasValidCoordinates)
        .lastLocationAt(lastLocationAt)
        .lastLocationAgeSeconds(lastLocationAgeSeconds)
        .sessionLastSeenAt(sessionLastSeenAt)
        .sessionLastSeenAgeSeconds(sessionLastSeenAgeSeconds)
        .sessionExpiresAt(sessionExpiresAt)
        .sessionDeviceId(primarySession != null ? primarySession.getDeviceId() : null)
        .latitude(latest != null ? latest.getLatitude() : null)
        .longitude(latest != null ? latest.getLongitude() : null)
        .source(latest != null ? latest.getSource() : null)
        .build();
  }

  private boolean isProblematic(DriverOperationsDiagnosticDto dto) {
    return !"LIVE".equals(dto.getState());
  }

  private int problemRank(String state) {
    return switch (state == null ? "" : state) {
      case "STALE_SESSION" -> 0;
      case "OFFLINE_APP" -> 1;
      case "NO_GPS" -> 2;
      case "LOGGED_OUT" -> 3;
      case "LIVE" -> 4;
      default -> 5;
    };
  }

  private static Instant toInstant(LocalDateTime value) {
    return value != null ? value.toInstant(ZoneOffset.UTC) : null;
  }

  private static Long ageSeconds(Instant timestamp, Instant now) {
    if (timestamp == null) {
      return null;
    }
    return Math.max(0L, now.getEpochSecond() - timestamp.getEpochSecond());
  }

  private static boolean hasRenderableCoordinates(double latitude, double longitude) {
    return Double.isFinite(latitude)
        && Double.isFinite(longitude)
        && (Math.abs(latitude) >= 0.000001d || Math.abs(longitude) >= 0.000001d);
  }
}
