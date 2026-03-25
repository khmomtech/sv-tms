package com.svtrucking.logistics.enums;

public enum WarehouseCode {
  W1,
  W2,
  W3;

  public static WarehouseCode from(String code) {
    if (code == null || code.isBlank()) {
      return null;
    }
    return WarehouseCode.valueOf(code.trim().toUpperCase());
  }
}
