/* eslint-disable @typescript-eslint/consistent-type-imports */
import { CommonModule } from '@angular/common';
import { Component, ElementRef, ViewChild } from '@angular/core';

import { ItemImportComponent } from '../../../../components/settting/item/import/item-import.component';
import { SettingsService } from '../../../../services/settings.service';

@Component({
  selector: 'app-settings-import-export',
  standalone: true,
  imports: [CommonModule, ItemImportComponent],
  template: `
    <div class="p-6 bg-white rounded">
      <h2 class="mb-4 text-xl font-bold">Import / Export Settings</h2>

      <div class="flex gap-3 items-center">
        <input #fileInput type="file" (change)="onFile($event)" />
        <button class="btn" [disabled]="!buf || loading" (click)="dryRun()">Dry run</button>
        <button class="btn btn-primary" [disabled]="!buf || loading" (click)="apply()">
          {{ loading ? 'Applying…' : 'Apply' }}
        </button>
      </div>

      <p *ngIf="error" class="mt-3 text-red-600 text-sm">{{ error }}</p>

      <pre *ngIf="result" class="mt-4 p-3 bg-gray-50 rounded whitespace-pre-wrap">{{
        result | json
      }}</pre>
    </div>

    <div class="mt-6">
      <app-item-import></app-item-import>
    </div>
  `,
})
export class ImportExportComponent {
  @ViewChild('fileInput') fileInput!: ElementRef<HTMLInputElement>;

  buf?: ArrayBuffer;
  result: unknown;
  error?: string;
  loading = false;

  constructor(private api: SettingsService) {}

  onFile(e: Event) {
    const f = (e.target as HTMLInputElement).files?.[0];
    if (!f) return;
    this.result = undefined;
    this.error = undefined;
    f.arrayBuffer().then((b) => (this.buf = b));
  }

  dryRun() {
    if (!this.buf) return;
    this.loading = true;
    this.error = undefined;
    this.api.importRaw(this.buf, 'GLOBAL', undefined, false).subscribe({
      next: (r) => { this.result = r; this.loading = false; },
      error: (err) => { this.error = err?.message ?? 'Dry run failed'; this.loading = false; },
    });
  }

  apply() {
    if (!this.buf) return;
    this.loading = true;
    this.error = undefined;
    this.api.importRaw(this.buf, 'GLOBAL', undefined, true).subscribe({
      next: (r) => {
        this.result = r;
        this.loading = false;
        this.resetInput();
      },
      error: (err) => { this.error = err?.message ?? 'Import failed'; this.loading = false; },
    });
  }

  private resetInput() {
    this.buf = undefined;
    // Reset the native input so the same file can be selected again
    this.fileInput.nativeElement.value = '';
  }
}
