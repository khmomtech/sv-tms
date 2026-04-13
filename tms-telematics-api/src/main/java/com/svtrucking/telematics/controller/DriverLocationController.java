package com.svtrucking.telematics.controller;

import com.svtrucking.telematics.dto.PresenceHeartbeatDto;
import com.svtrucking.telematics.dto.SpoofingAlertDto;
import com.svtrucking.telematics.dto.requests.DriverLocationUpdateDto;
import com.svtrucking.telematics.dto.requests.TrackingSessionStartRequest;
import com.svtrucking.telematics.dto.responses.TrackingSessionResponse;
import com.svtrucking.telematics.security.TelematicsJwtUtil;
import com.svtrucking.telematics.service.DriverTrackingSessionService;
import com.svtrucking.telematics.service.LiveLocationCacheServiceInterface;
import com.svtrucking.telematics.service.LocationIngestService;
import com.svtrucking.telematics.service.PresencePolicyService;
import com.svtrucking.telematics.service.SpoofingAlertService;
import io.micrometer.core.instrument.Counter;
import io.micrometer.core.instrument.MeterRegistry;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.validation.Valid;
import java.util.HashMap;
import java.util.Map;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.messaging.handler.annotation.MessageMapping;
import org.springframework.messaging.handler.annotation.Payload;
import org.springframework.messaging.simp.SimpMessagingTemplate;
import org.springframework.messaging.simp.annotation.SendToUser;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.server.ResponseStatusException;

/**
 * GPS location ingest controller for tms-telematics-api.
 * Adapted from tms-backend DriverLocationController:
 * - spoofing alert TODO is now implemented via SpoofingAlertService
 * - driverId for startTrackingSession comes from the JWT claim
 */
@RestController
@Slf4j
public class DriverLocationController {
    private static final String DEPRECATION_SUNSET = "Tue, 30 Jun 2026 00:00:00 GMT";

    private final SimpMessagingTemplate messagingTemplate;
    private final LocationIngestService ingest;
    private final DriverTrackingSessionService trackingSessionService;
    private final TelematicsJwtUtil jwtUtil;
    private final SpoofingAlertService spoofingAlertService;
    private final LiveLocationCacheServiceInterface cacheService;
    private final PresencePolicyService presencePolicyService;
    private final Counter locationUnauthorizedCounter;
    private final Counter heartbeatUnauthorizedCounter;

