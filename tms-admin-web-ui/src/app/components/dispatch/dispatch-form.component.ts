import { CommonModule } from '@angular/common';
import type { OnInit, QueryList, ElementRef, AfterViewInit } from '@angular/core';
// eslint-disable-next-line @typescript-eslint/consistent-type-imports
import { ChangeDetectorRef } from '@angular/core';
import { Component, Input, Output, EventEmitter, ViewChildren } from '@angular/core';
import type { FormArray } from '@angular/forms';
// eslint-disable-next-line @typescript-eslint/consistent-type-imports
import { FormBuilder } from '@angular/forms';
import { FormGroup, Validators, ReactiveFormsModule, FormsModule } from '@angular/forms';
import { GoogleMapsModule } from '@angular/google-maps';
// eslint-disable-next-line @typescript-eslint/consistent-type-imports
import { ActivatedRoute } from '@angular/router';

import type { Vehicle } from '../../models/vehicle.model';
// eslint-disable-next-line @typescript-eslint/consistent-type-imports
import { VehicleService } from '../../services/vehicle.service'; //  Add your path here
import { AppDriverModalComponent } from '../app-driver-modal/app-driver-modal.component';
import { AppVehicleModalComponent } from '../app-vehicle-modal/app-vehicle-modal.component';

import { EditStopModalComponent } from './modals/edit-stop-modal.component';

@Component({
  selector: 'app-dispatch-form',
  standalone: true,
  templateUrl: './dispatch-form.component.html',
  styleUrls: ['./dispatch-form.component.css'],
  imports: [
    CommonModule,
    FormsModule,
    ReactiveFormsModule,
    GoogleMapsModule,
    AppDriverModalComponent,
    AppVehicleModalComponent,
    EditStopModalComponent,
  ],
})
export class DispatchFormComponent implements OnInit, AfterViewInit {
  @Input() form!: FormGroup;
  @Input() selectedDriver: any = null;
  @Input() selectedVehicle: any = null;
  @Output() submitForm = new EventEmitter<any>();
  @Output() cancel = new EventEmitter<void>();
  @ViewChildren('searchInput') searchInputs!: QueryList<ElementRef<HTMLInputElement>>;
  @ViewChildren('modalSearchInput') modalSearchInputs!: QueryList<ElementRef<HTMLInputElement>>;

  mapCenter: google.maps.LatLngLiteral = { lat: 11.5564, lng: 104.9282 };
  geocoder!: google.maps.Geocoder;

  allVehicles: Vehicle[] = [];
  loadingVehicles = false;

  showDriverModal = false;
  showVehicleModal = false;
  showEditStopModal = false;
  showDispatchForm = false;
  editingStopIndex: number | null = null;
  editStopForm: FormGroup;

  constructor(
    private fb: FormBuilder,
    private route: ActivatedRoute,
    private cdRef: ChangeDetectorRef,
    private vehicleService: VehicleService, //  inject service
  ) {
    this.editStopForm = this.fb.group({
      label: ['', Validators.required],
      type: ['pickup', Validators.required],
      coordinates: [''],
      location: [''],
      latitude: [null],
      longitude: [null],
      note: [''],
    });
  }

  ngOnInit(): void {
    console.debug('[DispatchFormComponent] Received form:', this.form);
    this.geocoder = new google.maps.Geocoder();

    if (!this.form || !(this.form instanceof FormGroup)) {
      console.warn('No input form provided, initializing new form.');
      this.form = this.fb.group(
        {
          manualRouteCode: ['', [Validators.required, Validators.maxLength(20)]],
          tripType: ['STANDARD', [Validators.required]],
          startTime: ['', Validators.required],
          estimatedArrival: ['', Validators.required],
          status: ['PLANNED', Validators.required],
          transportOrderId: [null],
          driverId: [null, [Validators.required, Validators.min(1)]],
          vehicleId: [null, [Validators.required, Validators.min(1)]],
          cancelReason: ['', Validators.maxLength(200)],
          stops: this.fb.array([]),
        },
        { validators: this.timeOrderValidator },
      );
    }

    this.setupTimeSync();

    const orderId = Number(this.route.snapshot.queryParamMap.get('orderId'));
    if (!isNaN(orderId) && orderId > 0 && !this.form.get('transportOrderId')?.value) {
      this.form.patchValue({ transportOrderId: orderId });
    }

    this.loadVehicles();
  }

  loadVehicles(): void {
    this.loadingVehicles = true;
    this.vehicleService.getAllVehicles().subscribe({
      next: (response) => {
        this.allVehicles = response.data; //  Extract data array
        this.syncSelectedVehicleFromForm();
        this.loadingVehicles = false;
      },
      error: (err) => {
        console.error(' Failed to load vehicles:', err);
        this.loadingVehicles = false;
      },
    });
  }

