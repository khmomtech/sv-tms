import { Injectable } from '@angular/core';
import { HttpClient, HttpHeaders } from '@angular/common/http';
import { Observable } from 'rxjs';
import { environment } from '../environments/environment';
import { AuthService } from './auth.service';

export interface Banner {
  id?: number;
  title: string;
  titleKh?: string;
  subtitle?: string;
  subtitleKh?: string;
  imageUrl: string;
  category: string;
  targetUrl?: string;
  displayOrder: number;
  startDate: string;
  endDate: string;
  active: boolean;
  clickCount?: number;
  viewCount?: number;
  createdBy?: string;
  createdAt?: string;
  updatedAt?: string;
}

export interface ApiResponse<T> {
  success: boolean;
  message: string;
  data: T;
}

@Injectable({
  providedIn: 'root',
})
export class BannerService {
  private apiUrl = `${environment.baseUrl}/api/admin/banners`;

  constructor(
    private http: HttpClient,
    private authService: AuthService,
  ) {}

  private getHeaders(): HttpHeaders {
    return new HttpHeaders({
      'Content-Type': 'application/json',
      Authorization: `Bearer ${this.authService.getToken()}`,
    });
  }

  getAllBanners(): Observable<ApiResponse<Banner[]>> {
    return this.http.get<ApiResponse<Banner[]>>(this.apiUrl, { headers: this.getHeaders() });
  }

  getBannerById(id: number): Observable<ApiResponse<Banner>> {
    return this.http.get<ApiResponse<Banner>>(`${this.apiUrl}/${id}`, {
      headers: this.getHeaders(),
    });
  }

  createBanner(banner: Banner): Observable<ApiResponse<Banner>> {
    return this.http.post<ApiResponse<Banner>>(this.apiUrl, banner, { headers: this.getHeaders() });
  }

  updateBanner(id: number, banner: Banner): Observable<ApiResponse<Banner>> {
    return this.http.put<ApiResponse<Banner>>(`${this.apiUrl}/${id}`, banner, {
      headers: this.getHeaders(),
    });
  }

  deleteBanner(id: number): Observable<ApiResponse<string>> {
    return this.http.delete<ApiResponse<string>>(`${this.apiUrl}/${id}`, {
      headers: this.getHeaders(),
    });
  }
}
