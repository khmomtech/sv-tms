package com.svtrucking.logistics.repository;

import com.svtrucking.logistics.model.OrderStop;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

@Repository
public interface OrderStopRepository extends JpaRepository<OrderStop, Long> {
  // List<OrderStop> findByCustomerId(Long customerId);  //  Find addresses for a specific customer
  @Modifying
  @Query("DELETE FROM OrderStop os WHERE os.transportOrder.id = :orderId")
  void deleteByTransportOrderId(@Param("orderId") Long orderId);
}
