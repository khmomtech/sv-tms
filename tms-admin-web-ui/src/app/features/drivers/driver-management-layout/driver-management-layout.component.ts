import { Component } from '@angular/core';
import { RouterModule } from '@angular/router';

@Component({
  selector: 'app-driver-management-layout',
  template: `
    <div class="driver-management-layout">
      <main class="driver-management-content">
        <router-outlet></router-outlet>
      </main>
    </div>
  `,
  styles: [
    `
      .driver-management-layout {
        display: flex;
        height: 100%;
      }
      .driver-management-content {
        flex-grow: 1;
        overflow-y: auto;
      }
    `,
  ],
  standalone: true,
  imports: [RouterModule],
})
export class DriverManagementLayoutComponent {}
