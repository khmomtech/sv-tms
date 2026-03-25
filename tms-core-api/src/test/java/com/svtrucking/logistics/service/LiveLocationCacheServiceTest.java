package com.svtrucking.logistics.service;

import com.svtrucking.logistics.dto.LiveDriverDto;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.data.redis.core.RedisTemplate;
import org.springframework.data.redis.core.ValueOperations;
import org.springframework.test.util.ReflectionTestUtils;

import java.time.Instant;
import java.util.Arrays;
import java.util.List;
import java.util.Map;
import java.util.Set;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.*;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class LiveLocationCacheServiceTest {

    @Mock
    private RedisTemplate<String, Object> redisTemplate;

    @Mock
    private ValueOperations<String, Object> valueOperations;

    private LiveLocationCacheService cacheService;

    @BeforeEach
    void setUp() {
        cacheService = new LiveLocationCacheService(redisTemplate);

        // Set up default values
        ReflectionTestUtils.setField(cacheService, "cachePrefix", "live:location:");
        ReflectionTestUtils.setField(cacheService, "cacheTtlMs", 300000L);
    }

    @Test
    @DisplayName("cacheDriverLocation stores location in Redis with TTL")
    void cacheDriverLocationStoresInRedis() {
        Long driverId = 123L;
        LiveDriverDto location = createTestLocation(driverId);

        when(redisTemplate.opsForValue()).thenReturn(valueOperations);

        cacheService.cacheDriverLocation(driverId, location);

        verify(valueOperations).set(eq("live:location:123"), eq(location), any());
    }

    @Test
    @DisplayName("cacheDriverLocation handles null inputs gracefully")
    void cacheDriverLocationHandlesNullInputs() {
        // Should not throw exceptions for null inputs and should not call Redis
        cacheService.cacheDriverLocation(null, createTestLocation(1L));
        cacheService.cacheDriverLocation(1L, null);
        cacheService.cacheDriverLocation(null, null);

        verify(redisTemplate, never()).opsForValue();
    }

    @Test
    @DisplayName("cacheDriverLocation handles Redis exceptions gracefully")
    void cacheDriverLocationHandlesRedisExceptions() {
        Long driverId = 123L;
        LiveDriverDto location = createTestLocation(driverId);

        when(redisTemplate.opsForValue()).thenReturn(valueOperations);
        doThrow(new RuntimeException("Redis connection failed"))
            .when(valueOperations).set(any(), any(), any());

        // Should not throw exception
        cacheService.cacheDriverLocation(driverId, location);

        verify(valueOperations).set(any(), any(), any());
    }

    @Test
    @DisplayName("getCachedDriverLocation retrieves from Redis")
    void getCachedDriverLocationRetrievesFromRedis() {
        Long driverId = 123L;
        LiveDriverDto expectedLocation = createTestLocation(driverId);

        when(redisTemplate.opsForValue()).thenReturn(valueOperations);
        when(valueOperations.get("live:location:123")).thenReturn(expectedLocation);

        LiveDriverDto result = cacheService.getCachedDriverLocation(driverId);

        assertThat(result).isEqualTo(expectedLocation);
        verify(valueOperations).get("live:location:123");
    }

    @Test
    @DisplayName("getCachedDriverLocation returns null for non-existent key")
    void getCachedDriverLocationReturnsNullForMissingKey() {
        Long driverId = 999L;

        when(redisTemplate.opsForValue()).thenReturn(valueOperations);
        when(valueOperations.get("live:location:999")).thenReturn(null);

        LiveDriverDto result = cacheService.getCachedDriverLocation(driverId);

        assertThat(result).isNull();
    }

    @Test
    @DisplayName("getCachedDriverLocation handles Redis exceptions")
    void getCachedDriverLocationHandlesRedisExceptions() {
        Long driverId = 123L;

        when(redisTemplate.opsForValue()).thenReturn(valueOperations);
        when(valueOperations.get(any())).thenThrow(new RuntimeException("Redis connection failed"));

        LiveDriverDto result = cacheService.getCachedDriverLocation(driverId);

        assertThat(result).isNull();
    }

    @Test
    @DisplayName("cacheDriverLocations handles empty/null inputs gracefully")
    void cacheDriverLocationsHandlesEmptyInputs() {
        // Should not throw exceptions for empty/null inputs
        cacheService.cacheDriverLocations(null);
        cacheService.cacheDriverLocations(Map.of());

        // No verification needed - just ensure no exceptions
    }

    @Test
    @DisplayName("getCachedDriverLocations retrieves multiple locations")
    void getCachedDriverLocationsRetrievesMultipleLocations() {
        List<Long> driverIds = List.of(1L, 2L, 3L);
        LiveDriverDto location1 = createTestLocation(1L);
        LiveDriverDto location2 = createTestLocation(2L);

        when(redisTemplate.opsForValue()).thenReturn(valueOperations);
        when(valueOperations.multiGet(anyList()))
            .thenReturn(Arrays.asList(location1, location2, null));

        Map<Long, LiveDriverDto> result = cacheService.getCachedDriverLocations(driverIds);

        assertThat(result).hasSize(2);
        assertThat(result.get(1L)).isEqualTo(location1);
        assertThat(result.get(2L)).isEqualTo(location2);
        assertThat(result.get(3L)).isNull();
    }

    @Test
    @DisplayName("evictDriverLocation removes from Redis")
    void evictDriverLocationRemovesFromRedis() {
        Long driverId = 123L;

        cacheService.evictDriverLocation(driverId);

        verify(redisTemplate).delete("live:location:123");
    }

    @Test
    @DisplayName("clearAllCache removes all cached locations")
    void clearAllCacheRemovesAllLocations() {
        Set<String> keys = Set.of("live:location:1", "live:location:2", "live:location:3");

        when(redisTemplate.keys("live:location:*")).thenReturn(keys);

        cacheService.clearAllCache();

        verify(redisTemplate).delete(keys);
    }

    @Test
    @DisplayName("getCacheStats returns correct statistics")
    void getCacheStatsReturnsCorrectStatistics() {
        Set<String> redisKeys = Set.of("live:location:1", "live:location:2");

        when(redisTemplate.keys("live:location:*")).thenReturn(redisKeys);

        CacheStats stats = cacheService.getCacheStats();

        assertThat(stats.entryCount).isEqualTo(2);
        assertThat(stats.memoryUsageBytes).isEqualTo(0); // Memory usage not available in test
    }

    @Test
    @DisplayName("getCacheStats handles Redis exceptions")
    void getCacheStatsHandlesRedisExceptions() {
        when(redisTemplate.keys(anyString())).thenThrow(new RuntimeException("Redis connection failed"));

        CacheStats stats = cacheService.getCacheStats();

        assertThat(stats.entryCount).isEqualTo(0);
        assertThat(stats.memoryUsageBytes).isEqualTo(0);
    }

    @Test
    @DisplayName("isDriverLocationCached checks Redis for key existence")
    void isDriverLocationCachedChecksRedis() {
        Long driverId = 123L;

        when(redisTemplate.hasKey("live:location:123")).thenReturn(true);

        boolean result = cacheService.isDriverLocationCached(driverId);

        assertThat(result).isTrue();
        verify(redisTemplate).hasKey("live:location:123");
    }

    @Test
    @DisplayName("getCacheTtl retrieves TTL from Redis")
    void getCacheTtlRetrievesFromRedis() {
        Long driverId = 123L;
        Long expectedTtl = 250L;

        when(redisTemplate.getExpire("live:location:123")).thenReturn(expectedTtl);

        Long result = cacheService.getCacheTtl(driverId);

        assertThat(result).isEqualTo(expectedTtl);
        verify(redisTemplate).getExpire("live:location:123");
    }

    private LiveDriverDto createTestLocation(Long driverId) {
        return LiveDriverDto.builder()
            .driverId(driverId)
            .latitude(11.5678)
            .longitude(104.9234)
            .locationName("Test Location")
            .updatedAt(Instant.now())
            .build();
    }
}
