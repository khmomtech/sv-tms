package com.svtrucking.logistics.dto;

import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import com.svtrucking.logistics.enums.OrderStatus;
import com.svtrucking.logistics.enums.OrderOrigin;
import com.svtrucking.logistics.model.TransportOrder;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.List;
import java.util.Objects;
import java.util.Optional;
import java.util.stream.Collectors;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

/** DTO for exposing transport order data to frontend or client APIs */
@JsonIgnoreProperties(ignoreUnknown = true)
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class TransportOrderDto {

    private Long id;
    private String orderReference;
    private Long customerId;
    private String customerName;
    private String billTo;
    private LocalDate orderDate;
    private LocalDate deliveryDate;
    private LocalDateTime createDate;
    private String shipmentType;
    private String courierAssigned;
    private String tripNo;
    private String truckNumber;
    private Integer truckTripCount;
    private OrderStatus status;
    private String remark;

    // Order origin and import metadata
    private OrderOrigin origin;
    private Boolean requiresDriver;
    private String sourceReference;

    private Long createdById;
    private String createdByUsername;

    private EmployeeDto seller;

    private List<OrderItemDto> items;

    /** 🧭 Header-level addresses */
    private CustomerAddressDto pickupAddress;

    private CustomerAddressDto dropAddress;

    /** 🧳 Multi-stop level addresses */
    private List<CustomerAddressDto> pickupAddresses;

    private List<CustomerAddressDto> dropAddresses;

    /** Dispatch records */
    private List<DispatchDto> dispatches;

    /** 💰 Invoice record */
    private InvoiceDto invoice;

    /** 🧭 NEW: Multi-stop support (arrival/eta/etc.) */
    private List<OrderStopDto> stops;

    /**
     * Convenience: derive the first pickup stop address if present. Useful for
     * clients that prefer a
     * single origin even when multi-stop data exists.
     */
    public CustomerAddressDto primaryPickupFromStops() {
        if (stops == null || stops.isEmpty())
            return pickupAddress;
        return stops.stream()
                .filter(s -> s.getType() != null && s.getType().name().startsWith("PICKUP"))
                .sorted((a, b) -> Integer.compare(
                        a.getSequence() != null ? a.getSequence() : Integer.MAX_VALUE,
                        b.getSequence() != null ? b.getSequence() : Integer.MAX_VALUE))
                .map(OrderStopDto::getAddress)
                .filter(a -> a != null)
                .findFirst()
                .orElse(pickupAddress);
    }

    /**
     * Convenience: derive the first drop stop address if present. Useful for
     * clients that prefer a
     * single destination even when multi-stop data exists.
     */
    public CustomerAddressDto primaryDropFromStops() {
        if (stops == null || stops.isEmpty())
            return dropAddress;
        return stops.stream()
                .filter(s -> s.getType() != null && s.getType().name().contains("DROP"))
                .sorted((a, b) -> Integer.compare(
                        a.getSequence() != null ? a.getSequence() : Integer.MAX_VALUE,
                        b.getSequence() != null ? b.getSequence() : Integer.MAX_VALUE))
                .map(OrderStopDto::getAddress)
                .filter(a -> a != null)
                .findFirst()
                .orElse(dropAddress);
    }

    /** 🔁 Mapping from entity to DTO */
    public static TransportOrderDto fromEntity(TransportOrder order) {
        if (order == null)
            return null;

        // Map stops first so we can derive primary/legacy addresses consistently
        List<OrderStopDto> stopDtos = order.getStops() != null
                ? order.getStops().stream()
                        .map(OrderStopDto::fromEntity)
                        .sorted(
                                Comparator.comparing(
                                        s -> Optional.ofNullable(s.getSequence()).orElse(Integer.MAX_VALUE)))
                        .collect(Collectors.toList())
                : List.of();

        // Derive primary pickup/drop from stops if header-level addresses are missing
        CustomerAddressDto pickupFromStops = stopDtos.stream()
                .filter(s -> s.getType() != null && s.getType().name().startsWith("PICKUP"))
                .map(OrderStopDto::getAddress)
                .filter(a -> a != null)
                .findFirst()
                .orElse(null);

        CustomerAddressDto dropFromStops = stopDtos.stream()
                .filter(s -> s.getType() != null && s.getType().name().contains("DROP"))
                .map(OrderStopDto::getAddress)
                .filter(a -> a != null)
                .findFirst()
                .orElse(null);

        // Legacy arrays: if explicit pickup/drop address lists are absent, derive from
        // stops
        List<CustomerAddressDto> pickupAddressList = order.getPickupAddresses() != null
                ? order.getPickupAddresses().stream()
                        .map(CustomerAddressDto::fromEntity)
                        .collect(Collectors.toList())
                : stopDtos.stream()
                        .filter(s -> s.getType() != null && s.getType().name().startsWith("PICKUP"))
                        .map(OrderStopDto::getAddress)
                        .filter(a -> a != null)
                        .collect(Collectors.toList());

        List<CustomerAddressDto> dropAddressList = order.getDropAddresses() != null
                ? order.getDropAddresses().stream()
                        .map(CustomerAddressDto::fromEntity)
                        .collect(Collectors.toList())
                : stopDtos.stream()
                        .filter(s -> s.getType() != null && s.getType().name().contains("DROP"))
                        .map(OrderStopDto::getAddress)
                        .filter(a -> a != null)
                        .collect(Collectors.toList());

        return TransportOrderDto.builder()
                .id(order.getId())
                .orderReference(order.getOrderReference())
                .customerId(Optional.ofNullable(order.getCustomer()).map(c -> c.getId()).orElse(null))
                .customerName(Optional.ofNullable(order.getCustomer()).map(c -> c.getName()).orElse(null))
                .billTo(order.getBillTo())
                .orderDate(order.getOrderDate())
                .deliveryDate(order.getDeliveryDate())
                .createDate(order.getCreatedAt())
                .shipmentType(order.getShipmentType())
                .courierAssigned(order.getCourierAssigned())
                .tripNo(order.getTripNo())
                .truckNumber(order.getTruckNumber())
                .truckTripCount(order.getTruckTripCount())
                .status(order.getStatus())
                .remark(order.getRemark())
                .origin(order.getOrigin())
                .requiresDriver(order.getRequiresDriver())
                .sourceReference(order.getSourceReference())
                .createdById(Optional.ofNullable(order.getCreatedBy()).map(u -> u.getId()).orElse(null))
                .createdByUsername(
                        Optional.ofNullable(order.getCreatedBy()).map(u -> u.getUsername()).orElse(null))
                .seller(order.getSeller() != null ? EmployeeDto.fromEntity(order.getSeller()) : null)
                .items(
                        order.getItems() != null
                                ? order.getItems().stream()
                                        .filter(Objects::nonNull)
                                        .filter(i -> {
                                            try {
                                                return i.getItem() != null && i.getItem().getItemCode() != null;
                                            } catch (jakarta.persistence.EntityNotFoundException ex) {
                                                return false; // orphaned FK — skip
                                            }
                                        })
                                        .collect(Collectors.toMap(
                                                i -> i.getItem().getItemCode(),
                                                i -> OrderItemDto.fromEntity(i),
                                                (a, b) -> a))
                                        .values()
                                        .stream()
                                        .collect(Collectors.toList())
                                : List.of())
                .pickupAddress(
                        order.getPickupAddress() != null
                                ? CustomerAddressDto.fromEntity(order.getPickupAddress())
                                : pickupFromStops)
                .dropAddress(
                        order.getDropAddress() != null
                                ? CustomerAddressDto.fromEntity(order.getDropAddress())
                                : dropFromStops)
                .pickupAddresses(pickupAddressList)
                .dropAddresses(dropAddressList)
                .dispatches(
                        order.getDispatches() != null
                                ? order.getDispatches().stream()
                                        .map(DispatchDto::fromEntity)
                                        .collect(Collectors.toList())
                                : List.of())
                .invoice(order.getInvoice() != null ? InvoiceDto.fromEntity(order.getInvoice()) : null)
                .stops(stopDtos)
                .build();
    }

    public List<DispatchStopDto> toDispatchStops() {
        if (stops == null || stops.isEmpty()) {
            return new ArrayList<>();
        }
        return stops.stream()
                .filter(Objects::nonNull)
                .map(DispatchStopDto::fromOrderStopDto)
                .filter(Objects::nonNull)
                .collect(Collectors.toCollection(ArrayList::new));
    }
}
