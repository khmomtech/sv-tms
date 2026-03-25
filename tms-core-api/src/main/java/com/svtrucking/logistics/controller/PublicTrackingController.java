package com.svtrucking.logistics.controller;

import com.svtrucking.logistics.core.ApiResponse;
import com.svtrucking.logistics.exception.ResourceNotFoundException;
import com.svtrucking.logistics.model.Dispatch;
import com.svtrucking.logistics.model.DispatchStatusHistory;
import com.svtrucking.logistics.model.TransportOrder;
import com.svtrucking.logistics.repository.DispatchRepository;
import com.svtrucking.logistics.repository.DispatchStatusHistoryRepository;
import com.svtrucking.logistics.repository.TransportOrderRepository;
import com.svtrucking.logistics.service.TelematicsProxyService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.Parameter;
import io.swagger.v3.oas.annotations.tags.Tag;
import java.time.LocalDateTime;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

/**
 * Public Shipment Tracking API
 * No authentication required. Customers can track shipments using their order reference.
 * 
 * Endpoints:
 * - GET /api/public/tracking/{orderReference}
 * - GET /api/public/tracking/{orderReference}/location
 * - GET /api/public/tracking/{orderReference}/history
 * - GET /api/public/tracking/{orderReference}/proof-of-delivery
 */
@RestController
@RequestMapping("/api/public/tracking")
@Tag(name = "Public Tracking", description = "Public shipment tracking endpoints (no authentication required)")
public class PublicTrackingController {

  private final TransportOrderRepository transportOrderRepository;
  private final DispatchRepository dispatchRepository;
  private final DispatchStatusHistoryRepository dispatchStatusHistoryRepository;
  private final TelematicsProxyService telematicsProxy;

  public PublicTrackingController(
      TransportOrderRepository transportOrderRepository,
      DispatchRepository dispatchRepository,
      DispatchStatusHistoryRepository dispatchStatusHistoryRepository,
      TelematicsProxyService telematicsProxy) {
    this.transportOrderRepository = transportOrderRepository;
    this.dispatchRepository = dispatchRepository;
    this.dispatchStatusHistoryRepository = dispatchStatusHistoryRepository;
    this.telematicsProxy = telematicsProxy;
  }

