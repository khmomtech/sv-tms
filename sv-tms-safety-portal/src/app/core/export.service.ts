import { Injectable } from '@angular/core';
import { HttpClient, HttpResponse } from '@angular/common/http';
import { environment } from '../../environments/environment';
import { SafetyService } from './safety.service';
import { generateXlsx, generatePdf } from './export-util';

@Injectable({ providedIn: 'root' })
export class ExportService {
  private base = environment.apiBaseUrl;
  constructor(private http: HttpClient, private safety: SafetyService) {}

  async exportChecks(dateFrom: string | null, dateTo: string | null, format: 'xlsx' | 'pdf'){
    const params: any = {};
    if(dateFrom) params.dateFrom = dateFrom;
    if(dateTo) params.dateTo = dateTo;
    params.format = format;

    try {
      const resp = await this.http.get(`${this.base}/safety/checks/export`, { params, responseType: 'blob', observe: 'response' }).toPromise() as HttpResponse<Blob>;
      if (resp.status === 200) {
        // forward blob to download using header filename if present
        const disposition = resp.headers.get('content-disposition') || '';
        let fname = `export.${format}`;
        const m = /filename\*=UTF-8''(.+)$/.exec(disposition);
        if (m && m[1]) fname = decodeURIComponent(m[1]);
        const blob = resp.body as Blob;
        const url = window.URL.createObjectURL(blob);
        const a = document.createElement('a');
        a.href = url;
        a.download = fname;
        document.body.appendChild(a);
        a.click();
        a.remove();
        window.URL.revokeObjectURL(url);
        return true;
      }
    } catch (e) {
      // fallthrough to client-side generation
    }

    // Fallback: fetch checks and generate client-side
    try {
      const res: any = await this.safety.getChecks({ page: 0, size: 1000 }).toPromise();
      const rows = (res && res.content) ? res.content : res || [];
      const filename = `safety_checks_${new Date().toISOString()}.${format}`;
      if (format === 'xlsx') generateXlsx(rows, filename);
      else generatePdf(rows, filename);
      return true;
    } catch (err) {
      console.error('Export failed', err);
      return false;
    }
  }
}
