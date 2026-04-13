/* eslint-disable @typescript-eslint/consistent-type-imports */
import { CommonModule } from '@angular/common';
import {
  ChangeDetectionStrategy,
  Component,
  ElementRef,
  inject,
  OnInit,
  ViewChild,
} from '@angular/core';
import { FormArray, FormBuilder, FormGroup, ReactiveFormsModule, Validators } from '@angular/forms';
import { Router } from '@angular/router';
import { finalize } from 'rxjs';

import { VehicleType, TruckSize, VehicleOwnership } from '../../../../models/enums/vehicle.enums';
import type {
  VehicleSetupRequest,
  PMTriggerType,
} from '../../../../models/vehicle-setup.model';
import { VehicleService } from '../../../../services/vehicle.service';

@Component({
  selector: 'app-vehicle-setup',
  standalone: true,
  templateUrl: './vehicle-setup.component.html',
  styleUrls: ['./vehicle-setup.component.css'],
  changeDetection: ChangeDetectionStrategy.OnPush,
  imports: [CommonModule, ReactiveFormsModule],
})
export class VehicleSetupComponent implements OnInit {
  @ViewChild('licensePlateInput') licensePlateInput!: ElementRef<HTMLInputElement>;
  private fb = inject(FormBuilder);
  private vehicleService = inject(VehicleService);
  private router = inject(Router);

  vehicleForm!: FormGroup;
  isLoading = false;
  errorMessage = '';
  showError = true;
  licensePlateFieldError = '';
  successMessage = '';
  showSuccess = true;

  // Enum values for dropdowns
  vehicleTypes = Object.values(VehicleType);
  vehicleOwnerships = Object.values(VehicleOwnership);
  truckSizes = Object.values(TruckSize);

  // Dismiss success alert
  dismissSuccess(): void {
    this.showSuccess = false;
  }

  // Dismiss error alert
  dismissError(): void {
    this.showError = false;
  }

  // Field-level error check for template
  hasError(controlName: string): boolean {
    const control = this.vehicleForm.get(controlName);
    return !!(control && control.invalid && (control.dirty || control.touched));
  }

  // Get error message for a specific field
  getErrorMessage(controlName: string): string {
    const control = this.vehicleForm.get(controlName);
    if (!control || !control.errors) return '';
    if (control.errors['required']) return 'This field is required.';
    if (control.errors['minlength'])
      return `Minimum length is ${control.errors['minlength'].requiredLength}.`;
    if (control.errors['maxlength'])
      return `Maximum length is ${control.errors['maxlength'].requiredLength}.`;
    if (control.errors['pattern']) return 'Invalid format.';
    if (control.errors['duplicate']) return this.licensePlateFieldError || 'Duplicate value.';
    if (control.errors['min']) return `Minimum value is ${control.errors['min'].min}.`;
    if (control.errors['max']) return `Maximum value is ${control.errors['max'].max}.`;
    return 'Invalid value.';
  }

  // Cancel button handler
  onCancel(): void {
    this.router.navigate(['/fleet/vehicles']);
  }
  // ...existing code up to the end of the first VehicleSetupComponent class...

  // Document types required for vehicles
  requiredDocumentTypes = ['REGISTRATION', 'INSURANCE', 'INSPECTION'];

  ngOnInit(): void {
    this.initializeForm();
    this.updateTruckSizeValidation();
  }

  private initializeForm(): void {
    this.vehicleForm = this.fb.group({
      licensePlate: ['', [Validators.required, Validators.minLength(2), Validators.maxLength(20)]],
      vin: ['', [Validators.required, Validators.maxLength(17)]],
      manufacturer: ['', [Validators.required, Validators.maxLength(80)]],
      model: ['', [Validators.required, Validators.maxLength(80)]],
      yearMade: [
        new Date().getFullYear(),
        [Validators.required, Validators.min(1900), Validators.max(2100)],
      ],
      type: [VehicleType.TRUCK, Validators.required],
      ownership: [VehicleOwnership.OWNED, Validators.required],
      truckSize: [TruckSize.MEDIUM_TRUCK],

      fuelConsumption: [0, [Validators.required, Validators.min(0)]],
      mileage: [0, [Validators.required, Validators.min(0)]],
      maxWeight: [null],
      maxVolume: [null],
      qtyPalletsCapacity: [null],
      gpsDeviceId: [''],
      assignedZone: [''],
      requiredLicenseClass: [''],
      remarks: [''],

      documents: this.fb.array([]),
      maintenancePolicy: this.fb.group({
        schedules: this.fb.array([]),
      }),
    });
    this.initializeRequiredDocuments();

    this.vehicleForm.get('type')?.valueChanges.subscribe(() => {
      this.updateTruckSizeValidation();
    });
  }

