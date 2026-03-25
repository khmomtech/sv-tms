import { CommonModule } from '@angular/common';
import type { OnInit } from '@angular/core';
import { Component, inject } from '@angular/core';
import { FormBuilder, FormControl, ReactiveFormsModule, Validators } from '@angular/forms';
import type { FormArray, FormGroup } from '@angular/forms';
import { ActivatedRoute, Router } from '@angular/router';
import { NgSelectModule } from '@ng-select/ng-select';
import { concat, Observable, of, Subject } from 'rxjs';
import {
  catchError,
  debounceTime,
  distinctUntilChanged,
  map,
  switchMap,
  tap,
} from 'rxjs/operators';

import { BookingPaymentType, BookingServiceType } from '@models/booking-status.enum';
import type { Booking, BookingPackage, CreateBookingDto } from '@models/booking.model';
import type { Customer } from '@models/customer.model';
import { BookingService } from '@services/booking.service';
import { CustomerService } from '@services/custommer.service';
import { AddressService, type OrderAddress } from '@services/address.service';
import { ConfirmService } from '@services/confirm.service';
import { NotificationService } from '@services/notification.service';

@Component({
  selector: 'app-booking-form',
  standalone: true,
  imports: [CommonModule, ReactiveFormsModule, NgSelectModule],
  templateUrl: './booking-form.component.html',
  styleUrls: ['./booking-form.component.css'],
})
export class BookingFormComponent implements OnInit {
  bookingForm!: FormGroup;
  isEditMode = false;
  bookingId: number | null = null;
  loading = false;
  submitting = false;
  error: string | null = null;

  // Customer autocomplete
  customerSearchControl = new FormControl<Customer | null>(null);
  customers$!: Observable<Customer[]>;
  customerSearchInput$ = new Subject<string>();
  selectedCustomer: Customer | null = null;
  loadingCustomers = false;

  // Location autocomplete (Pickup/Delivery)
  pickupLocationControl = new FormControl<OrderAddress | null>(null);
  deliveryLocationControl = new FormControl<OrderAddress | null>(null);
  pickupLocations$!: Observable<OrderAddress[]>;
  deliveryLocations$!: Observable<OrderAddress[]>;
  pickupLocationSearchInput$ = new Subject<string>();
  deliveryLocationSearchInput$ = new Subject<string>();
  loadingPickupLocations = false;
  loadingDeliveryLocations = false;

  // Enums for template
  ServiceTypes = Object.values(BookingServiceType);
  PaymentTypes = Object.values(BookingPaymentType);

  // Services
  private readonly fb = inject(FormBuilder);
  private readonly route = inject(ActivatedRoute);
  private readonly router = inject(Router);
  private readonly bookingService = inject(BookingService);
  readonly customerService = inject(CustomerService);
  private readonly addressService = inject(AddressService);
  private readonly confirm = inject(ConfirmService);
  private readonly notify = inject(NotificationService);

  ngOnInit(): void {
    this.initForm();
    this.setupCustomerSearch();
    this.setupLocationSearch();

    const id = this.route.snapshot.paramMap.get('id');
    if (id && id !== 'create') {
      this.isEditMode = true;
      this.bookingId = +id;
      this.loadBooking(this.bookingId);
    }
  }

  setupCustomerSearch(): void {
    // Initial load of customers
    const initialCustomers$ = this.customerService.getAllCustomers(0, 100).pipe(
      map((response) => response.content || []),
      catchError(() => of([])),
    );

    // Search customers based on user input
    const searchCustomers$ = this.customerSearchInput$.pipe(
      debounceTime(300),
      distinctUntilChanged(),
      tap(() => (this.loadingCustomers = true)),
      switchMap((term) => {
        if (!term || term.length < 2) {
          return this.customerService.getAllCustomers(0, 100).pipe(
            map((response) => response.content || []),
            catchError(() => of([])),
          );
        }
        return this.customerService.searchCustomers(term).pipe(catchError(() => of([])));
      }),
      tap(() => (this.loadingCustomers = false)),
    );

    // Combine initial load and search results
    this.customers$ = concat(initialCustomers$, searchCustomers$);
  }

