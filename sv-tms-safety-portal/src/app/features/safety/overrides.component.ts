
import { Component, OnInit } from '@angular/core';
import { CommonModule } from '@angular/common';
import { SafetyService } from '../../core/safety.service';
import { AuditService } from '../../core/audit.service';
import { NotificationService } from '../../core/notification.service';
import { ConfirmService } from '../../core/confirm.service';
import { FormsModule } from '@angular/forms';

@Component({
  selector: 'app-safety-overrides',
  standalone: true,
  imports: [CommonModule, FormsModule],
  template: `
    <div class="flex items-center justify-between">
      <h2 class="text-xl font-semibold">Overrides</h2>
      <button class="px-3 py-2 bg-blue-600 text-white rounded" (click)="refresh()">Refresh</button>
    </div>
    <div class="mt-4 grid grid-cols-2 gap-4">
      <div>
        <h3 class="font-medium">Active Overrides</h3>
        <ul class="mt-2">
          <li *ngFor="let o of overrides" class="p-2 border rounded mb-2">
            <div class="flex justify-between">
              <div>
                <strong>{{o.vehicleId}}</strong> — {{o.reason}}
                <div class="text-sm">Valid until: {{o.validUntil}}</div>
              </div>
              <div>
                <button class="px-2 py-1 border" (click)="revoke(o)">Revoke</button>
              </div>
            </div>
          </li>
        </ul>
      </div>
      <div>
        <h3 class="font-medium">Create Override</h3>
        <form (ngSubmit)="create()" class="mt-2 space-y-2">
          <div>
            <label>Vehicle ID</label>
            <input [(ngModel)]="model.vehicleId" name="vehicleId" class="border p-2 w-full" />
          </div>
          <div>
            <label>Valid Until (ISO)</label>
            <input [(ngModel)]="model.validUntil" name="validUntil" class="border p-2 w-full" />
          </div>
          <div>
            <label>Reason</label>
            <textarea [(ngModel)]="model.reason" name="reason" class="border p-2 w-full"></textarea>
          </div>
          <div>
            <button class="px-3 py-2 bg-green-600 text-white rounded" type="submit">Create</button>
          </div>
        </form>
      </div>
    </div>
  `
})
export class OverridesComponent implements OnInit {
  overrides: any[] = [];
  model: any = { vehicleId: '', validUntil: '', reason: '' };
  constructor(private safety: SafetyService, private audit: AuditService, private notify: NotificationService, private confirm: ConfirmService) {}
  ngOnInit(){ this.load(); }
  load(){ this.safety.getOverrides({ active: true }).subscribe((r:any)=> this.overrides = (r && r.content) || []); }
  refresh(){ this.load(); }
  create(){
    const payload = { vehicleId: this.model.vehicleId, validUntil: this.model.validUntil, reason: this.model.reason };
    if(!payload.vehicleId) return this.notify.error('vehicleId required');
    this.safety.createOverride(payload).subscribe((r:any)=>{ this.audit.log('create_override', 'override', r && r.id, payload); this.load(); this.model = { vehicleId:'', validUntil:'', reason:'' }; });
  }
  async revoke(o: any){
    const ok = await this.confirm.confirm('Revoke override?');
    if(!ok) return;
    this.safety.revokeOverride(o.id).subscribe(()=>{ this.audit.log('revoke_override','override', o.id); this.load(); });
  }
}

