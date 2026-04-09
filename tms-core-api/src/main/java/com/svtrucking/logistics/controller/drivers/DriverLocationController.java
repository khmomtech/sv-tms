package com.svtrucking.logistics.controller.drivers;

import com.svtrucking.logistics.dto.PresenceHeartbeatDto;
import com.svtrucking.logistics.dto.SpoofingAlertDto;
import com.svtrucking.logistics.dto.requests.DriverLocationUpdateDto;
import com.svtrucking.logistics.service.DriverTrackingSessionService;
import com.svtrucking.logistics.service.LocationIngestService;
import com.svtrucking.logistics.service.LiveLocationCacheServiceInterface;
import com.svtrucking.logistics.service.TelematicsProxyService;
import io.micrometer.core.instrument.Counter;
import io.micrometer.core.instrument.MeterRegistry;
import jakarta.validation.Valid;
import java.util.HashMap;
import java.util.Map;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.messaging.handler.annotation.MessageMapping;
import org.springframework.messaging.handler.annotation.Payload;
import org.springframework.messaging.simp.SimpMessagingTemplate;
import org.springframework.messaging.simp.annotation.SendToUser;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestHeader;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.server.ResponseStatusException;

@RestController
@Slf4j
public class DriverLocationController {

  private final SimpMessagingTemplate messagingTemplate;
  private final LocationIngestService ingest;
  private final DriverTrackingSessionService trackingSessionService;
  private final LiveLocationCacheServiceInterface cacheService;
  private final TelematicsProxyService telematicsProxy;
  private final Counter locationUnauthorizedCounter;
  private final Counter heartbeatUnauthorizedCounter;

  public DriverLocationController(
      SimpMessagingTemplate messagingTemplate,
      LocationIngestService ingest,
      DriverTrackingSessionService trackingSessionService,
      TelematicsProxyService telematicsProxy,
      MeterRegistry meterRegistry,
      @org.springframework.beans.factory.annotation.Autowired(required = false) LiveLocationCacheServiceInterface cacheService) {
    this.messagingTemplate = messagingTemplate;
    this.ingest = ingest;
    this.trackingSessionService = trackingSessionService;
    this.telematicsProxy = telematicsProxy;
    this.cacheService = cacheService;
    this.locationUnauthorizedCounter = Counter.builder("tracking.location.unauthorized.count")
        .description("Unauthorized responses for /api/driver/location/update")
        .register(meterRegistry);
    this.heartbeatUnauthorizedCounter = Counter.builder("tracking.heartbeat.unauthorized.count")
        .description("Unauthorized responses for /api/driver/presence/heartbeat")
        .register(meterRegistry);
  }

  // Topics
  private static final String T_LOC_ONE = "/topic/driver-location/";
  private static final String T_LOC_ALL = "/topic/driver-location/all";
  private static final String T_PRES_ONE = "/topic/driver-presence/";
  private static final String T_PRES_ALL = "/topic/driver-presence/all";

  // Presence thresholds
  private static final long ONLINE_MS = 35_000L;
  private static final long IDLE_MS = 180_000L;

  private enum Presence {
    ONLINE,
    IDLE,
    OFFLINE
  }

  private static Presence computePresence(long lastSeenMs, long nowMs) {
    long dt = Math.max(0, nowMs - lastSeenMs);
    if (dt <= ONLINE_MS)
      return Presence.ONLINE;
    if (dt <= IDLE_MS)
      return Presence.IDLE;
    return Presence.OFFLINE;
  }

  private static void putIfNotNull(Map<String, Object> m, String k, Object v) {
    if (v != null)
      m.put(k, v);
  }

