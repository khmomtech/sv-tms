package com.svtrucking.logistics.service;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anySet;
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

@ExtendWith(MockitoExtension.class)
class LiveDriverQueryServiceGeocodeStatusTest {

  @Mock private DriverLatestLocationRepository latestRepo;
  @Mock private ActiveVehicleAssignmentReadService assignmentReadService;
  @Mock private DriverDirectoryReadService driverDirectoryReadService;

  private LiveDriverQueryService service;

  @BeforeEach
  void setUp() {
    service =
        new LiveDriverQueryService(
            latestRepo, assignmentReadService, driverDirectoryReadService, new SimpleMeterRegistry());
  }

  @Test
  @DisplayName("returns resolved geocode status when address exists")
  void returnsResolvedGeocodeStatus() {
    long driverId = 70001L;
    DriverLatestLocation latest =
        DriverLatestLocation.builder()
            .driverId(driverId)
            .latitude(11.5564)
            .longitude(104.9282)
            .locationName("Sangkat Boeung Kak, Phnom Penh")
            .lastSeen(Timestamp.from(Instant.now().minusSeconds(10)))
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
    assertThat(out.get(0).getLocationName()).isEqualTo("Sangkat Boeung Kak, Phnom Penh");
    assertThat(out.get(0).getGeocodeStatus()).isEqualTo("resolved");
  }

  @Test
  @DisplayName("returns pending geocode status for online drivers without resolved address")
  void returnsPendingGeocodeStatus() {
    long driverId = 70002L;
    DriverLatestLocation latest =
        DriverLatestLocation.builder()
            .driverId(driverId)
            .latitude(11.5564)
            .longitude(104.9282)
            .locationName("Unknown location")
            .lastSeen(Timestamp.from(Instant.now().minusSeconds(5)))
            .isOnline(true)
            .build();

    when(latestRepo.findSince(any())).thenReturn(List.of(latest));
    when(driverDirectoryReadService.findByIds(anySet()))
        .thenReturn(
            java.util.Map.of(
                driverId,
                new DriverDirectoryReadService.DriverDirectoryRow(driverId, "Driver Two", "090000001")));
    when(assignmentReadService.findActiveByDriverIds(anySet())).thenReturn(java.util.Map.of());

    List<LiveDriverDto> out = service.getLiveDrivers(true, 120, null, null, null, null);

    assertThat(out).hasSize(1);
    assertThat(out.get(0).getLocationName()).isNull();
    assertThat(out.get(0).getGeocodeStatus()).isEqualTo("pending");
  }

  @Test
  @DisplayName("returns failed geocode status for offline drivers without resolved address")
  void returnsFailedGeocodeStatus() {
    long driverId = 70003L;
    DriverLatestLocation latest =
        DriverLatestLocation.builder()
            .driverId(driverId)
            .latitude(11.57)
            .longitude(104.91)
            .locationName("Unknown location")
            .lastSeen(Timestamp.from(Instant.now().minusSeconds(600)))
            .isOnline(false)
            .build();

    when(latestRepo.findById(driverId)).thenReturn(java.util.Optional.of(latest));

    var out = service.getLatestForDriver(driverId);

    assertThat(out).isPresent();
    assertThat(out.get().getLocationName()).isNull();
    assertThat(out.get().getGeocodeStatus()).isEqualTo("failed");
  }
}
