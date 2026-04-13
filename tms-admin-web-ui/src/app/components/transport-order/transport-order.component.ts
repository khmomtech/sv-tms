/* eslint-disable @typescript-eslint/consistent-type-imports */
import { CommonModule } from '@angular/common';
import { Component, OnInit, OnDestroy, ChangeDetectorRef, HostListener } from '@angular/core';
import {
  FormBuilder,
  Validators,
  FormsModule,
  ReactiveFormsModule,
  FormGroup,
  FormArray,
} from '@angular/forms';
import { MatExpansionModule } from '@angular/material/expansion';
import { TranslateModule, TranslateService } from '@ngx-translate/core';
import { ActivatedRoute, Router } from '@angular/router';
import { NgSelectModule } from '@ng-select/ng-select';

import { Subject } from 'rxjs';
import { takeUntil } from 'rxjs/operators';

import type { Customer } from '../../models/customer.model';
import type { Dispatch } from '../../models/dispatch.model';
import type { Driver } from '../../models/driver.model';
import type { OrderStatus } from '../../models/order-status.enum';
import type { TransportOrderResponseDto } from '../../models/transport-order-response.model';
import type { Vehicle } from '../../models/vehicle.model';

import { CustomerBillToAddressService } from '../../services/customer-bill-to-address.service';
import { CustomerService } from '../../services/custommer.service';
import { DispatchService } from '../../services/dispatch.service';
import { DriverService } from '../../services/driver.service';
import { TransportOrderService } from '../../services/transport-order.service';
import { VehicleService } from '../../services/vehicle.service';
import { ToastService } from '../../shared/services/toast.service';
import { AppAddressModalComponent } from '../app-address-modal/app-address-modal.component';
import { AppCustomerModalComponent } from '../app-customer-modal/app-customer-modal.component';
import { AppItemModalComponent } from '../app-item-modal/app-item-modal.component';
import { CreateAddressModalComponent } from '../create-address-modal/create-address-modal.component';

@Component({
  selector: 'app-transport-order',
  templateUrl: './transport-order.component.html',
  styleUrls: ['./transport-order.component.css'],
  standalone: true,
  imports: [
    CommonModule,
    FormsModule,
    ReactiveFormsModule,
    AppAddressModalComponent,
    AppCustomerModalComponent,
    AppItemModalComponent,
    MatExpansionModule,
    TranslateModule,
    NgSelectModule,
    CreateAddressModalComponent,
  ],
})
export class TransportOrderComponent implements OnInit, OnDestroy {
  // ...existing properties...
  constructor(
    private readonly fb: FormBuilder,
    private readonly orderService: TransportOrderService,
    private readonly customerService: CustomerService,
    private readonly customerBillToAddressService: CustomerBillToAddressService,
    private readonly dispatchService: DispatchService,
    private readonly driverService: DriverService,
    private readonly vehicleService: VehicleService,
    private readonly cdr: ChangeDetectorRef,
    private readonly route: ActivatedRoute,
    public readonly router: Router,
    private readonly toastService: ToastService,
    private readonly translate: TranslateService,
  ) {}

  loadOrder(orderId: number): void {
    this.orderService.getOrderById(orderId).subscribe({
      next: (response: any) => {
        const order = response?.data;
        if (!order) {
          this.toastService.error(this.translate.instant('orders.form.messages.order_not_found'));
          return;
        }
        this.selectedOrder = order;
        this.patchOrderForm(order);
      },
      error: (err: any) => {
        this.toastService.error(
          err?.message || this.translate.instant('orders.form.messages.load_failed'),
        );
      },
    });
  }

  @HostListener('document:mousedown', ['$event'])
  onDocumentMouseDown(event: MouseEvent): void {
    const target = event.target as HTMLElement | null;
    if (!target?.closest('.dispatch-selector')) {
      this.driverSelectorOpen = false;
      this.vehicleSelectorOpen = false;
      this.driverSearchTerm = this.selectedDispatchDriverOption?.label ?? '';
      this.vehicleSearchTerm = this.selectedDispatchVehicleOption?.label ?? '';
    }
  }
  // --- Template-required properties and methods ---
  fetchShipmentTypes(): void {
    this.orderService.getShipmentTypes().subscribe({
      next: (payload: unknown) => {
        this.shipmentTypes = this.normalizeStringArray(payload);
      },
      error: (err) => {
        if (err && err.message && err.message.toLowerCase().includes('jwt')) {
          this.toastService.error(
            this.translate.instant('orders.form.messages.auth_error'),
          );
          // Optionally, force logout or redirect
          // this.authService.logout();
        } else {
          this.toastService.error(this.translate.instant('orders.form.messages.shipment_types_failed'));
        }
      },
    });
  }
  get pickupLocations(): FormArray {
    return this.transportOrderForm.get('pickupLocations') as FormArray;
  }
  get dropLocations(): FormArray {
    return this.transportOrderForm.get('dropLocations') as FormArray;
  }
  get items(): FormArray {
    return this.transportOrderForm.get('items') as FormArray;
  }

  getPickupFormGroup(index: number): FormGroup {
    return this.pickupLocations.at(index) as FormGroup;
  }
  getDropFormGroup(index: number): FormGroup {
    return this.dropLocations.at(index) as FormGroup;
  }
  getItemFormGroup(index: number): FormGroup {
    return this.items.at(index) as FormGroup;
  }

  addPickup(): void {
    this.addPickupLocation();
  }
  removePickup(index: number): void {
    this.pickupLocations.removeAt(index);
  }
  addDrop(): void {
    this.addDropLocation();
  }
  removeDrop(index: number): void {
    this.dropLocations.removeAt(index);
  }
  addItem(item: any): void {
    this.items.push(this.createItemFormGroup(item));
  }
  removeItem(index: number): void {
    this.items.removeAt(index);
  }
  calculateTotalWeight(): number {
    return this.items.controls.reduce(
      (sum, group: any) => sum + (group.get('weight')?.value || 0),
      0,
    );
  }
  calculateTotalQuantity(): number {
    return this.items.controls.reduce(
      (sum, group: any) => sum + Number(group.get('quantity')?.value || 0),
      0,
    );
  }
  clearForm(): void {
    this.transportOrderForm.reset();
    this.initializeForm();
  }

  submitForm(): void {
    this.syncHeaderAddressesFromLocations();

    if (this.transportOrderForm.invalid) {
      this.transportOrderForm.markAllAsTouched();
      this.toastService.error(this.translate.instant('orders.form.messages.required_fields'));
      return;
    }
    const hasPickupStop = this.pickupLocations.controls.some(
      (group) =>
        Number.isFinite(Number(group.get('id')?.value)) && Number(group.get('id')?.value) > 0,
    );
    const hasDropStop = this.dropLocations.controls.some(
      (group) =>
        Number.isFinite(Number(group.get('id')?.value)) && Number(group.get('id')?.value) > 0,
    );
    if (!hasPickupStop || !hasDropStop) {
      this.toastService.error(
        this.translate.instant('orders.form.messages.pickup_drop_required'),
      );
      return;
    }

    if (this.isSubmitting) return;
    this.isSubmitting = true;
    if (this.shouldCreateDispatch && !this.hasValidDispatchAssignment()) {
      this.isSubmitting = false;
      this.dispatchAssignmentValidationAttempted = true;
      this.dispatchAssignmentForm.markAllAsTouched();
      this.toastService.error(this.translate.instant('orders.form.messages.dispatch_assignment_required'));
      return;
    }

    const payload =
      this.mode === 'edit' && this.orderId
        ? this.buildUpdateOrderPayload()
        : this.buildCreateOrderPayload();
    const request$ =
      this.mode === 'edit' && this.orderId
        ? this.orderService.updateOrder(this.orderId, payload)
        : this.orderService.createOrder(payload);

    request$.subscribe({
      next: (response: any) => {
        if (this.mode === 'create' && this.shouldCreateDispatch) {
          const createdOrderId = this.resolveOrderId(response);
          if (!createdOrderId) {
            this.isSubmitting = false;
            this.toastService.error(
              this.translate.instant('orders.form.messages.dispatch_missing_order_id'),
            );
            void this.router.navigate(['/orders']);
            return;
          }

          const createdOrderReference = response?.data?.orderReference ?? payload?.orderReference ?? '';
          this.createDispatchAfterOrder(createdOrderId, createdOrderReference);
          return;
        }

        this.isSubmitting = false;
        this.toastService.success(
          this.mode === 'edit'
            ? this.translate.instant('orders.form.messages.updated_success')
            : this.translate.instant('orders.form.messages.created_success'),
        );
        void this.router.navigate(['/orders']);
      },
      error: (err: any) => {
        this.isSubmitting = false;
        this.toastService.error(err?.message || this.translate.instant('orders.form.messages.save_failed'));
      },
    });
  }

