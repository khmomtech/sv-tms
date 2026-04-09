import { HttpClient } from '@angular/common/http';
import { Injectable } from '@angular/core';

import { environment } from '../environments/environment';
import type { ApiResponse } from '../models/api-response.model';

export interface PmChecklistItemDto {
  checklistItemId: number;
  templateId: number;
  seq: number;
  label: string;
  required: boolean;
  inputType: 'CHECK' | 'TEXT' | 'NUMBER' | 'PHOTO';
}

export interface PmChecklistTemplateDto {
  templateId: number;
  itemCode?: string;
  templateName: string;
  active: boolean;
  items?: PmChecklistItemDto[];
}

@Injectable({ providedIn: 'root' })
export class PmChecklistService {
  private readonly apiUrl = `${environment.apiBaseUrl}/admin/pm/checklists/templates`;

  constructor(private readonly http: HttpClient) {}

  listTemplates() {
    return this.http.get<ApiResponse<PmChecklistTemplateDto[]>>(this.apiUrl);
  }

  getTemplate(id: number) {
    return this.http.get<ApiResponse<PmChecklistTemplateDto>>(`${this.apiUrl}/${id}`);
  }
}
