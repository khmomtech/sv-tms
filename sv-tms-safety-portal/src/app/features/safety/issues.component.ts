import { Component, OnInit } from '@angular/core';
import { CommonModule } from '@angular/common';
import { SafetyService } from '../../core/safety.service';
import { AuditService } from '../../core/audit.service';
import { FileService } from '../../core/file.service';
import { NotificationService } from '../../core/notification.service';
import { FormBuilder, ReactiveFormsModule, FormsModule } from '@angular/forms';

@Component({
  selector: 'app-safety-issues',
  standalone: true,
  imports: [CommonModule, ReactiveFormsModule, FormsModule],
  template: `
    <div class="flex items-center justify-between">
      <h2 class="text-xl font-semibold">Issues</h2>
      <button class="px-3 py-2 bg-green-600 text-white rounded" (click)="refresh()">Refresh</button>
    </div>
    <div class="mt-4">
      <form class="flex gap-2 items-end mb-3" (ngSubmit)="applyFilters()">
        <div>
          <label class="block text-sm">Status</label>
          <select [(ngModel)]="filters.status" name="status" class="border p-1 rounded">
            <option value="">All</option>
            <option>OPEN</option>
            <option>IN_PROGRESS</option>
            <option>RESOLVED</option>
            <option>VERIFIED</option>
            <option>CLOSED</option>
          </select>
        </div>
        <div>
          <label class="block text-sm">Severity</label>
          <select [(ngModel)]="filters.severity" name="severity" class="border p-1 rounded">
            <option value="">All</option>
            <option>LOW</option>
            <option>MEDIUM</option>
            <option>HIGH</option>
            <option>CRITICAL</option>
          </select>
        </div>
        <div>
          <label class="block text-sm">Vehicle ID</label>
          <input [(ngModel)]="filters.vehicleId" name="vehicleId" class="border p-1 rounded" />
        </div>
        <div>
          <button class="px-3 py-2 bg-blue-600 text-white rounded" type="submit">Apply</button>
        </div>
      </form>

      <table class="w-full table-auto">
        <thead><tr><th>#</th><th>Title</th><th>Vehicle</th><th>Driver</th><th>Severity</th><th>Status</th><th>Assigned</th><th>Actions</th></tr></thead>
        <tbody>
          <tr *ngFor="let it of issues">
            <td>{{it.id}}</td>
            <td>{{it.title}}</td>
            <td>{{it.vehicleReg || it.vehicleId}}</td>
            <td>{{it.driverName || it.driverId}}</td>
            <td>{{it.severity}}</td>
            <td>{{it.status}}</td>
            <td>{{it.assignedTo || '-'}}</td>
            <td class="space-x-2">
              <button class="px-2 py-1 border" (click)="openResolve(it)">Update</button>
              <button class="px-2 py-1 border" (click)="createMR(it)">Create MR</button>
            </td>
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

    <div *ngIf="editing" class="mt-6 p-4 bg-white rounded shadow">
      <h3 class="font-medium">Update Issue #{{editing.id}}</h3>
      <form [formGroup]="editForm" (ngSubmit)="save()" class="space-y-3 mt-2">
        <div>
          <label>Status</label>
          <select formControlName="status" class="border p-2">
            <option>OPEN</option>
            <option>IN_PROGRESS</option>
            <option>RESOLVED</option>
            <option>VERIFIED</option>
            <option>CLOSED</option>
          </select>
        </div>
        <div>
          <label>Assign To (user or role)</label>
          <input formControlName="assignedTo" class="border p-2 w-64" />
        </div>
        <div>
          <label>Notes</label>
          <textarea formControlName="notes" class="w-full border p-2"></textarea>
        </div>
        <div>
          <label>Attach evidence</label>
          <input type="file" (change)="onFile($event)" />
        </div>
        <div>
          <button class="px-3 py-2 bg-blue-600 text-white rounded" type="submit">Save</button>
          <button type="button" class="ml-2 px-3 py-2 border" (click)="cancel()">Cancel</button>
        </div>
      </form>
    </div>
  `,
  providers: [SafetyService, AuditService, FileService]
})
export class IssuesComponent implements OnInit {
  issues: any[] = [];
  editing: any = null;
  editForm = this.fb.group({ status: [''], assignedTo: [''], notes: [''], evidenceUrl: [''] });
  page = 0; size = 10; total = 0;
  filters: any = { status: '', severity: '', vehicleId: '' };
  constructor(private safety: SafetyService, private audit: AuditService, private file: FileService, private fb: FormBuilder, private notify: NotificationService) {}
  ngOnInit(){ this.load(); }
  load(){
    const params: any = { page: this.page, size: this.size };
    if(this.filters.status) params.status = this.filters.status;
    if(this.filters.severity) params.severity = this.filters.severity;
    if(this.filters.vehicleId) params.vehicleId = this.filters.vehicleId;
    this.safety.getIssues(params).subscribe((r:any)=>{ this.issues = (r && r.content) || []; this.total = r?.totalElements || 0; });
  }
  refresh(){ this.load(); }
  openResolve(issue: any){ this.editing = issue; this.editForm.patchValue({ status: issue.status, assignedTo: issue.assignedTo, notes: '' }); }
  cancel(){ this.editing = null; }
  onFile(e: any){ const f = e.target.files[0]; if(!f) return; this.file.upload(f).subscribe((res:any)=> this.editForm.patchValue({ evidenceUrl: res.url })); }
  save(){ if(!this.editing) return; const payload = { status: this.editForm.value.status, assignedTo: this.editForm.value.assignedTo, notes: this.editForm.value.notes, evidenceUrl: this.editForm.value.evidenceUrl };
    this.safety.updateIssue(this.editing.id, payload).subscribe(()=>{
      this.audit.log('update_issue','issue', this.editing.id, payload);
      this.load(); this.editing = null;
    }); }
  createMR(issue: any){ const payload = { title: `MR for issue ${issue.id}`, description: issue.title };
    this.safety.createMaintenanceFromIssue(issue.id, payload).subscribe((r:any)=>{ this.notify.success('MR created: ' + (r && r.mrId)); this.audit.log('create_mr','issue', issue.id, r); }); }

  applyFilters(){ this.page = 0; this.load(); }
  prev(){ if(this.page>0){ this.page--; this.load(); } }
  next(){ if((this.page+1)*this.size < this.total){ this.page++; this.load(); } }
  get totalPages(){ return Math.max(1, Math.ceil(this.total / this.size)); }
}