  openCustomerModal(): void {
    this.isCustomerModalOpen = true;
  }
  closeCustomerModal(): void {
    this.isCustomerModalOpen = false;
  }
  selectCustomer(customer: any): void {
    this.upsertCustomerOption(customer);
    this.transportOrderForm.patchValue({
      customer: {
        customerId: customer.id,
        customerName: customer.name,
      },
      customerId: customer.id,
    });
    this.closeCustomerModal();
  }

  openAddressModal(type: 'PICKUP' | 'DROP', index: number): void {
    this.addressSelectionType = type;
    this.selectedAddressIndex = index;
    this.isAddressModalOpen = true;
  }
  closeAddressModal(): void {
    this.isAddressModalOpen = false;
  }
  selectAddress(address: any): void {
    if (this.addressSelectionType === 'PICKUP') {
      this.getPickupFormGroup(this.selectedAddressIndex).patchValue(address);
    } else {
      this.getDropFormGroup(this.selectedAddressIndex).patchValue(address);
    }
    this.closeAddressModal();
  }

  openItemModal(): void {
    this.isItemModalOpen = true;
  }
  closeItemModal(): void {
    this.isItemModalOpen = false;
  }
  ngOnInit(): void {
    this.initializeForm();
    this.setupDispatchAssignmentSync();
    // Defensive reset so template iterables remain stable even if state was mutated.
    this.couriers = [...this.defaultCouriers];
    this.orderStatuses = [...this.defaultOrderStatuses];
    this.route.paramMap.pipe(takeUntil(this.destroy$)).subscribe((params) => {
      const id = Number(params.get('id'));
      if (Number.isFinite(id) && id > 0) {
        this.mode = 'edit';
        this.orderId = id;
        this.loadOrder(id);
      } else {
        this.mode = 'create';
        this.orderId = null;
      }
    });
    this.route.queryParamMap.pipe(takeUntil(this.destroy$)).subscribe((params) => {
      const customerId = params.get('customerId');
      if (!customerId || this.mode === 'edit') return;
      this.fetchCustomerAndBind(customerId);
    });
    this.fetchOrders();
    this.loadSellers();
    this.fetchShipmentTypes();
    this.loadInitialCustomers();
    this.loadDispatchResources();
  }

  addPickupLocation(): void {
    const pickupLocations = this.transportOrderForm.get('pickupLocations') as FormArray;
    if (pickupLocations) {
      pickupLocations.push(this.createAddressFormGroup());
    }
  }

  addDropLocation(): void {
    const dropLocations = this.transportOrderForm.get('dropLocations') as FormArray;
    if (dropLocations) {
      dropLocations.push(this.createAddressFormGroup());
    }
  }
  shipmentTypes: string[] = [];
  customerOptions: Customer[] = [];
  isCustomerLoading = false;
  private destroy$ = new Subject<void>();
  billToAddresses: any[] = [];
  isBillToLoading = false;
  isCreateBillToAddressModalOpen = false;
  isBillToModalOpen = false;

  transportOrderForm!: FormGroup;
  orders: TransportOrderResponseDto[] = [];
  errorMessage: string = '';
  searchQuery: string = '';
  filterStatus: OrderStatus | null = null;
  page: number = 0;
  size: number = 10;
  mode: 'create' | 'edit' = 'create';
  orderId: number | null = null;

  isCustomerModalOpen = false;
  isAddressModalOpen = false;
  isItemModalOpen = false;
  selectedOrder: TransportOrderResponseDto | null = null;

  addressSelectionType!: 'PICKUP' | 'DROP';
  selectedAddressIndex!: number;
  isSubmitting = false;
  dispatchAssignmentValidationAttempted = false;
  loadingDrivers = false;
  loadingVehicles = false;
  driverSelectorOpen = false;
  vehicleSelectorOpen = false;
  driverSearchTerm = '';
  vehicleSearchTerm = '';

  sellers: any[] = [];
  drivers: Driver[] = [];
  vehicles: Vehicle[] = [];
  private readonly defaultCouriers: string[] = ['CHHAY_Y', 'SV', 'Partner', 'Other'];
  couriers: string[] = [...this.defaultCouriers];

  private readonly defaultOrderStatuses: string[] = [
    'PENDING',
    'ASSIGNED',
    'DRIVER_CONFIRMED',
    'APPROVED',
    'REJECTED',
    'SCHEDULED',
    'ARRIVED_LOADING',
    'LOADING',
    'LOADED',
    'IN_TRANSIT',
    'ARRIVED_UNLOADING',
    'UNLOADING',
    'UNLOADED',
    'DELIVERED',
    'COMPLETED',
    'CANCELLED',
  ];
  orderStatuses: string[] = [...this.defaultOrderStatuses];

  initializeForm(): void {
    this.transportOrderForm = this.fb.group({
      customer: this.fb.group({
        customerId: ['', Validators.required],
        customerName: ['', Validators.required],
      }),
      customerId: ['', Validators.required],
      orderReference: ['', Validators.required],
      billTo: [''],
      orderDate: [new Date().toISOString().split('T')[0], Validators.required],
      deliveryDate: ['', Validators.required],
      shipmentType: ['FTL', Validators.required],
      courierAssigned: [''],
      status: ['PENDING'],
      sellerId: [null],
      pickupAddress: this.fb.group({
        id: [null],
        name: [''],
        address: [''],
        postcode: [''],
        contactName: [''],
        contactPhone: [''],
        country: [''],
        scheduledTime: [''],
      }),
      dropAddress: this.fb.group({
        id: [null],
        name: [''],
        address: [''],
        postcode: [''],
        contactName: [''],
        contactPhone: [''],
        country: [''],
        scheduledTime: [''],
      }),
      pickupLocations: this.fb.array([]),
      dropLocations: this.fb.array([]),
      items: this.fb.array([]),
      dispatchAssignment: this.fb.group({
        createDispatchNow: [true],
        driverId: [null],
        vehicleId: [null],
        manualRouteCode: [''],
        notes: [''],
      }),
    });
    this.transportOrderForm.patchValue({
      orderReference: 'ORD-' + Math.floor(Math.random() * 10000),
    });
    this.addPickupLocation();
    this.addDropLocation();
    // Optionally sync validators
  }

