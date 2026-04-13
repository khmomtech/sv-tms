package com.svtrucking.logistics.dto;

import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import com.svtrucking.logistics.enums.DispatchStatus;
import com.svtrucking.logistics.enums.PreEntrySafetyStatus;
import com.svtrucking.logistics.enums.SafetyCheckStatus;
import com.svtrucking.logistics.model.Dispatch;
import jakarta.persistence.EntityNotFoundException;
import org.hibernate.Hibernate;
import org.hibernate.HibernateException;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.List;
import java.util.Optional;
import java.util.stream.Collectors;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
@JsonIgnoreProperties(ignoreUnknown = true)
public class DispatchDto {
  private Long id;
  private String routeCode;

  private LocalDateTime startTime;
  private LocalDateTime estimatedArrival;
  private DispatchStatus status;
  private SafetyCheckStatus safetyStatus;
  private Boolean preEntrySafetyRequired;
  private PreEntrySafetyStatus preEntrySafetyStatus;
  private String tripType;
  private String loadingTypeCode;
  private Long workflowVersionId;
  private Boolean podRequired;
  private Boolean podSubmitted;
  private LocalDateTime podSubmittedAt;
  private Boolean podVerified;

  // Transport Order Details
  private Long transportOrderId;
  private String orderReference;
  private TransportOrderDto transportOrder;

  // Customer Info (Short)
  private Long customerId;
  private String customerName;
  private String customerPhone;

  // Pickup Info
  private String pickupName;
  private String pickupLocation;
  private Double pickupLat;
  private Double pickupLng;

  // Drop-off Info
  private String dropoffName;
  private String dropoffLocation;
  private Double dropoffLat;
  private Double dropoffLng;

  // Legacy/flattened labels for UI (avoid [object Object])
  private String from;
  private String to;

  // Assigned Driver
  private Long driverId;
  private String driverName;
  private String driverPhone;

  // Assigned Vehicle
  private Long vehicleId;
  private String licensePlate;

  // Optional manual route code provided by client
  private String manualRouteCode;

  // Created By User
  private Long createdBy;
  private String createdByUsername;

  // Timestamps
  private LocalDateTime createdDate;
  private LocalDateTime updatedDate;
  private String cancelReason;

  // Stops and Items
  private List<DispatchStopDto> stops;
  private List<DispatchItemDto> items;

  // Load & Unload Proofs
  private LoadProofDto loadProof;
  private UnloadProofDto unloadProof;

  // Flattened proof data for UI
  private List<String> loadingProofImages;
  private String loadingSignature;
  private List<String> unloadingProofImages;
  private String unloadingSignature;

  public LocalDateTime getExpectedDelivery() {
    return estimatedArrival;
  }

  public static DispatchDto fromEntity(Dispatch dispatch) {
    if (dispatch == null) return null;

    return DispatchDto.builder()
        .id(dispatch.getId())
        .routeCode(dispatch.getRouteCode())
        .startTime(dispatch.getStartTime())
        .estimatedArrival(dispatch.getEstimatedArrival())
        .status(dispatch.getStatus())
        .tripType(dispatch.getTripType())
        .loadingTypeCode(dispatch.getLoadingTypeCode())
        .workflowVersionId(dispatch.getWorkflowVersionId())
        .safetyStatus(dispatch.getSafetyStatus())
        .preEntrySafetyRequired(Boolean.TRUE.equals(dispatch.getPreEntrySafetyRequired()))
        .preEntrySafetyStatus(dispatch.getPreEntrySafetyStatus())
        .podRequired(Boolean.TRUE.equals(dispatch.getPodRequired()))
        .podSubmitted(Boolean.TRUE.equals(dispatch.getPodSubmitted()))
        .podSubmittedAt(dispatch.getPodSubmittedAt())
        .podVerified(Boolean.TRUE.equals(dispatch.getPodVerified()))
        .transportOrderId(getSafeTransportOrderId(dispatch))
        .orderReference(
            getSafeTransportOrderReference(dispatch) != null
                ? getSafeTransportOrderReference(dispatch)
                : dispatch.getTrackingNo())
        .manualRouteCode(dispatch.getRouteCode())
        .pickupLocation(dispatch.getFromLocation())
        .dropoffLocation(dispatch.getToLocation())
        .from(dispatch.getFromLocation())
        .to(dispatch.getToLocation())
        .driverId(getSafeDriverId(dispatch))
        .driverName(getSafeDriverName(dispatch))
        .driverPhone(getSafeDriverPhone(dispatch))
        .vehicleId(getSafeVehicleId(dispatch))
        .licensePlate(getSafeVehicleLicensePlate(dispatch))
        .createdBy(getSafeCreatedById(dispatch))
        .createdByUsername(getSafeCreatedByUsername(dispatch))
        .createdDate(dispatch.getCreatedDate())
        .updatedDate(dispatch.getUpdatedDate())
        .cancelReason(dispatch.getCancelReason())
        .stops(mapStopsSafely(dispatch))
        .items(mapItemsSafely(dispatch))
        .build();
  }

