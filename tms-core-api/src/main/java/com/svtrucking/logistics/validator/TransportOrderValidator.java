package com.svtrucking.logistics.validator;

import com.svtrucking.logistics.enums.OrderStatus;
import com.svtrucking.logistics.exception.InvalidCustomerDataException;
import com.svtrucking.logistics.exception.OrderNotFoundException;
import com.svtrucking.logistics.model.Customer;
import com.svtrucking.logistics.model.CustomerAddress;
import com.svtrucking.logistics.model.OrderItem;
import com.svtrucking.logistics.model.TransportOrder;
import com.svtrucking.logistics.repository.CustomerRepository;
import com.svtrucking.logistics.repository.TransportOrderRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Component;

import java.time.LocalDate;
import java.util.EnumSet;
import java.util.List;
import java.util.Set;

/**
 * Validator for TransportOrder entity with comprehensive business rule validation.
 * Handles order creation, updates, status transitions, and business constraints.
 */
@Slf4j
@Component
@RequiredArgsConstructor
public class TransportOrderValidator {

    private final TransportOrderRepository transportOrderRepository;
    private final CustomerRepository customerRepository;

    // Terminal statuses that cannot be modified
    private static final Set<OrderStatus> TERMINAL_STATUSES = EnumSet.of(
            OrderStatus.DELIVERED,
            OrderStatus.COMPLETED,
            OrderStatus.CANCELLED
    );

    // Active statuses that prevent deletion
    private static final Set<OrderStatus> ACTIVE_STATUSES = EnumSet.of(
            OrderStatus.ASSIGNED,
            OrderStatus.DRIVER_CONFIRMED,
            OrderStatus.ARRIVED_LOADING,
            OrderStatus.LOADING,
            OrderStatus.LOADED,
            OrderStatus.IN_TRANSIT,
            OrderStatus.ARRIVED_UNLOADING,
            OrderStatus.UNLOADING,
            OrderStatus.UNLOADED
    );

    /**
     * Validates transport order before creation.
     */
    public void validateForCreate(TransportOrder order) {
        validateRequiredFields(order);
        validateCustomer(order.getCustomer());
        validateDateConstraints(order);
        validateOrderItems(order.getItems());
        validateAddresses(order);
        validateInitialStatus(order);
        validateBusinessRules(order);
    }

    /**
     * Validates transport order before update.
     */
    public void validateForUpdate(TransportOrder order, Long orderId) {
        if (orderId == null) {
            throw new InvalidCustomerDataException("id", "Order ID is required for update");
        }

        TransportOrder existingOrder = transportOrderRepository.findById(orderId)
                .orElseThrow(() -> new OrderNotFoundException(orderId));

        // Cannot update terminal status orders
        if (TERMINAL_STATUSES.contains(existingOrder.getStatus())) {
            throw new InvalidCustomerDataException(
                    "status",
                    "Cannot update order with terminal status: " + existingOrder.getStatus()
            );
        }

        validateRequiredFields(order);
        validateCustomer(order.getCustomer());
        validateDateConstraints(order);
        validateOrderItems(order.getItems());
        validateAddresses(order);
        validateBusinessRules(order);
    }

    /**
     * Validates order status transition.
     */
    public void validateStatusTransition(OrderStatus currentStatus, OrderStatus newStatus) {
        if (currentStatus == null) {
            throw new InvalidCustomerDataException("status", "Current status cannot be null");
        }

        if (newStatus == null) {
            throw new InvalidCustomerDataException("status", "New status cannot be null");
        }

        if (currentStatus == newStatus) {
            return; // No change
        }

        // Cannot change terminal statuses
        if (TERMINAL_STATUSES.contains(currentStatus)) {
            throw new InvalidCustomerDataException(
                    "status",
                    "Cannot change status from " + currentStatus + " (terminal state)"
            );
        }

        // Validate specific transitions
        if (!isValidStatusTransition(currentStatus, newStatus)) {
            throw new InvalidCustomerDataException(
                    "status",
                    "Invalid status transition from " + currentStatus + " to " + newStatus
            );
        }
    }

