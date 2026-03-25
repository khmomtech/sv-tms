/* eslint-disable @typescript-eslint/consistent-type-imports */
import { Component } from '@angular/core';

import type { Driver } from '../../models/driver.model';
import { DriverService } from '../../services/driver.service';

type CreateDriverDto = Pick<
  Driver,
  'name' | 'licenseNumber' | 'phone' | 'rating' | 'isActive' | 'isPartner'
>;

const defaultDriverData: CreateDriverDto = {
  name: '',
  licenseNumber: '',
  phone: '',
  rating: 0,
  isActive: true,
  isPartner: false,
};

@Component({
  selector: 'app-add-driver',
  templateUrl: './add-driver.component.html',
  styleUrls: ['./add-driver.component.css'],
})
export class AddDriverComponent {
  driver: CreateDriverDto = { ...defaultDriverData };
  isSubmitting = false;
  errorMessage = '';

  constructor(private readonly driverService: DriverService) {}

  addDriver(): void {
    if (!this.driver.name || !this.driver.licenseNumber || !this.driver.phone) {
      this.errorMessage = '⚠️ Please fill out all required fields.';
      return;
    }

    this.isSubmitting = true;
    this.errorMessage = '';

    this.driverService.addDriver(this.driver as Driver).subscribe({
      next: (res) => {
        console.log('Driver added on UI:', res);
        this.resetForm();
      },
      error: (err) => {
        this.errorMessage = ' Failed to add driver. Please try again.';
        console.error('Add Driver Error:', err);
      },
      complete: () => {
        this.isSubmitting = false;
      },
    });
  }

  resetForm(): void {
    this.driver = { ...defaultDriverData };
  }
}
