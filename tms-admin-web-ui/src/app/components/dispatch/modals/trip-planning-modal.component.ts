import { CommonModule } from '@angular/common';
import { Component, EventEmitter, Input, Output } from '@angular/core';
import { FormsModule } from '@angular/forms';

import type { TransportOrder } from '../../../models/transport-order.model';
import type { Vehicle } from '../../../models/vehicle.model';

@Component({
  selector: 'app-trip-planning-modal',
  standalone: true,
  imports: [CommonModule, FormsModule],
  templateUrl: './trip-planning-modal.component.html',
})
export class TripPlanningModalComponent {
  @Input() order: TransportOrder | null | undefined;
  @Input() vehicles: Vehicle[] = [];
  @Input() visible = false;

  @Output() close = new EventEmitter<void>();
  @Output() submitPlan = new EventEmitter<any>();

  selectedOrder?: TransportOrder;
  showTripModal: boolean = false;

  tripPlan = {
    tripType: '',
    vehicleId: null,
    scheduleTime: '',
    estimatedDrop: '',
  };

  submit() {
    if (!this.order) return;
    this.submitPlan.emit({
      orderId: this.order.id,
      ...this.tripPlan,
    });
  }

  cancel() {
    this.close.emit();
  }

  onPlanTrip(order: TransportOrder): void {
    this.selectedOrder = order;
    this.showTripModal = true;
  }

  handleTripSubmit(plan: any): void {
    console.log(' Trip Plan Submitted:', plan);
    // Call your backend service to create the trip or assign it to a driver
    this.showTripModal = false;
  }

  closeModal(): void {
    this.showTripModal = false;
  }
}
