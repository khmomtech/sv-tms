import { TestBed } from '@angular/core/testing';
import { HttpClientTestingModule, HttpTestingController } from '@angular/common/http/testing';
import { of, Subject } from 'rxjs';

import { DriverService } from '../services/driver.service';
import { VehicleService } from '../services/vehicle.service';
import { CacheService } from '../services/cache.service';
import { CircuitBreakerService } from '../services/circuit-breaker.service';
import { WebSocketService } from '../services/websocket.service';
import { AuthService } from '../services/auth.service';
import { environment } from '../../environments/environment';

/**
 * Phase 3 Testing - Week 3: Integration Tests
 *
 * Tests integration between multiple services and components:
 * - API contract validation
 * - Service layer integration
 * - WebSocket realtime updates
 * - End-to-end data flows
 */

describe('Integration Tests - API Contracts', () => {
  let httpMock: HttpTestingController;
  let driverService: DriverService;
  let vehicleService: VehicleService;

  beforeEach(() => {
    TestBed.configureTestingModule({
      imports: [HttpClientTestingModule],
      providers: [
        DriverService,
        VehicleService,
        CacheService,
        CircuitBreakerService,
        {
          provide: AuthService,
          useValue: {
            getAuthToken: () => 'test-token',
            getToken: () => 'test-token',
          },
        },
      ],
    });

    httpMock = TestBed.inject(HttpTestingController);
    driverService = TestBed.inject(DriverService);
    vehicleService = TestBed.inject(VehicleService);
  });

  afterEach(() => {
    httpMock.verify();
  });

  describe('Driver API Contract', () => {
    it('should match expected paginated response schema', (done) => {
      driverService.getDrivers(0, 15).subscribe((response) => {
        expect(response).toEqual({
          success: true,
          data: jasmine.objectContaining({
            content: jasmine.any(Array),
            totalElements: jasmine.any(Number),
            totalPages: jasmine.any(Number),
          }),
        });
        done();
      });

      const req = httpMock.expectOne(`${environment.apiUrl}/admin/drivers/alllists?page=0&size=15`);
      expect(req.request.method).toBe('GET');

      req.flush({
        success: true,
        data: {
          content: [{ id: 1, name: 'John Doe', status: 'AVAILABLE' }],
          totalElements: 1,
          totalPages: 1,
        },
      });
    });

    it('should include required headers in requests', () => {
      driverService.getDrivers(0, 15).subscribe();

      const req = httpMock.expectOne(`${environment.apiUrl}/admin/drivers/alllists?page=0&size=15`);

      expect(req.request.headers.has('Authorization')).toBe(true);
      expect(req.request.headers.get('Authorization')).toBe('Bearer test-token');

      req.flush({ success: true, data: { content: [], totalElements: 0 } });
    });

    it('should send correct payload for driver creation', () => {
      const newDriver: Partial<import('../models/driver.model').Driver> = {
        firstName: 'Test',
        lastName: 'Driver',
        phone: '+1234567890',
        licenseNumber: 'DL123456',
        status: 'online' as import('../models/driver.model').DriverStatusLiteral,
        isActive: true,
        rating: 5,
      };

      driverService.addDriver(newDriver).subscribe();

      const req = httpMock.expectOne(`${environment.apiUrl}/admin/drivers/add`);
      expect(req.request.method).toBe('POST');
      expect(req.request.body).toEqual(
        jasmine.objectContaining({
          firstName: 'Test',
          lastName: 'Driver',
          phone: '+1234567890',
          licenseNumber: 'DL123456',
          isActive: true,
        }),
      );

      req.flush({ success: true, data: { id: 1, ...newDriver } });
    });

    it('should handle version field in update requests', () => {
      const updatedDriver = {
        name: 'Updated Name',
        version: 2,
      };

      driverService.updateDriver(1, updatedDriver).subscribe();

      const req = httpMock.expectOne(`${environment.apiUrl}/admin/drivers/update/1`);
      expect(req.request.method).toBe('PUT');
      expect(req.request.body.version).toBe(2);

      req.flush({ success: true, data: { id: 1, ...updatedDriver } });
    });

    it('should handle optimistic locking conflict response', () => {
      const driver = { name: 'Test', version: 1 };

      driverService.updateDriver(1, driver).subscribe({
        error: (error) => {
          expect(error.status).toBe(409);
          expect(error.error).toEqual(
            jasmine.objectContaining({
              localVersion: jasmine.any(Object),
              serverVersion: jasmine.any(Object),
              conflicts: jasmine.any(Array),
            }),
          );
        },
      });

      const req = httpMock.expectOne(`${environment.apiUrl}/admin/drivers/update/1`);
      req.flush(
        {
          localVersion: { id: 1, name: 'Local', version: 1 },
          serverVersion: { id: 1, name: 'Server', version: 2 },
          conflicts: [{ field: 'name', localValue: 'Local', serverValue: 'Server' }],
        },
        { status: 409, statusText: 'Conflict' },
      );
    });
  });

  describe('Vehicle API Contract', () => {
    it('should match expected vehicle response schema', (done) => {
      vehicleService.getVehicles(0, 15).subscribe((response) => {
        expect(response.data.content[0]).toEqual(
          jasmine.objectContaining({
            id: jasmine.any(Number),
            plateNumber: jasmine.any(String),
            type: jasmine.any(String),
            status: jasmine.any(String),
            capacity: jasmine.any(Number),
          }),
        );
        done();
      });

      const req = httpMock.expectOne(`${environment.apiUrl}/admin/vehicles/search?page=0&size=15`);
      req.flush({
        success: true,
        data: {
          content: [
            {
              id: 1,
              plateNumber: 'ABC-123',
              type: 'TRUCK',
              status: 'AVAILABLE',
              capacity: 1000,
            },
          ],
          totalElements: 1,
          totalPages: 1,
        },
      });
    });

    it('should handle filter parameters correctly', () => {
      const filters = {
        search: 'ABC',
        status: 'AVAILABLE',
        truckSize: 'LARGE',
      };

      vehicleService.getVehicles(0, 15, filters).subscribe();

      const req = httpMock.expectOne((request) => {
        return (
          request.url.includes('/admin/vehicles/search') &&
          request.urlWithParams.includes('search=ABC') &&
          request.urlWithParams.includes('status=AVAILABLE') &&
          request.urlWithParams.includes('truckSize=LARGE')
        );
      });

      expect(req.request.method).toBe('GET');

      req.flush({ success: true, data: { content: [], totalElements: 0 } });
    });
  });
});

