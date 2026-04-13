package com.svtrucking.logistics.service;

import com.svtrucking.logistics.dto.LiveDriverDto;
import com.svtrucking.logistics.model.DriverLatestLocation;
import com.svtrucking.logistics.repository.DriverLatestLocationRepository;
import io.micrometer.core.instrument.Counter;
import io.micrometer.core.instrument.MeterRegistry;
import java.sql.Timestamp;
import java.time.Instant;
import java.time.temporal.ChronoUnit;
import java.util.ArrayList;
import java.util.Collections;
import java.util.List;
import java.util.Optional;
import java.util.Set;
import java.util.UUID;
import java.util.stream.Collectors;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;

@Service
@Slf4j
public class LiveDriverQueryService {
  private static final String GEOCODE_RESOLVED = "resolved";
  private static final String GEOCODE_PENDING = "pending";
  private static final String GEOCODE_FAILED = "failed";
  private static final String UNKNOWN_LOCATION = "Unknown location";

  private final DriverLatestLocationRepository latestRepo;
  private final ActiveVehicleAssignmentReadService assignmentReadService;
  private final DriverDirectoryReadService driverDirectoryReadService;
  private final Counter liveFallbackCounter;
  private final Counter staleMarkedCounter;

  @org.springframework.beans.factory.annotation.Value("${spring.task.scheduling.enabled:true}")
  private boolean schedulingEnabled;

  public LiveDriverQueryService(
      DriverLatestLocationRepository latestRepo,
      ActiveVehicleAssignmentReadService assignmentReadService,
      DriverDirectoryReadService driverDirectoryReadService,
      MeterRegistry meterRegistry) {
    this.latestRepo = latestRepo;
    this.assignmentReadService = assignmentReadService;
    this.driverDirectoryReadService = driverDirectoryReadService;
    this.liveFallbackCounter =
        Counter.builder("tracking.live.fallback.count")
            .description("Count of live query fallback executions from since-query to in-memory freshness")
            .register(meterRegistry);
    this.staleMarkedCounter =
        Counter.builder("tracking.stale.marked_offline.count")
            .description("Count of drivers marked offline by stale sweeper")
            .register(meterRegistry);
  }

