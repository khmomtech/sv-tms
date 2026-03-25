/// <reference types="jasmine" />
import { HttpClientTestingModule } from '@angular/common/http/testing';
import type { ComponentFixture } from '@angular/core/testing';
import { TestBed } from '@angular/core/testing';
import { of } from 'rxjs';

import type { PartnerAdmin, PartnerCompany } from '../../../../models/partner.model';
import { PartnershipType } from '../../../../models/partner.model';
import { VendorService } from '../../../../services/vendor.service';

import { SubcontractorAdminsComponent } from './subcontractor-admins.component';

class MockVendorService {
  getAllPartners() {
    const companies: PartnerCompany[] = [
      { id: 1, companyName: 'ACME', partnershipType: PartnershipType.DRIVER_FLEET },
    ];
    return of(companies);
  }
  getCompanyAdmins(companyId: number) {
    const admins: PartnerAdmin[] = [
      {
        id: 10,
        userId: 7,
        partnerCompanyId: companyId,
        canManageDrivers: true,
        canManageCustomers: false,
        canViewReports: true,
        canManageSettings: false,
        isPrimary: false,
      },
    ];
    return of(admins);
  }
  assignAdminToCompany(payload: Partial<PartnerAdmin>) {
    return of({ ...payload, id: 99 });
  }
  updateAdminPermissions(adminId: number) {
    return of({ id: adminId });
  }
  removeAdmin(adminId: number) {
    return of(void 0);
  }
}

describe('SubcontractorAdminsComponent', () => {
  let component: SubcontractorAdminsComponent;
  let fixture: ComponentFixture<SubcontractorAdminsComponent>;

  beforeEach(async () => {
    await TestBed.configureTestingModule({
      imports: [HttpClientTestingModule, SubcontractorAdminsComponent],
      providers: [{ provide: VendorService, useClass: MockVendorService }],
    }).compileComponents();

    fixture = TestBed.createComponent(SubcontractorAdminsComponent);
    component = fixture.componentInstance;
    fixture.detectChanges();
  });

  it('should load companies on init', () => {
    const companies = component.companies();
    expect(companies.length).toBe(1);
    expect(companies[0].companyName).toBe('ACME');
  });

  it('should refresh admins when company selected', () => {
    component.selectedCompanyId = 1;
    component.refresh();
    const admins = component.admins();
    expect(admins.length).toBe(1);
    expect(admins[0].userId).toBe(7);
  });

  it('should assign admin and refresh', () => {
    component.selectedCompanyId = 1;
    component.newAdmin = { userId: 123, canManageDrivers: true } as any;
    component.assignAdmin();
    const admins = component.admins();
    expect(Array.isArray(admins)).toBeTrue();
  });

  it('should remove admin', () => {
    component.selectedCompanyId = 1;
    component.refresh();
    const current = component.admins();
    expect(current.length).toBeGreaterThan(0);
    component.removeAdmin(current[0]);
    // Just ensure no crash and loading cleared
    expect(component.loading()).toBeFalse();
  });
});
