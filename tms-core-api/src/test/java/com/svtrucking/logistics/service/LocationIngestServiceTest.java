package com.svtrucking.logistics.service;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.*;
import static org.mockito.Mockito.*;

import com.svtrucking.logistics.core.service.GeocodingService;
import com.svtrucking.logistics.dto.LiveDriverDto;
import com.svtrucking.logistics.dto.requests.DriverLocationUpdateDto;
import com.svtrucking.logistics.model.Driver;
import com.svtrucking.logistics.repository.DriverLatestLocationRepository;
import com.svtrucking.logistics.repository.LocationHistoryRepository;
import jakarta.persistence.EntityManager;
import java.lang.reflect.Constructor;
import java.lang.reflect.Method;
import java.sql.Timestamp;
import java.util.Map;
import java.util.Optional;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.test.util.ReflectionTestUtils;

@ExtendWith(MockitoExtension.class)
class LocationIngestServiceTest {

  @Mock private DriverLatestLocationRepository latestRepo;
  @Mock private LocationHistoryRepository historyRepo;
  @Mock private GeocodingService geocodingService;
  @Mock private LiveLocationCacheService cacheService;
  @Mock private DriverLocationMongoService mongoService;
  @Mock private LocationHistorySpoolService spoolService;
  @Mock private EntityManager entityManager;

  private LocationIngestService service;

  @BeforeEach
  void setUp() throws Exception {
    service =
        new LocationIngestService(
            latestRepo, historyRepo, geocodingService, cacheService, mongoService, spoolService);

    ReflectionTestUtils.setField(service, "em", entityManager);
    ReflectionTestUtils.setField(service, "SERVER_THROTTLE_MS", 0L);
    ReflectionTestUtils.setField(service, "SERVER_MIN_DIST_M", 0.0d);
    ReflectionTestUtils.setField(service, "MAX_IDLE_KEEPALIVE_MS", 60_000L);
    ReflectionTestUtils.setField(service, "SERVER_MIN_TIME_MS", 0L);
    ReflectionTestUtils.setField(service, "BATCH_FLUSH_MS", 1_000L);
    ReflectionTestUtils.setField(service, "BATCH_MAX_RECORDS", 100);
    ReflectionTestUtils.setField(service, "QUEUE_CAPACITY", 100);
    ReflectionTestUtils.setField(service, "mysqlHistoryWriteEnabled", false);
    ReflectionTestUtils.setField(service, "spoolEnabled", true);
    ReflectionTestUtils.setField(service, "spoolReplayBatchSize", 100);
    ReflectionTestUtils.setField(service, "schedulingEnabled", true);
    ReflectionTestUtils.setField(service, "PRESENCE_ONLINE_MS", 35_000L);
    ReflectionTestUtils.setField(service, "PRESENCE_IDLE_MS", 180_000L);
    ReflectionTestUtils.setField(service, "GEOCODE_MIN_DISTANCE_M", 200.0d);
    ReflectionTestUtils.setField(service, "PRESENCE_SWEEPER_MS", 10_000L);

    service.initBuffer();

    when(entityManager.getReference(eq(Driver.class), anyLong()))
        .thenAnswer(
            invocation -> {
              Long id = invocation.getArgument(1);
              Driver driver = new Driver();
              driver.setId(id);
              return driver;
            });

    when(latestRepo.upsertLatest(
            anyLong(),
            anyDouble(),
            anyDouble(),
            any(),
            any(),
            any(),
            any(),
            any(),
            any(),
            anyBoolean(),
            any(),
            any(),
            any(),
            any()))
        .thenReturn(1);
    when(latestRepo.findById(anyLong())).thenReturn(Optional.empty());
  }

  @Test
  @DisplayName("reverse geocoding is invoked when movement exceeds configured distance")
  void reverseGeocodeWhenBeyondThreshold() {
    long driverId = 42L;
    double lat = 11.0d;
    double lng = 104.0d;

    DriverLocationUpdateDto dto =
        DriverLocationUpdateDto.builder()
            .driverId(driverId)
            .latitude(lat)
            .longitude(lng)
            .clientTime(1_000L)
            .build();

    when(geocodingService.reverseGeocode(lat, lng)).thenReturn("Wat Phnom");

    Map<String, Object> live = service.accept(dto);

    assertThat(live).isNotNull();
    assertThat(live.get("locationName")).isEqualTo("Wat Phnom");
    verify(geocodingService).reverseGeocode(lat, lng);
  }

