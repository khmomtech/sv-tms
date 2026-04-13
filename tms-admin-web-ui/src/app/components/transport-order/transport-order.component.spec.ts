import { ComponentFixture, TestBed } from '@angular/core/testing';
import { BehaviorSubject, of } from 'rxjs';
import { throwError } from 'rxjs';
import { ActivatedRoute, convertToParamMap, Router } from '@angular/router';
import { TranslateFakeLoader, TranslateLoader, TranslateModule } from '@ngx-translate/core';

import { CustomerBillToAddressService } from '../../services/customer-bill-to-address.service';
import { CustomerService } from '../../services/custommer.service';
import { DispatchService } from '../../services/dispatch.service';
import { DriverService } from '../../services/driver.service';
import { TransportOrderService } from '../../services/transport-order.service';
import { VehicleService } from '../../services/vehicle.service';
import { ToastService } from '../../shared/services/toast.service';
import { TransportOrderComponent } from './transport-order.component';

describe('TransportOrderComponent', () => {
  let component: TransportOrderComponent;
  let fixture: ComponentFixture<TransportOrderComponent>;

  const queryParamMap$ = new BehaviorSubject(convertToParamMap({}));
  const paramMap$ = new BehaviorSubject(convertToParamMap({}));

  const orderServiceMock = {
    getOrders: jasmine.createSpy('getOrders').and.returnValue(of({ data: { content: [] } })),
    getShipmentTypes: jasmine.createSpy('getShipmentTypes').and.returnValue(of(['FTL'])),
    getAvailableSellers: jasmine
      .createSpy('getAvailableSellers')
      .and.returnValue(of({ data: [{ id: 1, fullName: 'Seller A' }] })),
    getOrderById: jasmine.createSpy('getOrderById').and.returnValue(
      of({
        data: {
          id: 1,
          orderReference: 'ORD-EDIT-1',
          customerId: 147,
          customerName: 'SV Customer',
          orderDate: '2026-02-28',
          deliveryDate: '2026-03-01',
          shipmentType: 'FTL',
          status: 'PENDING',
          pickupAddresses: [{ id: 10, name: 'P1', address: 'Pickup address' }],
          dropAddresses: [{ id: 20, name: 'D1', address: 'Drop address' }],
          items: [],
        },
      }),
    ),
    createOrder: jasmine.createSpy('createOrder').and.returnValue(of({ data: { id: 9 } })),
    updateOrder: jasmine.createSpy('updateOrder').and.returnValue(of({ data: { id: 1 } })),
  };

  const customerServiceMock = {
    getAllCustomers: jasmine.createSpy('getAllCustomers').and.returnValue(
      of({
        data: {
          content: [{ id: 147, name: 'SV Customer' }],
        },
      }),
    ),
    searchCustomers: jasmine.createSpy('searchCustomers').and.returnValue(
      of({
        data: {
          content: [{ id: 147, name: 'SV Customer' }],
        },
      }),
    ),
    getCustomerById: jasmine.createSpy('getCustomerById').and.returnValue(
      of({
        data: { customer: { id: 147, name: 'SV Customer' } },
      }),
    ),
  };

  const customerBillToAddressServiceMock = {
    search: jasmine.createSpy('search').and.returnValue(of({ data: { content: [] } })),
    list: jasmine.createSpy('list').and.returnValue(of({ data: [] })),
  };

  const dispatchServiceMock = {
    createDispatch: jasmine.createSpy('createDispatch').and.returnValue(of({ data: { id: 88 } })),
  };

  const driverServiceMock = {
    getAllDriversModal: jasmine.createSpy('getAllDriversModal').and.returnValue(
      of({
        data: [
          {
            id: 5,
            name: 'Driver One',
            fullName: 'Driver One',
            phone: '012345678',
            licenseNumber: 'LIC-001',
            currentVehicleId: 8,
          },
        ],
      }),
    ),
  };

  const vehicleServiceMock = {
    getAllVehicles: jasmine.createSpy('getAllVehicles').and.returnValue(
      of({
        data: [
          {
            id: 8,
            licensePlate: '3E-0293',
            type: 'TRUCK',
            model: 'Hino',
            status: 'ACTIVE',
            assignedDriver: {
              id: 5,
              name: 'Driver One',
            },
          },
        ],
      }),
    ),
  };

  const toastServiceMock = {
    success: jasmine.createSpy('success'),
    error: jasmine.createSpy('error'),
    info: jasmine.createSpy('info'),
  };

  const routerMock = {
    navigate: jasmine.createSpy('navigate').and.returnValue(Promise.resolve(true)),
  };

  beforeEach(async () => {
    await TestBed.configureTestingModule({
      imports: [
        TransportOrderComponent,
        TranslateModule.forRoot({
          loader: { provide: TranslateLoader, useClass: TranslateFakeLoader },
        }),
      ],
      providers: [
        { provide: TransportOrderService, useValue: orderServiceMock },
        { provide: CustomerService, useValue: customerServiceMock },
        { provide: CustomerBillToAddressService, useValue: customerBillToAddressServiceMock },
        { provide: DispatchService, useValue: dispatchServiceMock },
        { provide: DriverService, useValue: driverServiceMock },
        { provide: ToastService, useValue: toastServiceMock },
        { provide: VehicleService, useValue: vehicleServiceMock },
        { provide: Router, useValue: routerMock },
        {
          provide: ActivatedRoute,
          useValue: {
            queryParamMap: queryParamMap$.asObservable(),
            paramMap: paramMap$.asObservable(),
          },
        },
      ],
    })
      .overrideComponent(TransportOrderComponent, {
        set: {
          template: '<form [formGroup]="transportOrderForm"></form>',
        },
      })
      .compileComponents();

    fixture = TestBed.createComponent(TransportOrderComponent);
    component = fixture.componentInstance;
    fixture.detectChanges();
  });

  afterEach(() => {
    queryParamMap$.next(convertToParamMap({}));
    paramMap$.next(convertToParamMap({}));
    orderServiceMock.createOrder.calls.reset();
    orderServiceMock.updateOrder.calls.reset();
    customerBillToAddressServiceMock.list.calls.reset();
    dispatchServiceMock.createDispatch.calls.reset();
    dispatchServiceMock.createDispatch.and.returnValue(of({ data: { id: 88 } }));
    routerMock.navigate.calls.reset();
    toastServiceMock.success.calls.reset();
    toastServiceMock.error.calls.reset();
  });

  it('prefills customer when customerId query param is provided', () => {
    queryParamMap$.next(convertToParamMap({ customerId: '147' }));

    expect(customerServiceMock.getCustomerById).toHaveBeenCalledWith(147);
    expect(component.transportOrderForm.get('customer.customerId')?.value).toBe(147);
    expect(component.transportOrderForm.get('customer.customerName')?.value).toBe('SV Customer');
  });

  it('submits create form and creates both order and dispatch when assignment is enabled', () => {
    component.transportOrderForm.patchValue({
      customer: { customerId: 147, customerName: 'SV Customer' },
      customerId: 147,
      deliveryDate: '2026-03-01',
      orderDate: '2026-02-28',
      shipmentType: 'FTL',
      status: 'PENDING',
      dispatchAssignment: {
        createDispatchNow: true,
        driverId: 5,
        vehicleId: 8,
      },
    });
    component.getPickupFormGroup(0).patchValue({ id: 10, name: 'P1', address: 'Pickup address' });
    component.getDropFormGroup(0).patchValue({ id: 20, name: 'D1', address: 'Drop address' });

    component.submitForm();

    expect(orderServiceMock.createOrder).toHaveBeenCalled();
    expect(dispatchServiceMock.createDispatch).toHaveBeenCalledWith(
      jasmine.objectContaining({
        transportOrderId: 9,
        driverId: 5,
        vehicleId: 8,
      }),
    );
    expect(routerMock.navigate).toHaveBeenCalledWith(['/dispatch']);
  });

  it('loads edit mode by route id and calls updateOrder on submit', () => {
    paramMap$.next(convertToParamMap({ id: '1' }));
    fixture.detectChanges();

    expect(component.mode).toBe('edit');
    expect(component.orderId).toBe(1);
    expect(component.transportOrderForm.get('orderReference')?.value).toBe('ORD-EDIT-1');
    expect(component.transportOrderForm.get('customer.customerId')?.value).toBe(147);
    expect(component.transportOrderForm.get('customer.customerName')?.value).toBe('SV Customer');
    expect(component.customerOptions.some((customer) => customer.id === 147)).toBeTrue();
    expect(customerBillToAddressServiceMock.list).toHaveBeenCalledWith(147);

    component.submitForm();
    expect(orderServiceMock.updateOrder).toHaveBeenCalledWith(1, jasmine.any(Object));
    expect(orderServiceMock.updateOrder.calls.mostRecent().args[1]).toEqual(
      jasmine.objectContaining({
        pickupAddresses: [jasmine.objectContaining({ id: 10, name: 'P1' })],
        dropAddresses: [jasmine.objectContaining({ id: 20, name: 'D1' })],
        pickupLocations: [jasmine.objectContaining({ id: 10, name: 'P1' })],
        dropLocations: [jasmine.objectContaining({ id: 20, name: 'D1' })],
      }),
    );
  });

  it('auto-selects the assigned vehicle when a driver is selected', () => {
    component.dispatchAssignmentForm.patchValue({
      createDispatchNow: true,
      driverId: 5,
      vehicleId: null,
    });

    component.onDispatchDriverChange(5);

    expect(component.dispatchAssignmentForm.get('vehicleId')?.value).toBe(8);
  });

  it('auto-selects the assigned driver when a vehicle is selected', () => {
    component.dispatchAssignmentForm.patchValue({
      createDispatchNow: true,
      driverId: null,
      vehicleId: 8,
    });

    component.onDispatchVehicleChange(8);

    expect(component.dispatchAssignmentForm.get('driverId')?.value).toBe(5);
  });

  it('keeps the saved order and surfaces a readable message when dispatch creation fails', () => {
    dispatchServiceMock.createDispatch.and.returnValue(
      throwError(() => ({
        error: {
          message: 'Failed to create dispatch',
          errors: {
            driverId: 'Driver must have a valid license number',
          },
        },
      })),
    );

    component.transportOrderForm.patchValue({
      customer: { customerId: 147, customerName: 'SV Customer' },
      customerId: 147,
      deliveryDate: '2026-03-01',
      orderDate: '2026-02-28',
      shipmentType: 'FTL',
      status: 'PENDING',
      dispatchAssignment: {
        createDispatchNow: true,
        driverId: 5,
        vehicleId: 8,
      },
    });
    component.getPickupFormGroup(0).patchValue({ id: 10, name: 'P1', address: 'Pickup address' });
    component.getDropFormGroup(0).patchValue({ id: 20, name: 'D1', address: 'Drop address' });

    component.submitForm();

    expect(orderServiceMock.createOrder).toHaveBeenCalled();
    expect(dispatchServiceMock.createDispatch).toHaveBeenCalled();
    expect(toastServiceMock.success).toHaveBeenCalledWith(
      'orders.form.messages.created_success',
    );
    expect(toastServiceMock.error).toHaveBeenCalledWith(
      'Dispatch could not be created. Driver must have a valid license number The order is already saved and ready to edit.',
    );
    expect(routerMock.navigate).toHaveBeenCalledWith(['/orders', 9, 'edit']);
  });
});
