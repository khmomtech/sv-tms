// eslint-disable-next-line @typescript-eslint/consistent-type-imports
import { HttpClient } from '@angular/common/http';
import { Injectable } from '@angular/core';
import type { Observable } from 'rxjs';

import { environment } from '../environments/environment';

export interface UserDto {
  id: number;
  username: string;
  email: string;
  roles: string[];
}

export interface RegisterRequest {
  username: string;
  password: string;
  email: string;
  roles: string[];
}

@Injectable({
  providedIn: 'root',
})
export class UserService {
  private apiUrl = `${environment.baseUrl}/api/admin/users`;

  constructor(private http: HttpClient) {}

  getAllUsers(): Observable<UserDto[]> {
    return this.http.get<UserDto[]>(this.apiUrl);
  }

  createUser(userRequest: RegisterRequest): Observable<any> {
    return this.http.post(this.apiUrl, userRequest);
  }

  updateUser(id: number, userRequest: RegisterRequest): Observable<any> {
    return this.http.put(`${this.apiUrl}/${id}`, userRequest);
  }

  deleteUser(id: number): Observable<any> {
    return this.http.delete(`${this.apiUrl}/${id}`);
  }

  registerDriverAccount(driverId: number, request: RegisterRequest): Observable<any> {
    return this.http.post(`${this.apiUrl}/registerdriver`, { driverId, ...request });
  }

  getDriverAccount(driverId: number): Observable<UserDto> {
    return this.http.get<UserDto>(`${this.apiUrl}/driver-account/${driverId}`);
  }

  deleteDriverAccount(driverId: number): Observable<any> {
    return this.http.delete(`${this.apiUrl}/driver-account/${driverId}`);
  }
}