  private Map<String, Object> buildPresencePayload(
      Long driverId,
      Long clientTs,
      Integer battery,
      Boolean gps,
      String device,
      String reason,
      long lastSeenMs,
      long nowMs) {
    Map<String, Object> p = new HashMap<>();
    p.put("driverId", driverId);
    p.put("serverTime", nowMs);
    p.put("clientTime", clientTs != null ? clientTs : nowMs);
    p.put("lastSeen", lastSeenMs);

    Presence status = computePresence(lastSeenMs, nowMs);
    p.put("presenceStatus", status.name());
    p.put("isOnline", status == Presence.ONLINE);

    putIfNotNull(p, "battery", battery);
    putIfNotNull(p, "gpsEnabled", gps);
    putIfNotNull(p, "device", device);
    putIfNotNull(p, "reason", reason);
    return p;
  }

  private void fanoutPresence(Long driverId, Map<String, Object> payload) {
    messagingTemplate.convertAndSend(T_PRES_ONE + driverId, payload);
    messagingTemplate.convertAndSend(T_PRES_ALL, payload);
    // Optional legacy mirrors (deprecated: avoid publishing presence into location
    // topic)
    // messagingTemplate.convertAndSend(T_LOC_ONE + driverId, payload);
    // messagingTemplate.convertAndSend(T_LOC_ALL, payload);
  }

  private void fanoutLocation(Long driverId, Map<String, Object> live) {
    messagingTemplate.convertAndSend(T_LOC_ONE + driverId, live);
    messagingTemplate.convertAndSend(T_LOC_ALL, live);
  }

  // ==============================
  // STOMP: Location update
  // ==============================
  @MessageMapping("/location.update")
  @SendToUser("/queue/location-status")
  public Map<String, Object> handleLocationUpdate(@Valid @Payload DriverLocationUpdateDto update) {
    Map<String, Object> ack = new HashMap<>();
    try {
      if (update == null
          || update.getDriverId() == null
          || update.getLatitude() == null
          || update.getLongitude() == null
          || update.getLatitude().isNaN()
          || update.getLongitude().isNaN()
          || update.getLatitude().isInfinite()
          || update.getLongitude().isInfinite()) {

        ack.put("ok", false);
        ack.put("message", "Location update failed: missing or invalid lat/lng/driverId.");
        return ack;
      }

      // Normalize battery: clients often send -1 initially
      if (update.getBatteryLevel() != null && update.getBatteryLevel() < 0) {
        update.setBatteryLevel(null);
      }

      final long nowMs = System.currentTimeMillis();
      Map<String, Object> live = ingest.accept(update); // may return null (throttled/dedup)

      if (live == null) {
        // Keep presence warm if we skipped location write
        ingest.markPresence(
            update.getDriverId(),
            update.getBatteryLevel(),
            update.getGpsOn(),
            update.getSource(),
            update.effectiveEpochMillisOr(nowMs),
            "dup/throttle");

        Long lastSeenMs = ingest.lastSeenEpochMs(update.getDriverId());
        if (lastSeenMs == null)
          lastSeenMs = nowMs;

        Map<String, Object> presence = buildPresencePayload(
            update.getDriverId(),
            update.effectiveEpochMillisOr(nowMs),
            update.getBatteryLevel(),
            update.getGpsOn(),
            update.getSource(),
            "dup/throttle",
            lastSeenMs,
            nowMs);
        fanoutPresence(update.getDriverId(), presence);
        // Renew 45s presence key (dedup/throttle ping still counts as "online")
        if (cacheService != null) {
          cacheService.markDriverOnline(update.getDriverId());
        }

        ack.put("ok", true);
        ack.put("dedup", true);
        ack.put("driverId", update.getDriverId());
        ack.put("serverTime", nowMs);
        ack.put("message", "Location ignored (duplicate/too soon). Presence refreshed.");
        return ack;
      }

      // Enrich + broadcast full live location packet
      live.putIfAbsent("serverTime", nowMs);
      live.putIfAbsent("clientTime", update.effectiveEpochMillisOr(nowMs));
      // We just accepted a fresh location → lastSeen is effectively now
      live.put("lastSeen", nowMs);
      Presence status = computePresence(nowMs, nowMs);
      live.put("presenceStatus", status.name());
      live.put("isOnline", status == Presence.ONLINE);

      fanoutLocation(update.getDriverId(), live);
      // Renew 45s presence key on accepted fresh location ping
      if (cacheService != null) {
        cacheService.markDriverOnline(update.getDriverId());
      }

      ack.put("ok", true);
      ack.put("driverId", update.getDriverId());
      ack.put("serverTime", nowMs);
      ack.put("message", "Location update processed.");
      return ack;

    } catch (Exception e) {
      log.error(
          " Error processing location [driver={}]: {}",
          update != null ? update.getDriverId() : null,
          e.getMessage(),
          e);
      ack.put("ok", false);
      ack.put("message", "Server error while processing location.");
      return ack;
    }
  }

