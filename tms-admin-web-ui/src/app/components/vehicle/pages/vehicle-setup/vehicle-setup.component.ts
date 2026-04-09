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
  VehicleDocumentRequest,
  MaintenancePolicyRequest,
  PMScheduleRequest,
} from '../../../../models/vehicle-setup.model';
import type { Vehicle } from '../../../../models/vehicle.model';
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
      truckSize: [''],

      fuelConsumption: [0, [Validators.required, Validators.min(0)]],
      mileage: [0, [Validators.required, Validators.min(0)]],
      maxWeight: [null],
      maxVolume: [null],
      qtyPalletsCapacity: [null],
      gpsDeviceId: [''],
      assignedZoneId: [null],
      requiredLicenseClass: [''],
      remarks: [''],

      documents: this.fb.array([]),
      maintenancePolicy: this.fb.group({
        schedules: this.fb.array([]),
      }),
    });
    this.initializeRequiredDocuments();
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
      reminderBeforeKm: [1000],
      reminderBeforeDays: [7],
      taskTypeId: [null, Validators.required],
    });
  }

  onSubmit(): void {
    if (this.vehicleForm.invalid) {
      this.markFormGroupTouched(this.vehicleForm);
      this.errorMessage = 'Please fill in all required fields correctly.';
      return;
    }
    this.isLoading = true;
    this.errorMessage = '';
    this.successMessage = '';
    this.showError = false;
    this.showSuccess = false;
    this.licensePlateFieldError = '';

    const setupRequest: VehicleSetupRequest = {
      ...this.vehicleForm.value,
      year: this.vehicleForm.value.yearMade,
    };
    // Convert date strings to proper format if needed
    setupRequest.documents = setupRequest.documents?.map((doc) => ({
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
            this.licensePlateFieldError = error.error.message || 'Duplicate license plate';
            this.errorMessage = '';
            this.showError = false;
            // Mark field as touched and focus
            const control = this.vehicleForm.get('licensePlate');
            control?.setErrors({ duplicate: true });
            control?.markAsTouched();
            setTimeout(() => {
              this.licensePlateInput?.nativeElement?.focus();
            }, 0);
          } else {
            this.errorMessage =
              error.error?.message || 'An error occurred while setting up the vehicle.';
            this.showError = true;
            this.licensePlateFieldError = '';
          }
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
      this.licensePlateFieldError = response.message || 'Duplicate license plate';
      this.errorMessage = '';
      this.showError = false;
      const control = this.vehicleForm.get('licensePlate');
      control?.setErrors({ duplicate: true });
      control?.markAsTouched();
      setTimeout(() => {
        this.licensePlateInput?.nativeElement?.focus();
      }, 0);
    } else {
      this.errorMessage = response.message || 'Failed to setup vehicle.';
      this.showError = true;
      this.licensePlateFieldError = '';
    }
  }
}
