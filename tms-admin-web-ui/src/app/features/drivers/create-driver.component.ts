/* eslint-disable @typescript-eslint/consistent-type-imports */
import { CommonModule } from '@angular/common';
import { Component } from '@angular/core';
import { Router } from '@angular/router';
import { DriversFormComponent } from '../../components/drivers/drivers-form.component';
import { DriverService } from '../../services/driver.service';
import type { Driver } from '../../models/driver.model';

@Component({
  selector: 'app-create-driver-page',
  standalone: true,
  imports: [CommonModule, DriversFormComponent],
  template: `
    <div class="p-6 bg-gray-50 min-h-screen">
      <h1 class="text-3xl font-bold mb-4">Create New Driver</h1>
      <app-drivers-form
        [displayAsPage]="true"
        [isOpen]="true"
        [isEditing]="false"
        [isSaving]="isSaving"
        (save)="onSave($event)"
        (cancel)="onCancel()"
      ></app-drivers-form>
    </div>
  `,
})
export class CreateDriverComponent {
  isSaving = false;

  constructor(
    private readonly driverService: DriverService,
    private readonly router: Router,
  ) {}

  onSave(payload: Partial<Driver>): void {
    this.isSaving = true;
    this.driverService.addDriver(payload as any).subscribe({
      next: (res: any) => {
        const id = res?.data?.id;
        if (id) {
          // navigate to driver detail
          this.router.navigate(['/drivers', id]);
        } else {
          // fallback to list
          this.router.navigate(['/drivers']);
        }
      },
      error: () => {
        this.isSaving = false;
      },
    });
  }

  onCancel(): void {
    this.router.navigate(['/drivers']);
  }
}
