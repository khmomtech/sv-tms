package com.svtrucking.logistics.service;

import com.svtrucking.logistics.core.service.GeocodingService;
import com.svtrucking.logistics.dto.LocationHistoryDto;
import com.svtrucking.logistics.enums.DispatchStatus;
import com.svtrucking.logistics.model.Dispatch;
import com.svtrucking.logistics.model.Driver;
import com.svtrucking.logistics.model.LocationHistory;
import com.svtrucking.logistics.repository.DispatchRepository;
import com.svtrucking.logistics.repository.DriverRepository;
import com.svtrucking.logistics.repository.LocationHistoryRepository;
import jakarta.transaction.TransactionalException;
import java.time.Duration;
import java.time.LocalDateTime;
import java.util.EnumSet;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.concurrent.ConcurrentHashMap;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.ApplicationEventPublisher;
import org.springframework.messaging.simp.SimpMessagingTemplate;
import org.springframework.stereotype.Service;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.domain.PageImpl;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.transaction.event.TransactionPhase;
import org.springframework.transaction.event.TransactionalEventListener;

@Slf4j
@Service
public class DriverLocationService {

  private final SimpMessagingTemplate messagingTemplate;
  private final DriverRepository driverRepository;
  private final LocationHistoryRepository locationHistoryRepository;
  private final DispatchRepository dispatchRepository;
  private final GeocodingService geocodingService;
  private final ApplicationEventPublisher publisher;
  private final DriverLocationMongoService mongoService;
  @org.springframework.beans.factory.annotation.Autowired(required = false)
  private LocationHistorySpoolService spoolService;
  @Value("${location.history.read.require-mongo:true}")
  private boolean requireMongoForHistoryReads;

  // ---- Tuning knobs ----
  private static final double MIN_DIST_M = 15.0; // ignore hops < 15 m
  private static final long MIN_TIME_S = 8L; // ignore intervals < 8 s
  private static final double MAX_SPEED_KMH = 180.0; // cap outliers
  private static final double EMA_ALPHA = 0.6; // smoothing factor

  // Lightweight server-side dedupe cache (per driver)
  private static final class LastPoint {
    final double lat, lng;
    final LocalDateTime ts;

    LastPoint(double lat, double lng, LocalDateTime ts) {
      this.lat = lat;
      this.lng = lng;
      this.ts = ts;
    }
  }

  private final ConcurrentHashMap<Long, LastPoint> lastPointCache = new ConcurrentHashMap<>();

  public DriverLocationService(
      SimpMessagingTemplate messagingTemplate,
      DriverRepository driverRepository,
      LocationHistoryRepository locationHistoryRepository,
      DispatchRepository dispatchRepository,
      GeocodingService geocodingService,
      ApplicationEventPublisher publisher,
      @org.springframework.beans.factory.annotation.Autowired(required = false)
          DriverLocationMongoService mongoService) {
    this.messagingTemplate = messagingTemplate;
    this.driverRepository = driverRepository;
    this.locationHistoryRepository = locationHistoryRepository;
    this.dispatchRepository = dispatchRepository;
    this.geocodingService = geocodingService;
    this.publisher = publisher;
    this.mongoService = mongoService;
  }

