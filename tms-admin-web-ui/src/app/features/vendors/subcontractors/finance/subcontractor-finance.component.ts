import { CommonModule } from '@angular/common';
import { Component } from '@angular/core';
import { RouterModule } from '@angular/router';

@Component({
  selector: 'app-subcontractor-finance',
  standalone: true,
  imports: [CommonModule, RouterModule],
  template: `
    <section class="page">
      <h1>Subcontractor Finance & Credit</h1>
      <p class="muted">Stub page: rates, commissions, credit limits overview.</p>
      <ul>
        <li>Commission rates</li>
        <li>Credit limits</li>
        <li>Settlement summaries</li>
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
export class SubcontractorFinanceComponent {}
