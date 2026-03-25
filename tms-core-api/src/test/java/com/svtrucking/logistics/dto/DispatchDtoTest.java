package com.svtrucking.logistics.dto;

import static org.assertj.core.api.Assertions.assertThat;

import com.svtrucking.logistics.enums.DispatchStatus;
import com.svtrucking.logistics.enums.StopType;
import com.svtrucking.logistics.model.Dispatch;
import com.svtrucking.logistics.model.CustomerAddress;
import com.svtrucking.logistics.model.OrderStop;
import com.svtrucking.logistics.model.TransportOrder;
import java.time.LocalDateTime;
import java.util.List;
import org.junit.jupiter.api.Test;

class DispatchDtoTest {

  @Test
  void fallsBackToTransportOrderStopsWhenDispatchStopsEmpty() {
    // Build order stops
    CustomerAddress pickup = new CustomerAddress();
    pickup.setId(1L);
    pickup.setName("Warehouse Alpha");
    pickup.setAddress("123 Main St");
    pickup.setLatitude(11.11);
    pickup.setLongitude(104.91);

    OrderStop s1 = new OrderStop();
    s1.setId(10L);
    s1.setType(StopType.PICKUP);
    s1.setAddress(pickup);
    s1.setSequence(1);
    s1.setArrivalTime(LocalDateTime.of(2025, 12, 13, 10, 0));

    CustomerAddress drop = new CustomerAddress();
    drop.setId(2L);
    drop.setName("Customer Beta");
    drop.setAddress("456 Market Rd");
    drop.setLatitude(11.12);
    drop.setLongitude(104.92);

    OrderStop s2 = new OrderStop();
    s2.setId(20L);
    s2.setType(StopType.DROP);
    s2.setAddress(drop);
    s2.setSequence(2);
    s2.setArrivalTime(LocalDateTime.of(2025, 12, 13, 12, 0));

    TransportOrder order = TransportOrder.builder().id(99L).orderReference("REF-99").build();
    order.setStops(List.of(s1, s2));

    Dispatch dispatch =
        Dispatch.builder()
            .id(5L)
            .status(DispatchStatus.ASSIGNED)
            .transportOrder(order)
            .stops(List.of()) // intentionally empty to trigger fallback
            .build();

    DispatchDto dto = DispatchDto.fromEntityWithDetails(dispatch);

    assertThat(dto.getStops()).hasSize(2);
    assertThat(dto.getStops().get(0).getStopSequence()).isEqualTo(1);
    assertThat(dto.getStops().get(0).getLocationName()).isEqualTo("Warehouse Alpha");
    assertThat(dto.getStops().get(0).getAddress()).contains("123 Main St");
    assertThat(dto.getStops().get(1).getStopSequence()).isEqualTo(2);
    assertThat(dto.getStops().get(1).getLocationName()).isEqualTo("Customer Beta");
    assertThat(dto.getStops().get(1).getAddress()).contains("456 Market Rd");
  }
}
