package com.svtrucking.logistics.controller;

import com.svtrucking.logistics.model.Dispatch;
import com.svtrucking.logistics.model.DispatchStatusHistory;
import com.svtrucking.logistics.model.TransportOrder;
import com.svtrucking.logistics.repository.DispatchRepository;
import com.svtrucking.logistics.repository.DispatchStatusHistoryRepository;
import com.svtrucking.logistics.repository.TransportOrderRepository;
import com.svtrucking.logistics.repository.UnloadProofRepository;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.HashMap;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.core.env.Environment;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestHeader;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

/**
 * Internal HTTP endpoints consumed by tms-telematics-api.
 * Guarded by the X-Internal-Api-Key header — not exposed via standard JWT auth.
 *
 * Endpoints:
 * GET /api/internal/telematics/dispatch/by-reference?ref=BK-2026-00125
 * GET /api/internal/telematics/dispatch?driverId=42
 */
@RestController
@RequestMapping("/api/internal/telematics")
@Slf4j
public class InternalTelematicsController {

    private final TransportOrderRepository transportOrderRepository;
    private final DispatchRepository dispatchRepository;
    private final DispatchStatusHistoryRepository dispatchStatusHistoryRepository;
    private final UnloadProofRepository unloadProofRepository;

    @Value("${telematics.internal.api-key:}")
    private String internalApiKey;

    private final boolean prodProfile;

    public InternalTelematicsController(
            TransportOrderRepository transportOrderRepository,
            DispatchRepository dispatchRepository,
            DispatchStatusHistoryRepository dispatchStatusHistoryRepository,
            UnloadProofRepository unloadProofRepository,
            Environment environment) {
        this.transportOrderRepository = transportOrderRepository;
        this.dispatchRepository = dispatchRepository;
        this.dispatchStatusHistoryRepository = dispatchStatusHistoryRepository;
        this.unloadProofRepository = unloadProofRepository;
        this.prodProfile = Arrays.stream(environment.getActiveProfiles())
                .anyMatch(profile -> "prod".equalsIgnoreCase(profile));
    }

    /**
     * Returns dispatch context by order reference.
     * Used by tms-telematics-api PublicTrackingController via
     * DispatchContextCacheService.
     */
    @GetMapping("/dispatch/by-reference")
    @org.springframework.transaction.annotation.Transactional(readOnly = true)
    public ResponseEntity<?> getDispatchByReference(
            @RequestHeader(value = "X-Internal-Api-Key", required = false) String apiKey,
            @RequestParam("ref") String orderRef) {

        if (!isAuthorized(apiKey)) {
            log.warn("[internal-telematics] Unauthorized attempt to access /dispatch/by-reference");
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED).build();
        }

        TransportOrder order = transportOrderRepository
                .findWithCustomerByOrderReferenceIgnoreCase(orderRef)
                .orElse(null);
        if (order == null) {
            return ResponseEntity.notFound().build();
        }

        Dispatch dispatch = dispatchRepository
                .findByTransportOrderOrderByCreatedDateDesc(order)
                .stream().findFirst().orElse(null);

        Map<String, Object> ctx = new HashMap<>();
        ctx.put("orderReference", order.getOrderReference());
        ctx.put("orderStatus", order.getStatus() != null ? order.getStatus().toString() : "UNKNOWN");
        ctx.put("shipmentType", order.getShipmentType());
        ctx.put("orderDate", order.getOrderDate());
        ctx.put("deliveryDate", order.getDeliveryDate());
        ctx.put("customerName", order.getCustomer() != null ? order.getCustomer().getName() : null);
        ctx.put("billTo", order.getBillTo());

        if (dispatch != null) {
            ctx.put("dispatchId", dispatch.getId());
            ctx.put("routeCode", dispatch.getRouteCode());
            ctx.put("trackingNo", dispatch.getTrackingNo());
            ctx.put("dispatchStatus",
                    dispatch.getStatus() != null ? dispatch.getStatus().toString() : "UNKNOWN");
            ctx.put("estimatedArrival", dispatch.getEstimatedArrival());
            ctx.put("startTime", dispatch.getStartTime());
            ctx.put("fromLocation", dispatch.getFromLocation());
            ctx.put("toLocation", dispatch.getToLocation());
            ctx.put("hasProofOfDelivery", dispatch.getUnloadProof() != null);
            ctx.put("deliveredAt", dispatch.getUpdatedDate());
            ctx.put("statusHistory", buildStatusHistory(dispatch));
            ctx.put("proofOfDelivery", buildProofOfDelivery(dispatch));

            if (dispatch.getDriver() != null) {
                ctx.put("driverId", dispatch.getDriver().getId());
                ctx.put("driverName", dispatch.getDriver().getName());
                ctx.put("driverPhone", dispatch.getDriver().getPhone());
            }
            if (dispatch.getVehicle() != null) {
                ctx.put("vehiclePlate", dispatch.getVehicle().getLicensePlate());
            }
        }

