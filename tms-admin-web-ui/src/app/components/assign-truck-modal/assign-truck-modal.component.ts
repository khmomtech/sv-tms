import { CommonModule } from '@angular/common';
import type { OnInit } from '@angular/core';
import { Component, Input, Output, EventEmitter } from '@angular/core';
import type { FormGroup } from '@angular/forms';
// eslint-disable-next-line @typescript-eslint/consistent-type-imports
import { FormBuilder } from '@angular/forms';
import { Validators, ReactiveFormsModule } from '@angular/forms';

// eslint-disable-next-line @typescript-eslint/consistent-type-imports
import { DispatchService } from '../../services/dispatch.service';
import { ToastrService } from 'ngx-toastr';

@Component({
  selector: 'app-assign-truck-modal',
  standalone: true,
  templateUrl: './assign-truck-modal.component.html',
  imports: [CommonModule, ReactiveFormsModule],
})
export class AssignTruckModalComponent implements OnInit {
  @Input() dispatchId!: number;
  @Output() closed = new EventEmitter<void>();

  form!: FormGroup;
  trucks: any[] = [];

  constructor(
    private readonly fb: FormBuilder,
    private readonly dispatchService: DispatchService,
    private readonly toastr: ToastrService,
  ) {}

  ngOnInit(): void {
    this.form = this.fb.group({
      vehicleId: [null, Validators.required],
    });

    this.dispatchService.getAvailableTrucks().subscribe({
      next: (res) => {
        this.trucks = res.data ?? [];
      },
      error: (err) => {
        console.error(' Failed to load trucks:', err);
      },
    });
  }

  submit(): void {
    if (this.form.valid) {
      const vehicleId = this.form.value.vehicleId;
      this.dispatchService.assignTruckOnly(this.dispatchId, vehicleId).subscribe({
        next: () => {
          this.toastr.success('Truck assigned successfully.');
          this.closed.emit();
        },
        error: (err) => {
          console.error(' Failed to assign truck:', err);
          this.toastr.error(err?.error?.message || 'Failed to assign truck.');
        },
      });
    }
  }

  cancel(): void {
    this.closed.emit();
  }
}