  public static DispatchDto fromEntityWithDetails(Dispatch dispatch) {
    DispatchDto dto = fromEntity(dispatch);
    if (dispatch.getTransportOrder() != null) {
      TransportOrderDto orderDto = TransportOrderDto.fromEntity(dispatch.getTransportOrder());
      dto.setTransportOrder(orderDto);
      dto.setTransportOrderId(orderDto != null ? orderDto.getId() : null);

      // Resolve primary pickup/drop using stops when available, otherwise header addresses
      var pickupAddr =
          orderDto != null
              ? Optional.ofNullable(orderDto.primaryPickupFromStops())
                  .orElse(orderDto.getPickupAddress())
              : null;
      var dropAddr =
          orderDto != null
              ? Optional.ofNullable(orderDto.primaryDropFromStops())
                  .orElse(orderDto.getDropAddress())
              : null;

      // Pickup Address
      try {
        if (pickupAddr != null) {
          var pickup = pickupAddr;
          dto.setPickupName(pickup.getName());
          dto.setPickupLocation(pickup.getAddress());
          dto.setPickupLat(pickup.getLatitude());
          dto.setPickupLng(pickup.getLongitude());
          dto.setFrom(
              pickup.getName() != null && !pickup.getName().isBlank()
                  ? pickup.getName()
                  : pickup.getAddress());
        }
      } catch (EntityNotFoundException | org.hibernate.ObjectNotFoundException ex) {
        dto.setPickupLocation("Pickup address not found");
      }

      // Drop-off Address
      try {
        if (dropAddr != null) {
          var drop = dropAddr;
          dto.setDropoffName(drop.getName());
          dto.setDropoffLocation(drop.getAddress());
          dto.setDropoffLat(drop.getLatitude());
          dto.setDropoffLng(drop.getLongitude());
          dto.setTo(
              drop.getName() != null && !drop.getName().isBlank()
                  ? drop.getName()
                  : drop.getAddress());
        }
      } catch (EntityNotFoundException | org.hibernate.ObjectNotFoundException ex) {
        dto.setDropoffLocation("Dropoff address not found");
      }

      // Customer Info
      try {
        if (dispatch.getTransportOrder().getCustomer() != null) {
          var customer = dispatch.getTransportOrder().getCustomer();
          dto.setCustomerId(customer.getId());
          dto.setCustomerName(customer.getName());
          dto.setCustomerPhone(customer.getPhone());
        }
      } catch (EntityNotFoundException | org.hibernate.ObjectNotFoundException ex) {
          dto.setCustomerName("Customer not found");
      }

      // Fallback stops from the transport order DTO if dispatch has none
      if ((dto.getStops() == null || dto.getStops().isEmpty()) && orderDto != null) {
        List<DispatchStopDto> fallbackStops = orderDto.toDispatchStops();
        if (!fallbackStops.isEmpty()) {
          dto.setStops(fallbackStops);
          // Derive from/to labels from stops when missing
          if (dto.getFrom() == null && !fallbackStops.isEmpty()) {
            dto.setFrom(fallbackStops.getFirst().getLocationName());
          }
          if (dto.getTo() == null && fallbackStops.size() > 1) {
            dto.setTo(fallbackStops.getLast().getLocationName());
          }
        }
      }

      // Deduplicate stops (addressId + type + sequence) to avoid duplicate rows in payload
      if (dto.getStops() != null && !dto.getStops().isEmpty()) {
        dto.setStops(dedupeStops(dto.getStops()));
        // Derive from/to from stops if still missing
        if (dto.getFrom() == null || dto.getFrom().isBlank()) {
          dto.setFrom(resolveFromLabel(dto.getStops(), true));
        }
        if (dto.getTo() == null || dto.getTo().isBlank()) {
          dto.setTo(resolveFromLabel(dto.getStops(), false));
        }
      }

      // Final fallback: use transport order stops directly if from/to still blank
      if (orderDto != null && (dto.getFrom() == null || dto.getFrom().isBlank())) {
        dto.setFrom(resolveOrderStopLabel(orderDto.getStops(), true));
      }
      if (orderDto != null && (dto.getTo() == null || dto.getTo().isBlank())) {
        dto.setTo(resolveOrderStopLabel(orderDto.getStops(), false));
      }
    }

    try {
      if (dispatch.getLoadProof() != null) {
        LoadProofDto loadProof = LoadProofDto.fromEntity(dispatch.getLoadProof());
        dto.setLoadProof(loadProof);
        dto.setLoadingProofImages(
            loadProof != null && loadProof.getProofImagePaths() != null
                ? new ArrayList<>(loadProof.getProofImagePaths())
                : new ArrayList<>());
        dto.setLoadingSignature(loadProof != null ? loadProof.getSignaturePath() : null);
      }

      if (dispatch.getUnloadProof() != null) {
        UnloadProofDto unloadProof = UnloadProofDto.fromEntity(dispatch.getUnloadProof());
        dto.setUnloadProof(unloadProof);
        dto.setUnloadingProofImages(
            unloadProof != null && unloadProof.getProofImagePaths() != null
                ? new ArrayList<>(unloadProof.getProofImagePaths())
                : new ArrayList<>());
        dto.setUnloadingSignature(unloadProof != null ? unloadProof.getSignaturePath() : null);
      }
    } catch (EntityNotFoundException | HibernateException ignore) {
      // lazy-loaded proof went missing; skip populating proof data.
    }

    return dto;
  }

