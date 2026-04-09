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
import java.time.temporal.ChronoUnit;
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

        private final DriverLatestLocationRepository latestRepo;
        private final DriverSnapshotRepository snapshotRepo;
        private final Counter liveFallbackCounter;
        private final Counter staleMarkedCounter;

        public LiveDriverQueryService(
                        DriverLatestLocationRepository latestRepo,
                        DriverSnapshotRepository snapshotRepo,
                        MeterRegistry meterRegistry) {
                this.latestRepo = latestRepo;
                this.snapshotRepo = snapshotRepo;
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
                final int windowSec = (onlineSeconds != null && onlineSeconds > 0) ? onlineSeconds : 120;
                final Timestamp since = wantOnline
                                ? Timestamp.from(Instant.now().minus(windowSec, ChronoUnit.SECONDS))
                                : null;
                final boolean hasFullBbox = south != null && west != null && north != null && east != null;

                List<DriverLatestLocation> rows;
                if (wantOnline) {
                        rows = hasFullBbox
                                        ? latestRepo.findSinceWithinBbox(since, south, west, north, east)
                                        : latestRepo.findSince(since);

                        if (rows.isEmpty()) {
                                liveFallbackCounter.increment();
                                Instant cutoff = Instant.now().minus(windowSec, ChronoUnit.SECONDS);
                                rows = latestRepo.findAllLive().stream()
                                                .filter(r -> r.getLastSeen() != null
                                                                && r.getLastSeen().toInstant().isAfter(cutoff))
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
                        Instant updatedAt = r.getLastSeen() != null ? r.getLastSeen().toInstant() : null;
                        long nowMs = System.currentTimeMillis();
                        Long lastSeenEpochMs = updatedAt != null ? updatedAt.toEpochMilli() : null;
                        Long lastSeenSeconds = lastSeenEpochMs != null
                                        ? Math.max(0L, (nowMs - lastSeenEpochMs) / 1000L)
                                        : null;

                        boolean onlineFlag;
                        if (wantOnline) {
                                onlineFlag = Boolean.TRUE.equals(r.getIsOnline())
                                                || (r.getLastSeen() != null
                                                                && (since == null || r.getLastSeen().after(since)));
                        } else {
                                onlineFlag = Boolean.TRUE.equals(r.getIsOnline());
                        }

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
                                        .locationName(r.getLocationName())
                                        .online(onlineFlag)
                                        .dispatchId(r.getDispatchId())
                                        .updatedAt(updatedAt)
                                        .lastSeenEpochMs(lastSeenEpochMs)
                                        .lastSeenSeconds(lastSeenSeconds)
                                        .ingestLagSeconds(lastSeenSeconds)
                                        .source(r.getSource())
                                        .build());
                }
                return out;
        }

        public Optional<LiveDriverDto> getLatestForDriver(Long driverId) {
                return latestRepo.findById(driverId).map(r -> {
                        Instant updatedAt = r.getLastSeen() != null ? r.getLastSeen().toInstant() : null;
                        Long lastSeenEpochMs = updatedAt != null ? updatedAt.toEpochMilli() : null;
                        Long lastSeenSeconds = lastSeenEpochMs != null
                                        ? Math.max(0L, (System.currentTimeMillis() - lastSeenEpochMs) / 1000L)
                                        : null;
                        DriverSnapshot snap = snapshotRepo.findById(driverId).orElse(null);
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
                                        .locationName(r.getLocationName())
                                        .online(Boolean.TRUE.equals(r.getIsOnline()))
                                        .dispatchId(r.getDispatchId())
                                        .updatedAt(updatedAt)
                                        .lastSeenEpochMs(lastSeenEpochMs)
                                        .lastSeenSeconds(lastSeenSeconds)
                                        .ingestLagSeconds(lastSeenSeconds)
                                        .source(r.getSource())
                                        .build();
                });
        }

        @Scheduled(fixedDelay = 60_000)
        public void markStaleDriversOffline() {
                final Timestamp cutoff = Timestamp.from(Instant.now().minus(3, ChronoUnit.MINUTES));
                int n = latestRepo.markOfflineIfLastSeenBefore(cutoff);
                if (n > 0) {
                        staleMarkedCounter.increment(n);
                        log.info("[stale] Marked {} drivers offline (last_seen < {})", n, cutoff);
                }
        }

        private static boolean inBbox(DriverLatestLocation r,
                        double south, double west, double north, double east) {
                return r.getLatitude() >= south && r.getLatitude() <= north
                                && r.getLongitude() >= west && r.getLongitude() <= east;
        }
}