  /**
   * Updates the driver's location. Orchestrates: - fast dedupe (cache + DB read), - geocoding
   * OUTSIDE transaction, - short transactional persist, - WebSocket broadcast + cache update AFTER
   * COMMIT.
   */
  public LocationHistoryDto updateDriverLocation(
      Long driverId,
      double latitude,
      double longitude,
      Dispatch optionalDispatch,
      Integer batteryLevel,
      String source,
      Double clientSpeed,
      String locationNameOverride) {

    // Quick existence check (cheap, early fail)
    if (!driverRepository.existsById(driverId)) {
      throw new RuntimeException("Driver not found with ID: " + driverId);
    }

    LocalDateTime now = LocalDateTime.now();

    // ---- Server-side jitter/dup guard (cache based, no DB) ----
    LastPoint lp = lastPointCache.get(driverId);
    if (lp != null) {
      double distM = haversineMeters(lp.lat, lp.lng, latitude, longitude);
      long dtSec = Math.max(0, Duration.between(lp.ts, now).getSeconds());
      if (distM < MIN_DIST_M && dtSec < MIN_TIME_S) {
        log.debug(
            "🛑 Server dedupe (cache): driver {} Δd={}m Δt={}s → skip",
            driverId,
            String.format("%.1f", distM),
            dtSec);
        LocationHistory last =
            locationHistoryRepository.findTopByDriverIdOrderByTimestampDesc(driverId).orElse(null);
        return last != null
            ? LocationHistoryDto.fromEntity(last)
            : LocationHistoryDto.builder().build();
      }
    }

    // ---- DB last point (read-only) for extra guard & speed calc ----
    Optional<LocationHistory> lastOpt =
        locationHistoryRepository.findTopByDriverIdOrderByTimestampDesc(driverId);

    // Resolve dispatch (prefer provided if active) using a quick DB read (will be reused in tx)
    Dispatch dispatch = resolveDispatch(driverId, optionalDispatch);

    if (lastOpt.isPresent()) {
      LocationHistory last = lastOpt.get();
      double distM = haversineMeters(last.getLatitude(), last.getLongitude(), latitude, longitude);
      long dtSec = Math.max(0, Duration.between(last.getTimestamp(), now).getSeconds());
      boolean sameDispatch =
          (last.getDispatch() == null && dispatch == null)
              || (last.getDispatch() != null
                  && dispatch != null
                  && last.getDispatch().getId().equals(dispatch.getId()));

      if (sameDispatch && distM < MIN_DIST_M && dtSec < MIN_TIME_S) {
        log.debug(
            "Server dedupe (DB): driver {} Δd={}m Δt={}s → skip",
            driverId,
            String.format("%.1f", distM),
            dtSec);
        return LocationHistoryDto.fromEntity(last);
      }
    }

    // ---- Reverse geocode (OUTSIDE transaction) ----
    String resolvedLocationName =
        (locationNameOverride != null && !locationNameOverride.isBlank())
            ? locationNameOverride
            : safeReverseGeocode(latitude, longitude);

    // ---- Persist in a short transaction, then publish AFTER_COMMIT ----
    return persistAndPublish(
        driverId,
        latitude,
        longitude,
        dispatch,
        batteryLevel,
        source,
        clientSpeed,
        resolvedLocationName,
        now,
        lastOpt);
  }

  private String safeReverseGeocode(double latitude, double longitude) {
    try {
      return geocodingService.reverseGeocode(latitude, longitude);
    } catch (Exception e) {
      log.warn("Geocoding failed at {}, {}: {}", latitude, longitude, e.toString());
      return null; // ok to store null; can enrich later
    }
  }

  // ========= TRANSACTION BOUNDARY (short + DB only) =========
  @Transactional(timeout = 3)
  protected LocationHistoryDto persistAndPublish(
      Long driverId,
      double latitude,
      double longitude,
      Dispatch resolvedDispatch,
      Integer batteryLevel,
      String source,
      Double clientSpeed,
      String locationName,
      LocalDateTime now,
      Optional<LocationHistory> lastOptForSpeed) {
    // Load managed entities
    Driver driver =
        driverRepository
            .findById(driverId)
            .orElseThrow(
                () -> new TransactionalException("Driver not found with ID: " + driverId, null));

    // Re-resolve dispatch inside tx in case state changed
    Dispatch dispatch =
        (resolvedDispatch != null) ? resolvedDispatch : resolveDispatch(driverId, null);

    // Compute canonical speed
    Double computedSpeedKmh = computeServerSpeedKmh(lastOptForSpeed, latitude, longitude, now);
    if (computedSpeedKmh == null && clientSpeed != null && clientSpeed >= 0) {
      computedSpeedKmh = clientSpeed;
    }
    if (computedSpeedKmh != null) {
      computedSpeedKmh = Math.min(MAX_SPEED_KMH, Math.max(0.0, computedSpeedKmh));
      if (computedSpeedKmh < 2.0) computedSpeedKmh = 0.0; // treat crawl as stopped
    }

    // Location now stored in DriverLatestLocation table (handled by LocationIngestService)
    // No longer updating Driver entity directly

    // Insert history
    LocationHistory saved =
        locationHistoryRepository.save(
            LocationHistory.builder()
                .driver(driver)
                .dispatch(dispatch)
                .latitude(latitude)
                .longitude(longitude)
                .locationName(locationName)
                .speed(computedSpeedKmh)
                .batteryLevel(batteryLevel)
                .source((source == null || source.isBlank()) ? "ANDROID_NATIVE" : source)
                .timestamp(now)
                .build());

    // Prepare DTO and publish AFTER_COMMIT event (no DB work in listener)
    LocationHistoryDto dto = LocationHistoryDto.fromEntity(saved);
    publisher.publishEvent(new LocationSavedEvent(driverId, dto, latitude, longitude, now));
    return dto;
  }

