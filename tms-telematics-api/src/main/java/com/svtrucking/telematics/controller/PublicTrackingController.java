package com.svtrucking.telematics.controller;

import com.svtrucking.telematics.dto.DispatchContextDto;
import com.svtrucking.telematics.model.DriverLatestLocation;
import com.svtrucking.telematics.repository.DriverLatestLocationRepository;
import com.svtrucking.telematics.service.DispatchContextCacheService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import java.time.LocalDateTime;
import java.util.HashMap;
import java.util.Map;
import java.util.Optional;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

/**
 * Public shipment tracking controller for tms-telematics-api.
 * Adapted from tms-backend PublicTrackingController:
 * - JPA repo injections replaced with DispatchContextCacheService (30s Caffeine
 * TTL)
 * - GPS location pulled directly from driver_latest_location (local table)
 * - Status history not available locally; returns link to order reference for
 * tms-backend
 */
@RestController
@RequestMapping("/api/public/tracking")
@RequiredArgsConstructor
@Slf4j
@Tag(name = "Public Tracking", description = "Public shipment tracking (no auth required)")
public class PublicTrackingController {

    private final DispatchContextCacheService dispatchContextCache;
    private final DriverLatestLocationRepository latestLocationRepo;

    @GetMapping("/{orderReference}")
    @Operation(summary = "Track shipment", description = "Get current status and driver info by order reference")
    public ResponseEntity<Map<String, Object>> trackShipment(
            @PathVariable String orderReference) {

        DispatchContextDto ctx = dispatchContextCache.getByOrderReference(orderReference);
        if (ctx == null) {
            return ResponseEntity.notFound().build();
        }

        Map<String, Object> response = buildBaseResponse(ctx);

        if (ctx.getDispatchId() != null) {
            Map<String, Object> dispatchInfo = new HashMap<>();
            dispatchInfo.put("id", ctx.getDispatchId());
            dispatchInfo.put("routeCode", ctx.getRouteCode());
            dispatchInfo.put("trackingNo", ctx.getTrackingNo());
            dispatchInfo.put("status", ctx.getDispatchStatus());
            dispatchInfo.put("estimatedArrival", ctx.getEstimatedArrival());
            dispatchInfo.put("startTime", ctx.getStartTime());
            dispatchInfo.put("fromLocation", ctx.getFromLocation());
            dispatchInfo.put("toLocation", ctx.getToLocation());

            if (ctx.getDriverId() != null) {
                Map<String, Object> driverInfo = new HashMap<>();
                driverInfo.put("id", ctx.getDriverId());
                driverInfo.put("name", ctx.getDriverName());
                driverInfo.put("phone", ctx.getDriverPhone());
                driverInfo.put("vehicleNumber", ctx.getVehiclePlate());
                dispatchInfo.put("driver", driverInfo);
            }
            response.put("dispatch", dispatchInfo);
        }

        if (ctx.getStops() != null && !ctx.getStops().isEmpty()) {
            response.put("stops", ctx.getStops());
        }

        return ResponseEntity.ok(response);
    }

    @GetMapping("/{orderReference}/location")
    @Operation(summary = "Get current shipment location", description = "Real-time GPS position of the assigned driver")
    public ResponseEntity<Map<String, Object>> getCurrentLocation(
            @PathVariable String orderReference) {

        DispatchContextDto ctx = dispatchContextCache.getByOrderReference(orderReference);
        if (ctx == null) {
            return ResponseEntity.notFound().build();
        }

        Map<String, Object> response = new HashMap<>();
        response.put("orderReference", orderReference);
        response.put("currentStatus", ctx.getOrderStatus());
        response.put("hasActiveDispatch", ctx.getDispatchId() != null);
        response.put("driverAssigned", ctx.getDriverId() != null);
        response.put("lastUpdated", LocalDateTime.now());

        if (ctx.getDriverId() != null) {
            Optional<DriverLatestLocation> locOpt = latestLocationRepo.findById(ctx.getDriverId());
            if (locOpt.isPresent()) {
                DriverLatestLocation loc = locOpt.get();
                Map<String, Object> gpsData = new HashMap<>();
                gpsData.put("latitude", loc.getLatitude());
                gpsData.put("longitude", loc.getLongitude());
                gpsData.put("accuracy", loc.getAccuracyMeters());
                gpsData.put("speed", loc.getSpeed());
                gpsData.put("heading", loc.getHeading());
                gpsData.put("locationName", loc.getLocationName());
                gpsData.put("lastSeen", loc.getLastReceivedAt() != null ? loc.getLastReceivedAt() : loc.getLastSeen());
                gpsData.put("lastEventTime", loc.getLastEventTime());
                gpsData.put("isOnline", loc.getIsOnline());
                response.put("location", gpsData);
                response.put("hasLocation", true);
            } else {
                response.put("hasLocation", false);
            }
        } else {
            response.put("hasLocation", false);
        }

        return ResponseEntity.ok(response);
    }

    @GetMapping("/{orderReference}/history")
    @Operation(summary = "Get shipment status history", description = "Timeline of status changes. Fetched from tms-backend via dispatch context cache.")
    public ResponseEntity<Map<String, Object>> getStatusHistory(
            @PathVariable String orderReference) {

        DispatchContextDto ctx = dispatchContextCache.getByOrderReference(orderReference);
        if (ctx == null) {
            return ResponseEntity.notFound().build();
        }
        Map<String, Object> response = new HashMap<>();
        response.put("orderReference", orderReference);
        response.put("orderStatus", ctx.getOrderStatus());
        response.put("dispatchId", ctx.getDispatchId());
        response.put("history", ctx.getStatusHistory() != null ? ctx.getStatusHistory() : java.util.List.of());
        return ResponseEntity.ok(response);
    }

    @GetMapping("/{orderReference}/proof-of-delivery")
    @Operation(summary = "Get proof of delivery")
    public ResponseEntity<Map<String, Object>> getProofOfDelivery(
            @PathVariable String orderReference) {

        DispatchContextDto ctx = dispatchContextCache.getByOrderReference(orderReference);
        if (ctx == null) {
            return ResponseEntity.notFound().build();
        }
        Map<String, Object> response = new HashMap<>();
        response.put("orderReference", orderReference);
        response.put("isDelivered", ctx.isHasProofOfDelivery());
        response.put("deliveredDate", ctx.getDeliveredAt());
        response.put("availableForDownload", ctx.getProofOfDelivery() != null
                ? Boolean.TRUE.equals(ctx.getProofOfDelivery().getAvailableForDownload())
                : ctx.isHasProofOfDelivery());
        if (ctx.getProofOfDelivery() != null) {
            response.put("proofOfDelivery", ctx.getProofOfDelivery());
        }
        return ResponseEntity.ok(response);
    }

    // ── Private ───────────────────────────────────────────────────────────────

    private Map<String, Object> buildBaseResponse(DispatchContextDto ctx) {
        Map<String, Object> response = new HashMap<>();
        response.put("orderReference", ctx.getOrderReference());
        response.put("orderStatus", ctx.getOrderStatus());
        response.put("shipmentType", ctx.getShipmentType());
        response.put("orderDate", ctx.getOrderDate());
        response.put("deliveryDate", ctx.getDeliveryDate());
        response.put("customerName", ctx.getCustomerName());
        response.put("billTo", ctx.getBillTo());
        response.put("lastUpdated", LocalDateTime.now());
        return response;
    }
}
