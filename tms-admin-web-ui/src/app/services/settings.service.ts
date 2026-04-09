import type { HttpErrorResponse } from '@angular/common/http';
// eslint-disable-next-line @typescript-eslint/consistent-type-imports
import { HttpClient } from '@angular/common/http';
import { HttpHeaders, HttpParams } from '@angular/common/http';
import { Injectable } from '@angular/core';
import type { Observable } from 'rxjs';
import { throwError } from 'rxjs';
import { catchError } from 'rxjs/operators';

import { environment } from '../environments/environment';

// eslint-disable-next-line @typescript-eslint/consistent-type-imports
import { AuthService } from './auth.service';

export interface SettingWriteRequest {
  groupCode: string;
  keyCode: string;
  scope: 'GLOBAL' | 'TENANT' | 'SITE' | 'ROLE' | 'USER';
  scopeRef?: string | null;
  value: any;
  reason: string;
}
export interface SettingReadResponse {
  groupCode: string;
  keyCode: string;
  type: string | null;
  value: any;
  scope: string;
  scopeRef?: string | null;
  version?: number | null;
  updatedBy?: string | null;
  updatedAt?: string | null;
}

export interface AppManagementCatalogItem {
  groupCode: string;
  keyCode: string;
  type: string;
  defaultValue: string | null;
  label: string;
  description: string;
}

export interface AppManagementCatalogResponse {
  scopes: string[];
  items: AppManagementCatalogItem[];
  resolutionOrder: string;
}

export interface AppBootstrapResponse {
  user: {
    id: number;
    roles: string[];
    derivedSegments: string[];
  };
  screens: Record<string, boolean>;
  features: Record<string, boolean>;
  policies: Record<string, unknown>;
  meta: {
    generatedAt: string;
    resolutionTraceVersion: string;
  };
}

@Injectable({ providedIn: 'root' })
export class SettingsService {
  private readonly base = `${environment.baseUrl}/api/admin/settings`;

  constructor(
    private readonly http: HttpClient,
    private readonly auth: AuthService,
  ) {}

  private headers(): HttpHeaders {
    const token = this.auth.getToken();
    return new HttpHeaders({
      'Content-Type': 'application/json',
      Authorization: `Bearer ${token}`,
    });
  }
  private handleError(error: HttpErrorResponse) {
    console.error('Settings API error:', error);
    return throwError(() => new Error(error?.error?.message ?? 'Settings action failed'));
  }

  getValue(
    groupCode: string,
    keyCode: string,
    scope = 'GLOBAL',
    scopeRef?: string | null,
  ): Observable<any> {
    let params = new HttpParams()
      .set('groupCode', groupCode)
      .set('keyCode', keyCode)
      .set('scope', scope);
    if (scopeRef) params = params.set('scopeRef', scopeRef);
    return this.http
      .get<any>(`${this.base}/value`, { headers: this.headers(), params })
      .pipe(catchError(this.handleError));
  }

  listValues(
    groupCode: string,
    scope = 'GLOBAL',
    scopeRef?: string | null,
    includeSecrets = false,
  ): Observable<SettingReadResponse[]> {
    let params = new HttpParams()
      .set('groupCode', groupCode)
      .set('scope', scope)
      .set('includeSecrets', includeSecrets);
    if (scopeRef) params = params.set('scopeRef', scopeRef);
    return this.http
      .get<SettingReadResponse[]>(`${this.base}/values`, { headers: this.headers(), params })
      .pipe(catchError(this.handleError));
  }

  upsert(req: SettingWriteRequest): Observable<SettingReadResponse> {
    return this.http
      .post<SettingReadResponse>(`${this.base}/value`, req, { headers: this.headers() })
      .pipe(catchError(this.handleError));
  }

  audit(
    groupCode?: string,
    keyCode?: string,
    page = 0,
    size = 20,
    scope?: 'GLOBAL' | 'TENANT' | 'SITE' | 'ROLE' | 'USER',
    scopeRef?: string | null,
  ) {
    let params = new HttpParams().set('page', page).set('size', size);
    if (groupCode) params = params.set('groupCode', groupCode);
    if (keyCode) params = params.set('keyCode', keyCode);
    if (scope) params = params.set('scope', scope);
    if (scopeRef) params = params.set('scopeRef', scopeRef);
    return this.http
      .get<any>(`${this.base}/audit`, { headers: this.headers(), params })
      .pipe(catchError(this.handleError));
  }

  importRaw(raw: ArrayBuffer, scope = 'GLOBAL', scopeRef?: string | null, apply = false) {
    let params = new HttpParams().set('scope', scope).set('apply', apply);
    if (scopeRef) params = params.set('scopeRef', scopeRef);
    return this.http
      .post(`${this.base}/import`, raw, {
        headers: this.headers().set('Content-Type', 'application/octet-stream'),
        params,
      })
      .pipe(catchError(this.handleError));
  }

  getAppManagementCatalog(): Observable<AppManagementCatalogResponse> {
    const primaryUrl = `${environment.baseUrl}/api/admin/app-management/catalog`;
    const compatibilityUrl = `${environment.baseUrl}/api/admin/settings/app-management/catalog`;
    return this.http
      .get<AppManagementCatalogResponse>(primaryUrl, {
        headers: this.headers(),
      })
      .pipe(
        catchError((error: HttpErrorResponse) => {
          if (error.status === 404) {
            return this.http.get<AppManagementCatalogResponse>(compatibilityUrl, {
              headers: this.headers(),
            });
          }
          return throwError(() => new Error(error?.error?.message ?? 'Settings action failed'));
        }),
      )
      .pipe(catchError(this.handleError));
  }

  getAppManagementEffective(userId: number): Observable<AppBootstrapResponse> {
    const params = new HttpParams().set('userId', userId);
    const primaryUrl = `${environment.baseUrl}/api/admin/app-management/effective`;
    const compatibilityUrl = `${environment.baseUrl}/api/admin/settings/app-management/effective`;
    return this.http
      .get<AppBootstrapResponse>(primaryUrl, {
        headers: this.headers(),
        params,
      })
      .pipe(
        catchError((error: HttpErrorResponse) => {
          if (error.status === 404) {
            return this.http.get<AppBootstrapResponse>(compatibilityUrl, {
              headers: this.headers(),
              params,
            });
          }
          return throwError(() => new Error(error?.error?.message ?? 'Settings action failed'));
        }),
      )
      .pipe(catchError(this.handleError));
  }
}
