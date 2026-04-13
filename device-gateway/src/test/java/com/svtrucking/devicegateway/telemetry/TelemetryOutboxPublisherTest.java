package com.svtrucking.devicegateway.telemetry;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

import java.time.Instant;
import java.util.List;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

@ExtendWith(MockitoExtension.class)
class TelemetryOutboxPublisherTest {

    @Mock
    private TelemetryPointRepository repository;

    @Mock
    private TelemetryStreamService streamService;

    private TelemetryOutboxPublisher publisher;

    @BeforeEach
    void setUp() {
        publisher = new TelemetryOutboxPublisher(repository, streamService, 200, null);
    }

    @Test
    void publishNowMarksPointPublishedWhenStreamSucceeds() {
        TelemetryPoint point = basePoint();
        when(streamService.publish(any())).thenReturn(TelemetryStreamService.PublishResult.success());

        publisher.publishNow(point);

        assertThat(point.getPublishStatus()).isEqualTo(TelemetryPublishStatus.PUBLISHED);
        assertThat(point.getPublishedAt()).isNotNull();
        assertThat(point.getLastPublishError()).isNull();
        verify(repository).save(point);
    }

    @Test
    void publishNowKeepsPointReplayableWhenStreamFails() {
        TelemetryPoint point = basePoint();
        when(streamService.publish(any())).thenReturn(TelemetryStreamService.PublishResult.failure("redis_down"));

        publisher.publishNow(point);

        assertThat(point.getPublishStatus()).isEqualTo(TelemetryPublishStatus.FAILED);
        assertThat(point.getPublishAttempts()).isEqualTo(1);
        assertThat(point.getLastPublishError()).isEqualTo("redis_down");
        verify(repository).save(point);
    }

    @Test
    void replayUnpublishedProcessesBacklog() {
        TelemetryPoint point = basePoint();
        point.setPublishStatus(TelemetryPublishStatus.FAILED);
        when(repository.findTop200ByPublishStatusInOrderByReceivedAtAsc(any()))
                .thenReturn(List.of(point));
        when(streamService.publish(any())).thenReturn(TelemetryStreamService.PublishResult.success());

        publisher.replayUnpublished();

        assertThat(point.getPublishStatus()).isEqualTo(TelemetryPublishStatus.PUBLISHED);
        verify(repository).findTop200ByPublishStatusInOrderByReceivedAtAsc(any());
        verify(repository).save(point);
    }

    @Test
    void publishNowSkipsAlreadyPublishedPoints() {
        TelemetryPoint point = basePoint();
        point.setPublishStatus(TelemetryPublishStatus.PUBLISHED);

        publisher.publishNow(point);

        verify(streamService, never()).publish(any());
        verify(repository, never()).save(any());
    }

    private TelemetryPoint basePoint() {
        return TelemetryPoint.builder()
                .id(10L)
                .deviceId("device-1")
                .sequenceNumber(11L)
                .driverId(12L)
                .receivedAt(Instant.parse("2026-04-08T01:00:00Z"))
                .recordedAt(Instant.parse("2026-04-08T00:59:55Z"))
                .latitude(11.55)
                .longitude(104.92)
                .publishStatus(TelemetryPublishStatus.PENDING)
                .publishAttempts(0)
                .build();
    }
}
