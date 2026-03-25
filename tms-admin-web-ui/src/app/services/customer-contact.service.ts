import { Injectable } from '@angular/core';
import { HttpClient, HttpHeaders, HttpParams } from '@angular/common/http';
import { Observable } from 'rxjs';
import { environment } from '../../environments/environment';
import { AuthService } from './auth.service';
import { CustomerContact, CustomerContactRequest } from '../models/customer-contact.model';
import { ApiResponse } from '../models/api-response.model';

@Injectable({
  providedIn: 'root',
})
export class CustomerContactService {
  private readonly baseUrl = `${environment.apiUrl}/admin/customer-contacts`;

  constructor(
    private readonly http: HttpClient,
    private readonly authService: AuthService,
  ) {}

  private getAuthHeaders(): HttpHeaders {
    const token = this.authService.getToken();
    return new HttpHeaders({
      'Content-Type': 'application/json',
      Authorization: `Bearer ${token}`,
    });
  }

  /**
   * Get all contacts for a customer
   */
  getContactsByCustomerId(
    customerId: number,
    activeOnly = false,
  ): Observable<ApiResponse<CustomerContact[]>> {
    const params = new HttpParams().set('activeOnly', activeOnly.toString());
    return this.http.get<ApiResponse<CustomerContact[]>>(`${this.baseUrl}/customer/${customerId}`, {
      headers: this.getAuthHeaders(),
      params,
    });
  }

  /**
   * Get primary contact for a customer
   */
  getPrimaryContact(customerId: number): Observable<ApiResponse<CustomerContact>> {
    return this.http.get<ApiResponse<CustomerContact>>(
      `${this.baseUrl}/customer/${customerId}/primary`,
      { headers: this.getAuthHeaders() },
    );
  }

  /**
   * Get contact by ID
   */
  getContactById(id: number): Observable<ApiResponse<CustomerContact>> {
    return this.http.get<ApiResponse<CustomerContact>>(`${this.baseUrl}/${id}`, {
      headers: this.getAuthHeaders(),
    });
  }

  /**
   * Create new contact
   */
  createContact(request: CustomerContactRequest): Observable<ApiResponse<CustomerContact>> {
    return this.http.post<ApiResponse<CustomerContact>>(this.baseUrl, request, {
      headers: this.getAuthHeaders(),
    });
  }

  /**
   * Update existing contact
   */
  updateContact(
    id: number,
    request: CustomerContactRequest,
  ): Observable<ApiResponse<CustomerContact>> {
    return this.http.put<ApiResponse<CustomerContact>>(`${this.baseUrl}/${id}`, request, {
      headers: this.getAuthHeaders(),
    });
  }

  /**
   * Delete contact
   */
  deleteContact(id: number): Observable<ApiResponse<void>> {
    return this.http.delete<ApiResponse<void>>(`${this.baseUrl}/${id}`, {
      headers: this.getAuthHeaders(),
    });
  }

  /**
   * Search contacts by name or email
   */
  searchContacts(customerId: number, query: string): Observable<ApiResponse<CustomerContact[]>> {
    const params = new HttpParams().set('query', query);
    return this.http.get<ApiResponse<CustomerContact[]>>(
      `${this.baseUrl}/customer/${customerId}/search`,
      { headers: this.getAuthHeaders(), params },
    );
  }

  /**
   * Count contacts for a customer
   */
  countContacts(customerId: number): Observable<ApiResponse<number>> {
    return this.http.get<ApiResponse<number>>(`${this.baseUrl}/customer/${customerId}/count`, {
      headers: this.getAuthHeaders(),
    });
  }
}
