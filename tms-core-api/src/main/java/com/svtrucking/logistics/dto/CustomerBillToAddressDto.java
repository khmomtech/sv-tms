package com.svtrucking.logistics.dto;

import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import com.svtrucking.logistics.model.Customer;
import com.svtrucking.logistics.model.CustomerBillToAddress;
import java.time.Instant;
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
public class CustomerBillToAddressDto {

  private Long id;
  private Long customerId;
  private String name;
  private String address;
  private String city;
  private String state;
  private String zip;
  private String country;
  private String contactName;
  private String contactPhone;
  private String email;
  private String taxId;
  private String notes;
  private boolean isPrimary;
  private Instant createdAt;
  private Instant updatedAt;

  public static CustomerBillToAddressDto fromEntity(CustomerBillToAddress entity) {
    if (entity == null) return null;
    return CustomerBillToAddressDto.builder()
        .id(entity.getId())
        .customerId(entity.getCustomer() != null ? entity.getCustomer().getId() : null)
        .name(entity.getName())
        .address(entity.getAddress())
        .city(entity.getCity())
        .state(entity.getState())
        .zip(entity.getZip())
        .country(entity.getCountry())
        .contactName(entity.getContactName())
        .contactPhone(entity.getContactPhone())
        .email(entity.getEmail())
        .taxId(entity.getTaxId())
        .notes(entity.getNotes())
        .isPrimary(entity.isPrimary())
        .createdAt(entity.getCreatedAt())
        .updatedAt(entity.getUpdatedAt())
        .build();
  }

  public CustomerBillToAddress toEntity() {
    CustomerBillToAddress entity = new CustomerBillToAddress();
    entity.setId(this.id);
    entity.setName(this.name);
    entity.setAddress(this.address);
    entity.setCity(this.city);
    entity.setState(this.state);
    entity.setZip(this.zip);
    entity.setCountry(this.country);
    entity.setContactName(this.contactName);
    entity.setContactPhone(this.contactPhone);
    entity.setEmail(this.email);
    entity.setTaxId(this.taxId);
    entity.setNotes(this.notes);
    entity.setPrimary(this.isPrimary);

    if (this.customerId != null) {
      Customer customer = new Customer();
      customer.setId(this.customerId);
      entity.setCustomer(customer);
    }
    return entity;
  }

  public static List<CustomerBillToAddressDto> fromEntityList(List<CustomerBillToAddress> list) {
    return list.stream()
        .filter(Objects::nonNull)
        .map(CustomerBillToAddressDto::fromEntity)
        .collect(Collectors.toList());
  }
}

