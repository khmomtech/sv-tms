// eslint-disable-next-line @typescript-eslint/consistent-type-imports
import { HttpClient } from '@angular/common/http';
import { Injectable } from '@angular/core';
import type { Observable } from 'rxjs';

import { environment } from '../environments/environment';
import type { Role } from '../models/role.model';

@Injectable({
  providedIn: 'root',
})
export class RoleService {
  private readonly baseUrl = `${environment.baseUrl}/api/admin/roles`;

  constructor(private http: HttpClient) {}

  getAllRoles(): Observable<Role[]> {
    return this.http.get<Role[]>(this.baseUrl);
  }

  getRoleById(id: number): Observable<Role> {
    return this.http.get<Role>(`${this.baseUrl}/${id}`);
  }

  createRole(role: Role): Observable<Role> {
    return this.http.post<Role>(this.baseUrl, role);
  }

  updateRole(role: Role): Observable<Role> {
    return this.http.put<Role>(`${this.baseUrl}/${role.id}`, role);
  }

  deleteRole(id: number): Observable<void> {
    return this.http.delete<void>(`${this.baseUrl}/${id}`);
  }

  addPermissionToRole(roleId: number, permissionId: number): Observable<Role> {
    return this.http.post<Role>(`${this.baseUrl}/${roleId}/permissions/${permissionId}`, {});
  }

  removePermissionFromRole(roleId: number, permissionId: number): Observable<Role> {
    return this.http.delete<Role>(`${this.baseUrl}/${roleId}/permissions/${permissionId}`);
  }

  getRolePermissions(roleId: number): Observable<any[]> {
    return this.http.get<any[]>(`${this.baseUrl}/${roleId}/permissions`);
  }
}