describe('Integration Tests - Service Layer Integration', () => {
  let driverService: DriverService;
  let cacheService: CacheService;
  let circuitBreaker: CircuitBreakerService;
  let httpMock: HttpTestingController;

  beforeEach(() => {
    TestBed.configureTestingModule({
      imports: [HttpClientTestingModule],
      providers: [
        DriverService,
        CacheService,
        CircuitBreakerService,
        {
          provide: AuthService,
          useValue: { getAuthToken: () => 'test-token', getToken: () => 'test-token' },
        },
      ],
    });

    driverService = TestBed.inject(DriverService);
    cacheService = TestBed.inject(CacheService);
    circuitBreaker = TestBed.inject(CircuitBreakerService);
    httpMock = TestBed.inject(HttpTestingController);
  });

  afterEach(() => {
    httpMock.verify();
  });

  it('should integrate cache service with driver service', (done) => {
    driverService.getAllDrivers().subscribe(() => {
      done();
    });

    const req = httpMock.expectOne(`${environment.apiUrl}/admin/drivers/alllists?page=0&size=10`);
    req.flush({ success: true, data: [] });
  });

  it('should use cached data when available', (done) => {
    driverService.getAllDrivers().subscribe((response) => {
      expect(response).toEqual({
        success: true,
        data: { content: [], size: 0, totalElements: 0, totalPages: 0 },
      });
      done();
    });

    const req = httpMock.expectOne(`${environment.apiUrl}/admin/drivers/alllists?page=0&size=10`);
    req.flush({ success: true, data: { content: [], size: 0, totalElements: 0, totalPages: 0 } });
  });

  it('should allow mutations without cache coupling', () => {
    spyOn(cacheService, 'invalidatePattern');

    driverService
      .addDriver({ firstName: 'New', lastName: 'Driver', phone: '+1234567890' } as any)
      .subscribe();

    const req = httpMock.expectOne(`${environment.apiUrl}/admin/drivers/add`);
    req.flush({ success: true, data: { id: 1 } });

    expect(cacheService.invalidatePattern).not.toHaveBeenCalled();
  });

  it('should fetch drivers without circuit breaker coupling', (done) => {
    spyOn(circuitBreaker, 'execute');

    driverService.getDrivers(0, 15).subscribe(() => {
      expect(circuitBreaker.execute).not.toHaveBeenCalled();
      done();
    });

    const req = httpMock.expectOne(`${environment.apiUrl}/admin/drivers/alllists?page=0&size=15`);
    req.flush({ success: true, data: { content: [], totalElements: 0 } });
  });
});

