package com.svtrucking.telematics.service;

import com.svtrucking.telematics.dto.LiveDriverDto;

/**
 * Interface for live location caching so the implementation can be swapped
 * (Redis when available, no-op in test).
 */
public interface LiveLocationCacheServiceInterface {

    void cacheDriverLocation(Long driverId, LiveDriverDto location);

    LiveDriverDto getCachedDriverLocation(Long driverId);

    void removeDriverLocation(Long driverId);

    void clearAllDriverLocations();

    void clearExpiredLocations();

    boolean isDriverOnline(Long driverId);

    void markDriverOnline(Long driverId);

    void markDriverOffline(Long driverId);
}