    /**
     * Validates order deletion is allowed.
     */
    public void validateForDeletion(Long orderId) {
        if (orderId == null) {
            throw new InvalidCustomerDataException("id", "Order ID is required for deletion");
        }

        TransportOrder order = transportOrderRepository.findById(orderId)
                .orElseThrow(() -> new OrderNotFoundException(orderId));

        // Cannot delete orders with active statuses
        if (ACTIVE_STATUSES.contains(order.getStatus())) {
            throw new InvalidCustomerDataException(
                    "status",
                    "Cannot delete order with active status: " + order.getStatus() +
                            ". Please cancel the order first."
            );
        }

        // Check if order has associated dispatches
        if (order.getDispatches() != null && !order.getDispatches().isEmpty()) {
            throw new InvalidCustomerDataException(
                    "dispatches",
                    "Cannot delete order with associated dispatches. Delete dispatches first."
            );
        }
    }

    /**
     * Validates order cancellation.
     */
    public void validateForCancellation(Long orderId, String reason) {
        if (orderId == null) {
            throw new InvalidCustomerDataException("id", "Order ID is required for cancellation");
        }

        TransportOrder order = transportOrderRepository.findById(orderId)
                .orElseThrow(() -> new OrderNotFoundException(orderId));

        // Cannot cancel already completed/delivered orders
        if (order.getStatus() == OrderStatus.DELIVERED ||
                order.getStatus() == OrderStatus.COMPLETED) {
            throw new InvalidCustomerDataException(
                    "status",
                    "Cannot cancel order with status: " + order.getStatus()
            );
        }

        // Cannot cancel already cancelled order
        if (order.getStatus() == OrderStatus.CANCELLED) {
            throw new InvalidCustomerDataException(
                    "status",
                    "Order is already cancelled"
            );
        }

        // Reason is required for cancellation
        if (reason == null || reason.trim().isEmpty()) {
            throw new InvalidCustomerDataException("reason", "Cancellation reason is required");
        }

        if (reason.length() > 500) {
            throw new InvalidCustomerDataException(
                    "reason",
                    "Cancellation reason cannot exceed 500 characters"
            );
        }
    }

    /**
     * Validates required fields.
     */
    private void validateRequiredFields(TransportOrder order) {
        if (order == null) {
            throw new InvalidCustomerDataException("order", "Transport order cannot be null");
        }

        if (order.getCustomer() == null) {
            throw new InvalidCustomerDataException("customer", "Customer is required");
        }

        if (order.getOrderDate() == null) {
            throw new InvalidCustomerDataException("orderDate", "Order date is required");
        }

        if (order.getStatus() == null) {
            throw new InvalidCustomerDataException("status", "Order status is required");
        }
    }

    /**
     * Validates customer exists and is active.
     */
    private void validateCustomer(Customer customer) {
        if (customer == null || customer.getId() == null) {
            throw new InvalidCustomerDataException("customer", "Valid customer is required");
        }

        Customer existingCustomer = customerRepository.findById(customer.getId())
                .orElseThrow(() -> new InvalidCustomerDataException(
                        "customer",
                        "Customer with ID " + customer.getId() + " not found"
                ));

        // Check customer is active
        if (existingCustomer.getStatus() != com.svtrucking.logistics.enums.Status.ACTIVE) {
            throw new InvalidCustomerDataException(
                    "customer",
                    "Customer " + existingCustomer.getName() + " is not active"
            );
        }
    }

    /**
     * Validates date constraints.
     */
    private void validateDateConstraints(TransportOrder order) {
        LocalDate today = LocalDate.now();

        // Order date cannot be too far in the past (more than 30 days)
        if (order.getOrderDate().isBefore(today.minusDays(30))) {
            throw new InvalidCustomerDataException(
                    "orderDate",
                    "Order date cannot be more than 30 days in the past"
            );
        }

        // Delivery date validation
        if (order.getDeliveryDate() != null) {
            // Delivery date must be on or after order date
            if (order.getDeliveryDate().isBefore(order.getOrderDate())) {
                throw new InvalidCustomerDataException(
                        "deliveryDate",
                        "Delivery date cannot be before order date"
                );
            }

            // Delivery date cannot be too far in the future (more than 1 year)
            if (order.getDeliveryDate().isAfter(today.plusYears(1))) {
                throw new InvalidCustomerDataException(
                        "deliveryDate",
                        "Delivery date cannot be more than 1 year in the future"
                );
            }
        }
    }

