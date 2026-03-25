import { HttpClient } from '@angular/common/http';
import { Injectable } from '@angular/core';
import type { Observable } from 'rxjs';

import type { ApiResponse } from '../models/api-response.model';

export interface SystemStatus {
  initialized: boolean;
  message: string;
  timestamp?: number;
  endpoints?: {
    full_initialization: string;
    permissions_only: string;
    roles_only: string;
    users_only: string;
  };
}

@Injectable({
  providedIn: 'root',
})
export class SystemInitializationService {
  private readonly baseUrl = '/api/admin/system';

  constructor(private http: HttpClient) {}

  /**
   * Initialize complete system (permissions, roles, users)
   */
  initializeSystem(): Observable<ApiResponse<string>> {
    return this.http.post<ApiResponse<string>>(`${this.baseUrl}/initialize`, {});
  }

  /**
   * Initialize only permissions
   */
  initializePermissions(): Observable<ApiResponse<string>> {
    return this.http.post<ApiResponse<string>>(`${this.baseUrl}/initialize/permissions`, {});
  }

  /**
   * Initialize only roles
   */
  initializeRoles(): Observable<ApiResponse<string>> {
    return this.http.post<ApiResponse<string>>(`${this.baseUrl}/initialize/roles`, {});
  }

  /**
   * Initialize only users
   */
  initializeUsers(): Observable<ApiResponse<string>> {
    return this.http.post<ApiResponse<string>>(`${this.baseUrl}/initialize/users`, {});
  }

  /**
   * Get system initialization status
   */
  getSystemStatus(): Observable<ApiResponse<SystemStatus>> {
    return this.http.get<ApiResponse<SystemStatus>>(`${this.baseUrl}/status`);
  }
}
