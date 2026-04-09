package com.svtrucking.telematics.service;

import com.svtrucking.telematics.dto.LiveDriverDto;
import com.svtrucking.telematics.dto.TelemetryEvent;
import com.svtrucking.telematics.dto.requests.DriverLocationUpdateDto;
import com.svtrucking.telematics.model.LocationHistory;
import com.svtrucking.telematics.model.DriverLatestLocation;
import com.svtrucking.telematics.repository.DriverLatestLocationRepository;
import com.svtrucking.telematics.repository.LocationHistoryRepository;
import com.svtrucking.telematics.service.TelemetryStreamService;
import io.micrometer.core.instrument.Gauge;
import io.micrometer.core.instrument.MeterRegistry;
import jakarta.annotation.PostConstruct;
import jakarta.annotation.PreDestroy;
import java.time.Instant;
import java.time.LocalDateTime;
import java.time.ZoneOffset;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.concurrent.BlockingQueue;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.LinkedBlockingQueue;
import java.util.concurrent.atomic.AtomicBoolean;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/**
 * GPS location ingest pipeline for tms-telematics-api.
 * Adapted from tms-backend: EntityManager removed — all LocationHistory fields
 * set via setDriverId()
 * / setDispatchId() directly.
 */
@Service
@Slf4j
public class LocationIngestService {

    private final DriverLatestLocationRepository latestRepo;
    private final LocationHistoryRepository historyRepo;
    private final GeocodingService geocodingService;
    private final LiveLocationCacheServiceInterface cacheService;
    private final DriverLocationMongoService mongoService;
    private final LocationHistorySpoolService spoolService;
    private final TelemetryStreamService telemetryStreamService;
    private final boolean mongoEnabled;

    @Autowired(required = false)
    private MeterRegistry meterRegistry;
    private final AtomicBoolean metricsInitialized = new AtomicBoolean(false);

    public LocationIngestService(
            DriverLatestLocationRepository latestRepo,
            LocationHistoryRepository historyRepo,
            GeocodingService geocodingService,
            @Autowired(required = false) LiveLocationCacheServiceInterface cacheService,
            @Autowired(required = false) DriverLocationMongoService mongoService,
            @Autowired(required = false) LocationHistorySpoolService spoolService,
            @Autowired(required = false) TelemetryStreamService telemetryStreamService) {
        this.latestRepo = latestRepo;
        this.historyRepo = historyRepo;
        this.geocodingService = geocodingService;
        this.cacheService = cacheService;
        this.mongoService = mongoService;
        this.spoolService = spoolService;
        this.telemetryStreamService = telemetryStreamService;
        this.mongoEnabled = mongoService != null;
    }

    @Value("${tracking.server_throttle_ms:3000}")
    private long SERVER_THROTTLE_MS;
    @Value("${tracking.server_min_distance_m:50}")
    private double SERVER_MIN_DIST_M;
    @Value("${tracking.max_idle_keepalive_ms:60000}")
    private long MAX_IDLE_KEEPALIVE_MS;
    @Value("${tracking.server_min_time_ms:8000}")
    private long SERVER_MIN_TIME_MS;
    @Value("${tracking.batch_flush_ms:2000}")
    private long BATCH_FLUSH_MS;
    @Value("${tracking.batch_max_records:2000}")
    private int BATCH_MAX_RECORDS;
    @Value("${tracking.queue_capacity:50000}")
    private int QUEUE_CAPACITY;
    @Value("${location.history.postgres.write.enabled:true}")
    private boolean postgresHistoryWriteEnabled;
    @Value("${location.history.spool.enabled:true}")
    private boolean spoolEnabled;
    @Value("${location.history.spool.replay.batch-size:2000}")
    private int spoolReplayBatchSize;
    @Value("${presence.online_ms:35000}")
    private long PRESENCE_ONLINE_MS;
    @Value("${presence.idle_ms:180000}")
    private long PRESENCE_IDLE_MS;
    @Value("${geocode.min_distance_m:200}")
    private double GEOCODE_MIN_DISTANCE_M;

    private final ConcurrentHashMap<Long, LastPoint> lastPoint = new ConcurrentHashMap<>();
    private final ConcurrentHashMap<Long, LastGeo> lastGeoName = new ConcurrentHashMap<>();
    private BlockingQueue<LocationHistory> buffer;

