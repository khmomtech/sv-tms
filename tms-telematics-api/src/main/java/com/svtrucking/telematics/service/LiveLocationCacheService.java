package com.svtrucking.telematics.service;

import com.svtrucking.telematics.dto.LiveDriverDto;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.autoconfigure.condition.ConditionalOnExpression;
import org.springframework.data.redis.core.RedisTemplate;
import org.springframework.stereotype.Service;

import java.time.Duration;
import java.util.List;
import java.util.Map;

/**
 * Redis-based live location cache for tms-telematics-api.
 * Uses prefix 'tele:location:' (configured via app.cache.live-location.prefix).
 */
@Service
@RequiredArgsConstructor
@Slf4j
@ConditionalOnExpression("!'${spring.data.redis.host:}'.equals('disabled')")
public class LiveLocationCacheService implements LiveLocationCacheServiceInterface {

    private final RedisTemplate<String, Object> redisTemplate;

    @Value("${app.cache.live-location.prefix:tele:location:}")
    private String cachePrefix;

    @Value("${app.cache.live-location.ttl:300000}")
    private long cacheTtlMs;

    @Override
    public void cacheDriverLocation(Long driverId, LiveDriverDto location) {
        if (driverId == null || location == null)
            return;
        try {
            redisTemplate.opsForValue().set(cachePrefix + driverId, location, Duration.ofMillis(cacheTtlMs));
        } catch (Exception e) {
            log.warn("Failed to cache location for driver {}: {}", driverId, e.getMessage());
        }
    }

    @Override
    public LiveDriverDto getCachedDriverLocation(Long driverId) {
        if (driverId == null)
            return null;
        try {
            return (LiveDriverDto) redisTemplate.opsForValue().get(cachePrefix + driverId);
        } catch (Exception e) {
            log.warn("Failed to get cached location for driver {}: {}", driverId, e.getMessage());
            return null;
        }
    }

    public void cacheDriverLocations(Map<Long, LiveDriverDto> locations) {
        if (locations == null || locations.isEmpty())
            return;
        locations.forEach(this::cacheDriverLocation);
    }

    public Map<Long, LiveDriverDto> getCachedDriverLocations(List<Long> driverIds) {
        if (driverIds == null || driverIds.isEmpty())
            return Map.of();
        try {
            List<String> keys = driverIds.stream().map(id -> cachePrefix + id).toList();
            List<Object> values = redisTemplate.opsForValue().multiGet(keys);
            Map<Long, LiveDriverDto> result = new java.util.HashMap<>();
            for (int i = 0; i < driverIds.size(); i++) {
                LiveDriverDto loc = (LiveDriverDto) values.get(i);
                if (loc != null)
                    result.put(driverIds.get(i), loc);
            }
            return result;
        } catch (Exception e) {
            log.warn("Failed to get cached locations: {}", e.getMessage());
            return Map.of();
        }
    }

    @Override
    public void removeDriverLocation(Long driverId) {
        if (driverId == null)
            return;
        try {
            redisTemplate.delete(cachePrefix + driverId);
        } catch (Exception e) {
            log.warn("Failed to evict cached location for driver {}: {}", driverId, e.getMessage());
        }
    }

    @Override
    public void clearAllDriverLocations() {
        try {
            var keys = redisTemplate.keys(cachePrefix + "*");
            if (keys != null && !keys.isEmpty())
                redisTemplate.delete(keys);
        } catch (Exception e) {
            log.warn("Failed to clear all cached locations: {}", e.getMessage());
        }
    }

    @Override
    public void clearExpiredLocations() {
        // Redis handles TTL expiration automatically
    }

    @Override
    public boolean isDriverOnline(Long driverId) {
        if (driverId == null)
            return false;
        try {
            return Boolean.TRUE.equals(redisTemplate.hasKey(cachePrefix + driverId));
        } catch (Exception e) {
            return false;
        }
    }

    @Override
    public void markDriverOnline(Long driverId) {
        // Online status is inferred from cached location presence
    }

    @Override
    public void markDriverOffline(Long driverId) {
        removeDriverLocation(driverId);
    }
}
