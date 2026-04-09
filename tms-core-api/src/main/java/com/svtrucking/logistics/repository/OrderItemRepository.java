package com.svtrucking.logistics.repository;

import com.svtrucking.logistics.model.OrderItem;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

@Repository
public interface OrderItemRepository extends JpaRepository<OrderItem, Long> {
  @Modifying
  @Query("DELETE FROM OrderItem oi WHERE oi.transportOrder.id = :orderId")
  void deleteByTransportOrderId(@Param("orderId") Long orderId);
}
