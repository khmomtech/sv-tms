import { HttpClient, HttpParams } from '@angular/common/http';
import { Injectable } from '@angular/core';

import { environment } from '../environments/environment';
import type { ApiResponse } from '../models/api-response.model';
import type { PagedResponse } from '../models/api-response-page.model';

export interface EmployeeDto {
  id?: number;
  employeeCode?: string;
  firstName: string;
  lastName: string;
  email: string;
  phoneNumber?: string;
  department?: string;
  position?: string;
  hireDate?: string;
  status?: string;
  userId?: number;
}

@Injectable({ providedIn: 'root' })
export class EmployeeService {
  private readonly apiUrl = `${environment.apiBaseUrl}/admin/employees`;

  constructor(private readonly http: HttpClient) {}

  list(params: { search?: string; page?: number; size?: number }) {
    let p = new HttpParams();
    if (params.search) p = p.set('search', params.search);
    if (typeof params.page === 'number') p = p.set('page', String(params.page));
    if (typeof params.size === 'number') p = p.set('size', String(params.size));
    return this.http.get<ApiResponse<PagedResponse<EmployeeDto>>>(this.apiUrl, { params: p });
  }

  create(dto: EmployeeDto) {
    return this.http.post<ApiResponse<EmployeeDto>>(this.apiUrl, dto);
  }

  update(id: number, dto: Partial<EmployeeDto>) {
    return this.http.put<ApiResponse<EmployeeDto>>(`${this.apiUrl}/${id}`, dto);
  }

  delete(id: number) {
    return this.http.delete<ApiResponse<void>>(`${this.apiUrl}/${id}`);
  }
}
