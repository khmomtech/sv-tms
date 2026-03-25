// eslint-disable-next-line @typescript-eslint/consistent-type-imports
import { HttpClient } from '@angular/common/http';
import { HttpHeaders, HttpParams } from '@angular/common/http';
import { Injectable } from '@angular/core';
import type { Observable } from 'rxjs';
import { throwError, of } from 'rxjs';
import { catchError, finalize, map } from 'rxjs/operators';

import { environment } from '../environments/environment';
import type { PageResult } from '../models/api-page-result.model';
import type { ApiResponse } from '../models/api-response.model';
import type { Customer } from '../models/customer.model';
import type { OrderAddress } from '../models/order-address.model';
// eslint-disable-next-line @typescript-eslint/consistent-type-imports
import { AuthService } from '../services/auth.service';

export interface CustomerFilters {
  name?: string;
  phone?: string;
  email?: string;
  customerCode?: string;
  types?: string[];
  status?: string;
}

export interface CustomerImportPayload {
  importedCustomers: Customer[];
  successCount: number;
  failureCount: number;
  failureMessages?: string[];
}

@Injectable({
  providedIn: 'root',
})
export class CustomerService {
  private readonly baseUrl = `${environment.apiUrl}/admin`;
  private readonly apiUrl = `${this.baseUrl}/customers`;
  private readonly addressUrl = `${this.baseUrl}/order-address`;
  private readonly importUrl = `${this.apiUrl}/import`;

  loading = false;

  constructor(
    private readonly http: HttpClient,
    private readonly authService: AuthService,
  ) {}

  /** ----------------------------
   * 🔐 Auth Headers
   * ---------------------------- */
  private getAuthHeaders(): HttpHeaders {
    const token = this.authService.getToken();
    return new HttpHeaders({
      Authorization: token ? `Bearer ${token}` : '',
    });
  }

  private getHttpOptions(params?: HttpParams) {
    return {
      headers: this.getAuthHeaders(),
      ...(params ? { params } : {}),
    };
  }

  /** ----------------------------
   * 🧩 Customer CRUD
   * ---------------------------- */

  getAllCustomers(page = 0, size = 10): Observable<PageResult<Customer>> {
    const params = new HttpParams().set('page', String(page)).set('size', String(size));
    return this.http
      .get<ApiResponse<PageResult<Customer>>>(this.apiUrl, this.getHttpOptions(params))
      .pipe(
        map((res) => res.data),
        catchError(this.handleError),
      );
  }

  getCustomerById(
    id: number,
  ): Observable<ApiResponse<{ customer: Customer; addresses: OrderAddress[] }>> {
    return this.http
      .get<
        ApiResponse<{ customer: Customer; addresses: OrderAddress[] }>
      >(`${this.apiUrl}/${id}`, this.getHttpOptions())
      .pipe(catchError(this.handleError));
  }

  createCustomer(customer: Customer): Observable<Customer> {
    // Use 'name' field directly (backend expects 'name')
    return this.http
      .post<Customer>(this.apiUrl, customer, this.getHttpOptions())
      .pipe(catchError(this.handleError));
  }

  updateCustomer(id: number, customer: Customer): Observable<Customer> {
    // Use 'name' field directly (backend expects 'name')
    return this.http
      .put<Customer>(`${this.apiUrl}/${id}`, customer, this.getHttpOptions())
      .pipe(catchError(this.handleError));
  }

  deleteCustomer(id: number): Observable<void> {
    return this.http
      .delete<void>(`${this.apiUrl}/${id}`, this.getHttpOptions())
      .pipe(catchError(this.handleError));
  }

  /** ----------------------------
   *  Customer Filter & Search
   * ---------------------------- */

  // searchCustomers(keyword: string): Observable<Customer[]> {
  //   this.loading = true;
  //   const params = new HttpParams().set('keyword', keyword);
  //   return this.http.get<Customer[]>(`${this.apiUrl}/search`, this.getHttpOptions(params))
  //     .pipe(
  //       catchError(this.handleError),
  //       finalize(() => (this.loading = false))
  //     );
  // }

