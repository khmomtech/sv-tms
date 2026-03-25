package com.svtrucking.logistics.controller;

import com.svtrucking.logistics.core.ApiResponse;
import com.svtrucking.logistics.dto.OrderAddressDto;
import com.svtrucking.logistics.dto.TransportOrderDto;
import com.svtrucking.logistics.enums.RoleType;
import com.svtrucking.logistics.security.AuthenticatedUserUtil;
import com.svtrucking.logistics.service.TransportOrderService;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.validation.annotation.Validated;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.time.LocalDate;

@RestController
@RequestMapping("/api/customers")
public class CustomerOrdersController {

    private final TransportOrderService transportOrderService;
    private final AuthenticatedUserUtil authUtil;

    public CustomerOrdersController(
            TransportOrderService transportOrderService, AuthenticatedUserUtil authUtil) {
        this.transportOrderService = transportOrderService;
        this.authUtil = authUtil;
    }

    @PostMapping("/{customerId}/orders")
    @PreAuthorize("hasAnyAuthority('ROLE_CUSTOMER','ROLE_ADMIN','ROLE_SUPERADMIN')")
    public ResponseEntity<ApiResponse<TransportOrderDto>> createOrder(
            @PathVariable Long customerId, @Validated @RequestBody TransportOrderDto payload) {
        // Authorize: customers may only create orders for themselves unless admin
        var optCust = authUtil.getCurrentCustomerId();
        if (optCust.isPresent()) {
            Long authCustomerId = optCust.get();
            if (!isAdmin() && !authCustomerId.equals(customerId)) {
                return ResponseEntity.status(403)
                        .body(ApiResponse.fail("Not authorized to create orders for this customer"));
            }
        }

        // Set sensible defaults the mobile client may omit
        if (payload.getOrderDate() == null) {
            payload.setOrderDate(LocalDate.now());
        }

        // If customer id missing in DTO, set from path
        payload.setCustomerId(customerId);

        // Normalize simple addresses: ensure non-null pickup/dropoff addresses
        if (payload.getPickupAddress() == null) {
            payload.setPickupAddress(new OrderAddressDto());
        }
        if (payload.getDropAddress() == null) {
            payload.setDropAddress(new OrderAddressDto());
        }

        return transportOrderService.saveOrder(payload);
    }

    private boolean isAdmin() {
        return authUtil.getCurrentUser().getRoles().stream()
                .anyMatch(r -> r.getName() == RoleType.ADMIN || r.getName() == RoleType.SUPERADMIN);
    }
}
