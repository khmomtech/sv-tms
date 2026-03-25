package com.svtrucking.logistics.enums;

/**
 * Vehicle type classification for fleet management.
 * 
 * <p>Groups vehicles by their primary function and size category.
 * This enum is used for fleet categorization, assignment rules, and reporting.
 * 
 * @see com.svtrucking.logistics.model.Vehicle
 */
public enum VehicleType {
  
  // Commercial Trucks
  /** Large commercial truck for heavy freight (Class 7-8) */
  BIG_TRUCK("Big Truck", "Commercial", true),
  
  /** Standard truck for general freight (Class 6-7) */
  TRUCK("Truck", "Commercial", true),
  
  /** Trailer unit that attaches to trucks */
  TRAILER("Trailer", "Commercial", false),
  
  // Vans
  /** Small commercial van for light deliveries */
  SMALL_VAN("Small Van", "Van", true),
  
  /** Standard commercial van for deliveries */
  VAN("Van", "Van", true),
  
  // Passenger Vehicles
  /** Sport Utility Vehicle for executive transport */
  SUV("SUV", "Passenger", true),
  
  /** Standard passenger car */
  CAR("Car", "Passenger", true),
  
  /** Passenger bus for group transport */
  BUS("Bus", "Passenger", true),
  
  // Specialty Vehicles
  /** Motorcycle or scooter for quick deliveries */
  MOTORBIKE("Motorbike", "Specialty", true),
  
  /** Electric vehicle (any type) */
  ELECTRIC("Electric", "Specialty", true),
  
  // Fallback Categories
  /** Other vehicle type not listed above */
  OTHER("Other", "Other", true),
  
  /** Unknown or unspecified vehicle type */
  UNKNOWN("Unknown", "Unknown", true);
  
  private final String displayName;
  private final String category;
  private final boolean canBeAssignedToDriver;
  
  VehicleType(String displayName, String category, boolean canBeAssignedToDriver) {
    this.displayName = displayName;
    this.category = category;
    this.canBeAssignedToDriver = canBeAssignedToDriver;
  }
  
  /**
   * @return Human-readable display name for UI
   */
  public String getDisplayName() {
    return displayName;
  }
  
  /**
   * @return Vehicle category for grouping (Commercial, Van, Passenger, Specialty, Other)
   */
  public String getCategory() {
    return category;
  }
  
  /**
   * @return true if this vehicle type can be directly assigned to a driver
   */
  public boolean canBeAssignedToDriver() {
    return canBeAssignedToDriver;
  }
  
  /**
   * Check if this is a commercial freight vehicle
   */
  public boolean isCommercialVehicle() {
    return "Commercial".equals(category) && this != TRAILER;
  }
  
  /**
   * Check if this is a trailer type
   */
  public boolean isTrailer() {
    return this == TRAILER;
  }
  
  /**
   * Check if this vehicle type requires special licensing
   */
  public boolean requiresCommercialLicense() {
    return this == BIG_TRUCK || this == TRUCK || this == BUS;
  }
}
