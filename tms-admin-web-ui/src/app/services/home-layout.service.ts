import { Injectable } from '@angular/core';
import { HttpClient, HttpHeaders } from '@angular/common/http';
import { Observable } from 'rxjs';
import { map } from 'rxjs/operators';
import { environment } from '../environments/environment';
import { HomeLayoutSection, HomeLayoutSectionRequest } from '../models/home-layout-section.model';

interface ApiResponse<T> {
  success: boolean;
  message: string;
  data: T;
}

@Injectable({
  providedIn: 'root',
})
export class HomeLayoutService {
  private apiUrl = `${environment.apiUrl}/admin/home-layout`;

  constructor(private http: HttpClient) {}

  private getHeaders(): HttpHeaders {
    let headers = new HttpHeaders({ 'Content-Type': 'application/json' });
    const token = localStorage.getItem('access_token');
    if (token) {
      headers = headers.set('Authorization', `Bearer ${token}`);
    }
    return headers;
  }

  /**
   * Get all layout sections
   */
  getAllSections(): Observable<HomeLayoutSection[]> {
    return this.http
      .get<ApiResponse<HomeLayoutSection[]>>(this.apiUrl, {
        headers: this.getHeaders(),
      })
      .pipe(map((response) => response.data));
  }

  /**
   * Get section by ID
   */
  getSectionById(id: number): Observable<HomeLayoutSection> {
    return this.http
      .get<ApiResponse<HomeLayoutSection>>(`${this.apiUrl}/${id}`, {
        headers: this.getHeaders(),
      })
      .pipe(map((response) => response.data));
  }

  /**
   * Get section by key
   */
  getSectionByKey(sectionKey: string): Observable<HomeLayoutSection> {
    return this.http
      .get<ApiResponse<HomeLayoutSection>>(`${this.apiUrl}/key/${sectionKey}`, {
        headers: this.getHeaders(),
      })
      .pipe(map((response) => response.data));
  }

  /**
   * Create new section
   */
  createSection(request: HomeLayoutSectionRequest): Observable<HomeLayoutSection> {
    return this.http
      .post<ApiResponse<HomeLayoutSection>>(this.apiUrl, request, {
        headers: this.getHeaders(),
      })
      .pipe(map((response) => response.data));
  }

  /**
   * Update existing section
   */
  updateSection(id: number, request: HomeLayoutSectionRequest): Observable<HomeLayoutSection> {
    return this.http
      .put<ApiResponse<HomeLayoutSection>>(`${this.apiUrl}/${id}`, request, {
        headers: this.getHeaders(),
      })
      .pipe(map((response) => response.data));
  }

  /**
   * Delete section
   */
  deleteSection(id: number): Observable<void> {
    return this.http
      .delete<ApiResponse<void>>(`${this.apiUrl}/${id}`, {
        headers: this.getHeaders(),
      })
      .pipe(map(() => undefined));
  }

  /**
   * Toggle section visibility
   */
  toggleVisibility(id: number): Observable<HomeLayoutSection> {
    return this.http
      .patch<
        ApiResponse<HomeLayoutSection>
      >(`${this.apiUrl}/${id}/toggle-visibility`, {}, { headers: this.getHeaders() })
      .pipe(map((response) => response.data));
  }

  /**
   * Reorder sections
   */
  reorderSections(orderedIds: number[]): Observable<HomeLayoutSection[]> {
    return this.http
      .patch<
        ApiResponse<HomeLayoutSection[]>
      >(`${this.apiUrl}/reorder`, { orderedIds }, { headers: this.getHeaders() })
      .pipe(map((response) => response.data));
  }

  /**
   * Initialize default sections
   */
  initializeDefaults(): Observable<string> {
    return this.http
      .post<
        ApiResponse<string>
      >(`${this.apiUrl}/initialize-defaults`, {}, { headers: this.getHeaders() })
      .pipe(map((response) => response.message));
  }
}
