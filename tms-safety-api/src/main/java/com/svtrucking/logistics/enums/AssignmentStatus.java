package com.svtrucking.logistics.enums;

public enum AssignmentStatus {
  ASSIGNED, // Actively assigned and in use
  ACTIVE,
  UNASSIGNED, // Driver was unassigned (manually or auto)
  COMPLETED, // Assignment completed as planned
  CANCELED, // Assignment was canceled before completion
  EXPIRED // Optional: assignment expired due to time/rules (future use)
}
