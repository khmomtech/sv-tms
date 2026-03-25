/* eslint-disable @typescript-eslint/consistent-type-imports */
import { CommonModule } from '@angular/common';
import { OnInit } from '@angular/core';
import { Component, Inject } from '@angular/core';
import { FormGroup } from '@angular/forms';
import { FormBuilder } from '@angular/forms';
import { Validators, ReactiveFormsModule } from '@angular/forms';
import { MatDialogRef } from '@angular/material/dialog';
import { MAT_DIALOG_DATA, MatDialogModule } from '@angular/material/dialog';

import type { Driver } from '../../models/driver.model';

@Component({
  selector: 'app-send-notification-dialog',
  standalone: true,
  imports: [CommonModule, ReactiveFormsModule, MatDialogModule],
  templateUrl: './send-notification-dialog.component.html',
  styleUrls: ['./send-notification-dialog.component.css'],
})
export class SendNotificationDialogComponent implements OnInit {
  form: FormGroup;
  drivers: Driver[] = [];
  filteredDrivers: Driver[] = [];

  constructor(
    private fb: FormBuilder,
    public dialogRef: MatDialogRef<SendNotificationDialogComponent>,
    @Inject(MAT_DIALOG_DATA) public data: { drivers: Driver[] },
  ) {
    this.drivers = data.drivers || [];
    this.form = this.fb.group({
      driver: ['', Validators.required],
      title: ['', Validators.required],
      message: ['', Validators.required],
    });
  }

  ngOnInit(): void {
    this.filterDrivers(); // Initialize filtered list
  }

  filterDrivers(): void {
    const value = this.form.get('driver')?.value?.toLowerCase() || '';
    this.filteredDrivers = this.drivers.filter((d) => d.name?.toLowerCase().includes(value));
  }

  selectDriver(driver: Driver): void {
    this.form.patchValue({ driver: driver.name });
    this.filteredDrivers = [];
  }

  onSubmit(): void {
    if (this.form.valid) {
      const selectedDriver = this.drivers.find((d) => d.name === this.form.value.driver);
      if (selectedDriver) {
        this.dialogRef.close({
          driver: selectedDriver,
          title: this.form.value.title,
          message: this.form.value.message,
        });
      } else {
        this.form.get('driver')?.setErrors({ notFound: true });
      }
    } else {
      this.form.markAllAsTouched();
    }
  }

  cancel(): void {
    this.dialogRef.close();
  }
}
