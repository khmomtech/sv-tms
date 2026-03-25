import { HttpClientTestingModule, HttpTestingController } from '@angular/common/http/testing';
import { TestBed } from '@angular/core/testing';

import { AlertTypeEnum, GeofenceType, type Geofence } from '../models/geofence.model';
import type { GeofenceCreateRequest } from '../models/geofence.model';
import { GeofenceService } from './geofence.service';

describe('GeofenceService', () => {
  let service: GeofenceService;
  let httpMock: HttpTestingController;

  const API_BASE = '/api/admin/geofences';
  const COMPANY_ID = 1;

  const mockGeofence: Geofence = {
    id: 42,
    name: 'Warehouse A',
    description: 'Main depot',
    type: GeofenceType.CIRCLE,
    centerLatitude: 11.5564,
    centerLongitude: 104.9282,
    radiusMeters: 500,
    alertType: AlertTypeEnum.BOTH,
    active: true,
    createdAt: '2026-01-01T00:00:00',
    updatedAt: '2026-01-01T00:00:00',
    createdBy: 'admin',
    tags: ['warehouse'],
  };

  const mockCreateRequest: GeofenceCreateRequest = {
    partnerCompanyId: COMPANY_ID,
    name: 'Warehouse A',
    type: GeofenceType.CIRCLE,
    centerLatitude: 11.5564,
    centerLongitude: 104.9282,
    radiusMeters: 500,
    alertType: AlertTypeEnum.BOTH,
    active: true,
  };

  beforeEach(() => {
    TestBed.configureTestingModule({
      imports: [HttpClientTestingModule],
      providers: [GeofenceService],
    });

    service = TestBed.inject(GeofenceService);
    httpMock = TestBed.inject(HttpTestingController);
  });

  afterEach(() => {
    httpMock.verify();
  });

  // ─── Initial state ───────────────────────────────────────────────────────

  it('should be created', () => {
    expect(service).toBeTruthy();
  });

  it('should start with an empty geofences list', () => {
    expect(service.getCachedGeofences()).toEqual([]);
  });

  // ─── loadGeofences ────────────────────────────────────────────────────────

  it('loadGeofences: GET returns geofences and updates subject', () => {
    const mockList = [mockGeofence];

    service.loadGeofences(COMPANY_ID).subscribe((result) => {
      expect(result.length).toBe(1);
      expect(result[0].id).toBe(42);
    });

    const req = httpMock.expectOne(`${API_BASE}?companyId=${COMPANY_ID}`);
    expect(req.request.method).toBe('GET');
    req.flush(mockList);

    expect(service.getCachedGeofences().length).toBe(1);
    expect(service.getCachedGeofences()[0].name).toBe('Warehouse A');
  });

  it('loadGeofences: 401 degrades gracefully with empty array', () => {
    service.loadGeofences(COMPANY_ID).subscribe((result) => {
      expect(result).toEqual([]);
    });

    const req = httpMock.expectOne(`${API_BASE}?companyId=${COMPANY_ID}`);
    req.flush('Unauthorized', { status: 401, statusText: 'Unauthorized' });

    expect(service.getCachedGeofences()).toEqual([]);
  });

  it('loadGeofences: 403 degrades gracefully with empty array', () => {
    service.loadGeofences(COMPANY_ID).subscribe((result) => {
      expect(result).toEqual([]);
    });

    const req = httpMock.expectOne(`${API_BASE}?companyId=${COMPANY_ID}`);
    req.flush('Forbidden', { status: 403, statusText: 'Forbidden' });

    expect(service.getCachedGeofences()).toEqual([]);
  });

  it('loadGeofences: 404 degrades gracefully with empty array', () => {
    service.loadGeofences(COMPANY_ID).subscribe((result) => {
      expect(result).toEqual([]);
    });

    const req = httpMock.expectOne(`${API_BASE}?companyId=${COMPANY_ID}`);
    req.flush('Not Found', { status: 404, statusText: 'Not Found' });

    expect(service.getCachedGeofences()).toEqual([]);
  });

  it('loadGeofences: 500 propagates error', () => {
    let errorThrown = false;

    service.loadGeofences(COMPANY_ID).subscribe({
      next: () => {},
      error: () => (errorThrown = true),
    });

    const req = httpMock.expectOne(`${API_BASE}?companyId=${COMPANY_ID}`);
    req.flush('Server Error', { status: 500, statusText: 'Internal Server Error' });

    expect(errorThrown).toBeTrue();
  });

  // ─── getGeofenceById ──────────────────────────────────────────────────────

  it('getGeofenceById: GET /{id} returns the geofence', () => {
    service.getGeofenceById(42).subscribe((result) => {
      expect(result.id).toBe(42);
      expect(result.name).toBe('Warehouse A');
    });

    const req = httpMock.expectOne(`${API_BASE}/42`);
    expect(req.request.method).toBe('GET');
    req.flush(mockGeofence);
  });

  // ─── createGeofence ───────────────────────────────────────────────────────

  it('createGeofence: POST sends request body and appends to subject', () => {
    const created = { ...mockGeofence, id: 99 };

    service.createGeofence(mockCreateRequest).subscribe((result) => {
      expect(result.id).toBe(99);
      expect(result.name).toBe('Warehouse A');
    });

    const req = httpMock.expectOne(API_BASE);
    expect(req.request.method).toBe('POST');
    expect(req.request.body).toEqual(mockCreateRequest);
    req.flush(created);

    expect(service.getCachedGeofences().length).toBe(1);
    expect(service.getCachedGeofences()[0].id).toBe(99);
  });

  it('createGeofence: appends to existing cached list', () => {
    // Pre-populate with one geofence
    service.loadGeofences(COMPANY_ID).subscribe();
    httpMock.expectOne(`${API_BASE}?companyId=${COMPANY_ID}`).flush([mockGeofence]);

    const created = { ...mockGeofence, id: 100, name: 'Zone B' };

    service.createGeofence(mockCreateRequest).subscribe();
    httpMock.expectOne(API_BASE).flush(created);

    expect(service.getCachedGeofences().length).toBe(2);
    expect(service.getCachedGeofences()[1].id).toBe(100);
  });

  // ─── updateGeofence ───────────────────────────────────────────────────────

  it('updateGeofence: PUT /{id} sends request body and updates subject', () => {
    // Pre-populate cache
    service.loadGeofences(COMPANY_ID).subscribe();
    httpMock.expectOne(`${API_BASE}?companyId=${COMPANY_ID}`).flush([mockGeofence]);

    const updateRequest: GeofenceCreateRequest = { ...mockCreateRequest, name: 'Updated Zone' };
    const updated: Geofence = { ...mockGeofence, name: 'Updated Zone' };

    service.updateGeofence(42, updateRequest).subscribe((result) => {
      expect(result.name).toBe('Updated Zone');
    });

    const req = httpMock.expectOne(`${API_BASE}/42`);
    expect(req.request.method).toBe('PUT');
    expect(req.request.body).toEqual(updateRequest);
    req.flush(updated);

    expect(service.getCachedGeofences()[0].name).toBe('Updated Zone');
  });

  it('updateGeofence: does not affect other cached geofences', () => {
    const other: Geofence = { ...mockGeofence, id: 55, name: 'Other Zone' };

    service.loadGeofences(COMPANY_ID).subscribe();
    httpMock.expectOne(`${API_BASE}?companyId=${COMPANY_ID}`).flush([mockGeofence, other]);

    const updated: Geofence = { ...mockGeofence, name: 'Updated' };
    service.updateGeofence(42, mockCreateRequest).subscribe();
    httpMock.expectOne(`${API_BASE}/42`).flush(updated);

    expect(service.getCachedGeofences().length).toBe(2);
    expect(service.getCachedGeofences().find((g) => g.id === 55)?.name).toBe('Other Zone');
  });

  // ─── deleteGeofence ───────────────────────────────────────────────────────

  it('deleteGeofence: DELETE /{id} removes from cached list', () => {
    service.loadGeofences(COMPANY_ID).subscribe();
    httpMock.expectOne(`${API_BASE}?companyId=${COMPANY_ID}`).flush([mockGeofence]);

    service.deleteGeofence(42).subscribe();

    const req = httpMock.expectOne(`${API_BASE}/42`);
    expect(req.request.method).toBe('DELETE');
    req.flush(null);

    expect(service.getCachedGeofences().length).toBe(0);
  });

  it('deleteGeofence: does not affect other cached geofences', () => {
    const other: Geofence = { ...mockGeofence, id: 55, name: 'Other Zone' };

    service.loadGeofences(COMPANY_ID).subscribe();
    httpMock.expectOne(`${API_BASE}?companyId=${COMPANY_ID}`).flush([mockGeofence, other]);

    service.deleteGeofence(42).subscribe();
    httpMock.expectOne(`${API_BASE}/42`).flush(null);

    expect(service.getCachedGeofences().length).toBe(1);
    expect(service.getCachedGeofences()[0].id).toBe(55);
  });

  // ─── Geofence alert state ─────────────────────────────────────────────────

  it('recordGeofenceAlert: adds alert and keeps max 50', () => {
    for (let i = 0; i < 55; i++) {
      service.recordGeofenceAlert({
        id: i,
        driverId: 1,
        geofenceId: 42,
        eventType: 'ENTER' as any,
        eventLatitude: 11.5,
        eventLongitude: 104.9,
        eventTimestamp: new Date().toISOString(),
        notificationSent: false,
        createdAt: new Date().toISOString(),
      });
    }
    expect(service.getGeofenceAlerts().length).toBe(50);
    // Most recent should be first
    expect(service.getGeofenceAlerts()[0].id).toBe(54);
  });

  it('clearGeofenceAlerts: empties alert list', () => {
    service.recordGeofenceAlert({
      id: 1,
      driverId: 1,
      geofenceId: 42,
      eventType: 'EXIT' as any,
      eventLatitude: 11.5,
      eventLongitude: 104.9,
      eventTimestamp: new Date().toISOString(),
      notificationSent: false,
      createdAt: new Date().toISOString(),
    });

    service.clearGeofenceAlerts();
    expect(service.getGeofenceAlerts().length).toBe(0);
  });

  // ─── Utility: get polygon/circle color ────────────────────────────────────

  it('getPolygonColor: ENTER → green', () => {
    const g = { ...mockGeofence, alertType: AlertTypeEnum.ENTER };
    expect(service.getPolygonColor(g)).toBe('#4CAF50');
  });

  it('getPolygonColor: EXIT → orange', () => {
    const g = { ...mockGeofence, alertType: AlertTypeEnum.EXIT };
    expect(service.getPolygonColor(g)).toBe('#FF9800');
  });

  it('getPolygonColor: BOTH → blue', () => {
    const g = { ...mockGeofence, alertType: AlertTypeEnum.BOTH };
    expect(service.getPolygonColor(g)).toBe('#2196F3');
  });

  it('getPolygonColor: NONE → gray', () => {
    const g = { ...mockGeofence, alertType: AlertTypeEnum.NONE };
    expect(service.getPolygonColor(g)).toBe('#9E9E9E');
  });

  it('getCircleColor: delegates to getPolygonColor', () => {
    const g = { ...mockGeofence, alertType: AlertTypeEnum.ENTER };
    expect(service.getCircleColor(g)).toBe(service.getPolygonColor(g));
  });

  // ─── Utility: labels ──────────────────────────────────────────────────────

  it('getAlertTypeLabel: returns correct labels', () => {
    expect(service.getAlertTypeLabel(AlertTypeEnum.ENTER)).toBe('Entry Alert');
    expect(service.getAlertTypeLabel(AlertTypeEnum.EXIT)).toBe('Exit Alert');
    expect(service.getAlertTypeLabel(AlertTypeEnum.BOTH)).toBe('Entry & Exit');
    expect(service.getAlertTypeLabel(AlertTypeEnum.NONE)).toBe('No Alerts');
  });

  it('getGeofenceTypeLabel: returns correct labels', () => {
    expect(service.getGeofenceTypeLabel(GeofenceType.CIRCLE)).toBe('Circular Zone');
    expect(service.getGeofenceTypeLabel(GeofenceType.POLYGON)).toBe('Polygon Zone');
    expect(service.getGeofenceTypeLabel(GeofenceType.LINEAR)).toBe('Route Zone');
  });

  // ─── Utility: GeoJSON parsing ─────────────────────────────────────────────

  it('parseGeoJsonCoordinates: parses flat coordinate array', () => {
    const json = JSON.stringify([
      [104.9, 11.5],
      [104.95, 11.5],
      [104.95, 11.55],
    ]);
    const result = service.parseGeoJsonCoordinates(json);
    expect(result.length).toBe(3);
    expect(result[0]).toEqual([104.9, 11.5]);
  });

  it('parseGeoJsonCoordinates: parses GeoJSON feature with geometry', () => {
    const json = JSON.stringify({
      geometry: {
        coordinates: [
          [104.9, 11.5],
          [104.95, 11.5],
        ],
      },
    });
    const result = service.parseGeoJsonCoordinates(json);
    expect(result.length).toBe(2);
  });

  it('parseGeoJsonCoordinates: returns empty array on invalid JSON', () => {
    expect(service.parseGeoJsonCoordinates('not-json')).toEqual([]);
  });

  it('parseGeoJsonCoordinates: returns empty array on empty input', () => {
    expect(service.parseGeoJsonCoordinates('[]')).toEqual([]);
  });

  it('coordinatesToGeoJson: serializes coordinates to JSON string', () => {
    const coords: [number, number][] = [
      [104.9, 11.5],
      [104.95, 11.55],
    ];
    expect(service.coordinatesToGeoJson(coords)).toBe(JSON.stringify(coords));
  });
});
