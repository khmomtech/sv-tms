package com.svtrucking.logistics.enums;

/**
 * Vehicle type classification for fleet management.
 */
public enum VehicleType {

  BIG_TRUCK("Big Truck", "Commercial", true),
  TRUCK("Truck", "Commercial", true),
  TRAILER("Trailer", "Commercial", false),
  SMALL_VAN("Small Van", "Van", true),
  VAN("Van", "Van", true),
  SUV("SUV", "Passenger", true),
  CAR("Car", "Passenger", true),
  BUS("Bus", "Passenger", true),
  MOTORBIKE("Motorbike", "Specialty", true),
  ELECTRIC("Electric", "Specialty", true),
  OTHER("Other", "Other", true),
  UNKNOWN("Unknown", "Unknown", true);

  private final String displayName;
  private final String category;
  private final boolean canBeAssignedToDriver;

  VehicleType(String displayName, String category, boolean canBeAssignedToDriver) {
    this.displayName = displayName;
    this.category = category;
    this.canBeAssignedToDriver = canBeAssignedToDriver;
  }

  public String getDisplayName() {
    return displayName;
  }

  public String getCategory() {
    return category;
  }

  public boolean canBeAssignedToDriver() {
    return canBeAssignedToDriver;
  }

  public boolean isCommercialVehicle() {
    return "Commercial".equals(category) && this != TRAILER;
  }

  public boolean isTrailer() {
    return this == TRAILER;
  }

  public boolean requiresCommercialLicense() {
    return this == BIG_TRUCK || this == TRUCK || this == BUS;
  }
}
