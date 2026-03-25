package com.svtrucking.logistics.enums;

/**
 * Specific types of incidents
 */
public enum IncidentType {
  // Traffic-related
  SPEEDING,
  HARSH_BRAKING,
  HARSH_ACCELERATION,
  SHARP_CORNERING,
  WRONG_ROUTE,
  
  // Behavior-related
  UNPROFESSIONAL_CONDUCT,
  POLICY_VIOLATION,
  UNAUTHORIZED_STOP,
  MISSED_SCHEDULE,
  
  // Customer-related
  CUSTOMER_COMPLAINT,
  DAMAGE_CLAIM,
  SERVICE_QUALITY_ISSUE,
  
  // Accident-related
  COLLISION,
  PROPERTY_DAMAGE,
  INJURY,
  
  // Vehicle-related
  MECHANICAL_FAILURE,
  BREAKDOWN,
  MAINTENANCE_DUE,
  
  // Other
  OTHER
}