  private setupDispatchAssignmentSync(): void {
    this.dispatchAssignmentForm
      .get('createDispatchNow')
      ?.valueChanges.pipe(takeUntil(this.destroy$))
      .subscribe((enabled) => {
        this.dispatchAssignmentValidationAttempted = false;
        if (!enabled) {
          this.dispatchAssignmentForm.patchValue(
            {
              driverId: null,
              vehicleId: null,
              manualRouteCode: '',
              notes: '',
            },
            { emitEvent: false },
          );
          this.driverSearchTerm = '';
          this.vehicleSearchTerm = '';
        }

        this.dispatchAssignmentForm.markAsPristine();
        this.dispatchAssignmentForm.markAsUntouched();
        this.dispatchAssignmentForm.get('driverId')?.markAsPristine();
        this.dispatchAssignmentForm.get('driverId')?.markAsUntouched();
        this.dispatchAssignmentForm.get('vehicleId')?.markAsPristine();
        this.dispatchAssignmentForm.get('vehicleId')?.markAsUntouched();
      });

    this.dispatchAssignmentForm
      .get('driverId')
      ?.valueChanges.pipe(takeUntil(this.destroy$))
      .subscribe((value) => {
        this.dispatchAssignmentValidationAttempted = false;
        const selectedDriverId = this.normalizeSelectedId(value);
        this.driverSearchTerm = this.selectedDispatchDriverOption?.label ?? '';
        if (!selectedDriverId) return;
        const preferredVehicleId = this.getAssignedVehicleIdForDriver(selectedDriverId);
        const currentVehicleId = this.normalizeSelectedId(
          this.dispatchAssignmentForm.get('vehicleId')?.value,
        );
        if (preferredVehicleId && currentVehicleId !== preferredVehicleId) {
          this.dispatchAssignmentForm.patchValue({ vehicleId: preferredVehicleId });
        }
      });

    this.dispatchAssignmentForm
      .get('vehicleId')
      ?.valueChanges.pipe(takeUntil(this.destroy$))
      .subscribe((value) => {
        this.dispatchAssignmentValidationAttempted = false;
        const selectedVehicleId = this.normalizeSelectedId(value);
        this.vehicleSearchTerm = this.selectedDispatchVehicleOption?.label ?? '';
        if (!selectedVehicleId) return;
        const preferredDriverId = this.getAssignedDriverIdForVehicle(selectedVehicleId);
        const currentDriverId = this.normalizeSelectedId(
          this.dispatchAssignmentForm.get('driverId')?.value,
        );
        if (preferredDriverId && currentDriverId !== preferredDriverId) {
          this.dispatchAssignmentForm.patchValue({ driverId: preferredDriverId });
        }
      });
  }

  fetchOrders(): void {
    this.orderService.getOrders(this.page, this.size).subscribe({
      next: (response: any) => {
        const content = response?.data?.content;
        this.orders = Array.isArray(content) ? content : [];
      },
      error: (err: any) => {
        this.errorMessage = err.message;
      },
    });
  }

  loadSellers(): void {
    this.orderService.getAvailableSellers().subscribe({
      next: (response: any) => {
        const raw = this.normalizeObjectArray(response?.data, response?.data?.content);
        this.sellers = raw.map((seller: any) => ({
          id: seller?.id,
          fullName:
            seller?.fullName ??
            seller?.name ??
            `${seller?.firstName ?? ''} ${seller?.lastName ?? ''}`.trim(),
        }));
      },
      error: () => {
        // Keep form usable even if seller API is temporarily unavailable.
        this.sellers = [];
      },
    });
  }

  fetchCustomerAndBind(customerId: string): void {
    const parsedCustomerId = Number(customerId);
    if (!Number.isFinite(parsedCustomerId) || parsedCustomerId <= 0) {
      return;
    }

    this.customerService.getCustomerById(parsedCustomerId).subscribe({
      next: (response: any) => {
        const customer = response?.data?.customer ?? response?.data ?? response?.customer;
        if (customer) {
          const customerKey = customer?.id ?? parsedCustomerId;
          const customerName = customer?.name ?? customer?.customerName ?? customer?.fullName ?? '';
          this.upsertCustomerOption({
            ...customer,
            id: customerKey,
            name: customerName,
          });
          this.transportOrderForm.patchValue({
            customer: {
              customerId: customerKey,
              customerName,
            },
            customerId: customerKey,
          });
          this.loadBillToAddresses(customerKey);
        }
      },
      error: (err: any) => {
        this.toastService.error(this.translate.instant('orders.form.messages.customer_fetch_failed'));
      },
    });
  }

  loadInitialCustomers(): void {
    this.isCustomerLoading = true;
    this.customerService.getAllCustomers(0, 20).subscribe({
      next: (result) => {
        this.customerOptions = this.mergeCustomerOptions(
          Array.isArray(result?.content) ? result.content : [],
        );
        this.isCustomerLoading = false;
      },
      error: () => {
        this.customerOptions = this.mergeCustomerOptions([]);
        this.isCustomerLoading = false;
      },
    });
  }

  onCustomerSearch(term: string): void {
    const query = term?.trim();
    if (!query) {
      this.loadInitialCustomers();
      return;
    }

    this.isCustomerLoading = true;
    this.customerService.searchCustomers(query).subscribe({
      next: (customers) => {
        this.customerOptions = this.mergeCustomerOptions(Array.isArray(customers) ? customers : []);
        this.isCustomerLoading = false;
      },
      error: () => {
        this.customerOptions = this.mergeCustomerOptions([]);
        this.isCustomerLoading = false;
        this.toastService.error(this.translate.instant('orders.form.messages.customer_search_failed'));
      },
    });
  }

  onCustomerChange(customer: Customer | number | string | null): void {
    const selectedCustomer =
      customer && typeof customer === 'object'
        ? customer
        : (this.customerOptions.find((option) => Number(option.id) === Number(customer)) ?? null);
    const parsedCustomerId = Number(selectedCustomer?.id ?? customer);
    if (!Number.isFinite(parsedCustomerId) || parsedCustomerId <= 0) {
      this.clearCustomerSelection();
      return;
    }

    this.transportOrderForm.patchValue({
      customer: {
        customerId: parsedCustomerId,
        customerName: selectedCustomer?.name ?? '',
      },
      customerId: parsedCustomerId,
      billTo: null,
    });

    this.billToAddresses = [];

    this.loadBillToAddresses(parsedCustomerId);

    if (!selectedCustomer) {
      this.fetchCustomerAndBind(String(parsedCustomerId));
    }
  }

  compareCustomerById = (optionValue: unknown, selectedValue: unknown): boolean => {
    return Number(optionValue) === Number(selectedValue);
  };

  getCustomerDisplayName(customer: Partial<Customer> | number | string | null | undefined): string {
    if (customer && typeof customer === 'object' && typeof customer.name === 'string') {
      return customer.name;
    }

    const customerId = Number(customer);
    if (Number.isFinite(customerId) && customerId > 0) {
      const matchedCustomer =
        this.customerOptions.find((option) => Number(option.id) === customerId) ?? null;
      if (matchedCustomer?.name) {
        return matchedCustomer.name;
      }
    }

    return String(this.transportOrderForm?.get('customer.customerName')?.value ?? '').trim();
  }

  getCustomerDisplayMeta(customer: Partial<Customer> | number | string | null | undefined): string {
    const normalizedCustomer =
      customer && typeof customer === 'object'
        ? customer
        : this.customerOptions.find((option) => Number(option.id) === Number(customer));

    if (normalizedCustomer?.customerCode) {
      return normalizedCustomer.customerCode;
    }

    if (normalizedCustomer?.phone) {
      return `Phone: ${normalizedCustomer.phone}`;
    }

    return '';
  }

  clearCustomerSelection(): void {
    this.transportOrderForm.patchValue({
      customer: {
        customerId: '',
        customerName: '',
      },
      customerId: '',
      billTo: null,
    });
    this.billToAddresses = [];
  }

  get hasSelectedCustomer(): boolean {
    const customerId = Number(this.transportOrderForm?.get('customer.customerId')?.value);
    return Number.isFinite(customerId) && customerId > 0;
  }

