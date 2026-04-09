package com.svtrucking.logistics.service;

import lombok.extern.slf4j.Slf4j;
import org.springframework.boot.autoconfigure.condition.ConditionalOnExpression;
import org.springframework.stereotype.Service;

@Service
@Slf4j
@ConditionalOnExpression("'${spring.data.redis.host:}'.equals('disabled')")
public class NoOpVehicleCacheService implements VehicleCacheServiceInterface {

    private final io.micrometer.core.instrument.MeterRegistry meterRegistry;

    public NoOpVehicleCacheService(io.micrometer.core.instrument.MeterRegistry meterRegistry) {
        this.meterRegistry = meterRegistry;
    }

    @Override
    public void clearVehiclesCache() {
        log.debug("Redis disabled: skipping vehicle cache clear (no-op)");
        try {
            meterRegistry.counter("vehicle.cache.clear_attempts_no_redis").increment();
        } catch (Exception ignored) {
        }
    }
}
