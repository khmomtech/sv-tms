package com.svtrucking.telematics.service;

import com.svtrucking.telematics.dto.DriverTelemetryDiagnosticDto;
import com.svtrucking.telematics.model.DriverLatestLocation;
import com.svtrucking.telematics.model.DriverSnapshot;
import com.svtrucking.telematics.model.DriverTrackingSession;
import com.svtrucking.telematics.repository.DriverLatestLocationRepository;
import com.svtrucking.telematics.repository.DriverSnapshotRepository;
import com.svtrucking.telematics.repository.DriverTrackingSessionRepository;
import java.sql.Timestamp;
import java.time.Instant;
import java.time.LocalDateTime;
import java.time.ZoneOffset;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.function.Function;
import java.util.stream.Collectors;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

@Service
@RequiredArgsConstructor
public class DriverTelemetryDiagnosticsService {

    private final DriverLatestLocationRepository latestRepo;
    private final DriverSnapshotRepository snapshotRepo;
    private final DriverTrackingSessionRepository trackingSessionRepo;
    private final PresencePolicyService presencePolicyService;

    public List<DriverTelemetryDiagnosticDto> listDiagnostics(Boolean onlyProblematic) {
        List<DriverLatestLocation> latestRows = latestRepo.findAll();
        Map<Long, DriverLatestLocation> latestByDriver = latestRows.stream()
                .collect(Collectors.toMap(DriverLatestLocation::getDriverId, Function.identity(), (a, b) -> a));
        Map<Long, DriverSnapshot> snapshots = snapshotRepo.findAll().stream()
                .collect(Collectors.toMap(DriverSnapshot::getDriverId, Function.identity(), (a, b) -> a));

        Set<Long> driverIds = new LinkedHashSet<>();
        driverIds.addAll(snapshots.keySet());
        driverIds.addAll(latestByDriver.keySet());

        List<DriverTelemetryDiagnosticDto> out = new ArrayList<>();
        for (Long driverId : driverIds) {
            DriverLatestLocation latest = latestByDriver.get(driverId);
            DriverSnapshot snapshot = snapshots.get(driverId);
            DriverTrackingSession activeSession = trackingSessionRepo
                    .findByDriverIdAndRevokedAtIsNullOrderByUpdatedAtDesc(driverId)
                    .stream()
                    .findFirst()
                    .orElse(null);
            DriverTrackingSession anySession = activeSession != null
                    ? activeSession
                    : trackingSessionRepo.findByDriverIdOrderByUpdatedAtDesc(driverId).stream().findFirst().orElse(null);

            DriverTelemetryDiagnosticDto dto = buildDiagnostic(driverId, snapshot, latest, activeSession, anySession);
            if (!Boolean.TRUE.equals(onlyProblematic) || isProblematic(dto)) {
                out.add(dto);
            }
        }

        out.sort(Comparator
                .comparing((DriverTelemetryDiagnosticDto d) -> Boolean.TRUE.equals(d.getOnline()) ? 1 : 0)
                .thenComparing(d -> d.getReceivedAgeSeconds() == null ? Long.MAX_VALUE : d.getReceivedAgeSeconds())
                .thenComparing(d -> d.getDriverName() == null ? "" : d.getDriverName()));
        return out;
    }

    private DriverTelemetryDiagnosticDto buildDiagnostic(
            Long driverId,
            DriverSnapshot snapshot,
            DriverLatestLocation latest,
            DriverTrackingSession activeSession,
            DriverTrackingSession anySession) {
        Timestamp receivedTs = latest != null && latest.getLastReceivedAt() != null
                ? latest.getLastReceivedAt()
                : latest != null ? latest.getLastSeen() : null;
        Timestamp eventTs = latest != null ? latest.getLastEventTime() : null;
        Instant receivedAt = toInstant(receivedTs);
        Instant eventAt = toInstant(eventTs);
        long nowMs = System.currentTimeMillis();
        Long receivedAgeSeconds = receivedAt != null ? Math.max(0L, (nowMs - receivedAt.toEpochMilli()) / 1000L) : null;
        Long eventAgeSeconds = eventAt != null ? Math.max(0L, (nowMs - eventAt.toEpochMilli()) / 1000L) : null;
        Long ingestLagSeconds = (receivedAt != null && eventAt != null)
                ? Math.max(0L, (receivedAt.toEpochMilli() - eventAt.toEpochMilli()) / 1000L)
                : null;

        boolean online = receivedAt != null && presencePolicyService.isOnline(receivedAt.toEpochMilli());
        String reasonCode;
        String status;
        if (receivedAt == null) {
            status = "problem";
            reasonCode = activeSession != null ? "NO_TELEMETRY_YET" : "NO_TELEMETRY_NO_SESSION";
        } else if (ingestLagSeconds != null && ingestLagSeconds > 300) {
            status = online ? "warning" : "problem";
            reasonCode = "DELAYED_REPLAY";
        } else if (online) {
            status = "healthy";
            reasonCode = "ONLINE";
        } else if (activeSession == null && anySession != null && anySession.getExpiresAt() != null
                && anySession.getExpiresAt().isBefore(LocalDateTime.now())) {
            status = "problem";
            reasonCode = "SESSION_EXPIRED";
        } else if (activeSession == null) {
            status = "problem";
            reasonCode = "NO_ACTIVE_SESSION";
        } else {
            status = "problem";
            reasonCode = "NO_RECENT_INGEST";
        }

        DriverTrackingSession sessionForDisplay = activeSession != null ? activeSession : anySession;
        return DriverTelemetryDiagnosticDto.builder()
                .driverId(driverId)
                .driverName(snapshot != null ? snapshot.getFullName() : null)
                .driverPhone(snapshot != null ? snapshot.getPhoneNumber() : null)
                .vehiclePlate(snapshot != null ? snapshot.getVehiclePlate() : null)
                .status(status)
                .reasonCode(reasonCode)
                .online(online)
                .lastReceivedAt(receivedAt)
                .lastEventAt(eventAt)
                .receivedAgeSeconds(receivedAgeSeconds)
                .eventAgeSeconds(eventAgeSeconds)
                .ingestLagSeconds(ingestLagSeconds)
                .activeSession(activeSession != null)
                .sessionExpiresAt(sessionForDisplay != null ? toInstant(sessionForDisplay.getExpiresAt()) : null)
                .sessionLastSeenAt(sessionForDisplay != null ? toInstant(sessionForDisplay.getLastSeen()) : null)
                .sessionDeviceId(sessionForDisplay != null ? sessionForDisplay.getDeviceId() : null)
                .latitude(latest != null ? latest.getLatitude() : null)
                .longitude(latest != null ? latest.getLongitude() : null)
                .source(latest != null ? latest.getSource() : null)
                .build();
    }

    private boolean isProblematic(DriverTelemetryDiagnosticDto dto) {
        return !"healthy".equalsIgnoreCase(dto.getStatus());
    }

    private Instant toInstant(Timestamp ts) {
        return ts != null ? ts.toInstant() : null;
    }

    private Instant toInstant(LocalDateTime value) {
        return value != null ? value.toInstant(ZoneOffset.UTC) : null;
    }
}
