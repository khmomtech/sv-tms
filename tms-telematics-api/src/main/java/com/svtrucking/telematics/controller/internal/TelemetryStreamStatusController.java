package com.svtrucking.telematics.controller.internal;

import jakarta.annotation.Nullable;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import com.svtrucking.telematics.service.TelemetryStreamConsumer;
import org.springframework.data.redis.core.StringRedisTemplate;
import org.springframework.data.redis.connection.stream.StreamInfo;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.util.HashMap;
import java.util.Map;
import java.util.Optional;

/**
 * Internal status endpoints for the streaming pipeline.
 */
@RestController
@RequestMapping("/api/internal/telemetry")
@RequiredArgsConstructor
@Slf4j
public class TelemetryStreamStatusController {

    private final StringRedisTemplate redis;
    private final TelemetryStreamConsumer streamConsumer;

    private static final String STREAM_NAME = "telemetry:events";
    private static final String OFFSET_KEY = "telemetry:events:last-id";

    @GetMapping("/stream-status")
    public ResponseEntity<Map<String, Object>> getStreamStatus() {
        Map<String, Object> status = new HashMap<>();
        status.put("streamName", STREAM_NAME);

        String storedLastId = redis.opsForValue().get(OFFSET_KEY);
        status.put("storedLastId", storedLastId);

        // Add consumer thread status
        status.put("consumer", streamConsumer.getConsumerStatus());
        status.put("approximateLagEntries", streamConsumer.getApproximateLagEntries().orElse(null));
        status.put("currentStreamLastId", streamConsumer.getCurrentStreamLastId().orElse(null));

        Optional<StreamInfo.XInfoStream> info = getStreamInfo(STREAM_NAME);
        if (info.isPresent()) {
            StreamInfo.XInfoStream streamInfo = info.get();
            status.put("streamLength", streamInfo.streamLength());
            status.put("streamFirstEntryId", streamInfo.firstEntryId());
            status.put("streamLastEntryId", streamInfo.lastEntryId());
            status.put("streamLastGeneratedId", streamInfo.lastGeneratedId());
            status.put("streamGroups", streamInfo.groupCount());
        } else {
            status.put("streamInfo", "stream not found");
        }

        return ResponseEntity.ok(status);
    }

    /**
     * Reset the stored consumer cursor (last-id) so the consumer can replay from the beginning.
     * If a specific `lastId` is provided it will be stored, otherwise it defaults to `0-0`.
     */
    @PostMapping("/stream-status/reset")
    public ResponseEntity<Map<String, Object>> resetStreamCursor(@RequestParam(required = false) String lastId) {
        String oldValue = redis.opsForValue().get(OFFSET_KEY);
        String newValue = (lastId == null || lastId.isBlank()) ? "0-0" : lastId;
        redis.opsForValue().set(OFFSET_KEY, newValue);
        Map<String, Object> result = new HashMap<>();
        result.put("oldLastId", oldValue);
        result.put("newLastId", newValue);
        result.put("appliedAt", System.currentTimeMillis());
        return ResponseEntity.ok(result);
    }

    private Optional<StreamInfo.XInfoStream> getStreamInfo(String streamName) {
        try {
            return Optional.ofNullable(redis.execute((org.springframework.data.redis.core.RedisCallback<StreamInfo.XInfoStream>) connection -> {
                try {
                    return connection.streamCommands().xInfo(streamName.getBytes());
                } catch (Exception e) {
                    log.debug("Unable to get stream info for {}: {}", streamName, e.getMessage());
                    return null;
                }
            }));
        } catch (Exception e) {
            log.debug("Redis execute failed when fetching stream info: {}", e.getMessage());
            return Optional.empty();
        }
    }
}
