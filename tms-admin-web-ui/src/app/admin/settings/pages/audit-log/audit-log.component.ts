/* eslint-disable @typescript-eslint/consistent-type-imports */
import { CommonModule } from '@angular/common';
import { OnInit } from '@angular/core';
import { Component } from '@angular/core';

import { SettingsService } from '../../../../services/settings.service';

@Component({
  selector: 'app-audit-log',
  standalone: true,
  imports: [CommonModule],
  template: `
    <div class="p-6 bg-white rounded">
      <h2 class="mb-4 text-xl font-bold">Settings Audit Log</h2>
      <div class="overflow-auto">
        <table class="min-w-full text-sm">
          <thead>
            <tr class="border-b">
              <th class="text-left p-2">When</th>
              <th class="text-left p-2">Actor</th>
              <th class="text-left p-2">Scope</th>
              <th class="text-left p-2">Key</th>
              <th class="text-left p-2">Old</th>
              <th class="text-left p-2">New</th>
              <th class="text-left p-2">Reason</th>
            </tr>
          </thead>
          <tbody>
            <tr *ngFor="let a of rows" class="border-b">
              <td class="p-2">{{ a.updatedAt }}</td>
              <td class="p-2">{{ a.updatedBy }}</td>
              <td class="p-2">{{ a.scope }} / {{ a.scopeRef || '-' }}</td>
              <td class="p-2">{{ a.groupCode }}.{{ a.keyCode }}</td>
              <td class="p-2 truncate max-w-[240px]">{{ a.oldValue }}</td>
              <td class="p-2 truncate max-w-[240px]">{{ a.newValue }}</td>
              <td class="p-2">{{ a.reason }}</td>
            </tr>
          </tbody>
        </table>
      </div>
    </div>
  `,
})
export class AuditLogComponent implements OnInit {
  rows: any[] = [];
  page = 0;
  size = 50;

  constructor(private api: SettingsService) {}

  ngOnInit(): void {
    this.api.audit(undefined, undefined, this.page, this.size).subscribe((p) => {
      this.rows = p.content || [];
    });
  }
}
