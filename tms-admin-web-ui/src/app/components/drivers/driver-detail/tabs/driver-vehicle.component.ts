import { CommonModule } from '@angular/common';
import type { OnChanges, SimpleChanges } from '@angular/core';
import { Component, EventEmitter, Input, Output, inject } from '@angular/core';
import { FormsModule } from '@angular/forms';
import { MatAutocompleteModule } from '@angular/material/autocomplete';
import { MatButtonModule } from '@angular/material/button';
import { MatFormFieldModule } from '@angular/material/form-field';
import { MatInputModule } from '@angular/material/input';

import type { Driver } from '../../../../models/driver.model';
import type { Vehicle } from '../../../../models/vehicle.model';
import { ConfirmService } from '../../../../services/confirm.service';

// Angular Material imports

@Component({
  selector: 'app-driver-vehicle',
  standalone: true,
  imports: [
    CommonModule,
    FormsModule,
    MatFormFieldModule,
    MatInputModule,
    MatAutocompleteModule,
    MatButtonModule,
  ],
  templateUrl: './driver-vehicle.component.html',
})
export class DriverVehicleComponent implements OnChanges {
  private confirm = inject(ConfirmService);
  @Input() driverData!: Driver;
  @Input() allVehicles: Vehicle[] = [];
  @Input() assignedVehicles: Vehicle[] = [];

  @Output() assignVehicle = new EventEmitter<number>();
  @Output() unassignVehicle = new EventEmitter<void>();
  @Output() viewVehicleEvent = new EventEmitter<Vehicle>();
  @Output() editVehicleEvent = new EventEmitter<Vehicle>();
  @Output() deleteVehicleEvent = new EventEmitter<Vehicle>();

  selectedVehicleId: number | null = null;
  showAssignConfirm = false;
  showUnassignConfirm = false;
  /** Parent can signal processing state to disable controls */
  @Input() isProcessing = false;
  openMenuId: number | null = null;
  vehicleSearch: string = '';

  // Local guard to prevent immediate duplicate clicks when parent doesn't toggle processing fast
  localSubmitting = false;

  /** Filtered list used by the autocomplete */
  get filteredVehicles(): Vehicle[] {
    const q = (this.vehicleSearch || '').toLowerCase().trim();
    if (!q) return this.allVehicles;
    return this.allVehicles.filter(
      (v) =>
        (v.licensePlate || '').toLowerCase().includes(q) ||
        (v.model || '').toLowerCase().includes(q) ||
        (v.type || '').toLowerCase().includes(q),
    );
  }

  /** Make a nice label for the text input */
  private vehicleLabel(v?: Vehicle): string {
    if (!v) return '';
    const plate = v.licensePlate ?? '';
    const model = v.model ?? '';
    const type = v.type ?? '';
    return `${plate} - ${model} (${type})`.trim();
  }

  /** When a user picks an option in the autocomplete */
  onVehicleSelected(event: any): void {
    const id = (event?.option?.value as number) ?? null;
    this.selectedVehicleId = id;
    const v = this.allVehicles.find((x) => x.id === id);
    this.vehicleSearch = this.vehicleLabel(v);
  }

  ngOnChanges(changes: SimpleChanges): void {
    if (changes['driverData'] && this.driverData) {
      this.selectedVehicleId = this.driverData.assignedVehicleId ?? null;
      const v = this.allVehicles.find((x) => x.id === (this.selectedVehicleId ?? undefined));
      this.vehicleSearch = this.vehicleLabel(v);
      this.showAssignConfirm = false;
      this.showUnassignConfirm = false;
    }
  }

  get assignedVehicle(): Vehicle | undefined {
    return this.allVehicles.find((v) => v.id === this.driverData?.assignedVehicleId);
  }

  confirmAssign(): void {
    if (
      this.selectedVehicleId !== null &&
      this.selectedVehicleId !== this.driverData.assignedVehicleId
    ) {
      this.showAssignConfirm = true;
    }
  }

  assign(): void {
    if (
      this.selectedVehicleId !== null &&
      this.selectedVehicleId !== this.driverData.assignedVehicleId
    ) {
      if (this.isProcessing || this.localSubmitting) return;
      this.localSubmitting = true;
      this.assignVehicle.emit(this.selectedVehicleId);
      this.showAssignConfirm = false;
      // release local guard shortly after emit; parent is expected to update `isProcessing`
      setTimeout(() => (this.localSubmitting = false), 1500);
    }
  }

  confirmUnassign(): void {
    this.showUnassignConfirm = true;
  }

  unassign(): void {
    this.unassignVehicle.emit();
    this.selectedVehicleId = null;
    this.vehicleSearch = '';
    this.showUnassignConfirm = false;
  }

  toggleMenu(vehicleId: number): void {
    this.openMenuId = this.openMenuId === vehicleId ? null : vehicleId;
  }

  viewVehicle(_vehicle: Vehicle): void {
    this.openMenuId = null;
    if (_vehicle) this.viewVehicleEvent.emit(_vehicle);
  }

  reassignVehicle(vehicle: Vehicle): void {
    this.selectedVehicleId = vehicle.id ?? null;
    this.vehicleSearch = this.vehicleLabel(vehicle);
    this.confirmAssign();
    this.openMenuId = null;
  }

  editVehicle(vehicle: Vehicle): void {
    this.openMenuId = null;
    if (vehicle) this.editVehicleEvent.emit(vehicle);
  }

  async deleteVehicle(vehicle: Vehicle): Promise<void> {
    this.openMenuId = null;
    if (!vehicle) return;
    const confirmed = await this.confirm.confirm(`Delete vehicle #${vehicle.id}?`);
    if (!confirmed) return;
    this.deleteVehicleEvent.emit(vehicle);
  }
}
