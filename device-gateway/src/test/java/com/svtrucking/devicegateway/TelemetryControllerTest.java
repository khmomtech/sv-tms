package com.svtrucking.devicegateway;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.svtrucking.devicegateway.telemetry.TelemetryController;
import com.svtrucking.devicegateway.telemetry.TelemetryController.TelemetryPointDto;
import com.svtrucking.devicegateway.telemetry.TelemetryOutboxPublisher;
import com.svtrucking.devicegateway.telemetry.TelemetryPoint;
import com.svtrucking.devicegateway.telemetry.TelemetryPointRepository;
import java.time.Instant;
import java.util.List;
import org.junit.jupiter.api.Test;
import org.mockito.Mockito;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.WebMvcTest;
import org.springframework.boot.test.mock.mockito.MockBean;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;

import static org.mockito.ArgumentMatchers.any;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@WebMvcTest(TelemetryController.class)
class TelemetryControllerTest {

  @Autowired private MockMvc mockMvc;

  @Autowired private ObjectMapper objectMapper;

  @MockBean private TelemetryPointRepository repository;
  @MockBean private TelemetryOutboxPublisher outboxPublisher;

  @Test
  void postTelemetry_returnsCreated_whenValidPayload() throws Exception {
    Mockito.when(repository.saveAndFlush(any(TelemetryPoint.class)))
        .thenAnswer(invocation -> invocation.getArgument(0));

    TelemetryPointDto dto = TelemetryPointDto.builder()
        .deviceId("device-1")
        .sequenceNumber(1L)
        .driverId(123L)
        .receivedAt(Instant.now())
        .recordedAt(Instant.now())
        .latitude(1.23)
        .longitude(4.56)
        .accuracy(5.0)
        .build();

    mockMvc.perform(post("/api/device/telemetry")
            .contentType(MediaType.APPLICATION_JSON)
            .content(objectMapper.writeValueAsString(List.of(dto))))
        .andExpect(status().isCreated());
  }

  @Test
  void postTelemetry_returnsBadRequest_whenEmptyList() throws Exception {
    mockMvc.perform(post("/api/device/telemetry")
            .contentType(MediaType.APPLICATION_JSON)
            .content("[]"))
        .andExpect(status().isBadRequest());
  }
}
