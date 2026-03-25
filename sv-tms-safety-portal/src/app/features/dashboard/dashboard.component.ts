import { Component, OnInit } from '@angular/core';
import { CommonModule } from '@angular/common';
import { SafetyService } from '../../core/safety.service';

@Component({
  selector: 'app-dashboard',
  standalone: true,
  imports: [CommonModule],
  template: `
    <h2 class="text-2xl font-bold">Dashboard</h2>
    <div class="grid grid-cols-3 gap-4 mt-4">
      <div class="p-4 bg-white rounded shadow">
        <h3 class="text-sm">Total Checks</h3>
        <div class="text-3xl">{{summary.total || 0}}</div>
      </div>
      <div class="p-4 bg-white rounded shadow">
        <h3 class="text-sm">Pass</h3>
        <div class="text-3xl">{{summary.pass || 0}}</div>
      </div>
      <div class="p-4 bg-white rounded shadow">
        <h3 class="text-sm">Fail</h3>
        <div class="text-3xl text-red-600">{{summary.fail || 0}}</div>
      </div>
    </div>
    <div class="mt-6">
      <h3 class="text-lg">Recent Fails</h3>
      <ul>
        <li *ngFor="let f of recentFails">#{{f.id}} - {{f.driverName}} - {{f.vehicleReg}}</li>
      </ul>
    </div>
  `,
  providers: [SafetyService]
})
export class DashboardComponent implements OnInit {
  summary: any = {};
  recentFails: any[] = [];
  constructor(private safety: SafetyService) {}
  ngOnInit(){
    this.safety.getChecks({ dateFrom: null }).subscribe((r: any) => {
      const checks = (r && r.content) || [];
      this.summary.total = checks.length;
      this.summary.pass = checks.filter((c:any)=> c.status === 'PASS').length;
      this.summary.fail = checks.filter((c:any)=> c.status === 'FAIL').length;
      this.recentFails = checks.filter((c:any)=> c.status === 'FAIL').slice(0,5);
    });
  }
}
