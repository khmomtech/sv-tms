import { CustomerAddressService } from './customer-address.service';
import type { CustomerAddress } from '../models/customer-address.model';

export { CustomerAddressService as AddressService };
export type { CustomerAddress };
export type OrderAddress = CustomerAddress;
