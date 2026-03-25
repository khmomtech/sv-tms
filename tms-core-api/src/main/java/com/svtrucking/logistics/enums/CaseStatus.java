package com.svtrucking.logistics.enums;

/**
 * Case processing status
 */
public enum CaseStatus {
  OPEN,                // Case created, investigation not started
  INVESTIGATION,       // Under investigation
  PENDING_APPROVAL,    // Investigation complete, awaiting approval
  CLOSED              // Case closed with resolution
}
