import { Component, OnInit } from '@angular/core';
import { CommonModule } from '@angular/common';
import { RouterModule } from '@angular/router';
import { SafetyService } from '../../core/safety.service';
import { ReactiveFormsModule, FormBuilder, FormsModule } from '@angular/forms';
import { StatusChipComponent } from '../../shared/status-chip.component';

@Component({
  selector: 'app-safety-checks',
  standalone: true,
  imports: [CommonModule, RouterModule, StatusChipComponent, ReactiveFormsModule, FormsModule],
  template: `
    <div class="flex items-center justify-between">
      <h2 class="text-xl font-semibold">Daily Safety Checks</h2>
      <div class="space-x-2">
        <a routerLink="/safety/checks/new" class="px-3 py-2 bg-blue-600 text-white rounded">Create Check</a>
      </div>
    </div>

    <form class="mt-4 flex gap-2 items-end" (ngSubmit)="applyFilters()">
      <div>
        <label class="block text-sm">Driver ID</label>
        <input [(ngModel)]="filters.driverId" name="driverId" class="border p-1 rounded" />
      </div>
      <div>
        <label class="block text-sm">Vehicle ID</label>
        <input [(ngModel)]="filters.vehicleId" name="vehicleId" class="border p-1 rounded" />
      </div>
      <div>
        <label class="block text-sm">Status</label>
        <select [(ngModel)]="filters.status" name="status" class="border p-1 rounded">
          <option value="">All</option>
          <option value="PASS">PASS</option>
          <option value="FAIL">FAIL</option>
          <option value="WARNING">WARNING</option>
        </select>
      </div>
      <div>
        <button class="px-3 py-2 bg-blue-600 text-white rounded" type="submit">Apply</button>
      </div>
    </form>

    <div class="mt-4">
      <table class="w-full table-auto">
        <thead><tr><th>Date</th><th>Driver</th><th>Vehicle</th><th>Status</th><th>Actions</th></tr></thead>
        <tbody>
          <tr *ngFor="let c of checks">
            <td>{{c.date | date:'dd-MMM-yyyy'}}</td>
            <td>{{c.driverName || c.driverId}}</td>
            <td>{{c.vehicleReg || c.vehicleId}}</td>
            <td><app-status-chip [status]="c.status"></app-status-chip></td>
            <td><button class="px-2 py-1 border">View</button></td>
          </tr>
        </tbody>
      </table>

      <div class="mt-4 flex items-center justify-between">
        <div>Showing page {{page + 1}} of {{totalPages}}</div>
        <div class="space-x-2">
          <button (click)="prev()" [disabled]="page===0" class="px-2 py-1 border">Prev</button>
          <button (click)="next()" [disabled]="(page+1)>=totalPages" class="px-2 py-1 border">Next</button>
        </div>
      </div>
    </div>
  `,
  providers: [SafetyService]
})
export class ChecksComponent implements OnInit {
  checks: any[] = [];
  page = 0; size = 10; total = 0;
  filters: any = { driverId: '', vehicleId: '', status: '' };
  constructor(private safety: SafetyService, private fb: FormBuilder) {}
  ngOnInit(){ this.load(); }
  load(){
    const params: any = { page: this.page, size: this.size };
    if(this.filters.driverId) params.driverId = this.filters.driverId;
    if(this.filters.vehicleId) params.vehicleId = this.filters.vehicleId;
    if(this.filters.status) params.status = this.filters.status;
    this.safety.getChecks(params).subscribe((r:any)=>{ this.checks = (r && r.content) || []; this.total = r?.totalElements || 0; });
  }
  applyFilters(){ this.page = 0; this.load(); }
  prev(){ if(this.page>0){ this.page--; this.load(); } }
  next(){ if((this.page+1)*this.size < this.total){ this.page++; this.load(); } }
  get totalPages(){ return Math.max(1, Math.ceil(this.total / this.size)); }
}
