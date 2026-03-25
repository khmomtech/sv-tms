package com.svtrucking.logistics.enums;

/**
 * Source of the incident report
 */
public enum IncidentSource {
  DRIVER_APP,     // Reported by driver via mobile app
  SYSTEM,         // Auto-detected by system (telematics, GPS)
  CUSTOMER,       // Reported by customer
  DISPATCHER,     // Reported by dispatcher/admin
  EXTERNAL        // External source (police report, third party)
}
