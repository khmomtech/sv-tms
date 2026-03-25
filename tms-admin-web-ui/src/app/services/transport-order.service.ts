import type { HttpErrorResponse } from '@angular/common/http';
// eslint-disable-next-line @typescript-eslint/consistent-type-imports
import { HttpClient } from '@angular/common/http';
import { HttpHeaders } from '@angular/common/http';
import { Injectable, Inject } from '@angular/core';
import type { Observable } from 'rxjs';
import { throwError } from 'rxjs';
import { catchError, map } from 'rxjs/operators';

import { environment } from '../environments/environment';
import type { ApiResponse } from '../models/api-response.model';
import type { Customer } from '../models/customer.model';
import type { TransportOrderResponseDto } from '../models/transport-order-response.model';
import type { TransportOrder } from '../models/transport-order.model';

// eslint-disable-next-line @typescript-eslint/consistent-type-imports
import { AuthService } from './auth.service';

@Injectable({ providedIn: 'root' })
export class TransportOrderService {
  /** Fetch shipment types for dropdown */
  getShipmentTypes(): Observable<string[]> {
    return this.http.get<unknown>(`${this.apiUrl}/types`, { headers: this.getHeaders() }).pipe(
      map((payload) => this.normalizeStringArray(payload)),
      catchError(this.handleError),
    );
  }
  private readonly apiUrl = `${environment.apiUrl}/admin/transportorders`;
  private readonly customerApiUrl = `${environment.apiUrl}/admin/customers`;
  private readonly driverApiUrl = `${environment.apiUrl}/admin/drivers`;

  constructor(
    @Inject(HttpClient) private readonly http: HttpClient,
    private readonly authService: AuthService,
  ) {}

  /** Development diagnostic: log presence of auth token (masked) for outgoing requests */
  private debugLogAuthFor(url: string): void {
    try {
      // Only log in non-production to avoid leaking tokens in production logs
      if ((environment as any)?.production) return;
      const token = this.authService.getToken();
      const has = !!token;
      const masked = token ? `${token.slice(0, 8)}... (len=${token.length})` : 'null';
      // Use console.debug so it's easy to filter in devtools
      console.debug(`[AuthDiag] ${has ? 'AUTH present' : 'NO AUTH'} for ${url} -> ${masked}`);
    } catch (err) {
      console.debug('[AuthDiag] Error while detecting auth token', err);
    }
  }

  private getHeaders(): HttpHeaders {
    const token = this.authService.getToken();
    return new HttpHeaders({
      'Content-Type': 'application/json',
      Authorization: `Bearer ${token}`,
    });
  }

  // For form uploads (multipart), do not set Content-Type explicitly so browser can set the boundary
  private getFormHeaders(): HttpHeaders {
    const token = this.authService.getToken();
    return new HttpHeaders({
      Authorization: `Bearer ${token}`,
    });
  }

  private handleError(error: HttpErrorResponse): Observable<never> {
    const apiError = error?.error as
      | { message?: string; error?: string; validationErrors?: Record<string, string> }
      | undefined;
    const validationErrors = apiError?.validationErrors ?? {};
    const firstValidationMessage =
      Object.values(validationErrors).find((value) => typeof value === 'string' && value.trim()) ??
      '';
    const backendMessage = apiError?.message || apiError?.error || '';
    const message =
      firstValidationMessage ||
      backendMessage ||
      error.message ||
      'Something went wrong. Please try again later.';
    console.error(' API Error:', error, 'Resolved message:', message);
    return throwError(() => new Error(message));
  }

  private normalizeStringArray(payload: unknown): string[] {
    if (Array.isArray(payload)) {
      return payload.filter((v): v is string => typeof v === 'string');
    }

    const p = payload as any;
    const candidates = [p?.data?.content, p?.data?.types, p?.data, p?.types, p?.content];
    for (const c of candidates) {
      if (Array.isArray(c)) {
        return c.filter((v): v is string => typeof v === 'string');
      }
    }

    return [];
  }

  //  CRUD Operations
  getAllOrders(): Observable<ApiResponse<TransportOrder[]>> {
    return this.http
      .get<ApiResponse<TransportOrder[]>>(`${this.apiUrl}/list`, {
        headers: this.getHeaders(),
      })
      .pipe(catchError(this.handleError));
  }