    /**
     * Validates order items.
     */
    private void validateOrderItems(List<OrderItem> items) {
        if (items == null || items.isEmpty()) {
            throw new InvalidCustomerDataException(
                    "items",
                    "Order must have at least one item"
            );
        }

        // Validate each item
        for (int i = 0; i < items.size(); i++) {
            OrderItem item = items.get(i);

            if (item.getItem() == null) {
                throw new InvalidCustomerDataException(
                        "items[" + i + "]",
                        "Item reference is required"
                );
            }

            double quantity = item.getQuantity();
            if (quantity <= 0) {
                throw new InvalidCustomerDataException(
                        "items[" + i + "].quantity",
                        "Item quantity must be greater than 0"
                );
            }

            if (quantity > 10000) {
                throw new InvalidCustomerDataException(
                        "items[" + i + "].quantity",
                        "Item quantity cannot exceed 10,000"
                );
            }

            // Validate weight if provided
            if (Double.compare(item.getWeight(), 0.0) < 0) {
                throw new InvalidCustomerDataException(
                        "items[" + i + "].weight",
                        "Item weight cannot be negative"
                );
            }
        }

        // Check for duplicate items
        long uniqueItemCount = items.stream()
                .map(item -> item.getItem().getId())
                .distinct()
                .count();

        if (uniqueItemCount < items.size()) {
            throw new InvalidCustomerDataException(
                    "items",
                    "Duplicate items found. Each item should appear only once with combined quantity."
            );
        }
    }

    /**
     * Validates order addresses.
     */
    private void validateAddresses(TransportOrder order) {
        // At least pickup or drop address must be provided
        boolean hasPickupAddress = order.getPickupAddress() != null ||
                (order.getPickupAddresses() != null && !order.getPickupAddresses().isEmpty());
        boolean hasDropAddress = order.getDropAddress() != null ||
                (order.getDropAddresses() != null && !order.getDropAddresses().isEmpty());

        if (!hasPickupAddress && !hasDropAddress) {
            throw new InvalidCustomerDataException(
                    "addresses",
                    "At least one pickup or drop address is required"
                );
        }

        // Validate individual addresses
        if (order.getPickupAddress() != null) {
            validateAddress(order.getPickupAddress(), "pickupAddress");
        }

        if (order.getDropAddress() != null) {
            validateAddress(order.getDropAddress(), "dropAddress");
        }

        // Validate multi-stop addresses
        if (order.getPickupAddresses() != null) {
            for (int i = 0; i < order.getPickupAddresses().size(); i++) {
                validateAddress(order.getPickupAddresses().get(i), "pickupAddresses[" + i + "]");
            }
        }

        if (order.getDropAddresses() != null) {
            for (int i = 0; i < order.getDropAddresses().size(); i++) {
                validateAddress(order.getDropAddresses().get(i), "dropAddresses[" + i + "]");
            }
        }
    }

    /**
     * Validates individual address.
     */
    private void validateAddress(CustomerAddress address, String fieldName) {
        if (address == null) {
            throw new InvalidCustomerDataException(fieldName, "Address cannot be null");
        }

        if (address.getAddress() == null || address.getAddress().trim().isEmpty()) {
            throw new InvalidCustomerDataException(
                    fieldName + ".address",
                    "Address is required"
            );
        }

        if (address.getName() == null || address.getName().trim().isEmpty()) {
            throw new InvalidCustomerDataException(
                fieldName + ".name",
                "Name is required"
            );
        }

        // Validate address length
        if (address.getAddress() != null && address.getAddress().length() > 500) {
            throw new InvalidCustomerDataException(
                fieldName + ".address",
                "Address cannot exceed 500 characters"
            );
        }
    }

