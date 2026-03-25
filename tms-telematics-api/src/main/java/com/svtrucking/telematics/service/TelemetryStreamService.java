package com.svtrucking.telematics.service;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.datatype.jsr310.JavaTimeModule;
import com.svtrucking.telematics.dto.TelemetryEvent;
import jakarta.annotation.PostConstruct;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.data.redis.core.RedisTemplate;
import org.springframework.data.redis.core.StreamOperations;
import org.springframework.stereotype.Service;

import java.time.Instant;
import java.util.HashMap;
import java.util.Map;

/**
 * Publishes telemetry events to a Redis stream for downstream processing.
 */
@Service
@Slf4j
public class TelemetryStreamService {

    private final StreamOperations<String, String, Object> streamOps;
    private final ObjectMapper objectMapper;
    private final String streamName;

    public TelemetryStreamService(RedisTemplate<String, Object> redisTemplate,
                                  ObjectMapper objectMapper,
                                  @Value("${telemetry.stream.name:telemetry:events}") String streamName) {
        this.streamOps = redisTemplate.opsForStream();
        this.objectMapper = objectMapper;
        this.objectMapper.registerModule(new JavaTimeModule());
        this.streamName = streamName;
    }

    @PostConstruct
    public void init() {
        log.info("TelemetryStreamService initialized (stream={})", streamName);
    }

    public void publish(TelemetryEvent event) {
        if (event == null) {
            log.warn("Telemetry event is null, skipping publish");
            return;
        }
        log.debug("Publishing telemetry event to stream {}: driverId={} sessionId={}",
                streamName, event.getDriverId(), event.getSessionId());
        try {
            if (event.getReceivedAt() == null) {
                event.setReceivedAt(Instant.now());
            }
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
}