  get selectedCustomerSummary(): { name: string; meta: string } | null {
    const customerId = Number(this.transportOrderForm?.get('customer.customerId')?.value);
    if (!Number.isFinite(customerId) || customerId <= 0) return null;

    const customer =
      this.customerOptions.find((option) => Number(option.id) === customerId) ?? null;
    const name =
      customer?.name ||
      String(this.transportOrderForm?.get('customer.customerName')?.value ?? '').trim();
    if (!name) return null;

    const meta = customer?.customerCode || (customer?.phone ? `Phone: ${customer.phone}` : '');
    return { name, meta };
  }

  ngOnDestroy(): void {
    this.destroy$.next();
    this.destroy$.complete();
  }

  onBillToAddressSearch(query: string): void {
    const customerId = Number(this.transportOrderForm.get('customer.customerId')?.value);
    if (!customerId) {
      this.billToAddresses = [];
      this.isBillToLoading = false;
      return;
    }

    this.loadBillToAddresses(customerId, query);
  }

  private loadBillToAddresses(customerId: number, query: string = ''): void {
    this.isBillToLoading = true;
    this.customerBillToAddressService.search(customerId, query).subscribe({
      next: (response: any) => {
        this.isBillToLoading = false;
        this.billToAddresses = this.normalizeObjectArray(
          response?.data?.content,
          response?.data?.addresses,
        );
        if (!this.billToAddresses.length) {
          this.toastService.info(this.translate.instant('orders.form.messages.bill_to_not_found'));
        }
      },
      error: (err: any) => {
        this.isBillToLoading = false;
        this.billToAddresses = [];
        this.toastService.error(this.translate.instant('orders.form.messages.bill_to_search_failed'));
        console.error('[BillTo] API error:', err);
      },
    });
  }

  onBillToAddressChange(addressId: number): void {
    // Optionally handle address selection (e.g., auto-fill fields)
  }

  openQuickCreateBillToAddressModal(): void {
    this.isCreateBillToAddressModalOpen = true;
  }

  onBillToAddressCreated(address: any): void {
    if (address && address.id) {
      if (!this.billToAddresses.some((a) => a.id === address.id)) {
        this.billToAddresses = [...this.billToAddresses, address];
      }
      this.transportOrderForm.get('billTo')?.setValue(address.id);
    }
    this.isCreateBillToAddressModalOpen = false;
  }

  selectBillToCustomer(customer: any): void {
    this.transportOrderForm.get('billTo')?.setValue(customer.name || customer.customerCode);
    this.isBillToModalOpen = false;
    // Removed obsolete billToSearchQuery, billToSearchResults, billToSearchError
  }

  openBillToModal(): void {
    this.isBillToModalOpen = true;
    // TODO: Implement modal logic to search/select bill-to customer
  }

  get safeShipmentTypes(): string[] {
    return Array.isArray(this.shipmentTypes) ? this.shipmentTypes : [];
  }

  get safeOrderStatuses(): string[] {
    return Array.isArray(this.orderStatuses) ? this.orderStatuses : this.defaultOrderStatuses;
  }

  get safeCouriers(): string[] {
    return Array.isArray(this.couriers) ? this.couriers : this.defaultCouriers;
  }

  get safeSellers(): any[] {
    return Array.isArray(this.sellers) ? this.sellers : [];
  }

  get dispatchAssignmentForm(): FormGroup {
    return this.transportOrderForm.get('dispatchAssignment') as FormGroup;
  }

  get shouldCreateDispatch(): boolean {
    return (
      this.mode === 'create' &&
      !!this.transportOrderForm.get('dispatchAssignment.createDispatchNow')?.value
    );
  }

  get selectedDispatchDriver(): Driver | null {
    const driverId = Number(this.dispatchAssignmentForm.get('driverId')?.value);
    if (!Number.isFinite(driverId) || driverId <= 0) return null;
    return this.drivers.find((driver) => Number(driver?.id) === driverId) ?? null;
  }

  get selectedDispatchVehicle(): Vehicle | null {
    const vehicleId = Number(this.dispatchAssignmentForm.get('vehicleId')?.value);
    if (!Number.isFinite(vehicleId) || vehicleId <= 0) return null;
    return this.vehicles.find((vehicle) => Number(vehicle?.id) === vehicleId) ?? null;
  }

  get dispatchDriverOptions(): Array<{ id: number; label: string; secondary: string }> {
    return this.drivers.map((driver) => ({
      id: Number(driver.id),
      label: this.formatDriverLabel(driver),
      secondary: this.formatDriverSecondary(driver),
    }));
  }

  get dispatchVehicleOptions(): Array<{ id: number; label: string; secondary: string }> {
    return this.vehicles.map((vehicle) => ({
      id: Number(vehicle.id),
      label: this.formatVehicleLabel(vehicle),
      secondary: this.formatVehicleSecondary(vehicle),
    }));
  }

  get filteredDispatchDriverOptions(): Array<{ id: number; label: string; secondary: string }> {
    return this.dispatchDriverOptions.filter((option) =>
      this.searchDispatchOption(this.driverSearchTerm, option),
    );
  }

  get filteredDispatchVehicleOptions(): Array<{ id: number; label: string; secondary: string }> {
    return this.dispatchVehicleOptions.filter((option) =>
      this.searchDispatchOption(this.vehicleSearchTerm, option),
    );
  }

  shouldShowDispatchFieldError(fieldName: 'driverId' | 'vehicleId'): boolean {
    if (!this.shouldCreateDispatch) return false;
    const control = this.dispatchAssignmentForm.get(fieldName);
    return !this.normalizeSelectedId(control?.value) && this.dispatchAssignmentValidationAttempted;
  }

  openDriverSelector(): void {
    this.driverSelectorOpen = true;
    this.driverSearchTerm = this.selectedDispatchDriverOption?.label ?? '';
  }

  openVehicleSelector(): void {
    this.vehicleSelectorOpen = true;
    this.vehicleSearchTerm = this.selectedDispatchVehicleOption?.label ?? '';
  }

  closeDriverSelector(): void {
    window.setTimeout(() => {
      this.driverSelectorOpen = false;
      this.driverSearchTerm = this.selectedDispatchDriverOption?.label ?? '';
    }, 120);
  }

  closeVehicleSelector(): void {
    window.setTimeout(() => {
      this.vehicleSelectorOpen = false;
      this.vehicleSearchTerm = this.selectedDispatchVehicleOption?.label ?? '';
    }, 120);
  }

  onDispatchDriverSearch(term: string): void {
    this.driverSelectorOpen = true;
    this.driverSearchTerm = term;
  }

  onDispatchVehicleSearch(term: string): void {
    this.vehicleSelectorOpen = true;
    this.vehicleSearchTerm = term;
  }

  selectDispatchDriverOption(optionId: number): void {
    this.dispatchAssignmentForm.patchValue({ driverId: optionId });
    this.driverSelectorOpen = false;
    this.vehicleSelectorOpen = false;
    this.driverSearchTerm = this.selectedDispatchDriverOption?.label ?? '';
  }

  selectDispatchVehicleOption(optionId: number): void {
    this.dispatchAssignmentForm.patchValue({ vehicleId: optionId });
    this.vehicleSelectorOpen = false;
    this.driverSelectorOpen = false;
    this.vehicleSearchTerm = this.selectedDispatchVehicleOption?.label ?? '';
  }

  clearDispatchDriverSelection(event?: Event): void {
    event?.preventDefault();
    event?.stopPropagation();
    this.dispatchAssignmentForm.patchValue({ driverId: null });
    this.driverSearchTerm = '';
    this.driverSelectorOpen = false;
  }

