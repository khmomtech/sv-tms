package com.svtrucking.telematics.service;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.svtrucking.telematics.dto.TelemetryEvent;
import io.micrometer.core.instrument.Counter;
import io.micrometer.core.instrument.Gauge;
import io.micrometer.core.instrument.MeterRegistry;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.data.redis.core.StringRedisTemplate;
import org.springframework.data.redis.core.StreamOperations;
import org.springframework.data.redis.connection.stream.Consumer;
import org.springframework.data.redis.connection.stream.MapRecord;
import org.springframework.data.redis.connection.stream.PendingMessage;
import org.springframework.data.redis.connection.stream.PendingMessagesSummary;
import org.springframework.data.redis.connection.stream.ReadOffset;
import org.springframework.data.redis.connection.stream.StreamOffset;
import org.springframework.data.redis.connection.stream.StreamReadOptions;
import jakarta.annotation.PostConstruct;
import jakarta.annotation.PreDestroy;
import org.springframework.stereotype.Service;

import io.lettuce.core.RedisCommandTimeoutException;
import java.time.Duration;
import java.time.Instant;
import java.util.HashMap;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.UUID;
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
    private final String dlqStreamName;
    private final String consumerMode;
    private final String consumerGroup;
    private final String consumerName;
    private final long claimIdleMs;
    private final int claimBatchSize;
    private final boolean enabled;
    private final long pollMs;
    private final LocationIngestService ingestService;
    private final Counter claimedCounter;
    private final Counter dlqCounter;
    private final Counter acknowledgedCounter;

    private volatile String lastId;
    private volatile long lastPollTimestampMs = 0;
    private volatile int lastPollRecordCount = 0;
    private volatile String lastPollError = null;
    private volatile int lastClaimedRecordCount = 0;
    private final AtomicBoolean running = new AtomicBoolean(false);
    private Thread pollingThread;

    public TelemetryStreamConsumer(StringRedisTemplate stringRedisTemplate,
                                   ObjectMapper objectMapper,
                                   @Value("${telemetry.stream.name:telemetry:events}") String streamName,
                                   @Value("${telemetry.stream.consumer.offset-key:telemetry:events:last-id}") String offsetKey,
                                   @Value("${telemetry.stream.consumer.dlq-name:telemetry:events:dlq}") String dlqStreamName,
                                   @Value("${telemetry.stream.consumer.mode:offset}") String consumerMode,
                                   @Value("${telemetry.stream.consumer.group-name:telematics-consumers}") String consumerGroup,
                                   @Value("${telemetry.stream.consumer.consumer-name:${HOSTNAME:telematics-api}}") String consumerName,
                                   @Value("${telemetry.stream.consumer.claim-idle-ms:60000}") long claimIdleMs,
                                   @Value("${telemetry.stream.consumer.claim-batch-size:25}") int claimBatchSize,
                                   @Value("${telemetry.stream.consumer.enabled:false}") boolean enabled,
                                   @Value("${telemetry.stream.consumer.poll-ms:1000}") long pollMs,
                                   @Autowired(required = false) LocationIngestService ingestService,
                                   @Autowired(required = false) MeterRegistry meterRegistry) {
        this.stringRedisTemplate = stringRedisTemplate;
        this.streamOps = stringRedisTemplate.opsForStream();
        this.objectMapper = objectMapper;
        this.streamName = streamName;
        this.offsetKey = offsetKey;
        this.dlqStreamName = dlqStreamName;
        this.consumerMode = normalizeMode(consumerMode);
        this.consumerGroup = consumerGroup;
        this.consumerName = sanitizeConsumerName(consumerName);
        this.claimIdleMs = claimIdleMs;
        this.claimBatchSize = claimBatchSize;
        this.enabled = enabled;
        this.pollMs = pollMs;
        this.ingestService = ingestService;
        this.lastId = "0-0";
        this.claimedCounter = meterRegistry != null
                ? Counter.builder("telemetry.stream.consumer.claimed.count").register(meterRegistry)
                : null;
        this.dlqCounter = meterRegistry != null
                ? Counter.builder("telemetry.stream.consumer.dlq.count").register(meterRegistry)
                : null;
        this.acknowledgedCounter = meterRegistry != null
                ? Counter.builder("telemetry.stream.consumer.acknowledged.count").register(meterRegistry)
                : null;
        if (meterRegistry != null) {
            Gauge.builder("telemetry.stream.consumer.pending.count", this, TelemetryStreamConsumer::pendingGaugeValue)
                    .register(meterRegistry);
            Gauge.builder("telemetry.stream.consumer.poll.staleness.ms", this, TelemetryStreamConsumer::pollStalenessGaugeValue)
                    .register(meterRegistry);
        }
    }

    private static String normalizeMode(String mode) {
        return mode == null || mode.isBlank() ? "group" : mode.trim().toLowerCase();
    }

    private static String sanitizeConsumerName(String name) {
        String fallback = "telematics-api-" + UUID.randomUUID();
        if (name == null || name.isBlank()) {
            return fallback;
        }
        return name.replaceAll("\\s+", "-");
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

        if (usesConsumerGroup()) {
            ensureConsumerGroup();
            this.lastId = ">";
        } else {
            refreshOffsetState();
        }

        log.info("Starting telemetry stream polling thread (pollMs={}ms, mode={}, group={}, consumer={})",
                pollMs, consumerMode, consumerGroup, consumerName);
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

        if (usesConsumerGroup()) {
            pollStreamWithConsumerGroup();
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
                        ingestService.acceptFromStreamDetailed(event);
                    }
                    advanceOffset(record);
                } catch (Exception e) {
                    log.warn("Failed to parse telemetry event {}: {}", record.getId(), e.getMessage());
                    publishToDlq(record, e);
                    advanceOffset(record);
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

    private void pollStreamWithConsumerGroup() {
        try {
            Consumer consumer = Consumer.from(consumerGroup, consumerName);
            int claimedCount = claimAbandonedPendingRecords(consumer);
            int pendingCount = drainPendingRecords(consumer);
            if (claimedCount > 0 || pendingCount > 0) {
                lastPollTimestampMs = System.currentTimeMillis();
                lastPollRecordCount = claimedCount + pendingCount;
                lastPollError = null;
                return;
            }

            List<MapRecord<String, String, String>> records = streamOps.read(
                    consumer,
                    StreamReadOptions.empty().count(50).block(Duration.ofMillis(500)),
                    StreamOffset.create(streamName, ReadOffset.lastConsumed()));
            processGroupRecords(records);
        } catch (RedisCommandTimeoutException e) {
            lastPollTimestampMs = System.currentTimeMillis();
            lastPollRecordCount = 0;
            lastPollError = e.getMessage();
            log.debug("Telemetry stream group poll timeout ({}): {}", streamName, e.getMessage());
        } catch (Exception e) {
            lastPollTimestampMs = System.currentTimeMillis();
            lastPollRecordCount = 0;
            lastPollError = e.getMessage();
            log.warn("Error polling telemetry stream {} with consumer group {}: {}",
                    streamName, consumerGroup, e.getMessage());
        }
    }

    private int drainPendingRecords(Consumer consumer) {
        List<MapRecord<String, String, String>> pendingRecords = streamOps.read(
                consumer,
                StreamReadOptions.empty().count(25),
                StreamOffset.create(streamName, ReadOffset.from("0")));
        processGroupRecords(pendingRecords);
        return pendingRecords == null ? 0 : pendingRecords.size();
    }

    private int claimAbandonedPendingRecords(Consumer consumer) {
        List<RecordIdHolder> claimableIds = getClaimablePendingIds(consumer);
        if (claimableIds.isEmpty()) {
            lastClaimedRecordCount = 0;
            return 0;
        }

        try {
            List<MapRecord<String, String, String>> claimed = streamOps.claim(
                    streamName,
                    consumerGroup,
                    consumerName,
                    org.springframework.data.redis.connection.RedisStreamCommands.XClaimOptions
                            .minIdle(Duration.ofMillis(claimIdleMs))
                            .ids(claimableIds.stream().map(RecordIdHolder::id).toArray(org.springframework.data.redis.connection.stream.RecordId[]::new)));
            int count = claimed == null ? 0 : claimed.size();
            lastClaimedRecordCount = count;
            if (count > 0) {
                increment(claimedCounter, count);
                log.warn("Claimed {} abandoned telemetry record(s) from group {} for consumer {}",
                        count, consumerGroup, consumerName);
                processGroupRecords(claimed);
            }
            return count;
        } catch (Exception e) {
            log.warn("Failed to claim abandoned telemetry records for group {} consumer {}: {}",
                    consumerGroup, consumerName, e.getMessage());
            lastClaimedRecordCount = 0;
            return 0;
        }
    }

    private List<RecordIdHolder> getClaimablePendingIds(Consumer consumer) {
        try {
            org.springframework.data.redis.connection.stream.PendingMessages pending =
                    streamOps.pending(streamName, consumerGroup,
                            org.springframework.data.domain.Range.unbounded(), claimBatchSize);
            if (pending == null || pending.isEmpty()) {
                return List.of();
            }

            List<RecordIdHolder> ids = new ArrayList<>();
            for (PendingMessage message : pending) {
                if (message == null || message.getId() == null) {
                    continue;
                }
                if (consumerName.equals(message.getConsumerName())) {
                    continue;
                }
                Duration idle = message.getElapsedTimeSinceLastDelivery();
                if (idle != null && idle.toMillis() >= claimIdleMs) {
                    ids.add(new RecordIdHolder(message.getId(), message.getConsumerName()));
                }
            }
            return ids;
        } catch (Exception e) {
            log.debug("Unable to inspect pending telemetry entries for group {}: {}", consumerGroup, e.getMessage());
            return List.of();
        }
    }

    private void processGroupRecords(List<MapRecord<String, String, String>> records) {
        int recordCount = records == null ? 0 : records.size();
        lastPollTimestampMs = System.currentTimeMillis();
        lastPollRecordCount = recordCount;
        lastPollError = null;

        if (recordCount == 0) {
            return;
        }

        log.info("Consumed {} records from stream {} via group {}", recordCount, streamName, consumerGroup);
        for (MapRecord<String, String, String> record : records) {
            try {
                TelemetryEvent event = parse(record.getValue());
                if (ingestService != null) {
                    ingestService.acceptFromStreamDetailed(event);
                }
                acknowledgeRecord(record);
            } catch (Exception e) {
                log.warn("Failed to process telemetry event {} in group {}: {}", record.getId(), consumerGroup, e.getMessage());
                publishToDlq(record, e);
                acknowledgeRecord(record);
            }
        }
    }

    public Map<String, Object> getConsumerStatus() {
        Map<String, Object> status = new java.util.HashMap<>();
        status.put("enabled", enabled);
        status.put("pollingThreadAlive", pollingThread != null && pollingThread.isAlive());
        status.put("mode", consumerMode);
        status.put("group", usesConsumerGroup() ? consumerGroup : null);
        status.put("consumerName", usesConsumerGroup() ? consumerName : null);
        status.put("lastId", lastId);
        status.put("lastPollTimestampMs", lastPollTimestampMs);
        status.put("lastPollRecordCount", lastPollRecordCount);
        status.put("lastClaimedRecordCount", lastClaimedRecordCount);
        status.put("lastPollError", lastPollError);
        status.put("pollStalenessMs", getPollStalenessMs());
        if (usesConsumerGroup()) {
            PendingMessagesSummary summary = getPendingSummary().orElse(null);
            status.put("pendingCount", summary != null ? summary.getTotalPendingMessages() : null);
        }
        return status;
    }

    public Optional<Long> getPendingCount() {
        return getPendingSummary().map(PendingMessagesSummary::getTotalPendingMessages);
    }

    public long getPollStalenessMs() {
        if (lastPollTimestampMs <= 0) {
            return Long.MAX_VALUE;
        }
        return Math.max(0, System.currentTimeMillis() - lastPollTimestampMs);
    }

    public Optional<String> getCurrentStreamLastId() {
        return getLastStreamId();
    }

    public Optional<Long> getApproximateLagEntries() {
        if (usesConsumerGroup()) {
            return getPendingCount();
        }
        Optional<String> streamLastId = getLastStreamId();
        if (streamLastId.isEmpty()) {
            return Optional.empty();
        }
        return approximateLagEntries(lastId, streamLastId.get());
    }

    static Optional<Long> approximateLagEntries(String consumerLastId, String streamLastId) {
        if (consumerLastId == null || streamLastId == null) {
            return Optional.empty();
        }
        String[] consumerParts = consumerLastId.split("-");
        String[] streamParts = streamLastId.split("-");
        if (consumerParts.length != 2 || streamParts.length != 2) {
            return Optional.empty();
        }
        try {
            long consumerMs = Long.parseLong(consumerParts[0]);
            long consumerSeq = Long.parseLong(consumerParts[1]);
            long streamMs = Long.parseLong(streamParts[0]);
            long streamSeq = Long.parseLong(streamParts[1]);
            if (streamMs < consumerMs || (streamMs == consumerMs && streamSeq < consumerSeq)) {
                return Optional.of(0L);
            }
            long msDelta = streamMs - consumerMs;
            long seqDelta = streamSeq - consumerSeq;
            long estimate = msDelta == 0 ? Math.max(0, seqDelta) : Math.max(1, msDelta);
            return Optional.of(Math.max(0, estimate));
        } catch (NumberFormatException ex) {
            return Optional.empty();
        }
    }

    private TelemetryEvent parse(Map<String, String> raw) {
        // Redis stream values are stored as strings. Jackson will convert them to the target types.
        return objectMapper.convertValue(raw, TelemetryEvent.class);
    }

    private boolean usesConsumerGroup() {
        return "group".equals(consumerMode);
    }

    private void ensureConsumerGroup() {
        try {
            ensureStreamExistsForGroup();
            streamOps.createGroup(streamName, ReadOffset.latest(), consumerGroup);
            log.info("Created telemetry consumer group {} on stream {}", consumerGroup, streamName);
        } catch (Exception e) {
            String message = e.getMessage() == null ? "" : e.getMessage();
            if (message.contains("BUSYGROUP")) {
                log.info("Telemetry consumer group {} already exists on {}", consumerGroup, streamName);
                return;
            }
            log.warn("Unable to create telemetry consumer group {} on {}: {}", consumerGroup, streamName, message);
        }
    }

    private void ensureStreamExistsForGroup() {
        try {
            if (streamOps.info(streamName) != null) {
                return;
            }
        } catch (Exception ignore) {
            // Stream may not exist yet.
        }

        try {
            MapRecord<String, String, String> bootstrapRecord =
                    org.springframework.data.redis.connection.stream.StreamRecords.mapBacked(Map.of("_bootstrap", "1"))
                            .withStreamKey(streamName);
            var recordId = streamOps.add(bootstrapRecord);
            if (recordId != null) {
                streamOps.delete(streamName, recordId);
            }
        } catch (Exception e) {
            log.debug("Unable to bootstrap telemetry stream {} before creating group: {}", streamName, e.getMessage());
        }
    }

    private Optional<PendingMessagesSummary> getPendingSummary() {
        if (!enabled || !usesConsumerGroup()) {
            return Optional.empty();
        }
        try {
            return Optional.ofNullable(streamOps.pending(streamName, consumerGroup));
        } catch (Exception e) {
            log.debug("Unable to read pending summary for stream {} group {}: {}",
                    streamName, consumerGroup, e.getMessage());
            return Optional.empty();
        }
    }

    record RecordIdHolder(org.springframework.data.redis.connection.stream.RecordId id, String previousConsumer) {
    }

    private void advanceOffset(MapRecord<String, String, String> record) {
        lastId = normalizeLastId(record.getId().getValue());
        try {
            stringRedisTemplate.opsForValue().set(offsetKey, lastId);
        } catch (Exception ignore) {
            // best-effort persistence
        }
    }

    private void acknowledgeRecord(MapRecord<String, String, String> record) {
        lastId = normalizeLastId(record.getId().getValue());
        if (!usesConsumerGroup()) {
            advanceOffset(record);
            return;
        }
        try {
            streamOps.acknowledge(streamName, consumerGroup, record.getId());
            increment(acknowledgedCounter);
        } catch (Exception e) {
            log.warn("Failed to acknowledge telemetry event {} for group {}: {}",
                    record.getId(), consumerGroup, e.getMessage());
        }
    }

    private void publishToDlq(MapRecord<String, String, String> record, Exception error) {
        try {
            Map<String, String> dlqPayload = new HashMap<>(record.getValue());
            dlqPayload.put("sourceStream", streamName);
            dlqPayload.put("sourceRecordId", record.getId().getValue());
            dlqPayload.put("failedAt", Instant.now().toString());
            dlqPayload.put("error", error.getClass().getSimpleName() + ": " + error.getMessage());
            streamOps.add(dlqStreamName, dlqPayload);
            increment(dlqCounter);
        } catch (Exception dlqError) {
            log.error("Failed to publish telemetry event {} to DLQ {}: {}",
                    record.getId(), dlqStreamName, dlqError.getMessage());
        }
    }

    double pendingGaugeValue() {
        return getPendingCount().orElse(0L);
    }

    double pollStalenessGaugeValue() {
        long staleness = getPollStalenessMs();
        return staleness == Long.MAX_VALUE ? -1d : staleness;
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
