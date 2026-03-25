import { HttpClient, HttpHeaders, HttpParams } from '@angular/common/http';
import { Injectable } from '@angular/core';
import type { Observable } from 'rxjs';
import { throwError, of } from 'rxjs';
import { catchError, map } from 'rxjs/operators';

import { environment } from '../environments/environment';
import type { ApiResponse } from '../models/api-response.model';
import type { CustomerAddress } from '../models/customer-address.model';
import { AuthService } from './auth.service';

export interface AddressSearchResult {
  addresses: CustomerAddress[];
  total: number;
  page: number;
  size: number;
}

@Injectable({
  providedIn: 'root',
})
export class CustomerAddressService {
  private readonly apiUrl = `${environment.apiUrl}/admin/customer-addresses`;

  constructor(
    private http: HttpClient,
    private authService: AuthService,
  ) {}

  private getHeaders(): HttpHeaders {
    const token = this.authService.getToken();
    return new HttpHeaders({
      'Content-Type': 'application/json',
      Authorization: token ? `Bearer ${token}` : '',
    });
  }

  private handleError(error: any): Observable<never> {
    console.error('CustomerAddressService API Error:', error);
    return throwError(() => new Error(error?.message || 'Server Error'));
  }

  private buildOptions(params?: HttpParams) {
    return {
      headers: this.getHeaders(),
      ...(params ? { params } : {}),
    };
  }

  list(customerId?: number): Observable<CustomerAddress[]> {
    const params = customerId ? new HttpParams().set('customerId', String(customerId)) : undefined;
    return this.http
      .get<ApiResponse<CustomerAddress[]>>(this.apiUrl, this.buildOptions(params))
      .pipe(
        map((res) => res?.data ?? []),
        catchError(this.handleError),
      );
  }

  searchAddressesByCustomer(
    customerId: number,
    search?: string,
    type?: string,
    page = 0,
    size = 10,
  ): Observable<AddressSearchResult> {
    let params = new HttpParams()
      .set('customerId', String(customerId))
      .set('page', String(page))
      .set('size', String(size));
    if (search?.trim()) {
      params = params.set('search', search.trim());
    }
    if (type?.trim()) {
      params = params.set('type', type.trim());
    }

    return this.http
      .get<
        ApiResponse<AddressSearchResult>
      >(`${environment.apiUrl}/admin/customer-addresses/search/customer`, this.buildOptions(params))
      .pipe(
        map((res) => res?.data ?? { addresses: [], total: 0, page, size }),
        catchError(this.handleError),
      );
  }

  getAllAddresses(): Observable<CustomerAddress[]> {
    return this.list();
  }

  getAddressesByCustomerId(customerId: number): Observable<CustomerAddress[]> {
    return this.list(customerId);
  }

  getAddressById(id: number): Observable<CustomerAddress> {
    return this.http
      .get<ApiResponse<CustomerAddress>>(`${this.apiUrl}/${id}`, {
        headers: this.getHeaders(),
      })
      .pipe(
        map((res) => res?.data as CustomerAddress),
        catchError(this.handleError),
      );
  }

  searchLocations(name: string): Observable<CustomerAddress[]> {
    return this.http
      .get<{
        data: CustomerAddress[];
      }>(`${this.apiUrl}/search?name=${encodeURIComponent(name)}`, { headers: this.getHeaders() })
      .pipe(
        map((response) => response.data ?? []),
        catchError(this.handleError),
      );
  }

  createAddress(address: Partial<CustomerAddress>): Observable<CustomerAddress> {
    return this.http
      .post<ApiResponse<CustomerAddress>>(this.apiUrl, address, { headers: this.getHeaders() })
      .pipe(
        map((res) => res?.data as CustomerAddress),
        catchError(this.handleError),
      );
  }

  updateAddress(id: number, address: Partial<CustomerAddress>): Observable<CustomerAddress> {
    return this.http
      .put<ApiResponse<CustomerAddress>>(`${this.apiUrl}/${id}`, address, {
        headers: this.getHeaders(),
      })
      .pipe(
        map((res) => res?.data as CustomerAddress),
        catchError(this.handleError),
      );
  }

  deleteAddress(id: number): Observable<void> {
    return this.http
      .delete<ApiResponse<string>>(`${this.apiUrl}/${id}`, { headers: this.getHeaders() })
      .pipe(
        map(() => undefined),
        catchError(this.handleError),
      );
  }

  exportAddresses(customerId: number): Observable<Blob> {
    return this.http
      .get(`${this.apiUrl}/export?customerId=${customerId}`, {
        headers: this.getHeaders(),
        responseType: 'blob',
      })
      .pipe(catchError(this.handleError));
  }

  importAddresses(file: File, customerId: number): Observable<ApiResponse<string>> {
    const formData = new FormData();
    formData.append('file', file);
    return this.http
      .post<ApiResponse<string>>(`${this.apiUrl}/import?customerId=${customerId}`, formData, {
        headers: new HttpHeaders({
          Authorization: this.authService.getToken() ? `Bearer ${this.authService.getToken()}` : '',
        }),
      })
      .pipe(catchError(this.handleError));
  }

  checkAddressExists(id: number): Observable<boolean> {
    return this.http
      .head(`${this.apiUrl}/${id}`, {
        headers: this.getHeaders(),
        observe: 'response',
      })
      .pipe(
        map((response) => response.status === 200),
        catchError(() => of(false)),
      );
  }
}
