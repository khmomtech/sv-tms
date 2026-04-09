export interface CustomerAddress {
  id: number;
  name: string;
  address: string;
  city: string;
  country: string;
  postcode?: string;
  scheduledTime?: string;
  contactName?: string;
  contactPhone?: string;
  longitude: number;
  latitude: number;
  type?: string;
  customerId?: number;
}
