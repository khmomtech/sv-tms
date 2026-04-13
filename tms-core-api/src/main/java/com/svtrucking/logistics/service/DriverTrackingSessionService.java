package com.svtrucking.logistics.service;

import com.svtrucking.logistics.dto.requests.TrackingSessionStartRequest;
import com.svtrucking.logistics.dto.responses.TrackingSessionResponse;
import com.svtrucking.logistics.model.DriverTrackingSession;
import com.svtrucking.logistics.model.User;
import com.svtrucking.logistics.repository.DriverRepository;
import com.svtrucking.logistics.repository.DriverTrackingSessionRepository;
import com.svtrucking.logistics.repository.UserRepository;
import com.svtrucking.logistics.security.JwtUtil;
import io.jsonwebtoken.Claims;
import java.time.LocalDateTime;
import java.time.ZoneOffset;
import java.util.List;
import java.util.UUID;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.server.ResponseStatusException;
import org.springframework.http.HttpStatus;

@Service
@RequiredArgsConstructor
@Slf4j
public class DriverTrackingSessionService {

  private final DriverTrackingSessionRepository trackingSessionRepository;
  private final DriverRepository driverRepository;
  private final UserRepository userRepository;
  private final JwtUtil jwtUtil;
  private final TelematicsProxyService telematicsProxy;
  private final DeviceRegistrationService deviceRegistrationService;

  @Value("${app.security.jwt.tracking-ttl-ms:86400000}")
  private long trackingTtlMs;

  @Value("${app.driver.require-approved-device-for-tracking:false}")
  private boolean requireApprovedDeviceForTracking;

  @Value("${app.driver.skip-device-check:false}")
  private boolean skipDeviceCheck;

  @Value("${app.driver.login-bypass:false}")
  private boolean driverLoginBypass;

  @Transactional
  public TrackingSessionResponse startSession(String username, TrackingSessionStartRequest req) {
    User user = userRepository
        .findByUsernameWithRoles(username)
        .orElseThrow(
            () -> new ResponseStatusException(
                HttpStatus.UNAUTHORIZED, "User not found for tracking session"));
    var driver = driverRepository
        .findByUserId(user.getId())
        .orElseThrow(
            () -> new ResponseStatusException(
                HttpStatus.BAD_REQUEST, "Driver profile not found"));
    String deviceId = normalizeDeviceId(req.getDeviceId());
    assertApprovedDeviceForTracking(driver.getId(), deviceId);

    List<DriverTrackingSession> actives = trackingSessionRepository
      .findByDriverIdAndDeviceIdAndRevokedAtIsNullOrderByIssuedAtDesc(
        driver.getId(), deviceId);
    LocalDateTime now = LocalDateTime.now();
    if (!actives.isEmpty()) {
      for (DriverTrackingSession s : actives) {
        s.setRevokedAt(now);
      }
      trackingSessionRepository.saveAll(actives);
    }

    String sessionId = UUID.randomUUID().toString();
    DriverTrackingSession session = DriverTrackingSession.builder()
        .sessionId(sessionId)
        .driver(driver)
        .deviceId(deviceId)
        .issuedAt(now)
        .expiresAt(now.plusSeconds(Math.max(1L, trackingTtlMs / 1000L)))
        .lastSeen(now)
        .build();
    trackingSessionRepository.save(session);

    // Fire-and-forget: sync driver snapshot to telematics service so it can
    // resolve display names without calling back into tms-backend.
    try {
      com.svtrucking.logistics.model.Vehicle veh =
          driver.getTempAssignedVehicle() != null
              ? driver.getTempAssignedVehicle()
              : driver.getAssignedVehicle();
      String plate = veh != null ? veh.getLicensePlate() : null;
      telematicsProxy.syncDriverAsync(driver.getId(), driver.getName(), driver.getPhone(), plate);
    } catch (Exception ignored) {
      // syncDriverAsync swallows errors; this is belt-and-suspenders
    }

    UserDetails principal = org.springframework.security.core.userdetails.User.withUsername(user.getUsername())
        .password(user.getPassword() == null ? "" : user.getPassword())
        .authorities("ROLE_DRIVER")
        .build();
    String token = jwtUtil.generateTrackingToken(principal, driver.getId(), session.getDeviceId(), sessionId);

    return TrackingSessionResponse.builder()
        .sessionId(sessionId)
        .trackingToken(token)
        .scope("LOCATION_WRITE TRACKING_WS")
        .expiresAtEpochMs(session.getExpiresAt().toInstant(ZoneOffset.UTC).toEpochMilli())
        .build();
  }

