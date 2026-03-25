import { TestBed } from '@angular/core/testing';
import { of } from 'rxjs';

import { AuthService } from '../../services/auth.service';
import { NotificationService } from '../../services/notification.service';
import { KhbTripPlannerComponent } from './khb-trip-planner.component';

describe('KhbTripPlannerComponent', () => {
  let component: KhbTripPlannerComponent;
  let notificationSpy: jasmine.SpyObj<NotificationService>;

  beforeEach(async () => {
    const authSpy = jasmine.createSpyObj('AuthService', ['getToken']);
    authSpy.getToken.and.returnValue('token');
    notificationSpy = jasmine.createSpyObj('NotificationService', ['simulateNotification']);

    await TestBed.configureTestingModule({
      imports: [KhbTripPlannerComponent],
      providers: [
        { provide: AuthService, useValue: authSpy },
        { provide: NotificationService, useValue: notificationSpy },
      ],
    }).compileComponents();

    const fixture = TestBed.createComponent(KhbTripPlannerComponent);
    component = fixture.componentInstance;
  });

  it('resolves driver from vehicle lookup for normalized truck plates', async () => {
    (component as any).vehicleLookupLoaded = true;
    (component as any).plateToDriverName.set('KH1234', 'Driver Lookup');

    component.trips = [
      {
        tripNo: 'T1',
        plant: 'KHB',
        assignedVehicleNumber: ' KH-1234 ',
        palletEstimate: 1,
        quantity: 10,
        distributorCode: 'D1',
      },
    ];

    await (component as any).processTripData();
    expect(component.trips[0].displayDriverName).toBe('Driver Lookup');
  });

  it('falls back to legacy row driverFullName when lookup is missing', async () => {
    (component as any).vehicleLookupLoaded = true;
    component.trips = [
      {
        tripNo: 'T2',
        plant: 'KHB',
        truckNo: 'NO-MATCH',
        driverFullName: 'Legacy Driver',
        palletEstimate: 1,
        quantity: 10,
        distributorCode: 'D1',
      },
    ];

    await (component as any).processTripData();

    expect(component.trips[0].displayDriverName).toBe('Legacy Driver');
  });

  it('sets Unassigned when neither lookup nor row driver exists', async () => {
    (component as any).vehicleLookupLoaded = true;
    component.trips = [
      {
        tripNo: 'T3',
        plant: 'KHB',
        truckNo: 'NO-DRIVER',
        palletEstimate: 1,
        quantity: 10,
        distributorCode: 'D1',
      },
    ];

    await (component as any).processTripData();

    expect(component.trips[0].displayDriverName).toBe('Unassigned');
  });

  it('includes driverName in temp preview payload', () => {
    const postSpy = spyOn((component as any).http, 'post').and.returnValue(of({}));
    component.uploadDate = '2026-03-04';
    component.trips = [
      {
        tripNo: 'T4',
        assignedVehicleNumber: 'KH-9999',
        dropOffLocation: 'Test Drop',
        productName: 'Water',
        quantity: 1,
        displayDriverName: 'Payload Driver',
      },
    ];

    component.saveToTempPreview();

    expect(postSpy).toHaveBeenCalled();
    const [url, payload] = postSpy.calls.mostRecent().args;
    expect(url).toContain('/api/khb-so-upload/plan-trip/preview');
    expect(payload[0].driverName).toBe('Payload Driver');
  });
});
