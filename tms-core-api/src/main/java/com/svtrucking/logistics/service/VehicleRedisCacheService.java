package com.svtrucking.logistics.service;

import io.micrometer.core.instrument.MeterRegistry;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.boot.autoconfigure.condition.ConditionalOnExpression;
import org.springframework.data.redis.core.RedisTemplate;
import org.springframework.stereotype.Service;

@Service
@RequiredArgsConstructor
@Slf4j
@ConditionalOnExpression("!'${spring.data.redis.host:}'.equals('disabled')")
public class VehicleRedisCacheService implements VehicleCacheServiceInterface {

    private final RedisTemplate<String, Object> redisTemplate;
    private final MeterRegistry meterRegistry;

    private final String VEHICLE_PREFIX = "vehicles:";

    @Override
    public void clearVehiclesCache() {
        try {
            long totalDeleted = 0L;

            // First, clear filter-specific caches (e.g., vehicles:filter:page=...)
            String filterPattern = VEHICLE_PREFIX + "filter:*";
            var filterKeys = redisTemplate.keys(filterPattern);
            if (filterKeys != null && !filterKeys.isEmpty()) {
                long deleted = redisTemplate.delete(filterKeys);
                totalDeleted += deleted;
                log.info("Cleared {} vehicle filter cache keys", deleted);
                try { meterRegistry.counter("vehicle.cache.filter.clears").increment();
                      meterRegistry.counter("vehicle.cache.filter.keys_deleted").increment(deleted);
                } catch (Exception ignored) {}
            } else {
                log.debug("No vehicle filter cache keys to clear for pattern {}", filterPattern);
            }

            // Then, clear any remaining vehicle keys (broad sweep)
            String pattern = VEHICLE_PREFIX + "*";
            var keys = redisTemplate.keys(pattern);
            if (keys != null && !keys.isEmpty()) {
                long deleted = redisTemplate.delete(keys);
                totalDeleted += deleted;
                log.info("Cleared {} vehicle cache keys (broad)", deleted);
                try {
                    meterRegistry.counter("vehicle.cache.clears").increment();
                    meterRegistry.counter("vehicle.cache.keys_deleted").increment(deleted);
                } catch (Exception ignored) {
                }
            } else {
                log.debug("No vehicle cache keys to clear for pattern {}", pattern);
                try {
                    meterRegistry.counter("vehicle.cache.clears_noop").increment();
                } catch (Exception ignored) {
                }
            }

            if (totalDeleted > 0) {
                log.info("Total vehicle cache keys cleared: {}", totalDeleted);
            }
        } catch (Exception e) {
            log.warn("Failed to clear vehicle cache: {}", e.getMessage(), e);
        }
    }
}
