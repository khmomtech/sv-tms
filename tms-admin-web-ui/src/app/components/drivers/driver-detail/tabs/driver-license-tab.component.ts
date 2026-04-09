/* eslint-disable @typescript-eslint/consistent-type-imports */
import { CommonModule } from '@angular/common';
import { OnInit } from '@angular/core';
import { Component, Input, Output, EventEmitter } from '@angular/core';
import { FormGroup } from '@angular/forms';
import { FormBuilder } from '@angular/forms';
import { FormsModule, ReactiveFormsModule, Validators } from '@angular/forms';

import { environment } from '../../../../environments/environment';
import type { ApiResponse } from '../../../../models/api-response.model';
import type { DriverLicense } from '../../../../models/driver-license.model';
import { DriverService } from '../../../../services/driver.service';
import { firstValueFrom } from 'rxjs';

@Component({
  selector: 'app-driver-license-tab',
  standalone: true,
  imports: [CommonModule, FormsModule, ReactiveFormsModule],
  templateUrl: './driver-license-tab.component.html',
})
export class DriverLicenseTabComponent implements OnInit {
  @Input() driverId!: number;
  @Output() licenseUpdated = new EventEmitter<DriverLicense | null>();

  // Cambodia driver license classes
  readonly cambodiaLicenseClasses = [
    { code: 'A1', label: 'A1 - Motorcycle ≤125cc' },
    { code: 'A', label: 'A - Motorcycle/Scooter' },
    { code: 'B1', label: 'B1 - Auto ≤400kg' },
    { code: 'B', label: 'B - Light vehicle ≤3,500kg' },
    { code: 'C', label: 'C - Truck (3,500-16,000kg)' },
    { code: 'C1', label: 'C1 - Medium truck ≤7,500kg' },
    { code: 'D', label: 'D - Passenger bus' },
    { code: 'E', label: 'E - Tractor/Trailer' },
  ];

  bsConfig = {
    dateInputFormat: 'DD-MMMM-YYYY',
    containerClass: 'theme-blue',
    showWeekNumbers: false,
  };

  licenseForm!: FormGroup;
  license: DriverLicense | null = null;

  dropdownOpen = false;
  dropdownOpenId: number | null = null;

  isEditing = false;
  isLoading = false;
  showModal = false;
  showDeleteConfirm = false; // Confirmation dialog for delete

  frontPreviewUrl: string | null = null;
  backPreviewUrl: string | null = null;

  selectedFrontFile: File | null = null;
  selectedBackFile: File | null = null;

  constructor(
    private fb: FormBuilder,
    private driverService: DriverService,
  ) {}

  ngOnInit(): void {
    this.initForm();
    if (this.driverId) {
      this.fetchLicense();
    }
  }

  getImageUrl(path: string | null): string {
    return path ? `${environment.baseUrl}${path}` : '';
  }

  toggleDropdown(id: number): void {
    this.dropdownOpenId = this.dropdownOpenId === id ? null : id;
  }

  private initForm(): void {
    this.licenseForm = this.fb.group({
      licenseNumber: ['', Validators.required],
      licenseClass: [''], // Cambodia: A1, A, B1, B, C, C1, D, E - Critical for truck assignments
      issuedDate: [''],
      expiryDate: [''],
      issuingAuthority: [''],
      licenseImageUrl: [''],
      licenseFrontImage: [''],
      licenseBackImage: [''],
      notes: [''],
    });
  }

  fetchLicense(): void {
    this.isLoading = true;
    this.driverService.getDriverLicense(this.driverId).subscribe({
      next: (res: ApiResponse<DriverLicense>) => {
        this.license = res.data;
        this.isLoading = false;
      },
      error: (err: any) => {
        // Gracefully handle server errors — keep UI usable and show a friendly message
        this.license = null;
        this.isLoading = false;
        try {
          const status = err?.status ?? 'unknown';
          const serverMsg = err?.error?.message || err?.message || '';
          const userMsg =
            status === 404
              ? 'Driver license not found.'
              : status === 500
                ? 'Server error while fetching driver license. Try again later.'
                : `Failed to fetch driver license (${status}).`;
          this.driverService.showToast(userMsg, 'Close', 6000);
          console.warn('[DriverLicenseTab] fetchLicense error', { status, serverMsg, err });
        } catch (e) {
          console.error('[DriverLicenseTab] unexpected error handling license fetch', e);
        }
      },
    });
  }

  openModal(): void {
    this.isEditing = false;
    this.licenseForm.reset();
    this.frontPreviewUrl = null;
    this.backPreviewUrl = null;
    this.selectedFrontFile = null;
    this.selectedBackFile = null;
    this.showModal = true;
  }

  editLicense(): void {
    if (!this.license) return;
    this.isEditing = true;
    this.licenseForm.patchValue({
      ...this.license,
      issuedDate: this.formatDateForInput(this.license.issuedDate),
      expiryDate: this.formatDateForInput(this.license.expiryDate),
    });
    this.frontPreviewUrl = this.getImageUrl(this.license.licenseFrontImage || null);
    this.backPreviewUrl = this.getImageUrl(this.license.licenseBackImage || null);
    this.showModal = true;
  }

