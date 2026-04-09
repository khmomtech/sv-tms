import { ComponentFixture, TestBed } from '@angular/core/testing';
import { NoopAnimationsModule } from '@angular/platform-browser/animations';
import { MAT_DIALOG_DATA, MatDialogRef } from '@angular/material/dialog';

import { AlertTypeEnum, GeofenceType, type Geofence } from '../../models/geofence.model';
import type { GeofenceCreateRequest } from '../../models/geofence.model';
import { GeofenceFormDialogComponent } from './geofence-form-dialog.component';
import type { GeofenceFormDialogData } from './geofence-form-dialog.component';

describe('GeofenceFormDialogComponent', () => {
  let component: GeofenceFormDialogComponent;
  let fixture: ComponentFixture<GeofenceFormDialogComponent>;
  let dialogRefSpy: jasmine.SpyObj<MatDialogRef<GeofenceFormDialogComponent>>;

  const COMPANY_ID = 1;

  const mockExistingGeofence: Geofence = {
    id: 42,
    name: 'Warehouse A',
    description: 'Main depot',
    type: GeofenceType.CIRCLE,
    centerLatitude: 11.5564,
    centerLongitude: 104.9282,
    radiusMeters: 500,
    alertType: AlertTypeEnum.BOTH,
    active: true,
    tags: ['warehouse', 'restricted'],
    createdAt: '2026-01-01T00:00:00',
    updatedAt: '2026-01-01T00:00:00',
  };

  function createComponent(
    dialogData: GeofenceFormDialogData,
  ): ComponentFixture<GeofenceFormDialogComponent> {
    dialogRefSpy = jasmine.createSpyObj('MatDialogRef', ['close']);

    TestBed.configureTestingModule({
      imports: [GeofenceFormDialogComponent, NoopAnimationsModule],
      providers: [
        { provide: MatDialogRef, useValue: dialogRefSpy },
        { provide: MAT_DIALOG_DATA, useValue: dialogData },
      ],
    });

    const f = TestBed.createComponent(GeofenceFormDialogComponent);
    f.componentInstance.ngOnInit();
    f.detectChanges();
    return f;
  }

  afterEach(() => {
    TestBed.resetTestingModule();
  });

  // ─── Create mode ─────────────────────────────────────────────────────────

  describe('create mode (no existing geofence)', () => {
    beforeEach(() => {
      fixture = createComponent({ companyId: COMPANY_ID, type: GeofenceType.CIRCLE });
      component = fixture.componentInstance;
    });

    it('should create', () => {
      expect(component).toBeTruthy();
    });

    it('editMode should be false', () => {
      expect(component.editMode).toBeFalse();
    });

    it('form should build with default CIRCLE type', () => {
      expect(component.form.get('type')?.value).toBe(GeofenceType.CIRCLE);
    });

    it('form should build with BOTH as default alertType', () => {
      expect(component.form.get('alertType')?.value).toBe(AlertTypeEnum.BOTH);
    });

    it('form should build with active = true by default', () => {
      expect(component.form.get('active')?.value).toBeTrue();
    });

    it('isCircleType getter returns true for CIRCLE type', () => {
      expect(component.isCircleType).toBeTrue();
    });

    it('isPolygonType getter returns false for CIRCLE type', () => {
      expect(component.isPolygonType).toBeFalse();
    });

    it('onCancel closes dialog without value', () => {
      component.onCancel();
      expect(dialogRefSpy.close).toHaveBeenCalledWith();
    });

    it('onSave marks fields as touched when form is invalid', () => {
      // Name is empty, form is invalid
      component.form.get('name')?.setValue('');
      component.onSave();
      expect(component.form.get('name')?.touched).toBeTrue();
      expect(dialogRefSpy.close).not.toHaveBeenCalled();
    });

    it('onSave closes dialog with GeofenceCreateRequest for valid CIRCLE form', () => {
      component.form.patchValue({
        name: 'New Zone',
        type: GeofenceType.CIRCLE,
        centerLatitude: 11.5564,
        centerLongitude: 104.9282,
        radiusMeters: 500,
        alertType: AlertTypeEnum.ENTER,
        active: true,
        tags: '',
      });

      component.onSave();

      expect(dialogRefSpy.close).toHaveBeenCalledOnceWith(
        jasmine.objectContaining<GeofenceCreateRequest>({
          partnerCompanyId: COMPANY_ID,
          name: 'New Zone',
          type: GeofenceType.CIRCLE,
          centerLatitude: 11.5564,
          centerLongitude: 104.9282,
          radiusMeters: 500,
          alertType: AlertTypeEnum.ENTER,
          active: true,
          tags: undefined,
        }),
      );
    });

    it('onSave strips centerLat/Lng/radius when type is POLYGON', () => {
      component.form.patchValue({
        name: 'Poly Zone',
        type: GeofenceType.POLYGON,
        geoJsonCoordinates: '[[11.5,104.9],[11.5,104.95],[11.55,104.95]]',
        alertType: AlertTypeEnum.EXIT,
        active: true,
      });

      component.onSave();

      const payload = dialogRefSpy.close.calls.mostRecent().args[0] as GeofenceCreateRequest;
      expect(payload.centerLatitude).toBeUndefined();
      expect(payload.centerLongitude).toBeUndefined();
      expect(payload.radiusMeters).toBeUndefined();
      expect(payload.geoJsonCoordinates).toBeTruthy();
    });

    it('onSave parses comma-separated tags into array', () => {
      component.form.patchValue({
        name: 'Tagged Zone',
        type: GeofenceType.CIRCLE,
        centerLatitude: 11.5564,
        centerLongitude: 104.9282,
        radiusMeters: 500,
        alertType: AlertTypeEnum.NONE,
        active: true,
        tags: 'warehouse, restricted, depot',
      });

      component.onSave();

      const payload = dialogRefSpy.close.calls.mostRecent().args[0] as GeofenceCreateRequest;
      expect(payload.tags).toEqual(['warehouse', 'restricted', 'depot']);
    });

    it('onSave sets tags to undefined when tag field is empty', () => {
      component.form.patchValue({
        name: 'No Tags Zone',
        type: GeofenceType.CIRCLE,
        centerLatitude: 11.5,
        centerLongitude: 104.9,
        radiusMeters: 100,
        alertType: AlertTypeEnum.NONE,
        active: true,
        tags: '',
      });

      component.onSave();

      const payload = dialogRefSpy.close.calls.mostRecent().args[0] as GeofenceCreateRequest;
      expect(payload.tags).toBeUndefined();
    });
  });

  // ─── Edit mode ────────────────────────────────────────────────────────────

  describe('edit mode (existing geofence provided)', () => {
    beforeEach(() => {
      fixture = createComponent({ companyId: COMPANY_ID, geofence: mockExistingGeofence });
      component = fixture.componentInstance;
    });

    it('editMode should be true', () => {
      expect(component.editMode).toBeTrue();
    });

    it('form should pre-populate name from existing geofence', () => {
      expect(component.form.get('name')?.value).toBe('Warehouse A');
    });

    it('form should pre-populate type from existing geofence', () => {
      expect(component.form.get('type')?.value).toBe(GeofenceType.CIRCLE);
    });

    it('form should pre-populate centerLatitude from existing geofence', () => {
      expect(component.form.get('centerLatitude')?.value).toBe(11.5564);
    });

    it('form should pre-populate radiusMeters from existing geofence', () => {
      expect(component.form.get('radiusMeters')?.value).toBe(500);
    });

    it('form should pre-populate alertType from existing geofence', () => {
      expect(component.form.get('alertType')?.value).toBe(AlertTypeEnum.BOTH);
    });

    it('form should join tags array into comma-separated string', () => {
      expect(component.form.get('tags')?.value).toBe('warehouse, restricted');
    });

    it('onSave closes dialog with updated GeofenceCreateRequest', () => {
      component.form.patchValue({ name: 'Warehouse A — Updated', radiusMeters: 750 });

      component.onSave();

      const payload = dialogRefSpy.close.calls.mostRecent().args[0] as GeofenceCreateRequest;
      expect(payload.name).toBe('Warehouse A — Updated');
      expect(payload.radiusMeters).toBe(750);
      expect(payload.partnerCompanyId).toBe(COMPANY_ID);
    });
  });

  // ─── Type switching ───────────────────────────────────────────────────────

  describe('type switching updates validators', () => {
    beforeEach(() => {
      fixture = createComponent({ companyId: COMPANY_ID });
      component = fixture.componentInstance;
    });

    it('switching to POLYGON makes geoJsonCoordinates required', () => {
      component.form.get('type')?.setValue(GeofenceType.POLYGON);
      component.form.get('geoJsonCoordinates')?.setValue(null);
      expect(component.form.get('geoJsonCoordinates')?.errors?.['required']).toBeTruthy();
    });

    it('switching back to CIRCLE clears geoJson validators', () => {
      component.form.get('type')?.setValue(GeofenceType.POLYGON);
      component.form.get('type')?.setValue(GeofenceType.CIRCLE);
      component.form.get('geoJsonCoordinates')?.setValue(null);
      expect(component.form.get('geoJsonCoordinates')?.errors?.['required']).toBeFalsy();
    });

    it('isCircleType returns false for POLYGON', () => {
      component.form.get('type')?.setValue(GeofenceType.POLYGON);
      expect(component.isCircleType).toBeFalse();
    });

    it('isPolygonType returns true for POLYGON', () => {
      component.form.get('type')?.setValue(GeofenceType.POLYGON);
      expect(component.isPolygonType).toBeTrue();
    });
  });

  // ─── Error messages ───────────────────────────────────────────────────────

  describe('getErrorMessage', () => {
    beforeEach(() => {
      fixture = createComponent({ companyId: COMPANY_ID });
      component = fixture.componentInstance;
    });

    it('returns required message for required error', () => {
      component.form.get('name')?.setValue('');
      component.form.get('name')?.markAsTouched();
      expect(component.getErrorMessage('name')).toBe('This field is required');
    });

    it('returns maxlength message for maxlength error', () => {
      component.form.get('name')?.setValue('a'.repeat(101));
      component.form.get('name')?.markAsTouched();
      expect(component.getErrorMessage('name')).toContain('100 characters');
    });

    it('returns empty string when no error', () => {
      component.form.get('name')?.setValue('Valid Name');
      expect(component.getErrorMessage('name')).toBe('');
    });

    it('returns latitude range message for invalid latitude', () => {
      component.form.get('type')?.setValue(GeofenceType.CIRCLE);
      component.form.get('centerLatitude')?.setValue(999);
      component.form.get('centerLatitude')?.markAsTouched();
      expect(component.getErrorMessage('centerLatitude')).toContain('-90 and 90');
    });
  });
});
