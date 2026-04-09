package com.svtrucking.logistics.dto;

import static org.assertj.core.api.Assertions.assertThat;

import com.svtrucking.logistics.enums.OrderStatus;
import com.svtrucking.logistics.enums.StopType;
import com.svtrucking.logistics.model.Customer;
import com.svtrucking.logistics.model.CustomerAddress;
import com.svtrucking.logistics.model.OrderStop;
import com.svtrucking.logistics.model.TransportOrder;
import java.time.LocalDate;
import java.util.List;
import org.junit.jupiter.api.Test;

class TransportOrderDtoTest {

  @Test
  void mapsCoreFieldsStopsAndAddressesFromEntity() {
    // Addresses
    CustomerAddress pickup = new CustomerAddress();
    pickup.setId(10L);
    pickup.setName("Pickup Hub");

    CustomerAddress drop = new CustomerAddress();
    drop.setId(20L);
    drop.setName("Drop Hub");

    // Stops
    OrderStop stop1 = new OrderStop();
    stop1.setId(100L);
    stop1.setType(StopType.PICKUP);
    stop1.setAddress(pickup);
    stop1.setSequence(1);

    OrderStop stop2 = new OrderStop();
    stop2.setId(200L);
    stop2.setType(StopType.DROP);
    stop2.setAddress(drop);
    stop2.setSequence(2);

    // Customer
    Customer cust = new Customer();
    cust.setId(5L);
    cust.setName("ACME");

    // Transport order
    TransportOrder order =
        TransportOrder.builder()
            .id(1L)
            .orderReference("REF-123")
            .customer(cust)
            .pickupAddress(pickup)
            .dropAddress(drop)
            .status(OrderStatus.PENDING)
            .orderDate(LocalDate.of(2025, 1, 1))
            .deliveryDate(LocalDate.of(2025, 1, 2))
            .remark("Handle with care")
            .build();

    order.setStops(List.of(stop1, stop2));

    TransportOrderDto dto = TransportOrderDto.fromEntity(order);

    assertThat(dto.getId()).isEqualTo(1L);
    assertThat(dto.getOrderReference()).isEqualTo("REF-123");
    assertThat(dto.getCustomerId()).isEqualTo(5L);
    assertThat(dto.getCustomerName()).isEqualTo("ACME");
    assertThat(dto.getPickupAddress()).isNotNull();
    assertThat(dto.getPickupAddress().getId()).isEqualTo(10L);
    assertThat(dto.getDropAddress()).isNotNull();
    assertThat(dto.getDropAddress().getId()).isEqualTo(20L);
    assertThat(dto.getStops()).hasSize(2);
    assertThat(dto.getStops().get(0).getType()).isEqualTo(StopType.PICKUP);
    assertThat(dto.getStops().get(1).getType()).isEqualTo(StopType.DROP);
    assertThat(dto.getStatus()).isEqualTo(OrderStatus.PENDING);
    assertThat(dto.getRemark()).isEqualTo("Handle with care");
  }
}
