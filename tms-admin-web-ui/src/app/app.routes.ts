import type { Routes } from '@angular/router';

import { LoginComponent } from './components/auth/login/login.component';
import { DashboardComponent } from './components/dashboard/dashboard.component';
import { AdminGuard } from './guards/admin.guard';
import { AuthGuard } from './guards/auth.guard';
import { PermissionGuard } from './guards/permission.guard';
import { PERMISSIONS } from './shared/permissions';

// Auth Components

// Dashboard Component

export const routes: Routes = [
  // Public routes
  {
    path: 'login',
    component: LoginComponent,
    data: { title: 'Login' },
  },

  // Public Shipment Tracking (no auth required)
  {
    path: 'tracking',
    loadChildren: () =>
      import('./components/shipment-tracking/tracking.routes').then((m) => m.TRACKING_ROUTES),
    data: { title: 'Track Shipment' },
  },

  // Protected routes
  {
    path: '',
    canActivate: [AuthGuard],
    canActivateChild: [AuthGuard],
    children: [
      {
        path: '',
        redirectTo: 'dashboard',
        pathMatch: 'full',
      },
      // Dashboard
      {
        path: 'dashboard',
        component: DashboardComponent,
        data: { title: 'Dashboard' },
      },

      // Fleet Management Feature Module
      {
        path: 'fleet',
        loadChildren: () => import('./features/fleet/fleet.routes').then((m) => m.FLEET_ROUTES),
        data: { title: 'Fleet Management' },
      },

      // Telematics Feature Module (live map, geofences, console)
      {
        path: 'live',
        loadChildren: () =>
          import('./features/telematics/telematics.routes').then((m) => m.TELEMATICS_ROUTES),
        data: { title: 'Live Tracking' },
      },

      // Backward-compat: old driver-monitoring/* URLs → live/*
      {
        path: 'driver-monitoring',
        loadChildren: () =>
          import('./features/telematics/telematics.routes').then((m) => m.TELEMATICS_ROUTES),
        data: { title: 'Live Tracking' },
      },

      // Order Management Feature Module
      {
        path: 'orders',
        loadChildren: () => import('./features/orders/orders.routes').then((m) => m.ORDERS_ROUTES),
        data: { title: 'Order Management' },
      },

      // Dispatch Management Feature Module
      {
        path: 'dispatch',
        loadChildren: () =>
          import('./features/dispatch/dispatch.routes').then((m) => m.DISPATCH_ROUTES),
        data: { title: 'Dispatch Management' },
      },

      // Safety Check Management
      {
        path: 'safety',
        loadChildren: () => import('./features/safety/safety.routes').then((m) => m.SAFETY_ROUTES),
        data: { title: 'ត្រួតពិនិត្យសុវត្ថិភាព' },
      },

      // Document Compliance Dashboard
      {
        path: 'compliance',
        canActivate: [PermissionGuard],
        loadChildren: () =>
          import('./features/compliance/compliance.routes').then((m) => m.COMPLIANCE_ROUTES),
        data: { title: 'Document Compliance', permissions: [PERMISSIONS.ADMIN_READ] },
      },

      // Training Records
      {
        path: 'training',
        canActivate: [PermissionGuard],
        loadChildren: () =>
          import('./features/training/training.routes').then((m) => m.TRAINING_ROUTES),
        data: { title: 'Training Records', permissions: [PERMISSIONS.ADMIN_READ] },
      },

      // Dispatches List (alias for convenience)
      {
        path: 'dispatches',
        redirectTo: 'dispatch',
        pathMatch: 'full',
      },

      // Customer Management Feature Module
      {
        path: 'customers',
        loadChildren: () =>
          import('./features/customers/customers.routes').then((m) => m.CUSTOMERS_ROUTES),
        data: { title: 'Customer Management' },
      },

      // Admin Feature Module (Admin only)
      {
        path: 'admin',
        canActivate: [AdminGuard],
        canActivateChild: [AdminGuard],
        loadChildren: () => import('./features/admin/admin.routes').then((m) => m.ADMIN_ROUTES),
        data: { title: 'Administration', roles: ['ADMIN', 'SUPERADMIN'] },
      },

      // Reports Feature Module
      {
        path: 'reports',
        loadChildren: () =>
          import('./features/reports/reports.routes').then((m) => m.REPORTS_ROUTES),
        data: { title: 'Reports' },
      },

      // Drivers Feature Module (new lazy feature for driver domain)
      {
        path: 'drivers',
        loadComponent: () =>
          import('./features/drivers/driver-management-layout/driver-management-layout.component').then(
            (m) => m.DriverManagementLayoutComponent,
          ),
        loadChildren: () =>
          import('./features/drivers/drivers.routes').then((m) => m.DRIVERS_ROUTES),
        data: { title: 'Drivers' },
      },

      // Vendors Feature Module (renamed from Partners)
      {
        path: 'vendors',
        loadChildren: () =>
          import('./features/vendors/vendors.routes').then((m) => m.VENDORS_ROUTES),
        data: { title: 'Vendors' },
      },
      // Alias path for Subcontractors pointing to vendors feature
      {
        path: 'subcontractors',
        loadChildren: () =>
          import('./features/vendors/vendors.routes').then((m) => m.VENDORS_ROUTES),
        data: { title: 'Subcontractors' },
      },
      // Subcontractor Admins (stub component)
      {
        path: 'subcontractors/admins',
        loadComponent: () =>
          import('./features/vendors/subcontractors/admins/subcontractor-admins.component').then(
            (m) => m.SubcontractorAdminsComponent,
          ),
        data: { title: 'Subcontractor Admins' },
      },
      // Subcontractor Metrics (stub component)
      {
        path: 'subcontractors/metrics',
        loadComponent: () =>
          import('./features/vendors/subcontractors/metrics/subcontractor-metrics.component').then(
            (m) => m.SubcontractorMetricsComponent,
          ),
        data: { title: 'Subcontractor Metrics' },
      },
      // Subcontractor Compliance (stub component)
      {
        path: 'subcontractors/compliance',
        loadComponent: () =>
          import('./features/vendors/subcontractors/compliance/subcontractor-compliance.component').then(
            (m) => m.SubcontractorComplianceComponent,
          ),
        data: { title: 'Subcontractor Compliance' },
      },
      // Subcontractor Finance (stub component)
      {
        path: 'subcontractors/finance',
        loadComponent: () =>
          import('./features/vendors/subcontractors/finance/subcontractor-finance.component').then(
            (m) => m.SubcontractorFinanceComponent,
          ),
        data: { title: 'Subcontractor Finance' },
      },
      // Backwards-compat: redirect old /partners to /vendors
      { path: 'partners', pathMatch: 'full', redirectTo: 'vendors' },

      // Settings (Admin only)
      {
        path: 'settings',
        canActivate: [AdminGuard],
        canActivateChild: [AdminGuard],
        loadChildren: () =>
          import('./features/settings/settings.routes').then((m) => m.SETTINGS_ROUTES),
        data: { title: 'Settings', roles: ['ADMIN', 'SUPERADMIN'] },
      },

      // Home Layout Management (Admin only)
      {
        path: 'settings/home-layout',
        canActivate: [AdminGuard],
        loadComponent: () =>
          import('./components/home-layout-management/home-layout-management.component').then(
            (m) => m.HomeLayoutManagementComponent,
          ),
        data: {
          title: 'Home Layout Management',
          roles: ['ADMIN', 'SUPERADMIN'],
          permissions: [PERMISSIONS.HOME_LAYOUT_MANAGE],
        },
      },

      // Items Management (Admin only)
      {
        path: 'items',
        canActivate: [AdminGuard],
        canActivateChild: [AdminGuard],
        loadChildren: () => import('./features/items/items.routes').then((m) => m.ITEMS_ROUTES),
        data: { title: 'Items Management', roles: ['ADMIN', 'SUPERADMIN'] },
      },

      // Banner Management (Admin only)
      {
        path: 'banners',
        canActivate: [AdminGuard],
        loadComponent: () =>
          import('./components/banner-management/banner-management.component').then(
            (m) => m.BannerManagementComponent,
          ),
        data: { title: 'Banner Management', roles: ['ADMIN', 'SUPERADMIN'] },
      },

      // Geofence shortcut
      {
        path: 'geofences',
        pathMatch: 'full',
        redirectTo: 'live/geofences',
      },

      // Backward-compat: old /live/drivers URL → /live/map
      {
        path: 'live/drivers',
        pathMatch: 'full',
        redirectTo: 'live/map',
      },

      // Issue Management Feature Module
      {
        path: 'issues',
        loadChildren: () => import('./features/issues/issues.routes').then((m) => m.ISSUES_ROUTES),
        data: { title: 'Issue Management' },
      },

      // Incident Management Feature Module
      {
        path: 'incidents',
        canActivate: [PermissionGuard],
        loadChildren: () =>
          import('./features/incidents/incidents.routes').then((m) => m.INCIDENT_ROUTES),
        data: {
          title: 'Incident Management',
          permissions: [PERMISSIONS.INCIDENT_READ, PERMISSIONS.ADMIN_READ],
        },
      },

      // Case Management Feature Module
      {
        path: 'cases',
        canActivate: [PermissionGuard],
        loadChildren: () =>
          import('./features/incidents/incidents.routes').then((m) => m.CASE_ROUTES),
        data: {
          title: 'Case Management',
          permissions: [PERMISSIONS.CASE_READ, PERMISSIONS.ADMIN_READ],
        },
      },

      // Task Management Feature Module
      {
        path: 'tasks',
        canActivate: [PermissionGuard],
        loadChildren: () => import('./features/tasks/tasks.routes').then((m) => m.TASK_ROUTES),
        data: {
          title: 'Task Management',
          permissions: [PERMISSIONS.TASK_READ, PERMISSIONS.ADMIN_READ],
        },
      },

      // Booking Management Feature Module
      {
        path: 'bookings',
        loadChildren: () =>
          import('./features/bookings/bookings.routes').then((m) => m.BOOKING_ROUTES),
        data: { title: 'Booking Management' },
      },

      // Shipments (Admin/Operations)
      {
        path: 'shipments',
        loadComponent: () =>
          import('./components/shipment/shipment.component').then((m) => m.ShipmentComponent),
        data: { title: 'Shipments' },
      },
      {
        path: 'shipments/:id',
        loadComponent: () =>
          import('./components/shipment-detail/shipment-detail.component').then(
            (m) => m.ShipmentDetailComponent,
          ),
        data: { title: 'Shipment Details' },
      },
    ],
  },

  // Error routes
  {
    path: 'unauthorized',
    loadComponent: () =>
      import('./components/errors/unauthorized/unauthorized.component').then(
        (m) => m.UnauthorizedComponent,
      ),
    data: { title: 'Unauthorized' },
  },

  // Default redirects
  { path: '', redirectTo: '/dashboard', pathMatch: 'full' },

  // Wildcard route - must be last
  {
    path: '**',
    loadComponent: () =>
      import('./components/errors/not-found/not-found.component').then((m) => m.NotFoundComponent),
    data: { title: 'Page Not Found' },
  },
];
