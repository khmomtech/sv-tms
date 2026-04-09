package com.svtrucking.logistics.service;

import com.svtrucking.logistics.dto.LiveDriverDto;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.autoconfigure.condition.ConditionalOnExpression;
import org.springframework.cache.annotation.CacheEvict;
import org.springframework.cache.annotation.Cacheable;
import org.springframework.data.redis.core.RedisTemplate;
import org.springframework.data.redis.core.RedisCallback;
import org.springframework.stereotype.Service;

import java.time.Duration;

import java.util.List;
import java.util.Map;

/**
 * Redis-based caching service for live driver location data.
 * Provides high-performance caching to reduce database load and improve
 * response times.
 * Only enabled when Redis is available (spring.data.redis.host != disabled).
 */
@Service
@RequiredArgsConstructor
@Slf4j
@ConditionalOnExpression("!'${spring.data.redis.host:}'.equals('disabled')")
public class LiveLocationCacheService implements LiveLocationCacheServiceInterface {

    private final RedisTemplate<String, Object> redisTemplate;

    @Value("${app.cache.live-location.prefix:live:location:}")
    private String cachePrefix;

    @Value("${app.cache.live-location.ttl:300000}")
    private long cacheTtlMs;

    /** Dedicated presence key prefix — separate from the location cache. */
    private static final String PRESENCE_PREFIX = "presence:driver:";

    /**
     * Presence key TTL: aligns with DriverLocationController.ONLINE_MS (35 s) +
     * buffer.
     */
    private static final java.time.Duration PRESENCE_TTL = java.time.Duration.ofSeconds(45);

    /**
     * Cache a driver's live location data
     */
    public void cacheDriverLocation(Long driverId, LiveDriverDto location) {
        if (driverId == null || location == null) {
            log.debug("Skipping cache operation for null driverId or location");
            return;
        }

        String key = cachePrefix + driverId;
        try {
            redisTemplate.opsForValue().set(key, location, Duration.ofMillis(cacheTtlMs));
            log.debug("Cached location for driver {}: {}", driverId, location.getLocationName());
        } catch (Exception e) {
            log.warn("Failed to cache location for driver {}: {}", driverId, e.getMessage(), e);
        }
    }

    /**
     * Get cached driver location
     */
    @Cacheable(value = "liveLocations", key = "#driverId")
    public LiveDriverDto getCachedDriverLocation(Long driverId) {
        if (driverId == null) {
            return null;
        }

        String key = cachePrefix + driverId;
        try {
            LiveDriverDto cached = (LiveDriverDto) redisTemplate.opsForValue().get(key);
            if (cached != null) {
                log.debug("Retrieved cached location for driver {}", driverId);
            } else {
                log.debug("No cached location found for driver {}", driverId);
            }
            return cached;
        } catch (Exception e) {
            log.warn("Failed to get cached location for driver {}: {}", driverId, e.getMessage(), e);
            return null;
        }
    }

    /**
     * Cache multiple driver locations asynchronously for better performance
     */
    public void cacheDriverLocations(Map<Long, LiveDriverDto> locations) {
        if (locations == null || locations.isEmpty()) {
            return;
        }

        try {
            // Use pipelining for batch operations
            redisTemplate.executePipelined((RedisCallback<Object>) connection -> {
                locations.forEach((driverId, location) -> {
                    String key = cachePrefix + driverId;
                    try {
                        redisTemplate.opsForValue().set(key, location, Duration.ofMillis(cacheTtlMs));
                    } catch (Exception e) {
                        log.warn("Failed to cache location for driver {} in batch: {}", driverId, e.getMessage());
                    }
                });
                return null;
            });

            log.debug("Cached {} driver locations", locations.size());
        } catch (Exception e) {
            log.warn("Failed to batch cache driver locations: {}", e.getMessage(), e);
        }
    }

    /**
     * Get multiple cached driver locations with pipelining for performance
     */
    public Map<Long, LiveDriverDto> getCachedDriverLocations(List<Long> driverIds) {
        if (driverIds == null || driverIds.isEmpty()) {
            return Map.of();
        }

        try {
            List<String> keys = driverIds.stream()
                    .map(id -> cachePrefix + id)
                    .toList();

            List<Object> cachedValues = redisTemplate.opsForValue().multiGet(keys);
            Map<Long, LiveDriverDto> result = new java.util.HashMap<>();

            for (int i = 0; i < driverIds.size(); i++) {
                Long driverId = driverIds.get(i);
                LiveDriverDto location = (LiveDriverDto) cachedValues.get(i);
                if (location != null) {
                    result.put(driverId, location);
                }
            }

            log.debug("Retrieved {} cached locations out of {} requested", result.size(), driverIds.size());
            return result;
        } catch (Exception e) {
            log.warn("Failed to get cached locations for drivers {}: {}", driverIds, e.getMessage(), e);
            return Map.of();
        }
    }

