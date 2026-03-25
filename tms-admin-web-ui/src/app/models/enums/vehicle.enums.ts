// src/app/models/vehicle.enums.ts

/** 🔧 Vehicle Type Enum */
export enum VehicleType {
  TRUCK = 'TRUCK',
  VAN = 'VAN',
  CAR = 'CAR',
  BUS = 'BUS',
  MOTORBIKE = 'MOTORBIKE',
  SUV = 'SUV',
  ELECTRIC = 'ELECTRIC',
  TRAILER = 'TRAILER',
  OTHER = 'OTHER',
}

/** ⚙️ Vehicle Status Enum */
export enum VehicleStatus {
  ACTIVE = 'ACTIVE',
  UNDER_REPAIR = 'UNDER_REPAIR',
  SAFETY_HOLD = 'SAFETY_HOLD',
  RETIRED = 'RETIRED',
  AVAILABLE = 'AVAILABLE',
  IN_USE = 'IN_USE',
  MAINTENANCE = 'MAINTENANCE',
  IN_ISSUE = 'IN_ISSUE',
  OUT_OF_SERVICE = 'OUT_OF_SERVICE',
}

/** 🏢 Vehicle Ownership Enum */
export enum VehicleOwnership {
  OWNED = 'OWNED',
  LEASED = 'LEASED',
  VENDOR = 'VENDOR',
}

/**  Truck Size Enum */
export enum TruckSize {
  SMALL_VAN = 'SMALL_VAN',
  MEDIUM_TRUCK = 'MEDIUM_TRUCK',
  BIG_TRUCK = 'BIG_TRUCK',
}
