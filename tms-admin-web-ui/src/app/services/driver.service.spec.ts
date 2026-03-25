import { HttpClientTestingModule, HttpTestingController } from '@angular/common/http/testing';
import { TestBed } from '@angular/core/testing';
import { MatSnackBarModule } from '@angular/material/snack-bar';

import { environment } from '../../environments/environment';

import { AuthService } from './auth.service';
import { DriverService } from './driver.service';

class MockAuthService {
  token: string | null = 'test-token-123';
  getToken() {
    return this.token;
  }
}

describe('DriverService', () => {
  let service: DriverService;
  let httpMock: HttpTestingController;
  let auth: MockAuthService;

  beforeEach(() => {
    TestBed.configureTestingModule({
      imports: [HttpClientTestingModule, MatSnackBarModule],
      providers: [DriverService, { provide: AuthService, useClass: MockAuthService }],
    });
    service = TestBed.inject(DriverService);
    httpMock = TestBed.inject(HttpTestingController);
    auth = TestBed.inject(AuthService) as any;
  });

  afterEach(() => {
    httpMock.verify();
  });

  describe('buildDocumentFileUrl', () => {
    it('should return empty string for undefined/null', () => {
      expect(service.buildDocumentFileUrl(undefined)).toBe('');
      expect(service.buildDocumentFileUrl(null)).toBe('');
    });

    it('should append token to absolute URL if missing', () => {
      const raw = 'https://files.example.com/doc.pdf';
      const built = service.buildDocumentFileUrl(raw);
      expect(built).toContain(raw);
      expect(built).toMatch(/token=test-token-123/);
    });

    it('should not duplicate token on absolute URL already containing token', () => {
      const raw = 'https://files.example.com/doc.pdf?token=existing';
      const built = service.buildDocumentFileUrl(raw);
      const matches = built.match(/token=/g) || [];
      expect(matches.length).toBe(1);
    });

    it('should normalize relative path without leading slash', () => {
      const raw = 'uploads/documents/4/file.pdf';
      const built = service.buildDocumentFileUrl(raw);
      expect(built).toContain(environment.apiBaseUrl.replace(/\/$/, '')); // base prefix
      expect(built).toMatch(/token=test-token-123/);
    });

    it('should handle relative path starting with slash', () => {
      const raw = '/uploads/documents/4/file.pdf';
      const built = service.buildDocumentFileUrl(raw);
      expect(built).toContain(environment.apiBaseUrl.replace(/\/$/, ''));
      expect(built).toMatch(/token=test-token-123/);
    });

    it('should handle relative path with existing query string', () => {
      const raw = 'documents/4/file.pdf?version=1';
      const built = service.buildDocumentFileUrl(raw);
      expect(built).toContain('version=1');
      expect(built).toMatch(/&token=test-token-123/);
    });
  });

  describe('downloadDriverDocument', () => {
    it('should call correct download URL and return blob', () => {
      const driverId = 7;
      const documentId = 42;
      let receivedBlob: Blob | null = null;

      service.downloadDriverDocument(driverId, documentId).subscribe((blob) => {
        receivedBlob = blob;
      });

      const req = httpMock.expectOne(
        `${environment.apiBaseUrl}/admin/drivers/${driverId}/documents/${documentId}/download`,
      );
      expect(req.request.method).toBe('GET');
      expect(req.request.responseType).toBe('blob');
      req.flush(new Blob(['content'], { type: 'application/pdf' }));

      expect(receivedBlob).toBeTruthy();
      expect(receivedBlob!.size).toBeGreaterThan(0);
    });
  });

  describe('getAdvancedDrivers', () => {
    it('should call advanced search endpoint with correct parameters', () => {
      const filter = {
        query: 'john',
        status: 'online',
        vehicleType: 'truck',
        zone: 'downtown',
        minRating: 4.0,
        maxRating: 5.0,
      };
      const mockDrivers = [
        { id: 1, name: 'John Doe', rating: 4.5, status: 'online' },
        { id: 2, name: 'Jane Smith', rating: 4.8, status: 'online' },
      ];

      service.getAdvancedDrivers(filter).subscribe((response) => {
        expect(response).toEqual({ success: true, data: mockDrivers });
      });

      const req = httpMock.expectOne(
        (request) =>
          request.url.includes('/admin/drivers/advanced-search') &&
          request.params.get('query') === 'john' &&
          request.params.get('status') === 'online' &&
          request.params.get('vehicleType') === 'truck' &&
          request.params.get('zone') === 'downtown' &&
          request.params.get('minRating') === '4' &&
          request.params.get('maxRating') === '5',
      );
      expect(req.request.method).toBe('GET');
      req.flush({ success: true, data: mockDrivers });
    });

    it('should handle empty filter object', () => {
      const filter = {};
      const mockDrivers = [{ id: 1, name: 'Test Driver' }];

      service.getAdvancedDrivers(filter).subscribe((response) => {
        expect(response).toEqual({ success: true, data: mockDrivers });
      });

      const req = httpMock.expectOne(`${environment.apiBaseUrl}/admin/drivers/advanced-search`);
      expect(req.request.method).toBe('GET');
      expect(req.request.params.keys().length).toBe(0);
      req.flush({ success: true, data: mockDrivers });
    });

    it('should handle rating range filters correctly', () => {
      const filter = { minRating: 3.5, maxRating: 4.5 };
      const mockDrivers = [{ id: 1, name: 'Rated Driver', rating: 4.0 }];

      service.getAdvancedDrivers(filter).subscribe((response) => {
        expect(response).toEqual({ success: true, data: mockDrivers });
      });

      const req = httpMock.expectOne(
        (request) =>
          request.params.get('minRating') === '3.5' && request.params.get('maxRating') === '4.5',
      );
      req.flush({ success: true, data: mockDrivers });
    });
  });

  describe('buildFilterParams', () => {
    it('should build HttpParams from filter object', () => {
      const filter = {
        query: 'test',
        status: 'active',
        minRating: 4.0,
        maxRating: 5.0,
      };

      const params = (service as any).buildFilterParams(filter);

      expect(params.get('query')).toBe('test');
      expect(params.get('status')).toBe('active');
      expect(params.get('minRating')).toBe('4');
      expect(params.get('maxRating')).toBe('5');
    });

    it('should exclude undefined and null values', () => {
      const filter = {
        query: 'test',
        status: undefined,
        zone: null,
        minRating: 4.0,
      };

      const params = (service as any).buildFilterParams(filter);

      expect(params.get('query')).toBe('test');
      expect(params.get('status')).toBeNull();
      expect(params.get('zone')).toBeNull();
      expect(params.get('minRating')).toBe('4');
    });

    it('should convert numbers to strings', () => {
      const filter = { minRating: 4.5, maxRating: 5.0 };
      const params = (service as any).buildFilterParams(filter);

      expect(params.get('minRating')).toBe('4.5');
      expect(params.get('maxRating')).toBe('5');
    });
  });
});
