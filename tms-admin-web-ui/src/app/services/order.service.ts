import type { HttpErrorResponse } from '@angular/common/http';
// eslint-disable-next-line @typescript-eslint/consistent-type-imports
import { HttpClient } from '@angular/common/http';
import { HttpHeaders } from '@angular/common/http';
import { Injectable } from '@angular/core';
import type { Observable } from 'rxjs';
import { catchError, throwError } from 'rxjs';

import { environment } from '../environments/environment';
import type { Order } from '../models/order.model';

// eslint-disable-next-line @typescript-eslint/consistent-type-imports
import { AuthService } from './auth.service';

@Injectable({
  providedIn: 'root',
})
export class OrderService {
  private apiUrl = `${environment.baseUrl}/api/admin/orders`;
  errorMessage = 'Something went wrong. Please try again later.';

  constructor(
    private http: HttpClient,
    private authService: AuthService,
  ) {}

  private getHeaders(): HttpHeaders {
    const token = this.authService.getToken();
    return new HttpHeaders({
      'Content-Type': 'application/json',
      Authorization: `Bearer ${token}`,
    });
  }

  getOrders(page: number = 0, size: number = 5): Observable<any> {
    return this.http
      .get(`${this.apiUrl}/list?page=${page}&size=${size}`, { headers: this.getHeaders() })
      .pipe(catchError(this.handleError));
  }

  searchOrders(
    customerName?: string,
    status?: string,
    page: number = 0,
    size: number = 5,
  ): Observable<any> {
    let query = `${this.apiUrl}/search?page=${page}&size=${size}`;
    if (customerName) query += `&customerName=${customerName}`;
    if (status) query += `&status=${status}`;
    return this.http.get(query, { headers: this.getHeaders() }).pipe(catchError(this.handleError));
  }

  getOrderById(orderId: number): Observable<any> {
    return this.http
      .get(`${this.apiUrl}/${orderId}`, { headers: this.getHeaders() })
      .pipe(catchError(this.handleError));
  }

  createOrder(order: Order): Observable<any> {
    return this.http
      .post(`${this.apiUrl}/add`, order, { headers: this.getHeaders() })
      .pipe(catchError(this.handleError));
  }

  updateOrder(orderId: number, order: Order): Observable<any> {
    return this.http
      .put(`${this.apiUrl}/update/${orderId}`, order, { headers: this.getHeaders() })
      .pipe(catchError(this.handleError));
  }

  updateOrderStatus(orderId: number, status: string): Observable<any> {
    return this.http
      .put(`${this.apiUrl}/${orderId}/status/${status}`, {}, { headers: this.getHeaders() })
      .pipe(catchError(this.handleError));
  }

  deleteOrder(orderId: number): Observable<void> {
    return this.http
      .delete<void>(`${this.apiUrl}/delete/${orderId}`, { headers: this.getHeaders() })
      .pipe(catchError(this.handleError));
  }

  private handleError(error: HttpErrorResponse): Observable<never> {
    console.error(' API Error:', error);
    let errorMessage = 'Something went wrong. Please try again later.';

    if (error.error) {
      if (typeof error.error === 'string') {
        errorMessage = error.error;
      } else if (error.error.message) {
        errorMessage = error.error.message;
      } else if (error.error.errors) {
        errorMessage = Object.values(error.error.errors).join(', ');
      }
    } else if (error.status === 0) {
      errorMessage = ' Unable to connect to the server. Please check your internet connection.';
    } else if (error.status === 400) {
      errorMessage = ' Bad request! Please check your input.';
    } else if (error.status === 401) {
      errorMessage = ' Unauthorized! Please log in again.';
    } else if (error.status === 500) {
      errorMessage = ' Server error! Please try again later.';
    }
    return throwError(() => new Error(errorMessage));
  }
}
