import { CommonModule } from '@angular/common';
import type { OnInit, OnChanges, SimpleChanges } from '@angular/core';
import { Component, Input, Output, EventEmitter } from '@angular/core';
import type { FormGroup } from '@angular/forms';
// eslint-disable-next-line @typescript-eslint/consistent-type-imports
import { FormBuilder } from '@angular/forms';
import { Validators, ReactiveFormsModule } from '@angular/forms';

// eslint-disable-next-line @typescript-eslint/consistent-type-imports
import { DispatchService } from '../../services/dispatch.service';
import { DriverService } from '../../services/driver.service';
import { ToastrService } from 'ngx-toastr';
import { DriverAutocompleteComponent } from '../../shared/components/driver-autocomplete/driver-autocomplete.component';

export interface Driver {
  id: number;
  name: string;
  phone?: string;
}

@Component({
  selector: 'app-assign-driver-modal',
  standalone: true,
  templateUrl: './assign-driver-modal.component.html',
  imports: [CommonModule, ReactiveFormsModule, DriverAutocompleteComponent],
})
export class AssignDriverModalComponent implements OnInit, OnChanges {
  @Input() dispatchId!: number;
  @Input() currentDriverId?: number | null;
  @Input() drivers: Driver[] = [];
  @Input() allowForceReassignment = false;
  @Input() defaultForceReassignment = false;
  @Output() closed = new EventEmitter<void>();
  @Output() submitAssign = new EventEmitter<number>();
  @Output() submitAssignDetailed = new EventEmitter<{
    driverId: number;
    forceReassignment: boolean;
  }>();

  form!: FormGroup;
  loading = false;
  errorMessage = '';

  constructor(
    private readonly fb: FormBuilder,
    private readonly dispatchService: DispatchService,
    private readonly driverService: DriverService,
    private readonly toastr: ToastrService,
  ) {}

  ngOnInit(): void {
    this.form = this.fb.group({
      driverId: [null, Validators.required],
      forceReassignment: [this.defaultForceReassignment],
    });

    if (this.drivers.length === 0) {
      this.loadDrivers();
    } else {
      this.applyCurrentSelection();
    }
  }

  ngOnChanges(changes: SimpleChanges): void {
    if (!this.form) return;
    if (changes['drivers'] || changes['currentDriverId']) {
      this.applyCurrentSelection();
    }
    if (changes['defaultForceReassignment']) {
      this.form.get('forceReassignment')?.patchValue(this.defaultForceReassignment, {
        emitEvent: false,
      });
    }
  }

  private applyCurrentSelection(): void {
    const ctrl = this.form.get('driverId');
    if (ctrl && this.currentDriverId != null && ctrl.value !== this.currentDriverId) {
      ctrl.patchValue(this.currentDriverId);
    }
  }

  private loadDrivers(): void {
    this.loading = true;
    this.errorMessage = '';
    this.dispatchService.getAvailableDrivers().subscribe({
      next: (res: any) => {
        this.drivers = res?.data ?? [];
        this.loading = false;
        this.applyCurrentSelection();
      },
      error: (err) => {
        console.error('Failed to fetch drivers:', err);
        this.errorMessage = 'Unable to load drivers.';
        this.loading = false;
      },
    });
  }

  onDriverSearch(query: string): void {
    const trimmedQuery = query.trim();
    if (!trimmedQuery) {
      this.loadDrivers();
      return;
    }

    this.loading = true;
    this.errorMessage = '';
    this.driverService.searchDrivers(trimmedQuery).subscribe({
      next: (res: any) => {
        this.drivers = res?.data ?? [];
        this.loading = false;
        this.applyCurrentSelection();
      },
      error: (err) => {
        console.error('Failed to search drivers:', err);
        this.errorMessage = 'Unable to search drivers.';
        this.loading = false;
      },
    });
  }

  submit(): void {
    if (this.form.invalid) {
      this.form.markAllAsTouched();
      return;
    }
    const selectedDriverId = this.form.value.driverId as number;
    const forceReassignment = !!this.form.value.forceReassignment;
    // emit to parent which will call API and refresh; show quick feedback here
    this.submitAssign.emit(selectedDriverId);
    this.submitAssignDetailed.emit({ driverId: selectedDriverId, forceReassignment });
    this.toastr.success('Assigning driver...');
  }

  cancel(): void {
    this.closed.emit();
  }
}