  private formatDateForInput(date: any): string {
    if (!date) return '';
    if (typeof date === 'string') {
      return date.substring(0, 10);
    }
    if (date instanceof Date) {
      return date.toISOString().substring(0, 10);
    }
    return '';
  }

  closeModal(): void {
    this.licenseForm.reset();
    this.frontPreviewUrl = null;
    this.selectedFrontFile = null;
    this.selectedBackFile = null;
    this.showModal = false;
    // Clear file input fields
    const fileInputs = document.querySelectorAll('input[type="file"]');
    fileInputs.forEach((input: Element) => {
      const fileInput = input as HTMLInputElement;
      fileInput.value = '';
    });
  }

  // Check if license is expired
  isLicenseExpired(): boolean {
    if (!this.license?.expiryDate) return false;
    const expiry = new Date(this.license.expiryDate);
    return expiry < new Date();
  }

  // Get expiry status text for badge
  getExpiryStatus(): string {
    if (!this.license?.expiryDate) return '';
    const expiry = new Date(this.license.expiryDate);
    const today = new Date();

    if (expiry < today) {
      const daysExpired = Math.floor((today.getTime() - expiry.getTime()) / (1000 * 60 * 60 * 24));
      return `EXPIRED ${daysExpired} days ago`;
    }

    const daysRemaining = Math.floor((expiry.getTime() - today.getTime()) / (1000 * 60 * 60 * 24));
    return `Valid for ${daysRemaining} more days`;
  }

  // Show delete confirmation dialog
  confirmDelete(): void {
    this.showDeleteConfirm = true;
  }

  // Cancel delete
  cancelDelete(): void {
    this.showDeleteConfirm = false;
  }

  onFileSelect(event: Event, field: 'licenseFrontImage' | 'licenseBackImage'): void {
    const input = event.target as HTMLInputElement;
    if (input.files && input.files.length > 0) {
      const file = input.files[0];

      //  Validate type
      const allowedTypes = ['image/jpeg', 'image/png', 'image/jpg'];
      if (!allowedTypes.includes(file.type)) {
        this.driverService.showToast('Only JPG and PNG images are allowed');
        return;
      }

      //  Validate size (10MB max)
      const maxSize = 10 * 1024 * 1024;
      if (file.size > maxSize) {
        this.driverService.showToast('File size must be under 10MB');
        return;
      }

      //  Preview
      const reader = new FileReader();
      reader.onload = () => {
        if (field === 'licenseFrontImage') {
          this.frontPreviewUrl = reader.result as string;
          this.selectedFrontFile = file;
        } else {
          this.backPreviewUrl = reader.result as string;
          this.selectedBackFile = file;
        }
      };
      reader.readAsDataURL(file);
    }
  }

  async onSubmit(): Promise<void> {
    if (!this.licenseForm.valid || !this.driverId || this.isLoading) return;

    const issued = new Date(this.licenseForm.value.issuedDate);
    const expiry = new Date(this.licenseForm.value.expiryDate);
    if (issued && expiry && expiry < issued) {
      this.driverService.showToast('Expiry date must be after issued date');
      return;
    }

    this.isLoading = true;

    try {
      if (this.selectedFrontFile) {
        const res = await firstValueFrom(
          this.driverService.uploadLicenseImage(
            this.driverId,
            this.selectedFrontFile,
            'licenseFrontImage',
          ),
        );
        this.licenseForm.patchValue({ licenseFrontImage: res?.data });
      }

      if (this.selectedBackFile) {
        const res = await firstValueFrom(
          this.driverService.uploadLicenseImage(
            this.driverId,
            this.selectedBackFile,
            'licenseBackImage',
          ),
        );
        this.licenseForm.patchValue({ licenseBackImage: res?.data });
      }

      const payload: DriverLicense = {
        ...this.licenseForm.value,
        driverId: this.driverId,
      };

      const request = this.isEditing
        ? this.driverService.updateDriverLicense(this.driverId, payload)
        : this.driverService.addDriverLicense(this.driverId, payload);

      request.subscribe({
        next: (res) => {
          this.license = res.data;
          this.licenseUpdated.emit(this.license);
          this.driverService.showToast(this.isEditing ? 'License updated' : 'License created');
          this.isEditing = true;
          this.isLoading = false;
          this.showModal = false;
        },
        error: () => {
          this.driverService.showToast('Failed to save license');
          this.isLoading = false;
        },
      });
    } catch (error) {
      this.driverService.showToast('Image upload or save failed');
      this.isLoading = false;
    }
  }

  onDelete(): void {
    if (!this.license?.id || this.isLoading) return;

    this.isLoading = true;
    this.showDeleteConfirm = false;
    this.driverService.deleteDriverLicense(this.license.id).subscribe({
      next: () => {
        this.driverService.showToast('License deleted');
        this.license = null;
        this.licenseForm.reset();
        this.isEditing = false;
        this.isLoading = false;
        this.licenseUpdated.emit(null);
      },
      error: () => {
        this.driverService.showToast('Failed to delete license');
        this.isLoading = false;
      },
    });
  }
}
