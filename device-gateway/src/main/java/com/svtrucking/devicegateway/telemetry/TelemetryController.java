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
    private final TelemetryStreamService streamService;

    public TelemetryController(TelemetryPointRepository repository,
                               @org.springframework.beans.factory.annotation.Autowired(required = false) TelemetryStreamService streamService) {
        this.repository = repository;
        this.streamService = streamService;
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

            boolean exists = repository.findByDeviceIdAndSequenceNumber(dto.getDeviceId(), dto.getSequenceNumber()).isPresent();
            if (exists) {
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
                .build();

            try {
                repository.save(entity);

                if (streamService != null) {
                    streamService.publish(TelemetryStreamService.TelemetryEvent.builder()
                            .driverId(entity.getDriverId())
                            .latitude(entity.getLatitude())
                            .longitude(entity.getLongitude())
                            .sessionId(entity.getDeviceId())
                            .seq(String.valueOf(entity.getSequenceNumber()))
                            .eventTime(entity.getRecordedAt())
                            .receivedAt(entity.getReceivedAt())
                            .build());
                }
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
