package com.svtrucking.logistics.service;

import com.svtrucking.logistics.core.service.GeocodingService;
import com.svtrucking.logistics.dto.LiveDriverDto;
import com.svtrucking.logistics.dto.requests.DriverLocationUpdateDto;
import com.svtrucking.logistics.model.Dispatch;
import com.svtrucking.logistics.model.Driver;
import com.svtrucking.logistics.model.DriverLatestLocation;
import com.svtrucking.logistics.model.LocationHistory;
import com.svtrucking.logistics.repository.DriverLatestLocationRepository;
import com.svtrucking.logistics.repository.LocationHistoryRepository;
import io.micrometer.core.instrument.Gauge;
import io.micrometer.core.instrument.MeterRegistry;
import jakarta.annotation.PostConstruct;
import jakarta.annotation.PreDestroy;
import jakarta.persistence.EntityManager;
import jakarta.persistence.PersistenceContext;
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

@Service
@Slf4j
public class LocationIngestService {

  private final DriverLatestLocationRepository latestRepo;
  private final LocationHistoryRepository historyRepo;
  private final GeocodingService geocodingService;
  private final LiveLocationCacheServiceInterface cacheService;
  private final DriverLocationMongoService mongoService;
  private final LocationHistorySpoolService spoolService;
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
      @Autowired(required = false) LocationHistorySpoolService spoolService) {
    this.latestRepo = latestRepo;
    this.historyRepo = historyRepo;
    this.geocodingService = geocodingService;
    this.cacheService = cacheService;
    this.mongoService = mongoService;
    this.spoolService = spoolService;
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

  @Value("${tracking.batch_flush_ms:1000}")
  private long BATCH_FLUSH_MS;

  @Value("${tracking.batch_max_records:2000}")
  private int BATCH_MAX_RECORDS;

  @Value("${tracking.queue_capacity:50000}")
  private int QUEUE_CAPACITY;

  @Value("${location.history.mysql.write.enabled:false}")
  private boolean mysqlHistoryWriteEnabled;

  @Value("${location.history.spool.enabled:true}")
  private boolean spoolEnabled;

  @Value("${location.history.spool.replay.batch-size:2000}")
  private int spoolReplayBatchSize;

  @Value("${app.scheduling.location.enabled:true}")
  private boolean schedulingEnabled;

  @Value("${presence.online_ms:35000}")
  private long PRESENCE_ONLINE_MS;

  @Value("${presence.idle_ms:180000}")
  private long PRESENCE_IDLE_MS;

  @Value("${geocode.min_distance_m:200}")
  private double GEOCODE_MIN_DISTANCE_M;

  @Value("${presence.sweeper_ms:10000}")
  private long PRESENCE_SWEEPER_MS;

  private final ConcurrentHashMap<Long, LastPoint> lastPoint = new ConcurrentHashMap<>();
  private final ConcurrentHashMap<Long, LastGeo> lastGeoName = new ConcurrentHashMap<>();
  private BlockingQueue<LocationHistory> buffer;

  @PersistenceContext private EntityManager em;

  @PostConstruct
  void initBuffer() {
    int cap = (QUEUE_CAPACITY > 0) ? QUEUE_CAPACITY : 50_000;
    buffer = new LinkedBlockingQueue<>(cap);
    log.info(" Location buffer capacity = {}", cap);
    log.info(
        "⚙️ tracking: throttle={}ms, minDist={}m, minTime={}ms, keepAlive={}ms, flush={}ms, batchMax={}",
        SERVER_THROTTLE_MS,
        SERVER_MIN_DIST_M,
        SERVER_MIN_TIME_MS,
        MAX_IDLE_KEEPALIVE_MS,
        BATCH_FLUSH_MS,
        BATCH_MAX_RECORDS);
    log.info(" Mongo dual-write {}", mongoEnabled ? "ENABLED" : "DISABLED");
    log.info(
        "📍 History stores: mysqlWrite={} mongo={} spool={}",
        mysqlHistoryWriteEnabled,
        mongoEnabled,
        spoolEnabled);
    registerMetricsIfNeeded();
  }

  public Map<String, Object> accept(DriverLocationUpdateDto u) {
    if (u.getDriverId() == null || !finite(u.getLatitude()) || !finite(u.getLongitude())) return null;
    if (mysqlHistoryWriteEnabled
        && u.getPointId() != null
        && !u.getPointId().isBlank()
        && historyRepo.existsByDriverIdAndPointId(u.getDriverId(), u.getPointId().trim())) {
      if (log.isDebugEnabled()) {
        log.debug("Drop duplicate pointId driver={} pointId={}", u.getDriverId(), u.getPointId());
      }
      return null;
    }

    if (u.getLatitude() < -90.0
        || u.getLatitude() > 90.0
        || u.getLongitude() < -180.0
        || u.getLongitude() > 180.0) {
      log.warn(
          "Ignored update: out-of-range lat/lng for driver={} lat={} lng={}",
          u.getDriverId(),
          u.getLatitude(),
          u.getLongitude());
      return null;
    }

    if (isInvalidMapFix(u.getLatitude(), u.getLongitude())) {
      log.info(
          "Treating invalid map fix as presence-only for driver={} lat={} lng={}",
          u.getDriverId(),
          u.getLatitude(),
          u.getLongitude());
      Map<String, Object> presence =
          markPresence(
              u.getDriverId(),
              u.getBatteryLevel(),
              u.getGpsOn(),
              u.getSource(),
              u.effectiveEpochMillisOr(System.currentTimeMillis()),
              "invalid-coordinates");
      presence.put("invalidCoordinates", Boolean.TRUE);
      presence.put("locationAccepted", Boolean.FALSE);
      return presence;
    }

    if (log.isTraceEnabled()) {
      log.trace(
          "↑ loc driver={} lat={} lng={} speed={} acc={} src={} locSrc={} net={} ver={}",
          u.getDriverId(),
          u.getLatitude(),
          u.getLongitude(),
          u.getSpeed(),
          u.getAccuracyMeters(),
          u.getSource(),
          u.getLocationSource(),
          u.getNetType(),
          u.getVersion());
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
      if (underThrottle && !timeEnough && !idleTooLong) {
        if (log.isDebugEnabled()) {
          log.debug(
              "🛑 Drop jitter: driver={} Δt={}ms (minTime={}ms keepAlive={}ms) Δd={}m (minDist={}m)",
              u.getDriverId(),
              dt,
              SERVER_MIN_TIME_MS,
              MAX_IDLE_KEEPALIVE_MS,
              Math.round(dist),
              Math.round(SERVER_MIN_DIST_M));
        }
        return null;
      }
    }

    Integer battery =
        (u.getBatteryLevel() != null && u.getBatteryLevel() >= 0) ? u.getBatteryLevel() : null;
    String src =
        (u.getSource() != null && !u.getSource().isBlank()) ? u.getSource() : "ANDROID_FLUTTER";
    Long appVersionCode = (u.getVersion() != null) ? u.getVersion().longValue() : null;
    String locName;
    if (u.getLocationName() != null && !u.getLocationName().isBlank()) {
      locName = u.getLocationName();
    } else {
      try {
        LastGeo lg = lastGeoName.get(u.getDriverId());
        double distFromNamed =
            (lg == null)
                ? Double.POSITIVE_INFINITY
                : haversine(lg.lat(), lg.lng(), u.getLatitude(), u.getLongitude());
        if (distFromNamed >= GEOCODE_MIN_DISTANCE_M) {
          locName = geocodingService.reverseGeocode(u.getLatitude(), u.getLongitude());
          if (locName != null && !locName.isBlank()) {
            lastGeoName.put(u.getDriverId(), new LastGeo(u.getLatitude(), u.getLongitude(), locName));
          }
        } else {
          locName = (lg != null) ? lg.name() : null;
        }
      } catch (Exception e) {
        log.warn(
            "Reverse geocode failed lat={}, lng={}: {}",
            u.getLatitude(),
            u.getLongitude(),
            e.toString());
        locName = null;
      }
    }
    boolean isOnline = true;
    log.debug(
        " Accept driver={} lat={} lng={} speed={} battery={} src={} dispatchId={} locName={}",
        u.getDriverId(),
        u.getLatitude(),
        u.getLongitude(),
        u.getSpeed(),
        battery,
        src,
        u.getDispatchId(),
        locName);

    log.debug(
        "⬆️ Upserting latest for driver={} (online={}, lat={}, lng={})",
        u.getDriverId(),
        isOnline,
        u.getLatitude(),
        u.getLongitude());

    try {
      latestRepo.upsertLatest(
          u.getDriverId(),
          u.getLatitude(),
          u.getLongitude(),
          u.getSpeed(),
          u.getHeading(),
          u.getDispatchId(),
          battery,
          src,
          locName,
          isOnline,
          u.getAccuracyMeters(),
          u.getLocationSource(),
          u.getNetType(),
          appVersionCode);
      if (meterRegistry != null) {
        meterRegistry.counter("location.latest.upsert.success").increment();
      }
    } catch (Exception e) {
      if (meterRegistry != null) {
        meterRegistry.counter("location.latest.upsert.failure").increment();
      }
      throw e;
    }

    LocationHistory h = new LocationHistory();
    h.setDriver(em.getReference(Driver.class, u.getDriverId()));
    if (u.getDispatchId() != null) {
      h.setDispatch(em.getReference(Dispatch.class, u.getDispatchId()));
    }
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
    if (u.getPointId() != null && !u.getPointId().isBlank()) {
      h.setPointId(u.getPointId().trim());
    }
    h.setSeq(u.getSeq());
    if (u.getSessionId() != null && !u.getSessionId().isBlank()) {
      h.setSessionId(u.getSessionId().trim());
    }

    LocalDateTime eventLdt = Instant.ofEpochMilli(eventMillis).atZone(ZoneOffset.UTC).toLocalDateTime();
    h.setTimestamp(eventLdt);
    h.setEventTime(eventLdt);
    h.setIsOnline(true);

    enqueueHistory(h, u.getDriverId());
    if (log.isDebugEnabled()) {
      log.debug(" Buffered history: driver={} queueSize={}/{}", u.getDriverId(), buffer.size(), QUEUE_CAPACITY);
    }

    lastPoint.put(u.getDriverId(), new LastPoint(u.getLatitude(), u.getLongitude(), eventMillis));
    if (locName != null && !locName.isBlank()) {
      lastGeoName.put(u.getDriverId(), new LastGeo(u.getLatitude(), u.getLongitude(), locName));
    }

    DriverLatestLocation latest = latestRepo.findById(u.getDriverId()).orElse(null);

    Map<String, Object> live = new HashMap<>();
    live.put("driverId", u.getDriverId());
    live.put("clientTime", eventMillis);
    live.put("serverTime", now);
    live.put("isOnline", Boolean.TRUE);

    if (latest != null) {
      live.put("latitude", latest.getLatitude());
      live.put("longitude", latest.getLongitude());

      Long ls = toEpochMillis(latest.getLastSeen());
      live.put("lastSeen", ls != null ? ls : now);

      Double spMpsFromDb = latest.getSpeed();
      if (spMpsFromDb != null) {
        double speedMps = Math.max(0.0, spMpsFromDb);
        double speedKmh = speedMps * 3.6;
        live.put("speedMps", speedMps);
        live.put("speed", Math.round(speedKmh * 10.0) / 10.0);
      }
      live.put("heading", latest.getHeading());
      if (latest.getBatteryLevel() != null) live.put("batteryLevel", latest.getBatteryLevel());
      if (latest.getLocationName() != null) live.put("locationName", latest.getLocationName());
    } else {
      live.put("latitude", u.getLatitude());
      live.put("longitude", u.getLongitude());
      live.put("lastSeen", now);
      if (u.getSpeed() != null) {
        double speedMps = Math.max(0.0, u.getSpeed());
        double speedKmh = speedMps * 3.6;
        live.put("speedMps", speedMps);
        live.put("speed", Math.round(speedKmh * 10.0) / 10.0);
      }
      if (battery != null) live.put("batteryLevel", battery);
      if (locName != null) live.put("locationName", locName);
    }

    if (log.isDebugEnabled()) {
      log.debug(
          "Live snapshot built for driver={} lastSeen={} lat={} lng={} speedMps={}",
          u.getDriverId(),
          live.get("lastSeen"),
          live.get("latitude"),
          live.get("longitude"),
          live.get("speedMps"));
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
    if (!schedulingEnabled) {
      return;
    }

    if (buffer.isEmpty()) {
      return;
    }

    int drained;
    int total = 0;
    do {
      List<LocationHistory> batch = new ArrayList<>(BATCH_MAX_RECORDS);
      drained = buffer.drainTo(batch, BATCH_MAX_RECORDS);
      if (drained > 0) {
        total += persistBatch(batch);
      }
    } while (drained == BATCH_MAX_RECORDS);
    if (total > 0) {
      log.info("Flushed {} history point(s) to configured history stores", total);
    }
  }

  @Scheduled(fixedDelayString = "${location.history.spool.replay.interval-ms:10000}")
  public void replaySpool() {
    if (!schedulingEnabled || !spoolEnabled || spoolService == null || mongoService == null) {
      return;
    }
    int replayed = spoolService.replayToMongo(Math.max(1, spoolReplayBatchSize), mongoService);
    if (replayed > 0) {
      log.info("Replayed {} spooled location history record(s) to Mongo", replayed);
      if (meterRegistry != null) {
        meterRegistry.counter("location.history.spool.replay.success").increment(replayed);
      }
    }
  }

  @PreDestroy
  void flushBufferOnShutdown() {
    if (buffer == null || buffer.isEmpty()) {
      return;
    }
    List<LocationHistory> remaining = new ArrayList<>(buffer.size());
    int drained = buffer.drainTo(remaining);
    if (drained <= 0) {
      return;
    }
    log.warn("🔚 Shutdown flush: persisting {} queued location point(s)", drained);
    int saved = persistBatch(remaining);
    if (saved < drained) {
      log.error("❌ Shutdown flush could not persist all points. saved={} expected={}", saved, drained);
    }
  }

  @Transactional(transactionManager = "jpaTransactionManager")
  public Map<String, Object> markPresence(
      Long driverId,
      Integer battery,
      Boolean gpsEnabled,
      String device,
      Long clientTs,
      String reason) {
    if (driverId == null) {
      log.warn("💓 Presence ping ignored: null driverId (device={} reason={})", device, reason);
      return Map.of("ok", false, "reason", "driverId is null");
    }

    final long now = System.currentTimeMillis();
    final String src = (device != null && !device.isBlank()) ? device : "HEARTBEAT";
    log.debug(
        "💓 Presence ping: driver={} battery={} gpsEnabled={} device={} reason={}",
        driverId,
        battery,
        gpsEnabled,
        device,
        reason);

    int updated = 0;
    try {
      updated = latestRepo.updatePresenceIfExists(driverId, battery, src);
    } catch (Exception e) {
      log.error(" updatePresenceIfExists failed driver={}: {}", driverId, e.toString(), e);
    }

    if (updated == 0) {
      try {
        latestRepo.upsertPresence(driverId, battery, src);
      } catch (Exception e) {
        log.error(" upsertPresence failed driver={}: {}", driverId, e.toString(), e);
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
        if (latest.getBatteryLevel() != null) m.put("batteryLevel", latest.getBatteryLevel());
        if (latest.getLocationName() != null) m.put("locationName", latest.getLocationName());
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
    if (driverId == null) return null;
    try {
      return latestRepo
          .findById(driverId)
          .map(DriverLatestLocation::getLastSeen)
          .map(ts -> ts != null ? ts.getTime() : null)
          .orElse(null);
    } catch (Exception e) {
      log.warn("lastSeenEpochMs({}) failed: {}", driverId, e.toString());
      return null;
    }
  }

  public String presenceStatus(Long lastSeenEpochMs) {
    long now = System.currentTimeMillis();
    long age = (lastSeenEpochMs == null) ? Long.MAX_VALUE : Math.max(0L, now - lastSeenEpochMs);
    if (age <= PRESENCE_ONLINE_MS) return "online";
    if (age <= PRESENCE_IDLE_MS) return "idle";
    return "offline";
  }

  private record LastGeo(double lat, double lng, String name) {}

  public void sweepPresence() {
    if (!schedulingEnabled) {
      return;
    }
    long cutoffMs = System.currentTimeMillis() - PRESENCE_ONLINE_MS;
    java.sql.Timestamp cutoff = new java.sql.Timestamp(cutoffMs);
    try {
      int n = latestRepo.markOfflineIfLastSeenBefore(cutoff);
      if (n > 0) {
        log.info("🧹 Presence sweeper marked {} driver(s) offline (cutoff={}ms ago)", n, PRESENCE_ONLINE_MS);
      }
    } catch (Exception e) {
      log.warn("⚠️ Presence sweeper failed: {}", e.toString());
    }
  }

  private record LastPoint(double lat, double lng, long eventTs) {}

  private static boolean finite(Double x) {
    return x != null && !x.isNaN() && !x.isInfinite();
  }

  private static boolean isInvalidMapFix(Double latitude, Double longitude) {
    if (!finite(latitude) || !finite(longitude)) {
      return true;
    }
    return Math.abs(latitude) < 0.000001d && Math.abs(longitude) < 0.000001d;
  }

  private static double haversine(double lat1, double lon1, double lat2, double lon2) {
    final double R = 6_371_000.0;
    double dLat = Math.toRadians(lat2 - lat1);
    double dLon = Math.toRadians(lon2 - lon1);
    double a =
        Math.sin(dLat / 2) * Math.sin(dLat / 2)
            + Math.cos(Math.toRadians(lat1))
                * Math.cos(Math.toRadians(lat2))
                * Math.sin(dLon / 2)
                * Math.sin(dLon / 2);
    return 2 * R * Math.asin(Math.sqrt(a));
  }

  private static Long toEpochMillis(java.sql.Timestamp ts) {
    return ts != null ? ts.getTime() : null;
  }

  private void enqueueHistory(LocationHistory h, Long driverId) {
    if (buffer.offer(h)) {
      return;
    }

    log.warn(
        "Queue full for driver={} queueSize={}/{}. Persisting overflow point directly to fallback stores.",
        driverId,
        buffer.size(),
        QUEUE_CAPACITY);

    int saved = persistBatch(List.of(h));
    if (saved <= 0) {
      log.error("Unable to persist overflow location history for driver={}", driverId);
    }
  }

  @Transactional
  protected int persistBatch(List<LocationHistory> batch) {
    if (batch == null || batch.isEmpty()) {
      return 0;
    }

    if (mysqlHistoryWriteEnabled) {
      persistMysqlHistory(batch);
    }

    boolean mongoSaved = false;
    if (mongoService != null) {
      mongoSaved = mongoService.trySaveAll(batch);
      if (meterRegistry != null) {
        meterRegistry
            .counter(
                mongoSaved
                    ? "location.history.mongo.write.success"
                    : "location.history.mongo.write.failure")
            .increment(batch.size());
      }
    }

    if (!mongoSaved) {
      if (spoolEnabled && spoolService != null) {
        spoolService.appendBatch(batch);
      } else if (mongoService == null) {
        log.warn("Mongo history store unavailable and spool disabled. Dropping {} history records.", batch.size());
        if (meterRegistry != null) {
          meterRegistry.counter("location.history.dropped.records").increment(batch.size());
        }
      }
    }

    return batch.size();
  }

  private void persistMysqlHistory(List<LocationHistory> batch) {
    try {
      historyRepo.saveAll(batch);
    } catch (Exception e) {
      log.error(
          "MySQL history batch save failed for {} item(s): {}. Falling back to row-by-row.",
          batch.size(),
          e.toString(),
          e);
      for (LocationHistory h : batch) {
        try {
          historyRepo.save(h);
        } catch (Exception ex) {
          Long driverId = (h.getDriver() != null ? h.getDriver().getId() : null);
          log.error(
              "Failed MySQL history row save driverId={} lat={} lng={} ts={} : {}",
              driverId,
              h.getLatitude(),
              h.getLongitude(),
              h.getTimestamp(),
              ex.toString(),
              ex);
          if (meterRegistry != null) {
            meterRegistry.counter("location.history.mysql.write.failure").increment();
          }
        }
      }
    }
  }

  private void registerMetricsIfNeeded() {
    if (meterRegistry == null || !metricsInitialized.compareAndSet(false, true)) {
      return;
    }
    Gauge.builder("location.history.buffer.depth", buffer, BlockingQueue::size).register(meterRegistry);
    if (spoolService != null) {
      Gauge.builder("location.history.spool.bytes", spoolService, s -> (double) s.currentSpoolBytes())
          .register(meterRegistry);
      Gauge.builder(
              "location.history.spool.oldest.age.seconds",
              spoolService,
              s -> (double) s.oldestPendingAgeSeconds())
          .register(meterRegistry);
    }
  }

  public Map<String, Object> getHistoryPipelineHealth() {
    Map<String, Object> health = new HashMap<>();
    health.put("primaryHistoryStore", mongoEnabled ? "MONGO" : (mysqlHistoryWriteEnabled ? "MYSQL" : "NONE"));
    health.put("mongoEnabled", mongoEnabled);
    health.put("mysqlHistoryWriteEnabled", mysqlHistoryWriteEnabled);
    health.put("spoolEnabled", spoolEnabled && spoolService != null);
    health.put("inMemoryBufferDepth", buffer != null ? buffer.size() : 0);
    health.put("inMemoryBufferCapacity", QUEUE_CAPACITY);

    if (spoolService != null) {
      long spoolBytes = spoolService.currentSpoolBytes();
      long replayLagSeconds = spoolService.oldestPendingAgeSeconds();
      health.put("spoolBytes", spoolBytes);
      health.put("spoolReplayLagSeconds", replayLagSeconds);
      health.put("historyPipelineStatus", replayLagSeconds > 900 ? "DEGRADED" : "OK");
    } else {
      health.put("spoolBytes", 0L);
      health.put("spoolReplayLagSeconds", 0L);
      health.put("historyPipelineStatus", mongoEnabled ? "OK" : "DEGRADED");
    }

    return health;
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
}