  clearDispatchVehicleSelection(event?: Event): void {
    event?.preventDefault();
    event?.stopPropagation();
    this.dispatchAssignmentForm.patchValue({ vehicleId: null });
    this.vehicleSearchTerm = '';
    this.vehicleSelectorOpen = false;
  }

  get selectedDispatchDriverOption(): { id: number; label: string; secondary: string } | null {
    const selectedId = this.normalizeSelectedId(this.dispatchAssignmentForm.get('driverId')?.value);
    if (!selectedId) return null;
    return this.dispatchDriverOptions.find((option) => option.id === selectedId) ?? null;
  }

  get selectedDispatchVehicleOption(): { id: number; label: string; secondary: string } | null {
    const selectedId = this.normalizeSelectedId(this.dispatchAssignmentForm.get('vehicleId')?.value);
    if (!selectedId) return null;
    return this.dispatchVehicleOptions.find((option) => option.id === selectedId) ?? null;
  }

  private normalizeStringArray(payload: unknown): string[] {
    if (Array.isArray(payload)) {
      return payload.filter((v): v is string => typeof v === 'string');
    }

    const p = payload as any;
    const candidates = [p?.data?.content, p?.data?.types, p?.data, p?.types, p?.content];
    for (const c of candidates) {
      if (Array.isArray(c)) {
        return c.filter((v): v is string => typeof v === 'string');
      }
    }

    console.warn('[TransportOrder] Expected array payload for shipment types, received:', payload);
    return [];
  }

  private normalizeObjectArray(...candidates: unknown[]): any[] {
    for (const candidate of candidates) {
      if (Array.isArray(candidate)) {
        return candidate;
      }
      const nested = (candidate as any)?.content;
      if (Array.isArray(nested)) {
        return nested;
      }
    }
    return [];
  }

  private loadDispatchResources(): void {
    this.loadDrivers();
    this.loadVehicles();
  }

  private loadDrivers(): void {
    this.loadingDrivers = true;
    this.driverService.getAllDriversModal({ isActive: true }).subscribe({
      next: (response: any) => {
        const rawDrivers = this.normalizeObjectArray(
          response?.data,
          response?.data?.content,
          response?.content,
        );
        this.drivers = rawDrivers.filter((driver: Driver) => Number(driver?.id) > 0);
        this.loadingDrivers = false;
        this.syncDispatchSelectionFromAssignments('driver');
      },
      error: () => {
        this.drivers = [];
        this.loadingDrivers = false;
        this.toastService.error(
          this.translate.instant('orders.form.messages.drivers_load_failed'),
        );
      },
    });
  }

  private loadVehicles(): void {
    this.loadingVehicles = true;
    this.vehicleService.getAllVehicles().subscribe({
      next: (response: any) => {
        const rawVehicles = this.normalizeObjectArray(
          response?.data,
          response?.data?.content,
          response?.content,
        );
        this.vehicles = rawVehicles.filter((vehicle: Vehicle) => {
          const status = String(vehicle?.status ?? '').toUpperCase();
          return Number(vehicle?.id) > 0 && status !== 'OUT_OF_SERVICE' && status !== 'MAINTENANCE';
        });
        this.loadingVehicles = false;
        this.syncDispatchSelectionFromAssignments('vehicle');
      },
      error: () => {
        this.vehicles = [];
        this.loadingVehicles = false;
        this.toastService.error(
          this.translate.instant('orders.form.messages.vehicles_load_failed'),
        );
      },
    });
  }

  onDispatchDriverChange(driverId: number | null): void {
    const selectedDriverId = this.normalizeSelectedId(driverId);
    if (!selectedDriverId) return;
    const preferredVehicleId = this.getAssignedVehicleIdForDriver(selectedDriverId);
    if (preferredVehicleId) {
      this.dispatchAssignmentForm.patchValue({ vehicleId: preferredVehicleId });
    }
  }

  onDispatchVehicleChange(vehicleId: number | null): void {
    const selectedVehicleId = this.normalizeSelectedId(vehicleId);
    if (!selectedVehicleId) return;
    const preferredDriverId = this.getAssignedDriverIdForVehicle(selectedVehicleId);
    if (preferredDriverId) {
      this.dispatchAssignmentForm.patchValue({ driverId: preferredDriverId });
    }
  }

  searchDispatchOption(
    term: string,
    item: { label?: string | null; secondary?: string | null },
  ): boolean {
    const normalizedTerm = String(term ?? '')
      .trim()
      .toLowerCase();
    if (!normalizedTerm) return true;
    const haystack = [item?.label, item?.secondary]
      .map((value) => String(value ?? '').toLowerCase())
      .join(' ');
    return haystack.includes(normalizedTerm);
  }

  private formatDriverLabel(driver: Driver): string {
    const fullName = String(driver?.fullName ?? driver?.name ?? '').trim();
    const licenseNumber = String(driver?.licenseNumber ?? '').trim();
    if (licenseNumber) {
      return `${fullName} (${licenseNumber})`;
    }
    return fullName || `Driver #${driver?.id}`;
  }

  private formatDriverSecondary(driver: Driver): string {
    return [
      String(driver?.phone ?? '').trim(),
      String(driver?.currentVehiclePlate ?? driver?.assignedVehicle?.licensePlate ?? '').trim(),
    ]
      .filter(Boolean)
      .join(' • ');
  }

  private formatVehicleLabel(vehicle: Vehicle): string {
    const plate = String(vehicle?.licensePlate ?? vehicle?.plateNumber ?? '').trim();
    const type = String(vehicle?.type ?? '').trim();
    return type ? `${plate} (${type})` : plate || `Vehicle #${vehicle?.id}`;
  }

  private formatVehicleSecondary(vehicle: Vehicle): string {
    return [
      String(vehicle?.status ?? '').replace(/_/g, ' ').trim(),
      String(vehicle?.model ?? '').trim(),
      String(vehicle?.assignedDriver?.fullName ?? '').trim(),
    ]
      .filter(Boolean)
      .join(' • ');
  }

  private syncDispatchSelectionFromAssignments(source: 'driver' | 'vehicle'): void {
    if (!this.shouldCreateDispatch) return;

    const selectedDriverId = this.normalizeSelectedId(
      this.dispatchAssignmentForm.get('driverId')?.value,
    );
    const selectedVehicleId = this.normalizeSelectedId(
      this.dispatchAssignmentForm.get('vehicleId')?.value,
    );

    if (source === 'driver' && selectedDriverId) {
      const preferredVehicleId = this.getAssignedVehicleIdForDriver(selectedDriverId);
      if (preferredVehicleId && !selectedVehicleId) {
        this.dispatchAssignmentForm.patchValue({ vehicleId: preferredVehicleId });
      }
      return;
    }

    if (source === 'vehicle' && selectedVehicleId) {
      const preferredDriverId = this.getAssignedDriverIdForVehicle(selectedVehicleId);
      if (preferredDriverId && !selectedDriverId) {
        this.dispatchAssignmentForm.patchValue({ driverId: preferredDriverId });
      }
    }
  }

  private normalizeSelectedId(value: unknown): number | null {
    const candidate =
      typeof value === 'object' && value !== null && 'id' in value
        ? (value as { id?: unknown }).id
        : value;
    const normalized = Number(candidate);
    return Number.isFinite(normalized) && normalized > 0 ? normalized : null;
  }

  private getAssignedVehicleIdForDriver(driverId: number | null): number | null {
    if (!driverId) return null;
    const driver = this.drivers.find((candidate) => Number(candidate?.id) === Number(driverId));
    const preferredVehicleId = Number(
      driver?.currentVehicleId ?? driver?.assignedVehicleId ?? driver?.assignedVehicle?.id,
    );
    if (
      Number.isFinite(preferredVehicleId) &&
      preferredVehicleId > 0 &&
      this.vehicles.some((vehicle) => Number(vehicle?.id) === preferredVehicleId)
    ) {
      return preferredVehicleId;
    }
    return null;
  }

