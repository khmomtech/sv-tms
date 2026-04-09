import type { HttpErrorResponse } from '@angular/common/http';
// eslint-disable-next-line @typescript-eslint/consistent-type-imports
import { HttpClient } from '@angular/common/http';
import { HttpHeaders } from '@angular/common/http';
import { Injectable } from '@angular/core';
import type { Observable } from 'rxjs';
import { throwError } from 'rxjs';
import { catchError } from 'rxjs/operators';

import { environment } from '../environments/environment';
import type { ApiResponse } from '../models/api-response.model';

// eslint-disable-next-line @typescript-eslint/consistent-type-imports
import { AuthService } from './auth.service';

@Injectable({
  providedIn: 'root',
})
export class LoadProofService {
  private readonly apiUrl = `${environment.baseUrl}/api/admin/dispatches/proofs/load`;

  constructor(
    private http: HttpClient,
    private auth: AuthService,
  ) {}

  private getHeaders(): HttpHeaders {
    return new HttpHeaders({
      'Content-Type': 'application/json',
      Authorization: `Bearer ${this.auth.getToken()}`,
    });
  }

  private handleError(error: HttpErrorResponse): Observable<never> {
    console.error(' Load Proof API error:', error);
    return throwError(() => new Error('Failed to fetch load proof data.'));
  }

  getAllLoadProofs(): Observable<ApiResponse<any>> {
    return this.http
      .get<ApiResponse<any>>(this.apiUrl, {
        headers: this.getHeaders(),
      })
      .pipe(catchError(this.handleError));
  }
}
