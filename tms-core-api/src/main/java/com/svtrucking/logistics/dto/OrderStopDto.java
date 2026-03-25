package com.svtrucking.logistics.dto;

import com.fasterxml.jackson.annotation.JsonSetter;
import com.svtrucking.logistics.enums.StopType;
import com.svtrucking.logistics.model.OrderStop;
import java.time.LocalDateTime;
import java.util.List;
import java.util.Objects;
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
public class OrderStopDto {

  private Long id;
  private StopType type;
  private Long transportOrderId;

  private CustomerAddressDto address;

  private Integer sequence;

  private LocalDateTime eta;
  private LocalDateTime arrivalTime;
  private LocalDateTime departureTime;

  private String remarks;
  private String proofImageUrl;
  private String confirmedBy;
  private String contactPhone;
  private String contactName;

  //  For serialization/deserialization of flat 'addressId'
  public Long getAddressId() {
    return this.address != null ? this.address.getId() : null;
  }

  @JsonSetter("addressId")
  public void setAddressId(Long addressId) {
    if (this.address == null) {
      this.address = new CustomerAddressDto();
    }
    this.address.setId(addressId);
  }

  // 🔁 Convert from entity to DTO
  public static OrderStopDto fromEntity(OrderStop stop) {
    if (stop == null) return null;

    return OrderStopDto.builder()
        .id(stop.getId())
        .type(stop.getType())
        .transportOrderId(
            stop.getTransportOrder() != null ? stop.getTransportOrder().getId() : null)
        .address(CustomerAddressDto.fromEntity(stop.getAddress()))
        .sequence(stop.getSequence())
        .eta(stop.getEta())
        .arrivalTime(stop.getArrivalTime())
        .departureTime(stop.getDepartureTime())
        .remarks(stop.getRemarks())
        .proofImageUrl(stop.getProofImageUrl())
        .confirmedBy(stop.getConfirmedBy())
        .contactPhone(stop.getContactPhone())
          .contactName(stop.getContactName())
        .build();
  }

  // 🔁 Convert from DTO to Entity
  public OrderStop toEntity() {
    OrderStop stop = new OrderStop();
    stop.setId(this.id);
    stop.setType(this.type);
    stop.setSequence(this.sequence);
    stop.setEta(this.eta);
    stop.setArrivalTime(this.arrivalTime);
    stop.setDepartureTime(this.departureTime);
    stop.setRemarks(this.remarks);
    stop.setProofImageUrl(this.proofImageUrl);
    stop.setConfirmedBy(this.confirmedBy);
    stop.setContactPhone(this.contactPhone);
    stop.setContactName(this.contactName);

    if (this.address != null) {
      stop.setAddress(this.address.toEntity());
    }

    return stop;
  }

  public static List<OrderStopDto> fromEntityList(List<OrderStop> stops) {
    return stops.stream()
        .filter(Objects::nonNull)
        .map(OrderStopDto::fromEntity)
        .collect(Collectors.toList());
  }
}
