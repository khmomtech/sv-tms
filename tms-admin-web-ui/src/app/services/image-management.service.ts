import { HttpClient, HttpHeaders } from '@angular/common/http';
import { Injectable } from '@angular/core';
import type { Observable } from 'rxjs';
import { map } from 'rxjs/operators';

import { environment } from '../environments/environment';
import { AuthService } from './auth.service';

export interface ImageInfo {
  id: string;
  filename: string;
  originalFilename: string;
  category: string;
  description?: string;
  size: number;
  uploadDate: string;
  url: string;
}

export interface ImageUploadRequest {
  file: File;
  category: string;
  description?: string;
}

export type ApiResponse<T> = {
  success: boolean;
  message?: string;
  data: T;
};

@Injectable({ providedIn: 'root' })
export class ImageManagementService {
  private apiUrl = `${environment.apiBaseUrl}/admin/images`;

  constructor(
    private http: HttpClient,
    private authService: AuthService,
  ) {}

  private authHeaders(): HttpHeaders {
    const token = this.authService.getToken();
    const headers: Record<string, string> = { Accept: 'application/json' };
    if (token) headers['Authorization'] = `Bearer ${token}`;
    return new HttpHeaders(headers);
  }

  /** Get all managed images */
  getAllImages(): Observable<ImageInfo[]> {
    return this.http
      .get<ApiResponse<ImageInfo[]>>(this.apiUrl, { headers: this.authHeaders() })
      .pipe(map((resp) => resp.data ?? []));
  }

  /** Get images by category */
  getImagesByCategory(category: string): Observable<ImageInfo[]> {
    return this.http
      .get<
        ApiResponse<ImageInfo[]>
      >(`${this.apiUrl}/category/${category}`, { headers: this.authHeaders() })
      .pipe(map((resp) => resp.data ?? []));
  }

  /** Upload a new image */
  uploadImage(request: ImageUploadRequest): Observable<ImageInfo> {
    const formData = new FormData();
    formData.append('file', request.file);
    formData.append('category', request.category);
    if (request.description) {
      formData.append('description', request.description);
    }
    return this.http
      .post<
        ApiResponse<ImageInfo>
      >(`${this.apiUrl}/upload`, formData, { headers: this.authHeaders() })
      .pipe(map((resp) => resp.data));
  }

  /** Delete an image */
  deleteImage(imageId: string): Observable<void> {
    return this.http
      .delete<ApiResponse<string>>(`${this.apiUrl}/${imageId}`, { headers: this.authHeaders() })
      .pipe(map(() => void 0));
  }

  /** Update image metadata */
  updateImageMetadata(imageId: string, metadata: Partial<ImageInfo>): Observable<ImageInfo> {
    return this.http
      .put<
        ApiResponse<ImageInfo>
      >(`${this.apiUrl}/${imageId}`, metadata, { headers: this.authHeaders() })
      .pipe(map((resp) => resp.data));
  }

  /** Build full image URL from info */
  getImageUrl(image: ImageInfo): string {
    return `${environment.apiBaseUrl}${image.url}`;
  }

  /** Validate image file before upload */
  validateImageFile(file: File): { valid: boolean; error?: string } {
    const allowedTypes = [
      'image/jpeg',
      'image/jpg',
      'image/png',
      'image/gif',
      'image/webp',
      'image/svg+xml',
    ];
    const maxSize = 5 * 1024 * 1024; // 5MB

    if (!allowedTypes.includes(file.type)) {
      return {
        valid: false,
        error: 'Invalid file type. Please upload a JPEG, PNG, GIF, WebP, or SVG image.',
      };
    }

    if (file.size > maxSize) {
      return { valid: false, error: 'File size exceeds 5MB limit.' };
    }

    return { valid: true };
  }
}
