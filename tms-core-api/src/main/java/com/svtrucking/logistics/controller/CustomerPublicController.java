package com.svtrucking.logistics.controller;

import com.svtrucking.logistics.core.ApiResponse;
import com.svtrucking.logistics.dto.CustomerAddressDto;
import com.svtrucking.logistics.dto.IncidentDto;
import com.svtrucking.logistics.dto.TransportOrderDto;
import com.svtrucking.logistics.dto.requests.CustomerDeviceTokenRequest;
import com.svtrucking.logistics.exception.CustomerNotFoundException;
import com.svtrucking.logistics.security.AuthenticatedUserUtil;
import com.svtrucking.logistics.service.CustomerAddressService;
import com.svtrucking.logistics.service.CustomerService;
import com.svtrucking.logistics.service.IncidentService;
import com.svtrucking.logistics.service.TransportOrderService;
import org.springframework.http.HttpStatus;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import java.util.List;
import java.util.Objects;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.web.PageableDefault;
import org.springframework.web.bind.annotation.RestController;

/**
 * Public (customer-facing) APIs. These are small, focused endpoints used by the
 * customer mobile
 * application to list orders and addresses belonging to a specific customer.
 *
 * Security: endpoints require authentication; further authorization can be
 * added to restrict
 * access to only the owning customer (by mapping users to customers) if that
 * association exists.
 */
@RestController
@RequestMapping("/api/customer")
@PreAuthorize("isAuthenticated()")
@Tag(name = "Customer Public", description = "Customer-facing endpoints for orders and addresses")
public class CustomerPublicController {

  private final TransportOrderService transportOrderService;
  private final CustomerAddressService customerAddressService;
  private final CustomerService customerService;
  private final AuthenticatedUserUtil authenticatedUserUtil;
  private final IncidentService incidentService;

  public CustomerPublicController(
      TransportOrderService transportOrderService,
      CustomerAddressService customerAddressService,
      CustomerService customerService,
      AuthenticatedUserUtil authenticatedUserUtil,
      IncidentService incidentService) {
    this.transportOrderService = transportOrderService;
    this.customerAddressService = customerAddressService;
    this.customerService = customerService;
    this.authenticatedUserUtil = authenticatedUserUtil;
    this.incidentService = incidentService;
  }

  /**
   * List orders for a given customer id.
   * GET /api/customers/{customerId}/orders
   */
  @GetMapping("/{customerId}/orders")
  @Operation(summary = "List orders for a customer", description = "Returns transport orders belonging to the specified customer")
  public ResponseEntity<ApiResponse<List<TransportOrderDto>>> listOrdersForCustomer(
      @PathVariable Long customerId) {
    try {
      // Authorization: allow ADMINs, otherwise only the owning customer
      if (!isAdmin()) {
        var optCid = authenticatedUserUtil.getCurrentCustomerId();
        if (optCid.isEmpty() || !Objects.equals(optCid.get(), customerId)) {
          return ResponseEntity.status(HttpStatus.FORBIDDEN)
              .body(new ApiResponse<>(false, "Access denied", null));
        }
      }

      List<TransportOrderDto> orders = transportOrderService.findByCustomerId(customerId);
      return ResponseEntity.ok(new ApiResponse<>(true, "Orders retrieved", orders));
    } catch (CustomerNotFoundException ex) {
      return ResponseEntity.status(404)
          .body(new ApiResponse<>(false, "Customer not found", null));
    }
  }

  /**
   * Get a single order for a customer. Ensures the requested order belongs to the
   * customer.
   * GET /api/customers/{customerId}/orders/{orderId}
   */
  @GetMapping("/{customerId}/orders/{orderId}")
  @Operation(summary = "Get a single order for a customer", description = "Returns a single transport order if it belongs to the customer")
  public ResponseEntity<ApiResponse<TransportOrderDto>> getOrderForCustomer(
      @PathVariable Long customerId, @PathVariable Long orderId) {
    ResponseEntity<com.svtrucking.logistics.core.ApiResponse<com.svtrucking.logistics.dto.TransportOrderDto>> resp = transportOrderService
        .getOrderById(orderId);

    if (!resp.getStatusCode().is2xxSuccessful() || resp.getBody() == null) {
      return ResponseEntity.status(resp.getStatusCode())
          .body(new ApiResponse<>(false, "Order not found", null));
    }

    TransportOrderDto dto = resp.getBody().getData();
    if (dto == null || dto.getCustomerId() == null || !dto.getCustomerId().equals(customerId)) {
      return ResponseEntity.status(404).body(new ApiResponse<>(false, "Order not found", null));
    }

    // Authorization check (ADMIN or owning customer)
    if (!isAdmin()) {
      var optCid = authenticatedUserUtil.getCurrentCustomerId();
      if (optCid.isEmpty() || !Objects.equals(optCid.get(), customerId)) {
        return ResponseEntity.status(HttpStatus.FORBIDDEN)
            .body(new ApiResponse<>(false, "Access denied", null));
      }
    }

    return ResponseEntity.ok(new ApiResponse<>(true, "Order retrieved", dto));
  }

