// package com.svtrucking.logistics.service;

// import com.svtrucking.logistics.model.Order;
// import com.svtrucking.logistics.repository.OrderRepository;
// import com.svtrucking.logistics.enums.OrderStatus;
// import org.springframework.stereotype.Service;
// import java.util.List;

// @Service
// public class OrderService {

//     private final OrderRepository orderRepository;

//     public OrderService(OrderRepository orderRepository) {
//         this.orderRepository = orderRepository;
//     }

//     public List<Order> getAllOrders() {
//         return orderRepository.findAll();
//     }

//     public Order createOrder(Order order) {
//         return orderRepository.save(order);
//     }

//     public Order updateOrderStatus(Long orderId, OrderStatus status) {
//         Order order = orderRepository.findById(orderId).orElseThrow();
//         order.setStatus(status);
//         return orderRepository.save(order);
//     }
// }
package com.svtrucking.logistics.service;

import com.svtrucking.logistics.enums.OrderStatus;
import com.svtrucking.logistics.model.Order;
import com.svtrucking.logistics.repository.OrderRepository;
import java.util.Optional;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;

@Service
public class OrderService {

  private final OrderRepository orderRepository;

  public OrderService(OrderRepository orderRepository) {
    this.orderRepository = orderRepository;
  }

  public Page<Order> getAllOrders(Pageable pageable) {
    return orderRepository.findAll(pageable);
  }

  public Optional<Order> getOrderById(Long orderId) {
    return orderRepository.findById(orderId);
  }

  public Page<Order> searchOrders(String customerName, OrderStatus status, Pageable pageable) {
    if (customerName != null && status != null) {
      return orderRepository.findByCustomerNameContainingIgnoreCaseAndStatus(
          customerName, status, pageable);
    } else if (customerName != null) {
      return orderRepository.findByCustomerNameContainingIgnoreCase(customerName, pageable);
    } else if (status != null) {
      return orderRepository.findByStatus(status, pageable);
    } else {
      return orderRepository.findAll(pageable);
    }
  }

  public Order addOrder(Order order) {
    order.setCreatedAt(java.time.LocalDateTime.now()); // Ensure createdAt is set
    return orderRepository.save(order);
  }

  public Order updateOrder(Long orderId, Order updatedOrder) {
    return orderRepository
        .findById(orderId)
        .map(
            order -> {
              order.setCustomerName(updatedOrder.getCustomerName());
              order.setDeliveryAddress(updatedOrder.getDeliveryAddress());
              order.setPickupAddress(updatedOrder.getPickupAddress());
              order.setStatus(updatedOrder.getStatus());
              order.setAssignedVehicle(updatedOrder.getAssignedVehicle());
              order.setAssignedDriver(updatedOrder.getAssignedDriver());
              order.setProofOfDelivery(updatedOrder.getProofOfDelivery());
              return orderRepository.save(order);
            })
        .orElseThrow(() -> new RuntimeException("Order not found"));
  }

  public Order updateOrderStatus(Long orderId, OrderStatus status) {
    return orderRepository
        .findById(orderId)
        .map(
            order -> {
              order.setStatus(status);
              return orderRepository.save(order);
            })
        .orElseThrow(() -> new RuntimeException("Order not found"));
  }

  public void deleteOrder(Long orderId) {
    if (!orderRepository.existsById(orderId)) {
      throw new RuntimeException("Order not found");
    }
    orderRepository.deleteById(orderId);
  }
}
