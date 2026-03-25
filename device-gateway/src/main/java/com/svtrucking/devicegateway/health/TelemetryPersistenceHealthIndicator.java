package com.svtrucking.devicegateway.health;

import com.svtrucking.devicegateway.telemetry.TelemetryPointRepository;
import org.springframework.boot.actuate.health.Health;
import org.springframework.boot.actuate.health.HealthIndicator;
import org.springframework.stereotype.Component;

/**
 * Health check that validates the gateway can reach the telemetry persistence store.
 */
@Component
public class TelemetryPersistenceHealthIndicator implements HealthIndicator {

    private final TelemetryPointRepository repository;

    public TelemetryPersistenceHealthIndicator(TelemetryPointRepository repository) {
        this.repository = repository;
    }

    @Override
    public Health health() {
        try {
            // Ensure the table exists and the database is reachable.
            long count = repository.count();
            return Health.up().withDetail("telemetryRecords", count).build();
        } catch (Exception e) {
            return Health.down(e).withDetail("message", "Cannot access telemetry persistence").build();
        }
    }
}