  ngAfterViewInit(): void {
    setTimeout(() => {
      this.modalSearchInputs?.forEach((inputRef) => {
        if (inputRef?.nativeElement) {
          this.initEditModalAutocomplete(inputRef.nativeElement);
        }
      });
    }, 100);
  }

  get stopsFormArray(): FormArray<FormGroup> {
    return this.form.get('stops') as FormArray<FormGroup>;
  }

  openNewDispatchForm(): void {
    this.showDispatchForm = true;
    if (this.stopsFormArray.length === 0) {
      this.addStop();
    }
    this.cdRef.detectChanges();
  }

  addStop(): void {
    const stopGroup = this.fb.group({
      label: ['Stop', Validators.required],
      type: ['dropoff', Validators.required],
      coordinates: [''],
      location: [''],
      latitude: [null],
      longitude: [null],
      note: [''],
    });

    this.editingStopIndex = this.stopsFormArray.length;
    this.editStopForm.reset(stopGroup.value);
    this.showEditStopModal = true;
    this.cdRef.detectChanges();
  }

  removeStop(index: number): void {
    if (index >= 0 && index < this.stopsFormArray.length) {
      this.stopsFormArray.removeAt(index);
    }
  }

  moveStopUp(index: number): void {
    if (index <= 0) return;
    const stops = this.stopsFormArray;
    const temp = stops.at(index);
    stops.setControl(index, stops.at(index - 1));
    stops.setControl(index - 1, temp);
  }

  moveStopDown(index: number): void {
    const stops = this.stopsFormArray;
    if (index >= stops.length - 1) return;
    const temp = stops.at(index);
    stops.setControl(index, stops.at(index + 1));
    stops.setControl(index + 1, temp);
  }

  openEditStop(index: number): void {
    const stop = this.stopsFormArray.at(index);
    if (!stop) return;
    this.editStopForm.patchValue(stop.value);
    this.editingStopIndex = index;
    this.showEditStopModal = true;
    this.cdRef.detectChanges();

    setTimeout(() => {
      this.modalSearchInputs?.forEach((inputRef) => {
        if (inputRef?.nativeElement) {
          this.initEditModalAutocomplete(inputRef.nativeElement);
        }
      });
    }, 100);
  }

  saveStop(): void {
    if (this.editStopForm.valid) {
      const stopGroup = this.fb.group(this.editStopForm.value);
      if (this.editingStopIndex !== null && this.stopsFormArray.at(this.editingStopIndex)) {
        this.stopsFormArray.setControl(this.editingStopIndex, stopGroup);
      } else {
        this.stopsFormArray.push(stopGroup);
      }
      this.showEditStopModal = false;
    }
  }

  cancelStopEdit(): void {
    this.showEditStopModal = false;
  }

  initEditModalAutocomplete(input: HTMLInputElement): void {
    const autocomplete = new google.maps.places.Autocomplete(input, {
      fields: ['geometry', 'formatted_address'],
      types: ['geocode'],
    });

    autocomplete.addListener('place_changed', () => {
      const place = autocomplete.getPlace();
      if (!place.geometry || !place.geometry.location) return;

      const lat = place.geometry.location.lat();
      const lng = place.geometry.location.lng();
      const coord = `${lat},${lng}`;
      const address = place.formatted_address || coord;

      this.editStopForm.patchValue({
        latitude: lat,
        longitude: lng,
        coordinates: coord,
        location: address,
        note: `Selected: ${address}`,
      });

      this.cdRef.detectChanges();
    });
  }

  onMapSelect(event: google.maps.MapMouseEvent, index: number): void {
    const latLng = event.latLng?.toJSON();
    if (!latLng) return;

    const coord = `${latLng.lat},${latLng.lng}`;
    const stop = this.stopsFormArray.at(index);
    if (!stop) return;

    stop.patchValue({
      latitude: latLng.lat,
      longitude: latLng.lng,
      coordinates: coord,
    });

    this.geocoder.geocode({ location: latLng }, (results, status) => {
      if (status === 'OK' && results && results.length > 0) {
        const result = results[0];
        stop.patchValue({
          location: result.formatted_address,
          note: `Selected: ${result.formatted_address}`,
        });
      }
    });
  }

  getMapCenter(index: number): google.maps.LatLngLiteral {
    const coord = this.stopsFormArray.at(index)?.get('coordinates')?.value;
    if (coord) {
      const [lat, lng] = coord.split(',').map(Number);
      return { lat, lng };
    }
    return this.mapCenter;
  }

