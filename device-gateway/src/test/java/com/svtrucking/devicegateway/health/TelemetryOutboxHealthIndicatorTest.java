package com.svtrucking.devicegateway.health;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.when;

import com.svtrucking.devicegateway.telemetry.TelemetryPoint;
import com.svtrucking.devicegateway.telemetry.TelemetryPointRepository;
import com.svtrucking.devicegateway.telemetry.TelemetryPublishStatus;
import java.time.Instant;
import java.util.Optional;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.boot.actuate.health.Status;

@ExtendWith(MockitoExtension.class)
class TelemetryOutboxHealthIndicatorTest {

    @Mock
    private TelemetryPointRepository repository;

    @Test
    void healthIsUpWhenNoBacklog() {
        TelemetryOutboxHealthIndicator indicator = new TelemetryOutboxHealthIndicator(repository, 60, 300);
        when(repository.countByPublishStatusIn(any())).thenReturn(0L);
        when(repository.findFirstByPublishStatusInOrderByReceivedAtAsc(any())).thenReturn(Optional.empty());

        var health = indicator.health();

        assertThat(health.getStatus()).isEqualTo(Status.UP);
        assertThat(health.getDetails()).containsEntry("backlogCount", 0L);
    }

    @Test
    void healthIsDegradedWhenOldestBacklogExceedsWarning() {
        TelemetryOutboxHealthIndicator indicator = new TelemetryOutboxHealthIndicator(repository, 60, 300);
        when(repository.countByPublishStatusIn(any())).thenReturn(5L);
        when(repository.findFirstByPublishStatusInOrderByReceivedAtAsc(any()))
                .thenReturn(Optional.of(pointWithReceivedAt(Instant.now().minusSeconds(120))));

        var health = indicator.health();

        assertThat(health.getStatus().getCode()).isEqualTo("DEGRADED");
    }

    @Test
    void healthIsDownWhenOldestBacklogExceedsFailureThreshold() {
        TelemetryOutboxHealthIndicator indicator = new TelemetryOutboxHealthIndicator(repository, 60, 300);
        when(repository.countByPublishStatusIn(any())).thenReturn(12L);
        when(repository.findFirstByPublishStatusInOrderByReceivedAtAsc(any()))
                .thenReturn(Optional.of(pointWithReceivedAt(Instant.now().minusSeconds(500))));

        var health = indicator.health();

        assertThat(health.getStatus()).isEqualTo(Status.DOWN);
    }

    private TelemetryPoint pointWithReceivedAt(Instant receivedAt) {
        return TelemetryPoint.builder()
                .id(1L)
                .deviceId("device-1")
                .sequenceNumber(1L)
                .receivedAt(receivedAt)
                .recordedAt(receivedAt)
                .publishStatus(TelemetryPublishStatus.FAILED)
                .publishAttempts(1)
                .build();
    }
}