  getOrders(page = 0, size = 10): Observable<ApiResponse<any>> {
    return this.http
      .get<ApiResponse<any>>(`${this.apiUrl}?page=${page}&size=${size}`, {
        headers: this.getHeaders(),
      })
      .pipe(catchError(this.handleError));
  }

  getOrderById(orderId: number): Observable<ApiResponse<TransportOrderResponseDto>> {
    return this.http
      .get<ApiResponse<TransportOrderResponseDto>>(`${this.apiUrl}/${orderId}`, {
        headers: this.getHeaders(),
      })
      .pipe(catchError(this.handleError));
  }

  createOrder(
    order: TransportOrderResponseDto,
  ): Observable<ApiResponse<TransportOrderResponseDto>> {
    return this.http
      .post<ApiResponse<TransportOrderResponseDto>>(this.apiUrl, order, {
        headers: this.getHeaders(),
      })
      .pipe(catchError(this.handleError));
  }

  updateOrder(
    orderId: number,
    order: TransportOrderResponseDto,
  ): Observable<ApiResponse<TransportOrderResponseDto>> {
    return this.http
      .put<ApiResponse<TransportOrderResponseDto>>(`${this.apiUrl}/${orderId}`, order, {
        headers: this.getHeaders(),
      })
      .pipe(catchError(this.handleError));
  }

  deleteOrder(orderId: number): Observable<ApiResponse<string>> {
    return this.http
      .delete<ApiResponse<string>>(`${this.apiUrl}/${orderId}`, {
        headers: this.getHeaders(),
      })
      .pipe(catchError(this.handleError));
  }

  updateOrderStatus(
    orderId: number,
    status: string,
  ): Observable<ApiResponse<TransportOrderResponseDto>> {
    const url = `${this.apiUrl}/${orderId}/status?status=${encodeURIComponent(status)}`;
    return this.http
      .put<ApiResponse<TransportOrderResponseDto>>(
        url,
        {},
        {
          headers: this.getHeaders(),
        },
      )
      .pipe(catchError(this.handleError));
  }

  assignDispatch(
    orderId: number,
    driverId: string,
  ): Observable<ApiResponse<{ assignedDriver: any }>> {
    const url = `${this.apiUrl}/${orderId}/assign-driver`;
    return this.http
      .post<ApiResponse<{ assignedDriver: any }>>(
        url,
        { driverId },
        {
          headers: this.getHeaders(),
        },
      )
      .pipe(catchError(this.handleError));
  }

  // 🔍 Search & Filter (Legacy)
  searchOrders(query: string, page = 0, size = 10): Observable<ApiResponse<any>> {
    const url = `${this.apiUrl}/search?query=${encodeURIComponent(query)}&page=${page}&size=${size}`;
    return this.http
      .get<ApiResponse<any>>(url, {
        headers: this.getHeaders(),
      })
      .pipe(catchError(this.handleError));
  }

  //  Advanced Filter (Combined)
  getFilteredOrders(
    query: string = '',
    status: string = '',
    fromDate: string = '',
    toDate: string = '',
    sort: 'asc' | 'desc' = 'asc',
    page: number = 0,
    size: number = 10,
  ): Observable<ApiResponse<any>> {
    const params: string[] = [`page=${page}`, `size=${size}`, `sort=createdAt,${sort}`];
    if (query) params.push(`query=${encodeURIComponent(query)}`);
    if (status) params.push(`status=${encodeURIComponent(status)}`);
    if (fromDate) params.push(`fromDate=${encodeURIComponent(fromDate)}`);
    if (toDate) params.push(`toDate=${encodeURIComponent(toDate)}`);

    const url = `${this.apiUrl}/filter?${params.join('&')}`;
    return this.http
      .get<ApiResponse<any>>(url, {
        headers: this.getHeaders(),
      })
      .pipe(catchError(this.handleError));
  }

  // 👥 Customer Utilities
  getAvailableSellers(): Observable<ApiResponse<any[]>> {
    return this.http
      .get<ApiResponse<any[]>>(`${this.apiUrl}/sellers`, {
        headers: this.getHeaders(),
      })
      .pipe(catchError(this.handleError));
  }

