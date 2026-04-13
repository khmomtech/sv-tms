package com.svtrucking.telematics.health;

import com.svtrucking.telematics.service.TelemetryStreamConsumer;
import java.util.Map;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.boot.actuate.health.Health;
import org.springframework.boot.actuate.health.HealthIndicator;
import org.springframework.stereotype.Component;

@Component
@ConditionalOnProperty(prefix = "telemetry.stream.consumer", name = "enabled", havingValue = "true")
public class TelemetryStreamConsumerHealthIndicator implements HealthIndicator {

    private final TelemetryStreamConsumer consumer;
    private final long warnLagEntries;
    private final long failLagEntries;
    private final long warnPollStalenessMs;
    private final long failPollStalenessMs;

    public TelemetryStreamConsumerHealthIndicator(
            TelemetryStreamConsumer consumer,
            @Value("${telemetry.stream.consumer.health.warn-lag-entries:200}") long warnLagEntries,
            @Value("${telemetry.stream.consumer.health.fail-lag-entries:2000}") long failLagEntries,
            @Value("${telemetry.stream.consumer.health.warn-poll-staleness-ms:15000}") long warnPollStalenessMs,
            @Value("${telemetry.stream.consumer.health.fail-poll-staleness-ms:60000}") long failPollStalenessMs) {
        this.consumer = consumer;
        this.warnLagEntries = warnLagEntries;
        this.failLagEntries = failLagEntries;
        this.warnPollStalenessMs = warnPollStalenessMs;
        this.failPollStalenessMs = failPollStalenessMs;
    }

    @Override
    public Health health() {
        Map<String, Object> status = consumer.getConsumerStatus();
        boolean enabled = Boolean.TRUE.equals(status.get("enabled"));
        boolean alive = Boolean.TRUE.equals(status.get("pollingThreadAlive"));
        long pollStalenessMs = asLong(status.get("pollStalenessMs"));
        long lagEntries = consumer.getApproximateLagEntries().orElse(0L);

        Health.Builder builder;
        if (!enabled) {
            builder = Health.up().withDetail("mode", "disabled");
        } else if (!alive || pollStalenessMs >= failPollStalenessMs || lagEntries >= failLagEntries) {
            builder = Health.down();
        } else if (pollStalenessMs >= warnPollStalenessMs || lagEntries >= warnLagEntries) {
            builder = Health.status("DEGRADED");
        } else {
            builder = Health.up();
        }

        builder.withDetail("enabled", enabled)
                .withDetail("pollingThreadAlive", alive)
                .withDetail("pollStalenessMs", pollStalenessMs)
                .withDetail("approximateLagEntries", lagEntries)
                .withDetail("warnLagEntries", warnLagEntries)
                .withDetail("failLagEntries", failLagEntries)
                .withDetail("warnPollStalenessMs", warnPollStalenessMs)
                .withDetail("failPollStalenessMs", failPollStalenessMs);
        addDetailIfPresent(builder, "lastId", status.get("lastId"));
        addDetailIfPresent(builder, "lastPollTimestampMs", status.get("lastPollTimestampMs"));
        addDetailIfPresent(builder, "lastPollRecordCount", status.get("lastPollRecordCount"));
        addDetailIfPresent(builder, "lastPollError", status.get("lastPollError"));
        return builder.build();
    }

    private long asLong(Object value) {
        if (value instanceof Number number) {
            return number.longValue();
        }
        return 0L;
    }

    private void addDetailIfPresent(Health.Builder builder, String key, Object value) {
        if (value != null) {
            builder.withDetail(key, value);
        }
    }
}