  onDriverSelected(driver: any): void {
    this.selectedDriver = driver;
    const formUpdates: any = { driverId: driver.id };
    const driverVehicle = this.findAssociatedVehicleFromDriver(driver);
    if (driverVehicle) {
      formUpdates.vehicleId = driverVehicle.id;
      this.selectedVehicle = driverVehicle;
    } else {
      this.selectedVehicle = null;
      formUpdates.vehicleId = null;
    }

    this.form.patchValue(formUpdates);
    this.showDriverModal = false;
  }

  onVehicleSelected(vehicle: Vehicle): void {
    this.selectedVehicle = vehicle;
    this.form.patchValue({ vehicleId: vehicle.id });
    this.showVehicleModal = false;
  }

  onSubmit(): void {
    // Mark all fields as touched to show validation errors
    this.form.markAllAsTouched();

    if (!this.form.valid) {
      // Identify and report specific validation errors
      const errors: string[] = [];

      if (this.form.get('transportOrderId')?.hasError('required')) {
        errors.push('Transport Order is required');
      }
      if (this.form.get('driverId')?.hasError('required')) {
        errors.push('Driver is required');
      }
      if (this.form.get('vehicleId')?.hasError('required')) {
        errors.push('Vehicle is required');
      }
      if (this.form.get('startTime')?.hasError('required')) {
        errors.push('Start Time is required');
      }
      if (this.form.get('estimatedArrival')?.hasError('required')) {
        errors.push('Estimated Arrival is required');
      }

      console.warn('Form validation failed:', errors);
      return;
    }

    this.submitForm.emit(this.form.value);
  }

  onCancel(): void {
    this.cancel.emit();
  }

  timeOrderValidator(group: FormGroup): any {
    const start = new Date(group.get('startTime')?.value);
    const end = new Date(group.get('estimatedArrival')?.value);
    return start && end && start >= end ? { timeOrderInvalid: true } : null;
  }

  private setupTimeSync(): void {
    const startCtrl = this.form.get('startTime');
    const etaCtrl = this.form.get('estimatedArrival');

    startCtrl?.valueChanges.subscribe(() => {
      this.ensureEstimatedArrivalAfterStart();
    });

    etaCtrl?.valueChanges.subscribe(() => {
      this.ensureEstimatedArrivalAfterStart(false);
    });
  }

  private ensureEstimatedArrivalAfterStart(forceUpdate: boolean = true): void {
    const start = this.parseInputToDate(this.form.get('startTime')?.value);
    const etaCtrl = this.form.get('estimatedArrival');
    const eta = this.parseInputToDate(etaCtrl?.value);

    if (!start || (eta && eta > start && !forceUpdate)) {
      return;
    }

    const candidate = new Date(start.getTime() + 5 * 60 * 1000);
    etaCtrl?.setValue(this.toDateTimeLocalString(candidate), { emitEvent: false });
  }

  private parseInputToDate(value: unknown): Date | null {
    if (!value) return null;
    const parsed = typeof value === 'string' ? new Date(value) : value;
    return parsed instanceof Date && !isNaN(parsed.getTime()) ? parsed : null;
  }

  private toDateTimeLocalString(date: Date): string {
    const offsetMinutes = date.getTimezoneOffset();
    const localDate = new Date(date.getTime() - offsetMinutes * 60 * 1000);
    return localDate.toISOString().slice(0, 16);
  }

  private syncSelectedVehicleFromForm(): void {
    const vehicleId = this.form.get('vehicleId')?.value;
    if (!vehicleId) {
      return;
    }

    const vehicle = this.allVehicles.find((v) => Number(v.id) === Number(vehicleId));
    if (vehicle) {
      this.selectedVehicle = vehicle;
    }
  }

  private findAssociatedVehicleFromDriver(driver: any): Vehicle | null {
    const directVehicleId =
      driver.currentVehicleId || driver.assignedVehicleId || driver.assignedVehicle?.id;
    if (directVehicleId) {
      const matchedById = this.allVehicles.find((v) => Number(v.id) === Number(directVehicleId));
      if (matchedById) {
        return matchedById;
      }
    }

    const rawPlate =
      driver.currentVehiclePlate ||
      driver.assignedVehiclePlate ||
      driver.assignedVehicle?.licensePlate;
    const driverPlate = this.normalizePlate(rawPlate);
    if (driverPlate) {
      const matchedByPlate = this.allVehicles.find(
        (v) => this.normalizePlate((v as any).licensePlate) === driverPlate,
      );
      if (matchedByPlate) {
        return matchedByPlate;
      }
    }

    return null;
  }

  private normalizePlate(plate: unknown): string {
    return String(plate || '')
      .toUpperCase()
      .replace(/[\s-]/g, '')
      .trim();
  }
}