  private initializeRequiredDocuments(): void {
    const documentsArray = this.vehicleForm.get('documents') as FormArray;
    this.requiredDocumentTypes.forEach((docType) => {
      documentsArray.push(this.createDocumentFormGroup(docType));
    });
  }

  private createDocumentFormGroup(documentType: string): FormGroup {
    return this.fb.group({
      documentType: [documentType, Validators.required],
      documentUrl: ['', Validators.required],
      documentNumber: [''],
      issueDate: [''],
      expiryDate: ['', Validators.required],
      approved: [true],
      notes: [''],
    });
  }

  get documents(): FormArray {
    return this.vehicleForm.get('documents') as FormArray;
  }

  get maintenanceSchedules(): FormArray {
    return this.vehicleForm.get('maintenancePolicy.schedules') as FormArray;
  }

  addMaintenanceSchedule(): void {
    const schedulesArray = this.maintenanceSchedules;
    schedulesArray.push(this.createMaintenanceScheduleFormGroup());
    this.onScheduleTriggerTypeChange(schedulesArray.length - 1);
  }

  removeMaintenanceSchedule(index: number): void {
    const schedulesArray = this.maintenanceSchedules;
    schedulesArray.removeAt(index);
  }

  private createMaintenanceScheduleFormGroup(): FormGroup {
    return this.fb.group({
      scheduleName: ['', Validators.required],
      description: [''],
      triggerType: ['MILEAGE', Validators.required],
      triggerInterval: [10000, [Validators.required, Validators.min(1)]],
      triggerIntervalDays: [null, [Validators.min(1)]],
      reminderBeforeKm: [1000],
      reminderBeforeDays: [7],
      taskTypeId: [null, Validators.required],
    });
  }

  isTruckType(): boolean {
    return this.vehicleForm.get('type')?.value === VehicleType.TRUCK;
  }

  isTimeBasedTrigger(index: number): boolean {
    return this.maintenanceSchedules.at(index)?.get('triggerType')?.value === 'TIME_BASED';
  }

  usesMileageTrigger(index: number): boolean {
    const triggerType = this.maintenanceSchedules.at(index)?.get('triggerType')?.value;
    return triggerType === 'MILEAGE' || triggerType === 'BOTH';
  }

  usesTimeTrigger(index: number): boolean {
    const triggerType = this.maintenanceSchedules.at(index)?.get('triggerType')?.value;
    return triggerType === 'TIME_BASED' || triggerType === 'BOTH';
  }

  onScheduleTriggerTypeChange(index: number): void {
    const scheduleGroup = this.maintenanceSchedules.at(index) as FormGroup | null;
    if (!scheduleGroup) return;

    const triggerType = scheduleGroup.get('triggerType')?.value as string | undefined;
    const triggerIntervalControl = scheduleGroup.get('triggerInterval');
    const triggerIntervalDaysControl = scheduleGroup.get('triggerIntervalDays');

    if (triggerType === 'TIME_BASED') {
      triggerIntervalControl?.clearValidators();
      triggerIntervalControl?.setValue(null);
      triggerIntervalDaysControl?.setValidators([Validators.required, Validators.min(1)]);
      triggerIntervalDaysControl?.setValue(triggerIntervalDaysControl.value ?? 30);
    } else if (triggerType === 'BOTH') {
      triggerIntervalControl?.setValidators([Validators.required, Validators.min(1)]);
      triggerIntervalDaysControl?.setValidators([Validators.required, Validators.min(1)]);
      triggerIntervalControl?.setValue(triggerIntervalControl.value ?? 10000);
      triggerIntervalDaysControl?.setValue(triggerIntervalDaysControl.value ?? 30);
    } else {
      triggerIntervalControl?.setValidators([Validators.required, Validators.min(1)]);
      triggerIntervalControl?.setValue(triggerIntervalControl.value ?? 10000);
      triggerIntervalDaysControl?.clearValidators();
      triggerIntervalDaysControl?.setValue(null);
    }

    triggerIntervalControl?.updateValueAndValidity();
    triggerIntervalDaysControl?.updateValueAndValidity();
  }

