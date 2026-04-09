package com.svtrucking.logistics.repository;

import com.svtrucking.logistics.enums.OrderStatus;
import com.svtrucking.logistics.model.Order;
import java.util.List;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

@Repository
public interface OrderRepository extends JpaRepository<Order, Long> {

  List<Order> findByStatus(OrderStatus status);

  Page<Order> findByCustomerNameContainingIgnoreCase(String customerName, Pageable pageable);

  Page<Order> findByStatus(OrderStatus status, Pageable pageable);

  Page<Order> findByCustomerNameContainingIgnoreCaseAndStatus(
      String customerName, OrderStatus status, Pageable pageable);
}