  searchCustomers(keyword: string): Observable<Customer[]> {
    this.loading = true;
    const params = new HttpParams().set('keyword', keyword);

    return this.http
      .get<ApiResponse<Customer[]>>(`${this.apiUrl}/search`, this.getHttpOptions(params))
      .pipe(
        map((res) => res.data), // extract customers array
        catchError(this.handleError),
        finalize(() => (this.loading = false)),
      );
  }

  /**
   * Generate next sequential customer code from backend
   * Format: CUSTXXXX (CUST0001, CUST0002, etc.)
   * @returns Observable of generated customer code
   */
  generateNextCustomerCode(): Observable<string> {
    const url = `${this.apiUrl}/generate-code`;
    console.log('[CustomerService] Calling API:', url);
    return this.http.get<ApiResponse<string>>(url, this.getHttpOptions()).pipe(
      map((res) => {
        console.log('[CustomerService] ✅ Backend response:', res);
        return res.data;
      }),
      catchError((error) => {
        console.error('[CustomerService] ❌ API error:', error);
        // Fallback to local generation if endpoint fails
        const fallback = this.generateLocalFallbackCode();
        console.log('[CustomerService] Using fallback:', fallback);
        return of(fallback);
      }),
    );
  }

  /**
   * Fallback local generation if backend endpoint fails
   * Format: CUSTXXXX using timestamp
   */
  private generateLocalFallbackCode(): string {
    const timestamp = Date.now().toString().slice(-4);
    return `CUST${timestamp}`;
  }

  searchCustomersByFilters(
    filters: CustomerFilters,
    page = 0,
    size = 10,
  ): Observable<PageResult<Customer>> {
    let params = new HttpParams().set('page', String(page)).set('size', String(size));

    if (filters.customerCode?.trim()) {
      params = params.set('customerCode', filters.customerCode.trim());
    }
    if (filters.name?.trim()) {
      params = params.set('name', filters.name.trim());
    }
    if (filters.phone?.trim()) {
      params = params.set('phone', filters.phone.trim());
    }
    if (filters.email?.trim()) {
      params = params.set('email', filters.email.trim());
    }
    if ((filters.types ?? []).length > 0) {
      params = params.set('types', filters.types!.join(','));
    }
    if (filters.status && filters.status.trim() !== '') {
      params = params.set('status', filters.status.trim());
    }

    return this.http
      .get<ApiResponse<PageResult<Customer>>>(`${this.apiUrl}/filter`, this.getHttpOptions(params))
      .pipe(
        map((res) => res.data),
        catchError(this.handleError),
        finalize(() => (this.loading = false)),
      );
  }

  /** ----------------------------
   * 📥 Import Customers
   * ---------------------------- */
  importCustomers(file: File): Observable<ApiResponse<CustomerImportPayload>> {
    const formData = new FormData();
    formData.append('file', file);
    return this.http
      .post<ApiResponse<CustomerImportPayload>>(this.importUrl, formData, {
        headers: this.getAuthHeaders(),
      })
      .pipe(catchError(this.handleError));
  }

  /** ----------------------------
   * 🏠 Address Management
   * ---------------------------- */
  createAddress(data: Partial<OrderAddress>): Observable<any> {
    return this.http
      .post<any>(this.addressUrl, data, this.getHttpOptions())
      .pipe(catchError(this.handleError));
  }

  updateAddress(id: number, data: Partial<OrderAddress>): Observable<any> {
    return this.http
      .put<any>(`${this.addressUrl}/${id}`, data, this.getHttpOptions())
      .pipe(catchError(this.handleError));
  }

  deleteAddress(id: number): Observable<any> {
    return this.http
      .delete<any>(`${this.addressUrl}/${id}`, this.getHttpOptions())
      .pipe(catchError(this.handleError));
  }

  /** ----------------------------
   * ✅ Validation Methods
   * ---------------------------- */

  /**
   * Validate customer data before submission
   * @returns array of validation error messages, empty if valid
   */
  validateCustomer(customer: Customer): string[] {
    const errors: string[] = [];

    // Required fields validation
    if (!customer.name || customer.name.trim() === '') {
      errors.push('Customer Name: This field is required');
    }

    if (!customer.email || customer.email.trim() === '') {
      errors.push('Email: This field is required');
    } else if (!this.isValidEmail(customer.email)) {
      errors.push('Email: Please enter a valid email address');
    }

    if (!customer.phone || customer.phone.trim() === '') {
      errors.push('Phone: This field is required');
    }

    if (!customer.customerCode || customer.customerCode.trim() === '') {
      errors.push('Customer Code: This field is required');
    }

    if (!customer.type) {
      errors.push('Type: Please select a customer type');
    }

    return errors;
  }

