import { Injectable } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { BehaviorSubject, Observable, of } from 'rxjs';
import { catchError } from 'rxjs/operators';
import { map } from 'rxjs/operators';
import { environment } from '../environments/environment';
import type { Geofence, GeofenceCreateRequest, GeofenceAlert } from '../models/geofence.model';
import { GeofenceType, AlertTypeEnum } from '../models/geofence.model';

/**
 * Service for geofence management and tracking.
 * Handles fetching geofences from the backend API and managing local state.
 */
@Injectable({
  providedIn: 'root',
})
export class GeofenceService {
  private geofencesSubject = new BehaviorSubject<Geofence[]>([]);
  public geofences$ = this.geofencesSubject.asObservable();

  private geofenceAlertsSubject = new BehaviorSubject<GeofenceAlert[]>([]);
  public geofenceAlerts$ = this.geofenceAlertsSubject.asObservable();

  private readonly API_BASE = `${environment.baseUrl}/api/admin/geofences`;

  constructor(private readonly http: HttpClient) {}

  /**
   * Load all active geofences for a company
   */
  loadGeofences(companyId: number): Observable<Geofence[]> {
    return this.http.get<Geofence[]>(`${this.API_BASE}?companyId=${companyId}`).pipe(
      map((geofences) => {
        this.geofencesSubject.next(geofences);
        return geofences;
      }),
      catchError((err) => {
        // Geofence endpoint may not be implemented yet or user may lack permission.
        // In all cases, degrade gracefully so the live tracking UI keeps working.
        const status = err?.status as number;
        if (status === 404 || status === 401 || status === 403) {
          this.geofencesSubject.next([]);
          return of([]);
        }
        throw err;
      }),
    );
  }

  /**
   * Get current cached geofences
   */
  getCachedGeofences(): Geofence[] {
    return this.geofencesSubject.value;
  }

  /**
   * Get a specific geofence by ID
   */
  getGeofenceById(id: number): Observable<Geofence> {
    return this.http.get<Geofence>(`${this.API_BASE}/${id}`);
  }

  /**
   * Create a new geofence
   */
  createGeofence(request: GeofenceCreateRequest): Observable<Geofence> {
    return this.http.post<Geofence>(this.API_BASE, request).pipe(
      map((geofence) => {
        // Add to local state
        const current = this.geofencesSubject.value;
        this.geofencesSubject.next([...current, geofence]);
        return geofence;
      }),
    );
  }

  /**
   * Update an existing geofence
   */
  updateGeofence(id: number, request: GeofenceCreateRequest): Observable<Geofence> {
    return this.http.put<Geofence>(`${this.API_BASE}/${id}`, request).pipe(
      map((geofence) => {
        // Update local state
        const current = this.geofencesSubject.value;
        const updated = current.map((g) => (g.id === id ? geofence : g));
        this.geofencesSubject.next(updated);
        return geofence;
      }),
    );
  }

  /**
   * Delete a geofence
   */
  deleteGeofence(id: number): Observable<void> {
    return this.http.delete<void>(`${this.API_BASE}/${id}`).pipe(
      map(() => {
        // Remove from local state
        const current = this.geofencesSubject.value;
        const updated = current.filter((g) => g.id !== id);
        this.geofencesSubject.next(updated);
      }),
    );
  }

  /**
   * Record a geofence alert event
   */
  recordGeofenceAlert(alert: GeofenceAlert): void {
    const current = this.geofenceAlertsSubject.value;
    this.geofenceAlertsSubject.next([alert, ...current.slice(0, 49)]); // Keep last 50
  }

  /**
   * Get all recorded geofence alerts
   */
  getGeofenceAlerts(): GeofenceAlert[] {
    return this.geofenceAlertsSubject.value;
  }

  /**
   * Clear geofence alerts
   */
  clearGeofenceAlerts(): void {
    this.geofenceAlertsSubject.next([]);
  }

  /**
   * Parse GeoJSON string into coordinates array
   */
  parseGeoJsonCoordinates(geoJsonStr: string): [number, number][] {
    try {
      const json = JSON.parse(geoJsonStr);

      // Handle both direct array format and GeoJSON Feature format
      let coords = json;
      if (json.geometry) {
        coords = json.geometry.coordinates;
      }

      // Ensure array of [lat, lng] tuples
      if (Array.isArray(coords) && coords.length > 0) {
        return coords.map((c: any) => [Number(c[0]), Number(c[1])]);
      }
    } catch (e) {
      console.error('Failed to parse GeoJSON coordinates:', e);
    }

    return [];
  }

  /**
   * Convert coordinates to GeoJSON string
   */
  coordinatesToGeoJson(coordinates: [number, number][]): string {
    return JSON.stringify(coordinates);
  }

  /**
   * Get Google Maps polygon color based on geofence alert type
   */
  getPolygonColor(geofence: Geofence): string {
    switch (geofence.alertType) {
      case AlertTypeEnum.ENTER:
        return '#4CAF50'; // Green for entry alerts
      case AlertTypeEnum.EXIT:
        return '#FF9800'; // Orange for exit alerts
      case AlertTypeEnum.BOTH:
        return '#2196F3'; // Blue for both
      case AlertTypeEnum.NONE:
        return '#9E9E9E'; // Gray for no alerts
      default:
        return '#2196F3';
    }
  }

  /**
   * Get circle border color
   */
  getCircleColor(geofence: Geofence): string {
    return this.getPolygonColor(geofence);
  }

  /**
   * Get displayable name for alert type
   */
  getAlertTypeLabel(alertType: AlertTypeEnum): string {
    switch (alertType) {
      case AlertTypeEnum.ENTER:
        return 'Entry Alert';
      case AlertTypeEnum.EXIT:
        return 'Exit Alert';
      case AlertTypeEnum.BOTH:
        return 'Entry & Exit';
      case AlertTypeEnum.NONE:
        return 'No Alerts';
      default:
        return '';
    }
  }

  /**
   * Get displayable name for geofence type
   */
  getGeofenceTypeLabel(type: GeofenceType): string {
    switch (type) {
      case GeofenceType.CIRCLE:
        return 'Circular Zone';
      case GeofenceType.POLYGON:
        return 'Polygon Zone';
      case GeofenceType.LINEAR:
        return 'Route Zone';
      default:
        return '';
    }
  }
}
