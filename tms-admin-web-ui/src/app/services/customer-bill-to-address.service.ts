import { HttpClient, HttpHeaders } from '@angular/common/http';
import { Injectable } from '@angular/core';
import type { Observable } from 'rxjs';
import { throwError } from 'rxjs';
import { catchError } from 'rxjs/operators';

import { environment } from '../environments/environment';
import type { ApiResponse } from '../models/api-response.model';
import type { CustomerBillToAddress } from '../models/customer-bill-to-address.model';
import { AuthService } from './auth.service';

@Injectable({ providedIn: 'root' })
export class CustomerBillToAddressService {
  private readonly baseUrl = `${environment.apiUrl}/admin/customers`;

  constructor(
    private readonly http: HttpClient,
    private readonly authService: AuthService,
  ) {}

  private getHeaders(): HttpHeaders {
    const token = this.authService.getToken();
    return new HttpHeaders({
      'Content-Type': 'application/json',
      Authorization: token ? `Bearer ${token}` : '',
    });
  }

  list(customerId: number): Observable<ApiResponse<CustomerBillToAddress[]>> {
    return this.http
      .get<
        ApiResponse<CustomerBillToAddress[]>
      >(`${this.baseUrl}/${customerId}/bill-to-addresses`, { headers: this.getHeaders() })
      .pipe(catchError((e) => throwError(() => e)));
  }

  search(customerId: number, search?: string, page = 0, size = 10): Observable<ApiResponse<any>> {
    const params: any = {};
    if (search && String(search).trim()) params.search = String(search).trim();
    params.page = String(page);
    params.size = String(size);
    return this.http
      .get<ApiResponse<any>>(`${this.baseUrl}/${customerId}/bill-to-addresses`, {
        headers: this.getHeaders(),
        params,
      })
      .pipe(catchError((e) => throwError(() => e)));
  }

  create(
    customerId: number,
    payload: CustomerBillToAddress,
  ): Observable<ApiResponse<CustomerBillToAddress>> {
    return this.http
      .post<
        ApiResponse<CustomerBillToAddress>
      >(`${this.baseUrl}/${customerId}/bill-to-addresses`, payload, { headers: this.getHeaders() })
      .pipe(catchError((e) => throwError(() => e)));
  }

  update(
    customerId: number,
    billToId: number,
    payload: Partial<CustomerBillToAddress>,
  ): Observable<ApiResponse<CustomerBillToAddress>> {
    return this.http
      .put<
        ApiResponse<CustomerBillToAddress>
      >(`${this.baseUrl}/${customerId}/bill-to-addresses/${billToId}`, payload, { headers: this.getHeaders() })
      .pipe(catchError((e) => throwError(() => e)));
  }

  delete(customerId: number, billToId: number): Observable<ApiResponse<string>> {
    return this.http
      .delete<ApiResponse<string>>(`${this.baseUrl}/${customerId}/bill-to-addresses/${billToId}`, {
        headers: this.getHeaders(),
      })
      .pipe(catchError((e) => throwError(() => e)));
  }

  migrateLegacy(customerId: number): Observable<ApiResponse<number>> {
    return this.http
      .post<
        ApiResponse<number>
      >(`${this.baseUrl}/${customerId}/bill-to-addresses/migrate-legacy`, {}, { headers: this.getHeaders() })
      .pipe(catchError((e) => throwError(() => e)));
  }

  exportCsv(customerId: number): Observable<Blob> {
    const token = this.authService.getToken();
    const headers = new HttpHeaders({
      Authorization: token ? `Bearer ${token}` : '',
    });
    return this.http
      .get(`${this.baseUrl}/${customerId}/bill-to-addresses/export`, {
        headers,
        responseType: 'blob',
      })
      .pipe(catchError((e) => throwError(() => e)));
  }
}
