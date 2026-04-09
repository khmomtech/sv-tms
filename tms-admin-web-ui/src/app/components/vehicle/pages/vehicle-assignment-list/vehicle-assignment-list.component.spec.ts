import { ComponentFixture, TestBed } from '@angular/core/testing';
import { of } from 'rxjs';

import { NotificationService } from '@services/notification.service';
import { VehicleDriverService } from '@services/vehicle-driver.service';
import { VehicleAssignmentListComponent } from './vehicle-assignment-list';

describe('VehicleAssignmentListComponent', () => {
  let component: VehicleAssignmentListComponent;
  let fixture: ComponentFixture<VehicleAssignmentListComponent>;
  let notificationSpy: jasmine.SpyObj<NotificationService>;
  let vehicleDriverSpy: jasmine.SpyObj<VehicleDriverService>;

  beforeEach(async () => {
    spyOn(VehicleAssignmentListComponent.prototype as any, 'load').and.returnValue(
      Promise.resolve(),
    );

    notificationSpy = jasmine.createSpyObj<NotificationService>('NotificationService', [
      'simulateNotification',
    ]);
    vehicleDriverSpy = jasmine.createSpyObj<VehicleDriverService>('VehicleDriverService', [
      'assignTruckToDriver',
    ]);
    vehicleDriverSpy.assignTruckToDriver.and.returnValue(of({ success: true } as any));

    await TestBed.configureTestingModule({
      imports: [VehicleAssignmentListComponent],
      providers: [
        { provide: NotificationService, useValue: notificationSpy },
        { provide: VehicleDriverService, useValue: vehicleDriverSpy },
      ],
    }).compileComponents();

    fixture = TestBed.createComponent(VehicleAssignmentListComponent);
    component = fixture.componentInstance;
    fixture.detectChanges();
  });

  it('should skip API call when selecting the same already assigned driver', async () => {
    component.selectedVehicleId = 10;
    component.selectedVehicleCode = '3B-9150';
    component.currentDriverId = 33;
    component.showAssignModal = true;

    await component.handleAssignDriverWithOptions({ driverId: 33, forceReassignment: false });

    expect(vehicleDriverSpy.assignTruckToDriver).not.toHaveBeenCalled();
    expect(notificationSpy.simulateNotification).toHaveBeenCalledWith(
      'Info',
      'Driver is already assigned to vehicle 3B-9150.',
    );
    expect(component.showAssignModal).toBeFalse();
  });

  it('should force reassignment when changing to another driver', async () => {
    component.selectedVehicleId = 88;
    component.currentDriverId = 21;

    await component.handleAssignDriverWithOptions({ driverId: 22, forceReassignment: false });

    expect(vehicleDriverSpy.assignTruckToDriver).toHaveBeenCalledWith(
      jasmine.objectContaining({
        driverId: 22,
        vehicleId: 88,
        forceReassignment: true,
      }),
    );
  });

  it('should pass explicit forceReassignment option from modal payload', async () => {
    component.selectedVehicleId = 99;
    component.currentDriverId = null;

    await component.handleAssignDriverWithOptions({ driverId: 44, forceReassignment: true });

    expect(vehicleDriverSpy.assignTruckToDriver).toHaveBeenCalledWith(
      jasmine.objectContaining({
        driverId: 44,
        vehicleId: 99,
        forceReassignment: true,
      }),
    );
  });
});
