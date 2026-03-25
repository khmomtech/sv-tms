package com.svtrucking.telematics.service;

import com.svtrucking.telematics.dto.LiveDriverDto;

/**
 * No-op cache implementation used when Redis is disabled
 * (spring.data.redis.host=disabled or not configured).
 */
public class NoOpLiveLocationCacheService implements LiveLocationCacheServiceInterface {

    @Override
    public void cacheDriverLocation(Long driverId, LiveDriverDto location) {
    }

    @Override
    public LiveDriverDto getCachedDriverLocation(Long driverId) {
        return null;
    }

    @Override
    public void removeDriverLocation(Long driverId) {
    }

    @Override
    public void clearAllDriverLocations() {
    }

    @Override
    public void clearExpiredLocations() {
    }

    @Override
    public boolean isDriverOnline(Long driverId) {
        return false;
    }

    @Override
    public void markDriverOnline(Long driverId) {
    }

    @Override
    public void markDriverOffline(Long driverId) {
    }
}
