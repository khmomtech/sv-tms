package com.svtrucking.logistics.dto;

import com.fasterxml.jackson.annotation.JsonInclude;
import com.svtrucking.logistics.enums.DispatchStatus;
import com.svtrucking.logistics.enums.StopType;
import java.time.LocalDateTime;
import java.util.List;
import java.util.Comparator;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

/**
 * Slim driver-facing dispatch DTO to avoid recursive payloads and null-heavy fields.
 */
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
@JsonInclude(JsonInclude.Include.NON_NULL)
public class DriverDispatchDto {
  private Long id;
  private String routeCode;
  private DispatchStatus status;
  private String tripType;
  private LocalDateTime startTime;
  private LocalDateTime estimatedArrival;
  private LocalDateTime expectedDelivery;
  private LocalDateTime deliveryDate;

  private Long transportOrderId;
  private String orderReference;

  private Summary customer;
  private Summary driver;
  private VehicleSummary vehicle;
  private Summary createdBy;
  private LocationSummary from;
  private LocationSummary to;

  private List<DispatchStopDto> stops;
  private List<DispatchItemDto> items;

  private ProofSummary loadProof;
  private ProofSummary unloadProof;

  private LocalDateTime createdAt;
  private LocalDateTime updatedAt;

  public static DriverDispatchDto from(DispatchDto dto) {
    if (dto == null) return null;

    LocalDateTime delivery = null;
    if (dto.getTransportOrder() != null && dto.getTransportOrder().getDeliveryDate() != null) {
      delivery = dto.getTransportOrder().getDeliveryDate().atStartOfDay();
    } else {
      delivery = dto.getEstimatedArrival();
    }

    return DriverDispatchDto.builder()
        .id(dto.getId())
        .routeCode(dto.getRouteCode())
        .status(dto.getStatus())
        .tripType(dto.getTripType())
        .startTime(dto.getStartTime())
        .estimatedArrival(dto.getEstimatedArrival())
        .expectedDelivery(dto.getEstimatedArrival())
        .deliveryDate(delivery)
        .transportOrderId(dto.getTransportOrderId())
        .orderReference(dto.getOrderReference())
        .customer(
            (dto.getCustomerId() != null || dto.getCustomerName() != null)
                ? new Summary(dto.getCustomerId(), dto.getCustomerName(), dto.getCustomerPhone())
                : null)
        .driver(
            (dto.getDriverId() != null || dto.getDriverName() != null)
                ? new Summary(dto.getDriverId(), dto.getDriverName(), dto.getDriverPhone())
                : null)
        .vehicle(
            dto.getVehicleId() != null || dto.getLicensePlate() != null
                ? new VehicleSummary(dto.getVehicleId(), dto.getLicensePlate())
                : null)
        .createdBy(
            (dto.getCreatedBy() != null || dto.getCreatedByUsername() != null)
                ? new Summary(dto.getCreatedBy(), dto.getCreatedByUsername(), null)
                : null)
        .stops(dto.getStops())
        .items(dto.getItems())
        .loadProof(ProofSummary.fromLoad(dto.getLoadProof()))
        .unloadProof(ProofSummary.fromUnload(dto.getUnloadProof()))
        .createdAt(dto.getCreatedDate())
        .updatedAt(dto.getUpdatedDate())
        .from(
            fallbackLocation(
                deriveLocation(dto.getTransportOrder(), StopType.PICKUP),
                dto.getFrom(),
                dto.getPickupLocation(),
                dto.getEstimatedArrival()))
        .to(
            fallbackLocation(
                deriveLocation(dto.getTransportOrder(), StopType.DROP),
                dto.getTo(),
                dto.getDropoffLocation(),
                dto.getEstimatedArrival()))
        .build();
  }

  private static LocationSummary deriveLocation(TransportOrderDto order, StopType type) {
    if (order == null) return null;

    // Prefer multi-stop stops if provided
    if (order.getStops() != null && !order.getStops().isEmpty()) {
      return order.getStops().stream()
          .filter(s -> s != null && s.getType() == type)
          .sorted(Comparator.comparing(OrderStopDto::getSequence))
          .findFirst()
          .map(
              s ->
                  LocationSummary.builder()
                      .name(s.getAddress() != null ? s.getAddress().getName() : null)
                      .address(s.getAddress() != null ? s.getAddress().getAddress() : null)
                      .latitude(
                          s.getAddress() != null ? s.getAddress().getLatitude() : null)
                      .longitude(
                          s.getAddress() != null ? s.getAddress().getLongitude() : null)
                      .eta(s.getEta())
                      .build())
          .orElse(null);
    }

    // Fallback to single pickup/drop addresses
    if (type == StopType.PICKUP && order.getPickupAddress() != null) {
      var a = order.getPickupAddress();
      return LocationSummary.builder()
          .name(a.getName())
          .address(a.getAddress())
          .latitude(a.getLatitude())
          .longitude(a.getLongitude())
          .build();
    }
    if (type == StopType.DROP && order.getDropAddress() != null) {
      var a = order.getDropAddress();
      return LocationSummary.builder()
          .name(a.getName())
          .address(a.getAddress())
          .latitude(a.getLatitude())
          .longitude(a.getLongitude())
          .build();
    }
    return null;
  }

  private static LocationSummary fallbackLocation(
      LocationSummary primary, String name, String address, LocalDateTime eta) {
    if (primary != null) return primary;
    if ((name == null || name.isBlank()) && (address == null || address.isBlank())) {
      return null;
    }
    return LocationSummary.builder()
        .name(name)
        .address(address)
        .eta(eta)
        .build();
  }

  @Getter
  @Setter
  @NoArgsConstructor
  @AllArgsConstructor
  @Builder
  @JsonInclude(JsonInclude.Include.NON_NULL)
  public static class Summary {
    private Long id;
    private String name;
    private String phone;
  }

  @Getter
  @Setter
  @NoArgsConstructor
  @AllArgsConstructor
  @Builder
  @JsonInclude(JsonInclude.Include.NON_NULL)
  public static class VehicleSummary {
    private Long id;
    private String licensePlate;
  }

  @Getter
  @Setter
  @NoArgsConstructor
  @AllArgsConstructor
  @Builder
  @JsonInclude(JsonInclude.Include.NON_NULL)
  public static class ProofSummary {
    private Long id;
    private String remarks;
    private String address;
    private Double latitude;
    private Double longitude;
    private List<String> imageUrls;
    private String signatureUrl;
    private LocalDateTime submittedAt;

    public static ProofSummary fromLoad(LoadProofDto load) {
      if (load == null) return null;
      return ProofSummary.builder()
          .id(load.getId())
          .remarks(load.getRemarks())
          .imageUrls(load.getImageUrls())
          .signatureUrl(load.getSignatureUrl())
          .build();
    }

    public static ProofSummary fromUnload(UnloadProofDto unload) {
      if (unload == null) return null;
      return ProofSummary.builder()
          .id(unload.getId())
          .remarks(unload.getRemarks())
          .address(unload.getAddress())
          .latitude(unload.getLatitude())
          .longitude(unload.getLongitude())
          .imageUrls(unload.getImageUrls())
          .signatureUrl(unload.getSignatureUrl())
          .submittedAt(unload.getSubmittedAt())
          .build();
    }
  }

  @Getter
  @Setter
  @NoArgsConstructor
  @AllArgsConstructor
  @Builder
  @JsonInclude(JsonInclude.Include.NON_NULL)
  public static class LocationSummary {
    private String name;
    private String address;
    private Double latitude;
    private Double longitude;
    private LocalDateTime eta;
  }
}