  public static Dispatch toEntity(DispatchDto dto) {
    if (dto == null) return null;

    return Dispatch.builder()
        .id(dto.getId())
        .routeCode(dto.getRouteCode())
        .startTime(dto.getStartTime())
        .estimatedArrival(dto.getEstimatedArrival())
        .status(dto.getStatus())
        .safetyStatus(dto.getSafetyStatus())
        .preEntrySafetyRequired(Boolean.TRUE.equals(dto.getPreEntrySafetyRequired()))
        .preEntrySafetyStatus(dto.getPreEntrySafetyStatus())
        .tripType(dto.getTripType())
        .createdDate(dto.getCreatedDate())
        .updatedDate(dto.getUpdatedDate())
        .build();
  }

  private static Long getSafeTransportOrderId(Dispatch dispatch) {
    if (dispatch == null) return null;
    try {
      var to = initializeIfNeeded(dispatch.getTransportOrder());
      if (to == null) return null;
      return to.getId();
    } catch (Exception ex) {
      return null;
    }
  }

  private static String getSafeTransportOrderReference(Dispatch dispatch) {
    if (dispatch == null) return null;
    try {
      var to = initializeIfNeeded(dispatch.getTransportOrder());
      if (to == null) return null;
      return to.getOrderReference();
    } catch (Exception ex) {
      return null;
    }
  }

  private static Long getSafeDriverId(Dispatch dispatch) {
    if (dispatch == null) return null;
    try {
      var d = initializeIfNeeded(dispatch.getDriver());
      if (d == null) return null;
      return d.getId();
    } catch (Exception ex) {
      return null;
    }
  }

  private static String getSafeDriverName(Dispatch dispatch) {
    if (dispatch == null) return null;
    try {
      var d = initializeIfNeeded(dispatch.getDriver());
      if (d == null) return null;
      return d.getName();
    } catch (Exception ex) {
      return null;
    }
  }

  private static String getSafeDriverPhone(Dispatch dispatch) {
    if (dispatch == null) return null;
    try {
      var d = initializeIfNeeded(dispatch.getDriver());
      if (d == null) return null;
      return d.getPhone();
    } catch (Exception ex) {
      return null;
    }
  }