        // Build stops from transport order (same logic as PublicTrackingController)
        if (order.getStops() != null && !order.getStops().isEmpty()) {
            Map<String, Map<String, Object>> unique = new LinkedHashMap<>();
            order.getStops().stream()
                    .sorted((a, b) -> Integer.compare(
                            a.getSequence() != null ? a.getSequence() : Integer.MAX_VALUE,
                            b.getSequence() != null ? b.getSequence() : Integer.MAX_VALUE))
                    .forEach(stop -> {
                        Map<String, Object> s = new HashMap<>();
                        s.put("type", stop.getType() != null ? stop.getType().toString() : null);
                        s.put("sequence", stop.getSequence());
                        s.put("eta", stop.getEta());
                        s.put("arrivalTime", stop.getArrivalTime());
                        s.put("departureTime", stop.getDepartureTime());
                        s.put("remarks", stop.getRemarks());
                        s.put("proofImageUrl", stop.getProofImageUrl());
                        s.put("confirmedBy", stop.getConfirmedBy());
                        s.put("contactPhone", stop.getContactPhone());

                        String name = null, address = null;
                        Double lat = null, lon = null;
                        if (stop.getAddress() != null) {
                            Map<String, Object> addr = new HashMap<>();
                            name = stop.getAddress().getName();
                            address = stop.getAddress().getAddress();
                            addr.put("name", name);
                            addr.put("address", address);
                            addr.put("city", stop.getAddress().getCity());
                            addr.put("country", stop.getAddress().getCountry());
                            addr.put("postcode", stop.getAddress().getPostcode());
                            lat = stop.getAddress().getLatitude();
                            lon = stop.getAddress().getLongitude();
                            addr.put("latitude", lat);
                            addr.put("longitude", lon);
                            s.put("address", addr);
                        }
                        String key = String.format("%s|%s|%s|%s|%s",
                                s.get("type"),
                                name != null ? name.trim().toLowerCase() : "",
                                address != null ? address.trim().toLowerCase() : "",
                                lat != null ? lat : 0.0,
                                lon != null ? lon : 0.0);
                        unique.putIfAbsent(key, s);
                    });
            ctx.put("stops", new ArrayList<>(unique.values()));
        } else {
            ctx.put("stops", List.of());
        }

        return ResponseEntity.ok(ctx);
    }

    /**
     * Returns the current active dispatch for a given driverId.
     * Used by tms-telematics-api LocationIngestService dispatch resolution.
     */
    @GetMapping("/dispatch")
    @org.springframework.transaction.annotation.Transactional(readOnly = true)
    public ResponseEntity<?> getDispatchForDriver(
            @RequestHeader(value = "X-Internal-Api-Key", required = false) String apiKey,
            @RequestParam("driverId") Long driverId) {

        if (!isAuthorized(apiKey)) {
            log.warn("[internal-telematics] Unauthorized attempt to access /dispatch?driverId={}", driverId);
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED).build();
        }

        List<Dispatch> active = dispatchRepository.findByDriverIdAndStatusIn(
                driverId,
                java.util.EnumSet.of(
                        com.svtrucking.logistics.enums.DispatchStatus.ASSIGNED,
                        com.svtrucking.logistics.enums.DispatchStatus.DRIVER_CONFIRMED,
                        com.svtrucking.logistics.enums.DispatchStatus.IN_TRANSIT,
                        com.svtrucking.logistics.enums.DispatchStatus.IN_QUEUE,
                        com.svtrucking.logistics.enums.DispatchStatus.SAFETY_PASSED));

        if (active.isEmpty()) {
            return ResponseEntity.ok(Map.of("driverId", driverId, "dispatchId", (Object) null));
        }

        Dispatch d = active.get(0);
        Map<String, Object> result = new HashMap<>();
        result.put("driverId", driverId);
        result.put("dispatchId", d.getId());
        result.put("dispatchStatus", d.getStatus() != null ? d.getStatus().toString() : null);
        result.put("orderReference",
                d.getTransportOrder() != null ? d.getTransportOrder().getOrderReference() : null);
        result.put("vehiclePlate",
                d.getVehicle() != null ? d.getVehicle().getLicensePlate() : null);
        return ResponseEntity.ok(result);
    }

    private boolean isAuthorized(String providedKey) {
        if (internalApiKey == null || internalApiKey.isBlank()) {
            if (prodProfile) {
                log.error("[internal-telematics] TELEMATICS_INTERNAL_API_KEY not configured in prod");
                return false;
            }
            log.warn("[internal-telematics] TELEMATICS_INTERNAL_API_KEY not configured — allowing outside prod");
            return true;
        }
        return internalApiKey.equals(providedKey);
    }

    private List<Map<String, Object>> buildStatusHistory(Dispatch dispatch) {
        List<DispatchStatusHistory> statusHistory = dispatchStatusHistoryRepository
                .findByDispatchOrderByUpdatedAtAsc(dispatch);
        return statusHistory.stream().map(history -> {
            Map<String, Object> item = new HashMap<>();
            item.put("status", history.getStatus() != null ? history.getStatus().toString() : "UNKNOWN");
            item.put("timestamp", history.getUpdatedAt());
            item.put("notes", history.getRemarks());
            item.put("updatedBy", history.getUpdatedBy());
            item.put("source", history.getSource() != null ? history.getSource().toString() : null);
            return item;
        }).toList();
    }

    private Map<String, Object> buildProofOfDelivery(Dispatch dispatch) {
        return unloadProofRepository.findFirstByDispatchIdOrderBySubmittedAtDescIdDesc(dispatch.getId())
                .map(proof -> {
                    Map<String, Object> payload = new HashMap<>();
                    payload.put("id", proof.getId());
                    payload.put("dispatchId", dispatch.getId());
                    payload.put("remarks", proof.getRemarks());
                    payload.put("address", proof.getAddress());
                    payload.put("latitude", proof.getLatitude());
                    payload.put("longitude", proof.getLongitude());
                    payload.put("proofImagePaths",
                            proof.getProofImagePaths() != null ? List.copyOf(proof.getProofImagePaths()) : List.of());
                    payload.put("signaturePath", proof.getSignaturePath());
                    payload.put("submittedAt", proof.getSubmittedAt());
                    payload.put("availableForDownload", true);
                    payload.put("delivered", true);
                    return payload;
                })
                .orElse(null);
    }
}
