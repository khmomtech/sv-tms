import type { VehicleTypeEnum } from './driver.model';

export type ActivityFilter = 'all' | 'active' | 'inactive';
export type AccountFilter = 'any' | 'with' | 'without';

export interface DriverListFilters {
  query: string;
  activity: ActivityFilter;
  driverStatuses: string[];
  vehicleType: VehicleTypeEnum | '';
  zone: string;
  account: AccountFilter;
  minRating?: number;
  maxRating?: number;
  licensePlate?: string;
  employmentStatus?: string | '';
}
