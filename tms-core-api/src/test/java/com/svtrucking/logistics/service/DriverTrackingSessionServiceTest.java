package com.svtrucking.logistics.service;

import static org.assertj.core.api.Assertions.assertThat;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

import com.svtrucking.logistics.dto.requests.TrackingSessionStartRequest;
import com.svtrucking.logistics.dto.responses.TrackingSessionResponse;
import com.svtrucking.logistics.model.Driver;
import com.svtrucking.logistics.model.DriverTrackingSession;
import com.svtrucking.logistics.model.User;
import com.svtrucking.logistics.repository.DriverRepository;
import com.svtrucking.logistics.repository.DriverTrackingSessionRepository;
import com.svtrucking.logistics.repository.UserRepository;
import com.svtrucking.logistics.security.JwtUtil;
import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.test.util.ReflectionTestUtils;
import org.springframework.web.server.ResponseStatusException;

@ExtendWith(MockitoExtension.class)
class DriverTrackingSessionServiceTest {

  @Mock private DriverTrackingSessionRepository trackingSessionRepository;
  @Mock private DriverRepository driverRepository;
  @Mock private UserRepository userRepository;
  @Mock private JwtUtil jwtUtil;
  @Mock private TelematicsProxyService telematicsProxyService;
  @Mock private DeviceRegistrationService deviceRegistrationService;

  private DriverTrackingSessionService service;

  @BeforeEach
  void setUp() {
    service =
        new DriverTrackingSessionService(
            trackingSessionRepository,
            driverRepository,
            userRepository,
            jwtUtil,
            telematicsProxyService,
            deviceRegistrationService);
    ReflectionTestUtils.setField(service, "trackingTtlMs", 86_400_000L);
  }

  @Test
  void startSession_revokesOldSessionAndReturnsScopedToken() {
    User user = new User();
    user.setId(100L);
    user.setUsername("driver1");
    user.setPassword("pw");

    Driver driver = new Driver();
    driver.setId(200L);
    driver.setUser(user);

    DriverTrackingSession active =
        DriverTrackingSession.builder()
            .sessionId("old-session")
            .driver(driver)
            .deviceId("ios-01")
            .issuedAt(LocalDateTime.now().minusHours(1))
            .expiresAt(LocalDateTime.now().plusHours(1))
            .build();

    when(userRepository.findByUsernameWithRoles("driver1")).thenReturn(Optional.of(user));
    when(driverRepository.findByUserId(100L)).thenReturn(Optional.of(driver));
    when(trackingSessionRepository.findByDriverIdAndDeviceIdAndRevokedAtIsNullOrderByIssuedAtDesc(
        200L, "ios-01"))
      .thenReturn(List.of(active));
    when(jwtUtil.generateTrackingToken(any(), any(), anyString(), anyString())).thenReturn("trk-token");

    TrackingSessionStartRequest request = new TrackingSessionStartRequest();
    request.setDeviceId("ios-01");

    TrackingSessionResponse response = service.startSession("driver1", request);

    assertThat(active.getRevokedAt()).isNotNull();
    assertThat(response.getTrackingToken()).isEqualTo("trk-token");
    assertThat(response.getScope()).isEqualTo("LOCATION_WRITE TRACKING_WS");
    assertThat(response.getSessionId()).isNotBlank();
    assertThat(response.getExpiresAtEpochMs()).isPositive();
    verify(trackingSessionRepository).saveAll(any());
    verify(trackingSessionRepository).save(any(DriverTrackingSession.class));
  }

  @Test
  void refreshSession_rejectsWhenTokenTypeIsNotTracking() {
    when(jwtUtil.extractTokenType("access-token")).thenReturn("access");

    ResponseStatusException ex =
        assertThrows(ResponseStatusException.class, () -> service.refreshSession("access-token"));

    assertThat(ex.getStatusCode().value()).isEqualTo(401);
    assertThat(ex.getReason()).contains("Not a tracking token");
  }

  @Test
  void validateLocationWriteOrThrow_acceptsAccessTokenForBackwardCompatibility() {
    when(jwtUtil.extractTokenType("access-token")).thenReturn("access");

    service.validateLocationWriteOrThrow("access-token", 55L, "session-x");

    verify(jwtUtil).extractTokenType("access-token");
    verify(trackingSessionRepository, never()).findBySessionIdAndRevokedAtIsNull(anyString());
  }

  @Test
  void validateLocationWriteOrThrow_rejectsDriverMismatch() {
    when(jwtUtil.extractTokenType("tracking-token")).thenReturn("tracking");
    when(jwtUtil.hasScope("tracking-token", "LOCATION_WRITE")).thenReturn(true);
    when(jwtUtil.extractDriverIdClaim("tracking-token")).thenReturn(999L);
    when(jwtUtil.extractSessionIdClaim("tracking-token")).thenReturn("sess-1");

    ResponseStatusException ex =
        assertThrows(
            ResponseStatusException.class,
            () -> service.validateLocationWriteOrThrow("tracking-token", 1000L, "sess-1"));

    assertThat(ex.getStatusCode().value()).isEqualTo(403);
    assertThat(ex.getReason()).contains("driverId mismatch");
  }