    @PostConstruct
    void initBuffer() {
        int cap = (QUEUE_CAPACITY > 0) ? QUEUE_CAPACITY : 50_000;
        buffer = new LinkedBlockingQueue<>(cap);
        log.info("Location buffer capacity = {}", cap);
        log.info("tracking: throttle={}ms, minDist={}m, minTime={}ms, keepAlive={}ms",
                SERVER_THROTTLE_MS, SERVER_MIN_DIST_M, SERVER_MIN_TIME_MS, MAX_IDLE_KEEPALIVE_MS);
        log.info("Optional Mongo history sink {}", mongoEnabled ? "ENABLED" : "DISABLED");
        registerMetricsIfNeeded();
    }

    public Map<String, Object> accept(DriverLocationUpdateDto u) {
        return processLocationUpdate(u, true);
    }

    public Map<String, Object> acceptFromStream(TelemetryEvent event) {
        Long dispatchId = null;
        if (event.getDispatchId() != null) {
            try {
                dispatchId = Long.valueOf(event.getDispatchId());
            } catch (NumberFormatException ignored) {
                // keep null
            }
        }
        Long seq = null;
        if (event.getSeq() != null) {
            try {
                seq = Long.valueOf(event.getSeq());
            } catch (NumberFormatException ignored) {
                // keep null
            }
        }

        DriverLocationUpdateDto u = DriverLocationUpdateDto.builder()
                .driverId(event.getDriverId())
                .dispatchId(dispatchId)
                .pointId(event.getPointId())
                .seq(seq)
                .sessionId(event.getSessionId())
                .source(event.getSource())
                .version(null)
                .netType(event.getNetType())
                .locationSource(event.getLocationSource())
                .gpsOn(null)
                .vehiclePlate(null)
                .latitude(event.getLatitude())
                .longitude(event.getLongitude())
                .heading(event.getHeading())
                .accuracyMeters(event.getAccuracyMeters())
                .speed(event.getSpeed())
                .clientTime(event.getEventTime() != null ? event.getEventTime().toEpochMilli() : null)
                .batteryLevel(event.getBatteryLevel())
                .locationName(event.getLocationName())
                .build();
        return processLocationUpdate(u, false);
    }

