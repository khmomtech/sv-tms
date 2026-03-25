import { Injectable, inject } from '@angular/core';
import { HttpClient, HttpParams } from '@angular/common/http';
import { Observable } from 'rxjs';
import { environment } from '../../environments/environment';
import type {
  ApiResponse,
  SafetyCategory,
  SafetyMasterItem,
} from '../safety/models/safety-master.model';

@Injectable({ providedIn: 'root' })
export class PreEntryMasterDataService {
  private readonly http = inject(HttpClient);
  private readonly baseUrl = `${environment.apiBaseUrl}/admin/pre-entry-master`;

  getCategories(activeOnly = false): Observable<ApiResponse<SafetyCategory[]>> {
    const params = new HttpParams().set('activeOnly', String(activeOnly));
    return this.http.get<ApiResponse<SafetyCategory[]>>(`${this.baseUrl}/categories`, { params });
  }

  createCategory(payload: Partial<SafetyCategory>): Observable<ApiResponse<SafetyCategory>> {
    return this.http.post<ApiResponse<SafetyCategory>>(`${this.baseUrl}/categories`, payload);
  }

  updateCategory(
    id: number,
    payload: Partial<SafetyCategory>,
  ): Observable<ApiResponse<SafetyCategory>> {
    return this.http.put<ApiResponse<SafetyCategory>>(`${this.baseUrl}/categories/${id}`, payload);
  }

  setCategoryActive(id: number, isActive: boolean): Observable<ApiResponse<SafetyCategory>> {
    return this.updateCategory(id, { isActive });
  }

  getItems(
    filter: { categoryId?: number; activeOnly?: boolean; keyword?: string } = {},
  ): Observable<ApiResponse<SafetyMasterItem[]>> {
    let params = new HttpParams();
    if (filter.categoryId) params = params.set('categoryId', String(filter.categoryId));
    if (filter.activeOnly !== undefined)
      params = params.set('activeOnly', String(filter.activeOnly));
    if (filter.keyword) params = params.set('q', filter.keyword);
    return this.http.get<ApiResponse<SafetyMasterItem[]>>(`${this.baseUrl}/items`, { params });
  }

  createItem(payload: Partial<SafetyMasterItem>): Observable<ApiResponse<SafetyMasterItem>> {
    return this.http.post<ApiResponse<SafetyMasterItem>>(`${this.baseUrl}/items`, payload);
  }

  updateItem(
    id: number,
    payload: Partial<SafetyMasterItem>,
  ): Observable<ApiResponse<SafetyMasterItem>> {
    return this.http.put<ApiResponse<SafetyMasterItem>>(`${this.baseUrl}/items/${id}`, payload);
  }

  setItemActive(id: number, isActive: boolean): Observable<ApiResponse<SafetyMasterItem>> {
    return this.updateItem(id, { isActive });
  }
}
