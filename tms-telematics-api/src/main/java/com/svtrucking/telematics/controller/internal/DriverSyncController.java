package com.svtrucking.telematics.controller.internal;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.svtrucking.telematics.model.DriverSnapshot;
import com.svtrucking.telematics.repository.DriverSnapshotRepository;
import jakarta.validation.Valid;
import jakarta.validation.constraints.NotNull;
import java.time.LocalDateTime;
import java.time.ZoneOffset;
import java.util.Map;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

/**
 * Internal API for tms-backend to push driver name/plate snapshots.
 * Guarded by InternalApiKeyFilter (X-Internal-Api-Key header).
 * Fire-and-forget: tms-backend calls PATCH after every driver create/update.
 */
@RestController
@RequestMapping("/api/internal/telematics")
@RequiredArgsConstructor
@Slf4j
public class DriverSyncController {

    private final DriverSnapshotRepository snapshotRepository;
    private final ObjectMapper objectMapper;

    @PatchMapping("/driver-sync")
    public ResponseEntity<Map<String, Object>> syncDriver(
            @Valid @RequestBody DriverSyncRequest req) {
        try {
            DriverSnapshot snap = snapshotRepository.findById(req.getDriverId())
                    .orElse(new DriverSnapshot());
            snap.setDriverId(req.getDriverId());
            if (req.getName() != null)
                snap.setFullName(req.getName());
            if (req.getPhone() != null)
                snap.setPhoneNumber(req.getPhone());
            if (req.getVehiclePlate() != null)
                snap.setVehiclePlate(req.getVehiclePlate());
            snap.setSyncedAt(LocalDateTime.now(ZoneOffset.UTC));
            snapshotRepository.save(snap);

            log.debug("[driver-sync] Updated snapshot driverId={} name={}",
                    req.getDriverId(), snap.getFullName());

            return ResponseEntity.ok(Map.of(
                    "ok", true,
                    "driverId", req.getDriverId(),
                    "synced", true));

        } catch (Exception e) {
            log.error("[driver-sync] Failed for driverId={}: {}", req.getDriverId(), e.getMessage(), e);
            return ResponseEntity.internalServerError()
                    .body(Map.of("ok", false, "message", "Sync failed: " + e.getMessage()));
        }
    }

    /** Bulk upsert — sent on service start-up or after batch driver imports. */
    @PatchMapping("/driver-sync/bulk")
    public ResponseEntity<Map<String, Object>> syncDriversBulk(
            @RequestBody JsonNode req) {
        java.util.List<DriverSyncRequest> drivers = extractDrivers(req);
        if (drivers.isEmpty()) {
            return ResponseEntity.ok(Map.of("ok", true, "synced", 0));
        }
        int count = 0;
        for (DriverSyncRequest item : drivers) {
            if (item.getDriverId() == null)
                continue;
            try {
                DriverSnapshot snap = snapshotRepository.findById(item.getDriverId())
                        .orElse(new DriverSnapshot());
                snap.setDriverId(item.getDriverId());
                if (item.getName() != null)
                    snap.setFullName(item.getName());
                if (item.getPhone() != null)
                    snap.setPhoneNumber(item.getPhone());
                if (item.getVehiclePlate() != null)
                    snap.setVehiclePlate(item.getVehiclePlate());
                snap.setSyncedAt(LocalDateTime.now(ZoneOffset.UTC));
                snapshotRepository.save(snap);
                count++;
            } catch (Exception e) {
                log.warn("[driver-sync] bulk item driverId={} failed: {}", item.getDriverId(), e.getMessage());
            }
        }
        log.info("[driver-sync] Bulk synced {} drivers", count);
        return ResponseEntity.ok(Map.of("ok", true, "synced", count));
    }

    private java.util.List<DriverSyncRequest> extractDrivers(JsonNode req) {
        if (req == null || req.isNull()) {
            return java.util.List.of();
        }
        try {
            if (req.isArray()) {
                java.util.List<DriverSyncRequest> out = new java.util.ArrayList<>();
                for (JsonNode node : req) {
                    DriverSyncRequest item = objectMapper.treeToValue(node, DriverSyncRequest.class);
                    out.add(item);
                }
                return out;
            }
            if (req.isObject() && req.has("drivers") && req.get("drivers").isArray()) {
                java.util.List<DriverSyncRequest> out = new java.util.ArrayList<>();
                for (JsonNode node : req.get("drivers")) {
                    DriverSyncRequest item = objectMapper.treeToValue(node, DriverSyncRequest.class);
                    out.add(item);
                }
                return out;
            }
        } catch (Exception e) {
            log.warn("[driver-sync] bulk payload parse failed: {}", e.getMessage());
        }
        return java.util.List.of();
    }

    // ── Inner DTOs ──────────────────────────────────────────────────────────

    @lombok.Data
    @lombok.NoArgsConstructor
    @lombok.AllArgsConstructor
    public static class DriverSyncRequest {
        @NotNull
        private Long driverId;
        private String name;
        private String phone;
        private String vehiclePlate;
    }

    @lombok.Data
    @lombok.NoArgsConstructor
    public static class BulkSyncRequest {
        private java.util.List<DriverSyncRequest> drivers;
    }
}