  // AFTER_COMMIT: safe for WebSocket + cache update (no DB connection held)
  @TransactionalEventListener(phase = TransactionPhase.AFTER_COMMIT)
  public void onLocationSaved(LocationSavedEvent ev) {
    try {
      // Build enriched live payload (keeps old fields from DTO, adds serverTime/lastSeen/isOnline)
      LocationHistoryDto d = ev.dto;
      Map<String, Object> live = new HashMap<>();
      // Core identifiers
      live.put("driverId", d.getDriverId());
      if (d.getDispatch() != null) {
        live.put("dispatchId", d.getDispatch().getId());
      } else if (d.getDispatchId() != null) {
        live.put("dispatchId", d.getDispatchId());
      }
      // Coordinates & location meta
      live.put("latitude", d.getLatitude());
      live.put("longitude", d.getLongitude());
      if (d.getLocationName() != null) live.put("locationName", d.getLocationName());
      // Speeds / battery / source as provided by server persist
      if (d.getSpeed() != null) live.put("speed", d.getSpeed()); // km/h
      if (d.getBatteryLevel() != null) live.put("batteryLevel", d.getBatteryLevel());
      if (d.getSource() != null) live.put("source", d.getSource());
      // Timing / presence flags
      long nowMs = System.currentTimeMillis();
      live.put("serverTime", nowMs);
      live.put("lastSeen", nowMs);
      live.put("isOnline", Boolean.TRUE); // fresh after commit
      // Also forward the original DTO timestamp if available
      if (d.getTimestamp() != null) {
        live.put(
            "clientTime",
            d.getTimestamp().atZone(java.time.ZoneId.systemDefault()).toInstant().toEpochMilli());
      }

      // Broadcast enriched payload
      messagingTemplate.convertAndSend("/topic/driver-location/" + ev.driverId, live);
      messagingTemplate.convertAndSend("/topic/driver-location/all", live);

      // Update cache only after DB commit succeeded
      lastPointCache.put(ev.driverId, new LastPoint(ev.lat, ev.lng, ev.ts));
      log.debug("Sent location update for driver {} to all listeners (enriched)", ev.driverId);
    } catch (Exception e) {
      log.warn("WebSocket broadcast failed for driver {}: {}", ev.driverId, e.toString());
    }
  }

  private record LocationSavedEvent(
      Long driverId, LocationHistoryDto dto, double lat, double lng, LocalDateTime ts) {}

  // -------------------------------------------------------------------------
  // Helpers
  // -------------------------------------------------------------------------

  private Dispatch resolveDispatch(Long driverId, Dispatch optionalDispatch) {
    if (optionalDispatch != null && isDispatchActive(optionalDispatch)) {
      return optionalDispatch;
    }
    return dispatchRepository
      .findTopByDriverIdAndStatusInOrderByIdDesc(
        driverId,
        EnumSet.of(
          DispatchStatus.ASSIGNED,
          DispatchStatus.DRIVER_CONFIRMED,
          DispatchStatus.IN_QUEUE,
          DispatchStatus.ARRIVED_LOADING,
          DispatchStatus.LOADING,
          DispatchStatus.LOADED,
          DispatchStatus.IN_TRANSIT,
          DispatchStatus.ARRIVED_UNLOADING))
      .orElse(null);
  }