  public List<LiveDriverDto> getLiveDrivers(
      Boolean onlyOnline,
      Integer onlineSeconds,
      Double south,
      Double west,
      Double north,
      Double east) {

    final String requestId = UUID.randomUUID().toString().substring(0, 8);
    final long t0 = System.nanoTime();

    final boolean wantOnline =
        Boolean.TRUE.equals(onlyOnline) || (onlineSeconds != null && onlineSeconds > 0);
    final int windowSec = (onlineSeconds != null && onlineSeconds > 0) ? onlineSeconds : 120;
    final Timestamp since =
        wantOnline ? Timestamp.from(Instant.now().minus(windowSec, ChronoUnit.SECONDS)) : null;

    final boolean hasFullBbox = south != null && west != null && north != null && east != null;

    log.debug(
        "[live:{}] getLiveDrivers start onlyOnline={} onlineSeconds={} -> wantOnline={} windowSec={} hasFullBbox={} bbox=[S:{}, W:{}, N:{}, E:{}]",
        requestId,
        onlyOnline,
        onlineSeconds,
        wantOnline,
        windowSec,
        hasFullBbox,
        south,
        west,
        north,
        east);

    List<DriverLatestLocation> rows;
    long qStart = System.nanoTime();

    if (wantOnline) {
      if (hasFullBbox) {
        log.debug("[live:{}] Query path: findSinceWithinBbox(since={}, bbox)", requestId, since);
        rows = latestRepo.findSinceWithinBbox(since, south, west, north, east);
      } else {
        log.debug("[live:{}] Query path: findSince(since={})", requestId, since);
        rows = latestRepo.findSince(since);
      }

      if (rows.isEmpty()) {
        log.warn(
            "[live:{}] Online-window query returned 0 rows; applying Java-side freshness fallback (windowSec={})",
            requestId,
            windowSec);
        liveFallbackCounter.increment();
        List<DriverLatestLocation> fallbackRows = latestRepo.findAllLive();
        final Instant cutoff = Instant.now().minus(windowSec, ChronoUnit.SECONDS);
        rows =
            fallbackRows.stream()
                .filter(r -> r.getLastSeen() != null && r.getLastSeen().toInstant().isAfter(cutoff))
                .filter(
                    r ->
                        !hasFullBbox
                            || (r.getLatitude() >= south
                                && r.getLatitude() <= north
                                && r.getLongitude() >= west
                                && r.getLongitude() <= east))
                .collect(Collectors.toList());
        log.debug(
            "[live:{}] Fallback freshness produced {} rows from {} latest rows",
            requestId,
            rows.size(),
            fallbackRows.size());
      }
    } else {
      log.debug("[live:{}] Query path: findAllLive()", requestId);
      rows = latestRepo.findAllLive();

      if (hasFullBbox) {
        final int before = rows.size();
        rows =
            rows.stream()
                .filter(l -> l.getLatitude() != 0 && l.getLongitude() != 0)
                .filter(l -> l.getLatitude() >= south && l.getLatitude() <= north)
                .filter(l -> l.getLongitude() >= west && l.getLongitude() <= east)
                .collect(Collectors.toList());
        log.debug("[live:{}] In-memory bbox filter applied: {} -> {} rows", requestId, before, rows.size());
      }
    }

    final int beforeCoordinateFilter = rows.size();
    rows =
        rows.stream()
            .filter(r -> hasRenderableCoordinates(r.getLatitude(), r.getLongitude()))
            .collect(Collectors.toList());
    if (rows.size() != beforeCoordinateFilter) {
      log.info(
          "[live:{}] Filtered {} row(s) with invalid coordinates before DTO build",
          requestId,
          beforeCoordinateFilter - rows.size());
    }

    long qMs = (System.nanoTime() - qStart) / 1_000_000;
    log.debug("[live:{}] Repo query done in {} ms, rows={}", requestId, qMs, rows.size());

    if (rows.isEmpty()) {
      long totalMs = (System.nanoTime() - t0) / 1_000_000;
      log.debug("[live:{}] No rows. Returning empty list. totalMs={}", requestId, totalMs);
      return Collections.emptyList();
    }

    Set<Long> driverIds =
        rows.stream().map(DriverLatestLocation::getDriverId).collect(Collectors.toSet());
    log.debug("[live:{}] Distinct driverIds={}", requestId, driverIds.size());

    java.util.Map<Long, ActiveVehicleAssignmentReadService.ActiveVehicleAssignmentRow> activeByDriver =
        assignmentReadService.findActiveByDriverIds(driverIds);
    log.debug("[live:{}] Active assignments fetched: {}", requestId, activeByDriver.size());

    long enrichStart = System.nanoTime();
    var drivers = driverDirectoryReadService.findByIds(driverIds);
    long enrichMs = (System.nanoTime() - enrichStart) / 1_000_000;
    log.debug(
        "[live:{}] Driver enrichment loaded in {} ms (drivers={})",
        requestId,
        enrichMs,
        drivers.size());

    List<LiveDriverDto> out = new ArrayList<>(rows.size());
    int onlineCount = 0;

    for (var r : rows) {
      var d = drivers.get(r.getDriverId());
      var asg = activeByDriver.get(r.getDriverId());
      Instant updatedAt = r.getLastSeen() != null ? r.getLastSeen().toInstant() : null;
      long nowMs = System.currentTimeMillis();
      Long lastSeenEpochMs = updatedAt != null ? updatedAt.toEpochMilli() : null;
      Long lastSeenSeconds =
          lastSeenEpochMs != null ? Math.max(0L, (nowMs - lastSeenEpochMs) / 1000L) : null;

      boolean onlineFlag;
      if (wantOnline) {
        onlineFlag =
            Boolean.TRUE.equals(r.getIsOnline())
                || (r.getLastSeen() != null && (since == null || r.getLastSeen().after(since)));
      } else {
        onlineFlag = Boolean.TRUE.equals(r.getIsOnline());
      }
      if (onlineFlag) onlineCount++;

      out.add(
          LiveDriverDto.builder()
              .driverId(r.getDriverId())
              .driverName(d != null ? d.fullName() : null)
              .driverPhone(d != null ? d.phone() : null)
              .latitude(r.getLatitude())
              .longitude(r.getLongitude())
              .speed(r.getSpeed())
              .heading(r.getHeading())
              .batteryLevel(r.getBatteryLevel())
              .locationName(normalizeLocationName(r.getLocationName()))
              .geocodeStatus(
                  deriveGeocodeStatus(normalizeLocationName(r.getLocationName()), onlineFlag))
              .online(onlineFlag)
              .dispatchId(asg != null ? asg.assignmentId() : r.getDispatchId())
              .vehiclePlate(asg != null ? asg.vehiclePlate() : null)
              .updatedAt(updatedAt)
              .lastSeenEpochMs(lastSeenEpochMs)
              .lastSeenSeconds(lastSeenSeconds)
              .ingestLagSeconds(lastSeenSeconds)
              .source(r.getSource())
              .build());
    }

    long totalMs = (System.nanoTime() - t0) / 1_000_000;
    log.debug(
        "[live:{}] Built {} DTOs (online={}) in {} ms total (query={} ms, enrich={} ms)",
        requestId,
        out.size(),
        onlineCount,
        totalMs,
        qMs,
        enrichMs);

    return out;
  }

