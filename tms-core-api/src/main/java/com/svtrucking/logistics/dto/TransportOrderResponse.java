package com.svtrucking.logistics.dto;

import com.svtrucking.logistics.model.TransportOrder;
import com.svtrucking.logistics.enums.OrderStatus;
import java.time.LocalDate;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

/**
 * Full response DTO for TransportOrder entity.
 * Used for GET /api/transport-orders/{id} - detailed view.
 * Includes all fields and nested customer information.
 */
@Data
@NoArgsConstructor
@AllArgsConstructor
public class TransportOrderResponse {
  private Long id;
  private String orderReference;
  private LocalDate orderDate;
  private LocalDate deliveryDate;
  private OrderStatus status;
  private String billTo;
  private String shipmentType;
  private String tripNo;

  // Customer information
  private Long customerId;
  private String customerName;
  private String customerCode;

  /**
   * Creates a TransportOrderResponse from a TransportOrder entity.
   *
   * @param order the TransportOrder entity
   * @return TransportOrderResponse populated with order data
   */
  public static TransportOrderResponse fromEntity(TransportOrder order) {
    if (order == null) {
      return null;
    }

    TransportOrderResponse response = new TransportOrderResponse();
    response.setId(order.getId());
    response.setOrderReference(order.getOrderReference());
    response.setOrderDate(order.getOrderDate());
    response.setDeliveryDate(order.getDeliveryDate());
    response.setStatus(order.getStatus());
    response.setBillTo(order.getBillTo());
    response.setShipmentType(order.getShipmentType());
    response.setTripNo(order.getTripNo());

    // Customer information
    if (order.getCustomer() != null) {
      response.setCustomerId(order.getCustomer().getId());
      response.setCustomerName(order.getCustomer().getName());
      response.setCustomerCode(order.getCustomer().getCustomerCode());
    }

    return response;
  }
}
