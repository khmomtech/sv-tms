import { Injectable } from '@angular/core';
import { HttpClient, HttpParams } from '@angular/common/http';
import { Observable } from 'rxjs';
import { environment } from '@env/environment';
import { Booking, CreateBookingDto, UpdateBookingDto, BookingFilter } from '@models/booking.model';

export interface BookingListResponse {
  success: boolean;
  message: string;
  data: {
    content: Booking[];
    totalElements: number;
    totalPages: number;
    size: number;
    number: number;
  };
}

export interface BookingResponse {
  success: boolean;
  message: string;
  data: Booking;
}

@Injectable({
  providedIn: 'root',
})
export class BookingService {
  // Use apiBaseUrl (already includes '/api') and avoid duplicate '/api'
  private readonly apiUrl = `${environment.apiBaseUrl}/admin/bookings`;

  constructor(private http: HttpClient) {}

  /**
   * Get all bookings with pagination and filters
   */
  getBookings(
    page: number = 0,
    size: number = 10,
    filter?: BookingFilter,
  ): Observable<BookingListResponse> {
    let params = new HttpParams().set('page', page.toString()).set('size', size.toString());

    if (filter?.searchQuery) {
      params = params.set('query', filter.searchQuery);
    }
    if (filter?.status) {
      params = params.set('status', filter.status);
    }
    if (filter?.serviceType) {
      params = params.set('serviceType', filter.serviceType);
    }
    if (filter?.fromDate) {
      params = params.set('fromDate', this.formatDate(filter.fromDate));
    }
    if (filter?.toDate) {
      params = params.set('toDate', this.formatDate(filter.toDate));
    }
    if (filter?.customerId) {
      params = params.set('customerId', filter.customerId.toString());
    }

    return this.http.get<BookingListResponse>(this.apiUrl, { params });
  }

  /**
   * Get booking by ID
   */
  getBookingById(id: number): Observable<BookingResponse> {
    return this.http.get<BookingResponse>(`${this.apiUrl}/${id}`);
  }

  /**
   * Create new booking
   */
  createBooking(booking: CreateBookingDto): Observable<BookingResponse> {
    return this.http.post<BookingResponse>(this.apiUrl, booking);
  }

  /**
   * Update existing booking
   */
  updateBooking(id: number, booking: UpdateBookingDto): Observable<BookingResponse> {
    return this.http.put<BookingResponse>(`${this.apiUrl}/${id}`, booking);
  }

  /**
   * Delete booking
   */
  deleteBooking(id: number): Observable<{ success: boolean; message: string }> {
    return this.http.delete<{ success: boolean; message: string }>(`${this.apiUrl}/${id}`);
  }

  /**
   * Confirm booking (change status to CONFIRMED)
   */
  confirmBooking(id: number): Observable<BookingResponse> {
    return this.http.post<BookingResponse>(`${this.apiUrl}/${id}/confirm`, {});
  }

  /**
   * Cancel booking
   */
  cancelBooking(id: number, reason?: string): Observable<BookingResponse> {
    return this.http.post<BookingResponse>(`${this.apiUrl}/${id}/cancel`, { reason });
  }

  /**
   * Convert booking to transport order
   */
  convertToOrder(id: number): Observable<{ success: boolean; message: string; orderId: number }> {
    return this.http.post<{ success: boolean; message: string; orderId: number }>(
      `${this.apiUrl}/${id}/convert-to-order`,
      {},
    );
  }

  /**
   * Helper to format date for API
   */
  private formatDate(date: Date | string): string {
    if (typeof date === 'string') {
      return date;
    }
    return date.toISOString().split('T')[0];
  }
}
