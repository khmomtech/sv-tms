package com.svtrucking.devicegateway.health;

import com.svtrucking.devicegateway.telemetry.TelemetryPoint;
import com.svtrucking.devicegateway.telemetry.TelemetryPointRepository;
import com.svtrucking.devicegateway.telemetry.TelemetryPublishStatus;
import java.time.Duration;
import java.time.Instant;
import java.util.Set;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.actuate.health.Health;
import org.springframework.boot.actuate.health.HealthIndicator;
import org.springframework.stereotype.Component;

@Component
public class TelemetryOutboxHealthIndicator implements HealthIndicator {

    private static final Set<TelemetryPublishStatus> UNPUBLISHED_STATUSES =
            Set.of(TelemetryPublishStatus.PENDING, TelemetryPublishStatus.FAILED);

    private final TelemetryPointRepository repository;
    private final long warnOldestSeconds;
    private final long failOldestSeconds;

    public TelemetryOutboxHealthIndicator(TelemetryPointRepository repository,
                                          @Value("${telemetry.outbox.health.warn-oldest-seconds:60}") long warnOldestSeconds,
                                          @Value("${telemetry.outbox.health.fail-oldest-seconds:300}") long failOldestSeconds) {
        this.repository = repository;
        this.warnOldestSeconds = warnOldestSeconds;
        this.failOldestSeconds = failOldestSeconds;
    }

    @Override
    public Health health() {
        long backlogCount = repository.countByPublishStatusIn(UNPUBLISHED_STATUSES);
        TelemetryPoint oldest = repository.findFirstByPublishStatusInOrderByReceivedAtAsc(UNPUBLISHED_STATUSES).orElse(null);
        long oldestAgeSeconds = oldest == null || oldest.getReceivedAt() == null
                ? 0
                : Math.max(0, Duration.between(oldest.getReceivedAt(), Instant.now()).getSeconds());

        Health.Builder builder = oldestAgeSeconds >= failOldestSeconds
                ? Health.down()
                : oldestAgeSeconds >= warnOldestSeconds ? Health.status("DEGRADED") : Health.up();

        return builder
                .withDetail("backlogCount", backlogCount)
                .withDetail("oldestUnpublishedAgeSeconds", oldestAgeSeconds)
                .withDetail("warnOldestSeconds", warnOldestSeconds)
                .withDetail("failOldestSeconds", failOldestSeconds)
                .build();
    }
}
