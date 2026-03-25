import { Injectable } from '@angular/core';
import { ApiService } from './api.service';

@Injectable({ providedIn: 'root' })
export class SafetyService {
  constructor(private api: ApiService) {}

  getCategories() { return this.api.get('/safety/categories'); }
  createCategory(payload: any) { return this.api.post('/safety/categories', payload); }

  getItems(params?: any) { return this.api.get('/safety/items', params); }
  createItem(payload: any) { return this.api.post('/safety/items', payload); }

  getChecks(params?: any) { return this.api.get('/safety/checks', params); }
  getCheck(checkId: any) { return this.api.get(`/safety/checks/${checkId}`); }
  createCheck(payload: any) { return this.api.post('/safety/checks', payload); }

  getIssues(params?: any) { return this.api.get('/safety/issues', params); }
  getIssue(issueId: any) { return this.api.get(`/safety/issues/${issueId}`); }
  updateIssue(issueId: any, payload: any) { return this.api.put(`/safety/issues/${issueId}`, payload); }

  // vehicle status
  getVehicleStatus(params?: any) { return this.api.get('/safety/vehicles/status', params); }
  blockVehicle(vehicleId: any) { return this.api.put(`/safety/vehicles/${vehicleId}/block`, {}); }
  unblockVehicle(vehicleId: any) { return this.api.put(`/safety/vehicles/${vehicleId}/unblock`, {}); }

  // overrides
  getOverrides(params?: any) { return this.api.get('/safety/overrides', params); }
  createOverride(payload: any) { return this.api.post('/safety/overrides', payload); }
  revokeOverride(overrideId: any) { return this.api.put(`/safety/overrides/${overrideId}/revoke`, {}); }

  // maintenance linking
  createMaintenanceFromIssue(issueId: any, payload: any) { return this.api.post('/maintenance/requests', { issueId, ...payload }); }
}
