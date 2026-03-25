/* eslint-disable */
// @ts-nocheck
import { HttpClientTestingModule, HttpTestingController } from '@angular/common/http/testing';
import { TestBed } from '@angular/core/testing';

import { environment } from '../../environments/environment';
import { PartnerService } from './partner.service';

describe('PartnerService', () => {
  let service: PartnerService;
  let httpMock: HttpTestingController;
  const partnerBase = `${environment.apiBaseUrl}/${environment.useVendorApiPaths ? 'vendors' : 'partners'}`;

  beforeEach(() => {
    TestBed.configureTestingModule({
      imports: [HttpClientTestingModule],
      providers: [PartnerService],
    });

    service = TestBed.inject(PartnerService);
    httpMock = TestBed.inject(HttpTestingController);
  });

  afterEach(() => {
    httpMock.verify();
  });

  it('should GET company admins', () => {
    const companyId = 42;
    const mock = {
      data: [
        {
          userId: 7,
          partnerCompanyId: companyId,
          canManageDrivers: true,
          canManageCustomers: false,
          canViewReports: true,
          canManageSettings: false,
          isPrimary: false,
        },
      ],
    };
    service.getCompanyAdmins(companyId).subscribe((res) => {
      expect(res.length).toBe(1);
      expect(res[0].userId).toBe(7);
    });
    const req = httpMock.expectOne(`${environment.apiBaseUrl}/partner-admins/company/${companyId}`);
    expect(req.request.method).toBe('GET');
    req.flush(mock);
  });

  it('should map null admin list to empty array', () => {
    const companyId = 99;
    const mock = { data: null };
    service.getCompanyAdmins(companyId).subscribe((res) => {
      expect(Array.isArray(res)).toBeTrue();
      expect(res.length).toBe(0);
    });
    const req = httpMock.expectOne(`${environment.apiBaseUrl}/partner-admins/company/${companyId}`);
    req.flush(mock);
  });

  it('should GET all partners', () => {
    const mock = { data: [{ id: 1, companyName: 'ACME', partnershipType: 'DRIVER_FLEET' }] };
    service.getAllPartners().subscribe((res) => {
      expect(res.length).toBe(1);
      expect(res[0].companyName).toBe('ACME');
    });
    const req = httpMock.expectOne(partnerBase);
    expect(req.request.method).toBe('GET');
    req.flush(mock);
  });

  it('should GET partner by id', () => {
    const id = 5;
    const mock = { data: { id, companyName: 'Beta Ltd', partnershipType: 'CUSTOMER_CORPORATE' } };
    service.getPartnerById(id).subscribe((res) => {
      expect(res.id).toBe(id);
      expect(res.companyName).toBe('Beta Ltd');
    });
    const req = httpMock.expectOne(`${partnerBase}/${id}`);
    expect(req.request.method).toBe('GET');
    req.flush(mock);
  });

  it('should assign, update, and remove admin', () => {
    const adminPayload = { userId: 11, partnerCompanyId: 2 } as any;

    // assign
    service.assignAdminToCompany(adminPayload).subscribe((res) => {
      expect(res.userId).toBe(11);
    });
    let req = httpMock.expectOne(`${environment.apiBaseUrl}/partner-admins`);
    expect(req.request.method).toBe('POST');
    req.flush({ data: { ...adminPayload, isPrimary: false } });

    // update permissions
    const adminId = 77;
    const permissions = {
      canManageDrivers: true,
      canManageCustomers: true,
      canViewReports: false,
      canManageSettings: false,
    };
    service.updateAdminPermissions(adminId, permissions).subscribe((res) => {
      expect(res.isPrimary).toBeDefined();
    });
    req = httpMock.expectOne(`${environment.apiBaseUrl}/partner-admins/${adminId}/permissions`);
    expect(req.request.method).toBe('PATCH');
    req.flush({ data: { id: adminId, ...adminPayload, ...permissions, isPrimary: false } });

    // remove
    service.removeAdmin(adminId).subscribe((res) => {
      expect(res).toBeUndefined();
    });
    req = httpMock.expectOne(`${environment.apiBaseUrl}/partner-admins/${adminId}`);
    expect(req.request.method).toBe('DELETE');
    req.flush({});
  });

  it('should create partner', () => {
    const payload: any = {
      companyName: 'NewCo',
      partnershipType: 'DRIVER_FLEET',
      status: 'ACTIVE',
    };
    service.createPartner(payload).subscribe((res) => {
      expect(res.companyName).toBe('NewCo');
    });
    const req = httpMock.expectOne(partnerBase);
    expect(req.request.method).toBe('POST');
    req.flush({ data: { id: 101, ...payload } });
  });

  it('should update partner', () => {
    const id = 55;
    const payload: any = {
      companyName: 'UpdatedCo',
      partnershipType: 'CUSTOMER_CORPORATE',
      status: 'ACTIVE',
    };
    service.updatePartner(id, payload).subscribe((res) => {
      expect(res.id).toBe(id);
      expect(res.companyName).toBe('UpdatedCo');
    });
    const req = httpMock.expectOne(`${partnerBase}/${id}`);
    expect(req.request.method).toBe('PUT');
    req.flush({ data: { id, ...payload } });
  });

  it('should handle missing createPartner data gracefully', () => {
    const payload: any = {
      companyName: 'BrokenCo',
      partnershipType: 'DRIVER_FLEET',
      status: 'ACTIVE',
    };
    service.createPartner(payload).subscribe((res) => {
      expect(res).toBeNull();
    });
    const req = httpMock.expectOne(partnerBase);
    req.flush({ data: null });
  });

  it('should GET active partners', () => {
    const mock = { data: [{ id: 1, companyName: 'ACME', partnershipType: 'DRIVER_FLEET' }] };
    service.getActivePartners().subscribe((res) => {
      expect(res.length).toBe(1);
      expect(res[0].companyName).toBe('ACME');
    });

    const req = httpMock.expectOne(`${partnerBase}/active`);
    expect(req.request.method).toBe('GET');
    req.flush(mock);
  });

  it('should POST create customer account', () => {
    const payload = { username: 'user1', email: 'u@example.com', password: 'secret' };
    const customerId = 42;
    const mock = { data: { id: 99 } };

    service.createCustomerAccount(customerId, payload).subscribe((res) => {
      expect(res.id).toBe(99);
    });

    const req = httpMock.expectOne(
      `${environment.apiBaseUrl}/admin/customers/${customerId}/account`,
    );
    expect(req.request.method).toBe('POST');
    expect(req.request.body).toEqual(payload);
    req.flush(mock);
  });

  it('should check business license exists (true)', () => {
    const license = 'ABC-123';
    service.checkBusinessLicenseExists(license).subscribe((exists) => {
      expect(exists).toBeTrue();
    });
    const req = httpMock.expectOne(
      `${environment.apiBaseUrl}/${environment.useVendorApiPaths ? 'vendors' : 'partners'}/license/${encodeURIComponent(license)}/exists`,
    );
    expect(req.request.method).toBe('GET');
    req.flush({ data: true });
  });

  it('should short-circuit checkBusinessLicenseExists on empty license', () => {
    service.checkBusinessLicenseExists('').subscribe((exists) => {
      expect(exists).toBeFalse();
    });
    // No HTTP request should be made
    httpMock.expectNone(/\/license\//);
  });
});
