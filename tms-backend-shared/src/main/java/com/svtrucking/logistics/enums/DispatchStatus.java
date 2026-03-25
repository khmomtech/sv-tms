package com.svtrucking.logistics.enums;

import com.fasterxml.jackson.annotation.JsonCreator;
import com.fasterxml.jackson.annotation.JsonValue;

public enum DispatchStatus {
  PLANNED,
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
  IN_TRANSIT_BREAKDOWN,
  PENDING_INVESTIGATION,
  AT_HUB,
  HUB_LOADING,
  ARRIVED_UNLOADING,
  UNLOADING,
  UNLOADED,
  DELIVERED,
  FINANCIAL_LOCKED,
  CLOSED,
  COMPLETED,
  CANCELLED;

  @JsonCreator
  public static DispatchStatus from(String raw) {
    if (raw == null || raw.isBlank()) {
      return null;
    }
    String value = raw.trim().toUpperCase();
    if ("DRIVER_ACCEPTED".equals(value)) {
      return DRIVER_CONFIRMED;
    }
    if ("SCHEDULED".equals(value)) {
      return SCHEDULED;
    }
    return DispatchStatus.valueOf(value);
  }

  @JsonValue
  public String jsonValue() {
    return this.name();
  }

  public OrderStatus toOrderStatus() {
    switch (this) {
      case PLANNED:
      case PENDING:
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
      case SAFETY_FAILED:
        return null;
      case IN_QUEUE:
        return OrderStatus.ARRIVED_LOADING;
      case IN_TRANSIT:
      case IN_TRANSIT_BREAKDOWN:
      case PENDING_INVESTIGATION:
      case AT_HUB:
      case HUB_LOADING:
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
      case CLOSED:
        return OrderStatus.COMPLETED;
      case APPROVED:
        return OrderStatus.APPROVED;
      case REJECTED:
        return OrderStatus.REJECTED;
      default:
        return null;
    }
  }

  public static DispatchStatus fromOrderStatus(OrderStatus os) {
    if (os == null) {
      return null;
    }
    switch (os) {
      case PENDING:
        return PLANNED;
      case ASSIGNED:
        return ASSIGNED;
      case DRIVER_CONFIRMED:
        return DRIVER_CONFIRMED;
      case APPROVED:
        return APPROVED;
      case REJECTED:
        return REJECTED;
      case SCHEDULED:
        return PLANNED;
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