    private Map<String, Object> processLocationUpdate(DriverLocationUpdateDto u, boolean publishToStream) {
        if (u.getDriverId() == null || !finite(u.getLatitude()) || !finite(u.getLongitude()))
            return null;

        if (postgresHistoryWriteEnabled && u.getPointId() != null && !u.getPointId().isBlank()
                && historyRepo.existsByDriverIdAndPointId(u.getDriverId(), u.getPointId().trim()))
            return null;

        if (u.getLatitude() < -90.0 || u.getLatitude() > 90.0
                || u.getLongitude() < -180.0 || u.getLongitude() > 180.0) {
            log.warn("Ignored update: out-of-range lat/lng for driver={}", u.getDriverId());
            return null;
        }

        final long now = System.currentTimeMillis();
        final long eventMillis = u.effectiveEpochMillisOr(now);

        final LastPoint prev = lastPoint.get(u.getDriverId());
        if (prev != null) {
            long dt = Math.max(0L, eventMillis - prev.eventTs());
            double dist = haversine(prev.lat(), prev.lng(), u.getLatitude(), u.getLongitude());
            boolean underThrottle = dt < SERVER_THROTTLE_MS && dist < SERVER_MIN_DIST_M;
            boolean timeEnough = dt >= SERVER_MIN_TIME_MS;
            boolean idleTooLong = dt >= MAX_IDLE_KEEPALIVE_MS;
            if (underThrottle && !timeEnough && !idleTooLong)
                return null;
        }

        Integer battery = (u.getBatteryLevel() != null && u.getBatteryLevel() >= 0) ? u.getBatteryLevel() : null;
        String src = (u.getSource() != null && !u.getSource().isBlank()) ? u.getSource() : "ANDROID_FLUTTER";
        Long appVersionCode = (u.getVersion() != null) ? u.getVersion().longValue() : null;

        String locName;
        if (u.getLocationName() != null && !u.getLocationName().isBlank()) {
            locName = u.getLocationName();
        } else {
            try {
                LastGeo lg = lastGeoName.get(u.getDriverId());
                double distFromNamed = (lg == null)
                        ? Double.POSITIVE_INFINITY
                        : haversine(lg.lat(), lg.lng(), u.getLatitude(), u.getLongitude());
                if (distFromNamed >= GEOCODE_MIN_DISTANCE_M) {
                    locName = geocodingService.reverseGeocode(u.getLatitude(), u.getLongitude());
                    if (locName != null && !locName.isBlank())
                        lastGeoName.put(u.getDriverId(), new LastGeo(u.getLatitude(), u.getLongitude(), locName));
                } else {
                    locName = (lg != null) ? lg.name() : null;
                }
            } catch (Exception e) {
                log.warn("Reverse geocode failed: {}", e.toString());
                locName = null;
            }
        }

        // Publish telemetry event to stream (if configured) for downstream processing / replay.
        if (publishToStream && telemetryStreamService != null) {
            telemetryStreamService.publish(TelemetryEvent.builder()
                    .driverId(u.getDriverId())
                    .dispatchId(u.getDispatchId() == null ? null : u.getDispatchId().toString())
                    .latitude(u.getLatitude())
                    .longitude(u.getLongitude())
                    .speed(u.getSpeed())
                    .heading(u.getHeading())
                    .batteryLevel(battery)
                    .source(src)
                    .locationName(locName)
                    .accuracyMeters(u.getAccuracyMeters())
                    .locationSource(u.getLocationSource())
                    .netType(u.getNetType())
                    .pointId(u.getPointId())
                    .sessionId(u.getSessionId())
                    .seq(u.getSeq() == null ? null : u.getSeq().toString())
                    .eventTime(Instant.ofEpochMilli(eventMillis))
                    .build());
        }

        try {
            latestRepo.upsertLatest(u.getDriverId(), u.getLatitude(), u.getLongitude(),
                    u.getSpeed(), u.getHeading(), u.getDispatchId(), battery, src, locName,
                    true, u.getAccuracyMeters(), u.getLocationSource(), u.getNetType(), appVersionCode);
            if (meterRegistry != null)
                meterRegistry.counter("location.latest.upsert.success").increment();
        } catch (Exception e) {
            if (meterRegistry != null)
                meterRegistry.counter("location.latest.upsert.failure").increment();
            throw e;
        }

        // Build history row — plain setDriverId / setDispatchId (no EntityManager
        // needed)
        LocationHistory h = new LocationHistory();
        h.setDriverId(u.getDriverId());
        h.setDispatchId(u.getDispatchId());
        h.setLatitude(u.getLatitude());
        h.setLongitude(u.getLongitude());
        h.setSpeed(u.getSpeed());
        h.setBatteryLevel(battery);
        h.setSource(src);
        h.setLocationName(locName);
        h.setHeading(u.getHeading());
        h.setAccuracyMeters(u.getAccuracyMeters());
        h.setLocationSource(u.getLocationSource());
        h.setNetType(u.getNetType());
        h.setAppVersionCode(appVersionCode);
        if (u.getPointId() != null && !u.getPointId().isBlank())
            h.setPointId(u.getPointId().trim());
        h.setSeq(u.getSeq());
        if (u.getSessionId() != null && !u.getSessionId().isBlank())
            h.setSessionId(u.getSessionId().trim());

        LocalDateTime eventLdt = Instant.ofEpochMilli(eventMillis).atZone(ZoneOffset.UTC).toLocalDateTime();
        h.setTimestamp(eventLdt);
        h.setEventTime(eventLdt);
        h.setIsOnline(true);

        enqueueHistory(h, u.getDriverId());
        lastPoint.put(u.getDriverId(), new LastPoint(u.getLatitude(), u.getLongitude(), eventMillis));
        if (locName != null && !locName.isBlank())
            lastGeoName.put(u.getDriverId(), new LastGeo(u.getLatitude(), u.getLongitude(), locName));

        DriverLatestLocation latest = latestRepo.findById(u.getDriverId()).orElse(null);
        Map<String, Object> live = new HashMap<>();
        live.put("driverId", u.getDriverId());
        live.put("clientTime", eventMillis);
        live.put("serverTime", now);
        live.put("isOnline", Boolean.TRUE);

        if (latest != null) {
            live.put("latitude", latest.getLatitude());
            live.put("longitude", latest.getLongitude());
            live.put("lastSeen",
                    toEpochMillis(latest.getLastSeen()) != null ? toEpochMillis(latest.getLastSeen()) : now);
            if (latest.getSpeed() != null) {
                double kmh = Math.max(0, latest.getSpeed()) * 3.6;
                live.put("speedMps", Math.max(0, latest.getSpeed()));
                live.put("speed", Math.round(kmh * 10.0) / 10.0);
            }
            live.put("heading", latest.getHeading());
            if (latest.getBatteryLevel() != null)
                live.put("batteryLevel", latest.getBatteryLevel());
            if (latest.getLocationName() != null)
                live.put("locationName", latest.getLocationName());
        } else {
            live.put("latitude", u.getLatitude());
            live.put("longitude", u.getLongitude());
            live.put("lastSeen", now);
        }

        if (cacheService != null) {
            try {
                cacheService.cacheDriverLocation(u.getDriverId(), convertToLiveDriverDto(live));
            } catch (Exception e) {
                log.warn("Failed to cache live location for driver {}: {}", u.getDriverId(), e.getMessage());
            }
        }

        return live;
    }

