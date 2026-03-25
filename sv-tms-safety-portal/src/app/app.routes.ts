import { Routes } from '@angular/router';
import { DashboardComponent } from './features/dashboard/dashboard.component';
import { ChecksComponent } from './features/safety/checks.component';
import { CheckFormComponent } from './features/safety/check-form.component';
import { ItemsComponent } from './features/safety/items.component.ts';
import { IssuesComponent } from './features/safety/issues.component.ts';
import { VehiclesComponent } from './features/safety/vehicles.component.ts';
import { OverridesComponent } from './features/safety/overrides.component.ts';
import { ReportsComponent } from './features/safety/reports.component.ts';
import { AuditComponent } from './features/audit/audit.component';

export const appRoutes: Routes = [
  { path: '', component: DashboardComponent },
  { path: 'safety/checks', component: ChecksComponent },
  { path: 'safety/checks/new', component: CheckFormComponent },
  { path: 'safety/items', component: ItemsComponent },
  { path: 'safety/issues', component: IssuesComponent },
  { path: 'safety/vehicles', component: VehiclesComponent },
  { path: 'safety/overrides', component: OverridesComponent },
  { path: 'safety/reports', component: ReportsComponent },
  { path: 'audit', component: AuditComponent }
];
