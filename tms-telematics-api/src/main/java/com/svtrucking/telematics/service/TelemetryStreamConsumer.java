package com.svtrucking.telematics.service;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.svtrucking.telematics.dto.TelemetryEvent;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.data.redis.core.StringRedisTemplate;
import org.springframework.data.redis.core.StreamOperations;
import org.springframework.data.redis.connection.stream.MapRecord;
import org.springframework.data.redis.connection.stream.StreamOffset;
import org.springframework.data.redis.connection.stream.StreamReadOptions;
import jakarta.annotation.PostConstruct;
import jakarta.annotation.PreDestroy;
import org.springframework.stereotype.Service;

import io.lettuce.core.RedisCommandTimeoutException;
import java.time.Duration;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.concurrent.atomic.AtomicBoolean;

/**
 * Pulls telemetry events from the Redis stream and processes them.
 * <p>
 * This is a simple consumer that reads new events and logs them. It is intended as a starting
 * point for ensuring the stream is working end-to-end.
 */
@Service
@Slf4j
public class TelemetryStreamConsumer {

    private final StringRedisTemplate stringRedisTemplate;
    private final StreamOperations<String, String, String> streamOps;
    private final ObjectMapper objectMapper;
    private final String streamName;
    private final String offsetKey;
    private final boolean enabled;
    private final long pollMs;
    private final LocationIngestService ingestService;

    private volatile String lastId;
    private volatile long lastPollTimestampMs = 0;
    private volatile int lastPollRecordCount = 0;
    private volatile String lastPollError = null;
    private final AtomicBoolean running = new AtomicBoolean(false);
    private Thread pollingThread;

    public TelemetryStreamConsumer(StringRedisTemplate stringRedisTemplate,
                                   ObjectMapper objectMapper,
                                   @Value("${telemetry.stream.name:telemetry:events}") String streamName,
                                   @Value("${telemetry.stream.consumer.offset-key:telemetry:events:last-id}") String offsetKey,
                                   @Value("${telemetry.stream.consumer.enabled:false}") boolean enabled,
                                   @Value("${telemetry.stream.consumer.poll-ms:1000}") long pollMs,
                                   @Autowired(required = false) LocationIngestService ingestService) {
        this.stringRedisTemplate = stringRedisTemplate;
        this.streamOps = stringRedisTemplate.opsForStream();
        this.objectMapper = objectMapper;
        this.streamName = streamName;
        this.offsetKey = offsetKey;
        this.enabled = enabled;
        this.pollMs = pollMs;
        this.ingestService = ingestService;
        this.lastId = "0-0";
    }

    private static String normalizeLastId(String raw) {
        if (raw == null || raw.isBlank()) {
            return "0-0";
        }
        String trimmed = raw.trim();
        if (trimmed.length() > 1 && trimmed.startsWith("\"") && trimmed.endsWith("\"")) {
            trimmed = trimmed.substring(1, trimmed.length() - 1);
        }
        return trimmed;
    }

    private Optional<String> getLastStreamId() {
        try {
            return Optional.ofNullable(stringRedisTemplate.execute((org.springframework.data.redis.core.RedisCallback<String>) connection -> {
                try {
                    // Spring Data Redis provides a stream info command; use it to determine the current tail of the stream.
                    var info = connection.streamCommands().xInfo(streamName.getBytes());
                    if (info == null) {
                        return null;
                    }
                    String lastId = info.lastGeneratedId();
                    return lastId;
                } catch (Exception e) {
                    // If the stream does not exist or the command is unsupported, ignore.
                    return null;
                }
            }));
        } catch (Exception e) {
            log.debug("Unable to fetch last stream id for {}: {}", streamName, e.getMessage());
            return Optional.empty();
        }
    }

    private static boolean isStreamIdGreater(String candidate, String reference) {
        if (candidate == null || reference == null) {
            return false;
        }

        String[] candParts = candidate.split("-");
        String[] refParts = reference.split("-");
        if (candParts.length != 2 || refParts.length != 2) {
            return false;
        }

        try {
            long candMs = Long.parseLong(candParts[0]);
            long refMs = Long.parseLong(refParts[0]);
            if (candMs != refMs) {
                return candMs > refMs;
            }
            long candSeq = Long.parseLong(candParts[1]);
            long refSeq = Long.parseLong(refParts[1]);
            return candSeq > refSeq;
        } catch (NumberFormatException e) {
            return false;
        }
    }


