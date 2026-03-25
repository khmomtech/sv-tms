package com.svtrucking.logistics.enums;

/**
 * Unified Task Status for all task types across the system
 * Used by: CaseTask, MaintenanceTask, WorkOrderTask, and new unified Task entity
 */
public enum TaskStatus {
  OPEN,           // Task created, not started
  IN_PROGRESS,    // Currently being worked on
  BLOCKED,        // Blocked by dependencies or issues
  ON_HOLD,        // Paused, waiting for something
  IN_REVIEW,      // Waiting for approval/review
  COMPLETED,      // Done
  CANCELLED       // Cancelled/abandoned
}