  /** Optional utility: STOMP ping/pong */
  @MessageMapping("/ping")
  @SendToUser("/queue/location-status")
  public String ping() {
    return "pong";
  }

  // ==============================
  // REST: Location update (mirror of STOMP handler)
  // ==============================
  @PostMapping("/api/driver/location/update")
  public ResponseEntity<?> restLocationUpdate(
      @RequestHeader(value = "Authorization", required = false) String authorization,
      @Valid @RequestBody DriverLocationUpdateDto update) {
    Map<String, Object> ack = new HashMap<>();
    try {
      if (update == null
          || update.getDriverId() == null
          || update.getLatitude() == null
          || update.getLongitude() == null
          || update.getLatitude().isNaN()
          || update.getLongitude().isNaN()
          || update.getLatitude().isInfinite()
          || update.getLongitude().isInfinite()) {

        ack.put("ok", false);
        ack.put("message", "Location update failed: missing or invalid lat/lng/driverId.");
        return ResponseEntity.badRequest().body(ack);
      }

      // When telematics service is configured, proxy the request and return its
      // response.
      if (telematicsProxy.isForwardingEnabled()) {
        return (ResponseEntity<?>) telematicsProxy.forward(
            "/api/driver/location/update", authorization, update);
      }

      String token = DriverTrackingSessionService.extractBearerToken(authorization);
      trackingSessionService.validateLocationWriteOrThrow(
          token, update.getDriverId(), update.getSessionId());

      // Normalize battery: clients often send -1 initially
      if (update.getBatteryLevel() != null && update.getBatteryLevel() < 0) {
        update.setBatteryLevel(null);
      }

      final long nowMs = System.currentTimeMillis();
      Map<String, Object> live = ingest.accept(update); // may return null (throttled/dedup)

      if (live == null) {
        // Keep presence warm if we skipped location write
        ingest.markPresence(
            update.getDriverId(),
            update.getBatteryLevel(),
            update.getGpsOn(),
            update.getSource(),
            update.effectiveEpochMillisOr(nowMs),
            "dup/throttle");

        Long lastSeenMs = ingest.lastSeenEpochMs(update.getDriverId());
        if (lastSeenMs == null)
          lastSeenMs = nowMs;

        Map<String, Object> presence = buildPresencePayload(
            update.getDriverId(),
            update.effectiveEpochMillisOr(nowMs),
            update.getBatteryLevel(),
            update.getGpsOn(),
            update.getSource(),
            "dup/throttle",
            lastSeenMs,
            nowMs);
        fanoutPresence(update.getDriverId(), presence);
        // Renew 45s presence key (dedup/throttle ping still counts as "online")
        if (cacheService != null) {
          cacheService.markDriverOnline(update.getDriverId());
        }

        ack.put("ok", true);
        ack.put("dedup", true);
        ack.put("driverId", update.getDriverId());
        ack.put("serverTime", nowMs);
        ack.put("message", "Location ignored (duplicate/too soon). Presence refreshed.");
        return ResponseEntity.ok(ack);
      }

      // Enrich + broadcast full live location packet
      live.putIfAbsent("serverTime", nowMs);
      live.putIfAbsent("clientTime", update.effectiveEpochMillisOr(nowMs));
      // We just accepted a fresh location → lastSeen is effectively now
      live.put("lastSeen", nowMs);
      Presence status = computePresence(nowMs, nowMs);
      live.put("presenceStatus", status.name());
      live.put("isOnline", status == Presence.ONLINE);

      fanoutLocation(update.getDriverId(), live);
      // Renew 45s presence key on accepted fresh location ping
      if (cacheService != null) {
        cacheService.markDriverOnline(update.getDriverId());
      }

      ack.put("ok", true);
      ack.put("driverId", update.getDriverId());
      ack.put("serverTime", nowMs);
      ack.put("message", "Location update processed.");
      return ResponseEntity.ok(ack);

    } catch (ResponseStatusException e) {
      if (e.getStatusCode() == HttpStatus.UNAUTHORIZED) {
        locationUnauthorizedCounter.increment();
      }
      log.warn(
          " Location update rejected [driver={}]: {}",
          update != null ? update.getDriverId() : null,
          e.getReason());
      return ResponseEntity.status(e.getStatusCode())
          .body(Map.of("ok", false, "message", e.getReason() == null ? "Request rejected" : e.getReason()));
    } catch (Exception e) {
      log.error(
          " Error processing REST location [driver={}]: {}",
          update != null ? update.getDriverId() : null,
          e.getMessage(),
          e);
      return ResponseEntity.internalServerError()
          .body(Map.of("ok", false, "message", "Server error while processing location."));
    }
  }