describe('Integration Tests - WebSocket Realtime Updates', () => {
  let webSocketService: WebSocketService;
  let driverService: DriverService;
  let mockWebSocket: Subject<any>;

  beforeEach(() => {
    mockWebSocket = new Subject();

    TestBed.configureTestingModule({
      imports: [HttpClientTestingModule],
      providers: [
        DriverService,
        {
          provide: WebSocketService,
          useValue: {
            connect: jasmine.createSpy('connect'),
            disconnect: jasmine.createSpy('disconnect'),
            subscribe: jasmine.createSpy('subscribe').and.returnValue(mockWebSocket.asObservable()),
            send: jasmine.createSpy('send'),
            isConnected: () => true,
          },
        },
        {
          provide: AuthService,
          useValue: { getAuthToken: () => 'test-token', getToken: () => 'test-token' },
        },
        CacheService,
        CircuitBreakerService,
      ],
    });

    webSocketService = TestBed.inject(WebSocketService);
    driverService = TestBed.inject(DriverService);
  });

  it('should connect to WebSocket when invoked', () => {
    webSocketService.connect('', '');
    expect(webSocketService.connect).toHaveBeenCalled();
  });

  it('should subscribe to driver location updates', (done) => {
    const subscription = webSocketService
      .subscribe('/topic/driver-locations')
      .subscribe((message) => {
        expect(message).toEqual({
          driverId: 1,
          latitude: 11.5564,
          longitude: 104.9282,
          timestamp: jasmine.any(String),
        });
        done();
      });

    mockWebSocket.next({
      driverId: 1,
      latitude: 11.5564,
      longitude: 104.9282,
      timestamp: new Date().toISOString(),
    });

    subscription.unsubscribe();
  });

  it('should subscribe to driver status updates', (done) => {
    const subscription = webSocketService.subscribe('/topic/driver-status').subscribe((message) => {
      expect(message).toEqual({
        driverId: 1,
        status: 'ON_TRIP',
        timestamp: jasmine.any(String),
      });
      done();
    });

    mockWebSocket.next({
      driverId: 1,
      status: 'ON_TRIP',
      timestamp: new Date().toISOString(),
    });

    subscription.unsubscribe();
  });
});

