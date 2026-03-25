export interface DispatchStop {
  id?: number;
  location: string;
  type: 'PICKUP' | 'DROPOFF';
  latitude: number;
  longitude: number;
  stopTime?: string; // ISO format
}
