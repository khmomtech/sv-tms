import { TestBed, fakeAsync, tick } from '@angular/core/testing';
import { HttpClientTestingModule, HttpTestingController } from '@angular/common/http/testing';
import { of, throwError } from 'rxjs';

import { VehicleService } from './vehicle.service';
import { AuthService } from './auth.service';
import { CacheService } from './cache.service';
import { CircuitBreakerService } from './circuit-breaker.service';
import { environment } from '../../environments/environment';
import { Vehicle } from '../models/vehicle.model';
import { ApiResponse } from '../models/api-response.model';

describe('VehicleService', () => {
  let service: VehicleService;
  let httpMock: HttpTestingController;
  let mockAuthService: jasmine.SpyObj<AuthService>;
  let mockCacheService: jasmine.SpyObj<CacheService>;
  let mockCircuitBreaker: jasmine.SpyObj<CircuitBreakerService>;

  const mockToken = 'test-jwt-token-123';
  const mockVehicle: Vehicle = {
    id: 1,
    licensePlate: 'ABC-123',
    type: 'TRUCK',
    status: 'AVAILABLE',
    model: 'Hino 500',
    manufacturer: 'Hino',
    mileage: 10000,
    fuelConsumption: 25,
  };

  beforeEach(() => {
    const authServiceSpy = jasmine.createSpyObj('AuthService', ['getToken']);
    const cacheServiceSpy = jasmine.createSpyObj('CacheService', [
      'get',
      'set',
      'getOrFetch',
      'invalidate',
      'invalidatePattern',
      'cleanup',
    ]);
    const circuitBreakerSpy = jasmine.createSpyObj('CircuitBreakerService', [
      'execute',
      'getState',
      'reset',
    ]);

    authServiceSpy.getToken.and.returnValue(mockToken);
    cacheServiceSpy.getOrFetch.and.callFake((key: string, request: any) => request);
    circuitBreakerSpy.execute.and.callFake((name: string, request: any) => request);

    TestBed.configureTestingModule({
      imports: [HttpClientTestingModule],
      providers: [
        VehicleService,
        { provide: AuthService, useValue: authServiceSpy },
        { provide: CacheService, useValue: cacheServiceSpy },
        { provide: CircuitBreakerService, useValue: circuitBreakerSpy },
      ],
    });

    service = TestBed.inject(VehicleService);
    httpMock = TestBed.inject(HttpTestingController);
    mockAuthService = TestBed.inject(AuthService) as jasmine.SpyObj<AuthService>;
    mockCacheService = TestBed.inject(CacheService) as jasmine.SpyObj<CacheService>;
    mockCircuitBreaker = TestBed.inject(
      CircuitBreakerService,
    ) as jasmine.SpyObj<CircuitBreakerService>;
  });

  afterEach(() => {
    httpMock.verify();
  });

  describe('Service Initialization', () => {
    it('should be created', () => {
      expect(service).toBeTruthy();
    });

    it('should have correct API URL', () => {
      expect(service['apiUrl']).toBe(`${environment.baseUrl}/api/admin/vehicles`);
    });

    it('should set up cache cleanup interval', fakeAsync(() => {
      tick(10 * 60 * 1000); // 10 minutes
      expect(mockCacheService.cleanup).toHaveBeenCalled();
    }));
  });

  describe('getVehicles (Paginated)', () => {
    it('should fetch paginated vehicles without filters', () => {
      const mockResponse: ApiResponse<{
        content: Vehicle[];
        totalElements: number;
        totalPages: number;
      }> = {
        success: true,
        data: {
          content: [mockVehicle],
          totalElements: 1,
          totalPages: 1,
        },
      };

      service.getVehicles(0, 15).subscribe((response) => {
        expect(response.success).toBe(true);
        expect(response.data.content.length).toBe(1);
        expect(response.data.content[0]).toEqual(mockVehicle);
      });

      const req = httpMock.expectOne(
        (request) =>
          request.url.includes('/api/admin/vehicles/search') &&
          request.url.includes('page=0') &&
          request.url.includes('size=15'),
      );

      expect(req.request.method).toBe('GET');
      expect(req.request.headers.get('Authorization')).toBe(`Bearer ${mockToken}`);
      req.flush(mockResponse);
    });

    it('should apply search filter', () => {
      const filters = { search: 'ABC' };

      service.getVehicles(0, 15, filters).subscribe();

      const req = httpMock.expectOne((request) => request.url.includes('search=ABC'));

      expect(req.request.method).toBe('GET');
      req.flush({ success: true, data: { content: [], totalElements: 0, totalPages: 0 } });
    });

    it('should apply multiple filters', () => {
      const filters = {
        search: 'ABC',
        status: 'AVAILABLE',
        truckSize: 'LARGE',
        zone: 'NORTH',
        assigned: 'true',
      };

      service.getVehicles(0, 15, filters).subscribe();

      const req = httpMock.expectOne(
        (request) =>
          request.url.includes('search=ABC') &&
          request.url.includes('status=AVAILABLE') &&
          request.url.includes('truckSize=LARGE') &&
          request.url.includes('zone=NORTH') &&
          request.url.includes('assigned=true'),
      );

      req.flush({ success: true, data: { content: [], totalElements: 0, totalPages: 0 } });
    });

    it('should use circuit breaker for resilience', () => {
      service.getVehicles().subscribe();

      const req = httpMock.expectOne((request) =>
        request.url.includes('/api/admin/vehicles/search'),
      );
      req.flush({ success: true, data: { content: [], totalElements: 0, totalPages: 0 } });

      expect(mockCircuitBreaker.execute).toHaveBeenCalledWith(
        'vehicle-service',
        jasmine.any(Object),
      );
    });

    it('should use cache with TTL', () => {
      service.getVehicles(0, 15, { search: 'test' }).subscribe();

      const req = httpMock.expectOne((request) =>
        request.url.includes('/api/admin/vehicles/search'),
      );
      req.flush({ success: true, data: { content: [], totalElements: 0, totalPages: 0 } });

      expect(mockCacheService.getOrFetch).toHaveBeenCalledWith(
        jasmine.stringContaining('vehicles:search:'),
        jasmine.any(Object),
        5 * 60 * 1000, // 5 minutes TTL
        true, // useStaleOnError
      );
    });

    it('should handle timeout errors', fakeAsync(() => {
      let capturedError: unknown;

      service.getVehicles().subscribe(
        () => fail('Should have failed'),
        (error) => {
          capturedError = error;
        },
      );

      httpMock.expectOne((request) => request.url.includes('/api/admin/vehicles/search'));

      tick(31000); // Exceed 30 second timeout
      expect(capturedError).toBeDefined();
    }));
  });

  describe('getAllVehicles', () => {
    it('should fetch all vehicles', () => {
      const mockResponse: ApiResponse<Vehicle[]> = {
        success: true,
        data: [mockVehicle],
      };

      service.getAllVehicles().subscribe((response) => {
        expect(response.success).toBe(true);
        expect(response.data.length).toBe(1);
        expect(response.data[0]).toEqual(mockVehicle);
      });

      const req = httpMock.expectOne(`${environment.baseUrl}/api/admin/vehicles/all`);
      expect(req.request.method).toBe('GET');
      req.flush(mockResponse);
    });

    it('should use cache for all vehicles', () => {
      service.getAllVehicles().subscribe();

      const req = httpMock.expectOne(`${environment.baseUrl}/api/admin/vehicles/all`);
      req.flush({ success: true, data: [] });

      expect(mockCacheService.getOrFetch).toHaveBeenCalledWith(
        'vehicles:all',
        jasmine.any(Object),
        5 * 60 * 1000,
        true,
      );
    });

    it('should use circuit breaker', () => {
      service.getAllVehicles().subscribe();

      const req = httpMock.expectOne(`${environment.baseUrl}/api/admin/vehicles/all`);
      req.flush({ success: true, data: [] });

      expect(mockCircuitBreaker.execute).toHaveBeenCalledWith(
        'vehicle-service',
        jasmine.any(Object),
      );
    });
  });

  describe('addVehicle', () => {
    it('should create new vehicle', () => {
      const newVehicle: Vehicle = {
        licensePlate: 'XYZ-789',
        type: 'VAN',
        status: 'AVAILABLE',
        model: 'Hyundai H350',
        manufacturer: 'Hyundai',
        mileage: 0,
        fuelConsumption: 18,
      };

      const mockResponse: ApiResponse<Vehicle> = {
        success: true,
        data: { ...mockVehicle, id: 2, licensePlate: 'XYZ-789' },
      };

      service.addVehicle(newVehicle).subscribe((response) => {
        expect(response.success).toBeTrue();
        expect(response.data.licensePlate).toBe('XYZ-789');
      });

      const req = httpMock.expectOne(`${environment.baseUrl}/api/admin/vehicles`);
      expect(req.request.method).toBe('POST');
      expect(req.request.body).toEqual(newVehicle);
      req.flush(mockResponse);
    });

    it('should post to the admin vehicles endpoint on create', () => {
      service.addVehicle(mockVehicle).subscribe();

      const req = httpMock.expectOne(`${environment.baseUrl}/api/admin/vehicles`);
      req.flush({ success: true, data: mockVehicle });
      expect(mockCacheService.invalidatePattern).toHaveBeenCalledWith(/^vehicles:/);
    });

    it('should handle validation errors', () => {
      service.addVehicle(mockVehicle).subscribe(
        () => fail('Should have failed'),
        (error) => {
          expect(error).toBeDefined();
        },
      );

      const req = httpMock.expectOne(`${environment.baseUrl}/api/admin/vehicles`);
      req.flush({ message: 'Validation failed' }, { status: 400, statusText: 'Bad Request' });
    });
  });

  describe('updateVehicle', () => {
    it('should update existing vehicle', () => {
      const updates = { ...mockVehicle, status: 'IN_USE' as any };

      const mockResponse: ApiResponse<Vehicle> = {
        success: true,
        data: updates,
      };

      service.updateVehicle(updates).subscribe((response) => {
        expect(response.success).toBe(true);
        expect(response.data.status).toBe('IN_USE');
      });

      const req = httpMock.expectOne(`${environment.baseUrl}/api/admin/vehicles/${mockVehicle.id}`);
      expect(req.request.method).toBe('PUT');
      expect(req.request.body).toEqual(updates);
      req.flush(mockResponse);
    });

    it('should require vehicle ID for update', (done) => {
      const vehicleWithoutId = { ...mockVehicle, id: undefined };

      service.updateVehicle(vehicleWithoutId as any).subscribe(
        () => fail('Should have failed'),
        (error) => {
          expect(error.message).toContain('Vehicle ID is required');
          done();
        },
      );
    });

    it('should invalidate cache after update', () => {
      service.updateVehicle(mockVehicle).subscribe();

      const req = httpMock.expectOne(`${environment.baseUrl}/api/admin/vehicles/${mockVehicle.id}`);
      req.flush({ success: true, data: mockVehicle });

      expect(mockCacheService.invalidatePattern).toHaveBeenCalledWith(/^vehicles:/);
    });

    it('should handle 404 not found', () => {
      service.updateVehicle(mockVehicle).subscribe(
        () => fail('Should have failed'),
        (error) => {
          expect(error.message).toContain('Not found');
        },
      );

      const req = httpMock.expectOne(`${environment.baseUrl}/api/admin/vehicles/${mockVehicle.id}`);
      req.flush('Not found', { status: 404, statusText: 'Not Found' });
    });
  });

  describe('deleteVehicle', () => {
    it('should delete vehicle by ID', () => {
      service.deleteVehicle(1).subscribe((response) => {
        expect(response.success).toBe(true);
      });

      const req = httpMock.expectOne(`${environment.baseUrl}/api/admin/vehicles/1`);
      expect(req.request.method).toBe('DELETE');
      req.flush({ success: true });
    });

    it('should invalidate cache after deletion', () => {
      service.deleteVehicle(1).subscribe();

      const req = httpMock.expectOne(`${environment.baseUrl}/api/admin/vehicles/1`);
      req.flush({ success: true });

      expect(mockCacheService.invalidatePattern).toHaveBeenCalledWith(/^vehicles:/);
    });

    it('should handle deletion errors', () => {
      service.deleteVehicle(1).subscribe(
        () => fail('Should have failed'),
        (error) => {
          expect(error).toBeDefined();
        },
      );

      const req = httpMock.expectOne(`${environment.baseUrl}/api/admin/vehicles/1`);
      req.flush('Cannot delete', { status: 500, statusText: 'Internal Server Error' });
    });
  });

  describe('Error Handling', () => {
    it('should map 400 to bad request message', () => {
      service.getAllVehicles().subscribe(
        () => fail('Should have failed'),
        (error) => {
          expect(error.message).toContain('Bad request');
        },
      );

      const req = httpMock.expectOne(`${environment.baseUrl}/api/admin/vehicles/all`);
      req.flush('Bad request', { status: 400, statusText: 'Bad Request' });
    });

    it('should map 401 to unauthorized message', () => {
      service.getAllVehicles().subscribe(
        () => fail('Should have failed'),
        (error) => {
          expect(error.message).toContain('Unauthorized');
        },
      );

      const req = httpMock.expectOne(`${environment.baseUrl}/api/admin/vehicles/all`);
      req.flush('Unauthorized', { status: 401, statusText: 'Unauthorized' });
    });

    it('should map 403 to forbidden message', () => {
      service.getAllVehicles().subscribe(
        () => fail('Should have failed'),
        (error) => {
          expect(error.message).toContain('Forbidden');
        },
      );

      const req = httpMock.expectOne(`${environment.baseUrl}/api/admin/vehicles/all`);
      req.flush('Forbidden', { status: 403, statusText: 'Forbidden' });
    });

    it('should map 404 to not found message', () => {
      service.getAllVehicles().subscribe(
        () => fail('Should have failed'),
        (error) => {
          expect(error.message).toContain('Not found');
        },
      );

      const req = httpMock.expectOne(`${environment.baseUrl}/api/admin/vehicles/all`);
      req.flush('Not found', { status: 404, statusText: 'Not Found' });
    });

    it('should map 500 to server error message', () => {
      service.getAllVehicles().subscribe(
        () => fail('Should have failed'),
        (error) => {
          expect(error.message).toContain('Server error');
        },
      );

      const req = httpMock.expectOne(`${environment.baseUrl}/api/admin/vehicles/all`);
      req.flush('Server error', { status: 500, statusText: 'Internal Server Error' });
    });

    it('should map network errors (status 0)', () => {
      service.getAllVehicles().subscribe(
        () => fail('Should have failed'),
        (error) => {
          expect(error.message).toContain('Something went wrong');
        },
      );

      const req = httpMock.expectOne(`${environment.baseUrl}/api/admin/vehicles/all`);
      req.error(new ProgressEvent('error'), { status: 0 });
    });

    it('should extract error message from response', () => {
      service.getAllVehicles().subscribe(
        () => fail('Should have failed'),
        (error) => {
          expect(error.message).toBe('Custom error message');
        },
      );

      const req = httpMock.expectOne(`${environment.baseUrl}/api/admin/vehicles/all`);
      req.flush({ message: 'Custom error message' }, { status: 400, statusText: 'Bad Request' });
    });

    it('should handle string error responses', () => {
      service.getAllVehicles().subscribe(
        () => fail('Should have failed'),
        (error) => {
          expect(error.message).toBe('String error');
        },
      );

      const req = httpMock.expectOne(`${environment.baseUrl}/api/admin/vehicles/all`);
      req.flush('String error', { status: 400, statusText: 'Bad Request' });
    });

    it('should extract validation errors', () => {
      service.getAllVehicles().subscribe(
        () => fail('Should have failed'),
        (error) => {
          expect(error.message).toContain('Field 1 error');
          expect(error.message).toContain('Field 2 error');
        },
      );

      const req = httpMock.expectOne(`${environment.baseUrl}/api/admin/vehicles/all`);
      req.flush(
        { errors: { field1: 'Field 1 error', field2: 'Field 2 error' } },
        { status: 422, statusText: 'Unprocessable Entity' },
      );
    });
  });

  describe('Header Configuration', () => {
    it('should include Authorization header', () => {
      service.getAllVehicles().subscribe();

      const req = httpMock.expectOne(`${environment.baseUrl}/api/admin/vehicles/all`);
      expect(req.request.headers.get('Authorization')).toBe(`Bearer ${mockToken}`);
      req.flush({ success: true, data: [] });
    });

    it('should include Content-Type header', () => {
      service.getAllVehicles().subscribe();

      const req = httpMock.expectOne(`${environment.baseUrl}/api/admin/vehicles/all`);
      expect(req.request.headers.get('Content-Type')).toBe('application/json');
      req.flush({ success: true, data: [] });
    });
  });

  describe('Resilience Patterns', () => {
    it('should integrate cache service for performance', () => {
      service.getVehicles().subscribe();

      const req = httpMock.expectOne((request) =>
        request.url.includes('/api/admin/vehicles/search'),
      );
      req.flush({ success: true, data: { content: [], totalElements: 0, totalPages: 0 } });

      expect(mockCacheService.getOrFetch).toHaveBeenCalled();
    });

    it('should integrate circuit breaker for resilience', () => {
      service.getAllVehicles().subscribe();

      const req = httpMock.expectOne(`${environment.baseUrl}/api/admin/vehicles/all`);
      req.flush({ success: true, data: [] });

      expect(mockCircuitBreaker.execute).toHaveBeenCalledWith(
        'vehicle-service',
        jasmine.any(Object),
      );
    });

    it('should use stale data on error', () => {
      mockCacheService.getOrFetch.and.callFake((key, request, ttl, useStale) => {
        expect(useStale).toBe(true);
        return request;
      });

      service.getVehicles().subscribe();

      const req = httpMock.expectOne((request) =>
        request.url.includes('/api/admin/vehicles/search'),
      );
      req.flush({ success: true, data: { content: [], totalElements: 0, totalPages: 0 } });
    });
  });

  describe('Cache Invalidation', () => {
    it('should invalidate all vehicle caches on create', () => {
      service.addVehicle(mockVehicle).subscribe();

      const req = httpMock.expectOne(`${environment.baseUrl}/api/admin/vehicles`);
      req.flush({ success: true, data: mockVehicle });

      expect(mockCacheService.invalidatePattern).toHaveBeenCalledWith(/^vehicles:/);
    });

    it('should invalidate all vehicle caches on update', () => {
      service.updateVehicle(mockVehicle).subscribe();

      const req = httpMock.expectOne(`${environment.baseUrl}/api/admin/vehicles/${mockVehicle.id}`);
      req.flush({ success: true, data: mockVehicle });

      expect(mockCacheService.invalidatePattern).toHaveBeenCalledWith(/^vehicles:/);
    });

    it('should invalidate all vehicle caches on delete', () => {
      service.deleteVehicle(1).subscribe();

      const req = httpMock.expectOne(`${environment.baseUrl}/api/admin/vehicles/1`);
      req.flush({ success: true });

      expect(mockCacheService.invalidatePattern).toHaveBeenCalledWith(/^vehicles:/);
    });
  });

  describe('Performance', () => {
    it('should handle pagination efficiently', () => {
      service.getVehicles(0, 100).subscribe();

      const req = httpMock.expectOne(
        (request) => request.url.includes('page=0') && request.url.includes('size=100'),
      );
      req.flush({ success: true, data: { content: [], totalElements: 0, totalPages: 0 } });

      expect(req.request.url).toContain('size=100');
    });

    it('should use default page size', () => {
      service.getVehicles().subscribe();

      const req = httpMock.expectOne((request) => request.url.includes('size=15'));
      req.flush({ success: true, data: { content: [], totalElements: 0, totalPages: 0 } });
    });
  });

  describe('Edge Cases', () => {
    it('should handle empty filter object', () => {
      service.getVehicles(0, 15, {}).subscribe();

      const req = httpMock.expectOne((request) =>
        request.url.includes('/api/admin/vehicles/search'),
      );

      // Should only have page and size params
      expect(req.request.url).not.toContain('search=');
      expect(req.request.url).not.toContain('status=');
      req.flush({ success: true, data: { content: [], totalElements: 0, totalPages: 0 } });
    });

    it('should handle partial filters', () => {
      service.getVehicles(0, 15, { search: 'ABC' }).subscribe();

      const req = httpMock.expectOne(
        (request) => request.url.includes('search=ABC') && !request.url.includes('status='),
      );
      req.flush({ success: true, data: { content: [], totalElements: 0, totalPages: 0 } });
    });

    it('should handle special characters in search', () => {
      service.getVehicles(0, 15, { search: 'ABC-123 #test' }).subscribe();

      const req = httpMock.expectOne((request) => request.url.includes('search='));
      req.flush({ success: true, data: { content: [], totalElements: 0, totalPages: 0 } });
    });
  });
});
