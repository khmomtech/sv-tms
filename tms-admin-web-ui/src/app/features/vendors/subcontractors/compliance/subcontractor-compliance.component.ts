import { CommonModule } from '@angular/common';
import { Component } from '@angular/core';
import { RouterModule } from '@angular/router';

@Component({
  selector: 'app-subcontractor-compliance',
  standalone: true,
  imports: [CommonModule, RouterModule],
  template: `
    <section class="page">
      <h1>Subcontractor Compliance</h1>
      <p class="muted">Stub page: compliance statuses and document tracking.</p>
      <ul>
        <li>Licenses & Insurance expiry</li>
        <li>Document completeness</li>
        <li>Compliance warnings</li>
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
export class SubcontractorComplianceComponent {}
