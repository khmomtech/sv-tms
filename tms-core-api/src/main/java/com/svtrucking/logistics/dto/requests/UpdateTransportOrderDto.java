package com.svtrucking.logistics.dto.requests;

import com.fasterxml.jackson.annotation.JsonAlias;
import com.fasterxml.jackson.annotation.JsonProperty;
import com.svtrucking.logistics.dto.CustomerDto;
import com.svtrucking.logistics.dto.CustomerAddressDto;
import com.svtrucking.logistics.dto.OrderItemDto;
import com.svtrucking.logistics.dto.OrderStopDto;
import com.svtrucking.logistics.enums.OrderStatus;
import com.svtrucking.logistics.enums.OrderOrigin;
import java.time.LocalDate;
import java.util.List;
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
public class UpdateTransportOrderDto {

  private Long id;

  private String orderReference;

  private Long customerId; // Consider using Long if your system uses numeric customer IDs

  @JsonProperty("customer")
  private CustomerDto customer;

  private String billTo;
  private LocalDate orderDate;
  private LocalDate deliveryDate;

  private String shipmentType;
  private String courierAssigned;
  private OrderStatus status;

  private String remark;
  private Long createdById;
  private Long sellerId;

  private CustomerAddressDto pickupAddress;
  private CustomerAddressDto dropAddress;

  // allow changing origin/driver requirement for manual edits
  private OrderOrigin origin;
  private Boolean requiresDriver;
  private String sourceReference;

  @JsonAlias("pickupLocations")
  private List<CustomerAddressDto> pickupAddresses;
  @JsonAlias("dropLocations")
  private List<CustomerAddressDto> dropAddresses;

  private List<OrderItemDto> items;
  private List<OrderStopDto> stops;
}
