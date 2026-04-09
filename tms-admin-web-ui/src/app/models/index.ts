// Barrel export for all models
// This allows importing multiple models from a single source: import { Driver, Vehicle } from '@models';

// Domain models
export * from './driver.model';
export * from './vehicle.model';
export * from './order.model';
export * from './customer.model';
export * from './transport-order.model';
export * from './dispatch.model';
export * from './shipment.model';
// export * from './fleet.model'; // Empty file

// Supporting models
export * from './api-response.model';
export * from './api-response-page.model';
export * from './api-page-result.model';
export * from './page.model';
export * from './permission.model';
export { type Role } from './role.model'; // Specific export to avoid conflict
export * from './user.model';

// Documents
export * from './driver-document.model';
export * from './driver-license.model';
export * from './document.model';
export * from './inspection.model';
export * from './service-history.model';

// Driver related
export * from './driver-assignment.model';
export * from './driver-simple.model';
export * from './driver.dto.ts';

// Order related
export * from './customer-address.model';
export * from './order-address.model';
export * from './item.model';
export * from './invoice.model';

// Dispatch related
export * from './dispatch-item.model';
export * from './dispatch-stop.model';
export * from './dispatch-status-history.model';

// Vehicle related
// export * from './vehicle-status.model'; // Commented - exported in enums/vehicle.enums
// export * from './vehicle-type.model'; // Commented - exported in enums/vehicle.enums

// Maintenance
// export * from './maintenance-task.model'; // Duplicate - now in task.model.ts
export * from './maintenance-task-type.model';

// Task Management
export * from './task.model';

// Other
export * from './notification.model';
export * from './audit-trail.model';
export * from './load-proof.model';
export * from './location-history.model';
export * from './device-register.dto';
export * from './CompanyDetails';
export * from './IndividualDetails';
export * from './transport-order-response.model';

// Enums
export * from './order-status.enum';
export * from './dispatch-status.enum';
// export * from './enums/driver.enums'; // File does not exist
export * from './enums/vehicle.enums';
