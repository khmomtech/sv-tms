import { ComponentFixture, TestBed } from '@angular/core/testing';
import { ReactiveFormsModule } from '@angular/forms';
import { Router, ActivatedRoute } from '@angular/router';
import { HttpClientTestingModule, HttpTestingController } from '@angular/common/http/testing';
import { of, throwError } from 'rxjs';
import { NgSelectModule } from '@ng-select/ng-select';

import { IncidentFormComponent } from './incident-form.component';
import { IncidentService } from '../../services/incident.service';
import { DriverService } from '../../../../services/driver.service';
import { VehicleService } from '../../../../services/vehicle.service';
import { IncidentStatus, IncidentGroup, IssueSeverity } from '../../models/incident.model';
import { environment } from '../../../../environments/environment';

describe('IncidentFormComponent - API Integration', () => {
  let component: IncidentFormComponent;
  let fixture: ComponentFixture<IncidentFormComponent>;
  let httpMock: HttpTestingController;
  let router: Router;
  let incidentService: IncidentService;
  let driverService: DriverService;
  let vehicleService: VehicleService;
  const driversUrl = `${environment.apiBaseUrl}/admin/drivers/alllists?page=0&size=100`;
  const vehiclesUrl = `${environment.baseUrl}/api/admin/vehicles/search?page=0&size=100`;

  const mockDrivers = {
    data: {
      content: [
        { id: 1, name: 'John Doe', phone: '555-0001', employeeId: 'EMP001' },
        { id: 2, name: 'Jane Smith', phone: '555-0002', employeeId: 'EMP002' },
        { id: 3, name: 'Bob Johnson', phone: '555-0003', employeeId: 'EMP003' },
      ],
      totalElements: 3,
      totalPages: 1,
    },
  };

  const mockVehicles = {
    data: {
      content: [
        { id: 1, licensePlate: 'ABC-123', model: 'Toyota Camry', vin: 'VIN001' },
        { id: 2, licensePlate: 'XYZ-789', model: 'Honda Accord', vin: 'VIN002' },
        { id: 3, licensePlate: 'DEF-456', model: 'Ford F-150', vin: 'VIN003' },
      ],
      totalElements: 3,
      totalPages: 1,
    },
  };

  const mockIncidentResponse = {
    success: true,
    message: 'Incident created successfully',
    data: {
      id: 100,
      code: 'INC-2025-001',
      title: 'Test Incident',
      description: 'Test description',
      incidentStatus: IncidentStatus.NEW,
      incidentGroup: IncidentGroup.DRIVER,
      incidentType: 'SPEEDING',
      severity: IssueSeverity.HIGH,
      driverId: 1,
      vehicleId: 1,
      locationText: 'Test Location',
      reportedAt: new Date().toISOString(),
    },
  };

  beforeEach(async () => {
    const routerSpy = jasmine.createSpyObj('Router', ['navigate']);
    const activatedRouteStub = {
      snapshot: {
        paramMap: {
          get: jasmine.createSpy('get').and.returnValue(null),
        },
      },
    };

    TestBed.overrideComponent(IncidentFormComponent, {
      set: {
        template: '',
      },
    });

    await TestBed.configureTestingModule({
      imports: [
        IncidentFormComponent,
        ReactiveFormsModule,
        HttpClientTestingModule,
        NgSelectModule,
      ],
      providers: [
        IncidentService,
        DriverService,
        VehicleService,
        { provide: Router, useValue: routerSpy },
        { provide: ActivatedRoute, useValue: activatedRouteStub },
      ],
    }).compileComponents();

    fixture = TestBed.createComponent(IncidentFormComponent);
    component = fixture.componentInstance;
    httpMock = TestBed.inject(HttpTestingController);
    router = TestBed.inject(Router);
    incidentService = TestBed.inject(IncidentService);
    driverService = TestBed.inject(DriverService);
    vehicleService = TestBed.inject(VehicleService);
  });

  function flushInitialRequests() {
    httpMock.expectOne(driversUrl).flush(mockDrivers);
    httpMock.expectOne(vehiclesUrl).flush(mockVehicles);
  }

  afterEach(() => {
    httpMock.verify();
  });

  describe('Component Initialization', () => {
    it('should create the component', () => {
      expect(component).toBeTruthy();
    });

    it('should load drivers on init', (done) => {
      fixture.detectChanges();

      component.drivers$.subscribe((drivers) => {
        expect(drivers.length).toBe(3);
        expect(drivers[0].name).toBe('John Doe');
        expect(component.driversLoading()).toBe(false);
        done();
      });

      const driversReq = httpMock.expectOne(driversUrl);
      expect(driversReq.request.method).toBe('GET');
      driversReq.flush(mockDrivers);
    });

    it('should load vehicles on init', (done) => {
      fixture.detectChanges();

      component.vehicles$.subscribe((vehicles) => {
        expect(vehicles.length).toBe(3);
        expect(vehicles[0].licensePlate).toBe('ABC-123');
        expect(component.vehiclesLoading()).toBe(false);
        done();
      });

      const vehiclesReq = httpMock.expectOne(vehiclesUrl);
      expect(vehiclesReq.request.method).toBe('GET');
      vehiclesReq.flush(mockVehicles);
    });

    it('should handle driver loading error gracefully', (done) => {
      fixture.detectChanges();

      component.drivers$.subscribe((drivers) => {
        expect(drivers.length).toBe(0);
        expect(component.driversLoading()).toBe(false);
        done();
      });

      const driversReq = httpMock.expectOne(driversUrl);
      driversReq.error(new ErrorEvent('Network error'));
    });

    it('should initialize form with empty values', () => {
      expect(component.incidentForm).toBeDefined();
      expect(component.incidentForm.get('title')?.value).toBe('');
      expect(component.incidentForm.get('description')?.value).toBe('');
      expect(component.incidentForm.get('incidentGroup')?.value).toBe('');
      expect(component.incidentForm.get('severity')?.value).toBe('');
      expect(component.incidentForm.get('incidentType')?.value).toBe('');
    });
  });

  describe('Form Validation', () => {
    beforeEach(() => {
      fixture.detectChanges();
    });

    it('should require title field', () => {
      const titleControl = component.incidentForm.get('title');
      expect(titleControl?.valid).toBeFalse();

      titleControl?.setValue('Test Incident');
      expect(titleControl?.valid).toBeTrue();
    });

    it('should require description field', () => {
      const descControl = component.incidentForm.get('description');
      expect(descControl?.valid).toBeFalse();

      descControl?.setValue('Test description');
      expect(descControl?.valid).toBeTrue();
    });

    it('should require incidentGroup field', () => {
      const groupControl = component.incidentForm.get('incidentGroup');
      expect(groupControl?.valid).toBeFalse();

      groupControl?.setValue('DRIVER');
      expect(groupControl?.valid).toBeTrue();
    });

    it('should require severity field', () => {
      const severityControl = component.incidentForm.get('severity');
      expect(severityControl?.valid).toBeFalse();

      severityControl?.setValue('HIGH');
      expect(severityControl?.valid).toBeTrue();
    });

    it('should require incidentType field', () => {
      const typeControl = component.incidentForm.get('incidentType');
      expect(typeControl?.valid).toBeFalse();

      typeControl?.setValue('SPEEDING');
      expect(typeControl?.valid).toBeTrue();
    });

    it('should allow optional fields to be empty', () => {
      const locationControl = component.incidentForm.get('location');
      const driverControl = component.incidentForm.get('driverId');
      const vehicleControl = component.incidentForm.get('vehicleId');

      expect(locationControl?.valid).toBeTrue();
      expect(driverControl?.valid).toBeTrue();
      expect(vehicleControl?.valid).toBeTrue();
    });

    it('should validate max length for title', () => {
      const titleControl = component.incidentForm.get('title');
      const longTitle = 'a'.repeat(256);

      titleControl?.setValue(longTitle);
      expect(titleControl?.valid).toBeFalse();
      expect(titleControl?.errors?.['maxlength']).toBeTruthy();
    });
  });

  describe('Create Incident API Integration', () => {
    beforeEach(() => {
      fixture.detectChanges();
    });

    it('should create incident with valid form data', () => {
      // Fill form with valid data
      component.incidentForm.patchValue({
        title: 'Speeding Violation',
        description: 'Driver exceeded speed limit',
        incidentGroup: 'DRIVER',
        incidentType: 'SPEEDING',
        severity: 'HIGH',
        location: 'Highway 101',
        driverId: 1,
        vehicleId: 1,
      });

      expect(component.incidentForm.valid).toBeTrue();

      // Submit form
      component.onSubmit();

      // Verify API call
      const req = httpMock.expectOne(`${environment.apiBaseUrl}/incidents`);
      expect(req.request.method).toBe('POST');
      expect(req.request.body).toEqual({
        title: 'Speeding Violation',
        description: 'Driver exceeded speed limit',
        incidentGroup: 'DRIVER',
        incidentType: 'SPEEDING',
        severity: 'HIGH',
        locationText: 'Highway 101',
        driverId: 1,
        vehicleId: 1,
        incidentStatus: IncidentStatus.NEW,
      });

      req.flush(mockIncidentResponse);

      // Verify navigation
      expect(router.navigate).toHaveBeenCalledWith(['/incidents', 100]);
    });

    it('should send default incidentStatus on creation', () => {
      component.incidentForm.patchValue({
        title: 'Test',
        description: 'Test desc',
        incidentGroup: 'DRIVER',
        incidentType: 'SPEEDING',
        severity: 'HIGH',
      });

      component.onSubmit();

      const req = httpMock.expectOne(`${environment.apiBaseUrl}/incidents`);
      expect(req.request.body.incidentStatus).toBe(IncidentStatus.NEW);

      req.flush(mockIncidentResponse);
    });

    it('should map location to locationText in request', () => {
      component.incidentForm.patchValue({
        title: 'Test',
        description: 'Test',
        incidentGroup: 'DRIVER',
        incidentType: 'SPEEDING',
        severity: 'HIGH',
        location: 'Test Location',
      });

      component.onSubmit();

      const req = httpMock.expectOne(`${environment.apiBaseUrl}/incidents`);
      expect(req.request.body.locationText).toBe('Test Location');
      expect(req.request.body.location).toBeUndefined();

      req.flush(mockIncidentResponse);
    });

    it('should handle API error on creation', () => {
      component.incidentForm.patchValue({
        title: 'Test',
        description: 'Test',
        incidentGroup: 'DRIVER',
        incidentType: 'SPEEDING',
        severity: 'HIGH',
      });

      component.onSubmit();

      const req = httpMock.expectOne(`${environment.apiBaseUrl}/incidents`);
      req.error(new ErrorEvent('Network error'), { status: 500 });

      expect(component.error()).toBe('Failed to create incident');
      expect(component.submitting()).toBe(false);
      expect(router.navigate).not.toHaveBeenCalled();
    });

    it('should not submit if form is invalid', () => {
      component.incidentForm.patchValue({
        title: '', // Invalid - required
        description: 'Test',
      });

      component.onSubmit();

      httpMock.expectNone(`${environment.apiBaseUrl}/incidents`);
      expect(component.submitting()).toBe(false);
    });

    it('should mark all fields as touched on invalid submit', () => {
      component.onSubmit();

      expect(component.incidentForm.get('title')?.touched).toBeTrue();
      expect(component.incidentForm.get('description')?.touched).toBeTrue();
      expect(component.incidentForm.get('incidentGroup')?.touched).toBeTrue();
      expect(component.incidentForm.get('severity')?.touched).toBeTrue();
      expect(component.incidentForm.get('incidentType')?.touched).toBeTrue();
    });
  });

  describe('Photo Upload Integration', () => {
    beforeEach(() => {
      fixture.detectChanges();
    });

    it('should upload photos after creating incident', () => {
      // Create mock file
      const mockFile = new File(['test'], 'test.jpg', { type: 'image/jpeg' });
      component.selectedFiles = [mockFile];

      component.incidentForm.patchValue({
        title: 'Test',
        description: 'Test',
        incidentGroup: 'DRIVER',
        incidentType: 'SPEEDING',
        severity: 'HIGH',
      });

      component.onSubmit();

      // Handle incident creation
      const createReq = httpMock.expectOne(`${environment.apiBaseUrl}/incidents`);
      createReq.flush(mockIncidentResponse);

      // Handle photo upload
      const uploadReq = httpMock.expectOne(`${environment.apiBaseUrl}/incidents/100/upload-photos`);
      expect(uploadReq.request.method).toBe('POST');
      expect(uploadReq.request.body instanceof FormData).toBeTrue();

      uploadReq.flush({ success: true, message: 'Photos uploaded' });

      expect(router.navigate).toHaveBeenCalledWith(['/incidents', 100]);
    });

    it('should navigate even if photo upload fails', () => {
      const mockFile = new File(['test'], 'test.jpg', { type: 'image/jpeg' });
      component.selectedFiles = [mockFile];

      component.incidentForm.patchValue({
        title: 'Test',
        description: 'Test',
        incidentGroup: 'DRIVER',
        incidentType: 'SPEEDING',
        severity: 'HIGH',
      });

      component.onSubmit();

      const createReq = httpMock.expectOne(`${environment.apiBaseUrl}/incidents`);
      createReq.flush(mockIncidentResponse);

      const uploadReq = httpMock.expectOne(`${environment.apiBaseUrl}/incidents/100/upload-photos`);
      uploadReq.error(new ErrorEvent('Upload error'));

      // Should still navigate despite upload failure
      expect(router.navigate).toHaveBeenCalledWith(['/incidents', 100]);
    });

    it('should skip upload if no files selected', () => {
      component.selectedFiles = [];

      component.incidentForm.patchValue({
        title: 'Test',
        description: 'Test',
        incidentGroup: 'DRIVER',
        incidentType: 'SPEEDING',
        severity: 'HIGH',
      });

      component.onSubmit();

      const createReq = httpMock.expectOne(`${environment.apiBaseUrl}/incidents`);
      createReq.flush(mockIncidentResponse);

      // No upload request should be made
      httpMock.expectNone(`${environment.apiBaseUrl}/incidents/100/upload-photos`);

      expect(router.navigate).toHaveBeenCalledWith(['/incidents', 100]);
    });
  });

  describe('Update Incident API Integration', () => {
    beforeEach(() => {
      // Setup edit mode
      const activatedRoute = TestBed.inject(ActivatedRoute);
      (activatedRoute.snapshot.paramMap.get as jasmine.Spy).and.returnValue('50');

      fixture = TestBed.createComponent(IncidentFormComponent);
      component = fixture.componentInstance;
      fixture.detectChanges();
    });

    it('should load existing incident in edit mode', () => {
      const existingIncident = {
        success: true,
        data: {
          id: 50,
          title: 'Existing Incident',
          description: 'Existing description',
          incidentGroup: 'VEHICLE',
          incidentType: 'BREAKDOWN',
          severity: 'MEDIUM',
          location: 'Old Location',
          driverId: 2,
          vehicleId: 2,
        },
      };

      const req = httpMock.expectOne(`${environment.apiBaseUrl}/incidents/50`);
      expect(req.request.method).toBe('GET');
      req.flush(existingIncident);

      expect(component.incidentForm.get('title')?.value).toBe('Existing Incident');
      expect(component.incidentForm.get('description')?.value).toBe('Existing description');
      expect(component.incidentForm.get('incidentGroup')?.value).toBe('VEHICLE');
      expect(component.isEditMode()).toBeTrue();
    });

    it('should update incident when in edit mode', () => {
      // Load existing incident first
      const loadReq = httpMock.expectOne(`${environment.apiBaseUrl}/incidents/50`);
      loadReq.flush({
        success: true,
        data: {
          id: 50,
          title: 'Old Title',
          description: 'Old desc',
          incidentGroup: 'DRIVER',
          incidentType: 'SPEEDING',
          severity: 'HIGH',
        },
      });

      // Update form
      component.incidentForm.patchValue({
        title: 'Updated Title',
        description: 'Updated description',
      });

      component.onSubmit();

      const updateReq = httpMock.expectOne(`${environment.apiBaseUrl}/incidents/50`);
      expect(updateReq.request.method).toBe('PUT');
      expect(updateReq.request.body.title).toBe('Updated Title');

      updateReq.flush({ success: true, data: { id: 50 } });

      expect(router.navigate).toHaveBeenCalledWith(['/incidents', 50]);
    });
  });

  describe('File Selection', () => {
    beforeEach(() => {
      fixture.detectChanges();
    });

    it('should handle file selection', () => {
      const mockFile1 = new File(['content1'], 'photo1.jpg', { type: 'image/jpeg' });
      const mockFile2 = new File(['content2'], 'photo2.jpg', { type: 'image/jpeg' });

      const mockEvent = {
        target: {
          files: [mockFile1, mockFile2],
        },
      } as any;

      component.onFileSelect(mockEvent);

      expect(component.selectedFiles.length).toBe(2);
      expect(component.selectedFiles[0].name).toBe('photo1.jpg');
      expect(component.selectedFiles[1].name).toBe('photo2.jpg');
    });

    it('should handle empty file selection', () => {
      const mockEvent = {
        target: {
          files: null,
        },
      } as any;

      component.onFileSelect(mockEvent);

      expect(component.selectedFiles.length).toBe(0);
    });
  });

  describe('Navigation', () => {
    beforeEach(() => {
      fixture.detectChanges();
    });

    it('should navigate back to incidents list', () => {
      component.goBack();
      expect(router.navigate).toHaveBeenCalledWith(['/incidents']);
    });
  });
});
