export interface LocationHistory {
  id: number; // Unique ID for the location record
  driverId: number; // Foreign key to the Driver
  latitude: number; // Latitude coordinate
  longitude: number; // Longitude coordinate
  timestamp: string; // ISO timestamp (e.g. "2025-06-12T09:45:00Z")
  speed?: number; // Optional: speed in km/h or m/s
  heading?: number; // Optional: direction of movement in degrees (0–360)
  altitude?: number; // Optional: altitude in meters
  accuracy?: number; // Optional: GPS accuracy in meters
  eventType?: string; // Optional: event type (e.g., 'STOP', 'MOVE', etc.)
}
