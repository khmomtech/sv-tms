package com.svtrucking.telematics.health;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.Mockito.when;

import com.svtrucking.telematics.service.TelemetryStreamConsumer;
import java.util.Map;
import java.util.Optional;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.boot.actuate.health.Status;

@ExtendWith(MockitoExtension.class)
class TelemetryStreamConsumerHealthIndicatorTest {

    @Mock
    private TelemetryStreamConsumer consumer;

    @Test
    void healthIsUpWhenConsumerHealthy() {
        TelemetryStreamConsumerHealthIndicator indicator =
                new TelemetryStreamConsumerHealthIndicator(consumer, 200, 2000, 15000, 60000);
        when(consumer.getConsumerStatus()).thenReturn(Map.of(
                "enabled", true,
                "pollingThreadAlive", true,
                "lastId", "100-1",
                "lastPollTimestampMs", System.currentTimeMillis(),
                "lastPollRecordCount", 1,
                "lastPollError", "",
                "pollStalenessMs", 500L));
        when(consumer.getApproximateLagEntries()).thenReturn(Optional.of(10L));

        var health = indicator.health();

        assertThat(health.getStatus()).isEqualTo(Status.UP);
    }

    @Test
    void healthIsDegradedWhenLagCrossesWarningThreshold() {
        TelemetryStreamConsumerHealthIndicator indicator =
                new TelemetryStreamConsumerHealthIndicator(consumer, 200, 2000, 15000, 60000);
        when(consumer.getConsumerStatus()).thenReturn(Map.of(
                "enabled", true,
                "pollingThreadAlive", true,
                "lastId", "100-1",
                "lastPollTimestampMs", System.currentTimeMillis(),
                "lastPollRecordCount", 0,
                "lastPollError", "",
                "pollStalenessMs", 1000L));
        when(consumer.getApproximateLagEntries()).thenReturn(Optional.of(250L));

        var health = indicator.health();

        assertThat(health.getStatus().getCode()).isEqualTo("DEGRADED");
    }

    @Test
    void healthIsDownWhenPollThreadIsNotAlive() {
        TelemetryStreamConsumerHealthIndicator indicator =
                new TelemetryStreamConsumerHealthIndicator(consumer, 200, 2000, 15000, 60000);
        when(consumer.getConsumerStatus()).thenReturn(Map.of(
                "enabled", true,
                "pollingThreadAlive", false,
                "lastId", "100-1",
                "lastPollTimestampMs", System.currentTimeMillis(),
                "lastPollRecordCount", 0,
                "lastPollError", "stopped",
                "pollStalenessMs", 70000L));
        when(consumer.getApproximateLagEntries()).thenReturn(Optional.of(0L));

        var health = indicator.health();

        assertThat(health.getStatus()).isEqualTo(Status.DOWN);
    }

    @Test
    void healthOmitsNullDetailsInsteadOfThrowing() {
        TelemetryStreamConsumerHealthIndicator indicator =
                new TelemetryStreamConsumerHealthIndicator(consumer, 200, 2000, 15000, 60000);
        when(consumer.getConsumerStatus()).thenReturn(Map.of(
                "enabled", true,
                "pollingThreadAlive", true,
                "pollStalenessMs", 500L));
        when(consumer.getApproximateLagEntries()).thenReturn(Optional.of(0L));

        var health = indicator.health();

        assertThat(health.getStatus()).isEqualTo(Status.UP);
        assertThat(health.getDetails()).doesNotContainKeys(
                "lastId", "lastPollTimestampMs", "lastPollRecordCount", "lastPollError");
    }
}
