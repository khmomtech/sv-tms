/**
 * Shipment Tracking Module Exports
 * Public API for tracking feature
 */

export { ShipmentTrackingComponent } from './shipment-tracking.component';
export { TrackingTimelineComponent } from './tracking-timeline.component';
export { TrackingMapComponent } from './tracking-map.component';
export { ShipmentTrackingService } from '../../services/shipment-tracking.service';
export type {
  ShipmentStatus,
  StatusTimeline,
  GeoLocation,
  DriverInfo,
  ShipmentSummary,
  ShipmentItem,
  ProofOfDelivery,
  TrackingResponse,
  TrackingError,
} from '../../models/shipment-tracking.model';
export {
  STATUS_TIMELINE_ORDER,
  STATUS_DISPLAY_NAMES,
  STATUS_COLORS,
} from '../../models/shipment-tracking.model';
