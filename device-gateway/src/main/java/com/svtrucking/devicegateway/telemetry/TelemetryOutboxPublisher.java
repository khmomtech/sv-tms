package com.svtrucking.devicegateway.telemetry;

import io.micrometer.core.instrument.Counter;
import io.micrometer.core.instrument.Gauge;
import io.micrometer.core.instrument.MeterRegistry;
import java.time.Instant;
import java.util.List;
import java.util.Set;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
@Slf4j
public class TelemetryOutboxPublisher {

    private static final Set<TelemetryPublishStatus> RETRYABLE_STATUSES =
            Set.of(TelemetryPublishStatus.PENDING, TelemetryPublishStatus.FAILED);

    private final TelemetryPointRepository repository;
    private final TelemetryStreamService streamService;
    private final int replayBatchSize;
    private final Counter publishSuccessCounter;
    private final Counter publishFailureCounter;
    private final Counter replayProcessedCounter;

    public TelemetryOutboxPublisher(TelemetryPointRepository repository,
                                    @Autowired(required = false) TelemetryStreamService streamService,
                                    @Value("${telemetry.stream.replay.batch-size:200}") int replayBatchSize,
                                    @Autowired(required = false) MeterRegistry meterRegistry) {
        this.repository = repository;
        this.streamService = streamService;
        this.replayBatchSize = replayBatchSize;
        this.publishSuccessCounter = meterRegistry != null
                ? Counter.builder("telemetry.outbox.publish.success.count").register(meterRegistry)
                : null;
        this.publishFailureCounter = meterRegistry != null
                ? Counter.builder("telemetry.outbox.publish.failure.count").register(meterRegistry)
                : null;
        this.replayProcessedCounter = meterRegistry != null
                ? Counter.builder("telemetry.outbox.replay.processed.count").register(meterRegistry)
                : null;
        if (meterRegistry != null) {
            Gauge.builder("telemetry.outbox.backlog.count", this, TelemetryOutboxPublisher::backlogCount)
                    .register(meterRegistry);
            Gauge.builder("telemetry.outbox.oldest.backlog.age.seconds", this, TelemetryOutboxPublisher::oldestBacklogAgeSeconds)
                    .register(meterRegistry);
        }
    }

    @Transactional
    public void publishNow(TelemetryPoint point) {
        if (point == null || point.getId() == null) {
            return;
        }
        if (point.getPublishStatus() == TelemetryPublishStatus.PUBLISHED) {
            return;
        }
        if (streamService == null) {
            markFailed(point, "stream_disabled");
            return;
        }

        TelemetryStreamService.PublishResult result = streamService.publish(toEvent(point));
        if (result.isSuccess()) {
            point.setPublishStatus(TelemetryPublishStatus.PUBLISHED);
            point.setPublishedAt(Instant.now());
            point.setLastPublishError(null);
            increment(publishSuccessCounter);
        } else {
            markFailed(point, result.getError());
            increment(publishFailureCounter);
        }
        repository.save(point);
    }

    @Scheduled(fixedDelayString = "${telemetry.stream.replay.fixed-delay-ms:5000}")
    @Transactional
    public void replayUnpublished() {
        if (streamService == null) {
            return;
        }

        List<TelemetryPoint> backlog = repository.findTop200ByPublishStatusInOrderByReceivedAtAsc(RETRYABLE_STATUSES);
        if (backlog.isEmpty()) {
            return;
        }

        int processed = 0;
        for (TelemetryPoint point : backlog) {
            if (processed >= replayBatchSize) {
                break;
            }
            publishNow(point);
            processed++;
        }

        if (processed > 0) {
            increment(replayProcessedCounter, processed);
            log.info("Telemetry outbox replay processed {} point(s)", processed);
        }
    }

    private void markFailed(TelemetryPoint point, String error) {
        point.setPublishStatus(TelemetryPublishStatus.FAILED);
        point.setPublishAttempts((point.getPublishAttempts() == null ? 0 : point.getPublishAttempts()) + 1);
        point.setLastPublishError(truncate(error));
    }

    private TelemetryStreamService.TelemetryEvent toEvent(TelemetryPoint point) {
        return TelemetryStreamService.TelemetryEvent.builder()
                .driverId(point.getDriverId())
                .latitude(point.getLatitude())
                .longitude(point.getLongitude())
                .sessionId(point.getDeviceId())
                .seq(String.valueOf(point.getSequenceNumber()))
                .eventTime(point.getRecordedAt())
                .receivedAt(point.getReceivedAt())
                .build();
    }

    private String truncate(String error) {
        if (error == null || error.length() <= 1000) {
            return error;
        }
        return error.substring(0, 1000);
    }

    double backlogCount() {
        return repository.countByPublishStatusIn(RETRYABLE_STATUSES);
    }

    double oldestBacklogAgeSeconds() {
        return repository.findFirstByPublishStatusInOrderByReceivedAtAsc(RETRYABLE_STATUSES)
                .map(TelemetryPoint::getReceivedAt)
                .map(receivedAt -> Math.max(0, java.time.Duration.between(receivedAt, Instant.now()).getSeconds()))
                .orElse(0L)
                .doubleValue();
    }

    private void increment(Counter counter) {
        if (counter != null) {
            counter.increment();
        }
    }

    private void increment(Counter counter, double amount) {
        if (counter != null) {
            counter.increment(amount);
        }
    }
}
