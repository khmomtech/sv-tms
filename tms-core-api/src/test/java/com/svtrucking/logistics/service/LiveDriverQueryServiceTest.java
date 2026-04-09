package com.svtrucking.logistics.service;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anySet;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

import com.svtrucking.logistics.dto.LiveDriverDto;
import com.svtrucking.logistics.model.DriverLatestLocation;
import com.svtrucking.logistics.repository.DriverLatestLocationRepository;
import io.micrometer.core.instrument.simple.SimpleMeterRegistry;
import java.sql.Timestamp;
import java.time.Instant;
import java.util.List;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.test.util.ReflectionTestUtils;

@ExtendWith(MockitoExtension.class)
class LiveDriverQueryServiceTest {

  @Mock private DriverLatestLocationRepository latestRepo;
  @Mock private ActiveVehicleAssignmentReadService assignmentReadService;
  @Mock private DriverDirectoryReadService driverDirectoryReadService;

  private LiveDriverQueryService service;

  @BeforeEach
  void setUp() {
    service =
        new LiveDriverQueryService(
            latestRepo, assignmentReadService, driverDirectoryReadService, new SimpleMeterRegistry());
    ReflectionTestUtils.setField(service, "schedulingEnabled", true);
  }

  @Test
  @DisplayName("fallback returns online rows when findSince returns empty")
  void fallbackOnlineRowsWhenFindSinceEmpty() {
    long driverId = 30211L;
    Instant now = Instant.now();

    DriverLatestLocation latest =
        DriverLatestLocation.builder()
            .driverId(driverId)
            .latitude(11.5564)
            .longitude(104.9282)
            .lastSeen(Timestamp.from(now.minusSeconds(10)))
            .isOnline(true)
            .source("HEARTBEAT")
            .build();

    when(latestRepo.findSince(any())).thenReturn(List.of());
    when(latestRepo.findAllLive()).thenReturn(List.of(latest));
    when(driverDirectoryReadService.findByIds(anySet()))
        .thenReturn(
            java.util.Map.of(
                driverId,
                new DriverDirectoryReadService.DriverDirectoryRow(driverId, "testdriver KEHT", "123456789")));
    when(assignmentReadService.findActiveByDriverIds(anySet())).thenReturn(java.util.Map.of());

    List<LiveDriverDto> out = service.getLiveDrivers(true, 120, null, null, null, null);

    assertThat(out).hasSize(1);
    assertThat(out.get(0).getDriverId()).isEqualTo(driverId);
    assertThat(out.get(0).getOnline()).isTrue();
    assertThat(out.get(0).getLatitude()).isEqualTo(11.5564);
    assertThat(out.get(0).getLongitude()).isEqualTo(104.9282);
    assertThat(out.get(0).getLastSeenEpochMs()).isNotNull();
    assertThat(out.get(0).getLastSeenSeconds()).isNotNull();
    assertThat(out.get(0).getLastSeenSeconds()).isGreaterThanOrEqualTo(0);
    assertThat(out.get(0).getIngestLagSeconds()).isNotNull();
    assertThat(out.get(0).getIngestLagSeconds()).isGreaterThanOrEqualTo(0);
    verify(latestRepo).findAllLive();
  }

  @Test
  @DisplayName("does not use fallback when findSince already returns data")
  void noFallbackWhenFindSinceHasRows() {
    long driverId = 30212L;
    DriverLatestLocation latest =
        DriverLatestLocation.builder()
            .driverId(driverId)
            .latitude(11.55)
            .longitude(104.92)
            .lastSeen(Timestamp.from(Instant.now()))
            .isOnline(true)
            .build();
    when(latestRepo.findSince(any())).thenReturn(List.of(latest));
    when(driverDirectoryReadService.findByIds(anySet()))
        .thenReturn(
            java.util.Map.of(
                driverId,
                new DriverDirectoryReadService.DriverDirectoryRow(driverId, "Driver One", "090000000")));
    when(assignmentReadService.findActiveByDriverIds(anySet())).thenReturn(java.util.Map.of());

    List<LiveDriverDto> out = service.getLiveDrivers(true, 120, null, null, null, null);

    assertThat(out).hasSize(1);
    assertThat(out.get(0).getDriverId()).isEqualTo(driverId);
    assertThat(out.get(0).getLastSeenEpochMs()).isNotNull();
    assertThat(out.get(0).getLastSeenSeconds()).isNotNull();
    assertThat(out.get(0).getIngestLagSeconds()).isNotNull();
    assertThat(out.get(0).getLastSeenSeconds()).isGreaterThanOrEqualTo(0);
    assertThat(out.get(0).getIngestLagSeconds()).isGreaterThanOrEqualTo(0);
    verify(latestRepo, never()).findAllLive();
  }

  @Test
  @DisplayName("live driver query excludes invalid zero-zero coordinates")
  void excludesInvalidZeroZeroCoordinates() {
    long validDriverId = 30213L;
    long invalidDriverId = 30214L;
    Instant now = Instant.now();

    DriverLatestLocation valid =
        DriverLatestLocation.builder()
            .driverId(validDriverId)
            .latitude(11.5564)
            .longitude(104.9282)
            .lastSeen(Timestamp.from(now.minusSeconds(5)))
            .isOnline(true)
            .build();

    DriverLatestLocation invalid =
        DriverLatestLocation.builder()
            .driverId(invalidDriverId)
            .latitude(0.0)
            .longitude(0.0)
            .lastSeen(Timestamp.from(now.minusSeconds(5)))
            .isOnline(true)
            .build();

    when(latestRepo.findSince(any())).thenReturn(List.of(valid, invalid));
    when(driverDirectoryReadService.findByIds(anySet()))
        .thenReturn(
            java.util.Map.of(
                validDriverId,
                new DriverDirectoryReadService.DriverDirectoryRow(validDriverId, "Valid Driver", "090000001")));
    when(assignmentReadService.findActiveByDriverIds(anySet())).thenReturn(java.util.Map.of());

    List<LiveDriverDto> out = service.getLiveDrivers(true, 120, null, null, null, null);

    assertThat(out).hasSize(1);
    assertThat(out.get(0).getDriverId()).isEqualTo(validDriverId);
    assertThat(out.get(0).getLatitude()).isEqualTo(11.5564);
    assertThat(out.get(0).getLongitude()).isEqualTo(104.9282);
  }

  @Test
  @DisplayName("getLatestForDriver exposes telemetry freshness fields")
  void latestForDriverExposesFreshnessFields() {
    long driverId = 50001L;
    Instant now = Instant.now();
    DriverLatestLocation latest =
        DriverLatestLocation.builder()
            .driverId(driverId)
            .latitude(11.57)
            .longitude(104.91)
            .lastSeen(Timestamp.from(now.minusSeconds(5)))
            .isOnline(true)
            .source("NATIVE_IOS")
            .build();
    when(latestRepo.findById(driverId)).thenReturn(java.util.Optional.of(latest));

    var out = service.getLatestForDriver(driverId);

    assertThat(out).isPresent();
    LiveDriverDto dto = out.get();
    assertThat(dto.getDriverId()).isEqualTo(driverId);
    assertThat(dto.getLastSeenEpochMs()).isNotNull();
    assertThat(dto.getLastSeenSeconds()).isNotNull();
    assertThat(dto.getIngestLagSeconds()).isNotNull();
    assertThat(dto.getLastSeenSeconds()).isGreaterThanOrEqualTo(0);
    assertThat(dto.getIngestLagSeconds()).isGreaterThanOrEqualTo(0);
  }
}
