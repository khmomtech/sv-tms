import { HttpClient } from '@angular/common/http';
import { Injectable } from '@angular/core';

import { environment } from '../environments/environment';
import type { ApiResponse } from '../models/api-response.model';

@Injectable({ providedIn: 'root' })
export class MaintenanceImportService {
  private readonly apiUrl = `${environment.apiBaseUrl}/admin/maintenance/import/excel`;

  constructor(private readonly http: HttpClient) {}

  importExcel(file: File) {
    const form = new FormData();
    form.append('file', file);
    return this.http.post<ApiResponse<Record<string, any>>>(this.apiUrl, form);
  }
}
