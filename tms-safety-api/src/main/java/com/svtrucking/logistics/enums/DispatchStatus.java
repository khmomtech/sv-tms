package com.svtrucking.logistics.enums;

import com.fasterxml.jackson.annotation.JsonCreator;
import com.fasterxml.jackson.annotation.JsonValue;
import com.svtrucking.logistics.enums.OrderStatus;

public enum DispatchStatus {
  PENDING,
  ASSIGNED,
  DRIVER_CONFIRMED,
  APPROVED,
  REJECTED,
  SCHEDULED,
  ARRIVED_LOADING,
  LOADING,
  LOADED,
  SAFETY_PASSED,
  SAFETY_FAILED,
  IN_QUEUE,
  IN_TRANSIT,
  ARRIVED_UNLOADING,
  UNLOADING,
  UNLOADED,
  DELIVERED,
  COMPLETED,
  CANCELLED;

  /**
   * Lenient enum factory to accept legacy/alt labels (e.g., PLANNED) and case-insensitive input.
   */
  @JsonCreator
  public static DispatchStatus from(String raw) {
    if (raw == null || raw.isBlank()) return null;
    String value = raw.trim().toUpperCase();
    // Accept PLANNED as SCHEDULED for backward compatibility with UI payloads
    if ("PLANNED".equals(value)) {
      return SCHEDULED;
    }
    return DispatchStatus.valueOf(value);
  }

  @JsonValue
  public String jsonValue() {
    return this.name();
  }

  /**
   * Map this DispatchStatus to the corresponding OrderStatus according to business rules.
   * Returns null when no reasonable mapping exists.
   */
  public OrderStatus toOrderStatus() {
    switch (this) {
      case PENDING:
        return OrderStatus.PENDING;
      case SCHEDULED:
        return OrderStatus.PENDING;
      case ASSIGNED:
        return OrderStatus.ASSIGNED;
      case DRIVER_CONFIRMED:
        return OrderStatus.DRIVER_CONFIRMED;
      case ARRIVED_LOADING:
        return OrderStatus.ARRIVED_LOADING;
      case LOADING:
        return OrderStatus.LOADING;
      case LOADED:
        return OrderStatus.LOADED;
      case SAFETY_PASSED:
        // Safety checks are orthogonal to order lifecycle; do not change OrderStatus here.
        return null;
      case SAFETY_FAILED:
        // Safety failures should not alter the transport order lifecycle directly.
        return null;
      case IN_QUEUE:
        return OrderStatus.ARRIVED_LOADING;
      case IN_TRANSIT:
        return OrderStatus.IN_TRANSIT;
      case ARRIVED_UNLOADING:
        return OrderStatus.ARRIVED_UNLOADING;
      case UNLOADING:
        return OrderStatus.UNLOADING;
      case UNLOADED:
        return OrderStatus.UNLOADED;
      case DELIVERED:
        return OrderStatus.DELIVERED;
      case CANCELLED:
        return OrderStatus.CANCELLED;
      case COMPLETED:
        return OrderStatus.COMPLETED;
      case APPROVED:
        return OrderStatus.APPROVED;
      case REJECTED:
        return OrderStatus.REJECTED;
      default:
        return null;
    }
  }

  /**
   * Create a DispatchStatus from an OrderStatus when possible. Returns null if no direct mapping.
   */
  public static DispatchStatus fromOrderStatus(OrderStatus os) {
    if (os == null) return null;
    switch (os) {
      case PENDING:
        return PENDING;
      case ASSIGNED:
        return ASSIGNED;
      case DRIVER_CONFIRMED:
        return DRIVER_CONFIRMED;
      case APPROVED:
        return APPROVED;
      case REJECTED:
        return REJECTED;
      case SCHEDULED:
        return SCHEDULED;
      case ARRIVED_LOADING:
        return ARRIVED_LOADING;
      case LOADING:
        return LOADING;
      case LOADED:
        return LOADED;
      case IN_TRANSIT:
        return IN_TRANSIT;
      case ARRIVED_UNLOADING:
        return ARRIVED_UNLOADING;
      case UNLOADING:
        return UNLOADING;
      case UNLOADED:
        return UNLOADED;
      case DELIVERED:
        return DELIVERED;
      case COMPLETED:
        return COMPLETED;
      case CANCELLED:
        return CANCELLED;
      default:
        return null;
    }
  }
}
