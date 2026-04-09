import type { Routes } from '@angular/router';

import { DriverDocumentsGuard } from '../../guards/driver-documents.guard';
import { PermissionGuard } from '../../guards/permission.guard';
import { DriverDocumentsResolver } from '../../resolvers/driver-documents.resolver';
import { PERMISSIONS } from '../../shared/permissions';

export const FLEET_ROUTES: Routes = [
  {
    path: '',
    redirectTo: 'drivers',
    pathMatch: 'full',
  },
  {
    path: 'drivers',
    data: { title: 'Drivers' },
    children: [
      {
        path: '',
        canActivate: [PermissionGuard],
        data: { permissions: [PERMISSIONS.DRIVER_LIST] },
        loadComponent: () =>
          import('../drivers/driver-list/driver-list.component').then((m) => m.DriverListComponent),
      },
      {
        path: 'create',
        canActivate: [PermissionGuard],
        loadComponent: () =>
          import('../drivers/driver-list/driver-list.component').then((m) => m.DriverListComponent),
        data: {
          title: 'Create Driver',
          permissions: [PERMISSIONS.DRIVER_CREATE],
          action: 'create',
        },
      },
      {
        path: 'documents',
        canActivate: [PermissionGuard, DriverDocumentsGuard],
        loadComponent: () =>
          import('../../components/drivers/documents/driver-documents.component').then(
            (m) => m.DriverDocumentsComponent,
          ),
        resolve: {
          driverData: DriverDocumentsResolver,
        },
        data: {
          title: 'Driver Documents',
          permissions: [PERMISSIONS.DRIVER_DOCUMENTS_READ, PERMISSIONS.DRIVER_VIEW_ALL],
        },
      },
      {
        path: 'shifts',
        canActivate: [PermissionGuard],
        loadComponent: () =>
          import('../../components/drivers/shifts/driver-shifts.component').then(
            (m) => m.DriverShiftsComponent,
          ),
        data: { title: 'Driver Shifts', permissions: [PERMISSIONS.DRIVER_SCHEDULE_READ] },
      },
      {
        path: 'accounts',
        canActivate: [PermissionGuard],
        loadComponent: () =>
          import('../../components/drivers/accounts/driver-accounts.component').then(
            (m) => m.DriverAccountsComponent,
          ),
        data: { title: 'Driver Accounts', permissions: [PERMISSIONS.DRIVER_ACCOUNT_MANAGE] },
      },
      {
        path: 'groups',
        canActivate: [PermissionGuard],
        loadComponent: () =>
          import('../../components/drivers/driver-groups.component').then(
            (m) => m.DriverGroupsComponent,
          ),
        data: { title: 'Driver Groups', permissions: [PERMISSIONS.DRIVER_MANAGE] },
      },
      {
        path: 'performance',
        canActivate: [PermissionGuard],
        loadComponent: () =>
          import('../../components/drivers/performance/driver-performance.component').then(
            (m) => m.DriverPerformanceComponent,
          ),
        data: { title: 'Driver Performance', permissions: [PERMISSIONS.REPORT_DRIVER_PERFORMANCE] },
      },
      {
        path: 'devices',
        canActivate: [PermissionGuard],
        loadComponent: () =>
          import('../../components/devices/device.component').then((m) => m.DeviceComponent),
        data: { title: 'Driver Devices', permissions: [PERMISSIONS.DRIVER_MANAGE] },
      },
      {
        path: 'attendance',
        canActivate: [PermissionGuard],
        loadComponent: () =>
          import('../../components/drivers/attendance/driver-attendance.component').then(
            (m) => m.DriverAttendanceComponent,
          ),
        data: { title: 'Driver Attendance', permissions: [PERMISSIONS.DRIVER_SCHEDULE_READ] },
      },
      {
        path: ':id',
        canActivate: [PermissionGuard],
        loadComponent: () =>
          import('../../components/drivers/driver-detail/driver-detail.component').then(
            (m) => m.DriverDetailComponent,
          ),
        data: {
          title: 'Driver Details',
          permissions: [PERMISSIONS.DRIVER_READ, PERMISSIONS.DRIVER_VIEW_ALL],
        },
      },
      {
        path: ':id/location-history',
        canActivate: [PermissionGuard],
        loadComponent: () =>
          import('../../components/drivers/location/driver-location-history.component').then(
            (m) => m.DriverLocationHistoryComponent,
          ),
        data: {
          title: 'Driver Location History',
          permissions: [PERMISSIONS.DRIVER_READ, PERMISSIONS.DRIVER_VIEW_ALL],
        },
      },
    ],
  },
  {
    path: 'vehicles',
    data: { title: 'Vehicles' },
    children: [
      {
        path: '',
        loadComponent: () =>
          import('../../components/vehicle/vehicle.component').then((m) => m.VehicleComponent),
      },
      {
        path: 'setup',
        loadComponent: () =>
          import('../../components/vehicle/pages/vehicle-setup/vehicle-setup.component').then(
            (m) => m.VehicleSetupComponent,
          ),
        data: { title: 'Vehicle Master Setup' },
      },
      {
        path: 'create',
        canActivate: [PermissionGuard],
        loadComponent: () =>
          import('../../components/vehicle/vehicle.component').then((m) => m.VehicleComponent),
        data: {
          title: 'Create Vehicle',
          permissions: [PERMISSIONS.VEHICLE_CREATE],
          action: 'create',
        },
      },
      {
        path: 'documents',
        loadComponent: () =>
          import('../../components/vehicle/pages/vehicle-document-list/vehicle-document-list').then(
            (m) => m.VehicleDocumentListComponent,
          ),
        data: { title: 'Vehicle Documents' },
      },
      {
        path: 'inspections',
        loadComponent: () =>
          import('../../components/vehicle/pages/vehicle-inspection-list/vehicle-inspection-list').then(
            (m) => m.VehicleInspectionListComponent,
          ),
        data: { title: 'Vehicle Inspections' },
      },
      {
        path: 'assignments',
        canActivate: [PermissionGuard],
        loadComponent: () =>
          import('../../components/vehicle/pages/vehicle-assignment-list/vehicle-assignment-list').then(
            (m) => m.VehicleAssignmentListComponent,
          ),
        data: {
          title: 'Vehicle Assignments',
          permissions: [PERMISSIONS.DRIVER_MANAGE, PERMISSIONS.VEHICLE_UPDATE],
        },
      },
      {
        path: 'map',
        loadComponent: () =>
          import('../../components/vehicle/pages/vehicle-location-map/vehicle-location-map').then(
            (m) => m.VehicleLocationMapComponent,
          ),
        data: { title: 'Vehicle Location Map' },
      },
      {
        path: ':id',
        loadComponent: () =>
          import('../../components/vehicle/pages/vehicle-detail.component').then(
            (m) => m.VehicleDetailComponent,
          ),
        data: { title: 'Vehicle Details' },
      },
    ],
  },
  {
    path: 'assign-truck-driver',
    canActivate: [PermissionGuard],
    loadComponent: () =>
      import('../../pages/assign-truck-driver/assign-truck-driver.component').then(
        (m) => m.AssignTruckDriverComponent,
      ),
    data: {
      title: 'Assign Truck to Driver',
      permissions: [PERMISSIONS.VEHICLE_UPDATE, PERMISSIONS.DRIVER_MANAGE],
      requireAny: true,
    },
  },
  {
    path: 'truck-driver-assignments',
    canActivate: [PermissionGuard],
    loadComponent: () =>
      import('../../pages/truck-driver-assignments/truck-driver-assignments.component').then(
        (m) => m.TruckDriverAssignmentsComponent,
      ),
    data: {
      title: 'Truck-Driver Assignments',
      permissions: [PERMISSIONS.VEHICLE_UPDATE, PERMISSIONS.DRIVER_MANAGE],
      requireAny: true,
    },
  },
  {
    path: 'trailers',
    data: { title: 'Trailers' },
    children: [
      {
        path: '',
        loadComponent: () =>
          import('../../components/fleet/trailers/trailers.component').then(
            (m) => m.TrailersComponent,
          ),
      },
      {
        path: 'create',
        canActivate: [PermissionGuard],
        loadComponent: () =>
          import('../../components/fleet/trailers/trailers.component').then(
            (m) => m.TrailersComponent,
          ),
        data: {
          title: 'Create Trailer',
          permissions: [PERMISSIONS.TRAILER_CREATE],
          action: 'create',
        },
      },
    ],
  },
  {
    path: 'maintenance',
    data: { title: 'Maintenance' },
    children: [
      {
        path: '',
        redirectTo: 'dashboard',
        pathMatch: 'full',
      },
      {
        path: 'dashboard',
        canActivate: [PermissionGuard],
        data: { title: 'Maintenance Dashboard', permissions: [PERMISSIONS.MAINTENANCE_READ] },
        loadComponent: () =>
          import('../../components/maintenance/dashboard/maintenance-dashboard.component').then(
            (m) => m.MaintenanceDashboardComponent,
          ),
      },
      {
        path: 'requests',
        canActivate: [PermissionGuard],
        data: { title: 'Maintenance Requests', permissions: [PERMISSIONS.MAINTENANCE_READ] },
        loadComponent: () =>
          import('../../components/maintenance/maintenance-requests/maintenance-requests.component').then(
            (m) => m.MaintenanceRequestsComponent,
          ),
      },
      {
        path: 'requests/:id',
        canActivate: [PermissionGuard],
        data: { title: 'Maintenance Request Details', permissions: [PERMISSIONS.MAINTENANCE_READ] },
        loadComponent: () =>
          import('../../components/maintenance/maintenance-request-details/maintenance-request-details.component').then(
            (m) => m.MaintenanceRequestDetailsComponent,
          ),
      },
      {
        path: 'records',
        canActivate: [PermissionGuard],
        data: { title: 'Maintenance Records', permissions: [PERMISSIONS.MAINTENANCE_RECORD_READ] },
        loadComponent: () =>
          import('../../components/fleet/maintenance-records/maintenance-records.component').then(
            (m) => m.MaintenanceRecordsComponent,
          ),
      },
      {
        path: 'schedule',
        canActivate: [PermissionGuard],
        data: {
          title: 'Maintenance Schedule',
          permissions: [PERMISSIONS.MAINTENANCE_SCHEDULE_READ],
        },
        loadComponent: () =>
          import('../../components/maintenance/pm-schedule/pm-schedule.component').then(
            (m) => m.PmScheduleComponent,
          ),
      },
      {
        path: 'pm-plans',
        canActivate: [PermissionGuard],
        data: { title: 'PM Plans', permissions: [PERMISSIONS.MAINTENANCE_PM_READ] },
        loadComponent: () =>
          import('../../components/maintenance/pm-plans/pm-plans.component').then(
            (m) => m.PmPlansComponent,
          ),
      },
      {
        path: 'pm-plans/:id',
        canActivate: [PermissionGuard],
        data: { title: 'PM Plan Detail', permissions: [PERMISSIONS.MAINTENANCE_PM_WRITE] },
        loadComponent: () =>
          import('../../components/maintenance/pm-plan-detail/pm-plan-detail.component').then(
            (m) => m.PmPlanDetailComponent,
          ),
      },
      {
        path: 'pm-dashboard',
        canActivate: [PermissionGuard],
        data: { title: 'PM Dashboard', permissions: [PERMISSIONS.MAINTENANCE_PM_READ] },
        loadComponent: () =>
          import('../../components/maintenance/pm-dashboard/pm-dashboard.component').then(
            (m) => m.PmDashboardComponent,
          ),
      },
      {
        path: 'pm-runs',
        canActivate: [PermissionGuard],
        data: { title: 'PM Runs', permissions: [PERMISSIONS.MAINTENANCE_PM_READ] },
        loadComponent: () =>
          import('../../components/maintenance/pm-runs/pm-runs.component').then(
            (m) => m.PmRunsComponent,
          ),
      },
      {
        path: 'pm-runs/:id',
        canActivate: [PermissionGuard],
        data: { title: 'PM Run Detail', permissions: [PERMISSIONS.MAINTENANCE_PM_READ] },
        loadComponent: () =>
          import('../../components/maintenance/pm-run-detail/pm-run-detail.component').then(
            (m) => m.PmRunDetailComponent,
          ),
      },
      {
        path: 'pm-calendar',
        canActivate: [PermissionGuard],
        data: { title: 'PM Calendar', permissions: [PERMISSIONS.MAINTENANCE_PM_READ] },
        loadComponent: () =>
          import('../../components/maintenance/pm-calendar/pm-calendar.component').then(
            (m) => m.PmCalendarComponent,
          ),
      },
      {
        path: 'pm-reports',
        canActivate: [PermissionGuard],
        data: { title: 'PM Reports', permissions: [PERMISSIONS.MAINTENANCE_PM_READ] },
        loadComponent: () =>
          import('../../components/maintenance/pm-reports/pm-reports.component').then(
            (m) => m.PmReportsComponent,
          ),
      },
      {
        path: 'pm-workshop',
        canActivate: [PermissionGuard],
        data: { title: 'Workshop Queue', permissions: [PERMISSIONS.MAINTENANCE_WORKORDER_READ] },
        loadComponent: () =>
          import('../../components/maintenance/pm-workshop-queue/pm-workshop-queue.component').then(
            (m) => m.PmWorkshopQueueComponent,
          ),
      },
      {
        path: 'failure-codes',
        canActivate: [PermissionGuard],
        data: { title: 'Failure Codes', permissions: [PERMISSIONS.MAINTENANCE_FAILURE_CODE_READ] },
        loadComponent: () =>
          import('../../components/maintenance/failure-codes/failure-codes.component').then(
            (m) => m.FailureCodesComponent,
          ),
      },
      {
        path: 'work-orders',
        canActivate: [PermissionGuard],
        data: { title: 'Work Orders', permissions: [PERMISSIONS.MAINTENANCE_WORKORDER_READ] },
        loadComponent: () =>
          import('../../components/maintenance/work-orders/work-orders.component').then(
            (m) => m.WorkOrdersComponent,
          ),
      },
      {
        path: 'work-orders/:id',
        canActivate: [PermissionGuard],
        data: {
          title: 'Work Order Details',
          permissions: [PERMISSIONS.MAINTENANCE_WORKORDER_READ],
        },
        loadComponent: () =>
          import('../../components/maintenance/work-order-details/work-order-details.component').then(
            (m) => m.WorkOrderDetailsComponent,
          ),
      },
      {
        path: 'repairs',
        canActivate: [PermissionGuard],
        data: { title: 'Repairs', permissions: [PERMISSIONS.MAINTENANCE_REPAIR_READ] },
        loadComponent: () =>
          import('../../components/maintenance/repairs/repairs.component').then(
            (m) => m.RepairsComponent,
          ),
      },
      {
        path: 'parts',
        canActivate: [PermissionGuard],
        data: { title: 'Parts Inventory', permissions: [PERMISSIONS.MAINTENANCE_PART_READ] },
        loadComponent: () =>
          import('../../components/maintenance/parts-inventory/parts-inventory.component').then(
            (m) => m.PartsInventoryComponent,
          ),
      },
    ],
  },
];
