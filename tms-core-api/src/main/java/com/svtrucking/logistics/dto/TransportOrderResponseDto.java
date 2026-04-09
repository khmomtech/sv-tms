package com.svtrucking.logistics.dto;

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
public class TransportOrderResponseDto {
  private Long id;
  private String orderReference;
  private Long customerId; //  Updated to store only the Customer ID
  private String customerName; //  Updated to store Customer Name
  private String billTo;
  private LocalDate orderDate;
  private LocalDate deliveryDate;
  private String shipmentType;
  private String courierAssigned;
  private OrderStatus status;
  private String createdBy;
  private OrderOrigin origin;
  private Boolean requiresDriver;
  private String sourceReference;
  private List<OrderItemDto> items;
  private CustomerAddressDto pickupAddress;
  private CustomerAddressDto dropAddress;
}
