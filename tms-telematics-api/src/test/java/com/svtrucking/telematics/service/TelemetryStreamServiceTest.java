package com.svtrucking.telematics.service;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.svtrucking.telematics.dto.TelemetryEvent;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.mockito.ArgumentCaptor;
import org.springframework.data.redis.core.RedisTemplate;
import org.springframework.data.redis.core.StreamOperations;

import java.util.Map;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

class TelemetryStreamServiceTest {

    private StreamOperations<String, String, Object> streamOps;
    private TelemetryStreamService service;

    @BeforeEach
    void setUp() {
        RedisTemplate<String, Object> redisTemplate = mock(RedisTemplate.class);
        streamOps = mock(StreamOperations.class);
        when(redisTemplate.opsForStream()).thenReturn((StreamOperations) streamOps);
        ObjectMapper objectMapper = new ObjectMapper();
        objectMapper.registerModule(new com.fasterxml.jackson.datatype.jsr310.JavaTimeModule());
        service = new TelemetryStreamService(redisTemplate, objectMapper, "telemetry:events");
    }

    @Test
    void publish_shouldWriteToStreamWithStringValues() {
        TelemetryEvent event = TelemetryEvent.builder()
                .driverId(123L)
                .latitude(11.0)
                .longitude(22.0)
                .speed(1.5)
                .heading(300.0)
                .batteryLevel(87)
                .eventTime(java.time.Instant.parse("2025-01-01T00:00:00Z"))
                .build();

        service.publish(event);

        ArgumentCaptor<Map<String, String>> captor = ArgumentCaptor.forClass(Map.class);
        verify(streamOps).add(org.mockito.ArgumentMatchers.eq("telemetry:events"), captor.capture());

        Map<String, String> map = captor.getValue();
        assertThat(map.get("driverId")).isEqualTo("123");
        assertThat(map.get("latitude")).isEqualTo("11.0");
        assertThat(map.get("eventTime")).contains("2025-01-01");
    }
}