    @PostConstruct
    public void startPolling() {
        if (!enabled) {
            log.info("Telemetry stream consumer is disabled; polling will not start.");
            return;
        }

        refreshOffsetState();

        log.info("Starting telemetry stream polling thread (pollMs={}ms)", pollMs);
        running.set(true);
        pollingThread = new Thread(() -> {
            while (running.get()) {
                log.debug("Telemetry polling loop tick (lastId={})", lastId);
                try {
                    pollStream();
                } catch (Exception e) {
                    log.warn("Unexpected error while polling telemetry stream", e);
                }
                try {
                    Thread.sleep(pollMs);
                } catch (InterruptedException e) {
                    Thread.currentThread().interrupt();
                }
            }
        }, "telemetry-stream-consumer");
        pollingThread.setDaemon(true);
        pollingThread.start();
    }

    @PreDestroy
    public void stopPolling() {
        running.set(false);
        if (pollingThread != null) {
            pollingThread.interrupt();
        }
    }

    private void refreshOffsetState() {
        try {
            String stored = stringRedisTemplate.opsForValue().get(offsetKey);
            this.lastId = normalizeLastId(stored);

            // If the stored cursor is ahead of the stream (e.g., invalid or from a different stream epoch),
            // reset to the beginning so we can consume available entries.
            String streamLastId = getLastStreamId().orElse(null);
            if (streamLastId != null && isStreamIdGreater(this.lastId, streamLastId)) {
                log.warn("Stored lastId {} is ahead of stream lastId {}; resetting to 0-0", this.lastId, streamLastId);
                this.lastId = "0-0";
            }

            log.info("Telemetry stream consumer enabled={} starting from lastId={} (offsetKey={})",
                    this.enabled, this.lastId, offsetKey);
        } catch (Exception e) {
            this.lastId = "0-0";
            log.warn("Unable to initialize telemetry stream offset from Redis; starting from {} and retrying during polling: {}",
                    this.lastId, e.getMessage());
        }
    }

    public void pollStream() {
        if (!enabled) {
            return;
        }

        try {
            log.debug("Polling telemetry stream {} from lastId={}", streamName, lastId);
            List<MapRecord<String, String, String>> records = streamOps.read(
                    StreamReadOptions.empty().count(50).block(Duration.ofMillis(500)),
                    StreamOffset.create(streamName, org.springframework.data.redis.connection.stream.ReadOffset.from(lastId)));

            int recordCount = (records == null) ? 0 : records.size();
            lastPollTimestampMs = System.currentTimeMillis();
            lastPollRecordCount = recordCount;
            lastPollError = null;

            log.debug("Read {} records from stream {}", recordCount, streamName);
            if (recordCount == 0) {
                return;
            }

            log.info("Consumed {} records from stream {}", recordCount, streamName);
            for (MapRecord<String, String, String> record : records) {
                try {
                    TelemetryEvent event = parse(record.getValue());
                    if (log.isDebugEnabled()) {
                        log.debug("Consumed telemetry event from stream {}: {}", streamName, event);
                    }
                    if (ingestService != null) {
                        ingestService.acceptFromStream(event);
                    }
                } catch (Exception e) {
                    log.warn("Failed to parse telemetry event {}: {}", record.getId(), e.getMessage());
                }
                lastId = normalizeLastId(record.getId().getValue());
                try {
                    stringRedisTemplate.opsForValue().set(offsetKey, lastId);
                } catch (Exception ignore) {
                    // best-effort persistence
                }
            }
        } catch (RedisCommandTimeoutException e) {
            // Redis blocking read can occasionally hit timeouts; this is non-fatal.
            lastPollTimestampMs = System.currentTimeMillis();
            lastPollRecordCount = 0;
            lastPollError = e.getMessage();
            log.debug("Telemetry stream poll timeout ({}): {}", streamName, e.getMessage());
        } catch (Exception e) {
            lastPollTimestampMs = System.currentTimeMillis();
            lastPollRecordCount = 0;
            lastPollError = e.getMessage();
            log.warn("Error polling telemetry stream {}: {}", streamName, e.getMessage());
        }
    }

    public Map<String, Object> getConsumerStatus() {
        Map<String, Object> status = new java.util.HashMap<>();
        status.put("enabled", enabled);
        status.put("pollingThreadAlive", pollingThread != null && pollingThread.isAlive());
        status.put("lastId", lastId);
        status.put("lastPollTimestampMs", lastPollTimestampMs);
        status.put("lastPollRecordCount", lastPollRecordCount);
        status.put("lastPollError", lastPollError);
        return status;
    }

    private TelemetryEvent parse(Map<String, String> raw) {
        // Redis stream values are stored as strings. Jackson will convert them to the target types.
        return objectMapper.convertValue(raw, TelemetryEvent.class);
    }
}
