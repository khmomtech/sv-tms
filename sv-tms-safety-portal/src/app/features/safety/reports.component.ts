import { Component } from '@angular/core';
import { ExportService } from '../../core/export.service';
import { NotificationService } from '../../core/notification.service';

function downloadBlob(response: any, defaultName: string){
  const contentDisposition = response.headers?.get?.('content-disposition');
  let filename = defaultName;
  if(contentDisposition){
    const match = /filename\*=UTF-8''(.+)$/.exec(contentDisposition) || /filename="?([^";]+)"?/.exec(contentDisposition);
    if(match) filename = decodeURIComponent(match[1]);
  }
  const blob = new Blob([response.body], { type: response.body.type || 'application/octet-stream' });
  const url = window.URL.createObjectURL(blob);
  const a = document.createElement('a');
  a.href = url; a.download = filename; document.body.appendChild(a); a.click(); a.remove(); window.URL.revokeObjectURL(url);
}

@Component({
  selector: 'app-safety-reports',
  standalone: true,
  template: `
    <h2 class="text-xl font-semibold">Reports & Exports</h2>
    <p class="mt-4">Generate Excel/PDF reports, monthly matrix export.</p>
    <div class="mt-4">
      <button (click)="export('xlsx')" [disabled]="loading" class="px-3 py-2 bg-blue-600 text-white rounded">Export Daily Compliance (XLSX)</button>
      <button (click)="export('pdf')" [disabled]="loading" class="ml-2 px-3 py-2 bg-gray-800 text-white rounded">Export Monthly Matrix (PDF)</button>
    </div>
  `
})
export class ReportsComponent {
  dateFrom: string | null = null;
  dateTo: string | null = null;
  loading = false;
  constructor(private exporter: ExportService, private notify: NotificationService) {}

  async export(format: 'xlsx' | 'pdf'){
    this.loading = true;
    try {
      const ok = await this.exporter.exportChecks(this.dateFrom, this.dateTo, format);
      if (ok) {
        this.notify.success('Export started/downloaded');
      } else {
        this.notify.error('Export failed');
      }
    } catch (e) {
      console.error(e);
      this.notify.error('Export failed');
    } finally {
      this.loading = false;
    }
  }
}
