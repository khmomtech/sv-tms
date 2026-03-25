import { TestBed } from '@angular/core/testing';
import { HttpClientTestingModule, HttpTestingController } from '@angular/common/http/testing';

import { SafetyMasterDataService } from './safety-master-data.service';

describe('SafetyMasterDataService', () => {
  let service: SafetyMasterDataService;
  let httpMock: HttpTestingController;

  beforeEach(() => {
    TestBed.configureTestingModule({
      imports: [HttpClientTestingModule],
    });

    service = TestBed.inject(SafetyMasterDataService);
    httpMock = TestBed.inject(HttpTestingController);
  });

  afterEach(() => {
    httpMock.verify();
  });

  it('should call PUT category endpoint for setCategoryActive', () => {
    service.setCategoryActive(11, false).subscribe();

    const req = httpMock.expectOne((request) => {
      return (
        request.method === 'PUT' &&
        request.url.endsWith('/admin/safety-master/categories/11') &&
        request.body?.isActive === false
      );
    });
    expect(req.request.method).toBe('PUT');
    expect(req.request.body).toEqual({ isActive: false });

    req.flush({ success: true, data: { id: 11, isActive: false } });
  });

  it('should call PUT item endpoint for setItemActive', () => {
    service.setItemActive(22, true).subscribe();

    const req = httpMock.expectOne((request) => {
      return (
        request.method === 'PUT' &&
        request.url.endsWith('/admin/safety-master/items/22') &&
        request.body?.isActive === true
      );
    });
    expect(req.request.method).toBe('PUT');
    expect(req.request.body).toEqual({ isActive: true });

    req.flush({ success: true, data: { id: 22, isActive: true } });
  });
});
