package com.svtrucking.logistics.enums;

import com.fasterxml.jackson.annotation.JsonCreator;
import com.fasterxml.jackson.annotation.JsonValue;

public enum WarehouseCode {
  KHB,
  W1,
  W2,
  W3;

  /**
   * Accept legacy aliases while moving to canonical site codes.
   */
  public static WarehouseCode from(String code) {
    if (code == null || code.isBlank()) {
      return null;
    }
    final String normalized = code.trim().toUpperCase();
    try {
      return switch (normalized) {
        case "KHB", "W1" -> KHB;
        default -> WarehouseCode.valueOf(normalized);
      };
    } catch (IllegalArgumentException ex) {
      return null;
    }
  }

  @JsonCreator
  public static WarehouseCode fromJson(String code) {
    return from(code);
  }

  @JsonValue
  public String jsonValue() {
    return name();
  }
}