  /** Setup typeahead for pickup and delivery locations with optional filtering by selected customer */
  setupLocationSearch(): void {
    const makeSearchStream = (
      term$: Subject<string>,
      setLoading: (v: boolean) => void,
    ): Observable<OrderAddress[]> => {
      return term$.pipe(
        debounceTime(300),
        distinctUntilChanged(),
        tap(() => setLoading(true)),
        switchMap((term) => {
          const q = term?.trim();
          if (!q || q.length < 2) {
            // fallback: no default flood of results; return empty list
            return of([]);
          }
          return this.addressService.searchLocations(q).pipe(
            map((list) => {
              // If a customer is selected, strictly return entries tied to that customer
              if (this.selectedCustomer?.id) {
                return list.filter((a) => a.customerId === this.selectedCustomer!.id);
              }
              // No customer selected: do not surface generic locations in booking context
              return [];
            }),
            catchError(() => of([])),
          );
        }),
        tap(() => setLoading(false)),
      );
    };

    this.pickupLocations$ = makeSearchStream(
      this.pickupLocationSearchInput$,
      (v) => (this.loadingPickupLocations = v),
    );
    this.deliveryLocations$ = makeSearchStream(
      this.deliveryLocationSearchInput$,
      (v) => (this.loadingDeliveryLocations = v),
    );
  }

  onCustomerSelected(customer: Customer | null): void {
    if (!customer) {
      // Clear customer fields if selection is cleared
      this.selectedCustomer = null;
      this.bookingForm.patchValue({
        customerId: null,
        customerName: '',
        customerPhone: '',
      });
      // Clear any selected locations when customer cleared
      this.pickupLocationControl.setValue(null);
      this.deliveryLocationControl.setValue(null);
      return;
    }

    this.selectedCustomer = customer;
    this.bookingForm.patchValue({
      customerId: customer.id,
      customerName: (customer as any).name ?? (customer as any).customerName ?? '',
      customerPhone: customer.phone || '',
    });
  }

  onPickupLocationSelected(addr: OrderAddress | null): void {
    if (!addr) {
      this.bookingForm.get('pickupAddress')?.patchValue({
        addressLine: '',
        city: '',
        province: '',
        postalCode: '',
        companyName: '',
        contactName: '',
        contactPhone: '',
      });
      return;
    }
    this.bookingForm.get('pickupAddress')?.patchValue({
      addressLine: addr.address ?? '',
      city: addr.city ?? '',
      companyName: addr.name ?? '',
    });
  }

  onDeliveryLocationSelected(addr: OrderAddress | null): void {
    if (!addr) {
      this.bookingForm.get('deliveryAddress')?.patchValue({
        addressLine: '',
        city: '',
        province: '',
        postalCode: '',
        companyName: '',
        contactName: '',
        contactPhone: '',
      });
      return;
    }
    this.bookingForm.get('deliveryAddress')?.patchValue({
      addressLine: addr.address ?? '',
      city: addr.city ?? '',
      companyName: addr.name ?? '',
    });
  }

  initForm(): void {
    this.bookingForm = this.fb.group({
      customerId: [null, Validators.required],
      customerName: ['', Validators.required],
      customerPhone: [''],

      // Pickup Address
      pickupAddress: this.fb.group({
        addressLine: ['', Validators.required],
        city: [''],
        province: [''],
        postalCode: [''],
        contactName: [''],
        contactPhone: [''],
        companyName: [''],
      }),

      // Delivery Address
      deliveryAddress: this.fb.group({
        addressLine: ['', Validators.required],
        city: [''],
        province: [''],
        postalCode: [''],
        contactName: [''],
        contactPhone: [''],
        companyName: [''],
      }),

      // Service Details
      serviceType: [BookingServiceType.FTL, Validators.required],
      truckType: [''],
      capacity: [null],

      // Schedule
      pickupDate: ['', Validators.required],
      deliveryDate: [''],

      // Payment
      paymentType: [BookingPaymentType.COD, Validators.required],
      estimatedCost: [null],

      // Additional
      totalWeightTons: [null],
      totalVolumeCbm: [null],
      palletCount: [null],
      specialHandlingNotes: [''],
      requiresInsurance: [false],
      notes: [''],

      // Packages
      packages: this.fb.array([]),
    });
  }

  get packages(): FormArray {
    return this.bookingForm.get('packages') as FormArray;
  }

  addPackage(): void {
    const packageGroup = this.fb.group({
      itemType: ['', Validators.required],
      quantity: [1, [Validators.required, Validators.min(1)]],
      weightKg: [null],
      volumeCbm: [null],
      cod: [null],
      description: [''],
    });
    this.packages.push(packageGroup);
  }

