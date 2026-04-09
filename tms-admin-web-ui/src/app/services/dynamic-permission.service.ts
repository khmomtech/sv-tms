import { HttpClient } from '@angular/common/http';
import { Injectable } from '@angular/core';
import { Observable } from 'rxjs';

import { environment } from '../environments/environment';

export interface DynamicPermission {
  id?: number;
  name: string;
  description: string;
  resourceType: string;
  actionType: string;
}

export interface CreatePermissionRequest {
  name: string;
  description: string;
  resourceType: string;
  actionType: string;
}

export interface UpdatePermissionRequest {
  description: string;
  resourceType: string;
  actionType: string;
}

@Injectable({
  providedIn: 'root',
})
export class DynamicPermissionService {
  private readonly baseUrl = `${environment.baseUrl}/api/admin/dynamic-permissions`;

  constructor(private http: HttpClient) {}

  getAllPermissionNames(): Observable<string[]> {
    return this.http.get<string[]>(`${this.baseUrl}/names`);
  }

  getPermissionsByResource(resourceType: string): Observable<DynamicPermission[]> {
    return this.http.get<DynamicPermission[]>(`${this.baseUrl}/by-resource/${resourceType}`);
  }

  createPermission(request: CreatePermissionRequest): Observable<DynamicPermission> {
    return this.http.post<DynamicPermission>(this.baseUrl, request);
  }

  updatePermission(id: number, request: UpdatePermissionRequest): Observable<DynamicPermission> {
    return this.http.put<DynamicPermission>(`${this.baseUrl}/${id}`, request);
  }

  deletePermission(id: number): Observable<void> {
    return this.http.delete<void>(`${this.baseUrl}/${id}`);
  }

  checkPermissionExists(name: string): Observable<{ exists: boolean }> {
    return this.http.get<{ exists: boolean }>(`${this.baseUrl}/exists/${name}`);
  }

  clearCache(): Observable<void> {
    return this.http.post<void>(`${this.baseUrl}/clear-cache`, {});
  }
}
