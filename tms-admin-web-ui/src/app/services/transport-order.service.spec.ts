import { HttpClientTestingModule, HttpTestingController } from '@angular/common/http/testing';
import { TestBed } from '@angular/core/testing';

import { TransportOrderService } from './transport-order.service';
import { AuthService } from './auth.service';

describe('TransportOrderService', () => {
  let service: TransportOrderService;
  let httpMock: HttpTestingController;
  let authServiceSpy: jasmine.SpyObj<AuthService>;

  beforeEach(() => {
    authServiceSpy = jasmine.createSpyObj<AuthService>('AuthService', ['getToken']);
    authServiceSpy.getToken.and.returnValue('test-token');

    TestBed.configureTestingModule({
      imports: [HttpClientTestingModule],
      providers: [{ provide: AuthService, useValue: authServiceSpy }],
    });

    service = TestBed.inject(TransportOrderService);
    httpMock = TestBed.inject(HttpTestingController);
  });

  afterEach(() => {
    httpMock.verify();
  });

  it('should return shipment types from plain array payload', () => {
    let result: string[] | undefined;

    service.getShipmentTypes().subscribe((types) => {
      result = types;
    });

    const req = httpMock.expectOne((request) =>
      request.url.endsWith('/admin/transportorders/types'),
    );
    expect(req.request.method).toBe('GET');
    req.flush(['FTL', 'LTL']);

    expect(result).toEqual(['FTL', 'LTL']);
  });

  it('should return shipment types from data.content payload', () => {
    let result: string[] | undefined;

    service.getShipmentTypes().subscribe((types) => {
      result = types;
    });

    const req = httpMock.expectOne((request) =>
      request.url.endsWith('/admin/transportorders/types'),
    );
    req.flush({ data: { content: ['EXPRESS', 'STANDARD'] } });

    expect(result).toEqual(['EXPRESS', 'STANDARD']);
  });

  it('should return empty array for non-iterable payload', () => {
    let result: string[] | undefined;

    service.getShipmentTypes().subscribe((types) => {
      result = types;
    });

    const req = httpMock.expectOne((request) =>
      request.url.endsWith('/admin/transportorders/types'),
    );
    req.flush({ data: { content: { value: 'not-array' } } });

    expect(result).toEqual([]);
  });

  it('should filter out non-string values in shipment type payload', () => {
    let result: string[] | undefined;

    service.getShipmentTypes().subscribe((types) => {
      result = types;
    });

    const req = httpMock.expectOne((request) =>
      request.url.endsWith('/admin/transportorders/types'),
    );
    req.flush({ data: { content: ['FTL', 10, null, 'LTL'] } });

    expect(result).toEqual(['FTL', 'LTL']);
  });
});