  /**
   * Email validation using standard regex
   */
  private isValidEmail(email: string): boolean {
    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
    return emailRegex.test(email);
  }

  /**
   * Phone validation (accepts any format - no strict validation)
   */
  private isValidPhone(phone: string): boolean {
    // Accept any phone number - just check it has some content
    return !!phone && typeof phone === 'string' && phone.trim().length > 0;
  }

  /**
   * Check if email is already used by another customer
   * @param email Email to check
   * @param currentCustomerId ID of customer being edited (exclude from check if provided)
   * @returns Observable<boolean> - true if email is available, false if taken
   */
  isEmailAvailable(email: string, currentCustomerId?: number): Observable<boolean> {
    if (!email || !this.isValidEmail(email)) {
      return of(false);
    }

    return this.searchCustomers(email).pipe(
      map((customers) => {
        // If checking for update, exclude the current customer
        if (currentCustomerId) {
          const duplicates = customers.filter(
            (c) => c.email?.toLowerCase() === email.toLowerCase() && c.id !== currentCustomerId,
          );
          return duplicates.length === 0;
        }
        // For create, check if any customer has this email
        const duplicates = customers.filter((c) => c.email?.toLowerCase() === email.toLowerCase());
        return duplicates.length === 0;
      }),
      catchError(() => of(false)), // Assume unavailable on error
    );
  }

  /**
   * Check if phone is already used by another customer
   * @param phone Phone to check
   * @param currentCustomerId ID of customer being edited (exclude from check if provided)
   * @returns Observable<boolean> - true if phone is available, false if taken
   */
  isPhoneAvailable(phone: string, currentCustomerId?: number): Observable<boolean> {
    if (!phone || !this.isValidPhone(phone)) {
      return of(false);
    }

    return this.searchCustomers(phone).pipe(
      map((customers) => {
        // Normalize phone numbers for comparison (remove country code, spaces, dashes, etc.)
        const normalizedPhone = phone.replace(/[\s\-\(\)\.\+]/g, '');

        if (currentCustomerId) {
          const duplicates = customers.filter((c) => {
            const customerPhone = (c.phone || '').replace(/[\s\-\(\)\.\+]/g, '');
            return customerPhone === normalizedPhone && c.id !== currentCustomerId;
          });
          return duplicates.length === 0;
        }

        const duplicates = customers.filter((c) => {
          const customerPhone = (c.phone || '').replace(/[\s\-\(\)\.\+]/g, '');
          return customerPhone === normalizedPhone;
        });
        return duplicates.length === 0;
      }),
      catchError(() => of(false)), // Assume unavailable on error
    );
  }

  /**
   * Check if customer code is already used by another customer
   * @param code Code to check
   * @param currentCustomerId ID of customer being edited (exclude from check if provided)
   * @returns Observable<boolean> - true if code is available, false if taken
   */
  isCustomerCodeAvailable(code: string, currentCustomerId?: number): Observable<boolean> {
    if (!code || code.trim() === '') {
      return of(false);
    }

    return this.searchCustomers(code).pipe(
      map((customers) => {
        if (currentCustomerId) {
          const duplicates = customers.filter(
            (c) =>
              c.customerCode?.toUpperCase() === code.toUpperCase() && c.id !== currentCustomerId,
          );
          return duplicates.length === 0;
        }

        const duplicates = customers.filter(
          (c) => c.customerCode?.toUpperCase() === code.toUpperCase(),
        );
        return duplicates.length === 0;
      }),
      catchError(() => of(false)), // Assume unavailable on error
    );
  }

  /** ----------------------------
   * ❗ Global Error Handler
   * ---------------------------- */
  private handleError(error: any): Observable<never> {
    console.error('[CustomerService] Error:', error);
    return throwError(() => error);
  }
}
