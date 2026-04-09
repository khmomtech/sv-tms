package com.svtrucking.logistics.dto;

import com.svtrucking.logistics.model.TransportOrder;
import com.svtrucking.logistics.enums.OrderStatus;
import java.time.LocalDate;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

/**
 * Lightweight response DTO for TransportOrder list views.
 * Used for GET /api/transport-orders - list view.
 * Excludes detailed nested objects to reduce payload size.
 */
@Data
@NoArgsConstructor
@AllArgsConstructor
public class TransportOrderListResponse {
  private Long id;
  private String orderReference;
  private LocalDate orderDate;
  private LocalDate deliveryDate;
  private OrderStatus status;
  private String tripNo;

  // Customer information (minimal)
  private Long customerId;
  private String customerName;

  /**
   * Creates a TransportOrderListResponse from a TransportOrder entity.
   *
   * @param order the TransportOrder entity
   * @return TransportOrderListResponse with minimal order data
   */
  public static TransportOrderListResponse fromEntity(TransportOrder order) {
    if (order == null) {
      return null;
    }

    TransportOrderListResponse response = new TransportOrderListResponse();
    response.setId(order.getId());
    response.setOrderReference(order.getOrderReference());
    response.setOrderDate(order.getOrderDate());
    response.setDeliveryDate(order.getDeliveryDate());
    response.setStatus(order.getStatus());
    response.setTripNo(order.getTripNo());

    // Customer information (minimal)
    if (order.getCustomer() != null) {
      response.setCustomerId(order.getCustomer().getId());
      response.setCustomerName(order.getCustomer().getName());
    }

    return response;
  }
}
