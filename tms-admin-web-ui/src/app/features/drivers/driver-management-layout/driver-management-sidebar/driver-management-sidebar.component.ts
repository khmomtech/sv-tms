import { Component } from '@angular/core';
import { RouterModule } from '@angular/router';

@Component({
  selector: 'app-driver-management-sidebar',
  template: `
    <nav class="driver-sidebar">
      <ul>
        <li><a routerLink="list" routerLinkActive="active">Driver List</a></li>
        <li><a routerLink="documents" routerLinkActive="active">Documents & Licenses</a></li>
        <li><a routerLink="shifts" routerLinkActive="active">Shifts & Hours</a></li>
        <li><a routerLink="accounts" routerLinkActive="active">Driver App Accounts</a></li>
        <li><a routerLink="performance" routerLinkActive="active">Performance & Incidents</a></li>
        <li><a routerLink="devices" routerLinkActive="active">Driver App Devices</a></li>
        <li><a routerLink="attendance" routerLinkActive="active">Driver Attendance</a></li>
      </ul>
    </nav>
  `,
  styles: [
    `
      .driver-sidebar {
        width: 240px;
        background-color: #f4f4f4;
        padding: 20px;
      }
      .driver-sidebar ul {
        list-style: none;
        padding: 0;
        margin: 0;
      }
      .driver-sidebar li a {
        display: block;
        padding: 10px 15px;
        color: #333;
        text-decoration: none;
        border-radius: 4px;
      }
      .driver-sidebar li a:hover,
      .driver-sidebar li a.active {
        background-color: #e0e0e0;
      }
    `,
  ],
  standalone: true,
  imports: [RouterModule],
})
export class DriverManagementSidebarComponent {}
