package com.svtrucking.logistics.enums;

import com.fasterxml.jackson.annotation.JsonCreator;
import com.fasterxml.jackson.annotation.JsonValue;
import lombok.AllArgsConstructor;
import lombok.Getter;

@Getter
@AllArgsConstructor
public enum PreEntrySafetyStatus {
  NOT_STARTED("NOT_STARTED", "Inspection not started"),
  IN_PROGRESS("IN_PROGRESS", "Inspection in progress"),
  PASSED("PASSED", "All safety checks passed"),
  FAILED("FAILED", "Critical safety issues found"),
  CONDITIONAL("CONDITIONAL", "Minor issues - supervisor override needed");

  private final String value;
  private final String description;

  @JsonValue
  public String getValue() {
    return value;
  }

  @JsonCreator
  public static PreEntrySafetyStatus fromValue(String value) {
    if (value == null) {
      return NOT_STARTED;
    }
    for (PreEntrySafetyStatus status : PreEntrySafetyStatus.values()) {
      if (status.value.equalsIgnoreCase(value)) {
        return status;
      }
    }
    return NOT_STARTED;
  }
}
