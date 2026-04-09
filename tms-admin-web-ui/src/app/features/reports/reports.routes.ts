import type { Routes } from '@angular/router';

import { DispatchDayReportComponent } from '../../reports/dispatch-day-report/dispatch-day-report.component';

export const REPORTS_ROUTES: Routes = [
  { path: 'dispatch/day', component: DispatchDayReportComponent },
];
