package com.svtrucking.logistics.enums;

/**
 * Types of partnership relationships with the TMS system
 */
public enum PartnershipType {
  /** Partner provides drivers and vehicles to the platform */
  DRIVER_FLEET,
  
  /** Partner is a corporate customer with regular shipping needs */
  CUSTOMER_CORPORATE,
  
  /** Partner provides both drivers and is also a customer */
  FULL_SERVICE,
  
  /** Logistics partner (warehousing, cross-docking, etc.) */
  LOGISTICS_PROVIDER,
  
  /** Technology integration partner */
  TECHNOLOGY_PARTNER
}
