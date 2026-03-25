import { CommonModule } from '@angular/common';
import { Component } from '@angular/core';
import { FormsModule } from '@angular/forms'; //  Import FormsModule

@Component({
  selector: 'app-driver-assignments',
  standalone: true, //  Standalone component
  imports: [CommonModule, FormsModule], //  Add FormsModule here
  templateUrl: './driver-assignments.component.html',
  styleUrls: ['./driver-assignments.component.css'],
})
export class DriverAssignmentsComponent {
  newDriverId: number = 0;
  newVehicleId: number = 0;

  assignments: any[] = [];

  constructor() {}

  loadAssignments(): void {
    // Mock Data for Assignments (replace with API call)
    this.assignments = [
      {
        id: 1,
        driver: { name: 'John Doe' },
        vehicle: { licensePlate: 'ABC-123' },
        assignedAt: '2024-03-04',
        status: 'ASSIGNED',
      },
    ];
  }

  assignDriver(): void {
    console.log(`Assigning Driver ID: ${this.newDriverId} to Vehicle ID: ${this.newVehicleId}`);
  }

  completeAssignment(id: number): void {
    console.log(`Completing Assignment ID: ${id}`);
  }

  cancelAssignment(id: number): void {
    console.log(`Canceling Assignment ID: ${id}`);
  }
}
