package com.svtrucking.logistics.enums;

import com.fasterxml.jackson.annotation.JsonCreator;
import com.fasterxml.jackson.annotation.JsonValue;

public enum SafetySeverity {
  LOW,
  MEDIUM,
  HIGH;

  @JsonCreator
  public static SafetySeverity from(String raw) {
    if (raw == null || raw.isBlank()) return null;
    try {
      return SafetySeverity.valueOf(raw.trim().toUpperCase());
    } catch (Exception ex) {
      return null;
    }
  }

  @JsonValue
  public String jsonValue() {
    return this.name();
  }
}
