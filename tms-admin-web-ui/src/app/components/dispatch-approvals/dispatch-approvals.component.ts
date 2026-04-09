import { CommonModule } from '@angular/common';
import { Component, inject } from '@angular/core';
import { FormsModule } from '@angular/forms';
import { ToastrService } from 'ngx-toastr';
import { finalize } from 'rxjs';

import type { CodSettlement } from '../../models/cod-settlement.model';
import type { FuelRequest } from '../../models/fuel-request.model';
import type { OdometerLog } from '../../models/odometer-log.model';
import { DispatchService } from '../../services/dispatch.service';

@Component({
  selector: 'app-dispatch-approvals',
  standalone: true,
  imports: [CommonModule, FormsModule],
  templateUrl: './dispatch-approvals.component.html',
  styleUrls: ['./dispatch-approvals.component.css'],
})
export class DispatchApprovalsComponent {
  private readonly dispatchService = inject(DispatchService);
  private readonly toastr = inject(ToastrService);

  dispatchId?: number;
  loading = false;

  odometerLogs: OdometerLog[] = [];
  fuelRequests: FuelRequest[] = [];
  codSettlements: CodSettlement[] = [];

  loadAll(): void {
    if (!this.dispatchId) {
      this.toastr.error('Dispatch ID is required');
      return;
    }

    this.loading = true;
    this.dispatchService
      .getOdometerLogs(this.dispatchId)
      .pipe(finalize(() => (this.loading = false)))
      .subscribe({
        next: (res) => (this.odometerLogs = res.data || []),
        error: () => this.toastr.error('Failed to load odometer logs'),
      });

    this.dispatchService.getFuelRequests(this.dispatchId).subscribe({
      next: (res) => (this.fuelRequests = res.data || []),
      error: () => this.toastr.error('Failed to load fuel requests'),
    });

    this.dispatchService.getCodSettlements(this.dispatchId).subscribe({
      next: (res) => (this.codSettlements = res.data || []),
      error: () => this.toastr.error('Failed to load COD settlements'),
    });
  }

  approveOdometer(id: number): void {
    this.dispatchService.approveOdometer(id).subscribe({
      next: () => this.loadAll(),
      error: () => this.toastr.error('Approve failed'),
    });
  }

  rejectOdometer(id: number): void {
    this.dispatchService.rejectOdometer(id).subscribe({
      next: () => this.loadAll(),
      error: () => this.toastr.error('Reject failed'),
    });
  }

  approveFuel(id: number): void {
    this.dispatchService.approveFuelRequest(id).subscribe({
      next: () => this.loadAll(),
      error: () => this.toastr.error('Approve failed'),
    });
  }

  rejectFuel(id: number): void {
    this.dispatchService.rejectFuelRequest(id).subscribe({
      next: () => this.loadAll(),
      error: () => this.toastr.error('Reject failed'),
    });
  }

  approveCod(id: number): void {
    this.dispatchService.approveCodSettlement(id).subscribe({
      next: () => this.loadAll(),
      error: () => this.toastr.error('Approve failed'),
    });
  }

  rejectCod(id: number): void {
    this.dispatchService.rejectCodSettlement(id).subscribe({
      next: () => this.loadAll(),
      error: () => this.toastr.error('Reject failed'),
    });
  }
}