  private getAssignedDriverIdForVehicle(vehicleId: number | null): number | null {
    if (!vehicleId) return null;

    const vehicle = this.vehicles.find((candidate) => Number(candidate?.id) === Number(vehicleId));
    const assignedDriverId = Number(vehicle?.assignedDriver?.id);
    if (
      Number.isFinite(assignedDriverId) &&
      assignedDriverId > 0 &&
      this.drivers.some((driver) => Number(driver?.id) === assignedDriverId)
    ) {
      return assignedDriverId;
    }

    const matchedDriver = this.drivers.find((driver) => {
      const preferredVehicleId = Number(
        driver?.currentVehicleId ?? driver?.assignedVehicleId ?? driver?.assignedVehicle?.id,
      );
      return Number.isFinite(preferredVehicleId) && preferredVehicleId === Number(vehicleId);
    });

    return matchedDriver ? Number(matchedDriver.id) : null;
  }

  private createAddressFormGroup(address: any = {}): FormGroup {
    return this.fb.group({
      id: [address?.id ?? null],
      name: [address?.name ?? '', Validators.required],
      address: [address?.address ?? '', Validators.required],
      postcode: [address?.postcode ?? ''],
      contactName: [address?.contactName ?? ''],
      contactPhone: [address?.contactPhone ?? ''],
      country: [address?.country ?? ''],
      scheduledTime: [address?.scheduledTime ?? ''],
    });
  }

  private createItemFormGroup(item: any = {}): FormGroup {
    return this.fb.group({
      id: [item?.id ?? null],
      itemId: [item?.itemId ?? null],
      itemCode: [item?.itemCode ?? ''],
      itemName: [item?.itemName ?? ''],
      quantity: [item?.quantity ?? 1, Validators.required],
      unitOfMeasurement: [item?.unitOfMeasurement ?? item?.unit ?? ''],
      palletType: [item?.palletType ?? ''],
      size: [item?.size ?? item?.dimensions ?? ''],
      weight: [item?.weight ?? 0],
      fromDestination: [item?.fromDestination ?? ''],
      toDestination: [item?.toDestination ?? ''],
      warehouse: [item?.warehouse ?? ''],
      department: [item?.department ?? ''],
    });
  }

  private patchOrderForm(order: any): void {
    const customerId = order?.customerId ?? order?.customer?.id ?? '';
    const customerName = order?.customerName ?? order?.customer?.name ?? '';
    const pickupList = this.normalizeObjectArray(order?.pickupAddresses);
    const dropList = this.normalizeObjectArray(order?.dropAddresses);
    const itemList = this.normalizeObjectArray(order?.items);
    const resolvedBillTo = this.resolveBillToForControl(order);

    if (customerId) {
      this.upsertCustomerOption({
        ...(order?.customer ?? {}),
        id: customerId,
        name: customerName,
      });
    }

    this.transportOrderForm.patchValue({
      customer: {
        customerId,
        customerName,
      },
      customerId,
      orderReference: order?.orderReference ?? '',
      billTo: resolvedBillTo,
      orderDate: this.toInputDate(order?.orderDate),
      deliveryDate: this.toInputDate(order?.deliveryDate),
      shipmentType: order?.shipmentType ?? 'FTL',
      courierAssigned: order?.courierAssigned ?? '',
      status: `${order?.status ?? 'PENDING'}`,
      sellerId: order?.sellerId ?? order?.seller?.id ?? null,
    });
    this.ensureCourierOption(order?.courierAssigned);
    this.loadBillToOptionsForEdit(customerId, order);

    this.pickupLocations.clear();
    this.dropLocations.clear();
    this.items.clear();

    const pickupSource = pickupList.length ? pickupList : [order?.pickupAddress].filter(Boolean);
    const dropSource = dropList.length ? dropList : [order?.dropAddress].filter(Boolean);

    pickupSource.forEach((address: any) =>
      this.pickupLocations.push(this.createAddressFormGroup(address)),
    );
    dropSource.forEach((address: any) =>
      this.dropLocations.push(this.createAddressFormGroup(address)),
    );
    itemList.forEach((item: any) => this.items.push(this.createItemFormGroup(item)));

    if (this.pickupLocations.length === 0) this.addPickupLocation();
    if (this.dropLocations.length === 0) this.addDropLocation();
  }

  private loadBillToOptionsForEdit(customerId: unknown, order: any): void {
    const parsedCustomerId = Number(customerId);
    if (!Number.isFinite(parsedCustomerId) || parsedCustomerId <= 0) {
      return;
    }

    this.isBillToLoading = true;
    this.customerBillToAddressService.list(parsedCustomerId).subscribe({
      next: (response: any) => {
        this.isBillToLoading = false;
        const addresses = this.normalizeObjectArray(
          response?.data,
          response?.data?.content,
          response?.data?.addresses,
        );
        this.billToAddresses = addresses;
        const resolved = this.resolveBillToFromOptions(order, addresses);
        if (resolved !== null && resolved !== undefined) {
          this.transportOrderForm.get('billTo')?.setValue(resolved);
        } else if (!this.transportOrderForm.get('billTo')?.value) {
          const rawBillTo = String(order?.billTo ?? '').trim();
          if (rawBillTo) {
            const legacyOption = {
              id: rawBillTo,
              name: rawBillTo,
              address: '(legacy value)',
            };
            this.billToAddresses = [...addresses, legacyOption];
            this.transportOrderForm.get('billTo')?.setValue(rawBillTo);
          } else {
            this.transportOrderForm.get('billTo')?.setValue(null);
          }
        }
      },
      error: () => {
        this.isBillToLoading = false;
      },
    });
  }

  private resolveBillToForControl(order: any): number | string | null {
    const explicitIdCandidates = [
      order?.billToAddressId,
      order?.billToId,
      order?.billTo?.id,
      order?.billTo?.billToId,
    ];
    for (const candidate of explicitIdCandidates) {
      const parsed = Number(candidate);
      if (Number.isFinite(parsed) && parsed > 0) {
        return parsed;
      }
    }

    const rawBillTo = order?.billTo;
    if (typeof rawBillTo === 'number' && Number.isFinite(rawBillTo) && rawBillTo > 0) {
      return rawBillTo;
    }
    if (typeof rawBillTo === 'string') {
      const trimmed = rawBillTo.trim();
      if (!trimmed) return null;
      const parsed = Number(trimmed);
      if (Number.isFinite(parsed) && parsed > 0) {
        return parsed;
      }
      return trimmed;
    }

    return null;
  }

  private resolveBillToFromOptions(order: any, options: any[]): number | null {
    if (!Array.isArray(options) || options.length === 0) {
      return null;
    }

    const directControlValue = this.resolveBillToForControl(order);
    if (typeof directControlValue === 'number') {
      const matchById = options.find((option) => Number(option?.id) === directControlValue);
      if (matchById) return Number(matchById.id);
    }

    const rawBillTo = String(order?.billTo ?? '')
      .trim()
      .toLowerCase();
    if (!rawBillTo) return null;

    const match = options.find((option) => {
      const name = String(option?.name ?? '')
        .trim()
        .toLowerCase();
      const address = String(option?.address ?? '')
        .trim()
        .toLowerCase();
      return name === rawBillTo || address === rawBillTo;
    });

    return match?.id ? Number(match.id) : null;
  }

  private ensureCourierOption(courier: unknown): void {
    const value = String(courier ?? '').trim();
    if (!value) return;
    if (!this.couriers.includes(value)) {
      this.couriers = [...this.couriers, value];
    }
  }