    @Scheduled(fixedDelayString = "${tracking.batch_flush_ms:2000}")
    public void flushBatch() {
        if (buffer.isEmpty())
            return;
        int drained, total = 0;
        do {
            List<LocationHistory> batch = new ArrayList<>(BATCH_MAX_RECORDS);
            drained = buffer.drainTo(batch, BATCH_MAX_RECORDS);
            if (drained > 0)
                total += persistBatch(batch);
        } while (drained == BATCH_MAX_RECORDS);
        if (total > 0)
            log.info("Flushed {} history point(s)", total);
    }

    @Scheduled(fixedDelayString = "${location.history.spool.replay.interval-ms:10000}")
    public void replaySpool() {
        if (!spoolEnabled || spoolService == null || mongoService == null)
            return;
        int replayed = spoolService.replayToMongo(Math.max(1, spoolReplayBatchSize), mongoService);
        if (replayed > 0) {
            log.info("Replayed {} spooled records to Mongo", replayed);
            if (meterRegistry != null)
                meterRegistry.counter("location.history.spool.replay.success").increment(replayed);
        }
    }

    @PreDestroy
    void flushBufferOnShutdown() {
        if (buffer == null || buffer.isEmpty())
            return;
        List<LocationHistory> remaining = new ArrayList<>(buffer.size());
        int drained = buffer.drainTo(remaining);
        if (drained > 0) {
            log.warn("Shutdown flush: persisting {} queued point(s)", drained);
            persistBatch(remaining);
        }
    }

    public Map<String, Object> markPresence(Long driverId, Integer battery, Boolean gpsEnabled,
            String device, Long clientTs, String reason) {
        if (driverId == null)
            return Map.of("ok", false, "reason", "driverId is null");
        final long now = System.currentTimeMillis();
        final String src = (device != null && !device.isBlank()) ? device : "HEARTBEAT";

        int updated = 0;
        try {
            updated = latestRepo.updatePresenceIfExists(driverId, battery, src);
        } catch (Exception e) {
            log.error("updatePresenceIfExists failed driver={}: {}", driverId, e.toString(), e);
        }

        if (updated == 0) {
            try {
                latestRepo.upsertPresence(driverId, battery, src);
            } catch (Exception e) {
                log.error("upsertPresence failed driver={}: {}", driverId, e.toString(), e);
            }
        }

        Map<String, Object> m = new HashMap<>();
        m.put("ok", true);
        m.put("driverId", driverId);
        m.put("clientTime", clientTs != null ? clientTs : now);
        m.put("serverTime", now);
        m.put("battery", battery);
        m.put("gpsEnabled", gpsEnabled);
        m.put("device", device);
        m.put("reason", reason);
        m.put("isOnline", Boolean.TRUE);

        try {
            DriverLatestLocation latest = latestRepo.findById(driverId).orElse(null);
            if (latest != null) {
                m.put("lastSeen", toEpochMillis(latest.getLastSeen()));
                m.put("latitude", latest.getLatitude());
                m.put("longitude", latest.getLongitude());
                if (latest.getBatteryLevel() != null)
                    m.put("batteryLevel", latest.getBatteryLevel());
            } else {
                m.put("lastSeen", now);
            }
        } catch (Exception e) {
            log.warn("Read-back latest after presence failed driver={}: {}", driverId, e.toString());
            m.put("lastSeen", now);
        }
        return m;
    }

    @Transactional(readOnly = true)
    public Long lastSeenEpochMs(Long driverId) {
        if (driverId == null)
            return null;
        try {
            return latestRepo.findById(driverId)
                    .map(DriverLatestLocation::getLastSeen)
                    .map(ts -> ts != null ? ts.getTime() : null).orElse(null);
        } catch (Exception e) {
            log.warn("lastSeenEpochMs({}) failed: {}", driverId, e.toString());
            return null;
        }
    }

    public String presenceStatus(Long lastSeenEpochMs) {
        long age = (lastSeenEpochMs == null) ? Long.MAX_VALUE
                : Math.max(0L, System.currentTimeMillis() - lastSeenEpochMs);
        if (age <= PRESENCE_ONLINE_MS)
            return "online";
        if (age <= PRESENCE_IDLE_MS)
            return "idle";
        return "offline";
    }

