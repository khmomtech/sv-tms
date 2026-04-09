import { TestBed, fakeAsync, tick } from '@angular/core/testing';
import { HttpClientTestingModule, HttpTestingController } from '@angular/common/http/testing';
import { VehicleDriverService } from './vehicle-driver.service';
import type {
  AssignmentRequest,
  AssignmentResponse,
  ApiResponse,
  AssignmentStats,
} from './vehicle-driver.service';
import { environment } from '../../environments/environment';

describe('VehicleDriverService', () => {
  let service: VehicleDriverService;
  let httpMock: HttpTestingController;
  const baseUrl = `${environment.apiBaseUrl}/admin/assignments/permanent`;

  beforeEach(() => {
    TestBed.configureTestingModule({
      imports: [HttpClientTestingModule],
      providers: [VehicleDriverService],
    });
    service = TestBed.inject(VehicleDriverService);
    httpMock = TestBed.inject(HttpTestingController);
  });

  afterEach(() => {
    httpMock.verify(); // Verify no outstanding requests
  });

  describe('assignTruckToDriver', () => {
    it('should successfully assign truck to driver', (done) => {
      const request: AssignmentRequest = {
        vehicleId: 1,
        driverId: 2,
        reason: 'Test Assignment',
        forceReassignment: false,
      };

      const mockResponse: AssignmentResponse = {
        id: 100,
        vehicleId: 1,
        driverId: 2,
        truckPlate: 'ABC-123',
        driverName: 'John Doe',
        assignedAt: new Date().toISOString(),
        assignedBy: 'admin',
        reason: 'Test Assignment',
        active: true,
        version: 0,
      };

      service.assignTruckToDriver(request).subscribe({
        next: (response) => {
          expect(response.data).toEqual(mockResponse);
          expect(response.data.vehicleId).toBe(1);
          expect(response.data.driverId).toBe(2);
          expect(response.data.active).toBe(true);
          done();
        },
        error: done.fail,
      });

      const req = httpMock.expectOne(`${baseUrl}`);
      expect(req.request.method).toBe('POST');
      expect(req.request.body).toEqual(request);
      req.flush({
        success: true,
        data: mockResponse,
        message: 'Assignment created',
        timestamp: new Date().toISOString(),
      });
    });

    it('maps driverFullName into driverName for compatibility', (done) => {
      const request: AssignmentRequest = {
        vehicleId: 1,
        driverId: 2,
        reason: 'Compatibility Test',
        forceReassignment: false,
      };

      service.assignTruckToDriver(request).subscribe({
        next: (response) => {
          expect(response.data.driverName).toBe('Legacy Full Name');
          done();
        },
        error: done.fail,
      });

      const req = httpMock.expectOne(`${baseUrl}`);
      req.flush({
        success: true,
        data: {
          id: 100,
          vehicleId: 1,
          driverId: 2,
          truckPlate: 'ABC-123',
          driverFullName: 'Legacy Full Name',
          assignedAt: new Date().toISOString(),
          assignedBy: 'admin',
          active: true,
          version: 0,
        },
        message: 'Assignment created',
        timestamp: new Date().toISOString(),
      });
    });

    it('should handle 409 conflict error', (done) => {
      const request: AssignmentRequest = {
        vehicleId: 1,
        driverId: 2,
        reason: 'Test',
        forceReassignment: false,
      };

      service.assignTruckToDriver(request).subscribe({
        next: () => done.fail('Should have failed'),
        error: (error: any) => {
          expect(error.type).toBe('backend');
          expect(error.status).toBe(409);
          done();
        },
      });

      const req = httpMock.expectOne(`${baseUrl}`);
      req.flush(
        { error: 'Conflict', message: 'Truck is already assigned' },
        { status: 409, statusText: 'Conflict' },
      );
    });

    it('should retry on 5xx server errors', fakeAsync(() => {
      const request: AssignmentRequest = {
        vehicleId: 1,
        driverId: 2,
        reason: 'Test',
        forceReassignment: false,
      };

      let attemptCount = 0;
      let receivedError: any;

      service.assignTruckToDriver(request).subscribe({
        next: () => fail('Should have failed after retries'),
        error: (error: any) => {
          receivedError = error;
        },
      });

      const req1 = httpMock.expectOne(`${baseUrl}`);
      attemptCount++;
      req1.flush(
        { status: 'error', message: 'Internal server error' },
        { status: 500, statusText: 'Internal Server Error' },
      );

      tick(1000);
      const req2 = httpMock.expectOne(`${baseUrl}`);
      attemptCount++;
      req2.flush(
        { status: 'error', message: 'Internal server error' },
        { status: 500, statusText: 'Internal Server Error' },
      );

      tick(2000);
      const req3 = httpMock.expectOne(`${baseUrl}`);
      attemptCount++;
      req3.flush(
        { status: 'error', message: 'Internal server error' },
        { status: 500, statusText: 'Internal Server Error' },
      );

      tick();
      expect(receivedError.status).toBe(500);
      expect(attemptCount).toBeGreaterThan(1);
    }));

    it('should timeout after 30 seconds', fakeAsync(() => {
      const request: AssignmentRequest = {
        vehicleId: 1,
        driverId: 2,
        reason: 'Test',
        forceReassignment: false,
      };

      let receivedError: any;
      service.assignTruckToDriver(request).subscribe({
        next: () => fail('Should have timed out'),
        error: (error: any) => {
          receivedError = error;
        },
      });

      const req1 = httpMock.expectOne(`${baseUrl}`);
      tick(30001);

      tick(1000);
      const req2 = httpMock.expectOne(`${baseUrl}`);
      tick(30001);

      tick(2000);
      const req3 = httpMock.expectOne(`${baseUrl}`);
      tick(30001);

      expect(receivedError).toBeDefined();
    }));
  });

  describe('revokeDriverAssignment', () => {
    it('should successfully revoke assignment', (done) => {
      const driverId = 100;

      service.revokeDriverAssignment(driverId).subscribe({
        next: () => {
          expect(true).toBe(true);
          done();
        },
        error: done.fail,
      });

      const req = httpMock.expectOne(`${baseUrl}/${driverId}`);
      expect(req.request.method).toBe('DELETE');
      req.flush({
        success: true,
        data: null,
        message: 'Assignment revoked',
        timestamp: new Date().toISOString(),
      });
    });

    it('should handle 404 when assignment not found', (done) => {
      const driverId = 99999;

      service.revokeDriverAssignment(driverId).subscribe({
        next: () => done.fail('Should have failed'),
        error: (error: any) => {
          expect(error.status).toBe(404);
          done();
        },
      });

      const req = httpMock.expectOne(`${baseUrl}/${driverId}`);
      req.flush(
        { error: 'Not Found', message: 'Assignment not found' },
        { status: 404, statusText: 'Not Found' },
      );
    });
  });

  describe('getAssignmentStats', () => {
    it('should fetch assignment statistics', (done) => {
      const mockStats: AssignmentStats = {
        activeCount: 50,
        revokedCount: 10,
        totalCount: 60,
      };

      service.getAssignmentStats().subscribe({
        next: (stats) => {
          expect(stats.data).toEqual(mockStats);
          expect(stats.data.activeCount).toBe(50);
          expect(stats.data.totalCount).toBe(60);
          done();
        },
        error: done.fail,
      });

      const req = httpMock.expectOne(`${baseUrl}/stats`);
      expect(req.request.method).toBe('GET');
      req.flush({
        success: true,
        data: mockStats,
        message: '',
        timestamp: new Date().toISOString(),
      });
    });
  });

  describe('Error Handling', () => {
    it('should handle network errors', fakeAsync(() => {
      const request: AssignmentRequest = {
        vehicleId: 1,
        driverId: 2,
        reason: 'Test',
        forceReassignment: false,
      };

      let receivedError: any;
      service.assignTruckToDriver(request).subscribe({
        next: () => fail('Should have failed'),
        error: (error: any) => {
          receivedError = error;
        },
      });

      const req1 = httpMock.expectOne(`${baseUrl}`);
      req1.error(new ProgressEvent('Network error'));

      tick(1000);
      const req2 = httpMock.expectOne(`${baseUrl}`);
      req2.error(new ProgressEvent('Network error'));

      tick(2000);
      const req3 = httpMock.expectOne(`${baseUrl}`);
      req3.error(new ProgressEvent('Network error'));

      tick();
      expect(receivedError).toBeDefined();
    }));

    it('should include request ID in headers', (done) => {
      const request: AssignmentRequest = {
        vehicleId: 1,
        driverId: 2,
        reason: 'Test',
        forceReassignment: false,
      };

      service.assignTruckToDriver(request).subscribe();

      const req = httpMock.expectOne(`${baseUrl}`);
      expect(req.request.headers.has('X-Request-ID')).toBe(true);
      req.flush({ success: true, data: {}, message: '', timestamp: new Date().toISOString() });
      done();
    });

    it('should keep user-friendly message while preserving backend message details', (done) => {
      service.getAssignments().subscribe({
        next: () => fail('Should have failed'),
        error: (error: any) => {
          expect(error.message).toContain('An unexpected error occurred');
          expect(error.backendMessage).toContain('An unexpected error occurred');
          expect(error.requestId).toBe('assign-1234567890-abc');
          done();
        },
      });

      const req = httpMock.expectOne((r) => r.url === `${baseUrl}/list`);
      req.flush(
        {
          success: false,
          message:
            'An unexpected error occurred. Please contact support with request ID: assign-1234567890-abc',
          timestamp: new Date().toISOString(),
        },
        { status: 500, statusText: 'Internal Server Error' },
      );
    });
  });

  describe('getAssignments', () => {
    it('maps driverFullName into driverName for assignment list rows', (done) => {
      service.getAssignments().subscribe({
        next: (response) => {
          expect(response.data.length).toBe(1);
          expect(response.data[0].driverName).toBe('List Driver Full');
          done();
        },
        error: done.fail,
      });

      const req = httpMock.expectOne((r) => r.url === `${baseUrl}/list`);
      req.flush({
        success: true,
        data: [
          {
            id: 1,
            vehicleId: 1,
            driverId: 2,
            truckPlate: 'KH-1',
            driverFullName: 'List Driver Full',
            assignedAt: new Date().toISOString(),
            assignedBy: 'admin',
            active: true,
            version: 0,
          },
        ],
        message: '',
        timestamp: new Date().toISOString(),
      });
    });
  });
});
