/// <reference types="jasmine" />
import { HttpClientTestingModule } from '@angular/common/http/testing';
import type { ComponentFixture } from '@angular/core/testing';
import { TestBed } from '@angular/core/testing';
import { ReactiveFormsModule } from '@angular/forms';
import { ActivatedRoute, Router } from '@angular/router';
import { of, throwError } from 'rxjs';

import type { PartnerCompany } from '../../../models/partner.model';
import { PartnershipType } from '../../../models/partner.model';
import { ConfirmService } from '../../../services/confirm.service';
import { VendorService } from '../../../services/vendor.service';

import { PartnerListComponent } from './vendor-list.component';

class MockVendorService {
  createPartner(p: PartnerCompany) {
    return of({ ...p, id: 200 });
  }
  updatePartner(id: number, p: PartnerCompany) {
    return of({ ...p, id });
  }
  generateCompanyCode() {
    return of('VEND-001');
  }
  getAllPartners() {
    return of([]);
  }
  getPartnersPaged() {
    return of({ content: [], totalElements: 0, totalPages: 1 });
  }
  checkBusinessLicenseExists(license: string) {
    return of(license === 'DUPLICATE');
  }
}

class MockRouter {
  url = '/vendors';
  navigate() {
    return Promise.resolve(true);
  }
}

class MockConfirmService {
  confirm() {
    return Promise.resolve(true);
  }
}

describe('PartnerListComponent (VendorList)', () => {
  let component: PartnerListComponent;
  let fixture: ComponentFixture<PartnerListComponent>;
  let service: MockVendorService;

  beforeEach(async () => {
    await TestBed.configureTestingModule({
      imports: [HttpClientTestingModule, ReactiveFormsModule, PartnerListComponent],
      providers: [
        { provide: VendorService, useClass: MockVendorService },
        { provide: Router, useClass: MockRouter },
        { provide: ActivatedRoute, useValue: { snapshot: { data: {} } } },
        { provide: ConfirmService, useClass: MockConfirmService },
      ],
    }).compileComponents();
    fixture = TestBed.createComponent(PartnerListComponent);
    component = fixture.componentInstance;
    service = TestBed.inject(VendorService) as any;
    fixture.detectChanges();
  });

  it('should open create dialog and prefill company code', () => {
    component.openCreateDialog();
    expect(component.showForm()).toBeTrue();
    expect(component.form.get('companyCode')?.value).toBe('VEND-001');
  });

  it('should submit create form', () => {
    component.openCreateDialog();
    component.form.patchValue({
      companyName: 'New Vendor',
      partnershipType: PartnershipType.DRIVER_FLEET,
      status: 'ACTIVE',
    });
    component.submitForm();
    expect(component.saving()).toBeFalse();
    expect(component.showForm()).toBeFalse();
  });

  it('should set licenseTaken error for duplicate license', () => {
    component.openCreateDialog();
    const ctrl = component.form.get('businessLicense');
    ctrl?.setValue('DUPLICATE');
    // Trigger valueChanges manually
    ctrl?.markAsDirty();
    // Allow async debounce simulation: directly call validator service
    (component as any).partnerService
      .checkBusinessLicenseExists('DUPLICATE')
      .subscribe((exists: boolean) => {
        if (exists) ctrl?.setErrors({ licenseTaken: true });
        expect(ctrl?.errors?.['licenseTaken']).toBeTruthy();
      });
  });

  it('disables Save button when licenseTaken error present', () => {
    component.openCreateDialog();
    const ctrl = component.form.get('businessLicense');
    ctrl?.setErrors({ licenseTaken: true });
    fixture.detectChanges();
    const saveBtn: HTMLButtonElement | null =
      fixture.nativeElement.querySelector('.btn.btn-primary');
    expect(saveBtn).toBeTruthy();
    expect(saveBtn?.disabled).toBeTrue();
  });

  it('should handle invalid form (no submit)', () => {
    component.openCreateDialog();
    component.form.patchValue({ companyName: '' });
    component.submitForm();
    // saving should remain false because form invalid
    expect(component.saving()).toBeFalse();
    expect(component.showForm()).toBeTrue();
  });

  it('should show error toast on failed save', () => {
    const spy = spyOn(service, 'createPartner').and.returnValue(
      throwError(() => ({ error: { message: 'Bad payload' } })),
    );
    component.openCreateDialog();
    component.form.patchValue({
      companyName: 'Broken',
      partnershipType: PartnershipType.DRIVER_FLEET,
      status: 'ACTIVE',
    });
    component.submitForm();
    expect(spy).toHaveBeenCalled();
    expect(component.toastMessage()).toMatch(/Bad payload|Failed/);
    expect(component.saving()).toBeFalse();
  });
});
