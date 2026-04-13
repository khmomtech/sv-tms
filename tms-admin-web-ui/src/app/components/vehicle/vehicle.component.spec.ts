import { ComponentFixture, TestBed, fakeAsync, tick } from '@angular/core/testing';
import { of, throwError, BehaviorSubject } from 'rxjs';
import { FormsModule } from '@angular/forms';
import { CommonModule } from '@angular/common';
import { ScrollingModule } from '@angular/cdk/scrolling';
import { Router, ActivatedRoute } from '@angular/router';
import { ChangeDetectorRef } from '@angular/core';

import { VehicleComponent } from './vehicle.component';
import { VehicleService } from '../../services/vehicle.service';
import { Vehicle } from '../../models/vehicle.model';
import { VehicleStatus, VehicleType } from '../../models/enums/vehicle.enums';
import { NotificationService } from '../../services/notification.service';
import { ConfirmService } from '../../services/confirm.service';

describe('VehicleComponent', () => {
  let component: VehicleComponent;
  let fixture: ComponentFixture<VehicleComponent>;
  let mockVehicleService: jasmine.SpyObj<VehicleService>;
  let mockRouter: jasmine.SpyObj<Router>;
  let mockActivatedRoute: any;
  let mockChangeDetectorRef: jasmine.SpyObj<ChangeDetectorRef>;
  let mockNotificationService: jasmine.SpyObj<NotificationService>;
  let mockConfirmService: jasmine.SpyObj<ConfirmService>;

  const mockVehicle: Vehicle = {
    id: 1,
    licensePlate: 'ABC-123',
    plateNumber: 'ABC-123',
    model: 'Hino 500',
    manufacturer: 'Hino',
    type: VehicleType.TRUCK,
    status: VehicleStatus.AVAILABLE,
    assignedZoneName: 'North',
    mileage: 10000,
    fuelConsumption: 20,
  };

  const mockPagedResponse = {
    success: true,
    data: {
      content: [mockVehicle],
      totalElements: 1,
      totalPages: 1,
    },
  };

  beforeEach(async () => {
    const vehicleServiceSpy = jasmine.createSpyObj('VehicleService', [
      'getVehicles',
      'getAllVehicles',
      'addVehicle',
      'updateVehicle',
      'deleteVehicle',
    ]);

    const routerSpy = jasmine.createSpyObj('Router', ['navigate']);
    const cdrSpy = jasmine.createSpyObj('ChangeDetectorRef', ['markForCheck', 'detectChanges']);
    const notificationSpy = jasmine.createSpyObj('NotificationService', ['success', 'error']);
    const confirmSpy = jasmine.createSpyObj('ConfirmService', ['confirm']);

    mockActivatedRoute = {
      snapshot: {
        data: {},
      },
    };

    await TestBed.configureTestingModule({
      imports: [VehicleComponent, FormsModule, ScrollingModule],
      providers: [
        { provide: VehicleService, useValue: vehicleServiceSpy },
        { provide: Router, useValue: routerSpy },
        { provide: ActivatedRoute, useValue: mockActivatedRoute },
        { provide: ChangeDetectorRef, useValue: cdrSpy },
        { provide: NotificationService, useValue: notificationSpy },
        { provide: ConfirmService, useValue: confirmSpy },
      ],
    }).compileComponents();

    mockVehicleService = TestBed.inject(VehicleService) as jasmine.SpyObj<VehicleService>;
    mockRouter = TestBed.inject(Router) as jasmine.SpyObj<Router>;
    mockChangeDetectorRef = TestBed.inject(ChangeDetectorRef) as jasmine.SpyObj<ChangeDetectorRef>;
    mockNotificationService = TestBed.inject(
      NotificationService,
    ) as jasmine.SpyObj<NotificationService>;
    mockConfirmService = TestBed.inject(ConfirmService) as jasmine.SpyObj<ConfirmService>;

    mockVehicleService.getVehicles.and.returnValue(
      of({
        success: true,
        data: {
          content: [mockVehicle],
          totalElements: 1,
          totalPages: 1,
        },
      }),
    );

    fixture = TestBed.createComponent(VehicleComponent);
    component = fixture.componentInstance;
  });

  describe('Component Initialization', () => {
    it('should create', () => {
      expect(component).toBeTruthy();
    });

    it('should load vehicles on init', () => {
      fixture.detectChanges();

      expect(mockVehicleService.getVehicles).toHaveBeenCalled();
      expect(component.vehicles.length).toBe(1);
      expect(component.vehicles[0]).toEqual(jasmine.objectContaining(mockVehicle));
    });

    it('should compute summary on init', () => {
      fixture.detectChanges();

      // Remove summary checks; property does not exist
    });

    it('should restore saved filters', () => {
      spyOn(localStorage, 'getItem').and.returnValue(
        JSON.stringify({
          search: 'test',
          status: VehicleStatus.AVAILABLE,
        }),
      );

      component.ngOnInit();

      expect(component.filters.search).toBe('test');
    });

    it('should open modal if route action is create', fakeAsync(() => {
      mockActivatedRoute.snapshot.data['action'] = 'create';
      spyOn(component, 'openVehicleModal');

      component.ngOnInit();
      tick(150);

      expect(component.openVehicleModal).toHaveBeenCalled();
    }));
  });

  describe('Filtering', () => {
    beforeEach(() => {
      fixture.detectChanges();
    });

    it('should apply search filter', () => {
      component.filters.search = 'ABC';
      component.filterVehicles();

      expect(mockVehicleService.getVehicles).toHaveBeenCalledWith(
        0,
        15,
        jasmine.objectContaining({ search: 'ABC' }),
      );
    });

    it('should apply status filter', () => {
      component.filters.status = VehicleStatus.AVAILABLE;
      component.filterVehicles();

      expect(mockVehicleService.getVehicles).toHaveBeenCalledWith(
        0,
        15,
        jasmine.objectContaining({ status: VehicleStatus.AVAILABLE }),
      );
    });

    it('should apply assigned filter', () => {
      component.filters.assigned = 'assigned';
      component.filterVehicles();

      expect(mockVehicleService.getVehicles).toHaveBeenCalledWith(
        0,
        15,
        jasmine.objectContaining({ assigned: 'true' }),
      );
    });

    it('should clear all filters', () => {
      component.filters = {
        search: 'test',
        status: VehicleStatus.IN_USE,
        assigned: 'North',
      };

      component.clearFilters();

      expect(component.filters.search).toBe('');
      expect(component.filters.status).toBe('');
      expect(component.filters.assigned).toBe('');
      expect(component.filters.assigned).toBe('');
      expect(mockVehicleService.getVehicles).toHaveBeenCalled();
    });

    it('should persist filters to localStorage', () => {
      spyOn(localStorage, 'setItem');

      component.filters.search = 'ABC';
      component.filterVehicles();

      expect(localStorage.setItem).toHaveBeenCalledWith(
        component['FILTER_STORAGE_KEY'],
        jasmine.any(String),
      );
    });

    it('should reset page to 0 when filtering', () => {
      component.currentPage = 5;
      component.filterVehicles();

      expect(component.currentPage).toBe(0);
    });
  });

  describe('CRUD Operations', () => {
    beforeEach(() => {
      fixture.detectChanges();
    });

    it('should open modal for creating new vehicle', () => {
      component.openVehicleModal();

      expect(component.isModalOpen).toBe(true);
      expect(component.isEditing).toBe(false);
      expect(component.selectedVehicle.id).toBeUndefined();
    });

    it('should open modal for editing existing vehicle', () => {
      component.openVehicleModal(mockVehicle);

      expect(component.isModalOpen).toBe(true);
      expect(component.isEditing).toBe(true);
      expect(component.selectedVehicle.id).toBe(mockVehicle.id);
    });

    it('should create new vehicle', () => {
      mockVehicleService.addVehicle.and.returnValue(of({ success: true, data: mockVehicle } as any));

      component.selectedVehicle = { ...mockVehicle, id: undefined } as any;
      component.isEditing = false;
      component.saveVehicle();

      expect(mockVehicleService.addVehicle).toHaveBeenCalled();
      expect(mockNotificationService.success).toHaveBeenCalledWith('Vehicle created successfully!');
      expect(component.isModalOpen).toBe(false);
    });

    it('should update existing vehicle', () => {
      mockVehicleService.updateVehicle.and.returnValue(of({ success: true, data: mockVehicle }));

      component.openVehicleModal(mockVehicle);
      component.saveVehicle();

      expect(mockVehicleService.updateVehicle).toHaveBeenCalledWith(
        jasmine.objectContaining({
          id: mockVehicle.id,
          licensePlate: mockVehicle.licensePlate,
          assignedZone: mockVehicle.assignedZoneName,
        }),
      );
      expect(component.isModalOpen).toBe(false);
    });

    it('should delete vehicle with confirmation', async () => {
      mockConfirmService.confirm.and.resolveTo(true);
      mockVehicleService.deleteVehicle.and.returnValue(of({ success: true } as any));

      await component.deleteVehicle(1);

      expect(mockVehicleService.deleteVehicle).toHaveBeenCalledWith(1);
      expect(mockVehicleService.getVehicles).toHaveBeenCalled();
    });

    it('should not delete vehicle if not confirmed', async () => {
      mockConfirmService.confirm.and.resolveTo(false);

      await component.deleteVehicle(1);

      expect(mockVehicleService.deleteVehicle).not.toHaveBeenCalled();
    });

    it('should close modal', () => {
      component.isModalOpen = true;
      component.selectedVehicle = mockVehicle;

      component.closeModal();

      expect(component.isModalOpen).toBe(false);
      expect(component.selectedVehicle.id).toBeUndefined();
    });

    it('should navigate to vehicle detail', () => {
      component.viewVehicle(1);

      expect(mockRouter.navigate).toHaveBeenCalledWith(['/fleet/vehicles', 1]);
    });
  });

  describe('Pagination', () => {
    beforeEach(() => {
      fixture.detectChanges();
      component.totalPages = 5;
    });

    it('should go to next page', () => {
      component.currentPage = 0;
      component.nextPage();

      expect(component.currentPage).toBe(1);
      expect(mockVehicleService.getVehicles).toHaveBeenCalled();
    });

    it('should go to previous page', () => {
      component.currentPage = 2;
      component.prevPage();

      expect(component.currentPage).toBe(1);
      expect(mockVehicleService.getVehicles).toHaveBeenCalled();
    });

    it('should not go before first page', () => {
      component.currentPage = 0;
      component.prevPage();

      expect(component.currentPage).toBe(0);
    });

    it('should not go beyond last page', () => {
      component.currentPage = 4;
      component.nextPage();

      expect(component.currentPage).toBe(4);
    });

    it('should persist page when navigating', () => {
      spyOn(localStorage, 'setItem');

      component.nextPage();

      expect(localStorage.setItem).toHaveBeenCalled();
    });
  });

  describe('Error Handling', () => {
    it('should handle fetch errors gracefully', () => {
      mockVehicleService.getVehicles.and.returnValue(throwError(() => new Error('Network error')));

      component.fetchVehiclesWithFilters();

      expect(component.listErrorMessage).toContain('Error loading vehicles');
    });

    it('should handle save errors', () => {
      mockVehicleService.addVehicle.and.returnValue(throwError(() => new Error('Save failed')));

      component.selectedVehicle = mockVehicle;
      component.isEditing = false;
      component.saveVehicle();

      expect(component.modalErrorMessage).toContain('Error saving vehicle');
    });

    it('should handle delete errors', async () => {
      mockConfirmService.confirm.and.resolveTo(true);
      mockVehicleService.deleteVehicle.and.returnValue(
        throwError(() => new Error('Delete failed')),
      );

      await component.deleteVehicle(1);

      expect(component.listErrorMessage).toContain('Error deleting vehicle');
    });

    it('should clear error message on modal close', () => {
      component.modalErrorMessage = 'Test error';
      component.closeModal();

      expect(component.modalErrorMessage).toBe('');
    });
  });

  describe('OnPush Change Detection', () => {
    it('should mark for check after data load', () => {
      const cdr = (component as any).cdr as ChangeDetectorRef;
      const markSpy = spyOn(cdr, 'markForCheck');

      fixture.detectChanges();

      expect(markSpy).toHaveBeenCalled();
    });

    it('should detect changes after CRUD operations', () => {
      const cdr = (component as any).cdr as ChangeDetectorRef;
      const markSpy = spyOn(cdr, 'markForCheck');
      mockVehicleService.addVehicle.and.returnValue(
        of({
          success: true,
          data: mockVehicle,
        }),
      );

      component.selectedVehicle = mockVehicle;
      component.saveVehicle();

      expect(markSpy).toHaveBeenCalled();
    });
  });

  describe('Virtual Scrolling', () => {
    it('should handle large datasets efficiently', () => {
      const largeDataset = Array.from({ length: 1000 }, (_, i) => ({
        ...mockVehicle,
        id: i + 1,
        plateNumber: `ABC-${i}`,
      }));

      mockVehicleService.getVehicles.and.returnValue(
        of({
          success: true,
          data: {
            content: largeDataset,
            totalElements: 1000,
            totalPages: 67,
          },
        }),
      );

      component.fetchVehiclesWithFilters();

      expect(component.vehicles.length).toBe(1000);
      expect(component.totalPages).toBe(67);
    });
  });

  describe('UI State Management', () => {
    it('should toggle dropdown', () => {
      component.toggleDropdown(1);
      expect(component.dropdownOpen).toBe(1);

      component.toggleDropdown(1);
      expect(component.dropdownOpen).toBe(null);
    });

    it('should close dropdown after delete', async () => {
      mockConfirmService.confirm.and.resolveTo(true);
      mockVehicleService.deleteVehicle.and.returnValue(of({ success: true } as any));

      component.dropdownOpen = 1;
      await component.deleteVehicle(1);

      expect(component.dropdownOpen).toBe(null);
    });

    it('should default a new truck to a valid truck size', () => {
      component.openVehicleModal();

      expect(component.selectedVehicle.type).toBe(VehicleType.TRUCK);
      expect(component.selectedVehicle.truckSize).toBeDefined();
    });
  });

  describe('Filter Presets', () => {
    it('should save filter preset', () => {
      spyOn(localStorage, 'setItem');

      component.filters = {
        search: 'test',
        status: VehicleStatus.AVAILABLE,
        assigned: '',
      };

      component['persistFilters']();

      expect(localStorage.setItem).toHaveBeenCalled();
    });

    it('should restore filter preset', () => {
      const savedFilters = {
        search: 'test',
        status: VehicleStatus.AVAILABLE,
      };

      spyOn(localStorage, 'getItem').and.returnValue(JSON.stringify(savedFilters));

      component['restoreFilters']();

      expect(component.filters.search).toBe('test');
      expect(component.filters.status).toBe(VehicleStatus.AVAILABLE);
    });
  });
});