  public Optional<LiveDriverDto> getLatestForDriver(Long driverId) {
    final String requestId = "latest:" + driverId + ":" + UUID.randomUUID().toString().substring(0, 6);
    long t0 = System.nanoTime();
    log.debug("[{}] getLatestForDriver start driverId={}", requestId, driverId);

    var opt = latestRepo.findById(driverId);
    if (opt.isEmpty()) {
      long ms = (System.nanoTime() - t0) / 1_000_000;
      log.debug("[{}] No latest location for driverId={} ({} ms)", requestId, driverId, ms);
      return Optional.empty();
    }

    var r = opt.get();
    if (!hasRenderableCoordinates(r.getLatitude(), r.getLongitude())) {
      log.debug("[{}] Latest location ignored because coordinates are invalid", requestId);
      return Optional.empty();
    }
    var dto =
        LiveDriverDto.builder()
            .driverId(r.getDriverId())
            .latitude(r.getLatitude())
            .longitude(r.getLongitude())
            .speed(r.getSpeed())
            .heading(r.getHeading())
            .batteryLevel(r.getBatteryLevel())
            .locationName(normalizeLocationName(r.getLocationName()))
            .geocodeStatus(
                deriveGeocodeStatus(
                    normalizeLocationName(r.getLocationName()), Boolean.TRUE.equals(r.getIsOnline())))
            .online(Boolean.TRUE.equals(r.getIsOnline()))
            .updatedAt(r.getLastSeen() != null ? r.getLastSeen().toInstant() : null)
            .lastSeenEpochMs(r.getLastSeen() != null ? r.getLastSeen().toInstant().toEpochMilli() : null)
            .lastSeenSeconds(
                r.getLastSeen() != null
                    ? Math.max(0L, (System.currentTimeMillis() - r.getLastSeen().toInstant().toEpochMilli()) / 1000L)
                    : null)
            .ingestLagSeconds(
                r.getLastSeen() != null
                    ? Math.max(0L, (System.currentTimeMillis() - r.getLastSeen().toInstant().toEpochMilli()) / 1000L)
                    : null)
            .source(r.getSource())
            .build();

    long ms = (System.nanoTime() - t0) / 1_000_000;

    log.debug("[{}] Latest found (online={}, ts={}) in {} ms", requestId, dto.getOnline(), dto.getUpdatedAt(), ms);

    return Optional.of(dto);
  }

  private static boolean hasRenderableCoordinates(Double latitude, Double longitude) {
    if (latitude == null || longitude == null) {
      return false;
    }
    if (!Double.isFinite(latitude) || !Double.isFinite(longitude)) {
      return false;
    }
    return Math.abs(latitude) >= 0.000001d || Math.abs(longitude) >= 0.000001d;
  }

  private static String normalizeLocationName(String locationName) {
    if (locationName == null) {
      return null;
    }
    String normalized = locationName.trim();
    if (normalized.isEmpty() || UNKNOWN_LOCATION.equalsIgnoreCase(normalized)) {
      return null;
    }
    return normalized;
  }

  private static String deriveGeocodeStatus(String locationName, boolean onlineFlag) {
    if (locationName != null && !locationName.isBlank()) {
      return GEOCODE_RESOLVED;
    }
    return onlineFlag ? GEOCODE_PENDING : GEOCODE_FAILED;
  }

  @org.springframework.scheduling.annotation.Scheduled(fixedDelay = 60_000)
  @org.springframework.transaction.annotation.Transactional(transactionManager = "jpaTransactionManager")
  public void markStaleDriversOffline() {
    if (!schedulingEnabled) {
      log.info("Skipping markStaleDriversOffline because scheduling is disabled (export profile)");
      return;
    }
    final Instant now = Instant.now();
    final Timestamp cutoff = Timestamp.from(now.minus(3, ChronoUnit.MINUTES));
    final long t0 = System.nanoTime();

    int n = latestRepo.markOfflineIfLastSeenBefore(cutoff);
    long ms = (System.nanoTime() - t0) / 1_000_000;

    if (n > 0) {
      staleMarkedCounter.increment(n);
      log.info("[stale] Marked {} drivers offline (last_seen < {}) in {} ms", n, cutoff, ms);
    } else {
      log.debug("[stale] No drivers to mark offline (cutoff={}, {} ms)", cutoff, ms);
    }
  }
}
