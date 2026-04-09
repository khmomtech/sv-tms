package com.svtrucking.logistics.controller.drivers;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.when;

import com.svtrucking.logistics.dto.PresenceHeartbeatDto;
import com.svtrucking.logistics.dto.requests.DriverLocationUpdateDto;
import com.svtrucking.logistics.service.DriverTrackingSessionService;
import com.svtrucking.logistics.service.LiveLocationCacheServiceInterface;
import com.svtrucking.logistics.service.LocationIngestService;
import com.svtrucking.logistics.service.TelematicsProxyService;
import io.micrometer.core.instrument.simple.SimpleMeterRegistry;
import java.util.Map;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.messaging.simp.SimpMessagingTemplate;
import org.springframework.web.server.ResponseStatusException;

@ExtendWith(MockitoExtension.class)
class DriverLocationControllerUnitTest {

  @Mock private SimpMessagingTemplate messagingTemplate;
  @Mock private LocationIngestService ingest;
  @Mock private DriverTrackingSessionService trackingSessionService;
  @Mock private LiveLocationCacheServiceInterface cacheService;
  @Mock private TelematicsProxyService telematicsProxyService;

  private DriverLocationController controller;

  @BeforeEach
  void setUp() {
    controller =
        new DriverLocationController(
            messagingTemplate,
            ingest,
            trackingSessionService,
            telematicsProxyService,
            new SimpleMeterRegistry(),
            cacheService);
  }

  @Test
  void restLocationUpdate_returnsUnauthorizedWhenTrackingValidationFails() {
    DriverLocationUpdateDto update =
        DriverLocationUpdateDto.builder().driverId(30211L).latitude(11.55).longitude(104.92).build();

    org.mockito.Mockito.doThrow(
            new ResponseStatusException(org.springframework.http.HttpStatus.UNAUTHORIZED, "Tracking token missing"))
        .when(trackingSessionService)
        .validateLocationWriteOrThrow("bad", 30211L, null);

    ResponseEntity<?> response = controller.restLocationUpdate("Bearer bad", update);

    assertThat(response.getStatusCode().value()).isEqualTo(401);
    assertThat(response.getBody()).isInstanceOf(Map.class);
    @SuppressWarnings("unchecked")
    Map<String, Object> body = (Map<String, Object>) response.getBody();
    assertThat(body.get("ok")).isEqualTo(false);
    assertThat(String.valueOf(body.get("message"))).contains("Tracking token");
  }

  @Test
  void presenceHeartbeat_returnsUnauthorizedWhenTrackingValidationFails() {
    PresenceHeartbeatDto dto =
        PresenceHeartbeatDto.builder()
            .driverId(30211L)
            .device("NATIVE_IOS")
            .battery(88)
            .gpsEnabled(true)
            .ts(System.currentTimeMillis())
            .reason("timer")
            .build();

    org.mockito.Mockito.doThrow(new ResponseStatusException(HttpStatus.UNAUTHORIZED, "Tracking token missing"))
        .when(trackingSessionService)
        .validateLocationWriteOrThrow("bad", 30211L, null);

    ResponseEntity<?> response = controller.presenceHeartbeat("Bearer bad", dto);

    assertThat(response.getStatusCode().value()).isEqualTo(401);
    assertThat(response.getBody()).isInstanceOf(Map.class);
    @SuppressWarnings("unchecked")
    Map<String, Object> body = (Map<String, Object>) response.getBody();
    assertThat(body.get("status")).isEqualTo("error");
    assertThat(String.valueOf(body.get("message"))).contains("Tracking token");
  }

  @Test
  void presenceHeartbeat_returnsOkWhenTrackingValidationPasses() {
    PresenceHeartbeatDto dto =
        PresenceHeartbeatDto.builder()
            .driverId(30211L)
            .device("NATIVE_IOS")
            .battery(77)
            .gpsEnabled(true)
            .ts(System.currentTimeMillis())
            .reason("timer")
            .build();

    org.mockito.Mockito.doNothing()
        .when(trackingSessionService)
        .validateLocationWriteOrThrow("good", 30211L, null);
    when(ingest.markPresence(any(), any(), any(), any(), any(), any()))
        .thenReturn(Map.of("ok", true, "lastSeen", System.currentTimeMillis()));
    when(ingest.lastSeenEpochMs(30211L)).thenReturn(System.currentTimeMillis());

    ResponseEntity<?> response = controller.presenceHeartbeat("Bearer good", dto);

    assertThat(response.getStatusCode().value()).isEqualTo(200);
    assertThat(response.getBody()).isInstanceOf(Map.class);
    @SuppressWarnings("unchecked")
    Map<String, Object> body = (Map<String, Object>) response.getBody();
    assertThat(body.get("status")).isEqualTo("ok");
  }
}
