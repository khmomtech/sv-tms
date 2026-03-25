import { HttpClient, HttpParams } from '@angular/common/http';
import { inject, Injectable } from '@angular/core';
import type { Observable } from 'rxjs';
import { of } from 'rxjs';
import { map } from 'rxjs/operators';

import { environment } from '../environments/environment';
import type { ApiResponse } from '../models/api-response.model';
import type {
  CustomerAccountRequest,
  PartnerAdmin,
  PartnerAdminPermissions,
  PartnerCompany,
  PartnershipType,
} from '../models/partner.model';

@Injectable({ providedIn: 'root' })
export class PartnerService {
  private readonly apiUrl = `${environment.apiBaseUrl}/${environment.useVendorApiPaths ? 'vendors' : 'partners'}`;
  private readonly adminUrl = `${environment.apiBaseUrl}/partner-admins`;
  private readonly customerUrl = `${environment.apiBaseUrl}/admin/customers`;

  private readonly http = inject(HttpClient);

  // ===== PARTNER COMPANY METHODS =====

  /**
   * Get all partner companies
   */
  getAllPartners(): Observable<PartnerCompany[]> {
    return this.http
      .get<ApiResponse<PartnerCompany[]>>(this.apiUrl)
      .pipe(map((response) => response.data || []));
  }

  /**
   * Get active partners only
   */
  getActivePartners(): Observable<PartnerCompany[]> {
    return this.http
      .get<ApiResponse<PartnerCompany[]>>(`${this.apiUrl}/active`)
      .pipe(map((response) => response.data || []));
  }

  /**
   * Get partners by type
   */
  getPartnersByType(type: PartnershipType): Observable<PartnerCompany[]> {
    return this.http
      .get<ApiResponse<PartnerCompany[]>>(`${this.apiUrl}/type/${type}`)
      .pipe(map((response) => response.data || []));
  }

  /**
   * Get partner by ID
   */
  getPartnerById(id: number): Observable<PartnerCompany> {
    return this.http
      .get<ApiResponse<PartnerCompany>>(`${this.apiUrl}/${id}`)
      .pipe(map((response) => response.data));
  }

  /**
   * Create new partner company
   */
  createPartner(partner: PartnerCompany): Observable<PartnerCompany> {
    return this.http
      .post<ApiResponse<PartnerCompany>>(this.apiUrl, partner)
      .pipe(map((response) => response.data));
  }

  /**
   * Update existing partner
   */
  updatePartner(id: number, partner: PartnerCompany): Observable<PartnerCompany> {
    return this.http
      .put<ApiResponse<PartnerCompany>>(`${this.apiUrl}/${id}`, partner)
      .pipe(map((response) => response.data));
  }

  /**
   * Delete partner (SUPERADMIN only)
   */
  deletePartner(id: number): Observable<void> {
    return this.http.delete<ApiResponse<void>>(`${this.apiUrl}/${id}`).pipe(map(() => undefined));
  }

  /**
   * Deactivate partner
   */
  deactivatePartner(id: number): Observable<PartnerCompany> {
    return this.http
      .patch<ApiResponse<PartnerCompany>>(`${this.apiUrl}/${id}/deactivate`, {})
      .pipe(map((response) => response.data));
  }

  /**
   * Search partners
   */
  searchPartners(query: string): Observable<PartnerCompany[]> {
    const params = new HttpParams().set('query', query);
    return this.http
      .get<ApiResponse<PartnerCompany[]>>(`${this.apiUrl}/search`, { params })
      .pipe(map((response) => response.data || []));
  }

  /**
   * Server-side paged partners (when backend supports it)
   * Endpoint example: GET /partners/paged?page=0&size=10&query=...&status=ACTIVE&type=DRIVER_FLEET
   */
  getPartnersPaged(
    page: number,
    size: number,
    opts?: {
      query?: string;
      status?: 'ALL' | PartnershipType | any;
      type?: 'ALL' | PartnershipType;
    },
  ): Observable<{ content: PartnerCompany[]; totalElements: number; totalPages: number }> {
    let params = new HttpParams().set('page', page).set('size', size);
    if (opts?.query) params = params.set('query', opts.query);
    if (opts?.status && opts.status !== 'ALL') params = params.set('status', String(opts.status));
    if (opts?.type && opts.type !== 'ALL') params = params.set('type', String(opts.type));

    return this.http.get<ApiResponse<any>>(`${this.apiUrl}/paged`, { params }).pipe(
      map((response) => {
        const d = response.data || {};
        return {
          content: (d.content as PartnerCompany[]) || [],
          totalElements: Number(d.totalElements || 0),
          totalPages: Number(d.totalPages || 1),
        };
      }),
    );
  }

  /**
   * Generate next company code
   */
  generateCompanyCode(): Observable<string> {
    return this.http
      .get<ApiResponse<string>>(`${this.apiUrl}/generate-code`)
      .pipe(map((response) => response.data));
  }

  /**
   * Check if business license already exists (case-insensitive)
   */
  checkBusinessLicenseExists(license: string): Observable<boolean> {
    if (!license) return of(false);
    return this.http
      .get<ApiResponse<boolean>>(`${this.apiUrl}/license/${encodeURIComponent(license)}/exists`)
      .pipe(map((res) => !!res.data));
  }

  // ===== PARTNER ADMIN METHODS =====

  /**
   * Get all admins for a company
   */
  getCompanyAdmins(companyId: number): Observable<PartnerAdmin[]> {
    return this.http
      .get<ApiResponse<PartnerAdmin[]>>(`${this.adminUrl}/company/${companyId}`)
      .pipe(map((response) => response.data || []));
  }

  /**
   * Get all companies a user manages
   */
  getUserCompanies(userId: number): Observable<PartnerAdmin[]> {
    return this.http
      .get<ApiResponse<PartnerAdmin[]>>(`${this.adminUrl}/user/${userId}`)
      .pipe(map((response) => response.data || []));
  }

  /**
   * Assign admin to company
   */
  assignAdminToCompany(admin: Partial<PartnerAdmin>): Observable<PartnerAdmin> {
    return this.http
      .post<ApiResponse<PartnerAdmin>>(this.adminUrl, admin)
      .pipe(map((response) => response.data));
  }

  /**
   * Update admin permissions
   */
  updateAdminPermissions(
    adminId: number,
    permissions: PartnerAdminPermissions,
  ): Observable<PartnerAdmin> {
    return this.http
      .patch<ApiResponse<PartnerAdmin>>(`${this.adminUrl}/${adminId}/permissions`, permissions)
      .pipe(map((response) => response.data));
  }

  /**
   * Remove admin assignment
   */
  removeAdmin(adminId: number): Observable<void> {
    return this.http
      .delete<ApiResponse<void>>(`${this.adminUrl}/${adminId}`)
      .pipe(map(() => undefined));
  }

  /**
   * Get managed company IDs for a user
   */
  getManagedCompanyIds(userId: number): Observable<number[]> {
    return this.http
      .get<ApiResponse<number[]>>(`${this.adminUrl}/user/${userId}/managed-companies`)
      .pipe(map((response) => response.data || []));
  }

  // ===== CUSTOMER ACCOUNT METHODS =====

  /**
   * Create customer portal account
   */
  createCustomerAccount(customerId: number, accountData: CustomerAccountRequest): Observable<any> {
    return this.http
      .post<ApiResponse<any>>(`${this.customerUrl}/${customerId}/account`, accountData)
      .pipe(map((response) => response.data));
  }
}