    /**
     * Remove driver location from cache
     */
    @CacheEvict(value = "liveLocations", key = "#driverId")
    public void evictDriverLocation(Long driverId) {
        if (driverId == null) {
            return;
        }

        String key = cachePrefix + driverId;
        try {
            Boolean deleted = redisTemplate.delete(key);
            if (Boolean.TRUE.equals(deleted)) {
                log.debug("Evicted cached location for driver {}", driverId);
            } else {
                log.debug("No cached location found to evict for driver {}", driverId);
            }
        } catch (Exception e) {
            log.warn("Failed to evict cached location for driver {}: {}", driverId, e.getMessage(), e);
        }
    }

    /**
     * Clear all cached locations with pattern matching
     */
    @CacheEvict(value = "liveLocations", allEntries = true)
    public void clearAllCache() {
        try {
            String pattern = cachePrefix + "*";
            long deletedCount = redisTemplate.delete(redisTemplate.keys(pattern));
            log.info("Cleared {} cached driver locations", deletedCount);
        } catch (Exception e) {
            log.warn("Failed to clear all cached locations: {}", e.getMessage(), e);
        }
    }

    /**
     * Get cache statistics for monitoring
     */
    public CacheStats getCacheStats() {
        try {
            String pattern = cachePrefix + "*";
            long redisCount = redisTemplate.keys(pattern).size();
            long memoryUsage = getMemoryUsage();

            return new CacheStats(redisCount, memoryUsage);
        } catch (Exception e) {
            log.warn("Failed to get cache stats: {}", e.getMessage(), e);
            return new CacheStats(0, 0);
        }
    }

    /**
     * Check if driver location is cached
     */
    public boolean isDriverLocationCached(Long driverId) {
        if (driverId == null) {
            return false;
        }

        try {
            String key = cachePrefix + driverId;
            return Boolean.TRUE.equals(redisTemplate.hasKey(key));
        } catch (Exception e) {
            log.warn("Failed to check if driver location is cached for {}: {}", driverId, e.getMessage());
            return false;
        }
    }

    /**
     * Get cache TTL for a driver location
     */
    public Long getCacheTtl(Long driverId) {
        if (driverId == null) {
            return null;
        }

        try {
            String key = cachePrefix + driverId;
            return redisTemplate.getExpire(key);
        } catch (Exception e) {
            log.warn("Failed to get cache TTL for driver {}: {}", driverId, e.getMessage());
            return null;
        }
    }

    private long getMemoryUsage() {
        try {
            // Get memory usage info from Redis
            Object info = redisTemplate
                    .execute((RedisCallback<Object>) connection -> connection.serverCommands().info("memory"));
            if (info instanceof String) {
                String memoryInfo = (String) info;
                // Parse used_memory from INFO output
                for (String line : memoryInfo.split("\\r?\\n")) {
                    if (line.startsWith("used_memory:")) {
                        return Long.parseLong(line.split(":")[1]);
                    }
                }
            }
            return 0;
        } catch (Exception e) {
            log.debug("Could not retrieve Redis memory usage: {}", e.getMessage());
            return 0;
        }
    }

    /**
     * Remove driver location from cache (alias for evictDriverLocation)
     */
    @Override
    public void removeDriverLocation(Long driverId) {
        evictDriverLocation(driverId);
    }

    /**
     * Clear all driver locations (alias for clearAllCache)
     */
    @Override
    public void clearAllDriverLocations() {
        clearAllCache();
    }

    /**
     * Clear expired locations (no-op for Redis implementation)
     */
    @Override
    public void clearExpiredLocations() {
        // Redis handles expiration automatically
        log.debug("Redis handles expiration automatically, no manual cleanup needed");
    }

    /**
     * Check if driver is online.
     * Uses a dedicated short-lived presence key (45 s TTL) that is refreshed on
     * every GPS ping, giving accurate real-time online/offline detection.
     */
    @Override
    public boolean isDriverOnline(Long driverId) {
        if (driverId == null) {
            return false;
        }
        try {
            return Boolean.TRUE.equals(redisTemplate.hasKey(PRESENCE_PREFIX + driverId));
        } catch (Exception ex) {
            log.warn("Failed to check presence key for driver {}: {}", driverId, ex.getMessage());
            return false;
        }
    }

    /**
     * Mark driver as online by refreshing the dedicated presence key (TTL 45 s).
     * Must be called on every accepted GPS ping or presence heartbeat.
     */
    @Override
    public void markDriverOnline(Long driverId) {
        if (driverId == null) {
            return;
        }
        try {
            redisTemplate.opsForValue().set(PRESENCE_PREFIX + driverId, "1", PRESENCE_TTL);
            log.debug("Driver {} marked online (presence key refreshed)", driverId);
        } catch (Exception ex) {
            log.warn("Failed to set presence key for driver {}: {}", driverId, ex.getMessage());
        }
    }

    /**
     * Mark driver as offline by removing the presence key and evicting the
     * location cache entry.
     */
    @Override
    public void markDriverOffline(Long driverId) {
        evictDriverLocation(driverId);
        if (driverId == null) {
            return;
        }
        try {
            redisTemplate.delete(PRESENCE_PREFIX + driverId);
            log.debug("Driver {} marked offline (presence + location keys removed)", driverId);
        } catch (Exception ex) {
            log.warn("Failed to delete presence key for driver {}: {}", driverId, ex.getMessage());
        }
    }
}