  // ==============================
  // REST: Presence heartbeat
  // ==============================
  @PostMapping("/api/driver/presence/heartbeat")
  public ResponseEntity<?> presenceHeartbeat(
      @RequestHeader(value = "Authorization", required = false) String authorization,
      @Valid @RequestBody PresenceHeartbeatDto dto) {
    try {
      // When telematics service is configured, proxy the request and return its
      // response.
      if (telematicsProxy.isForwardingEnabled()) {
        return (ResponseEntity<?>) telematicsProxy.forward(
            "/api/driver/presence/heartbeat", authorization, dto);
      }

      String token = DriverTrackingSessionService.extractBearerToken(authorization);
      trackingSessionService.validateLocationWriteOrThrow(token, dto.getDriverId(), null);

      final long nowMs = System.currentTimeMillis();
      final Long clientTs = dto.getTs() != null ? dto.getTs() : nowMs;

      Map<String, Object> extra = ingest.markPresence(
          dto.getDriverId(),
          dto.getBattery(),
          dto.getGpsEnabled(),
          dto.getDevice(),
          clientTs,
          dto.getReason());

      Long lastSeenMs = ingest.lastSeenEpochMs(dto.getDriverId());
      if (lastSeenMs == null)
        lastSeenMs = nowMs;

      Map<String, Object> presence = buildPresencePayload(
          dto.getDriverId(),
          clientTs,
          dto.getBattery(),
          dto.getGpsEnabled(),
          dto.getDevice(),
          dto.getReason(),
          lastSeenMs,
          nowMs);
      if (extra != null)
        presence.putAll(extra);

      fanoutPresence(dto.getDriverId(), presence);
      // Renew 45s presence key on heartbeat
      if (cacheService != null) {
        cacheService.markDriverOnline(dto.getDriverId());
      }

      return ResponseEntity.ok(
          Map.of(
              "status",
              "ok",
              "message",
              "heartbeat accepted",
              "serverTime",
              nowMs,
              "presenceStatus",
              presence.get("presenceStatus")));
    } catch (ResponseStatusException e) {
      if (e.getStatusCode() == HttpStatus.UNAUTHORIZED) {
        heartbeatUnauthorizedCounter.increment();
      }
      return ResponseEntity.status(e.getStatusCode())
          .body(
              Map.of(
                  "status", "error",
                  "message", e.getReason() == null ? "Request rejected" : e.getReason()));
    } catch (Exception e) {
      log.error(
          " Error in presence heartbeat [driver={}]: {}", dto.getDriverId(), e.getMessage(), e);
      return ResponseEntity.internalServerError()
          .body(Map.of("status", "error", "message", e.getMessage()));
    }
  }

