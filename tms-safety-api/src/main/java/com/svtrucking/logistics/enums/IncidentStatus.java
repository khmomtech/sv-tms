package com.svtrucking.logistics.enums;

/**
 * Incident processing status
 */
public enum IncidentStatus {
  NEW,            // Just reported, not yet reviewed
  VALIDATED,      // Reviewed and confirmed as valid
  LINKED_TO_CASE, // Escalated to a case
  CLOSED          // Resolved without case escalation
}