  @Test
  @DisplayName("cached location name is reused when the driver stays within the geocode radius")
  void reuseCachedLocationWhenWithinRadius() {
    long driverId = 77L;

    DriverLocationUpdateDto initial =
        DriverLocationUpdateDto.builder()
            .driverId(driverId)
            .latitude(11.0d)
            .longitude(104.0d)
            .clientTime(2_000L)
            .build();

    when(geocodingService.reverseGeocode(11.0d, 104.0d)).thenReturn("Central Market");
    service.accept(initial);

    clearInvocations(geocodingService);

    DriverLocationUpdateDto followUp =
        DriverLocationUpdateDto.builder()
            .driverId(driverId)
            .latitude(11.0005d)
            .longitude(104.0005d)
            .clientTime(2_500L)
            .build();

    Map<String, Object> live = service.accept(followUp);

    assertThat(live).isNotNull();
    assertThat(live.get("locationName")).isEqualTo("Central Market");
    verify(geocodingService, never()).reverseGeocode(anyDouble(), anyDouble());
  }

  @Test
  @DisplayName("lastGeo cache tracks client-supplied location names")
  void updateLastGeoCacheWithClientProvidedName() throws Exception {
    long driverId = 7L;

    Class<?> lastGeoClass =
        Class.forName("com.svtrucking.logistics.service.LocationIngestService$LastGeo");
    Constructor<?> ctor =
        lastGeoClass.getDeclaredConstructor(double.class, double.class, String.class);
    ctor.setAccessible(true);

    Object existing = ctor.newInstance(0.0d, 0.0d, "Old Name");
    @SuppressWarnings("unchecked")
    Map<Long, Object> lastGeoMap =
        (Map<Long, Object>) ReflectionTestUtils.getField(service, "lastGeoName");
    if (lastGeoMap != null) {
      lastGeoMap.put(driverId, existing);
    }

    DriverLocationUpdateDto dto =
        DriverLocationUpdateDto.builder()
            .driverId(driverId)
            .latitude(13.3611d)
            .longitude(103.8597d)
            .locationName("Angkor Wat")
            .clientTime(3_000L)
            .build();

    when(latestRepo.findById(driverId))
        .thenReturn(
            Optional.ofNullable(
                com.svtrucking.logistics.model.DriverLatestLocation.builder()
                    .driverId(driverId)
                    .latitude(dto.getLatitude())
                    .longitude(dto.getLongitude())
                    .lastSeen(new Timestamp(System.currentTimeMillis()))
                    .wsConnected(false)
                    .locationName(dto.getLocationName())
                    .build()));

    service.accept(dto);

    Object updated = lastGeoMap != null ? lastGeoMap.get(driverId) : null;
    Method latMethod = lastGeoClass.getDeclaredMethod("lat");
    Method nameMethod = lastGeoClass.getDeclaredMethod("name");

    assertThat(updated).isNotNull();
    assertThat((double) latMethod.invoke(updated)).isEqualTo(dto.getLatitude());
    assertThat((String) nameMethod.invoke(updated)).isEqualTo("Angkor Wat");
  }

  @Test
  @DisplayName("location update caches driver location data")
  void locationUpdateCachesDriverLocation() {
    long driverId = 123L;
    double lat = 11.5678d;
    double lng = 104.9234d;

    DriverLocationUpdateDto dto =
        DriverLocationUpdateDto.builder()
            .driverId(driverId)
            .latitude(lat)
            .longitude(lng)
            .clientTime(System.currentTimeMillis())
            .build();

    when(geocodingService.reverseGeocode(lat, lng)).thenReturn("Test Location");

    service.accept(dto);

    verify(cacheService).cacheDriverLocation(eq(driverId), any(LiveDriverDto.class));
  }

  @Test
  @DisplayName("location update handles cache service failure gracefully")
  void locationUpdateHandlesCacheFailureGracefully() {
    long driverId = 456L;
    double lat = 12.3456d;
    double lng = 105.6789d;

    DriverLocationUpdateDto dto =
        DriverLocationUpdateDto.builder()
            .driverId(driverId)
            .latitude(lat)
            .longitude(lng)
            .clientTime(System.currentTimeMillis())
            .build();

    // Simulate cache service failure
    doThrow(new RuntimeException("Redis connection failed")).when(cacheService)
        .cacheDriverLocation(eq(driverId), any(LiveDriverDto.class));

    when(geocodingService.reverseGeocode(lat, lng)).thenReturn("Test Location");

    // Should not throw exception despite cache failure
    Map<String, Object> result = service.accept(dto);

    assertThat(result).isNotNull();
    assertThat(result.get("driverId")).isEqualTo(driverId);
    assertThat(result.get("latitude")).isEqualTo(lat);
    assertThat(result.get("longitude")).isEqualTo(lng);
  }