  searchCustomers(query: string, page = 0, size = 10): Observable<ApiResponse<Customer[]>> {
    const url = `${this.customerApiUrl}/search?query=${encodeURIComponent(query)}&page=${page}&size=${size}`;
    return this.http
      .get<ApiResponse<Customer[]>>(url, {
        headers: this.getHeaders(),
      })
      .pipe(catchError(this.handleError));
  }

  // 📥 Unscheduled Orders
  getUnscheduledOrders(): Observable<ApiResponse<TransportOrder[]>> {
    return this.http
      .get<ApiResponse<TransportOrder[]>>(`${this.apiUrl}/unscheduled`, {
        headers: this.getHeaders(),
      })
      .pipe(catchError(this.handleError));
  }

  //  Driver Utilities
  getAvailableDrivers(): Observable<ApiResponse<any>> {
    return this.http
      .get<ApiResponse<any>>(`${this.driverApiUrl}/available`, {
        headers: this.getHeaders(),
      })
      .pipe(catchError(this.handleError));
  }

  /** Retrieve delivery note PDF/blob for order (authenticated) */
  getDeliveryNote(orderId: number) {
    const url = `${this.apiUrl}/${orderId}/delivery-note`;
    this.debugLogAuthFor(url);
    return this.http
      .get(url, {
        headers: this.getHeaders(),
        responseType: 'blob',
      })
      .pipe(catchError(this.handleError));
  }

  /** Retrieve tracking information for a specific order */
  getOrderTracking(orderId: number): Observable<ApiResponse<any>> {
    const url = `${this.apiUrl}/${orderId}/tracking`;
    this.debugLogAuthFor(url);
    return this.http
      .get<ApiResponse<any>>(url, {
        headers: this.getHeaders(),
      })
      .pipe(catchError(this.handleError));
  }

  /** Alternate delivery note route used by some backends */
  getDeliveryNoteAlternate(orderId: number) {
    const url = `${environment.baseUrl}/api/orders/${orderId}/delivery-note`;
    this.debugLogAuthFor(url);
    return this.http
      .get(url, {
        headers: this.getHeaders(),
        responseType: 'blob',
      })
      .pipe(catchError(this.handleError));
  }

  /** Retrieve invoice PDF/blob for order (authenticated) */
  getInvoice(orderId: number) {
    const url = `${this.apiUrl}/${orderId}/invoice`;
    this.debugLogAuthFor(url);
    return this.http
      .get(url, {
        headers: this.getHeaders(),
        responseType: 'blob',
      })
      .pipe(catchError(this.handleError));
  }

  /** Notify customer (e.g., send SMS/email) */
  notifyCustomer(
    orderId: number,
    payload: { message?: string } = {},
  ): Observable<ApiResponse<any>> {
    const url = `${this.apiUrl}/${orderId}/notify-customer`;
    return this.http
      .post<ApiResponse<any>>(url, payload, {
        headers: this.getHeaders(),
      })
      .pipe(catchError(this.handleError));
  }

  /** Cancel an order (soft-cancel) */
  cancelOrder(orderId: number, reason?: string): Observable<ApiResponse<any>> {
    const url = `${this.apiUrl}/${orderId}/cancel`;
    return this.http
      .post<ApiResponse<any>>(url, { reason }, { headers: this.getHeaders() })
      .pipe(catchError(this.handleError));
  }

  getOrdersByCustomer(customerId: number): Observable<ApiResponse<TransportOrder[]>> {
    return this.http
      .get<ApiResponse<TransportOrder[]>>(`${this.apiUrl}/customer/${customerId}`, {
        headers: this.getHeaders(),
      })
      .pipe(catchError(this.handleError));
  }

  /** Import transport orders for a customer via CSV/XLSX file upload */
  importOrders(customerId: number, file: File): Observable<ApiResponse<any>> {
    const url = `${this.apiUrl}/import?customerId=${customerId}`;
    const fd = new FormData();
    fd.append('file', file);
    this.debugLogAuthFor(url);
    return this.http
      .post<ApiResponse<any>>(url, fd, {
        headers: this.getFormHeaders(),
      })
      .pipe(catchError(this.handleError));
  }
}
