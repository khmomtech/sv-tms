// eslint-disable-next-line @typescript-eslint/consistent-type-imports
import { HttpClient } from '@angular/common/http';
import { Injectable } from '@angular/core';
import type { Observable } from 'rxjs';

import { environment } from '../environments/environment';

@Injectable({
  providedIn: 'root',
})
export class SsoService {
  private readonly baseUrl = `${environment.baseUrl}/api/sso`;

  constructor(private http: HttpClient) {}

  authenticateWithSsoToken(ssoToken: string): Observable<any> {
    return this.http.post<any>(`${this.baseUrl}/authenticate`, { ssoToken });
  }

  validateSsoToken(ssoToken: string): Observable<any> {
    return this.http.post<any>(`${this.baseUrl}/validate`, { ssoToken });
  }

  createSsoToken(username: string): Observable<any> {
    return this.http.post<any>(`${this.baseUrl}/create-token`, { username });
  }
}
