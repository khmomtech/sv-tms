/**
 * Shipment Tracking Routes Configuration
 * Provides public tracking feature routes
 */

import { Routes } from '@angular/router';
import { ShipmentTrackingComponent } from './shipment-tracking.component';

/**
 * Tracking feature routes
 * - /tracking - main tracking page with search
 * - /tracking/:ref - auto-load tracking for reference (e.g., /tracking/2025345-00001)
 * - /tracking?ref=BOOKING_REF - query param support
 *
 * Usage in app.routes.ts:
 * {
 *   path: 'tracking',
 *   loadChildren: () => import('./components/shipment-tracking/tracking.routes').then(m => m.TRACKING_ROUTES)
 * }
 */
export const TRACKING_ROUTES: Routes = [
  {
    path: '',
    component: ShipmentTrackingComponent,
    data: { title: 'Track Shipment', description: 'Public shipment tracking' },
  },
  {
    path: ':ref',
    component: ShipmentTrackingComponent,
    data: { title: 'Track Shipment', description: 'Public shipment tracking' },
  },
];