    /**
     * Validates initial status for new orders.
     */
    private void validateInitialStatus(TransportOrder order) {
        if (order.getId() == null) {
            // New orders can only be PENDING or APPROVED
            if (order.getStatus() != OrderStatus.PENDING &&
                    order.getStatus() != OrderStatus.APPROVED) {
                throw new InvalidCustomerDataException(
                        "status",
                        "New orders must have status PENDING or APPROVED"
                );
            }
        }
    }

    /**
     * Validates business rules.
     */
    private void validateBusinessRules(TransportOrder order) {
        // Order reference validation if provided
        if (order.getOrderReference() != null) {
            if (order.getOrderReference().length() > 100) {
                throw new InvalidCustomerDataException(
                        "orderReference",
                        "Order reference cannot exceed 100 characters"
                );
            }

            // Check uniqueness if creating new order
            if (order.getId() == null) {
                boolean exists = transportOrderRepository
                        .existsByOrderReference(order.getOrderReference());
                if (exists) {
                    throw new InvalidCustomerDataException(
                            "orderReference",
                            "Order reference '" + order.getOrderReference() + "' already exists"
                    );
                }
            }
        }

        // Shipment type validation
        if (order.getShipmentType() != null && order.getShipmentType().length() > 50) {
            throw new InvalidCustomerDataException(
                    "shipmentType",
                    "Shipment type cannot exceed 50 characters"
            );
        }

        // Bill to validation
        if (order.getBillTo() != null && order.getBillTo().length() > 200) {
            throw new InvalidCustomerDataException(
                    "billTo",
                    "Bill to cannot exceed 200 characters"
            );
        }

        // Courier assigned validation
        if (order.getCourierAssigned() != null && order.getCourierAssigned().length() > 100) {
            throw new InvalidCustomerDataException(
                    "courierAssigned",
                    "Courier assigned cannot exceed 100 characters"
            );
        }
    }

    /**
     * Checks if status transition is valid.
     */
    private boolean isValidStatusTransition(OrderStatus from, OrderStatus to) {
        return switch (from) {
            case PENDING -> to == OrderStatus.APPROVED || to == OrderStatus.REJECTED ||
                    to == OrderStatus.CANCELLED || to == OrderStatus.ASSIGNED || to == OrderStatus.SCHEDULED;
            case APPROVED -> to == OrderStatus.SCHEDULED || to == OrderStatus.ASSIGNED ||
                    to == OrderStatus.CANCELLED;
            case REJECTED -> to == OrderStatus.PENDING || to == OrderStatus.CANCELLED;
            case SCHEDULED -> to == OrderStatus.ASSIGNED || to == OrderStatus.CANCELLED;
            case ASSIGNED -> to == OrderStatus.DRIVER_CONFIRMED || to == OrderStatus.CANCELLED;
            case DRIVER_CONFIRMED -> to == OrderStatus.ARRIVED_LOADING || to == OrderStatus.CANCELLED;
            case ARRIVED_LOADING -> to == OrderStatus.LOADING || to == OrderStatus.CANCELLED;
            case LOADING -> to == OrderStatus.LOADED || to == OrderStatus.CANCELLED;
            case LOADED -> to == OrderStatus.IN_TRANSIT || to == OrderStatus.CANCELLED;
            case IN_TRANSIT -> to == OrderStatus.ARRIVED_UNLOADING || to == OrderStatus.CANCELLED;
            case ARRIVED_UNLOADING -> to == OrderStatus.UNLOADING || to == OrderStatus.CANCELLED;
            case UNLOADING -> to == OrderStatus.UNLOADED || to == OrderStatus.CANCELLED;
            case UNLOADED -> to == OrderStatus.DELIVERED;
            case DELIVERED -> to == OrderStatus.COMPLETED;
            case COMPLETED, CANCELLED -> false; // Terminal states
        };
    }
}