  /** Admin/helper endpoint: quick presence snapshot */
  @GetMapping("/api/admin/driver/{driverId}/presence")
  public Map<String, Object> getPresence(@PathVariable Long driverId) {
    long now = System.currentTimeMillis();
    Long lastSeenBoxed = ingest.lastSeenEpochMs(driverId);
    long lastSeen = lastSeenBoxed != null ? lastSeenBoxed : 0L;
    Presence status = computePresence(lastSeen, now);
    return Map.of(
        "driverId", driverId,
        "lastSeen", lastSeen,
        "serverTime", now,
        "presenceStatus", status.name(),
        "isOnline", status == Presence.ONLINE);
  }

  // ==============================
  // REST: Driver logout/disconnect (cache cleanup)
  // ==============================
  @PostMapping("/api/driver/logout")
  public ResponseEntity<?> driverLogout(
      @RequestHeader(value = "Authorization", required = false) String authorization,
      @RequestParam Long driverId) {
    try {
      if (telematicsProxy.isForwardingEnabled()) {
        return (ResponseEntity<?>) telematicsProxy.forward(
            "/api/driver/logout?driverId=" + driverId, authorization, java.util.Map.of());
      }

      log.info("Driver {} logging out, evicting from cache", driverId);

      // Evict driver from cache
      if (cacheService != null) {
        cacheService.evictDriverLocation(driverId);
      }

      // Mark as offline in presence system
      ingest.markPresence(driverId, null, null, "logout", System.currentTimeMillis(), "logout");

      // Broadcast offline presence
      long nowMs = System.currentTimeMillis();
      Map<String, Object> presence = buildPresencePayload(
          driverId, nowMs, null, null, "logout", "logout", 0L, nowMs);
      presence.put("presenceStatus", Presence.OFFLINE.name());
      presence.put("isOnline", false);
      fanoutPresence(driverId, presence);

      return ResponseEntity.ok(Map.of(
          "status", "ok",
          "message", "Driver logged out successfully",
          "driverId", driverId,
          "serverTime", nowMs));
    } catch (Exception e) {
      log.error("Error during driver logout [driver={}]: {}", driverId, e.getMessage(), e);
      return ResponseEntity.internalServerError()
          .body(Map.of("status", "error", "message", "Failed to logout driver"));
    }
  }

  /**
   * Endpoint to receive GPS spoofing alerts from mobile apps
   * Logs suspicious location activity for investigation
   */
  @PostMapping("/api/locations/spoofing-alert")
  @PreAuthorize("hasAuthority('driver:location:update')")
  public ResponseEntity<Map<String, Object>> reportSpoofingAttempt(
      @RequestHeader(value = "Authorization", required = false) String authorization,
      @Valid @RequestBody SpoofingAlertDto alert) {
    try {
      // When telematics service is configured, proxy the request and return its
      // response.
      if (telematicsProxy.isForwardingEnabled()) {
        return (ResponseEntity<Map<String, Object>>) (ResponseEntity<?>) telematicsProxy.forward(
            "/api/locations/spoofing-alert", authorization, alert);
      }

      log.warn("GPS SPOOFING ALERT - Driver {}: {} at [{}, {}], isMocked={}, accuracy={}m, speed={}m/s",
          alert.getDriverId(),
          alert.getReason(),
          alert.getLatitude(),
          alert.getLongitude(),
          alert.getIsMocked(),
          alert.getAccuracy(),
          alert.getSpeed());

      // TODO: Store in database for investigation
      // TODO: Send notification to admin
      // TODO: Auto-suspend driver account if repeated attempts (>5 in 1 hour)

      return ResponseEntity.ok(Map.of(
          "status", "ok",
          "message", "Spoofing alert received and logged",
          "driverId", alert.getDriverId(),
          "serverTime", System.currentTimeMillis()));
    } catch (Exception e) {
      log.error("Error processing spoofing alert: {}", e.getMessage(), e);
      return ResponseEntity.internalServerError()
          .body(Map.of("status", "error", "message", "Failed to process alert"));
    }
  }
}
