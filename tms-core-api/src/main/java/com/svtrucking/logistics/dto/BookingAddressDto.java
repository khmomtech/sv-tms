package com.svtrucking.logistics.dto;

import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import com.svtrucking.logistics.model.CustomerAddress;
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
public class BookingAddressDto {
  private String addressLine;
  private String city;
  private String province;
  private String postalCode;
  private String country;
  private String contactName;
  private String contactPhone;
  private String companyName; // maps to OrderAddress.name
  private Long id; // optional existing address id

  public CustomerAddress toOrderAddress() {
    CustomerAddress addr = new CustomerAddress();
    addr.setId(this.id);
    addr.setName(this.companyName);
    addr.setAddress(this.addressLine);
    addr.setCity(this.city);
    addr.setCountry(this.country);
    addr.setPostcode(this.postalCode);
    return addr;
  }
}
