import type { HttpErrorResponse } from '@angular/common/http';
// eslint-disable-next-line @typescript-eslint/consistent-type-imports
import { HttpClient, HttpHeaders } from '@angular/common/http';
import { Injectable } from '@angular/core';
import type { Observable } from 'rxjs';
import { throwError } from 'rxjs';
import { map } from 'rxjs/operators';
import { catchError } from 'rxjs/operators';

import { environment } from '../environments/environment';

// eslint-disable-next-line @typescript-eslint/consistent-type-imports
import { AuthService } from './auth.service';

export interface AppVersionDto {
  id?: number;
  // Global
  latestVersion: string;
  minSupportedVersion: string;
  mandatoryUpdate: boolean;
  playstoreUrl: string;
  appstoreUrl: string;
  releaseNoteEn: string;
  releaseNoteKm: string;
  lastUpdated?: string;
  // Android
  androidLatestVersion: string;
  androidMandatoryUpdate: boolean;
  androidReleaseNoteEn: string;
  androidReleaseNoteKm: string;
  // iOS
  iosLatestVersion: string;
  iosMandatoryUpdate: boolean;
  iosReleaseNoteEn: string;
  iosReleaseNoteKm: string;
  // Maintenance
  maintenanceActive: boolean;
  maintenanceMessageEn: string;
  maintenanceMessageKm: string;
  maintenanceUntil: string;
  // Info
  infoEn: string;
  infoKm: string;
}

export function emptyAppVersion(): AppVersionDto {
  return {
    latestVersion: '',
    minSupportedVersion: '',
    mandatoryUpdate: false,
    playstoreUrl: '',
    appstoreUrl: '',
    releaseNoteEn: '',
    releaseNoteKm: '',
    androidLatestVersion: '',
    androidMandatoryUpdate: false,
    androidReleaseNoteEn: '',
    androidReleaseNoteKm: '',
    iosLatestVersion: '',
    iosMandatoryUpdate: false,
    iosReleaseNoteEn: '',
    iosReleaseNoteKm: '',
    maintenanceActive: false,
    maintenanceMessageEn: '',
    maintenanceMessageKm: '',
    maintenanceUntil: '',
    infoEn: '',
    infoKm: '',
  };
}

@Injectable({ providedIn: 'root' })
export class AppVersionService {
  private readonly base = `${environment.baseUrl}/api/admin/app-versions`;

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
    console.error('AppVersion API error:', error);
    return throwError(() => new Error(error?.error?.message ?? 'App version action failed'));
  }

  getLatest(): Observable<AppVersionDto> {
    return this.getAll().pipe(map((versions) => versions?.[0] ?? emptyAppVersion()));
  }

  getAll(): Observable<AppVersionDto[]> {
    return this.http
      .get<AppVersionDto[]>(this.base, { headers: this.headers() })
      .pipe(catchError(this.handleError));
  }

  save(dto: AppVersionDto): Observable<AppVersionDto> {
    return this.http
      .post<AppVersionDto>(this.base, dto, { headers: this.headers() })
      .pipe(catchError(this.handleError));
  }
}