  private boolean isDispatchActive(Dispatch dispatch) {
    return EnumSet.of(
        DispatchStatus.ASSIGNED,
        DispatchStatus.DRIVER_CONFIRMED,
        DispatchStatus.IN_QUEUE,
        DispatchStatus.ARRIVED_LOADING,
        DispatchStatus.LOADING,
        DispatchStatus.LOADED,
        DispatchStatus.IN_TRANSIT,
        DispatchStatus.ARRIVED_UNLOADING)
      .contains(dispatch.getStatus());
  }

  /** Compute smoothed speed in km/h, or null if not computable. */
  private Double computeServerSpeedKmh(
      Optional<LocationHistory> lastOpt, double lat, double lng, LocalDateTime now) {
    if (lastOpt.isEmpty()) return null;
    LocationHistory last = lastOpt.get();

    double distM = haversineMeters(last.getLatitude(), last.getLongitude(), lat, lng);
    long dtSec = Math.max(0, Duration.between(last.getTimestamp(), now).getSeconds());

    if (dtSec < MIN_TIME_S || distM < MIN_DIST_M) {
      return last.getSpeed(); // continuity; could also return null
    }

    double instKmh = (distM / Math.max(1, dtSec)) * 3.6; // m/s->km/h
    instKmh = Math.min(MAX_SPEED_KMH * 2, Math.max(0.0, instKmh)); // cap raw
    Double prev = last.getSpeed();
    if (prev != null) {
      instKmh = EMA_ALPHA * instKmh + (1.0 - EMA_ALPHA) * prev;
    }
    return Math.min(MAX_SPEED_KMH, instKmh);
  }

  /** Great-circle distance in meters (Haversine). */
  private static double haversineMeters(double lat1, double lon1, double lat2, double lon2) {
    final double R = 6371000.0; // meters
    double dLat = Math.toRadians(lat2 - lat1);
    double dLon = Math.toRadians(lon2 - lon1);
    double a =
        Math.sin(dLat / 2) * Math.sin(dLat / 2)
            + Math.cos(Math.toRadians(lat1))
                * Math.cos(Math.toRadians(lat2))
                * Math.sin(dLon / 2)
                * Math.sin(dLon / 2);
    double c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
    return R * c;
  }

  @SuppressWarnings("unused")
  private static void putIfNotNull(Map<String, Object> m, String k, Object v) {
    if (v != null) m.put(k, v);
  }

  /**
   * Get location history for a driver.
   */
  public List<LocationHistoryDto> getDriverLocationHistory(Long driverId) {
    if (mongoService != null) {
      return mongoService.findByDriver(driverId);
    }
    if (requireMongoForHistoryReads) {
      throw new IllegalStateException("Location history store unavailable (MongoDB not configured)");
    }
    List<LocationHistory> history = locationHistoryRepository.findByDriverIdOrderByTimestampDesc(driverId);
    return history.stream().map(LocationHistoryDto::fromEntity).toList();
  }

  /**
   * Get paginated location history for a driver.
   */
  public Page<LocationHistoryDto> getDriverLocationHistoryPaginated(Long driverId, int page, int size) {
    if (mongoService != null) {
      List<LocationHistoryDto> docs = mongoService.findByDriver(driverId, page, size);
      return new PageImpl<>(docs, Pageable.ofSize(size).withPage(page), docs.size());
    }
    if (requireMongoForHistoryReads) {
      throw new IllegalStateException("Location history store unavailable (MongoDB not configured)");
    }
    Pageable pageable = org.springframework.data.domain.PageRequest.of(page, size);
    Page<LocationHistory> historyPage = locationHistoryRepository.findByDriverIdOrderByTimestampDesc(driverId, pageable);
    return historyPage.map(LocationHistoryDto::fromEntity);
  }

  public String historyStoreName() {
    return mongoService != null ? "MONGO" : "MYSQL";
  }

  public long historyReplayLagSeconds() {
    if (spoolService == null) {
      return 0L;
    }
    return spoolService.oldestPendingAgeSeconds();
  }
}
