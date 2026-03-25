import { CommonModule } from '@angular/common';
import { Component, EventEmitter, Input, Output } from '@angular/core';
import { FormsModule } from '@angular/forms';
import { MatIconModule } from '@angular/material/icon';

import type { Vehicle } from '../../models/vehicle.model';
import { VehicleStatus } from '../../models/enums/vehicle.enums';

@Component({
  selector: 'app-vehicle-modal',
  standalone: true,
  imports: [CommonModule, FormsModule, MatIconModule],
  template: `
    <div
      *ngIf="visible"
      class="fixed inset-0 bg-gray-600 bg-opacity-50 flex items-center justify-center z-50"
    >
      <div class="bg-white rounded-lg p-6 w-full max-w-3xl shadow-lg">
        <div class="flex justify-between items-center mb-4">
          <h3 class="text-xl font-semibold">Select Vehicle</h3>
          <button (click)="close.emit()" class="text-gray-500 hover:text-red-600 text-lg">
            &times;
          </button>
        </div>

        <div class="grid grid-cols-1 gap-4 md:grid-cols-2">
          <input
            [(ngModel)]="filters.licensePlate"
            placeholder="License Plate"
            class="p-2 border rounded"
          />
          <input [(ngModel)]="filters.model" placeholder="Model" class="p-2 border rounded" />
          <select [(ngModel)]="filters.vehicleType" class="p-2 border rounded">
            <option value="">All Types</option>
            <option *ngFor="let type of vehicleTypes" [value]="type">{{ type }}</option>
          </select>
          <select [(ngModel)]="filters.status" class="p-2 border rounded">
            <option value="">All Statuses</option>
            <option *ngFor="let status of vehicleStatuses" [value]="status">{{ status }}</option>
          </select>
          <label class="inline-flex items-center gap-2 mt-1">
            <input type="checkbox" [(ngModel)]="filters.availableOnly" />
            <span>Available Only</span>
          </label>
        </div>

        <button
          (click)="resetFilters()"
          type="button"
          class="inline-flex items-center px-4 py-2 text-sm bg-gray-200 rounded hover:bg-gray-300"
          title="Reset Filters"
        >
          <mat-icon class="mr-1 align-middle">refresh</mat-icon>
          Reset Filters
        </button>

        <ul class="max-h-60 overflow-y-auto border rounded mt-4">
          <li
            *ngFor="let vehicle of filteredVehicles()"
            class="cursor-pointer px-4 py-2 border-b hover:bg-gray-100"
            (click)="chooseVehicle(vehicle)"
          >
            #{{ vehicle.id }} - {{ vehicle.licensePlate }} ({{ vehicle.model }}) -
            {{ vehicle.status }}
            <span
              class="text-xs text-green-600 ml-2"
              *ngIf="
                vehicle.status === VehicleStatus.ACTIVE ||
                vehicle.status === VehicleStatus.AVAILABLE
              "
            >
              [Available]
            </span>
          </li>
          <li *ngIf="filteredVehicles().length === 0" class="px-4 py-2 text-sm text-gray-400">
            No matching vehicles found.
          </li>
        </ul>

        <div class="flex justify-end mt-4">
          <button
            (click)="close.emit()"
            class="px-4 py-2 text-white bg-red-500 hover:bg-red-600 rounded"
          >
            Close
          </button>
        </div>
      </div>
    </div>
  `,
})
export class AppVehicleModalComponent {
  @Input() visible = false;
  @Output() close = new EventEmitter<void>();
  @Input() vehicles: Vehicle[] = [];
  @Output() vehicleSelected = new EventEmitter<Vehicle>();

  VehicleStatus = VehicleStatus;
  vehicleTypes = ['TRUCK', 'VAN', 'BIKE'];
  vehicleStatuses = Object.values(VehicleStatus);

  filters = {
    licensePlate: '',
    model: '',
    vehicleType: '',
    status: '',
    availableOnly: false,
  };

  filteredVehicles() {
    const availableStatuses = [VehicleStatus.ACTIVE, VehicleStatus.AVAILABLE];
    return this.vehicles.filter((vehicle) => {
      const matchPlate = vehicle.licensePlate
        .toLowerCase()
        .includes(this.filters.licensePlate.toLowerCase());
      const matchModel = vehicle.model.toLowerCase().includes(this.filters.model.toLowerCase());
      const matchType = this.filters.vehicleType ? vehicle.type === this.filters.vehicleType : true;
      const matchStatus = this.filters.status ? vehicle.status === this.filters.status : true;
      const matchAvailable = this.filters.availableOnly
        ? availableStatuses.includes(vehicle.status as VehicleStatus)
        : true;
      return matchPlate && matchModel && matchType && matchStatus && matchAvailable;
    });
  }

  resetFilters() {
    this.filters = {
      licensePlate: '',
      model: '',
      vehicleType: '',
      status: '',
      availableOnly: false,
    };
  }

  chooseVehicle(vehicle: any) {
    this.vehicleSelected.emit(vehicle);
    this.close.emit(); //  Ensure the modal closes after selection
  }
}
