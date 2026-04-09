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
import { DriverAutocompleteComponent } from '../../shared/components/driver-autocomplete/driver-autocomplete.component';

@Component({
  selector: 'app-change-driver-modal',
  standalone: true,
  templateUrl: './change-driver-modal.component.html',
  imports: [CommonModule, ReactiveFormsModule, DriverAutocompleteComponent],
})
export class ChangeDriverModalComponent implements OnInit {
  @Input() dispatchId!: number;
  @Output() closed = new EventEmitter<void>();

  form!: FormGroup;
  drivers: any[] = [];

  constructor(
    private readonly fb: FormBuilder,
    private readonly dispatchService: DispatchService,
    private readonly toastr: ToastrService,
  ) {}

  ngOnInit(): void {
    this.form = this.fb.group({
      driverId: [null, Validators.required],
    });

    this.loadDrivers();
  }

  loadDrivers(): void {
    this.dispatchService.getAvailableDrivers().subscribe({
      next: (res: any) => {
        this.drivers = res.data ?? [];
        console.log('Driver List:', this.drivers);
      },
      error: (err) => {
        console.error('Failed to fetch drivers:', err);
      },
    });
  }

  submit(): void {
    if (this.form.valid) {
      const selectedDriverId = this.form.value.driverId;
      this.dispatchService.changeDriver(this.dispatchId, selectedDriverId).subscribe({
        next: () => {
          this.toastr.success('Driver changed successfully.');
          this.closed.emit();
        },
        error: (err) => {
          console.error('Failed to change driver:', err);
          // If the service rethrows HttpErrorResponse, prefer the server message
          const serverMessage = err?.error?.message ?? err?.message;
          this.toastr.error(serverMessage || 'Failed to change driver.');
        },
      });
    }
  }

  cancel(): void {
    this.closed.emit();
  }
}
