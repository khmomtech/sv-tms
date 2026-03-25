import { CommonModule } from '@angular/common';
import { Component, inject } from '@angular/core';
import { FormsModule } from '@angular/forms';
import { ToastrService } from 'ngx-toastr';

import { DispatchService } from '../../services/dispatch.service';

@Component({
  selector: 'app-dispatch-closing',
  standalone: true,
  imports: [CommonModule, FormsModule],
  templateUrl: './dispatch-closing.component.html',
  styleUrls: ['./dispatch-closing.component.css'],
})
export class DispatchClosingComponent {
  private readonly dispatchService = inject(DispatchService);
  private readonly toastr = inject(ToastrService);

  date = '';
  reason = '';
  status: string | null = null;

  loadStatus(): void {
    if (!this.date) {
      this.toastr.error('Date is required');
      return;
    }
    this.dispatchService.getDispatchDayClosing(this.date).subscribe({
      next: (res) => {
        this.status = res.success ? (res.data?.status ?? 'CLOSED') : 'NOT_FOUND';
      },
      error: () => this.toastr.error('Failed to load closing status'),
    });
  }

  closeDay(): void {
    if (!this.date) {
      this.toastr.error('Date is required');
      return;
    }
    this.dispatchService.closeDispatchDay(this.date, this.reason).subscribe({
      next: () => {
        this.toastr.success('Day closed');
        this.loadStatus();
      },
      error: () => this.toastr.error('Close failed'),
    });
  }

  reopenDay(): void {
    if (!this.date) {
      this.toastr.error('Date is required');
      return;
    }
    this.dispatchService.reopenDispatchDay(this.date, this.reason).subscribe({
      next: () => {
        this.toastr.success('Day reopened');
        this.loadStatus();
      },
      error: () => this.toastr.error('Reopen failed'),
    });
  }
}
