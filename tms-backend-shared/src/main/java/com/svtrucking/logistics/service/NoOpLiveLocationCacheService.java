package com.svtrucking.logistics.service;

import com.svtrucking.logistics.dto.LiveDriverDto;
import java.util.Collections;
import java.util.List;
import java.util.Map;
import lombok.extern.slf4j.Slf4j;
import org.springframework.boot.autoconfigure.condition.ConditionalOnExpression;
import org.springframework.stereotype.Service;

/**
 * No-op implementation of LiveLocationCacheService when Redis is disabled.
 * Provides empty implementations to allow the application to run without Redis.
 */
@Service
@Slf4j
// No-op when Redis is intentionally disabled (host is 'none' or 'disabled')
@ConditionalOnExpression("'${spring.data.redis.host:}'.equals('none') or '${spring.data.redis.host:}'.equals('disabled')")
public class NoOpLiveLocationCacheService implements LiveLocationCacheServiceInterface {

  @Override
  public void cacheDriverLocation(Long driverId, LiveDriverDto location) {
    log.debug("Redis disabled: Skipping cache operation for driver {}", driverId);
  }

  @Override
  public LiveDriverDto getCachedDriverLocation(Long driverId) {
    log.debug("Redis disabled: Returning null for cached driver location {}", driverId);
    return null;
  }

  @Override
  public Map<Long, LiveDriverDto> getCachedDriverLocations(List<Long> driverIds) {
    log.debug("Redis disabled: Returning empty map for cached driver locations");
    return Collections.emptyMap();
  }

  @Override
  public void removeDriverLocation(Long driverId) {
    log.debug("Redis disabled: Skipping remove operation for driver {}", driverId);
  }

  @Override
  public void clearAllDriverLocations() {
    log.debug("Redis disabled: Skipping clear all operation");
  }

  @Override
  public void clearExpiredLocations() {
    log.debug("Redis disabled: Skipping clear expired operation");
  }

  @Override
  public CacheStats getCacheStats() {
    log.debug("Redis disabled: Returning empty cache stats");
    return new CacheStats(0, 0);
  }

  @Override
  public boolean isDriverOnline(Long driverId) {
    log.debug("Redis disabled: Returning false for driver online check {}", driverId);
    return false;
  }

  @Override
  public void markDriverOnline(Long driverId) {
    log.debug("Redis disabled: Skipping mark online for driver {}", driverId);
  }

  @Override
  public void markDriverOffline(Long driverId) {
    log.debug("Redis disabled: Skipping mark offline for driver {}", driverId);
  }

  @Override
  public void cacheDriverLocations(Map<Long, LiveDriverDto> locations) {
    log.debug("Redis disabled: Skipping batch cache operation");
  }

  @Override
  public void evictDriverLocation(Long driverId) {
    log.debug("Redis disabled: Skipping evict operation for driver {}", driverId);
  }

  @Override
  public void clearAllCache() {
    log.debug("Redis disabled: Skipping clear all cache operation");
  }

  @Override
  public boolean isDriverLocationCached(Long driverId) {
    log.debug("Redis disabled: Returning false for cached location check {}", driverId);
    return false;
  }

  @Override
  public Long getCacheTtl(Long driverId) {
    log.debug("Redis disabled: Returning null for cache TTL {}", driverId);
    return null;
  }
}
