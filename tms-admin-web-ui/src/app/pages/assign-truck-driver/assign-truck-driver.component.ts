import { Component, OnInit, OnDestroy } from '@angular/core';
import { FormBuilder, FormGroup, Validators, ReactiveFormsModule } from '@angular/forms';
import {
  VehicleDriverService,
  AssignmentRequest,
  AssignmentResponse,
} from '../../services/vehicle-driver.service';
import { DriverService } from '../../services/driver.service';
import { VehicleService } from '../../services/vehicle.service';
import { ConfirmService } from '../../services/confirm.service';
import { InputPromptService } from '../../core/input-prompt.service';
import { CommonModule } from '@angular/common';
import { TranslateModule, TranslateService } from '@ngx-translate/core';
import { Subject, takeUntil, debounceTime, distinctUntilChanged } from 'rxjs';

@Component({
  selector: 'app-assign-truck-driver',
  standalone: true,
  imports: [CommonModule, ReactiveFormsModule, TranslateModule],
  templateUrl: './assign-truck-driver.component.html',
  styleUrls: ['./assign-truck-driver.component.css'],
})
export class AssignTruckDriverComponent implements OnInit, OnDestroy {
  assignmentForm: FormGroup;
  drivers: any[] = [];
  trucks: any[] = [];

  // Loading states
  loading = false;
  loadingDrivers = false;
  loadingTrucks = false;
  checkingDriverAssignment = false;
  checkingTruckAssignment = false;

  // Messages
  successMessage = '';
  errorMessage = '';
  warningMessage = '';

  // Current assignments
  currentDriverAssignment: AssignmentResponse | null = null;
  currentTruckAssignment: AssignmentResponse | null = null;
  showSwapWarning = false;

  // Unsubscribe subject
  private destroy$ = new Subject<void>();

  constructor(
    private fb: FormBuilder,
    private assignmentService: VehicleDriverService,
    private driverService: DriverService,
    private vehicleService: VehicleService,
    private confirm: ConfirmService,
    private inputPrompt: InputPromptService,
    private translate: TranslateService,
  ) {
    this.assignmentForm = this.fb.group({
      driverId: [null, Validators.required],
      vehicleId: [null, Validators.required],
      reason: [''],
      forceReassignment: [false],
    });
  }

  ngOnInit(): void {
    this.loadDrivers();
    this.loadTrucks();
    this.setupFormListeners();
  }

  ngOnDestroy(): void {
    if (this.destroy$.closed || this.destroy$.isStopped) {
      return;
    }
    this.destroy$.next();
    this.destroy$.complete();
    this.destroy$.unsubscribe();
  }

  loadDrivers(): void {
    this.loadingDrivers = true;

    this.driverService
      .getDrivers(0, 1000)
      .pipe(takeUntil(this.destroy$))
      .subscribe({
        next: (response) => {
          if (response.success && response.data) {
            // Backend returns PageResponse<DriverDto> wrapped in ApiResponse
            // PageResponse has: content, totalElements, totalPages, size, number
            if ('content' in response.data && Array.isArray(response.data.content)) {
              this.drivers = response.data.content;
            } else if (Array.isArray(response.data)) {
              this.drivers = response.data;
            } else {
              console.warn('[AssignTruckDriver] Unexpected response structure:', response);
              this.drivers = [];
            }
            console.log('[AssignTruckDriver] Loaded', this.drivers.length, 'drivers');
          } else {
            console.warn('[AssignTruckDriver] Response success=false:', response);
            this.drivers = [];
          }
          setTimeout(() => {
            this.loadingDrivers = false;
          }, 0);
        },
        error: (err) => {
          console.error('[AssignTruckDriver] ❌ Failed to load drivers:', err);
          this.errorMessage = this.translate.instant('assignTruckDriver.load_drivers_failed');
          setTimeout(() => {
            this.loadingDrivers = false;
          }, 0);
          this.drivers = [];
        },
      });
  }

  loadTrucks(): void {
    this.loadingTrucks = true;

    this.vehicleService
      .getVehicles(0, 1000)
      .pipe(takeUntil(this.destroy$))
      .subscribe({
        next: (response) => {
          if (response.success && response.data) {
            // Backend returns Page<VehicleDto> wrapped in ApiResponse
            // Page has: content, totalElements, totalPages
            if ('content' in response.data && Array.isArray(response.data.content)) {
              this.trucks = response.data.content;
            } else if (Array.isArray(response.data)) {
              this.trucks = response.data;
            } else {
              console.warn('[AssignTruckDriver] Unexpected response structure:', response);
              this.trucks = [];
            }
            console.log('[AssignTruckDriver] Loaded', this.trucks.length, 'trucks');
          } else {
            console.warn('[AssignTruckDriver] Response success=false:', response);
            this.trucks = [];
          }
          setTimeout(() => {
            this.loadingTrucks = false;
          }, 0);
        },
        error: (err) => {
          console.error('[AssignTruckDriver] ❌ Failed to load trucks:', err);
          this.errorMessage = this.translate.instant('assignTruckDriver.load_trucks_failed');
          setTimeout(() => {
            this.loadingTrucks = false;
          }, 0);
          this.trucks = [];
        },
      });
  }

