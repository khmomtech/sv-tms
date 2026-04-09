/* eslint-disable @typescript-eslint/consistent-type-imports */
import { CommonModule } from '@angular/common';
import { Component } from '@angular/core';

import { SettingsService } from '../../../../services/settings.service';

@Component({
  selector: 'app-settings-import-export',
  standalone: true,
  imports: [CommonModule],
  template: `
    <div class="p-6 bg-white rounded">
      <h2 class="mb-4 text-xl font-bold">Import / Export Settings</h2>

      <div class="flex gap-3 items-center">
        <input type="file" (change)="onFile($event)" />
        <button class="btn" [disabled]="!buf" (click)="dryRun()">Dry run</button>
        <button class="btn btn-primary" [disabled]="!buf" (click)="apply()">Apply</button>
      </div>

      <pre *ngIf="result" class="mt-4 p-3 bg-gray-50 rounded whitespace-pre-wrap">{{
        result | json
      }}</pre>
    </div>
  `,
})
export class ImportExportComponent {
  buf?: ArrayBuffer;
  result: any;

  constructor(private api: SettingsService) {}

  onFile(e: any) {
    const f = e?.target?.files?.[0];
    if (!f) return;
    f.arrayBuffer().then((b: ArrayBuffer) => (this.buf = b));
  }

  dryRun() {
    if (!this.buf) return;
    this.api.importRaw(this.buf, 'GLOBAL', undefined, false).subscribe((r) => (this.result = r));
  }

  apply() {
    if (!this.buf) return;
    this.api.importRaw(this.buf, 'GLOBAL', undefined, true).subscribe((r) => (this.result = r));
  }
}
