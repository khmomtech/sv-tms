import { Injectable } from '@angular/core';
import { HttpClient, HttpEvent, HttpEventType, HttpRequest } from '@angular/common/http';
import { environment } from '../../environments/environment';
import { Observable } from 'rxjs';
import { map } from 'rxjs/operators';

export interface UploadProgress {
  progress: number; // 0-100
  url?: string; // set when upload completes
}

@Injectable({ providedIn: 'root' })
export class FileService {
  constructor(private http: HttpClient) {}

  upload(file: File): Observable<UploadProgress> {
    const fd = new FormData();
    fd.append('file', file);
    const req = new HttpRequest('POST', `${environment.apiBaseUrl}/files/upload`, fd, { reportProgress: true });
    return this.http.request(req).pipe(
      map((event: HttpEvent<any>) => {
        if (event.type === HttpEventType.UploadProgress) {
          const percent = event.total ? Math.round((100 * event.loaded) / event.total) : 0;
          return { progress: percent } as UploadProgress;
        }
        if (event.type === HttpEventType.Response) {
          return { progress: 100, url: event.body && event.body.url } as UploadProgress;
        }
        return { progress: 0 } as UploadProgress;
      })
    );
  }
}
