package com.svtrucking.devicegateway.telemetry;

import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

import java.time.Instant;
import java.util.List;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.http.HttpStatus;

@ExtendWith(MockitoExtension.class)
class TelemetryControllerTest {

    @Mock
    private TelemetryPointRepository repository;

    @Mock
    private TelemetryOutboxPublisher outboxPublisher;

    @InjectMocks
    private TelemetryController controller;

    @Test
    void acceptTelemetryPersistsThenPublishes() {
        TelemetryPoint saved = TelemetryPoint.builder()
                .id(1L)
                .deviceId("dev-1")
                .sequenceNumber(99L)
                .receivedAt(Instant.now())
                .recordedAt(Instant.now())
                .publishStatus(TelemetryPublishStatus.PENDING)
                .publishAttempts(0)
                .build();
        when(repository.saveAndFlush(any(TelemetryPoint.class))).thenReturn(saved);

        var response = controller.acceptTelemetry(List.of(
                TelemetryController.TelemetryPointDto.builder()
                        .deviceId("dev-1")
                        .sequenceNumber(99L)
                        .driverId(7L)
                        .latitude(11.0)
                        .longitude(104.0)
                        .build()
        ));

        verify(repository).saveAndFlush(any(TelemetryPoint.class));
        verify(outboxPublisher).publishNow(saved);
        org.assertj.core.api.Assertions.assertThat(response.getStatusCode()).isEqualTo(HttpStatus.CREATED);
    }

    @Test
    void acceptTelemetryIgnoresDuplicateConstraintViolation() {
        when(repository.saveAndFlush(any(TelemetryPoint.class)))
                .thenThrow(new DataIntegrityViolationException("duplicate"));

        var response = controller.acceptTelemetry(List.of(
                TelemetryController.TelemetryPointDto.builder()
                        .deviceId("dev-1")
                        .sequenceNumber(99L)
                        .build()
        ));

        verify(outboxPublisher, never()).publishNow(any());
        org.assertj.core.api.Assertions.assertThat(response.getStatusCode()).isEqualTo(HttpStatus.CREATED);
    }
}
