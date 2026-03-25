import { ComponentFixture, TestBed } from '@angular/core/testing';
import { BehaviorSubject, of } from 'rxjs';
import { ActivatedRoute, convertToParamMap, Router } from '@angular/router';

import { CustomerBillToAddressService } from '../../services/customer-bill-to-address.service';
import { CustomerService } from '../../services/custommer.service';
import { TransportOrderService } from '../../services/transport-order.service';
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
      imports: [TransportOrderComponent],
      providers: [
        { provide: TransportOrderService, useValue: orderServiceMock },
        { provide: CustomerService, useValue: customerServiceMock },
        { provide: CustomerBillToAddressService, useValue: customerBillToAddressServiceMock },
        { provide: ToastService, useValue: toastServiceMock },
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
  });

  it('prefills customer when customerId query param is provided', () => {
    queryParamMap$.next(convertToParamMap({ customerId: '147' }));

    expect(customerServiceMock.getCustomerById).toHaveBeenCalledWith(147);
    expect(component.transportOrderForm.get('customer.customerId')?.value).toBe(147);
    expect(component.transportOrderForm.get('customer.customerName')?.value).toBe('SV Customer');
  });

  it('submits create form and calls createOrder', () => {
    component.transportOrderForm.patchValue({
      customer: { customerId: 147, customerName: 'SV Customer' },
      customerId: 147,
      deliveryDate: '2026-03-01',
      orderDate: '2026-02-28',
      shipmentType: 'FTL',
      status: 'PENDING',
    });
    component.getPickupFormGroup(0).patchValue({ id: 10, name: 'P1', address: 'Pickup address' });
    component.getDropFormGroup(0).patchValue({ id: 20, name: 'D1', address: 'Drop address' });

    component.submitForm();

    expect(orderServiceMock.createOrder).toHaveBeenCalled();
    expect(toastServiceMock.success).toHaveBeenCalled();
  });

  it('loads edit mode by route id and calls updateOrder on submit', () => {
    paramMap$.next(convertToParamMap({ id: '1' }));
    fixture.detectChanges();

    expect(component.mode).toBe('edit');
    expect(component.orderId).toBe(1);
    expect(component.transportOrderForm.get('orderReference')?.value).toBe('ORD-EDIT-1');

    component.submitForm();
    expect(orderServiceMock.updateOrder).toHaveBeenCalledWith(1, jasmine.any(Object));
  });
});