  /**
   * List order addresses for a customer.
   * GET /api/customers/{customerId}/addresses
   */
  @GetMapping("/{customerId}/addresses")
  @Operation(summary = "List addresses for a customer", description = "Returns order addresses registered under the specified customer")
  public ResponseEntity<ApiResponse<List<CustomerAddressDto>>> listAddressesForCustomer(
      @PathVariable Long customerId) {
    try {
      // Authorization: only ADMINs or the owning customer may access
      if (!isAdmin()) {
        var optCid = authenticatedUserUtil.getCurrentCustomerId();
        if (optCid.isEmpty() || !Objects.equals(optCid.get(), customerId)) {
          return ResponseEntity.status(HttpStatus.FORBIDDEN)
              .body(new ApiResponse<>(false, "Access denied", null));
        }
      }

      List<com.svtrucking.logistics.model.CustomerAddress> addresses = customerAddressService
          .findByCustomerId(customerId);
      List<CustomerAddressDto> dtoList = CustomerAddressDto.fromEntityList(addresses);
      return ResponseEntity.ok(new ApiResponse<>(true, "Addresses retrieved", dtoList));
    } catch (CustomerNotFoundException ex) {
      return ResponseEntity.status(404)
          .body(new ApiResponse<>(false, "Customer not found", null));
    }
  }

  /**
   * Register or update FCM device token for push notification delivery.
   * POST /api/customer/{customerId}/device-token
   */
  @PostMapping("/{customerId}/device-token")
  @Operation(summary = "Register FCM device token", description = "Stores the customer's FCM token for push notification delivery")
  public ResponseEntity<ApiResponse<Void>> updateDeviceToken(
      @PathVariable Long customerId,
      @RequestBody @Valid CustomerDeviceTokenRequest request) {
    if (!isAdmin()) {
      var optCid = authenticatedUserUtil.getCurrentCustomerId();
      if (optCid.isEmpty() || !Objects.equals(optCid.get(), customerId)) {
        return ResponseEntity.status(HttpStatus.FORBIDDEN)
            .body(new ApiResponse<>(false, "Access denied", null));
      }
    }
    customerService.updateCustomerDeviceToken(customerId, request.getDeviceToken());
    return ResponseEntity.ok(new ApiResponse<>(true, "Device token updated", null));
  }

  /**
   * Returns paginated incidents (DriverIssues) linked to dispatches belonging to
   * this customer. Read-only — customers can view but not create or modify incidents.
   * GET /api/customer/{customerId}/incidents?page=0&size=50
   */
  @GetMapping("/{customerId}/incidents")
  @Operation(summary = "List incidents for a customer", description = "Returns incidents associated with the customer's dispatch history")
  public ResponseEntity<ApiResponse<Page<IncidentDto>>> getCustomerIncidents(
      @PathVariable Long customerId,
      @PageableDefault(size = 50) Pageable pageable) {
    if (!isAdmin()) {
      var optCid = authenticatedUserUtil.getCurrentCustomerId();
      if (optCid.isEmpty() || !Objects.equals(optCid.get(), customerId)) {
        return ResponseEntity.status(HttpStatus.FORBIDDEN)
            .body(new ApiResponse<>(false, "Access denied", null));
      }
    }
    Page<IncidentDto> incidents = incidentService.getIncidentsByCustomerId(customerId, pageable);
    return ResponseEntity.ok(new ApiResponse<>(true, "Incidents retrieved", incidents));
  }

  private boolean isAdmin() {
    var auth = org.springframework.security.core.context.SecurityContextHolder.getContext()
        .getAuthentication();
    if (auth == null || !auth.isAuthenticated())
      return false;
    return auth.getAuthorities().stream()
        .map(a -> a.getAuthority() == null ? "" : a.getAuthority())
        .anyMatch(
            s -> s.equalsIgnoreCase("ROLE_ADMIN") || s.equalsIgnoreCase("ADMIN") || s.toUpperCase().contains("ADMIN"));
  }
}
