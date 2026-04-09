import { HttpClient, HttpHeaders, HttpParams } from '@angular/common/http';
import { Injectable } from '@angular/core';
import type { Observable } from 'rxjs';
import { throwError } from 'rxjs';
import { catchError, map } from 'rxjs/operators';

import { environment } from '../../environments/environment';
import type { ApiResponse } from '../models/api-response.model';
import type { Item } from '../models/item.model';
import { AuthService } from './auth.service';

export interface SuggestDto {
  id: number;
  label: string;
}

@Injectable({
  providedIn: 'root',
})
export class ItemService {
  private apiUrl = `${environment.apiBaseUrl}/items`;

  constructor(
    private http: HttpClient,
    private authService: AuthService,
  ) {}

  /** 🔐 Auth headers */
  private getHeaders(): HttpHeaders {
    const token = this.authService.getToken();
    return new HttpHeaders({
      Authorization: `Bearer ${token}`,
      'Content-Type': 'application/json',
    });
  }

  private getHttpOptions(params?: HttpParams) {
    return {
      headers: this.getHeaders(),
      ...(params ? { params } : {}),
    };
  }

  autocomplete(q: string, limit = 10): Observable<SuggestDto[]> {
    const params = new HttpParams().set('q', q).set('limit', `${limit}`);
    return this.http
      .get<ApiResponse<SuggestDto[]>>(`${this.apiUrl}/search`, this.getHttpOptions(params))
      .pipe(
        map((res) => res.data ?? []),
        catchError(this.handleError),
      );
  }

  /** 🔍 Search items */
  searchItems(keyword: string): Observable<Item[]> {
    const params = new HttpParams().set('keyword', keyword);
    return this.http
      .get<Item[]>(`${this.apiUrl}/search`, this.getHttpOptions(params))
      .pipe(catchError(this.handleError));
  }

  /** 📥 Get all items */
  getAllItems(): Observable<Item[]> {
    return this.http
      .get<Item[]>(this.apiUrl, this.getHttpOptions())
      .pipe(catchError(this.handleError));
  }

  /** 🔎 Get item by ID */
  getItemById(id: number): Observable<Item> {
    return this.http
      .get<Item>(`${this.apiUrl}/${id}`, this.getHttpOptions())
      .pipe(catchError(this.handleError));
  }

  /** 🆕 Create item */
  createItem(item: Item): Observable<Item> {
    return this.http.post<ApiResponse<Item>>(this.apiUrl, item, this.getHttpOptions()).pipe(
      map((res) => res.data as Item),
      catchError(this.handleError),
    );
  }

  /**  Update item */
  updateItem(id: number, item: Item): Observable<Item> {
    return this.http
      .put<ApiResponse<Item>>(`${this.apiUrl}/${id}`, item, this.getHttpOptions())
      .pipe(
        map((res) => res.data as Item),
        catchError(this.handleError),
      );
  }

  /**  Delete item */
  deleteItem(id: number): Observable<void> {
    return this.http
      .delete<void>(`${this.apiUrl}/${id}`, this.getHttpOptions())
      .pipe(catchError(this.handleError));
  }

  /** ❗ Handle errors */
  private handleError(error: any): Observable<never> {
    console.error('[ItemService] Error:', error);
    const message = error?.error?.message || 'Unexpected error occurred.';
    return throwError(() => new Error(message));
  }

  /**  Bulk import items */
  bulkImport(items: Item[]): Observable<Item[]> {
    return this.http
      .post<ApiResponse<Item[]>>(`${this.apiUrl}/bulk-import`, items, this.getHttpOptions())
      .pipe(
        map((res) => res.data as Item[]),
        catchError(this.handleError),
      );
  }
}
