package com.svtrucking.telematics.service;

import com.svtrucking.telematics.dto.LiveDriverDto;
import com.svtrucking.telematics.model.DriverLatestLocation;
import com.svtrucking.telematics.model.DriverSnapshot;
import com.svtrucking.telematics.repository.DriverLatestLocationRepository;
import com.svtrucking.telematics.repository.DriverSnapshotRepository;
import io.micrometer.core.instrument.Counter;
import io.micrometer.core.instrument.MeterRegistry;
import java.sql.Timestamp;
import java.time.Instant;
import java.util.*;
import java.util.stream.Collectors;
import lombok.extern.slf4j.Slf4j;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Service;

/**
 * Admin live-track query service for tms-telematics-api.
 * Adapted from tms-backend: uses DriverSnapshotRepository for driver name/plate
 * enrichment
 * instead of DriverRepository + VehicleDriverRepository (which live in the main
 * schema).
 */
@Service
@Slf4j
public class LiveDriverQueryService {
        private static final String GEOCODE_RESOLVED = "resolved";
        private static final String GEOCODE_PENDING = "pending";
        private static final String GEOCODE_FAILED = "failed";
        private static final String UNKNOWN_LOCATION = "Unknown location";

        private final DriverLatestLocationRepository latestRepo;
        private final DriverSnapshotRepository snapshotRepo;
        private final PresencePolicyService presencePolicyService;
        private final Counter liveFallbackCounter;
        private final Counter staleMarkedCounter;

        public LiveDriverQueryService(
                        DriverLatestLocationRepository latestRepo,
                        DriverSnapshotRepository snapshotRepo,
                        PresencePolicyService presencePolicyService,
                        MeterRegistry meterRegistry) {
                this.latestRepo = latestRepo;
                this.snapshotRepo = snapshotRepo;
                this.presencePolicyService = presencePolicyService;
                this.liveFallbackCounter = Counter.builder("tracking.live.fallback.count")
                                .description("Count of live query fallback executions").register(meterRegistry);
                this.staleMarkedCounter = Counter.builder("tracking.stale.marked_offline.count")
                                .description("Count of drivers marked offline by stale sweeper")
                                .register(meterRegistry);
        }

        public List<LiveDriverDto> getLiveDrivers(
                        Boolean onlyOnline, Integer onlineSeconds,
                        Double south, Double west, Double north, Double east) {

                final boolean wantOnline = Boolean.TRUE.equals(onlyOnline)
                                || (onlineSeconds != null && onlineSeconds > 0);
                final Timestamp since = wantOnline ? presencePolicyService.cutoffTimestampForSeconds(onlineSeconds) : null;
                final boolean hasFullBbox = south != null && west != null && north != null && east != null;

                List<DriverLatestLocation> rows;
                if (wantOnline) {
                        rows = hasFullBbox
                                        ? latestRepo.findSinceWithinBbox(since, south, west, north, east)
                                        : latestRepo.findSince(since);

                        if (rows.isEmpty()) {
                                liveFallbackCounter.increment();
                                Instant cutoff = since.toInstant();
                                rows = latestRepo.findAllLive().stream()
                                                .filter(r -> receivedAt(r) != null
                                                                && receivedAt(r).toInstant().isAfter(cutoff))
                                                .filter(r -> !hasFullBbox || inBbox(r, south, west, north, east))
                                                .collect(Collectors.toList());
                        }
                } else {
                        rows = latestRepo.findAllLive();
                        if (hasFullBbox) {
                                rows = rows.stream()
                                                .filter(l -> l.getLatitude() != 0 && l.getLongitude() != 0)
                                                .filter(r -> inBbox(r, south, west, north, east))
                                                .collect(Collectors.toList());
                        }
                }

                if (rows.isEmpty())
                        return Collections.emptyList();

                Set<Long> driverIds = rows.stream()
                                .map(DriverLatestLocation::getDriverId).collect(Collectors.toSet());

                // Use DriverSnapshot for lightweight name/plate enrichment
                Map<Long, DriverSnapshot> snapshots = snapshotRepo.findAllById(driverIds).stream()
                                .collect(Collectors.toMap(DriverSnapshot::getDriverId, s -> s));

                List<LiveDriverDto> out = new ArrayList<>(rows.size());
                for (var r : rows) {
                        var snap = snapshots.get(r.getDriverId());
                        Instant updatedAt = receivedAt(r) != null ? receivedAt(r).toInstant() : null;
                        Instant eventAt = r.getLastEventTime() != null ? r.getLastEventTime().toInstant() : null;
                        long nowMs = System.currentTimeMillis();
                        Long lastSeenEpochMs = updatedAt != null ? updatedAt.toEpochMilli() : null;
                        Long lastEventEpochMs = eventAt != null ? eventAt.toEpochMilli() : null;
                        Long lastSeenSeconds = lastSeenEpochMs != null
                                        ? Math.max(0L, (nowMs - lastSeenEpochMs) / 1000L)
                                        : null;
                        Long eventAgeSeconds = lastEventEpochMs != null
                                        ? Math.max(0L, (nowMs - lastEventEpochMs) / 1000L)
                                        : null;
                        Long ingestLagSeconds = (lastSeenEpochMs != null && lastEventEpochMs != null)
                                        ? Math.max(0L, (lastSeenEpochMs - lastEventEpochMs) / 1000L)
                                        : lastSeenSeconds;

                        boolean onlineFlag = presencePolicyService.isOnline(lastSeenEpochMs);

                        String locationName = normalizeLocationName(r.getLocationName());
                        out.add(LiveDriverDto.builder()
                                        .driverId(r.getDriverId())
                                        .driverName(snap != null ? snap.getFullName() : null)
                                        .driverPhone(snap != null ? snap.getPhoneNumber() : null)
                                        .vehiclePlate(snap != null ? snap.getVehiclePlate() : null)
                                        .latitude(r.getLatitude())
                                        .longitude(r.getLongitude())
                                        .speed(r.getSpeed())
                                        .heading(r.getHeading())
                                        .batteryLevel(r.getBatteryLevel())
                                        .locationName(locationName)
                                        .geocodeStatus(deriveGeocodeStatus(locationName, lastSeenEpochMs))
                                        .online(onlineFlag)
                                        .dispatchId(r.getDispatchId())
                                        .updatedAt(updatedAt)
                                        .eventAt(eventAt)
                                        .lastSeenEpochMs(lastSeenEpochMs)
                                        .lastEventEpochMs(lastEventEpochMs)
                                        .lastSeenSeconds(lastSeenSeconds)
                                        .eventAgeSeconds(eventAgeSeconds)
                                        .ingestLagSeconds(ingestLagSeconds)
                                        .source(r.getSource())
                                        .build());
                }
                return out;
        }