  onSubmit(): void {
    if (this.vehicleForm.invalid) {
      this.markFormGroupTouched(this.vehicleForm);
      this.errorMessage = 'Please fill in all required fields correctly.';
      this.showError = true;
      return;
    }
    this.isLoading = true;
    this.errorMessage = '';
    this.successMessage = '';
    this.showError = false;
    this.showSuccess = false;
    this.licensePlateFieldError = '';

    const formValue = this.vehicleForm.getRawValue();
    const schedules = (formValue.maintenancePolicy?.schedules ?? []).map((schedule: any) => ({
      ...schedule,
      triggerInterval:
        schedule.triggerType === 'TIME_BASED' ? undefined : Number(schedule.triggerInterval),
      triggerIntervalDays: this.usesTimeBasedValue(schedule.triggerType)
        ? Number(schedule.triggerIntervalDays)
        : undefined,
      reminderBeforeKm:
        schedule.reminderBeforeKm !== null && schedule.reminderBeforeKm !== undefined
          ? Number(schedule.reminderBeforeKm)
          : undefined,
      reminderBeforeDays:
        schedule.reminderBeforeDays !== null && schedule.reminderBeforeDays !== undefined
          ? Number(schedule.reminderBeforeDays)
          : undefined,
      taskTypeId: Number(schedule.taskTypeId),
    }));

    const setupRequest: VehicleSetupRequest = {
      ...formValue,
      licensePlate: formValue.licensePlate.trim(),
      vin: formValue.vin?.trim() || undefined,
      manufacturer: formValue.manufacturer.trim(),
      model: formValue.model.trim(),
      assignedZone: formValue.assignedZone?.trim() || undefined,
      requiredLicenseClass: formValue.requiredLicenseClass?.trim() || undefined,
      gpsDeviceId: formValue.gpsDeviceId?.trim() || undefined,
      remarks: formValue.remarks?.trim() || undefined,
      truckSize: this.isTruckType() ? formValue.truckSize : undefined,
      maintenancePolicy: schedules.length > 0 ? { schedules } : undefined,
      year: formValue.yearMade,
    };

    setupRequest.documents = setupRequest.documents?.map((doc: any) => ({
      ...doc,
      issueDate: doc.issueDate ? new Date(doc.issueDate).toISOString().split('T')[0] : undefined,
      expiryDate: doc.expiryDate ? new Date(doc.expiryDate).toISOString().split('T')[0] : undefined,
    }));

    this.vehicleService
      .setupVehicle(setupRequest)
      .pipe(finalize(() => (this.isLoading = false)))
      .subscribe({
        next: (response) => {
          if (response.success && response.data) {
            this.successMessage = `Vehicle ${response.data.licensePlate} has been successfully set up and is ready for operation!`;
            this.showSuccess = true;
            setTimeout(() => {
              this.router.navigate(['/fleet/vehicles', response.data.id]);
            }, 2000);
          } else {
            this.handleApiError(response);
          }
        },
        error: (error) => {
          if (error.error?.code === 'DUPLICATE_LICENSE_PLATE') {
            this.handleDuplicateLicensePlate(error.error.message);
            return;
          }

          this.errorMessage = error.error?.message || 'An error occurred while setting up the vehicle.';
          this.showError = true;
          this.licensePlateFieldError = '';
        },
      });
  }

  private markFormGroupTouched(formGroup: FormGroup): void {
    Object.keys(formGroup.controls).forEach((key: string) => {
      const control = formGroup.get(key);
      if (control instanceof FormGroup) {
        this.markFormGroupTouched(control);
      } else if (control instanceof FormArray) {
        control.controls.forEach((child) => {
          if (child instanceof FormGroup) {
            this.markFormGroupTouched(child);
          } else {
            child.markAsTouched();
          }
        });
      } else {
        control?.markAsTouched();
      }
    });
  }

  private handleApiError(response: any): void {
    if (response.code === 'DUPLICATE_LICENSE_PLATE') {
      this.handleDuplicateLicensePlate(response.message);
    } else {
      this.errorMessage = response.errors || response.message || 'Failed to setup vehicle.';
      this.showError = true;
      this.licensePlateFieldError = '';
    }
  }

  private handleDuplicateLicensePlate(message?: string): void {
    this.licensePlateFieldError = message || 'Duplicate license plate';
    this.errorMessage = '';
    this.showError = false;
    const control = this.vehicleForm.get('licensePlate');
    control?.setErrors({ ...(control.errors ?? {}), duplicate: true });
    control?.markAsTouched();
    setTimeout(() => {
      this.licensePlateInput?.nativeElement?.focus();
    }, 0);
  }

  private updateTruckSizeValidation(): void {
    const truckSizeControl = this.vehicleForm.get('truckSize');
    if (!truckSizeControl) return;

    if (this.isTruckType()) {
      truckSizeControl.setValidators([Validators.required]);
      truckSizeControl.setValue(truckSizeControl.value || TruckSize.MEDIUM_TRUCK, {
        emitEvent: false,
      });
    } else {
      truckSizeControl.clearValidators();
      truckSizeControl.setValue('', { emitEvent: false });
    }

    truckSizeControl.updateValueAndValidity({ emitEvent: false });
  }

  private usesTimeBasedValue(triggerType: PMTriggerType | string | undefined): boolean {
    return triggerType === 'TIME_BASED' || triggerType === 'BOTH';
  }
}
