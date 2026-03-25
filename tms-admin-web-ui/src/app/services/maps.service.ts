// eslint-disable-next-line @typescript-eslint/consistent-type-imports
import { HttpClient } from '@angular/common/http';
import { Injectable } from '@angular/core';

import { environment } from '../environments/environment';

@Injectable({ providedIn: 'root' })
export class MapsService {
  private readonly apiUrl = `${environment.baseUrl}/api/admin/reports`;

  constructor(private http: HttpClient) {}

  getDistance(origin: string, destination: string) {
    return this.http.get<any>(`${this.apiUrl}/api/distance'`, {
      params: { origins: origin, destinations: destination },
    });
  }
}
