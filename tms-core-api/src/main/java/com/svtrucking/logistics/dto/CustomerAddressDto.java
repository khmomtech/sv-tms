package com.svtrucking.logistics.dto;

import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import com.svtrucking.logistics.model.Customer;
import com.svtrucking.logistics.model.CustomerAddress;
import java.util.List;
import java.util.Objects;
import java.util.stream.Collectors;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@JsonIgnoreProperties(ignoreUnknown = true)
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class CustomerAddressDto {

  private Long id;
  private String name;
  private String address;
  private String city;
  private String country;
  private String postcode;
  private String scheduledTime;
  private double longitude;
  private double latitude;
  private String type; // e.g., "WAREHOUSE" or "DEPO"
  private Long customerId;
  private String contactName;
  private String contactPhone;

  public static CustomerAddressDto fromEntity(CustomerAddress entity) {
    if (entity == null) return null;

    return CustomerAddressDto.builder()
        .id(entity.getId())
        .name(entity.getName())
        .address(entity.getAddress())
        .city(entity.getCity())
        .country(entity.getCountry())
        .postcode(entity.getPostcode())
        .scheduledTime(entity.getScheduledTime())
        .longitude(entity.getLongitude())
        .latitude(entity.getLatitude())
        .type(entity.getType()) // e.g., "WAREHOUSE" or "DEPO"
        .contactName(entity.getContactName())
        .contactPhone(entity.getContactPhone())
        .customerId(entity.getCustomer() != null ? entity.getCustomer().getId() : null)
        .build();
  }

  public CustomerAddress toEntity() {
    CustomerAddress entity = new CustomerAddress();
    entity.setId(this.id);
    entity.setName(this.name);
    entity.setAddress(this.address);
    entity.setCity(this.city);
    entity.setCountry(this.country);
    entity.setPostcode(this.postcode);
    entity.setScheduledTime(this.scheduledTime);
    entity.setLongitude(this.longitude);
    entity.setLatitude(this.latitude);
    entity.setType(this.type);
    entity.setContactName(this.contactName);
    entity.setContactPhone(this.contactPhone);

    if (this.customerId != null) {
      Customer customer = new Customer();
      customer.setId(this.customerId);
      entity.setCustomer(customer);
    }

    return entity;
  }

  public static List<CustomerAddressDto> fromEntityList(List<CustomerAddress> list) {
    return list.stream()
        .filter(Objects::nonNull)
        .map(CustomerAddressDto::fromEntity)
        .collect(Collectors.toList());
  }
}
