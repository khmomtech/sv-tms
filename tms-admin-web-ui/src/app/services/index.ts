// Barrel export for all services
// This allows importing multiple services from a single source: import { DriverService, VehicleService } from '@services';

// Core services
export * from './auth.service';
export { SocketService } from './socket.service'; // Specific export to avoid PresenceStatus conflict
export * from './connection-monitor.service';
export { DriverLocationService as WebSocketDriverLocationService } from './web-socket.service'; // Specific export with alias

// Domain services
export * from './driver.service';
export * from './driver-detail.service';
export * from './driver-assignment.service';
export * from './driver-connection.service';
export * from './driver-performance.service';
export { DriverLocationService } from './driver-location.service';
export * from './vehicle.service';
export * from './order.service';
export * from './custommer.service';
export * from './dispatch.service';
export * from './shipment.service';
export * from './transport-order.service';
export * from './transport-order-list.service';

// Admin services
export * from './permission.service';
export * from './permission-guard.service';
export * from './role.service';
export * from './user.service';
export * from './dynamic-permission.service';

// Supporting services
export * from './notification.service';
export * from './admin-notification.service';
export * from './settings.service';
export * from './maps.service';
export * from './google-maps-loader.service';
export * from './customer-address.service';
export * from './address.service';
export * from './breadcrumb.service';

// Feature services
export * from './item.service';
export * from './device.service';
export * from './image-management.service';
export * from './load-proof.service';
export * from './maintenance-task.service';
export * from './maintenance-task-type.service';
export * from './maintenance-report.service';
export {
  MaintenanceRequestService,
  type MaintenanceRequestDto,
  type MaintenanceRequestStatus,
  type MaintenanceRequestType,
  type SafetyLevel,
  type MaintenanceAttachmentType,
  type MaintenanceRequestAttachmentDto,
  type Priority as MaintenanceRequestPriority,
} from './maintenance-request.service';
export {
  MaintenanceWorkOrderService,
  type WorkOrderDto,
  type WorkOrderStatus,
  type WorkOrderType,
  type RepairType,
  type WorkOrderTaskDto,
  type WorkOrderPartDto,
  type WorkOrderPhotoDto,
  type VendorQuotationDto,
  type InvoiceDto,
  type InvoiceAttachmentDto,
  type PaymentDto,
  type Priority as WorkOrderPriority,
} from './maintenance-work-order.service';
export * from './pm-plan.service';
export {
  PmPlanV2Service,
  type PmPlanDto,
  type PmPlanTriggerType,
  type PmPlanStatus,
} from './pm-plan-v2.service';
export {
  PmRunService,
  type PmRunDto,
  type PmRunStatus,
  type PmRunTriggeredBy,
  type PmDueStatus as PmRunDueStatus,
  type PmChecklistItemDto as PmRunChecklistItemDto,
} from './pm-run.service';
export * from './pm-dashboard.service';
export * from './pm-calendar.service';
export * from './pm-report.service';
export {
  PmChecklistService,
  type PmChecklistItemDto as PmTemplateChecklistItemDto,
  type PmChecklistTemplateDto,
} from './pm-checklist.service';
export {
  PmEventService,
  type PmEventRequest,
  type PmEventCode as PmEventTriggerCode,
} from './pm-event.service';
export * from './failure-code.service';
export * from './task.service';

// Upload services
export * from './khb-so-upload.service';

// Other services
export * from './audit-trail.service';
export * from './dashboard.service';
export * from './sso.service';
export * from './system-initialization.service';
export * from './refresh-token-admin.service';

// Validators
export * from './driver-form-validators';

// Models (transitional - these should be in @models)
export * from './customer-address-dto.model';
export * from './order-address.model';
export * from './order-item.model';
export * from './order-stop.model';

// Interceptors
export * from './auth.interceptor';
