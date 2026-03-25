import { Injectable } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { environment } from '../../environments/environment';

@Injectable({ providedIn: 'root' })
export class AuditService {
  private endpoint = environment.apiBaseUrl + '/audit/logs';
  constructor(private http: HttpClient) {}

  log(action: string, entity: string, entityId: any, changes?: any) {
    const payload = { action, entity, entityId, changes, timestamp: new Date().toISOString() };
    return this.http.post(this.endpoint, payload).toPromise().catch(()=>{ console.warn('Audit log failed, falling back to console'); console.log(payload); });
  }
}