  private buildCreateOrderPayload(): any {
    const formValue = this.transportOrderForm.getRawValue();
    const customerId = Number(formValue?.customer?.customerId || formValue?.customerId);
    const pickupAddresses = this.normalizeObjectArray(formValue?.pickupLocations).map(
      (address: any) => ({
        id: address?.id ?? null,
        name: address?.name ?? '',
        address: address?.address ?? '',
        postcode: address?.postcode ?? '',
        contactName: address?.contactName ?? '',
        contactPhone: address?.contactPhone ?? '',
        country: address?.country ?? '',
        scheduledTime: address?.scheduledTime ?? '',
      }),
    );
    const dropAddresses = this.normalizeObjectArray(formValue?.dropLocations).map(
      (address: any) => ({
        id: address?.id ?? null,
        name: address?.name ?? '',
        address: address?.address ?? '',
        postcode: address?.postcode ?? '',
        contactName: address?.contactName ?? '',
        contactPhone: address?.contactPhone ?? '',
        country: address?.country ?? '',
        scheduledTime: address?.scheduledTime ?? '',
      }),
    );
    const items = this.normalizeObjectArray(formValue?.items).map((item: any) => ({
      id: item?.id ?? null,
      itemId: item?.itemId ?? null,
      itemCode: item?.itemCode ?? '',
      itemName: item?.itemName ?? '',
      quantity: Number(item?.quantity ?? 0),
      unitOfMeasurement: item?.unitOfMeasurement ?? '',
      palletType: Number(item?.palletType ?? 0),
      dimensions: item?.size ?? '',
      weight: Number(item?.weight ?? 0),
      fromDestination: item?.fromDestination ?? '',
      toDestination: item?.toDestination ?? '',
      warehouse: item?.warehouse ?? '',
      department: item?.department ?? '',
    }));
    const stops = this.buildStopsPayload(pickupAddresses, dropAddresses);

    return {
      id: this.orderId,
      orderReference: formValue?.orderReference,
      customerId: Number.isFinite(customerId) ? customerId : null,
      customerName: formValue?.customer?.customerName ?? '',
      billTo: formValue?.billTo ?? '',
      orderDate: formValue?.orderDate,
      deliveryDate: formValue?.deliveryDate,
      shipmentType: formValue?.shipmentType,
      courierAssigned: formValue?.courierAssigned ?? '',
      status: formValue?.status,
      sellerId: formValue?.sellerId ? Number(formValue.sellerId) : null,
      pickupAddress: pickupAddresses[0] ?? null,
      dropAddress: dropAddresses[0] ?? null,
      pickupAddresses,
      dropAddresses,
      stops,
      items,
    };
  }

  private buildUpdateOrderPayload(): any {
    const formValue = this.transportOrderForm.getRawValue();
    const customerId = Number(formValue?.customer?.customerId || formValue?.customerId);
    const pickupAddresses = this.normalizeObjectArray(formValue?.pickupLocations).map(
      (address: any) => ({
        id: address?.id ?? null,
        name: address?.name ?? '',
        address: address?.address ?? '',
        postcode: address?.postcode ?? '',
        contactName: address?.contactName ?? '',
        contactPhone: address?.contactPhone ?? '',
        country: address?.country ?? '',
        scheduledTime: address?.scheduledTime ?? '',
      }),
    );
    const dropAddresses = this.normalizeObjectArray(formValue?.dropLocations).map(
      (address: any) => ({
        id: address?.id ?? null,
        name: address?.name ?? '',
        address: address?.address ?? '',
        postcode: address?.postcode ?? '',
        contactName: address?.contactName ?? '',
        contactPhone: address?.contactPhone ?? '',
        country: address?.country ?? '',
        scheduledTime: address?.scheduledTime ?? '',
      }),
    );
    const items = this.normalizeObjectArray(formValue?.items).map((item: any) => ({
      id: item?.id ?? null,
      itemId: item?.itemId ?? null,
      itemCode: item?.itemCode ?? '',
      itemName: item?.itemName ?? '',
      quantity: Number(item?.quantity ?? 0),
      unitOfMeasurement: item?.unitOfMeasurement ?? '',
      palletType: Number(item?.palletType ?? 0),
      dimensions: item?.size ?? '',
      weight: Number(item?.weight ?? 0),
      fromDestination: item?.fromDestination ?? '',
      toDestination: item?.toDestination ?? '',
      warehouse: item?.warehouse ?? '',
      department: item?.department ?? '',
    }));
    const stops = this.buildStopsPayload(pickupAddresses, dropAddresses);

    return {
      id: this.orderId,
      orderReference: formValue?.orderReference ?? '',
      customerId: Number.isFinite(customerId) ? customerId : null,
      billTo: formValue?.billTo ?? '',
      orderDate: formValue?.orderDate ?? null,
      deliveryDate: formValue?.deliveryDate ?? null,
      shipmentType: formValue?.shipmentType ?? '',
      courierAssigned: formValue?.courierAssigned ?? '',
      status: formValue?.status ?? null,
      sellerId: formValue?.sellerId ? Number(formValue.sellerId) : null,
      pickupAddress: pickupAddresses[0] ?? null,
      dropAddress: dropAddresses[0] ?? null,
      pickupAddresses,
      dropAddresses,
      pickupLocations: pickupAddresses,
      dropLocations: dropAddresses,
      stops,
      items,
    };
  }

  private buildStopsPayload(pickups: any[], drops: any[]): any[] {
    const pickupStops = this.normalizeObjectArray(pickups)
      .filter((address: any) => Number.isFinite(Number(address?.id)) && Number(address?.id) > 0)
      .map((address: any, index: number) => ({
        type: 'PICKUP',
        sequence: index + 1,
        addressId: Number(address.id),
        contactName: address?.contactName ?? '',
        contactPhone: address?.contactPhone ?? '',
      }));

    const dropStops = this.normalizeObjectArray(drops)
      .filter((address: any) => Number.isFinite(Number(address?.id)) && Number(address?.id) > 0)
      .map((address: any, index: number) => ({
        type: 'DROP',
        sequence: pickupStops.length + index + 1,
        addressId: Number(address.id),
        contactName: address?.contactName ?? '',
        contactPhone: address?.contactPhone ?? '',
      }));

    return [...pickupStops, ...dropStops];
  }

  private toInputDate(value: unknown): string {
    if (!value) return '';

    if (value instanceof Date && !Number.isNaN(value.getTime())) {
      return value.toISOString().slice(0, 10);
    }

    const dateValue = String(value).trim();
    if (!dateValue) return '';

    if (/^\d{4}-\d{2}-\d{2}$/.test(dateValue)) {
      return dateValue;
    }

    if (dateValue.includes('T')) {
      const isoDate = dateValue.split('T')[0];
      if (/^\d{4}-\d{2}-\d{2}$/.test(isoDate)) {
        return isoDate;
      }
    }

    const slashOrDash = dateValue.match(/^(\d{1,2})[\/-](\d{1,2})[\/-](\d{4})$/);
    if (slashOrDash) {
      const first = Number(slashOrDash[1]);
      const second = Number(slashOrDash[2]);
      const year = Number(slashOrDash[3]);
      const day = first > 12 ? first : second;
      const month = first > 12 ? second : first;
      const monthStr = `${month}`.padStart(2, '0');
      const dayStr = `${day}`.padStart(2, '0');
      return `${year}-${monthStr}-${dayStr}`;
    }

    const parsedDate = new Date(dateValue);
    if (!Number.isNaN(parsedDate.getTime())) {
      return parsedDate.toISOString().slice(0, 10);
    }

    return '';
  }

