// eslint-disable-next-line @typescript-eslint/consistent-type-imports
import { HttpClient } from '@angular/common/http';
import { Injectable } from '@angular/core';
import type { Observable } from 'rxjs';

import { environment } from '../environments/environment';
import type { Permission } from '../models/permission.model';

@Injectable({
  providedIn: 'root',
})
export class PermissionService {
  private readonly baseUrl = `${environment.baseUrl}/api/admin/permissions`;

  constructor(private http: HttpClient) {}

  getAllPermissions(): Observable<Permission[]> {
    return this.http.get<Permission[]>(this.baseUrl);
  }

  getPermissionById(id: number): Observable<Permission> {
    return this.http.get<Permission>(`${this.baseUrl}/${id}`);
  }

  createPermission(permission: Permission): Observable<Permission> {
    return this.http.post<Permission>(this.baseUrl, permission);
  }

  updatePermission(permission: Permission): Observable<Permission> {
    return this.http.put<Permission>(`${this.baseUrl}/${permission.id}`, permission);
  }

  deletePermission(id: number): Observable<void> {
    return this.http.delete<void>(`${this.baseUrl}/${id}`);
  }
}
