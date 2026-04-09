package com.svtrucking.logistics.controller.admin;

import com.svtrucking.logistics.core.ApiResponse;
import com.svtrucking.logistics.dto.EmployeeDto;
import com.svtrucking.logistics.dto.TransportOrderDto;
import com.svtrucking.logistics.dto.requests.UpdateTransportOrderDto;
import com.svtrucking.logistics.enums.OrderStatus;
import com.svtrucking.logistics.model.CustomerAddress;
import com.svtrucking.logistics.model.OrderItem;
import com.svtrucking.logistics.model.TransportOrder;
import com.svtrucking.logistics.service.DispatchService;
import com.svtrucking.logistics.service.TransportOrderService;
import java.time.LocalDate;
import java.util.List;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

@Slf4j
@RestController
@RequestMapping("/api/admin/transportorders")
@CrossOrigin(origins = "*")
public class TransportOrderController {

  private final TransportOrderService transportOrderService;

  public TransportOrderController(
      TransportOrderService transportOrderService, DispatchService dispatchService) {
    this.transportOrderService = transportOrderService;
  }

  @PostMapping
  public ResponseEntity<ApiResponse<TransportOrderDto>> createOrder(
      @RequestBody TransportOrderDto orderDto) {
    log.info("Creating a new transport order");
    return transportOrderService.saveOrder(orderDto);
  }

  @GetMapping
  public ResponseEntity<ApiResponse<Page<TransportOrderDto>>> getAllOrders(Pageable pageable) {
    log.info("Fetching all transport orders (paginated)");
    return ResponseEntity.ok(transportOrderService.getAllOrders(pageable));
  }

  @GetMapping("/list")
  public ResponseEntity<ApiResponse<List<TransportOrderDto>>> getAllOrderLists() {
    log.info("Fetching all transport orders (non-paginated)");
    return ResponseEntity.ok(transportOrderService.getAllOrderLists());
  }

  @GetMapping("/search")
  public ResponseEntity<ApiResponse<Page<TransportOrderDto>>> searchOrders(
      @RequestParam String query, Pageable pageable) {
    log.info("Searching orders with query: {}", query);
    return transportOrderService.searchOrders(query, pageable);
  }

  @GetMapping("/searchs")
  public ResponseEntity<ApiResponse<List<TransportOrderDto>>> searchOrderss(
      @RequestParam String query) {
    List<TransportOrderDto> orders = transportOrderService.searchOrders(query);
    return ResponseEntity.ok(new ApiResponse<>(true, "Orders found", orders));
  }

  @GetMapping("/filter")
  public ResponseEntity<ApiResponse<Page<TransportOrderDto>>> filterOrders(
      @RequestParam(required = false) String query,
      @RequestParam(required = false) OrderStatus status,
      @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE)
          LocalDate fromDate,
      @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE)
          LocalDate toDate,
      Pageable pageable) {

    if (fromDate == null) fromDate = LocalDate.of(2000, 1, 1); // or earliest allowed date
    if (toDate == null) toDate = LocalDate.now();

    return transportOrderService.filterOrders(query, status, fromDate, toDate, pageable);
  }

  @GetMapping("/filter/status")
  public ResponseEntity<ApiResponse<Page<TransportOrder>>> filterByStatus(
      @RequestParam OrderStatus status, Pageable pageable) {
    log.info("Filtering orders by status: {}", status);
    return transportOrderService.filterByStatus(status, pageable);
  }

  @GetMapping("/filter/date")
  public ResponseEntity<ApiResponse<Page<TransportOrder>>> filterByDateRange(
      @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate startDate,
      @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate endDate,
      Pageable pageable) {
    log.info("Filtering orders from {} to {}", startDate, endDate);
    return transportOrderService.filterByDateRange(startDate, endDate, pageable);
  }

  @GetMapping("/types")
  public ResponseEntity<ApiResponse<List<String>>> getShipmentTypes() {
    log.info("Fetching transport order shipment types");
    return ResponseEntity.ok(transportOrderService.getShipmentTypes());
  }

  @GetMapping("/sellers")
  public ResponseEntity<ApiResponse<List<EmployeeDto>>> getAvailableSellers() {
    log.info("Fetching available sellers");
    return ResponseEntity.ok(transportOrderService.getAvailableSellers());
  }

  @GetMapping("/{id}")
  public ResponseEntity<ApiResponse<TransportOrderDto>> getOrderById(@PathVariable Long id) {
    log.info("Fetching transport order by ID: {}", id);
    return transportOrderService.getOrderById(id);
  }

  @PutMapping("/{id}")
  public ResponseEntity<ApiResponse<TransportOrderDto>> updateOrder(
      @PathVariable Long id, @RequestBody UpdateTransportOrderDto updatedOrderDto) {
    log.info("Updating transport order with ID: {}", id);
    return transportOrderService.updateOrder(id, updatedOrderDto);
  }

  @DeleteMapping("/{id}")
  public ResponseEntity<ApiResponse<String>> deleteOrder(@PathVariable Long id) {
    log.warn("Deleting transport order with ID: {}", id);
    return transportOrderService.deleteOrder(id);
  }

  @PutMapping("/{id}/status")
  public ResponseEntity<ApiResponse<TransportOrderDto>> updateOrderStatus(
      @PathVariable Long id, @RequestParam OrderStatus status) {
    log.info("Updating order ID {} to status {}", id, status);
    return transportOrderService.updateOrderStatus(id, status);
  }

  @GetMapping("/{id}/items")
  public ResponseEntity<ApiResponse<List<OrderItem>>> getOrderItems(@PathVariable Long id) {
    log.info("Fetching items for order ID: {}", id);
    return transportOrderService.getOrderItems(id);
  }

  @GetMapping("/{id}/addresses")
  public ResponseEntity<ApiResponse<List<CustomerAddress>>> getOrderAddresses(@PathVariable Long id) {
    log.info("Fetching addresses for order ID: {}", id);
    return transportOrderService.getOrderAddresses(id);
  }

  @GetMapping("/customer/{customerId}")
  public ResponseEntity<ApiResponse<List<TransportOrderDto>>> getOrdersByCustomer(
      @PathVariable Long customerId) {
    log.info("Fetching orders for customer ID: {}", customerId);
    return ResponseEntity.ok(
        new ApiResponse<>(
            true,
            "Orders for customer loaded",
            transportOrderService.findByCustomerId(customerId)));
  }

  @GetMapping("/unscheduled")
  public ResponseEntity<ApiResponse<List<TransportOrderDto>>> getUnscheduledOrders() {
    log.info("Fetching unscheduled transport orders");
    return ResponseEntity.ok(
        new ApiResponse<>(
            true, "Unscheduled orders loaded", transportOrderService.getUnscheduledOrders()));
  }

  @PostMapping("/import-bulk")
  public ResponseEntity<ApiResponse<?>> importBulkOrders(@RequestParam("file") MultipartFile file) {
    try {
      log.info(
          "Received bulk import request: file={}, size={} bytes",
          file.getOriginalFilename(),
          file.getSize());

      // Let the service handle validation, persistence, and error shaping
      return transportOrderService.importBulkOrders(file);

    } catch (Exception e) {
      log.error("Unexpected bulk import failure: {}", e.getMessage(), e);
      return ResponseEntity.status(500)
          .body(new ApiResponse<>(false, "Bulk import failed", e.getMessage()));
    }
  }
}
