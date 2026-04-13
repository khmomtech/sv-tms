package com.svtrucking.devicegateway.telemetry;

import java.time.Instant;
import java.util.List;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;
import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.retry.annotation.Backoff;
import org.springframework.retry.annotation.Retryable;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/device/telemetry")
public class TelemetryController {

    private final TelemetryPointRepository repository;
    private final TelemetryOutboxPublisher outboxPublisher;

    public TelemetryController(TelemetryPointRepository repository,
                               TelemetryOutboxPublisher outboxPublisher) {
        this.repository = repository;
        this.outboxPublisher = outboxPublisher;
    }

    @PostMapping
    @Retryable(value = {DataIntegrityViolationException.class}, maxAttempts = 3, backoff = @Backoff(delay = 500, multiplier = 2))
    @Transactional
    public ResponseEntity<Void> acceptTelemetry(@RequestBody List<TelemetryPointDto> points) {
        if (points == null || points.isEmpty()) {
            return ResponseEntity.badRequest().build();
        }

        for (TelemetryPointDto dto : points) {
            if (dto.getDeviceId() == null || dto.getSequenceNumber() == null) {
                continue;
            }

            TelemetryPoint entity = TelemetryPoint.builder()
                .deviceId(dto.getDeviceId())
                .sequenceNumber(dto.getSequenceNumber())
                .driverId(dto.getDriverId())
                .receivedAt(dto.getReceivedAt() != null ? dto.getReceivedAt() : Instant.now())
                .recordedAt(dto.getRecordedAt() != null ? dto.getRecordedAt() : Instant.now())
                .latitude(dto.getLatitude())
                .longitude(dto.getLongitude())
                .accuracy(dto.getAccuracy())
                .publishStatus(TelemetryPublishStatus.PENDING)
                .publishAttempts(0)
                .build();

            try {
                TelemetryPoint saved = repository.saveAndFlush(entity);
                outboxPublisher.publishNow(saved);
            } catch (DataIntegrityViolationException e) {
                // Idempotent behavior: ignore duplicates generated from concurrent retries
            }
        }

        return ResponseEntity.status(HttpStatus.CREATED).build();
    }

    @Data
    @NoArgsConstructor
    @AllArgsConstructor
    @Builder
    public static class TelemetryPointDto {
        private String deviceId;
        private Long sequenceNumber;
        private Long driverId;
        private Instant receivedAt;
        private Instant recordedAt;
        private Double latitude;
        private Double longitude;
        private Double accuracy;
    }
}
