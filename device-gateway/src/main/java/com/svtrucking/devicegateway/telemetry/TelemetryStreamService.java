package com.svtrucking.devicegateway.telemetry;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.datatype.jsr310.JavaTimeModule;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.data.redis.core.RedisTemplate;
import org.springframework.data.redis.core.StreamOperations;
import org.springframework.stereotype.Service;

import java.time.Instant;
import java.util.HashMap;
import java.util.Map;

/**
 * Publishes telemetry events to a Redis stream for downstream processors (e.g., tms-telematics-api).
 */
@Service
@Slf4j
@ConditionalOnProperty(prefix = "telemetry.stream", name = "enabled", havingValue = "true", matchIfMissing = false)
public class TelemetryStreamService {

    private final StreamOperations<Object, Object, Object> streamOps;
    private final ObjectMapper objectMapper;
    private final String streamName;

    public TelemetryStreamService(RedisTemplate<Object, Object> redisTemplate,
                                  ObjectMapper objectMapper,
                                  @Value("${telemetry.stream.name:telemetry:events}") String streamName) {
        this.streamOps = redisTemplate.opsForStream();
        this.objectMapper = objectMapper;
        this.objectMapper.registerModule(new JavaTimeModule());
        this.streamName = streamName;
        log.info("TelemetryStreamService initialized (stream={})", streamName);
    }

    public void publish(TelemetryEvent event) {
        if (event == null) {
            log.warn("Telemetry event is null, skipping publish");
            return;
        }

        if (event.getReceivedAt() == null) {
            event.setReceivedAt(Instant.now());
        }

        try {
            Map<String, Object> raw = objectMapper.convertValue(event, Map.class);
            Map<String, String> map = new HashMap<>(raw.size());
            raw.forEach((k, v) -> {
                if (v != null) {
                    map.put(k, v.toString());
                }
            });
            streamOps.add(streamName, map);
        } catch (Exception e) {
            log.warn("Failed to publish telemetry event to stream {}: {}", streamName, e.getMessage());
        }
    }

    /**
     * Minimal telemetry event format used for the stream. The important fields are those consumers care about.
     */
    @lombok.Data
    @lombok.Builder
    @lombok.NoArgsConstructor
    @lombok.AllArgsConstructor
    public static class TelemetryEvent {
        private Long driverId;
        private String dispatchId;
        private Double latitude;
        private Double longitude;
        private String sessionId;
        private String seq;
        private Instant eventTime;
        private Instant receivedAt;
        private String rawPayload;
    }
}
