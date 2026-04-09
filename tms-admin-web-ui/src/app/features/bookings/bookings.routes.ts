import { Routes } from '@angular/router';
import { BookingListComponent } from './booking-list/booking-list.component';
import { BookingDetailComponent } from './booking-detail/booking-detail.component';
import { BookingFormComponent } from './booking-form/booking-form.component';
import { BookingReportsSummaryComponent } from './booking-reports-summary/booking-reports-summary.component';
import { BookingReportsDetailedComponent } from './booking-reports-detailed/booking-reports-detailed.component';
import { BookingReportsAnalyticsComponent } from './booking-reports-analytics/booking-reports-analytics.component';

export const BOOKING_ROUTES: Routes = [
  {
    path: '',
    component: BookingListComponent,
    data: { title: 'Bookings' },
  },
  {
    path: 'create',
    component: BookingFormComponent,
    data: { title: 'Create Booking' },
  },
  {
    path: 'reports',
    component: BookingReportsSummaryComponent,
    data: { title: 'Booking Reports' },
  },
  {
    path: 'reports/detailed',
    component: BookingReportsDetailedComponent,
    data: { title: 'Detailed Booking List' },
  },
  {
    path: 'reports/analytics',
    component: BookingReportsAnalyticsComponent,
    data: { title: 'Booking Analytics' },
  },
  {
    path: ':id',
    component: BookingDetailComponent,
    data: { title: 'Booking Details' },
  },
  {
    path: ':id/edit',
    component: BookingFormComponent,
    data: { title: 'Edit Booking' },
  },
];
