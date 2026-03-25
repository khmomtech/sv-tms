import type { HttpErrorResponse } from '@angular/common/http';
// eslint-disable-next-line @typescript-eslint/consistent-type-imports
import { HttpClient } from '@angular/common/http';
import { HttpHeaders } from '@angular/common/http';
import { Injectable } from '@angular/core';
import type { Observable } from 'rxjs';
import { catchError, throwError } from 'rxjs';

import { environment } from '../environments/environment';
import type { Shipment } from '../models/shipment.model';

// eslint-disable-next-line @typescript-eslint/consistent-type-imports
import { AuthService } from './auth.service';

@Injectable({
  providedIn: 'root',
})
export class ShipmentService {
  private apiUrl = `${environment.baseUrl}/api/admin/shipments`;
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

  /** Fetch shipments with pagination */
  getShipments(page: number = 0, size: number = 5): Observable<any> {
    return this.http
      .get(`${this.apiUrl}/list?page=${page}&size=${size}`, { headers: this.getHeaders() })
      .pipe(catchError(this.handleError));
  }

  /** Get a single shipment by ID */
  getShipmentById(shipmentId: number): Observable<any> {
    return this.http
      .get(`${this.apiUrl}/${shipmentId}`, { headers: this.getHeaders() })
      .pipe(catchError(this.handleError));
  }

  /** Create a new shipment */
  createShipment(shipment: Shipment): Observable<any> {
    return this.http
      .post(`${this.apiUrl}/add`, shipment, { headers: this.getHeaders() })
      .pipe(catchError(this.handleError));
  }

  /** Update an existing shipment */
  updateShipment(shipmentId: number, shipment: Shipment): Observable<any> {
    return this.http
      .put(`${this.apiUrl}/update/${shipmentId}`, shipment, { headers: this.getHeaders() })
      .pipe(catchError(this.handleError));
  }

  /** Delete a shipment */
  deleteShipment(shipmentId: number): Observable<void> {
    return this.http
      .delete<void>(`${this.apiUrl}/delete/${shipmentId}`, { headers: this.getHeaders() })
      .pipe(catchError(this.handleError));
  }

  /** Error handling method */
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