  /**
   * Track shipment by order reference (BK-YYYY-XXXXX format)
   * @param orderReference - Transport order reference (e.g., BK-2026-00125)
   * @return Shipment tracking response with current status and details
   */
  @GetMapping("/{orderReference}")
  @Operation(
      summary = "Get shipment tracking information",
      description = "Retrieve current tracking status, driver info, and shipment details by order reference")
    @org.springframework.transaction.annotation.Transactional(readOnly = true)
    public ResponseEntity<ApiResponse<Map<String, Object>>> trackShipment(
      @PathVariable @Parameter(description = "Order reference (e.g., BK-2026-00125)")
          String orderReference) {
    if (telematicsProxy.isForwardingEnabled()) {
      return (ResponseEntity<ApiResponse<Map<String, Object>>>) (ResponseEntity<?>) telematicsProxy.forwardGet(
          "/api/public/tracking/" + orderReference, null);
    }
    
    // Find TransportOrder by reference
    TransportOrder order =
        transportOrderRepository
            .findWithCustomerByOrderReferenceIgnoreCase(orderReference)
            .orElseThrow(
                () ->
                    new ResourceNotFoundException(
                        String.format("Order not found with reference: %s", orderReference)));

    // Find associated Dispatch (may have multiple, get the latest/active one)
    Dispatch dispatch =
        dispatchRepository
            .findByTransportOrderOrderByCreatedDateDesc(order)
            .stream()
            .findFirst()
            .orElse(null);

    // Build response
    Map<String, Object> response = new HashMap<>();
    response.put("orderReference", order.getOrderReference());
    response.put("orderStatus", order.getStatus() != null ? order.getStatus().toString() : "UNKNOWN");
    response.put("shipmentType", order.getShipmentType());
    response.put("orderDate", order.getOrderDate());
    response.put("deliveryDate", order.getDeliveryDate());
    response.put("customerName", order.getCustomer() != null ? order.getCustomer().getName() : null);
    response.put("billTo", order.getBillTo());
    response.put("lastUpdated", LocalDateTime.now());

    // Unified stops list from transport order to avoid duplication
    if (order.getStops() != null && !order.getStops().isEmpty()) {
      // Map stops and deduplicate by (type + address + coords)
      Map<String, Map<String, Object>> unique = new java.util.LinkedHashMap<>();
      order.getStops().stream()
          .sorted((a, b) -> Integer.compare(a.getSequence() != null ? a.getSequence() : Integer.MAX_VALUE,
                                            b.getSequence() != null ? b.getSequence() : Integer.MAX_VALUE))
          .forEach(stop -> {
            Map<String, Object> s = new HashMap<>();
            s.put("type", stop.getType() != null ? stop.getType().toString() : null); // PICKUP or DROP
            s.put("sequence", stop.getSequence());
            s.put("eta", stop.getEta());
            s.put("arrivalTime", stop.getArrivalTime());
            s.put("departureTime", stop.getDepartureTime());
            s.put("remarks", stop.getRemarks());
            s.put("proofImageUrl", stop.getProofImageUrl());
            s.put("confirmedBy", stop.getConfirmedBy());
            s.put("contactPhone", stop.getContactPhone());
            String name = null, address = null; Double lat = null, lon = null;
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
      response.put("stops", new java.util.ArrayList<>(unique.values()));
    }

    if (dispatch != null) {
      Map<String, Object> dispatchInfo = new HashMap<>();
      dispatchInfo.put("id", dispatch.getId());
      dispatchInfo.put("routeCode", dispatch.getRouteCode());
      dispatchInfo.put("trackingNo", dispatch.getTrackingNo());
      dispatchInfo.put("status", dispatch.getStatus() != null ? dispatch.getStatus().toString() : "UNKNOWN");
      dispatchInfo.put("estimatedArrival", dispatch.getEstimatedArrival());
      dispatchInfo.put("startTime", dispatch.getStartTime());
      // Use dispatch locations only; stops provide detailed addresses
      dispatchInfo.put("fromLocation",
        dispatch.getFromLocation() != null && !dispatch.getFromLocation().isEmpty()
          ? dispatch.getFromLocation() : null);
      dispatchInfo.put("toLocation",
        dispatch.getToLocation() != null && !dispatch.getToLocation().isEmpty()
          ? dispatch.getToLocation() : null);
      dispatchInfo.put("createdDate", dispatch.getCreatedDate());
      dispatchInfo.put("updatedDate", dispatch.getUpdatedDate());

      if (dispatch.getDriver() != null) {
        Map<String, Object> driverInfo = new HashMap<>();
        driverInfo.put("id", dispatch.getDriver().getId());
        driverInfo.put("name", dispatch.getDriver().getName());
        driverInfo.put("phone", dispatch.getDriver().getPhone());
        if (dispatch.getVehicle() != null) {
          driverInfo.put("vehicleNumber", dispatch.getVehicle().getLicensePlate());
        }
        dispatchInfo.put("driver", driverInfo);
      }

      response.put("dispatch", dispatchInfo);
    }

    return ResponseEntity.ok(ApiResponse.success("Tracking information retrieved", response));
  }

  /**
   * Get current location of shipment
   * @param orderReference - Transport order reference
   * @return Current GPS location if available
   */
  @GetMapping("/{orderReference}/location")
  @Operation(
      summary = "Get current shipment location",
      description = "Get real-time GPS location of the shipment")
  @org.springframework.transaction.annotation.Transactional(readOnly = true)
  public ResponseEntity<ApiResponse<Map<String, Object>>> getCurrentLocation(
      @PathVariable String orderReference) {
    if (telematicsProxy.isForwardingEnabled()) {
      return (ResponseEntity<ApiResponse<Map<String, Object>>>) (ResponseEntity<?>) telematicsProxy.forwardGet(
          "/api/public/tracking/" + orderReference + "/location", null);
    }
    
    TransportOrder order =
        transportOrderRepository
            .findWithCustomerByOrderReferenceIgnoreCase(orderReference)
            .orElseThrow(
                () ->
                    new ResourceNotFoundException(
                        String.format("Order not found with reference: %s", orderReference)));

    Dispatch dispatch =
        dispatchRepository
            .findByTransportOrderOrderByCreatedDateDesc(order)
            .stream()
            .findFirst()
            .orElse(null);

    Map<String, Object> response = new HashMap<>();
    response.put("orderReference", order.getOrderReference());
    response.put("hasActiveDispatch", dispatch != null);
    response.put("driverAssigned", dispatch != null && dispatch.getDriver() != null);
    response.put("currentStatus", order.getStatus() != null ? order.getStatus().toString() : "UNKNOWN");
    response.put("lastUpdated", dispatch != null ? dispatch.getUpdatedDate() : order.getCreatedAt());

    // Include GPS location if driver is assigned and has location data
    if (dispatch != null && dispatch.getDriver() != null) {
      var driver = dispatch.getDriver();
      var location = driver.getLatestLocation();
      
      if (location != null) {
        Map<String, Object> gpsData = new HashMap<>();
        gpsData.put("latitude", location.getLatitude());
        gpsData.put("longitude", location.getLongitude());
        gpsData.put("accuracy", location.getAccuracyMeters());
        gpsData.put("speed", location.getSpeed());
        gpsData.put("heading", location.getHeading());
        gpsData.put("locationName", location.getLocationName());
        gpsData.put("lastSeen", location.getLastSeen());
        gpsData.put("isOnline", location.getIsOnline());
        
        response.put("location", gpsData);
        response.put("hasLocation", true);
      } else {
        response.put("hasLocation", false);
      }
    } else {
      response.put("hasLocation", false);
    }

    return ResponseEntity.ok(ApiResponse.success("Current location retrieved", response));
  }

  /**
   * Get shipment status history/timeline
   * @param orderReference - Transport order reference
   * @return List of status changes with timestamps
   */
  @GetMapping("/{orderReference}/history")
  @Operation(
      summary = "Get shipment status history",
      description = "Get timeline of all status changes for the shipment")
  public ResponseEntity<ApiResponse<List<Map<String, Object>>>> getStatusHistory(
      @PathVariable String orderReference) {
    if (telematicsProxy.isForwardingEnabled()) {
      return (ResponseEntity<ApiResponse<List<Map<String, Object>>>>) (ResponseEntity<?>) telematicsProxy.forwardGet(
          "/api/public/tracking/" + orderReference + "/history", null);
    }
    
    TransportOrder order =
        transportOrderRepository
            .findWithCustomerByOrderReferenceIgnoreCase(orderReference)
            .orElseThrow(
                () ->
                    new ResourceNotFoundException(
                        String.format("Order not found with reference: %s", orderReference)));

    Dispatch dispatch =
        dispatchRepository
            .findByTransportOrderOrderByCreatedDateDesc(order)
            .stream()
            .findFirst()
            .orElse(null);

    List<Map<String, Object>> history = List.of();
    if (dispatch != null) {
      List<DispatchStatusHistory> statusHistory =
          dispatchStatusHistoryRepository.findByDispatchOrderByUpdatedAtAsc(dispatch);
      history =
          statusHistory.stream()
              .map(sh -> {
                Map<String, Object> item = new HashMap<>();
                item.put("status", sh.getStatus() != null ? sh.getStatus().toString() : "UNKNOWN");
                item.put("timestamp", sh.getUpdatedAt());
                item.put("notes", sh.getRemarks());
                return item;
              })
              .collect(Collectors.toList());
    }

    return ResponseEntity.ok(ApiResponse.success("Status history retrieved", history));
  }

  /**
   * Get proof of delivery
   * @param orderReference - Transport order reference
   * @return Proof of delivery details if available
   */
  @GetMapping("/{orderReference}/proof-of-delivery")
  @Operation(
      summary = "Get proof of delivery",
      description = "Get proof of delivery documentation if shipment is delivered")
  public ResponseEntity<ApiResponse<Map<String, Object>>> getProofOfDelivery(
      @PathVariable String orderReference) {
    if (telematicsProxy.isForwardingEnabled()) {
      return (ResponseEntity<ApiResponse<Map<String, Object>>>) (ResponseEntity<?>) telematicsProxy.forwardGet(
          "/api/public/tracking/" + orderReference + "/proof-of-delivery", null);
    }
    
    TransportOrder order =
        transportOrderRepository
            .findByOrderReferenceIgnoreCase(orderReference)
            .orElseThrow(
                () ->
                    new ResourceNotFoundException(
                        String.format("Order not found with reference: %s", orderReference)));

    Dispatch dispatch =
        dispatchRepository
            .findByTransportOrderOrderByCreatedDateDesc(order)
            .stream()
            .findFirst()
            .orElse(null);

    Map<String, Object> response = new HashMap<>();
    response.put("orderReference", order.getOrderReference());
    response.put("isDelivered", dispatch != null && dispatch.getUnloadProof() != null);
    response.put("deliveredDate", dispatch != null ? dispatch.getUpdatedDate() : null);
    response.put("availableForDownload", dispatch != null && dispatch.getUnloadProof() != null);

    return ResponseEntity.ok(ApiResponse.success("Proof of delivery retrieved", response));
  }
}
