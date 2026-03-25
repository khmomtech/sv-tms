import { HttpClient, HttpHeaders, HttpParams } from '@angular/common/http';
import { Injectable } from '@angular/core';
import type { Observable } from 'rxjs';
import { map } from 'rxjs/operators';

import { environment } from '../environments/environment';
import type { ApiResponse } from '../models/api-response.model';
import type { LoadingDocument, LoadingDocumentType } from '../models/loading-document.model';
import type { LoadingEmptiesReturn } from '../models/loading-empties-return.model';
import type { LoadingPalletItem } from '../models/loading-pallet-item.model';
import type { LoadingQueue, WarehouseCode } from '../models/loading-queue.model';
import type { LoadingSession } from '../models/loading-session.model';
// eslint-disable-next-line @typescript-eslint/consistent-type-imports
import { AuthService } from './auth.service';

export interface LoadingQueuePayload {
  dispatchId: number;
  warehouseCode: WarehouseCode;
  queuePosition?: number | null;
  remarks?: string | null;
}

export interface LoadingSessionStartPayload {
  dispatchId: number;
  queueId?: number | null;
  warehouseCode?: WarehouseCode;
  bay?: string | null;
  startedAt?: string;
  remarks?: string | null;
}

export interface LoadingSessionCompletePayload {
  sessionId: number;
  endedAt?: string;
  remarks?: string | null;
  palletItems?: LoadingPalletItem[];
  emptiesReturns?: LoadingEmptiesReturn[];
}

export interface LoadingGateUpdatePayload {
  bay?: string | null;
  queuePosition?: number | null;
  remarks?: string | null;
}

export interface LoadingDispatchDetail {
  dispatchId: number;
  dispatch: any;
  queue: LoadingQueue | null;
  session: LoadingSession | null;
  preEntrySafetyRequired?: boolean | null;
  preEntrySafetyStatus?: string | null;
  loadingSafetyStatus?: string | null;
}

@Injectable({ providedIn: 'root' })
export class LoadingOpsService {
  private readonly apiUrl = `${environment.baseUrl}/api/loading-ops`;

  constructor(
    private readonly http: HttpClient,
    private readonly authService: AuthService,
  ) {}

  private headers(): HttpHeaders {
    const token = this.authService.getToken();
    return new HttpHeaders({
      'Content-Type': 'application/json',
      Authorization: `Bearer ${token}`,
    });
  }

  enqueue(payload: LoadingQueuePayload): Observable<LoadingQueue> {
    return this.http
      .post<ApiResponse<LoadingQueue>>(`${this.apiUrl}/queue`, payload, {
        headers: this.headers(),
      })
      .pipe(map((res) => res.data));
  }

  callToBay(queueId: number, bay?: string, remarks?: string | null): Observable<LoadingQueue> {
    let params = new HttpParams();
    if (bay) params = params.set('bay', bay);
    if (remarks && remarks.trim()) params = params.set('remarks', remarks.trim());
    return this.http
      .put<ApiResponse<LoadingQueue>>(
        `${this.apiUrl}/queue/${queueId}/call`,
        {},
        {
          headers: this.headers(),
          params,
        },
      )
      .pipe(map((res) => res.data));
  }

  updateGateInfo(queueId: number, payload: LoadingGateUpdatePayload): Observable<LoadingQueue> {
    return this.http
      .put<ApiResponse<LoadingQueue>>(`${this.apiUrl}/queue/${queueId}/gate`, payload || {}, {
        headers: this.headers(),
      })
      .pipe(map((res) => res.data));
  }

  startLoading(payload: LoadingSessionStartPayload): Observable<LoadingSession> {
    return this.http
      .post<ApiResponse<LoadingSession>>(`${this.apiUrl}/sessions/start`, payload, {
        headers: this.headers(),
      })
      .pipe(map((res) => res.data));
  }

  completeLoading(payload: LoadingSessionCompletePayload): Observable<LoadingSession> {
    return this.http
      .put<ApiResponse<LoadingSession>>(`${this.apiUrl}/sessions/complete`, payload, {
        headers: this.headers(),
      })
      .pipe(map((res) => res.data));
  }

  queueByWarehouse(warehouse: WarehouseCode, opts?: any): Observable<any> {
    let params = new HttpParams().set('warehouse', warehouse);
    if (opts) {
      Object.entries(opts).forEach(([key, value]) => {
        if (value !== undefined && value !== null && value !== '') {
          params = params.set(key, value as any);
        }
      });
    }
    return this.http
      .get<ApiResponse<any>>(`${this.apiUrl}/queue`, {
        headers: this.headers(),
        params,
      })
      .pipe(
        map((res) => {
          const body = res.data;
          if (body && Array.isArray(body.content)) {
            return body;
          }
          return body;
        }),
      );
  }

  queueForDispatch(dispatchId: number): Observable<LoadingQueue> {
    return this.http
      .get<ApiResponse<LoadingQueue>>(`${this.apiUrl}/queue/dispatch/${dispatchId}`, {
        headers: this.headers(),
      })
      .pipe(map((res) => res.data));
  }

  sessionForDispatch(dispatchId: number): Observable<LoadingSession> {
    return this.http
      .get<ApiResponse<LoadingSession>>(`${this.apiUrl}/sessions/dispatch/${dispatchId}`, {
        headers: this.headers(),
      })
      .pipe(map((res) => res.data));
  }

  getDispatchDetail(dispatchId: number): Observable<LoadingDispatchDetail> {
    return this.http
      .get<ApiResponse<LoadingDispatchDetail>>(`${this.apiUrl}/dispatch/${dispatchId}/detail`, {
        headers: this.headers(),
      })
      .pipe(map((res) => res.data));
  }

  uploadDocument(
    sessionId: number,
    documentType: LoadingDocumentType,
    file: File,
  ): Observable<ApiResponse<any>> {
    const formData = new FormData();
    formData.append('file', file);
    formData.append('documentType', documentType);
    return this.http.post<ApiResponse<any>>(
      `${this.apiUrl}/sessions/${sessionId}/documents`,
      formData,
      {
        headers: new HttpHeaders({
          Authorization: `Bearer ${this.authService.getToken()}`,
        }),
      },
    );
  }

  /** List documents for a session */
  getSessionDocuments(sessionId: number) {
    return this.http
      .get<ApiResponse<LoadingDocument[]>>(`${this.apiUrl}/sessions/${sessionId}/documents`, {
        headers: this.headers(),
      })
      .pipe(map((res) => res.data));
  }

  /** Download a specific session document as blob */
  downloadSessionDocument(sessionId: number, documentId: number) {
    const url = `${this.apiUrl}/sessions/${sessionId}/documents/${documentId}`;
    return this.http.get(url, {
      headers: this.headers(),
      responseType: 'blob',
    });
  }
}
