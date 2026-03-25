import type { ComponentFixture } from '@angular/core/testing';
import { TestBed, fakeAsync, tick } from '@angular/core/testing';
import { FormsModule, ReactiveFormsModule } from '@angular/forms';
import { MatAutocompleteModule } from '@angular/material/autocomplete';
import { MatButtonModule } from '@angular/material/button';
import { MatFormFieldModule } from '@angular/material/form-field';
import { MatIconModule } from '@angular/material/icon';
import { MatInputModule } from '@angular/material/input';
import { MatProgressSpinnerModule } from '@angular/material/progress-spinner';
import { MatSliderModule } from '@angular/material/slider';
import { BrowserAnimationsModule } from '@angular/platform-browser/animations';
import { ActivatedRoute, Router, convertToParamMap } from '@angular/router';
import { of } from 'rxjs';

import type { Driver } from '../../models/driver.model';
import type { Vehicle } from '../../models/vehicle.model';
import { AdminNotificationService } from '../../services/admin-notification.service';
import { ConfirmService } from '../../services/confirm.service';
import { DriverService } from '../../services/driver.service';
import { PermissionGuardService } from '../../services/permission-guard.service';
import { InputPromptService } from '../../core/input-prompt.service';

import { DriversComponent } from './drivers.component';

describe('DriversComponent', () => {
  let component: DriversComponent;
  let fixture: ComponentFixture<DriversComponent>;
  let mockDriverService: jasmine.SpyObj<DriverService>;
  let mockAdminNotificationService: jasmine.SpyObj<AdminNotificationService>;
  let mockPermissionGuardService: jasmine.SpyObj<PermissionGuardService>;
  let mockConfirmService: jasmine.SpyObj<ConfirmService>;
  let mockInputPromptService: jasmine.SpyObj<InputPromptService>;
  let mockRouter: jasmine.SpyObj<Router>;

  // Mock data
  const mockDrivers: Driver[] = [
    {
      id: 1,
      firstName: 'John',
      lastName: 'Doe',
      name: 'John Doe',
      licenseNumber: 'DL123456',
      phone: '+1234567890',
      rating: 4.5,
      isActive: true,
      status: 'online',
      vehicleType: 'TRUCK',
      zone: 'North',
      logs: [],
      updatedFromSocket: false,
      selected: false,
    },
    {
      id: 2,
      firstName: 'Jane',
      lastName: 'Smith',
      name: 'Jane Smith',
      licenseNumber: 'DL789012',
      phone: '+1987654321',
      rating: 3.8,
      isActive: true,
      status: 'busy',
      vehicleType: 'VAN',
      zone: 'South',
      logs: [],
      updatedFromSocket: false,
      selected: false,
    },
  ];

  const mockVehicles: Vehicle[] = [
    {
      id: 1,
      licensePlate: 'ABC123',
      model: 'Ford F-150',
      manufacturer: 'Ford',
      type: 'TRUCK',
      status: 'ACTIVE',
      mileage: 12000,
      fuelConsumption: 15,
    },
    {
      id: 2,
      licensePlate: 'XYZ789',
      model: 'Chevy Express',
      manufacturer: 'Chevrolet',
      type: 'VAN',
      status: 'ACTIVE',
      mileage: 8000,
      fuelConsumption: 18,
    },
  ];

  beforeEach(async () => {
    const driverServiceSpy = jasmine.createSpyObj('DriverService', [
      'getAdvancedDrivers',
      'getAllVehicles',
      'addDriver',
      'updateDriver',
      'deleteDriver',
      'assignDriverToVehicle',
      'addDriverAccount',
      'showToast',
    ]);

    const adminNotificationServiceSpy = jasmine.createSpyObj('AdminNotificationService', [
      'sendNotificationToDriver',
    ]);
    const permissionGuardServiceSpy = jasmine.createSpyObj('PermissionGuardService', [
      'hasPermission',
    ]);
    const confirmServiceSpy = jasmine.createSpyObj('ConfirmService', ['confirm']);
    const inputPromptServiceSpy = jasmine.createSpyObj('InputPromptService', ['prompt']);

    const routerSpy = jasmine.createSpyObj('Router', ['navigate']);

    TestBed.overrideComponent(DriversComponent, {
      set: {
        template: '',
      },
    });

    await TestBed.configureTestingModule({
      imports: [
        DriversComponent,
        FormsModule,
        ReactiveFormsModule,
        MatFormFieldModule,
        MatInputModule,
        MatAutocompleteModule,
        MatIconModule,
        MatButtonModule,
        MatProgressSpinnerModule,
        MatSliderModule,
        BrowserAnimationsModule,
      ],
      providers: [
        { provide: DriverService, useValue: driverServiceSpy },
        { provide: AdminNotificationService, useValue: adminNotificationServiceSpy },
        { provide: PermissionGuardService, useValue: permissionGuardServiceSpy },
        { provide: ConfirmService, useValue: confirmServiceSpy },
        { provide: InputPromptService, useValue: inputPromptServiceSpy },
        { provide: Router, useValue: routerSpy },
        {
          provide: ActivatedRoute,
          useValue: {
            snapshot: { data: {}, paramMap: { get: (_: string) => null } },
            paramMap: of(convertToParamMap({})),
            queryParamMap: of(convertToParamMap({})),
          },
        },
      ],
    }).compileComponents();

    fixture = TestBed.createComponent(DriversComponent);
    component = fixture.componentInstance;
    mockDriverService = TestBed.inject(DriverService) as jasmine.SpyObj<DriverService>;
    mockAdminNotificationService = TestBed.inject(
      AdminNotificationService,
    ) as jasmine.SpyObj<AdminNotificationService>;
    mockPermissionGuardService = TestBed.inject(
      PermissionGuardService,
    ) as jasmine.SpyObj<PermissionGuardService>;
    mockConfirmService = TestBed.inject(ConfirmService) as jasmine.SpyObj<ConfirmService>;
    mockInputPromptService = TestBed.inject(
      InputPromptService,
    ) as jasmine.SpyObj<InputPromptService>;
    mockRouter = TestBed.inject(Router) as jasmine.SpyObj<Router>;
  });

  beforeEach(() => {
    localStorage.clear();

    // Setup default mock responses
    mockDriverService.getAdvancedDrivers.and.returnValue(
      of({
        success: true,
        data: {
          content: mockDrivers,
          totalPages: 1,
          totalElements: 2,
        },
      }),
    );
    mockDriverService.getAllVehicles.and.returnValue(of({ success: true, data: mockVehicles }));
    mockDriverService.showToast.and.returnValue(void 0);
    mockPermissionGuardService.hasPermission.and.returnValue(true);
    mockConfirmService.confirm.and.resolveTo(true);
    mockInputPromptService.prompt.and.resolveTo('test-user');
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });

  describe('Component Initialization', () => {
    it('should load drivers and vehicles on init', fakeAsync(() => {
      component.ngOnInit();
      tick();

      expect(mockDriverService.getAdvancedDrivers).toHaveBeenCalledWith(
        0,
        10,
        jasmine.objectContaining({}),
      );
      expect(mockDriverService.getAllVehicles).toHaveBeenCalled();
      expect(component.drivers.length).toBe(2);
      expect(component.vehicles.length).toBe(2);
    }));

    it('should initialize filters with default values', () => {
      expect(component.filters).toEqual({
        query: '',
        activity: 'all',
        driverStatuses: [],
        vehicleType: '',
        zone: '',
        account: 'any',
        licensePlate: '',
      });
    });
  });

  describe('Rating Filter Functionality', () => {
    it('should include rating filters in service filters when set', () => {
      component.filters.minRating = 3.0;
      component.filters.maxRating = 5.0;

      const serviceFilters = component['buildServiceFilters']();

      expect(serviceFilters.minRating).toBe(3.0);
      expect(serviceFilters.maxRating).toBe(5.0);
    });

    it('should not include rating filters when not set', () => {
      const serviceFilters = component['buildServiceFilters']();

      expect(serviceFilters.minRating).toBeUndefined();
      expect(serviceFilters.maxRating).toBeUndefined();
    });

    it('should apply rating filters when applyFilters is called', fakeAsync(() => {
      component.filters.minRating = 4.0;
      component.filters.maxRating = 5.0;

      component.applyFilters();
      tick();

      expect(mockDriverService.getAdvancedDrivers).toHaveBeenCalledWith(
        0,
        10,
        jasmine.objectContaining({
          minRating: 4.0,
          maxRating: 5.0,
        }),
      );
    }));

    it('should clear rating filters when clearFilters is called', () => {
      component.filters.minRating = 3.0;
      component.filters.maxRating = 4.5;

      component.clearFilters();

      expect(component.filters.minRating).toBeUndefined();
      expect(component.filters.maxRating).toBeUndefined();
    });

    it('should count rating filters as active when set', () => {
      component.filters.minRating = 3.0;
      expect(component.getActiveFilterCount()).toBe(1);

      component.filters.maxRating = 4.5;
      expect(component.getActiveFilterCount()).toBe(1); // Still counts as one rating filter
    });

    it('should include rating range in filter summary', () => {
      component.filters.minRating = 3.5;
      component.filters.maxRating = 4.8;

      const summary = component.getFilterSummary();
      expect(summary).toContain('Rating: 3.5 - 4.8★');
    });
  });

  describe('Driver Filtering', () => {
    it('should not apply rating range locally when backend filters are used', () => {
      component['allDrivers'] = mockDrivers;
      component.filters.minRating = 4.0;
      component.filters.maxRating = 5.0;

      component.drivers = component['applyLocalFilters'](component['allDrivers']);

      expect(component.drivers.length).toBe(2);
    });

    it('should show all drivers when no rating filter is applied', () => {
      component['allDrivers'] = mockDrivers;

      component.drivers = component['applyLocalFilters'](component['allDrivers']);

      expect(component.drivers.length).toBe(2);
    });
  });

  describe('Driver CRUD Operations', () => {
    it('should add a new driver', fakeAsync(() => {
      const newDriver = {
        firstName: 'Bob',
        lastName: 'Wilson',
        licenseNumber: '123456789',
        phone: '12345678',
        rating: 4,
        countryCode: 'KH',
      };

      mockDriverService.addDriver.and.returnValue(of(void 0));
      component.selectedDriver = newDriver as any;

      component.addDriver();
      tick();

      expect(mockDriverService.addDriver).toHaveBeenCalled();
      expect(mockDriverService.getAdvancedDrivers).toHaveBeenCalled();
    }));

    it('should update an existing driver', fakeAsync(() => {
      const existingDriver = {
        ...mockDrivers[0],
        firstName: 'Johnny',
        phone: '+1234567890',
        rating: 4,
        countryCode: 'US',
      };

      mockDriverService.updateDriver.and.returnValue(of(void 0));
      component.selectedDriver = existingDriver;

      component.updateDriver();
      tick();

      expect(mockDriverService.updateDriver).toHaveBeenCalledWith(1, jasmine.any(Object));
      expect(mockDriverService.getAdvancedDrivers).toHaveBeenCalled();
    }));

    it('should delete a driver', fakeAsync(() => {
      mockDriverService.deleteDriver.and.returnValue(of(void 0));

      component.deleteDriver(1);
      tick();

      expect(mockDriverService.deleteDriver).toHaveBeenCalledWith(1);
      expect(mockDriverService.getAdvancedDrivers).toHaveBeenCalled();
    }));
  });

  describe('Vehicle Assignment', () => {
    it('should assign vehicle to driver', fakeAsync(() => {
      mockDriverService.assignDriverToVehicle.and.returnValue(of(void 0));
      component.selectedVehicleId = 1;

      component.assignVehicle(1);
      tick();

      expect(mockDriverService.assignDriverToVehicle).toHaveBeenCalledWith(1, jasmine.any(Number));
    }));
  });

  describe('UI Helpers', () => {
    it('should format rating display correctly', () => {
      expect(component.getRatingDisplay(4.5)).toBe('4.5★');
      expect(component.getRatingDisplay(0)).toBe('N/A');
      expect(component.getRatingDisplay(undefined)).toBe('N/A');
    });

    it('should format status correctly', () => {
      expect(component.formatStatus('ON_TRIP')).toBe('On Trip');
      expect(component.formatStatus('BUSY')).toBe('Busy');
      expect(component.formatStatus(undefined)).toBe('—');
    });

    it('should get correct status badge class', () => {
      expect(component.getStatusBadgeClass('ON_TRIP')).toBe('bg-blue-100 text-blue-800');
      expect(component.getStatusBadgeClass('BUSY')).toBe('bg-yellow-100 text-yellow-800');
      expect(component.getStatusBadgeClass('IDLE')).toBe('bg-green-100 text-green-800');
    });
  });

  describe('Pagination', () => {
    it('should go to next page', () => {
      component.currentPage = 0;
      component.totalPages = 3;

      component.goToNextPage();

      expect(component.currentPage).toBe(1);
      expect(mockDriverService.getAdvancedDrivers).toHaveBeenCalledWith(
        1,
        10,
        jasmine.objectContaining({}),
      );
    });

    it('should go to previous page', () => {
      component.currentPage = 2;

      component.goToPreviousPage();

      expect(component.currentPage).toBe(1);
      expect(mockDriverService.getAdvancedDrivers).toHaveBeenCalledWith(
        1,
        10,
        jasmine.objectContaining({}),
      );
    });

    it('should jump to specific page', () => {
      component.jumpToPageInput = '3';
      component.totalPages = 5;

      component.jumpToPage(3);

      expect(component.currentPage).toBe(2); // 0-indexed
      expect(component.jumpToPageInput).toBe('');
    });
  });

  describe('Selection Management', () => {
    it('should toggle driver selection', () => {
      component.toggleDriverSelection(1);
      expect(component.selectedIds).toContain(1);

      component.toggleDriverSelection(1);
      expect(component.selectedIds).not.toContain(1);
    });

    it('should select all drivers on page', () => {
      component.drivers = mockDrivers;

      component.toggleSelectAllOnPage({ target: { checked: true } } as any);

      expect(component.selectedIds).toEqual([1, 2]);
    });

    it('should clear all selections', () => {
      component.selectedIds = [1, 2, 3];

      component.clearSelection();

      expect(component.selectedIds).toEqual([]);
    });
  });
});