  @Test
  void validateLocationWriteOrThrow_updatesLastSeenForValidTrackingToken() {
    Driver driver = new Driver();
    driver.setId(321L);

    DriverTrackingSession session =
        DriverTrackingSession.builder()
            .sessionId("sess-ok")
            .driver(driver)
            .deviceId("ios-abc")
            .issuedAt(LocalDateTime.now().minusHours(1))
            .expiresAt(LocalDateTime.now().plusHours(1))
            .build();

    when(jwtUtil.extractTokenType("tracking-token")).thenReturn("tracking");
    when(jwtUtil.hasScope("tracking-token", "LOCATION_WRITE")).thenReturn(true);
    when(jwtUtil.extractDriverIdClaim("tracking-token")).thenReturn(321L);
    when(jwtUtil.extractSessionIdClaim("tracking-token")).thenReturn("sess-ok");
    when(trackingSessionRepository.findBySessionIdAndRevokedAtIsNull("sess-ok"))
        .thenReturn(Optional.of(session));

    service.validateLocationWriteOrThrow("tracking-token", 321L, "sess-ok");

    ArgumentCaptor<DriverTrackingSession> captor = ArgumentCaptor.forClass(DriverTrackingSession.class);
    verify(trackingSessionRepository).save(captor.capture());
    assertThat(captor.getValue().getLastSeen()).isNotNull();
  }

  @Test
  void validateLocationWriteOrThrow_ignoresStalePayloadSessionIdWhenTokenIsValid() {
    Driver driver = new Driver();
    driver.setId(321L);

    DriverTrackingSession session =
        DriverTrackingSession.builder()
            .sessionId("sess-token")
            .driver(driver)
            .deviceId("ios-abc")
            .issuedAt(LocalDateTime.now().minusHours(1))
            .expiresAt(LocalDateTime.now().plusHours(1))
            .build();

    when(jwtUtil.extractTokenType("tracking-token")).thenReturn("tracking");
    when(jwtUtil.hasScope("tracking-token", "LOCATION_WRITE")).thenReturn(true);
    when(jwtUtil.extractDriverIdClaim("tracking-token")).thenReturn(321L);
    when(jwtUtil.extractSessionIdClaim("tracking-token")).thenReturn("sess-token");
    when(trackingSessionRepository.findBySessionIdAndRevokedAtIsNull("sess-token"))
        .thenReturn(Optional.of(session));

    service.validateLocationWriteOrThrow("tracking-token", 321L, "sess-stale");

    ArgumentCaptor<DriverTrackingSession> captor = ArgumentCaptor.forClass(DriverTrackingSession.class);
    verify(trackingSessionRepository).save(captor.capture());
    assertThat(captor.getValue().getLastSeen()).isNotNull();
  }

  @Test
  void startSession_rejectsUnapprovedDeviceWhenTrackingRequiresApproval() {
    ReflectionTestUtils.setField(service, "requireApprovedDeviceForTracking", true);

    User user = new User();
    user.setId(100L);
    user.setUsername("driver1");

    Driver driver = new Driver();
    driver.setId(200L);
    driver.setUser(user);

    when(userRepository.findByUsernameWithRoles("driver1")).thenReturn(Optional.of(user));
    when(driverRepository.findByUserId(100L)).thenReturn(Optional.of(driver));
    when(deviceRegistrationService.isDeviceApproved(200L, "ios-01")).thenReturn(false);

    TrackingSessionStartRequest request = new TrackingSessionStartRequest();
    request.setDeviceId(" ios-01 ");

    ResponseStatusException ex =
        assertThrows(ResponseStatusException.class, () -> service.startSession("driver1", request));

    assertThat(ex.getStatusCode().value()).isEqualTo(403);
    assertThat(ex.getReason()).contains("Device not approved for tracking");
    verify(trackingSessionRepository, never()).save(any(DriverTrackingSession.class));
  }

  @Test
  void validateLocationWriteOrThrow_rejectsWhenDeviceApprovalWasRevoked() {
    ReflectionTestUtils.setField(service, "requireApprovedDeviceForTracking", true);

    Driver driver = new Driver();
    driver.setId(321L);

    DriverTrackingSession session =
        DriverTrackingSession.builder()
            .sessionId("sess-ok")
            .driver(driver)
            .deviceId("ios-abc")
            .issuedAt(LocalDateTime.now().minusHours(1))
            .expiresAt(LocalDateTime.now().plusHours(1))
            .build();

    when(jwtUtil.extractTokenType("tracking-token")).thenReturn("tracking");
    when(jwtUtil.hasScope("tracking-token", "LOCATION_WRITE")).thenReturn(true);
    when(jwtUtil.extractDriverIdClaim("tracking-token")).thenReturn(321L);
    when(jwtUtil.extractSessionIdClaim("tracking-token")).thenReturn("sess-ok");
    when(trackingSessionRepository.findBySessionIdAndRevokedAtIsNull("sess-ok"))
        .thenReturn(Optional.of(session));
    when(deviceRegistrationService.isDeviceApproved(321L, "ios-abc")).thenReturn(false);

    ResponseStatusException ex =
        assertThrows(
            ResponseStatusException.class,
            () -> service.validateLocationWriteOrThrow("tracking-token", 321L, "sess-ok"));

    assertThat(ex.getStatusCode().value()).isEqualTo(403);
    assertThat(ex.getReason()).contains("Device not approved for tracking");
  }

  @Test
  void extractBearerToken_handlesBearerPrefixAndBlank() {
    assertThat(DriverTrackingSessionService.extractBearerToken("Bearer abc")).isEqualTo("abc");
    assertThat(DriverTrackingSessionService.extractBearerToken("bearer   xyz")).isEqualTo("xyz");
    assertThat(DriverTrackingSessionService.extractBearerToken("   ")).isNull();
    assertThat(DriverTrackingSessionService.extractBearerToken(null)).isNull();
  }
}