        public Optional<LiveDriverDto> getLatestForDriver(Long driverId) {
                return latestRepo.findById(driverId).map(r -> {
                        Instant updatedAt = receivedAt(r) != null ? receivedAt(r).toInstant() : null;
                        Instant eventAt = r.getLastEventTime() != null ? r.getLastEventTime().toInstant() : null;
                        Long lastSeenEpochMs = updatedAt != null ? updatedAt.toEpochMilli() : null;
                        Long lastEventEpochMs = eventAt != null ? eventAt.toEpochMilli() : null;
                        Long lastSeenSeconds = lastSeenEpochMs != null
                                        ? Math.max(0L, (System.currentTimeMillis() - lastSeenEpochMs) / 1000L)
                                        : null;
                        Long eventAgeSeconds = lastEventEpochMs != null
                                        ? Math.max(0L, (System.currentTimeMillis() - lastEventEpochMs) / 1000L)
                                        : null;
                        Long ingestLagSeconds = (lastSeenEpochMs != null && lastEventEpochMs != null)
                                        ? Math.max(0L, (lastSeenEpochMs - lastEventEpochMs) / 1000L)
                                        : lastSeenSeconds;
                        DriverSnapshot snap = snapshotRepo.findById(driverId).orElse(null);
                        String locationName = normalizeLocationName(r.getLocationName());
                        return LiveDriverDto.builder()
                                        .driverId(r.getDriverId())
                                        .driverName(snap != null ? snap.getFullName() : null)
                                        .driverPhone(snap != null ? snap.getPhoneNumber() : null)
                                        .vehiclePlate(snap != null ? snap.getVehiclePlate() : null)
                                        .latitude(r.getLatitude())
                                        .longitude(r.getLongitude())
                                        .speed(r.getSpeed())
                                        .heading(r.getHeading())
                                        .batteryLevel(r.getBatteryLevel())
                                        .locationName(locationName)
                                        .geocodeStatus(deriveGeocodeStatus(locationName, lastSeenEpochMs))
                                        .online(Boolean.TRUE.equals(r.getIsOnline()))
                                        .dispatchId(r.getDispatchId())
                                        .updatedAt(updatedAt)
                                        .eventAt(eventAt)
                                        .lastSeenEpochMs(lastSeenEpochMs)
                                        .lastEventEpochMs(lastEventEpochMs)
                                        .lastSeenSeconds(lastSeenSeconds)
                                        .eventAgeSeconds(eventAgeSeconds)
                                        .ingestLagSeconds(ingestLagSeconds)
                                        .source(r.getSource())
                                        .build();
                });
        }

        @Scheduled(fixedDelay = 60_000)
        public void markStaleDriversOffline() {
                final Timestamp cutoff = presencePolicyService.offlineCutoffTimestamp();
                int n = latestRepo.markOfflineIfLastSeenBefore(cutoff);
                if (n > 0) {
                        staleMarkedCounter.increment(n);
                        log.info("[stale] Marked {} drivers offline (last_seen < {})", n, cutoff);
                }
        }

        private static Timestamp receivedAt(DriverLatestLocation r) {
                return r.getLastReceivedAt() != null ? r.getLastReceivedAt() : r.getLastSeen();
        }

        private static boolean inBbox(DriverLatestLocation r,
                        double south, double west, double north, double east) {
                return r.getLatitude() >= south && r.getLatitude() <= north
                                && r.getLongitude() >= west && r.getLongitude() <= east;
        }

        private static String normalizeLocationName(String locationName) {
                if (locationName == null)
                        return null;
                String normalized = locationName.trim();
                if (normalized.isEmpty() || UNKNOWN_LOCATION.equalsIgnoreCase(normalized))
                        return null;
                return normalized;
        }

        private String deriveGeocodeStatus(String locationName, Long lastSeenEpochMs) {
                if (locationName != null && !locationName.isBlank())
                        return GEOCODE_RESOLVED;
                if (lastSeenEpochMs != null && presencePolicyService.isOnline(lastSeenEpochMs))
                        return GEOCODE_PENDING;
                return GEOCODE_FAILED;
        }
}