  @Transactional
  public TrackingSessionResponse refreshSession(String trackingToken) {
    if (trackingToken == null || trackingToken.isBlank()) {
      throw new ResponseStatusException(HttpStatus.UNAUTHORIZED, "Tracking token missing");
    }
    if (!"tracking".equalsIgnoreCase(jwtUtil.extractTokenType(trackingToken))) {
      throw new ResponseStatusException(HttpStatus.UNAUTHORIZED, "Not a tracking token");
    }
    Claims claims = jwtUtil.extractAccessClaimsAllowExpired(trackingToken);
    String sessionId = jwtUtil.extractSessionIdClaim(trackingToken);
    Long driverId = jwtUtil.extractDriverIdClaim(trackingToken);
    String deviceId = jwtUtil.extractDeviceIdClaim(trackingToken);
    if (sessionId == null || driverId == null || deviceId == null) {
      throw new ResponseStatusException(HttpStatus.UNAUTHORIZED, "Invalid tracking token claims");
    }
    assertApprovedDeviceForTracking(driverId, deviceId);

    DriverTrackingSession session = trackingSessionRepository
        .findBySessionIdAndRevokedAtIsNull(sessionId)
        .orElseThrow(
            () -> new ResponseStatusException(
                HttpStatus.FORBIDDEN, "Tracking session not active"));
    LocalDateTime now = LocalDateTime.now();
    if (session.getExpiresAt() != null && session.getExpiresAt().isBefore(now)) {
      throw new ResponseStatusException(HttpStatus.FORBIDDEN, "Tracking session expired");
    }
    if (!session.getDriver().getId().equals(driverId)
        || !session.getDeviceId().equals(deviceId)) {
      throw new ResponseStatusException(HttpStatus.FORBIDDEN, "Tracking session mismatch");
    }

    session.setLastSeen(now);
    session.setExpiresAt(now.plusSeconds(Math.max(1L, trackingTtlMs / 1000L)));
    trackingSessionRepository.save(session);

    UserDetails principal = org.springframework.security.core.userdetails.User.withUsername(claims.getSubject())
        .password("")
        .authorities("ROLE_DRIVER")
        .build();
    String rotated = jwtUtil.generateTrackingToken(
        principal, session.getDriver().getId(), session.getDeviceId(), session.getSessionId());

    return TrackingSessionResponse.builder()
        .sessionId(session.getSessionId())
        .trackingToken(rotated)
        .scope("LOCATION_WRITE TRACKING_WS")
        .expiresAtEpochMs(session.getExpiresAt().toInstant(ZoneOffset.UTC).toEpochMilli())
        .build();
  }

