package com.svtrucking.logistics.enums;

import com.fasterxml.jackson.annotation.JsonCreator;
import com.fasterxml.jackson.annotation.JsonValue;

public enum SafetyCheckStatus {
  UNKNOWN,
  PASSED,
  FAILED,
  SKIPPED;

  @JsonCreator
  public static SafetyCheckStatus from(String raw) {
    if (raw == null || raw.isBlank()) {
      return null;
    }
    try {
      return SafetyCheckStatus.valueOf(raw.trim().toUpperCase());
    } catch (Exception ex) {
      return null;
    }
  }

  @JsonValue
  public String jsonValue() {
    return this.name();
  }
}
