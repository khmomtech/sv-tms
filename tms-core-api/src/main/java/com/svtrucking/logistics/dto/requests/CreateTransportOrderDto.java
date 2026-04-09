package com.svtrucking.logistics.dto.requests;

import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import com.svtrucking.logistics.enums.OrderStatus;
import java.time.LocalDate;
import java.util.List;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@Data
@JsonIgnoreProperties(ignoreUnknown = true)
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class CreateTransportOrderDto {

  private String orderReference;

  private String customerId; // Consider using Long if your system uses numeric customer IDs

  private LocalDate orderDate;
  private LocalDate deliveryDate;

  private OrderStatus status;

  private String remark;

  private Long createdById; // Refers to User entity
  private Long sellerId; // Refers to Employee entity

  private Long pickupAddressId; // Single pickup address
  private Long dropAddressId; // Single drop-off address

  private List<Long> pickupAddressIds; // Optional: for multiple pickups
  private List<Long> dropAddressIds; // Optional: for multiple drop-offs

  private List<Long> itemIds; // Optional: list of existing item IDs
  private List<Long> dispatchIds; // Optional: dispatch plan IDs
  private Long invoiceId; // Optional: pre-generated invoice ID
}