  @Transactional
  public void stopSession(String trackingToken) {
    String sessionId = jwtUtil.extractSessionIdClaim(trackingToken);
    if (sessionId == null || sessionId.isBlank()) {
      throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "sessionId missing from token");
    }
    DriverTrackingSession session = trackingSessionRepository
        .findBySessionIdAndRevokedAtIsNull(sessionId)
        .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Session not found"));
    session.setRevokedAt(LocalDateTime.now());
    trackingSessionRepository.save(session);
  }

  @Transactional
  public int revokeActiveSessionsForDriver(Long driverId) {
    if (driverId == null) {
      throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "driverId is required");
    }
    List<DriverTrackingSession> activeSessions =
        trackingSessionRepository.findByDriverIdAndRevokedAtIsNullOrderByIssuedAtDesc(driverId);
    if (activeSessions.isEmpty()) {
      return 0;
    }
    LocalDateTime now = LocalDateTime.now();
    for (DriverTrackingSession session : activeSessions) {
      session.setRevokedAt(now);
    }
    trackingSessionRepository.saveAll(activeSessions);
    return activeSessions.size();
  }

  @Transactional
  public void validateLocationWriteOrThrow(String bearerToken, Long payloadDriverId, String payloadSessionId) {
    if (bearerToken == null || bearerToken.isBlank()) {
      throw new ResponseStatusException(HttpStatus.UNAUTHORIZED, "Authorization token missing");
    }
    String typ = jwtUtil.extractTokenType(bearerToken);
    if (!"tracking".equalsIgnoreCase(typ)) {
      return; // keep backward compatibility for normal app access token paths
    }

    if (!jwtUtil.hasScope(bearerToken, "LOCATION_WRITE")) {
      throw new ResponseStatusException(HttpStatus.FORBIDDEN, "Tracking scope LOCATION_WRITE required");
    }
    Long tokenDriverId = jwtUtil.extractDriverIdClaim(bearerToken);
    String tokenSessionId = jwtUtil.extractSessionIdClaim(bearerToken);
    if (tokenDriverId == null || tokenSessionId == null) {
      throw new ResponseStatusException(HttpStatus.UNAUTHORIZED, "Tracking token missing claims");
    }
    if (payloadDriverId == null || !payloadDriverId.equals(tokenDriverId)) {
      throw new ResponseStatusException(HttpStatus.FORBIDDEN, "driverId mismatch");
    }
    if (payloadSessionId != null
        && !payloadSessionId.isBlank()
        && !payloadSessionId.equals(tokenSessionId)) {
      // Trust the tracking token as the source of truth. Native/mobile clients may
      // briefly hold a stale cached sessionId after rotation, and rejecting those
      // writes creates persistent 403 loops even though the token itself is valid.
      log.warn(
          "Ignoring stale payload sessionId for driver {}: payloadSessionId={}, tokenSessionId={}",
          tokenDriverId,
          payloadSessionId,
          tokenSessionId);
    }

    DriverTrackingSession session = trackingSessionRepository
        .findBySessionIdAndRevokedAtIsNull(tokenSessionId)
        .orElseThrow(() -> new ResponseStatusException(HttpStatus.FORBIDDEN, "Tracking session not active"));
    LocalDateTime now = LocalDateTime.now();
    if (session.getExpiresAt() != null && session.getExpiresAt().isBefore(now)) {
      throw new ResponseStatusException(HttpStatus.FORBIDDEN, "Tracking session expired");
    }
    if (!session.getDriver().getId().equals(tokenDriverId)) {
      throw new ResponseStatusException(HttpStatus.FORBIDDEN, "session driver mismatch");
    }
    assertApprovedDeviceForTracking(session.getDriver().getId(), session.getDeviceId());
    session.setLastSeen(now);
    session.setExpiresAt(now.plusSeconds(Math.max(1L, trackingTtlMs / 1000L)));
    trackingSessionRepository.save(session);
  }

  private String normalizeDeviceId(String deviceId) {
    if (deviceId == null || deviceId.isBlank()) {
      throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "deviceId is required");
    }
    return deviceId.trim();
  }

  private void assertApprovedDeviceForTracking(Long driverId, String deviceId) {
    if (!requireApprovedDeviceForTracking || skipDeviceCheck || driverLoginBypass) {
      if (skipDeviceCheck || driverLoginBypass) {
        log.debug(
            "Skipping tracking device approval check for driverId={} deviceId={} (requireApproved={}, skipDeviceCheck={}, loginBypass={})",
            driverId,
            deviceId,
            requireApprovedDeviceForTracking,
            skipDeviceCheck,
            driverLoginBypass);
      }
      return;
    }
    if (!deviceRegistrationService.isDeviceApproved(driverId, deviceId)) {
      throw new ResponseStatusException(HttpStatus.FORBIDDEN, "Device not approved for tracking");
    }
  }

  public static String extractBearerToken(String authHeader) {
    if (authHeader == null || authHeader.isBlank()) {
      return null;
    }
    String t = authHeader.trim();
    if (t.regionMatches(true, 0, "Bearer ", 0, 7)) {
      t = t.substring(7).trim();
    }
    return t.isEmpty() ? null : t;
  }
}
