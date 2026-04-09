// eslint-disable-next-line @typescript-eslint/consistent-type-imports
import { HttpClient } from '@angular/common/http';
import { Injectable } from '@angular/core';
import type { Observable } from 'rxjs';

export interface RefreshTokenDto {
  id: number;
  userId: number | null;
  token: string;
  issuedAt: string;
  expiresAt: string;
  revoked: boolean;
}

@Injectable({ providedIn: 'root' })
export class RefreshTokenAdminService {
  private base = '/api/admin/refresh-tokens';

  constructor(private http: HttpClient) {}

  list(userId?: number | null): Observable<RefreshTokenDto[]> {
    const params: any = {};
    if (userId != null) params.userId = userId;
    return this.http.get<RefreshTokenDto[]>(this.base, { params });
  }

  revoke(id: number) {
    return this.http.post(`${this.base}/${id}/revoke`, {});
  }
}
