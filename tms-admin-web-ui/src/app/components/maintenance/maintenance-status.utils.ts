import type { MaintenanceRequestStatus } from '../../services/maintenance-request.service';
import type { WorkOrderStatus } from '../../services/maintenance-work-order.service';

export function getMaintenanceRequestStatusClass(status?: MaintenanceRequestStatus): string {
  switch (status) {
    case 'APPROVED':
      return 'border-emerald-200 bg-emerald-50 text-emerald-700';
    case 'SUBMITTED':
      return 'border-blue-200 bg-blue-50 text-blue-700';
    case 'REJECTED':
      return 'border-red-200 bg-red-50 text-red-700';
    case 'CANCELLED':
      return 'border-gray-200 bg-gray-50 text-gray-700';
    case 'DRAFT':
    default:
      return 'border-amber-200 bg-amber-50 text-amber-700';
  }
}

export function getWorkOrderStatusClass(status?: WorkOrderStatus): string {
  switch (status) {
    case 'COMPLETED':
      return 'border-emerald-200 bg-emerald-50 text-emerald-700';
    case 'IN_PROGRESS':
      return 'border-blue-200 bg-blue-50 text-blue-700';
    case 'WAITING_PARTS':
      return 'border-amber-200 bg-amber-50 text-amber-700';
    case 'CANCELLED':
      return 'border-gray-200 bg-gray-50 text-gray-700';
    case 'OPEN':
    default:
      return 'border-indigo-200 bg-indigo-50 text-indigo-700';
  }
}
