import { CommonModule } from '@angular/common';
import { Component, inject, signal, type OnInit } from '@angular/core';
import {
  FormsModule,
  ReactiveFormsModule,
  FormBuilder,
  type FormGroup,
  Validators,
} from '@angular/forms';
import { Router, ActivatedRoute, RouterModule } from '@angular/router';
import { NgSelectModule } from '@ng-select/ng-select';
import type { Observable } from 'rxjs';
import { of, catchError, map, finalize } from 'rxjs';

import type { Driver } from '../../../../models/driver.model';
import type { Vehicle } from '../../../../models/vehicle.model';
import { DriverService } from '../../../../services/driver.service';
import { VehicleService } from '../../../../services/vehicle.service';
import { IncidentGroup, IncidentStatus, IssueSeverity } from '../../models/incident.model';
import { IncidentService } from '../../services/incident.service';

/**
 * IncidentFormComponent
 *
 * Form component for creating and editing incidents in the TMS system.
 * Provides a comprehensive interface for reporting driver, system, or customer incidents
 * with support for attachments, driver/vehicle selection, and severity classification.
 *
 * @standalone true
 * @selector app-incident-form
 */
@Component({
  selector: 'app-incident-form',
  standalone: true,
  imports: [CommonModule, FormsModule, ReactiveFormsModule, RouterModule, NgSelectModule],
  templateUrl: './incident-form.component.html',
  styleUrls: ['./incident-form.component.css'],
})
export class IncidentFormComponent implements OnInit {
  // ============================================================================
  // Dependency Injection
  // ============================================================================

  private readonly incidentService = inject(IncidentService);
  private readonly driverService = inject(DriverService);
  private readonly vehicleService = inject(VehicleService);
  private readonly router = inject(Router);
  private readonly route = inject(ActivatedRoute);
  private readonly fb = inject(FormBuilder);

  // ============================================================================
  // Component State
  // ============================================================================

  incidentForm: FormGroup;
  incidentId = signal<number | null>(null);
  isEditMode = signal(false);
  submitting = signal(false);
  error = signal<string | null>(null);
  selectedFiles: File[] = [];
  incidentStatuses = Object.values(IncidentStatus);

  // Dropdown data
  drivers$: Observable<Driver[]>;
  vehicles$: Observable<Vehicle[]>;
  driversLoading = signal(false);
  vehiclesLoading = signal(false);

  // ============================================================================
  // Lifecycle Hooks
  // ============================================================================

  constructor() {
    this.incidentForm = this.fb.group({
      title: ['', [Validators.required, Validators.maxLength(255)]],
      description: ['', Validators.required],
      incidentGroup: ['', Validators.required],
      severity: ['', Validators.required],
      incidentType: ['', Validators.required],
      location: [''],
      driverId: [null],
      vehicleId: [null],
      incidentStatus: [IncidentStatus.NEW, Validators.required],
    });

    // Load drivers and vehicles
    this.driversLoading.set(true);
    this.drivers$ = this.driverService.getDrivers(0, 100).pipe(
      map((response) => response.data?.content || []),
      catchError((err) => {
        console.error('Error loading drivers:', err);
        this.driversLoading.set(false);
        return of([]);
      }),
      map((drivers) => {
        this.driversLoading.set(false);
        return drivers;
      }),
    );

    this.vehiclesLoading.set(true);
    this.vehicles$ = this.vehicleService.getVehicles(0, 100, {}).pipe(
      map((response) => response.data?.content || []),
      catchError((err) => {
        console.error('Error loading vehicles:', err);
        this.vehiclesLoading.set(false);
        return of([]);
      }),
      map((vehicles) => {
        this.vehiclesLoading.set(false);
        return vehicles;
      }),
    );
  }

  /**
   * Initialize component and check for edit mode
   */
  ngOnInit() {
    const id = this.route.snapshot.paramMap.get('id');
    if (id) {
      this.incidentId.set(+id);
      this.isEditMode.set(true);
      this.loadIncident(+id);
    }
  }

  // ============================================================================
  // Public Methods
  // ============================================================================

  /**
   * Navigate back to incidents list
   */
  goBack() {
    this.router.navigate(['/incidents']);
  }

  /**
   * Load incident data for editing
   * @param id Incident ID to load
   */
  loadIncident(id: number) {
    this.incidentService.getIncident(id).subscribe({
      next: (response) => {
        const incident = response.data;
        this.incidentForm.patchValue({
          title: incident.title,
          description: incident.description,
          incidentGroup: incident.incidentGroup,
          severity: incident.severity,
          incidentType: incident.incidentType,
          location: incident.location,
          driverId: incident.driverId,
          vehicleId: incident.vehicleId,
          incidentStatus: incident.incidentStatus ?? IncidentStatus.NEW,
        });
      },
      error: (err) => {
        this.error.set('Failed to load incident data');
        console.error('Error loading incident:', err);
      },
    });
  }

  /**
   * Handle file selection for attachments
   * @param event File input change event
   */
  onFileSelect(event: Event) {
    const input = event.target as HTMLInputElement;
    if (input.files) {
      this.selectedFiles = Array.from(input.files);
    }
  }

  /**
   * Submit incident form (create or update)
   */
  onSubmit() {
    if (this.incidentForm.invalid) {
      this.incidentForm.markAllAsTouched();
      return;
    }

    this.submitting.set(true);
    this.error.set(null);

    const formValue = this.incidentForm.value;

    // Map form data to backend DTO
    const incidentData: any = {
      title: formValue.title,
      description: formValue.description,
      incidentGroup: formValue.incidentGroup,
      severity: formValue.severity,
      incidentType: formValue.incidentType,
      locationText: formValue.location, // Map location to locationText
      driverId: formValue.driverId,
      vehicleId: formValue.vehicleId,
      incidentStatus: formValue.incidentStatus,
    };

    const request = this.isEditMode()
      ? this.incidentService.updateIncident(this.incidentId()!, incidentData)
      : this.incidentService.createIncident(incidentData);

    request.pipe(finalize(() => this.submitting.set(false))).subscribe({
      next: (response) => {
        const incidentId = response.data.id!;

        // Upload files if any
        if (this.selectedFiles.length > 0) {
          this.incidentService.uploadPhotos(incidentId, this.selectedFiles).subscribe({
            next: (uploadResponse) => {
              console.log('Photos uploaded successfully:', uploadResponse);
              this.router.navigate(['/incidents', incidentId]);
            },
            error: (uploadErr) => {
              console.error('Failed to upload photos:', uploadErr);
              // Still navigate even if upload fails
              this.router.navigate(['/incidents', incidentId]);
            },
          });
        } else {
          this.router.navigate(['/incidents', incidentId]);
        }
      },
      error: (err) => {
        this.error.set(
          this.isEditMode() ? 'Failed to update incident' : 'Failed to create incident',
        );
        console.error('Error submitting incident:', err);
      },
    });
  }
}
