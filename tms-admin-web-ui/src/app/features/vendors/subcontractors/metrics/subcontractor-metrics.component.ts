import { CommonModule } from '@angular/common';
import { Component } from '@angular/core';
import { RouterModule } from '@angular/router';

@Component({
  selector: 'app-subcontractor-metrics',
  standalone: true,
  imports: [CommonModule, RouterModule],
  template: `
    <section class="page">
      <h1>Subcontractor Metrics</h1>
      <p class="muted">Stub page: KPIs and aggregates per subcontractor.</p>
      <ul>
        <li>Active drivers/vehicles</li>
        <li>Open vs completed shipments</li>
        <li>Capacity utilization</li>
      </ul>
    </section>
  `,
  styles: [
    `
      .page {
        padding: 16px;
      }
      .muted {
        color: #666;
      }
    `,
  ],
})
export class SubcontractorMetricsComponent {}