  setupFormListeners(): void {
    // Debounce driver selection to avoid excessive API calls
    this.assignmentForm
      .get('driverId')
      ?.valueChanges.pipe(debounceTime(300), distinctUntilChanged(), takeUntil(this.destroy$))
      .subscribe((driverId) => {
        if (driverId) {
          this.checkDriverAssignment(driverId);
        } else {
          this.currentDriverAssignment = null;
          this.updateSwapWarning();
        }
      });

    // Debounce truck selection to avoid excessive API calls
    this.assignmentForm
      .get('vehicleId')
      ?.valueChanges.pipe(debounceTime(300), distinctUntilChanged(), takeUntil(this.destroy$))
      .subscribe((vehicleId) => {
        if (vehicleId) {
          this.checkTruckAssignment(vehicleId);
        } else {
          this.currentTruckAssignment = null;
          this.updateSwapWarning();
        }
      });
  }

  checkDriverAssignment(driverId: number): void {
    this.checkingDriverAssignment = true;
    this.assignmentService
      .getDriverAssignment(driverId)
      .pipe(takeUntil(this.destroy$))
      .subscribe({
        next: (response) => {
          this.currentDriverAssignment = response.data;
          this.updateSwapWarning();
          this.checkingDriverAssignment = false;
          console.log('[AssignTruckDriver] Driver assignment:', this.currentDriverAssignment);
        },
        error: (err) => {
          // 404 is expected when no assignment exists
          if (err.status === 404) {
            this.currentDriverAssignment = null;
            this.updateSwapWarning();
          } else {
            console.error('[AssignTruckDriver] Failed to check driver assignment:', err);
            this.warningMessage = this.translate.instant(
              'assignTruckDriver.verify_driver_assignment_failed',
            );
          }
          this.checkingDriverAssignment = false;
        },
      });
  }

  checkTruckAssignment(vehicleId: number): void {
    this.checkingTruckAssignment = true;
    this.assignmentService
      .getTruckAssignment(vehicleId)
      .pipe(takeUntil(this.destroy$))
      .subscribe({
        next: (response) => {
          this.currentTruckAssignment = response.data;
          this.updateSwapWarning();
          this.checkingTruckAssignment = false;
          console.log('[AssignTruckDriver] Truck assignment:', this.currentTruckAssignment);
        },
        error: (err) => {
          // 404 is expected when no assignment exists
          if (err.status === 404) {
            this.currentTruckAssignment = null;
            this.updateSwapWarning();
          } else {
            console.error('[AssignTruckDriver] Failed to check truck assignment:', err);
            this.warningMessage = this.translate.instant(
              'assignTruckDriver.verify_truck_assignment_failed',
            );
          }
          this.checkingTruckAssignment = false;
        },
      });
  }

  updateSwapWarning(): void {
    this.showSwapWarning = !!(this.currentDriverAssignment || this.currentTruckAssignment);
  }

  getAssignmentDriverName(assignment: AssignmentResponse | null | undefined): string {
    if (!assignment) return this.translate.instant('assignTruckDriver.unassigned');
    return (
      assignment.driverName ||
      assignment.driverFullName ||
      this.translate.instant('assignTruckDriver.unassigned')
    );
  }

