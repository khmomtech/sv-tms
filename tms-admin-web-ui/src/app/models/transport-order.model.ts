import type { OrderAddressDto } from '../services/order-address.model';
import type { OrderItemDto } from '../services/order-item.model';
import type { Stop } from '../services/order-stop.model';

import type { Dispatch } from './dispatch.model';
import type { InvoiceDto } from './invoice.model';

export interface TransportOrder {
  id: number;
  orderReference: string;
  tripNo: string;
  customerId: number | string;
  customerName: string;
  billTo: string;
  orderDate: string | number | Date;
  deliveryDate: string | number | Date;
  createDate: string | number | Date;
  createdAt: string | number | Date;
  shipmentType: string;
  courierAssigned: string;
  status: string;

  createdBy: {
    username: string;
  };

  /**  Header-level addresses */
  pickupAddress: OrderAddressDto | null;
  dropAddress: OrderAddressDto | null;

  /**  List-level multiple addresses (for multi-stop support) */
  pickupAddresses: OrderAddressDto[];
  dropAddresses: OrderAddressDto[];

  /**  Line items in the order */
  items: OrderItemDto[];

  /**  List of dispatch plans (if any) */
  dispatches: Dispatch[];

  /**  Invoice information (nullable) */
  invoice: InvoiceDto | null;

  /**  Multi-stop route information */
  stops: Stop[];
  /** Order origin (e.g., IMPORT, BOOKING, MANUAL_ORDER, API) */
  origin?: string;

  /** Whether the order requires a driver to be assigned */
  requiresDriver?: boolean;
}
