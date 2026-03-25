import type { Routes } from '@angular/router';

export const ORDERS_ROUTES: Routes = [
  {
    path: '',
    loadComponent: () =>
      import('../../components/transport-order-list/transport-order-list.component').then(
        (m) => m.TransportOrderListComponent,
      ),
    data: { title: 'Orders' },
  },
  {
    path: 'create',
    loadComponent: () =>
      import('../../components/transport-order/transport-order.component').then(
        (m) => m.TransportOrderComponent,
      ),
    data: { title: 'Create Order' },
  },
  {
    path: ':id/edit',
    loadComponent: () =>
      import('../../components/transport-order/transport-order.component').then(
        (m) => m.TransportOrderComponent,
      ),
    data: { title: 'Edit Order' },
  },
  {
    path: 'upload',
    loadComponent: () =>
      import('../../components/order-list/bulk-order-upload/bulk-order-upload.component').then(
        (m) => m.BulkOrderUploadComponent,
      ),
    data: { title: 'Bulk Order Upload' },
  },
  {
    path: 'pending',
    loadComponent: () =>
      import('./pending-orders/pending-orders.component').then((m) => m.PendingOrdersComponent),
    data: { title: 'Pending Orders' },
  },
  {
    path: 'completed',
    loadComponent: () =>
      import('./completed-orders/completed-orders.component').then(
        (m) => m.CompletedOrdersComponent,
      ),
    data: { title: 'Completed Orders' },
  },
  {
    path: 'maps',
    loadComponent: () =>
      import('../../transport-order-maps/transport-order-maps.component').then(
        (m) => m.TransportOrderMapsComponent,
      ),
    data: { title: 'Order Maps' },
  },
  {
    path: ':id/tracking',
    loadComponent: () => import('./tracking/tracking.component').then((m) => m.TrackingComponent),
    data: { title: 'Shipment Tracking' },
  },
  {
    path: ':id/picking-list',
    loadComponent: () =>
      import('../../components/order-picking-list/order-picking-list.component').then(
        (m) => m.OrderPickingListComponent,
      ),
    data: { title: 'Picking List' },
  },
  {
    path: ':id',
    loadComponent: () =>
      import('../../components/transport-order-view/transport-order-view.component').then(
        (m) => m.TransportOrderViewComponent,
      ),
    data: { title: 'Order Details' },
  },
  {
    path: ':id/delivery-note',
    loadComponent: () =>
      import('../../components/delivery-note/delivery-note.component').then(
        (m) => m.DeliveryNoteComponent,
      ),
    data: { title: 'Delivery Note' },
  },
];