  async onSubmit(): Promise<void> {
    // Clear previous messages
    this.successMessage = '';
    this.errorMessage = '';
    this.warningMessage = '';

    // Validate form
    if (this.assignmentForm.invalid) {
      this.errorMessage = this.translate.instant('assignTruckDriver.required_fields');
      Object.keys(this.assignmentForm.controls).forEach((key) => {
        this.assignmentForm.get(key)?.markAsTouched();
      });
      return;
    }

    // Prevent double-submission
    if (this.loading) {
      return;
    }

    // Confirmation dialog for reassignments
    if (
      (this.currentDriverAssignment || this.currentTruckAssignment) &&
      !this.assignmentForm.value.forceReassignment
    ) {
      const confirmMessage = this.buildConfirmationMessage();
      if (!(await this.confirm.confirm(confirmMessage))) {
        return;
      }
    }

    this.loading = true;
    const request: AssignmentRequest = this.assignmentForm.value;

    console.log('[AssignTruckDriver] Submitting assignment:', request);

    this.assignmentService
      .assignTruckToDriver(request)
      .pipe(takeUntil(this.destroy$))
      .subscribe({
        next: (response) => {
          setTimeout(() => {
            this.loading = false;
          }, 0);
          this.successMessage = `Assigned ${response.data.truckPlate} to ${this.getAssignmentDriverName(response.data)} successfully`;
          if (response.requestId) {
            console.log('[AssignTruckDriver] Success - Request ID:', response.requestId);
          }

          // Reset form and state
          this.assignmentForm.reset({
            driverId: null,
            vehicleId: null,
            reason: '',
            forceReassignment: false,
          });
          this.currentDriverAssignment = null;
          this.currentTruckAssignment = null;
          this.showSwapWarning = false;

          // Scroll to success message
          setTimeout(() => window.scrollTo({ top: 0, behavior: 'smooth' }), 100);
        },
        error: (err) => {
          setTimeout(() => {
            this.loading = false;
          }, 0);
          if (err?.status === 404 && err?.error?.message) {
            this.errorMessage = err.error.message;
          } else if (err?.status === 409 && err?.error?.message) {
            this.errorMessage = err.error.message;
          } else if (err?.name === 'TimeoutError') {
            this.errorMessage = 'Request timeout';
          } else if (err?.status === 0) {
            this.errorMessage = 'network error';
          } else {
            this.errorMessage = err?.message || 'Failed to assign truck to driver';
          }

          if (err.requestId) {
            this.errorMessage += ` (Request ID: ${err.requestId})`;
            console.error('[AssignTruckDriver] Error - Request ID:', err.requestId);
          }

          // Provide helpful hints for common errors
          if (err.status === 409) {
            this.warningMessage =
              'Try enabling "Force Reassignment" if you want to override existing assignments.';
          } else if (err.status === 401 || err.status === 403) {
            this.warningMessage = 'You may need to re-login to perform this action.';
          }

          console.error('[AssignTruckDriver] Assignment failed:', err);

          // Scroll to error message
          setTimeout(() => window.scrollTo({ top: 0, behavior: 'smooth' }), 100);
        },
      });
  }

  private buildConfirmationMessage(): string {
    const parts: string[] = ['Warning: This will cause reassignments!'];

    if (this.currentDriverAssignment) {
      parts.push(`\n- Driver is currently assigned to ${this.currentDriverAssignment.truckPlate}`);
    }

    if (this.currentTruckAssignment) {
      parts.push(
        `\n- Truck is currently assigned to ${this.getAssignmentDriverName(this.currentTruckAssignment)}`,
      );
    }

    parts.push('\n\nDo you want to continue?');
    return parts.join('');
  }

  async revoke(driverId: number): Promise<void> {
    const driverName =
      this.getAssignmentDriverName(this.currentDriverAssignment) !== 'Unassigned'
        ? this.getAssignmentDriverName(this.currentDriverAssignment)
        : `Driver #${driverId}`;
    const truckPlate = this.currentDriverAssignment?.truckPlate || 'unknown';

    if (
      !(await this.confirm.confirm(
        `Are you sure you want to revoke the assignment of ${truckPlate} from ${driverName}?`,
      ))
    ) {
      return;
    }

    const reason = await this.inputPrompt.prompt('Reason for revocation (optional):', {
      placeholder: 'Optional reason',
    });

    this.loading = true;
    this.successMessage = '';
    this.errorMessage = '';
    this.warningMessage = '';

    console.log('[AssignTruckDriver] Revoking assignment:', { driverId, reason });

    this.assignmentService
      .revokeDriverAssignment(driverId, reason || undefined)
      .pipe(takeUntil(this.destroy$))
      .subscribe({
        next: () => {
          this.loading = false;
          this.successMessage = `Assignment revoked successfully for ${driverName}`;
          this.currentDriverAssignment = null;
          this.updateSwapWarning();

          // Clear driver selection if it matches revoked driver
          if (this.assignmentForm.value.driverId === driverId) {
            this.assignmentForm.patchValue({ driverId: null });
          }

          console.log('[AssignTruckDriver] Revoke successful');

          // Scroll to success message
          setTimeout(() => window.scrollTo({ top: 0, behavior: 'smooth' }), 100);
        },
        error: (err) => {
          this.loading = false;
          this.errorMessage = err.message || 'Failed to revoke assignment';

          if (err.requestId) {
            this.errorMessage += ` (Request ID: ${err.requestId})`;
          }

          console.error('[AssignTruckDriver] Revoke failed:', err);

          // Scroll to error message
          setTimeout(() => window.scrollTo({ top: 0, behavior: 'smooth' }), 100);
        },
      });
  }
}
