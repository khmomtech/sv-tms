/* eslint-disable @typescript-eslint/consistent-type-imports */
import { CommonModule } from '@angular/common';
import { Component, OnInit, OnDestroy, ChangeDetectorRef } from '@angular/core';
import {
  FormBuilder,
  Validators,
  FormsModule,
  ReactiveFormsModule,
  FormGroup,
  FormArray,
} from '@angular/forms';
import { MatExpansionModule } from '@angular/material/expansion';
import { ActivatedRoute, Router } from '@angular/router';
import { NgSelectModule } from '@ng-select/ng-select';

import { Subject } from 'rxjs';
import { takeUntil } from 'rxjs/operators';

import type { OrderStatus } from '../../models/order-status.enum';
import type { TransportOrderResponseDto } from '../../models/transport-order-response.model';

import { CustomerBillToAddressService } from '../../services/customer-bill-to-address.service';
import { CustomerService } from '../../services/custommer.service';
import { TransportOrderService } from '../../services/transport-order.service';
import { ToastService } from '../../shared/services/toast.service';
import { AppAddressModalComponent } from '../app-address-modal/app-address-modal.component';
import { AppCustomerModalComponent } from '../app-customer-modal/app-customer-modal.component';
import { AppItemModalComponent } from '../app-item-modal/app-item-modal.component';
import { CreateAddressModalComponent } from '../create-address-modal/create-address-modal.component';
import { CustomerModalComponent } from '../customer-modal/customer-modal.component';
import { ItemModalComponent } from '../item-modal/item-modal.component';

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
    private readonly cdr: ChangeDetectorRef,
    private readonly route: ActivatedRoute,
    public readonly router: Router,
    private readonly toastService: ToastService,
  ) {}

  loadOrder(orderId: number): void {
    this.orderService.getOrderById(orderId).subscribe({
      next: (response: any) => {
        const order = response?.data;
        if (!order) {
          this.toastService.error('Order not found.');
          return;
        }
        this.selectedOrder = order;
        this.patchOrderForm(order);
      },
      error: (err: any) => {
        this.toastService.error(err?.message || 'Failed to load order.');
      },
    });
  }
  // --- Template-required properties and methods ---
  fetchShipmentTypes(): void {
    this.orderService.getShipmentTypes().subscribe({
      next: (payload: unknown) => {
        this.shipmentTypes = this.normalizeStringArray(payload);
      },
      error: (err) => {
        if (err && err.message && err.message.toLowerCase().includes('jwt')) {
          this.toastService.error('Authentication error: Please log in again.');
          // Optionally, force logout or redirect
          // this.authService.logout();
        } else {
          this.toastService.error('Failed to load shipment types');
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
  clearForm(): void {
    this.transportOrderForm.reset();
    this.initializeForm();
  }

  submitForm(): void {
    this.syncHeaderAddressesFromLocations();

    if (this.transportOrderForm.invalid) {
      this.transportOrderForm.markAllAsTouched();
      this.toastService.error('Please fill all required fields.');
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
        'Please select at least one loading and one unloading address using the search button.',
      );
      return;
    }

    if (this.isSubmitting) return;
    this.isSubmitting = true;

    const payload =
      this.mode === 'edit' && this.orderId
        ? this.buildUpdateOrderPayload()
        : this.buildCreateOrderPayload();
    const request$ =
      this.mode === 'edit' && this.orderId
        ? this.orderService.updateOrder(this.orderId, payload)
        : this.orderService.createOrder(payload);

    request$.subscribe({
      next: () => {
        this.isSubmitting = false;
        this.toastService.success(
          this.mode === 'edit' ? 'Order updated successfully.' : 'Order created successfully.',
        );
        void this.router.navigate(['/orders']);
      },
      error: (err: any) => {
        this.isSubmitting = false;
        this.toastService.error(err?.message || 'Failed to save order.');
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

  sellers: any[] = [];
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
    });
    this.transportOrderForm.patchValue({
      orderReference: 'ORD-' + Math.floor(Math.random() * 10000),
    });
    this.addPickupLocation();
    this.addDropLocation();
    // Optionally sync validators
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
          this.transportOrderForm.patchValue({
            customer: {
              customerId: customerKey,
              customerName,
            },
            customerId: customerKey,
          });
        }
      },
      error: (err: any) => {
        this.toastService.error('Failed to fetch customer info.');
      },
    });
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

    this.isBillToLoading = true;
    this.customerBillToAddressService.search(customerId, query).subscribe({
      next: (response: any) => {
        this.isBillToLoading = false;
        this.billToAddresses = this.normalizeObjectArray(
          response?.data?.content,
          response?.data?.addresses,
        );
        if (!this.billToAddresses.length) {
          this.toastService.info('No Bill To addresses found for this search.');
        }
      },
      error: (err: any) => {
        this.isBillToLoading = false;
        this.billToAddresses = [];
        this.toastService.error('Failed to search Bill To addresses.');
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
    }
    return [];
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
    const pickupList = this.normalizeObjectArray(order?.pickupAddresses);
    const dropList = this.normalizeObjectArray(order?.dropAddresses);
    const itemList = this.normalizeObjectArray(order?.items);
    const resolvedBillTo = this.resolveBillToForControl(order);

    this.transportOrderForm.patchValue({
      customer: {
        customerId,
        customerName: order?.customerName ?? '',
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
    const pickupLocations = this.normalizeObjectArray(formValue?.pickupLocations).map(
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
    const dropLocations = this.normalizeObjectArray(formValue?.dropLocations).map(
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
    const stops = this.buildStopsPayload(pickupLocations, dropLocations);

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
      pickupAddress: pickupLocations[0] ?? null,
      dropAddress: dropLocations[0] ?? null,
      pickupLocations,
      dropLocations,
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

  // All other methods and logic remain unchanged
}