  private static Long getSafeVehicleId(Dispatch dispatch) {
    if (dispatch == null) return null;
    try {
      var v = initializeIfNeeded(dispatch.getVehicle());
      if (v == null) return null;
      return v.getId();
    } catch (Exception ex) {
      return null;
    }
  }

  private static String getSafeVehicleLicensePlate(Dispatch dispatch) {
    if (dispatch == null) return null;
    try {
      var v = initializeIfNeeded(dispatch.getVehicle());
      if (v == null) return null;
      return v.getLicensePlate();
    } catch (Exception ex) {
      return null;
    }
  }

  private static Long getSafeCreatedById(Dispatch dispatch) {
    if (dispatch == null) return null;
    try {
      var u = initializeIfNeeded(dispatch.getCreatedBy());
      if (u == null) return null;
      return u.getId();
    } catch (Exception ex) {
      return null;
    }
  }

  private static String getSafeCreatedByUsername(Dispatch dispatch) {
    if (dispatch == null) return null;
    try {
      var u = initializeIfNeeded(dispatch.getCreatedBy());
      if (u == null) return null;
      return u.getUsername();
    } catch (Exception ex) {
      return null;
    }
  }

  private static <T> T initializeIfNeeded(T proxy) {
    if (proxy == null) return null;
    if (!Hibernate.isInitialized(proxy)) {
      try {
        Hibernate.initialize(proxy); // ensure lazy proxy is loaded so we can read fields
      } catch (Exception ignore) {
        return proxy; // return proxy even if initialization fails to allow id access
      }
    }
    return proxy;
  }

  private static List<DispatchStopDto> mapStopsSafely(Dispatch dispatch) {
    if (dispatch == null) return new ArrayList<>();
    try {
      if (dispatch.getStops() == null) return new ArrayList<>();
      return dispatch.getStops().stream()
          .sorted(
              Comparator.comparing(
                  s -> s.getStopSequence() != null ? s.getStopSequence() : Integer.MAX_VALUE))
          .map(DispatchStopDto::fromEntity)
          .collect(Collectors.toCollection(ArrayList::new));
    } catch (RuntimeException ex) {
      return new ArrayList<>();
    }
  }

  private static List<DispatchItemDto> mapItemsSafely(Dispatch dispatch) {
    if (dispatch == null) return new ArrayList<>();
    try {
      if (dispatch.getItems() == null) return new ArrayList<>();
      return dispatch.getItems().stream()
          .map(DispatchItemDto::fromEntity)
          .collect(Collectors.toCollection(ArrayList::new));
    } catch (RuntimeException ex) {
      return new ArrayList<>();
    }
  }

  private static List<DispatchStopDto> dedupeStops(List<DispatchStopDto> stops) {
    if (stops == null || stops.isEmpty()) return stops;
    var map = new java.util.LinkedHashMap<String, DispatchStopDto>();
    for (DispatchStopDto stop : stops) {
      if (stop == null) continue;
      String loc = stop.getLocationName() != null ? stop.getLocationName() : "";
      String addr = stop.getAddress() != null ? stop.getAddress() : "";
      String seq = stop.getStopSequence() != null ? stop.getStopSequence().toString() : "";
      String key = loc + "|" + addr + "|" + seq;
      map.putIfAbsent(key, stop);
    }
    return new ArrayList<>(map.values());
  }

  private static String resolveFromLabel(List<DispatchStopDto> stops, boolean first) {
    if (stops == null || stops.isEmpty()) return null;
    DispatchStopDto stop = first ? stops.getFirst() : stops.getLast();
    if (stop == null) return null;
    if (stop.getLocationName() != null && !stop.getLocationName().isBlank()) {
      return stop.getLocationName();
    }
    if (stop.getAddress() != null && !stop.getAddress().isBlank()) {
      return stop.getAddress();
    }
    return null;
  }

  private static String resolveOrderStopLabel(List<OrderStopDto> stops, boolean first) {
    if (stops == null || stops.isEmpty()) return null;
    OrderStopDto stop = first ? stops.getFirst() : stops.getLast();
    if (stop == null) return null;
    if (stop.getAddress() != null && stop.getAddress().getName() != null) {
      return stop.getAddress().getName();
    }
    if (stop.getAddress() != null && stop.getAddress().getAddress() != null) {
      return stop.getAddress().getAddress();
    }
    return stop.getType() != null ? stop.getType().name() : null;
  }
}
