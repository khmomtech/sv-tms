package com.svtrucking.logistics.enums;

/**
 * Type of timeline entry for audit trail
 */
public enum TimelineEntryType {
  CREATED,               // Case created
  STATUS_CHANGE,         // Status changed
  TASK_ADDED,           // Task added
  TASK_COMPLETED,       // Task completed
  NOTE,                 // Manual note added
  EVIDENCE_UPLOADED,    // Evidence/attachment uploaded
  INCIDENT_LINKED,      // Incident linked to case
  INCIDENT_REMOVED,     // Incident removed from case
  ASSIGNED             // Case assigned/reassigned
}