    public DriverLocationController(
            SimpMessagingTemplate messagingTemplate,
            LocationIngestService ingest,
            DriverTrackingSessionService trackingSessionService,
            TelematicsJwtUtil jwtUtil,
            SpoofingAlertService spoofingAlertService,
            PresencePolicyService presencePolicyService,
            MeterRegistry meterRegistry,
            @Autowired(required = false) LiveLocationCacheServiceInterface cacheService) {
        this.messagingTemplate = messagingTemplate;
        this.ingest = ingest;
        this.trackingSessionService = trackingSessionService;
        this.jwtUtil = jwtUtil;
        this.spoofingAlertService = spoofingAlertService;
        this.presencePolicyService = presencePolicyService;
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

    // ==============================
    // STOMP: /app/location.update
    // ==============================
    @MessageMapping("/location.update")
    @SendToUser("/queue/location-status")
    public Map<String, Object> handleLocationUpdate(
            @Valid @Payload DriverLocationUpdateDto update) {
        Map<String, Object> ack = new HashMap<>();
        try {
            if (!validUpdate(update)) {
                ack.put("ok", false);
                ack.put("message", "Location update failed: missing or invalid lat/lng/driverId.");
                return ack;
            }
            if (update.getBatteryLevel() != null && update.getBatteryLevel() < 0) {
                update.setBatteryLevel(null);
            }
            final long nowMs = System.currentTimeMillis();
            LocationIngestService.IngestResult result = ingest.acceptDetailed(update);
            Map<String, Object> live = result.live();

            if (live == null) {
                refreshPresenceAndFanout(update, nowMs, result.dropReason());
                ack.put("ok", true);
                ack.put("dedup", true);
                ack.put("dropReason", result.dropReason());
                ack.put("driverId", update.getDriverId());
                ack.put("serverTime", nowMs);
                ack.put("message", "Location ignored (" + result.dropReason() + "). Presence refreshed.");
                return ack;
            }

            addPresenceFields(live, nowMs);
            fanoutLocation(update.getDriverId(), live);

            ack.put("ok", true);
            ack.put("driverId", update.getDriverId());
            ack.put("serverTime", nowMs);
            ack.put("message", "Location update processed.");
            return ack;

        } catch (Exception e) {
            log.error("Error processing STOMP location [driver={}]: {}",
                    update != null ? update.getDriverId() : null, e.getMessage(), e);
            ack.put("ok", false);
            ack.put("message", "Server error while processing location.");
            return ack;
        }
    }

    @MessageMapping("/ping")
    @SendToUser("/queue/location-status")
    public String ping() {
        return "pong";
    }

    // ==============================
    // REST: POST /api/driver/location
    // legacy alias: /api/driver/location/update
    // ==============================
    @PostMapping({ "/api/driver/location", "/api/driver/location/update" })
    public ResponseEntity<?> restLocationUpdate(
            HttpServletRequest request,
            @RequestHeader(value = "Authorization", required = false) String authorization,
            @Valid @RequestBody DriverLocationUpdateDto update) {
        try {
            String token = DriverTrackingSessionService.extractBearerToken(authorization);
            return withAliasHeaders(request, "/api/driver/location",
                    ResponseEntity.ok(processLocationUpdate(token, update)));

        } catch (ResponseStatusException e) {
            if (e.getStatusCode() == HttpStatus.UNAUTHORIZED)
                locationUnauthorizedCounter.increment();
            log.warn("Location update rejected [driver={}]: {}",
                    update != null ? update.getDriverId() : null, e.getReason());
            return withAliasHeaders(request, "/api/driver/location",
                    ResponseEntity.status(e.getStatusCode())
                            .body(Map.of("ok", false,
                                    "message", e.getReason() == null ? "Request rejected" : e.getReason())));
        } catch (Exception e) {
            log.error("Error processing REST location [driver={}]: {}",
                    update != null ? update.getDriverId() : null, e.getMessage(), e);
            return withAliasHeaders(request, "/api/driver/location",
                    ResponseEntity.internalServerError()
                            .body(Map.of("ok", false, "message", "Server error while processing location.")));
        }
    }

    @PostMapping({ "/api/driver/location/batch", "/api/driver/location/update/batch" })
    public ResponseEntity<Map<String, Object>> restLocationUpdateBatch(
            HttpServletRequest request,
            @RequestHeader(value = "Authorization", required = false) String authorization,
            @Valid @RequestBody java.util.List<DriverLocationUpdateDto> updates) {
        try {
            String token = DriverTrackingSessionService.extractBearerToken(authorization);
            int accepted = 0;
            int skipped = 0;

            if (updates != null) {
                for (DriverLocationUpdateDto update : updates) {
                    try {
                        Map<String, Object> ack = processLocationUpdate(token, update);
                        if (Boolean.TRUE.equals(ack.get("ok"))) {
                            accepted++;
                        } else {
                            skipped++;
                        }
                    } catch (ResponseStatusException perItem) {
                        if (perItem.getStatusCode() == HttpStatus.UNAUTHORIZED
                                || perItem.getStatusCode() == HttpStatus.FORBIDDEN) {
                            throw perItem;
                        }
                        skipped++;
                        log.warn("Skipped bad point for driver={} at clientTime={}: {}",
                                update != null ? update.getDriverId() : null,
                                update != null ? update.getClientTime() : null,
                                perItem.getReason());
                    } catch (Exception perItem) {
                        skipped++;
                        log.warn("Skipped bad point for driver={} at clientTime={}: {}",
                                update != null ? update.getDriverId() : null,
                                update != null ? update.getClientTime() : null,
                                perItem.getMessage());
                    }
                }
            }

            return withAliasHeaders(request, "/api/driver/location/batch",
                    ResponseEntity.ok(Map.of(
                            "ok", true,
                            "message", "Batch processed: " + accepted + " accepted, " + skipped + " skipped",
                            "accepted", accepted,
                            "skipped", skipped)));
        } catch (ResponseStatusException e) {
            if (e.getStatusCode() == HttpStatus.UNAUTHORIZED)
                locationUnauthorizedCounter.increment();
            return withAliasHeaders(request, "/api/driver/location/batch",
                    ResponseEntity.status(e.getStatusCode())
                            .body(Map.of("ok", false,
                                    "message", e.getReason() == null ? "Request rejected" : e.getReason())));
        } catch (Exception e) {
            log.error("Batch location update failed: {}", e.getMessage(), e);
            return withAliasHeaders(request, "/api/driver/location/batch",
                    ResponseEntity.internalServerError()
                            .body(Map.of("ok", false, "message", "Server error while processing batch updates.")));
        }
    }

    // ==============================
    // REST: POST /api/driver/presence/heartbeat
    // ==============================
    @PostMapping("/api/driver/presence/heartbeat")
    public ResponseEntity<?> presenceHeartbeat(
            @RequestHeader(value = "Authorization", required = false) String authorization,
            @Valid @RequestBody PresenceHeartbeatDto dto) {
        try {
            String token = DriverTrackingSessionService.extractBearerToken(authorization);
            trackingSessionService.validateLocationWriteOrThrow(token, dto.getDriverId(), null);

            final long nowMs = System.currentTimeMillis();
            final Long clientTs = dto.getTs() != null ? dto.getTs() : nowMs;

            Map<String, Object> extra = ingest.markPresence(
                    dto.getDriverId(), dto.getBattery(), dto.getGpsEnabled(),
                    dto.getDevice(), clientTs, dto.getReason());

            Long lastSeenMs = ingest.lastSeenEpochMs(dto.getDriverId());
            if (lastSeenMs == null)
                lastSeenMs = nowMs;

            Map<String, Object> presence = buildPresencePayload(
                    dto.getDriverId(), clientTs, dto.getBattery(),
                    dto.getGpsEnabled(), dto.getDevice(), dto.getReason(), lastSeenMs, nowMs);
            if (extra != null)
                presence.putAll(extra);

            fanoutPresence(dto.getDriverId(), presence);

            return ResponseEntity.ok(Map.of(
                    "status", "ok",
                    "message", "heartbeat accepted",
                    "serverTime", nowMs,
                    "presenceStatus", presence.get("presenceStatus")));

        } catch (ResponseStatusException e) {
            if (e.getStatusCode() == HttpStatus.UNAUTHORIZED)
                heartbeatUnauthorizedCounter.increment();
            return ResponseEntity.status(e.getStatusCode())
                    .body(Map.of("status", "error",
                            "message", e.getReason() == null ? "Request rejected" : e.getReason()));
        } catch (Exception e) {
            log.error("Error in presence heartbeat [driver={}]: {}",
                    ((PresenceHeartbeatDto) null) == null ? "?" : "", e.getMessage(), e);
            return ResponseEntity.internalServerError()
                    .body(Map.of("status", "error", "message", e.getMessage()));
        }
    }

    // ==============================
    // REST: GET /api/admin/drivers/{driverId}/presence
    // legacy alias: /api/admin/driver/{driverId}/presence
    // ==============================
    @GetMapping({ "/api/admin/drivers/{driverId}/presence", "/api/admin/driver/{driverId}/presence" })
    public ResponseEntity<Map<String, Object>> getPresence(
            HttpServletRequest request,
            @PathVariable Long driverId) {
        long now = System.currentTimeMillis();
        Long lastSeenBoxed = ingest.lastSeenEpochMs(driverId);
        long lastSeen = lastSeenBoxed != null ? lastSeenBoxed : 0L;
        PresencePolicyService.PresenceState status = presencePolicyService.resolve(lastSeen, now);
        return withAliasHeaders(request, "/api/admin/drivers/" + driverId + "/presence",
                ResponseEntity.ok(Map.of(
                        "driverId", driverId,
                        "lastSeen", lastSeen,
                        "serverTime", now,
                        "presenceStatus", status.name(),
                        "isOnline", status == PresencePolicyService.PresenceState.ONLINE)));
    }

    // ==============================
    // REST: POST /api/driver/logout
    // ==============================
    @PostMapping("/api/driver/logout")
    public ResponseEntity<?> driverLogout(@RequestParam Long driverId) {
        try {
            log.info("Driver {} logging out, evicting from cache", driverId);
            if (cacheService != null) {
                cacheService.removeDriverLocation(driverId);
            }
            long nowMs = System.currentTimeMillis();
            ingest.markPresence(driverId, null, null, "logout", nowMs, "logout");

            Map<String, Object> presence = buildPresencePayload(
                    driverId, nowMs, null, null, "logout", "logout", 0L, nowMs);
            presence.put("presenceStatus", PresencePolicyService.PresenceState.OFFLINE.name());
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

    // ==============================
    // REST: POST /api/driver/location/spoofing-alert
    // legacy alias: /api/locations/spoofing-alert
    // (Implements the TODO from tms-backend DriverLocationController:466-468)
    // ==============================
    @PostMapping({ "/api/driver/location/spoofing-alert", "/api/locations/spoofing-alert" })
    public ResponseEntity<Map<String, Object>> reportSpoofingAttempt(
            HttpServletRequest request,
            @Valid @RequestBody SpoofingAlertDto alert) {
        try {
            log.warn(
                    "GPS SPOOFING ALERT - Driver {}: {} at [{}, {}], isMocked={}, accuracy={}m, speed={}m/s",
                    alert.getDriverId(), alert.getReason(), alert.getLatitude(), alert.getLongitude(),
                    alert.getIsMocked(), alert.getAccuracy(), alert.getSpeed());

            spoofingAlertService.record(alert);

            return withAliasHeaders(request, "/api/driver/location/spoofing-alert",
                    ResponseEntity.ok(Map.of(
                            "status", "ok",
                            "message", "Spoofing alert received and persisted",
                            "driverId", alert.getDriverId(),
                            "serverTime", System.currentTimeMillis())));

        } catch (Exception e) {
            log.error("Error processing spoofing alert: {}", e.getMessage(), e);
            return withAliasHeaders(request, "/api/driver/location/spoofing-alert",
                    ResponseEntity.internalServerError()
                            .body(Map.of("status", "error", "message", "Failed to process alert")));
        }
    }

    // ==============================
    // REST: POST /api/driver/tracking/session/start
    // legacy alias: /api/driver/tracking-session/start
    // ==============================
    @PostMapping({ "/api/driver/tracking/session/start", "/api/driver/tracking-session/start" })
    public ResponseEntity<?> startTrackingSession(
            HttpServletRequest request,
            @RequestHeader(value = "Authorization", required = false) String authorization,
            @Valid @RequestBody TrackingSessionStartRequest req) {
        try {
            String token = DriverTrackingSessionService.extractBearerToken(authorization);
            if (token == null || !jwtUtil.isTokenValid(token)) {
                return withAliasHeaders(request, "/api/driver/tracking/session/start",
                        ResponseEntity.status(HttpStatus.UNAUTHORIZED)
                                .body(Map.of("ok", false, "message", "Valid Authorization token required")));
            }
            Long driverId = jwtUtil.extractDriverId(token);
            String username = jwtUtil.extractUsername(token);
            TrackingSessionResponse resp = trackingSessionService.startSession(driverId, username, req);
            return withAliasHeaders(request, "/api/driver/tracking/session/start", ResponseEntity.ok(resp));
        } catch (ResponseStatusException e) {
            return withAliasHeaders(request, "/api/driver/tracking/session/start",
                    ResponseEntity.status(e.getStatusCode())
                            .body(Map.of("ok", false,
                                    "message", e.getReason() == null ? "Error" : e.getReason())));
        } catch (Exception e) {
            log.error("Error starting tracking session: {}", e.getMessage(), e);
            return withAliasHeaders(request, "/api/driver/tracking/session/start",
                    ResponseEntity.internalServerError()
                            .body(Map.of("ok", false, "message", "Failed to start tracking session")));
        }
    }

    // ==============================
    // REST: POST /api/driver/tracking/session/refresh
    // legacy alias: /api/driver/tracking-session/refresh
    // ==============================
    @PostMapping({ "/api/driver/tracking/session/refresh", "/api/driver/tracking-session/refresh" })
    public ResponseEntity<?> refreshTrackingSession(
            HttpServletRequest request,
            @RequestHeader(value = "Authorization", required = false) String authorization) {
        try {
            String token = DriverTrackingSessionService.extractBearerToken(authorization);
            TrackingSessionResponse resp = trackingSessionService.refreshSession(token);
            return withAliasHeaders(request, "/api/driver/tracking/session/refresh", ResponseEntity.ok(resp));
        } catch (ResponseStatusException e) {
            return withAliasHeaders(request, "/api/driver/tracking/session/refresh",
                    ResponseEntity.status(e.getStatusCode())
                            .body(Map.of("ok", false,
                                    "message", e.getReason() == null ? "Error" : e.getReason())));
        } catch (Exception e) {
            log.error("Error refreshing tracking session: {}", e.getMessage(), e);
            return withAliasHeaders(request, "/api/driver/tracking/session/refresh",
                    ResponseEntity.internalServerError()
                            .body(Map.of("ok", false, "message", "Failed to refresh tracking session")));
        }
    }

    // ==============================
    // REST: POST /api/driver/tracking/session/stop
    // legacy alias: /api/driver/tracking-session/stop
    // ==============================
    @PostMapping({ "/api/driver/tracking/session/stop", "/api/driver/tracking-session/stop" })
    public ResponseEntity<?> stopTrackingSession(
            HttpServletRequest request,
            @RequestHeader(value = "Authorization", required = false) String authorization) {
        try {
            String token = DriverTrackingSessionService.extractBearerToken(authorization);
            trackingSessionService.stopSession(token);
            return withAliasHeaders(request, "/api/driver/tracking/session/stop",
                    ResponseEntity.ok(Map.of("status", "ok", "message", "Tracking session stopped")));
        } catch (ResponseStatusException e) {
            return withAliasHeaders(request, "/api/driver/tracking/session/stop",
                    ResponseEntity.status(e.getStatusCode())
                            .body(Map.of("ok", false,
                                    "message", e.getReason() == null ? "Error" : e.getReason())));
        } catch (Exception e) {
            log.error("Error stopping tracking session: {}", e.getMessage(), e);
            return withAliasHeaders(request, "/api/driver/tracking/session/stop",
                    ResponseEntity.internalServerError()
                            .body(Map.of("ok", false, "message", "Failed to stop tracking session")));
        }
    }

    // ── Private helpers ──────────────────────────────────────────────────────

    private boolean validUpdate(DriverLocationUpdateDto u) {
        return u != null && u.getDriverId() != null
                && u.getLatitude() != null && u.getLongitude() != null
                && !u.getLatitude().isNaN() && !u.getLongitude().isNaN()
                && !u.getLatitude().isInfinite() && !u.getLongitude().isInfinite();
    }

    private Map<String, Object> processLocationUpdate(String token, DriverLocationUpdateDto update) {
        Map<String, Object> ack = new HashMap<>();
        if (!validUpdate(update)) {
            ack.put("ok", false);
            ack.put("message", "Location update failed: missing or invalid lat/lng/driverId.");
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, (String) ack.get("message"));
        }

        trackingSessionService.validateLocationWriteOrThrow(
                token, update.getDriverId(), update.getSessionId());

        if (update.getBatteryLevel() != null && update.getBatteryLevel() < 0) {
            update.setBatteryLevel(null);
        }

        final long nowMs = System.currentTimeMillis();
        LocationIngestService.IngestResult result = ingest.acceptDetailed(update);
        Map<String, Object> live = result.live();

        if (live == null) {
            refreshPresenceAndFanout(update, nowMs, result.dropReason());
            ack.put("ok", true);
            ack.put("dedup", true);
            ack.put("dropReason", result.dropReason());
            ack.put("driverId", update.getDriverId());
            ack.put("serverTime", nowMs);
            ack.put("message", "Location ignored (" + result.dropReason() + "). Presence refreshed.");
            return ack;
        }

        addPresenceFields(live, nowMs);
        fanoutLocation(update.getDriverId(), live);

        ack.put("ok", true);
        ack.put("driverId", update.getDriverId());
        ack.put("serverTime", nowMs);
        ack.put("message", "Location update processed.");
        return ack;
    }

    private Map<String, Object> buildPresencePayload(
            Long driverId, Long clientTs, Integer battery, Boolean gps,
            String device, String reason, long lastSeenMs, long nowMs) {
        Map<String, Object> p = new HashMap<>();
        p.put("driverId", driverId);
        p.put("serverTime", nowMs);
        p.put("clientTime", clientTs != null ? clientTs : nowMs);
        p.put("lastSeen", lastSeenMs);
        PresencePolicyService.PresenceState status = presencePolicyService.resolve(lastSeenMs, nowMs);
        p.put("presenceStatus", status.name());
        p.put("isOnline", status == PresencePolicyService.PresenceState.ONLINE);
        if (battery != null)
            p.put("battery", battery);
        if (gps != null)
            p.put("gpsEnabled", gps);
        if (device != null)
            p.put("device", device);
        if (reason != null)
            p.put("reason", reason);
        return p;
    }

    private void refreshPresenceAndFanout(DriverLocationUpdateDto update, long nowMs, String reason) {
        ingest.markPresence(update.getDriverId(), update.getBatteryLevel(),
                update.getGpsOn(), update.getSource(),
                update.effectiveEpochMillisOr(nowMs), reason);
        Long lastSeenMs = ingest.lastSeenEpochMs(update.getDriverId());
        if (lastSeenMs == null)
            lastSeenMs = nowMs;
        Map<String, Object> presence = buildPresencePayload(
                update.getDriverId(), update.effectiveEpochMillisOr(nowMs),
                update.getBatteryLevel(), update.getGpsOn(), update.getSource(),
                reason, lastSeenMs, nowMs);
        fanoutPresence(update.getDriverId(), presence);
    }

    private void addPresenceFields(Map<String, Object> live, long nowMs) {
        live.putIfAbsent("serverTime", nowMs);
        live.putIfAbsent("clientTime", nowMs);
        live.put("lastSeen", nowMs);
        PresencePolicyService.PresenceState status = presencePolicyService.resolve(nowMs, nowMs);
        live.put("presenceStatus", status.name());
        live.put("isOnline", status == PresencePolicyService.PresenceState.ONLINE);
    }

    private void fanoutPresence(Long driverId, Map<String, Object> payload) {
        messagingTemplate.convertAndSend(T_PRES_ONE + driverId, payload);
        messagingTemplate.convertAndSend(T_PRES_ALL, payload);
    }

    private void fanoutLocation(Long driverId, Map<String, Object> live) {
        messagingTemplate.convertAndSend(T_LOC_ONE + driverId, live);
        messagingTemplate.convertAndSend(T_LOC_ALL, live);
    }

    private <T> ResponseEntity<T> withAliasHeaders(
            HttpServletRequest request,
            String canonicalPath,
            ResponseEntity<T> response) {
        if (request == null || canonicalPath.equals(request.getRequestURI())) {
            return response;
        }
        HttpHeaders headers = new HttpHeaders();
        headers.putAll(response.getHeaders());
        headers.set("Deprecation", "true");
        headers.set("Sunset", DEPRECATION_SUNSET);
        headers.add(HttpHeaders.LINK, "<" + canonicalPath + ">; rel=\"successor-version\"");
        return ResponseEntity.status(response.getStatusCode()).headers(headers).body(response.getBody());
    }
}
