package com.svtrucking.logistics.enums;

import com.fasterxml.jackson.annotation.JsonCreator;
import com.fasterxml.jackson.annotation.JsonValue;

public enum DailySafetyCheckStatus {
  NOT_STARTED,
  DRAFT,
  WAITING_APPROVAL,
  APPROVED,
  REJECTED;

  @JsonCreator
  public static DailySafetyCheckStatus from(String raw) {
    if (raw == null || raw.isBlank()) return null;
    try {
      return DailySafetyCheckStatus.valueOf(raw.trim().toUpperCase());
    } catch (Exception ex) {
      return null;
    }
  }

  @JsonValue
  public String jsonValue() {
    return this.name();
  }
}