  private syncHeaderAddressesFromLocations(): void {
    const firstPickup = this.pickupLocations.length > 0 ? this.pickupLocations.at(0).value : null;
    const firstDrop = this.dropLocations.length > 0 ? this.dropLocations.at(0).value : null;

    this.transportOrderForm.patchValue(
      {
        pickupAddress: {
          id: firstPickup?.id ?? null,
          name: firstPickup?.name ?? '',
          address: firstPickup?.address ?? '',
          postcode: firstPickup?.postcode ?? '',
          contactName: firstPickup?.contactName ?? '',
          contactPhone: firstPickup?.contactPhone ?? '',
          country: firstPickup?.country ?? '',
          scheduledTime: firstPickup?.scheduledTime ?? '',
        },
        dropAddress: {
          id: firstDrop?.id ?? null,
          name: firstDrop?.name ?? '',
          address: firstDrop?.address ?? '',
          postcode: firstDrop?.postcode ?? '',
          contactName: firstDrop?.contactName ?? '',
          contactPhone: firstDrop?.contactPhone ?? '',
          country: firstDrop?.country ?? '',
          scheduledTime: firstDrop?.scheduledTime ?? '',
        },
      },
      { emitEvent: false },
    );
  }

  private hasValidDispatchAssignment(): boolean {
    const driverId = Number(this.dispatchAssignmentForm.get('driverId')?.value);
    const vehicleId = Number(this.dispatchAssignmentForm.get('vehicleId')?.value);
    return Number.isFinite(driverId) && driverId > 0 && Number.isFinite(vehicleId) && vehicleId > 0;
  }

  private resolveOrderId(response: any): number | null {
    for (const candidate of [response?.data?.id, response?.id]) {
      const parsed = Number(candidate);
      if (Number.isFinite(parsed) && parsed > 0) {
        return parsed;
      }
    }
    return null;
  }

  private createDispatchAfterOrder(orderId: number, orderReference: string): void {
    const dispatchPayload = this.buildCreateDispatchPayload(orderId, orderReference);
    this.dispatchService.createDispatch(dispatchPayload).subscribe({
      next: (dispatchResponse: any) => {
        this.isSubmitting = false;
        this.toastService.success(
          this.translate.instant('orders.form.messages.created_dispatch_success'),
        );
        void this.router.navigate(['/dispatch']);
      },
      error: (error: any) => {
        this.isSubmitting = false;
        this.toastService.success(
          this.translate.instant('orders.form.messages.created_success'),
        );
        this.toastService.error(this.buildDispatchCreationErrorMessage(error));
        void this.router.navigate(['/orders', orderId, 'edit']);
      },
    });
  }

  private buildCreateDispatchPayload(orderId: number, orderReference: string): Dispatch {
    const dispatchAssignment = this.dispatchAssignmentForm.getRawValue();
    const startTime = this.resolveDispatchStartTime();
    return {
      showMenu: false,
      transportOrder: null,
      transportOrderId: orderId,
      orderReference,
      driverId: Number(dispatchAssignment?.driverId),
      driverName: this.selectedDispatchDriver?.fullName ?? this.selectedDispatchDriver?.name ?? '',
      driverPhone: this.selectedDispatchDriver?.phone ?? '',
      vehicleId: Number(dispatchAssignment?.vehicleId),
      licensePlate:
        this.selectedDispatchVehicle?.licensePlate ?? this.selectedDispatchVehicle?.plateNumber ?? '',
      status: 'PENDING' as any,
      startTime,
      estimatedArrival: this.resolveDispatchEstimatedArrival(startTime),
      tripType: 'STANDARD',
      loadingTypeCode: 'GENERAL',
      routeCode: dispatchAssignment?.manualRouteCode?.trim() || undefined,
      createdBy: 0,
      createdByUsername: '',
      createdDate: new Date().toISOString(),
      cancelReason: dispatchAssignment?.notes?.trim() || undefined,
    };
  }

  private resolveDispatchStartTime(): string {
    const firstPickupTime = String(this.getPickupFormGroup(0)?.get('scheduledTime')?.value ?? '').trim();
    const baseDate =
      String(this.transportOrderForm.get('orderDate')?.value ?? '').trim() ||
      String(this.transportOrderForm.get('deliveryDate')?.value ?? '').trim() ||
      new Date().toISOString().slice(0, 10);
    return `${baseDate}T${firstPickupTime || '08:00'}:00`;
  }

  private resolveDispatchEstimatedArrival(startTime: string): string {
    const firstDropTime = String(this.getDropFormGroup(0)?.get('scheduledTime')?.value ?? '').trim();
    const deliveryDate =
      String(this.transportOrderForm.get('deliveryDate')?.value ?? '').trim() ||
      String(this.transportOrderForm.get('orderDate')?.value ?? '').trim();

    if (deliveryDate && firstDropTime) {
      return `${deliveryDate}T${firstDropTime}:00`;
    }

    const fallbackDate = new Date();
    if (!Number.isNaN(fallbackDate.getTime())) {
      fallbackDate.setHours(fallbackDate.getHours() + 2);
      return this.formatLocalDateTime(fallbackDate);
    }

    return startTime;
  }

  private formatLocalDateTime(value: Date): string {
    const year = value.getFullYear();
    const month = `${value.getMonth() + 1}`.padStart(2, '0');
    const day = `${value.getDate()}`.padStart(2, '0');
    const hours = `${value.getHours()}`.padStart(2, '0');
    const minutes = `${value.getMinutes()}`.padStart(2, '0');
    const seconds = `${value.getSeconds()}`.padStart(2, '0');
    return `${year}-${month}-${day}T${hours}:${minutes}:${seconds}`;
  }

  private buildDispatchCreationErrorMessage(error: any): string {
    const fieldErrors = error?.error?.errors;
    const fieldMessage =
      fieldErrors && typeof fieldErrors === 'object'
        ? Object.values(fieldErrors).find((value) => typeof value === 'string' && value.trim())
        : '';
    const message =
      fieldMessage || error?.error?.message || error?.message || 'Dispatch could not be created.';
    return `Dispatch could not be created. ${message} The order is already saved and ready to edit.`;
  }

  private upsertCustomerOption(customer: Partial<Customer> | null | undefined): void {
    const customerId = Number(customer?.id);
    if (!Number.isFinite(customerId) || customerId <= 0) return;

    const normalizedCustomer = {
      addresses: [],
      type: 'COMPANY',
      phone: '',
      status: 'ACTIVE',
      ...customer,
      id: customerId,
      name: customer?.name ?? '',
    } as Customer;

    const existingIndex = this.customerOptions.findIndex((item) => Number(item.id) === customerId);
    if (existingIndex === -1) {
      this.customerOptions = [normalizedCustomer, ...this.customerOptions];
      return;
    }

    const updated = [...this.customerOptions];
    updated[existingIndex] = {
      ...updated[existingIndex],
      ...normalizedCustomer,
    };
    this.customerOptions = updated;
  }

  private mergeCustomerOptions(customers: Customer[]): Customer[] {
    const merged = Array.isArray(customers) ? [...customers] : [];
    const selectedCustomerId = Number(this.transportOrderForm?.get('customer.customerId')?.value);
    const selectedCustomerName = String(
      this.transportOrderForm?.get('customer.customerName')?.value ?? '',
    ).trim();

    if (Number.isFinite(selectedCustomerId) && selectedCustomerId > 0) {
      const existingSelected =
        this.customerOptions.find((customer) => Number(customer.id) === selectedCustomerId) ?? null;

      if (!merged.some((customer) => Number(customer.id) === selectedCustomerId)) {
        merged.unshift({
          addresses: [],
          type: 'COMPANY',
          phone: '',
          status: 'ACTIVE',
          ...(existingSelected ?? {}),
          id: selectedCustomerId,
          name: selectedCustomerName || existingSelected?.name || '',
        } as Customer);
      }
    }

    return merged;
  }

  // All other methods and logic remain unchanged
}
