package com.svtrucking.logistics.service;

import com.svtrucking.logistics.dto.LiveDriverDto;
import java.util.List;
import java.util.Map;

/** Interface for live location caching service. */
public interface LiveLocationCacheServiceInterface {

  void cacheDriverLocation(Long driverId, LiveDriverDto location);

  LiveDriverDto getCachedDriverLocation(Long driverId);

  Map<Long, LiveDriverDto> getCachedDriverLocations(List<Long> driverIds);

  void removeDriverLocation(Long driverId);

  void clearAllDriverLocations();

  void clearExpiredLocations();

  CacheStats getCacheStats();

  boolean isDriverOnline(Long driverId);

  void markDriverOnline(Long driverId);

  void markDriverOffline(Long driverId);

  void cacheDriverLocations(Map<Long, LiveDriverDto> locations);

  void evictDriverLocation(Long driverId);

  void clearAllCache();

  boolean isDriverLocationCached(Long driverId);

  Long getCacheTtl(Long driverId);
}
