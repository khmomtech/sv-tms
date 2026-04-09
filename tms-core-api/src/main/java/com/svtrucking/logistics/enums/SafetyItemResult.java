package com.svtrucking.logistics.enums;

import com.fasterxml.jackson.annotation.JsonCreator;
import com.fasterxml.jackson.annotation.JsonValue;

public enum SafetyItemResult {
  OK,
  NOT_OK,
  MISSING,
  YES_RISK;

  @JsonCreator
  public static SafetyItemResult from(String raw) {
    if (raw == null || raw.isBlank()) return null;
    try {
      return SafetyItemResult.valueOf(raw.trim().toUpperCase());
    } catch (Exception ex) {
      return null;
    }
  }

  @JsonValue
  public String jsonValue() {
    return this.name();
  }
}