    public Map<String, Object> getHistoryPipelineHealth() {
        Map<String, Object> h = new HashMap<>();
        h.put("primaryHistoryStore", postgresHistoryWriteEnabled ? "POSTGRES" : "NONE");
        h.put("mongoEnabled", mongoEnabled);
        h.put("postgresHistoryWriteEnabled", postgresHistoryWriteEnabled);
        h.put("spoolEnabled", spoolEnabled && spoolService != null);
        h.put("inMemoryBufferDepth", buffer != null ? buffer.size() : 0);
        h.put("inMemoryBufferCapacity", QUEUE_CAPACITY);
        return h;
    }

    // ── Private helpers ──────────────────────────────────────────────────────

    private void enqueueHistory(LocationHistory h, Long driverId) {
        if (buffer.offer(h))
            return;
        log.warn("Queue full for driver={}. Persisting overflow directly.", driverId);
        if (persistBatch(List.of(h)) <= 0)
            log.error("Unable to persist overflow history for driver={}", driverId);
    }

    @Transactional
    protected int persistBatch(List<LocationHistory> batch) {
        if (batch == null || batch.isEmpty())
            return 0;
        if (postgresHistoryWriteEnabled) {
            try {
                historyRepo.saveAll(batch);
            } catch (Exception e) {
                log.error("PostgreSQL batch save failed for {} item(s): {}", batch.size(), e.toString(), e);
                for (LocationHistory item : batch) {
                    try {
                        historyRepo.save(item);
                    } catch (Exception ex) {
                        log.error("Failed PostgreSQL row save driverId={}: {}", item.getDriverId(), ex.toString(), ex);
                        if (meterRegistry != null)
                            meterRegistry.counter("location.history.postgres.write.failure").increment();
                    }
                }
            }
            if (meterRegistry != null) {
                meterRegistry.counter("location.history.postgres.write.success").increment(batch.size());
            }
        }
        boolean mongoSaved = false;
        if (mongoService != null) {
            mongoSaved = mongoService.trySaveAll(batch);
            if (meterRegistry != null)
                meterRegistry
                        .counter(mongoSaved ? "location.history.mongo.write.success"
                                : "location.history.mongo.write.failure")
                        .increment(batch.size());
        }
        if (!mongoSaved) {
            if (spoolEnabled && spoolService != null)
                spoolService.appendBatch(batch);
            else if (mongoService == null) {
                log.warn("Secondary history sink unavailable and spool disabled. Dropping {} history records.", batch.size());
                if (meterRegistry != null)
                    meterRegistry.counter("location.history.dropped.records").increment(batch.size());
            }
        }
        return batch.size();
    }

    private void registerMetricsIfNeeded() {
        if (meterRegistry == null || !metricsInitialized.compareAndSet(false, true))
            return;
        Gauge.builder("location.history.buffer.depth", buffer, BlockingQueue::size).register(meterRegistry);
        if (spoolService != null) {
            Gauge.builder("location.history.spool.bytes", spoolService, s -> (double) s.currentSpoolBytes())
                    .register(meterRegistry);
            Gauge.builder("location.history.spool.oldest.age.seconds", spoolService,
                    s -> (double) s.oldestPendingAgeSeconds()).register(meterRegistry);
        }
    }

    private LiveDriverDto convertToLiveDriverDto(Map<String, Object> live) {
        LiveDriverDto dto = new LiveDriverDto();
        dto.setDriverId((Long) live.get("driverId"));
        dto.setLatitude((Double) live.get("latitude"));
        dto.setLongitude((Double) live.get("longitude"));
        dto.setSpeed((Double) live.get("speed"));
        dto.setHeading((Double) live.get("heading"));
        dto.setBatteryLevel((Integer) live.get("batteryLevel"));
        dto.setLocationName((String) live.get("locationName"));
        dto.setOnline((Boolean) live.get("isOnline"));
        dto.setUpdatedAt(Instant.now());
        dto.setSource((String) live.get("source"));
        return dto;
    }

    private record LastPoint(double lat, double lng, long eventTs) {
    }

    private record LastGeo(double lat, double lng, String name) {
    }

    private static boolean finite(Double x) {
        return x != null && !x.isNaN() && !x.isInfinite();
    }

    private static double haversine(double lat1, double lon1, double lat2, double lon2) {
        final double R = 6_371_000.0;
        double dLat = Math.toRadians(lat2 - lat1), dLon = Math.toRadians(lon2 - lon1);
        double a = Math.sin(dLat / 2) * Math.sin(dLat / 2) + Math.cos(Math.toRadians(lat1))
                * Math.cos(Math.toRadians(lat2)) * Math.sin(dLon / 2) * Math.sin(dLon / 2);
        return 2 * R * Math.asin(Math.sqrt(a));
    }

    private static Long toEpochMillis(java.sql.Timestamp ts) {
        return ts != null ? ts.getTime() : null;
    }
}