  removePackage(index: number): void {
    this.packages.removeAt(index);
  }

  loadBooking(id: number): void {
    this.loading = true;
    this.bookingService.getBookingById(id).subscribe({
      next: (response) => {
        const booking = response.data;
        this.patchFormWithBooking(booking);
        this.loading = false;
      },
      error: (err) => {
        this.error = 'Failed to load booking details.';
        this.loading = false;
        console.error('Error loading booking:', err);
      },
    });
  }

  patchFormWithBooking(booking: Booking): void {
    const normalizeAddress = (addr: Partial<Booking['pickupAddress']> | null | undefined) => ({
      addressLine: addr?.addressLine || (addr as any)?.address || '',
      city: addr?.city || '',
      province: addr?.province || '',
      postalCode: addr?.postalCode || '',
      country: (addr as any)?.country || '',
      contactName: addr?.contactName || '',
      contactPhone: addr?.contactPhone || '',
      companyName: addr?.companyName || '',
    });

    const pickupAddress = normalizeAddress(booking.pickupAddress);
    const deliveryAddress = normalizeAddress(booking.deliveryAddress);

    this.bookingForm.patchValue({
      customerId: booking.customerId,
      customerName: booking.customerName,
      customerPhone: booking.customerPhone,
      pickupAddress,
      deliveryAddress,
      serviceType: booking.serviceType,
      truckType: booking.truckType,
      capacity: booking.capacity,
      pickupDate: this.formatDateForInput(booking.pickupDate),
      deliveryDate: booking.deliveryDate ? this.formatDateForInput(booking.deliveryDate) : '',
      paymentType: booking.paymentType,
      estimatedCost: booking.estimatedCost,
      totalWeightTons: booking.totalWeightTons,
      totalVolumeCbm: booking.totalVolumeCbm,
      palletCount: booking.palletCount,
      specialHandlingNotes: booking.specialHandlingNotes,
      requiresInsurance: booking.requiresInsurance,
      notes: booking.notes,
    });

    // Find and set the customer in ng-select
    if (booking.customerId) {
      this.customerService.getCustomerById(booking.customerId).subscribe({
        next: (response) => {
          const fetchedCustomer = response.data.customer;
          this.customerSearchControl.setValue(fetchedCustomer);
          this.selectedCustomer = fetchedCustomer;
        },
        error: (err) => console.error('Error loading customer:', err),
      });
    }

    // Load packages
    if (booking.packages && booking.packages.length > 0) {
      booking.packages.forEach((pkg) => {
        const packageGroup = this.fb.group({
          itemType: [pkg.itemType, Validators.required],
          quantity: [pkg.quantity, [Validators.required, Validators.min(1)]],
          weightKg: [pkg.weightKg],
          volumeCbm: [pkg.volumeCbm],
          cod: [pkg.cod],
          description: [pkg.description],
        });
        this.packages.push(packageGroup);
      });
    }
  }

  formatDateForInput(date: Date | string): string {
    const d = new Date(date);
    return d.toISOString().split('T')[0];
  }

  onSubmit(): void {
    if (this.bookingForm.invalid) {
      this.bookingForm.markAllAsTouched();
      return;
    }

    this.submitting = true;
    this.error = null;

    const formValue = this.bookingForm.value;
    const bookingData: CreateBookingDto = {
      ...formValue,
      packages: formValue.packages.length > 0 ? formValue.packages : undefined,
    };

    const request =
      this.isEditMode && this.bookingId
        ? this.bookingService.updateBooking(this.bookingId, bookingData)
        : this.bookingService.createBooking(bookingData);

    request.subscribe({
      next: (response) => {
        this.submitting = false;
        this.notify.simulateNotification(
          'Success',
          this.isEditMode ? 'Booking updated successfully!' : 'Booking created successfully!',
        );
        this.router.navigate(['/bookings', response.data.id]);
      },
      error: (err) => {
        this.submitting = false;
        this.error = this.isEditMode
          ? 'Failed to update booking. Please try again.'
          : 'Failed to create booking. Please try again.';
        console.error('Error saving booking:', err);
      },
    });
  }

  async cancel(): Promise<void> {
    if (await this.confirm.confirm('Discard changes and go back?')) {
      this.router.navigate(['/bookings']);
    }
  }
}