  @Test
  @DisplayName("location update includes all required fields in cached data")
  void locationUpdateIncludesAllFieldsInCachedData() {
    long driverId = 789L;
    double lat = 13.1234d;
    double lng = 106.5678d;
    long clientTime = System.currentTimeMillis();
    String locationName = "Test Location";

    DriverLocationUpdateDto dto =
        DriverLocationUpdateDto.builder()
            .driverId(driverId)
            .latitude(lat)
            .longitude(lng)
            .clientTime(clientTime)
            .locationName(locationName)
            .build();

    service.accept(dto);

    verify(cacheService).cacheDriverLocation(eq(driverId), argThat(cachedLocation -> {
      assertThat(cachedLocation).isNotNull();
      assertThat(cachedLocation.getDriverId()).isEqualTo(driverId);
      assertThat(cachedLocation.getLatitude()).isEqualTo(lat);
      assertThat(cachedLocation.getLongitude()).isEqualTo(lng);
      assertThat(cachedLocation.getLocationName()).isEqualTo(locationName);
      assertThat(cachedLocation.getUpdatedAt()).isNotNull();
      return true;
    }));
  }

  @Test
  @DisplayName("batch location updates cache all driver locations")
  void batchLocationUpdatesCacheAllLocations() {
    // This test would require mocking the batch processing logic
    // For now, we verify that individual caching works as expected
    long driverId1 = 111L;
    long driverId2 = 222L;

    DriverLocationUpdateDto dto1 =
        DriverLocationUpdateDto.builder()
            .driverId(driverId1)
            .latitude(11.0d)
            .longitude(104.0d)
            .clientTime(System.currentTimeMillis())
            .build();

    DriverLocationUpdateDto dto2 =
        DriverLocationUpdateDto.builder()
            .driverId(driverId2)
            .latitude(12.0d)
            .longitude(105.0d)
            .clientTime(System.currentTimeMillis())
            .build();

    when(geocodingService.reverseGeocode(anyDouble(), anyDouble())).thenReturn("Location");

    service.accept(dto1);
    service.accept(dto2);

    verify(cacheService, times(2)).cacheDriverLocation(anyLong(), any(LiveDriverDto.class));
  }

  @Test
  @DisplayName("queue overflow persists location via fallback history stores instead of dropping")
  void queueOverflowPersistsDirectly() {
    ReflectionTestUtils.setField(service, "QUEUE_CAPACITY", 1);
    service.initBuffer();

    DriverLocationUpdateDto first =
        DriverLocationUpdateDto.builder()
            .driverId(1L)
            .latitude(11.0000d)
            .longitude(104.0000d)
            .clientTime(1_000L)
            .build();
    DriverLocationUpdateDto second =
        DriverLocationUpdateDto.builder()
            .driverId(1L)
            .latitude(11.1000d)
            .longitude(104.1000d)
            .clientTime(2_000L)
            .build();

    service.accept(first);
    service.accept(second);

    verify(mongoService, atLeastOnce()).trySaveAll(anyList());
    verify(spoolService, atLeastOnce()).appendBatch(anyList());
  }

  @Test
  @DisplayName("shutdown flush persists buffered points to history fallback stores")
  void shutdownFlushPersistsBufferedPoints() {
    DriverLocationUpdateDto dto =
        DriverLocationUpdateDto.builder()
            .driverId(88L)
            .latitude(11.2222d)
            .longitude(104.3333d)
            .clientTime(5_000L)
            .build();

    service.accept(dto);
    service.flushBufferOnShutdown();

    verify(mongoService, atLeastOnce()).trySaveAll(anyList());
    verify(spoolService, atLeastOnce()).appendBatch(anyList());
  }

  @Test
  @DisplayName("flush batch falls back to row-by-row MySQL save when MySQL batch save fails")
  void flushBatchFallsBackToPerRowSave() {
    ReflectionTestUtils.setField(service, "mysqlHistoryWriteEnabled", true);
    DriverLocationUpdateDto dto1 =
        DriverLocationUpdateDto.builder()
            .driverId(91L)
            .latitude(12.0000d)
            .longitude(105.0000d)
            .clientTime(7_000L)
            .build();
    DriverLocationUpdateDto dto2 =
        DriverLocationUpdateDto.builder()
            .driverId(92L)
            .latitude(12.1000d)
            .longitude(105.1000d)
            .clientTime(8_000L)
            .build();

    service.accept(dto1);
    service.accept(dto2);

    doThrow(new RuntimeException("batch failed")).when(historyRepo).saveAll(anyList());

    service.flushBatch();

    verify(historyRepo, atLeastOnce()).saveAll(anyList());
    verify(historyRepo, atLeast(2)).save(any());
  }
}
