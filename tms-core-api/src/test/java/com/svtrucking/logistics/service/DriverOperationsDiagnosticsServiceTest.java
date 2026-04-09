package com.svtrucking.logistics.service;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.Mockito.when;

import com.svtrucking.logistics.dto.DriverOperationsDiagnosticDto;
import com.svtrucking.logistics.model.Driver;
import com.svtrucking.logistics.model.DriverLatestLocation;
import com.svtrucking.logistics.model.DriverTrackingSession;
import com.svtrucking.logistics.repository.DriverLatestLocationRepository;
import com.svtrucking.logistics.repository.DriverRepository;
import com.svtrucking.logistics.repository.DriverTrackingSessionRepository;
import java.sql.Timestamp;
import java.time.Instant;
import java.time.LocalDateTime;
import java.util.List;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

@ExtendWith(MockitoExtension.class)
class DriverOperationsDiagnosticsServiceTest {

  @Mock private DriverRepository driverRepository;
  @Mock private DriverLatestLocationRepository driverLatestLocationRepository;
  @Mock private DriverTrackingSessionRepository driverTrackingSessionRepository;

  private DriverOperationsDiagnosticsService service;

  @BeforeEach
  void setUp() {
    service =
        new DriverOperationsDiagnosticsService(
            driverRepository, driverLatestLocationRepository, driverTrackingSessionRepository);
  }

  @Test
  void classifiesDriverAsLiveWhenFreshValidLocationExists() {
    Driver driver = new Driver();
    driver.setId(100L);
    driver.setName("Live Driver");
    driver.setPhone("012345678");

    DriverLatestLocation latest =
        DriverLatestLocation.builder()
            .driverId(100L)
            .latitude(11.5564)
            .longitude(104.9282)
            .lastSeen(Timestamp.from(Instant.now().minusSeconds(15)))
            .source("ANDROID_NATIVE")
            .build();

    when(driverRepository.findAll()).thenReturn(List.of(driver));
    when(driverLatestLocationRepository.findAllLive()).thenReturn(List.of(latest));
    when(driverTrackingSessionRepository.findByRevokedAtIsNullOrderByLastSeenDesc()).thenReturn(List.of());

    List<DriverOperationsDiagnosticDto> diagnostics = service.listDiagnostics(false);

    assertThat(diagnostics).hasSize(1);
    DriverOperationsDiagnosticDto dto = diagnostics.get(0);
    assertThat(dto.getState()).isEqualTo("LIVE");
    assertThat(dto.getRecommendedAction()).isEqualTo("MONITOR");
    assertThat(dto.getValidCoordinates()).isTrue();
  }

  @Test
  void classifiesDriverAsNoGpsWhenFreshLocationIsZeroZero() {
    Driver driver = new Driver();
    driver.setId(101L);
    driver.setName("No GPS Driver");
    driver.setPhone("099999999");

    DriverLatestLocation latest =
        DriverLatestLocation.builder()
            .driverId(101L)
            .latitude(0.0)
            .longitude(0.0)
            .lastSeen(Timestamp.from(Instant.now().minusSeconds(20)))
            .build();

    DriverTrackingSession session =
        DriverTrackingSession.builder()
            .sessionId("sess-101")
            .driver(driver)
            .deviceId("device-101")
            .issuedAt(LocalDateTime.now().minusHours(1))
            .expiresAt(LocalDateTime.now().plusHours(1))
            .lastSeen(LocalDateTime.now().minusSeconds(20))
            .build();

    when(driverRepository.findAll()).thenReturn(List.of(driver));
    when(driverLatestLocationRepository.findAllLive()).thenReturn(List.of(latest));
    when(driverTrackingSessionRepository.findByRevokedAtIsNullOrderByLastSeenDesc())
        .thenReturn(List.of(session));

    List<DriverOperationsDiagnosticDto> diagnostics = service.listDiagnostics(false);

    assertThat(diagnostics).hasSize(1);
    DriverOperationsDiagnosticDto dto = diagnostics.get(0);
    assertThat(dto.getState()).isEqualTo("NO_GPS");
    assertThat(dto.getReasonCode()).isEqualTo("INVALID_COORDINATES");
    assertThat(dto.getRecommendedAction()).isEqualTo("CHECK_GPS_OR_PERMISSIONS");
    assertThat(dto.getValidCoordinates()).isFalse();
    assertThat(dto.getActiveTrackingSession()).isTrue();
  }
}