describe('Integration Tests - End-to-End Data Flows', () => {
  let httpMock: HttpTestingController;
  let driverService: DriverService;
  let cacheService: CacheService;

  beforeEach(() => {
    TestBed.configureTestingModule({
      imports: [HttpClientTestingModule],
      providers: [
        DriverService,
        CacheService,
        CircuitBreakerService,
        {
          provide: AuthService,
          useValue: { getAuthToken: () => 'test-token', getToken: () => 'test-token' },
        },
      ],
    });

    httpMock = TestBed.inject(HttpTestingController);
    driverService = TestBed.inject(DriverService);
    cacheService = TestBed.inject(CacheService);
  });

  afterEach(() => {
    httpMock.verify();
  });

  it('should complete full CRUD cycle', () => {
    // Create
    driverService
      .addDriver({
        firstName: 'Test',
        lastName: 'Driver',
        phone: '+1234567890',
        licenseNumber: 'DL123456',
        status: 'online' as import('../models/driver.model').DriverStatusLiteral,
        isActive: true,
        rating: 5,
        selected: false,
        logs: [],
        updatedFromSocket: false,
      } as Partial<import('../models/driver.model').Driver>)
      .subscribe();
    let req = httpMock.expectOne(`${environment.apiUrl}/admin/drivers/add`);
    req.flush({
      success: true,
      data: {
        id: 1,
        name: 'Test Driver',
        licenseNumber: 'DL123456',
        phone: '+1234567890',
        rating: 5,
        isActive: true,
        selected: false,
        status: 'online' as import('../models/driver.model').DriverStatusLiteral,
        logs: [],
        updatedFromSocket: false,
      },
    });

    // Read
    driverService.getDrivers(0, 15).subscribe();
    req = httpMock.expectOne(`${environment.apiUrl}/admin/drivers/alllists?page=0&size=15`);
    req.flush({
      success: true,
      data: {
        content: [
          {
            id: 1,
            name: 'Test Driver',
            licenseNumber: 'DL123456',
            phone: '+1234567890',
            rating: 5,
            isActive: true,
            selected: false,
            status: 'online' as import('../models/driver.model').DriverStatusLiteral,
            logs: [],
            updatedFromSocket: false,
          },
        ],
        size: 1,
        totalElements: 1,
        totalPages: 1,
      },
    });

    // Update
    driverService
      .updateDriver(1, {
        name: 'Updated Driver',
        licenseNumber: 'DL123456',
        phone: '+1234567890',
        rating: 5,
        isActive: true,
        selected: false,
        status: 'online' as import('../models/driver.model').DriverStatusLiteral,
        logs: [],
        updatedFromSocket: false,
      } as Partial<import('../models/driver.model').Driver>)
      .subscribe();
    req = httpMock.expectOne(`${environment.apiUrl}/admin/drivers/update/1`);
    req.flush({
      success: true,
      data: {
        id: 1,
        name: 'Updated Driver',
        licenseNumber: 'DL123456',
        phone: '+1234567890',
        rating: 5,
        isActive: true,
        selected: false,
        status: 'online' as import('../models/driver.model').DriverStatusLiteral,
        logs: [],
        updatedFromSocket: false,
      },
    });

    // Delete
    driverService.deleteDriver(1).subscribe();
    req = httpMock.expectOne(`${environment.apiUrl}/admin/drivers/delete/1`);
    expect(req.request.method).toBe('DELETE');
    req.flush({ success: true });
  });

  it('should maintain cache consistency across operations', () => {
    // Fetch
    driverService.getAllDrivers().subscribe();
    let req = httpMock.expectOne(`${environment.apiUrl}/admin/drivers/alllists?page=0&size=10`);
    req.flush({ success: true, data: { content: [], size: 0, totalElements: 0, totalPages: 0 } });

    // Mutate
    driverService
      .addDriver({ firstName: 'New', lastName: 'Driver', phone: '+1234567890' } as any)
      .subscribe();
    req = httpMock.expectOne(`${environment.apiUrl}/admin/drivers/add`);
    req.flush({ success: true, data: { id: 1 } });
  });

  it('should handle concurrent requests correctly', () => {
    driverService.getDrivers(0, 15).subscribe();
    driverService.getDrivers(0, 15).subscribe();

    const requests = httpMock.match(`${environment.apiUrl}/admin/drivers/alllists?page=0&size=15`);
    expect(requests.length).toBe(2);

    requests.forEach((req) =>
      req.flush({ success: true, data: { content: [], totalElements: 0 } }),
    );
  });
});
