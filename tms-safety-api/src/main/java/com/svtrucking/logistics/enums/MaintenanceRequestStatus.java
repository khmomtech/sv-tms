package com.svtrucking.logistics.enums;

/**
 * SV Standard maintenance request lifecycle.
 * - All maintenance starts from a Maintenance Request (MR).
 */
public enum MaintenanceRequestStatus {
  DRAFT,
  SUBMITTED,
  APPROVED,
  REJECTED,
  CANCELLED
}

