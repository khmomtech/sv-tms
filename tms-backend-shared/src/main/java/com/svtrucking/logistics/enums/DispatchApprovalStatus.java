package com.svtrucking.logistics.enums;

import com.fasterxml.jackson.annotation.JsonCreator;
import com.fasterxml.jackson.annotation.JsonValue;
import lombok.AllArgsConstructor;
import lombok.Getter;

@Getter
@AllArgsConstructor
public enum DispatchApprovalStatus {
  NONE("NONE", "No approval required"),
  PENDING_APPROVAL("PENDING_APPROVAL", "Pending dispatcher approval"),
  APPROVED("APPROVED", "Approved by dispatcher"),
  REJECTED("REJECTED", "Rejected - needs resubmission"),
  ON_HOLD("ON_HOLD", "On hold pending investigation");

  private final String value;
  private final String description;

  @JsonValue
  public String getValue() {
    return value;
  }

  @JsonCreator
  public static DispatchApprovalStatus fromValue(String value) {
    if (value == null) {
      return NONE;
    }
    for (DispatchApprovalStatus status : DispatchApprovalStatus.values()) {
      if (status.value.equalsIgnoreCase(value)) {
        return status;
      }
    }
    return NONE;
  }
}
