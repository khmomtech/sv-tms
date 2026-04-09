import { CommonModule } from '@angular/common';
import { Component, computed, inject, type OnDestroy, type OnInit, signal } from '@angular/core';
import {
  FormBuilder,
  FormControl,
  FormsModule,
  ReactiveFormsModule,
  type AbstractControl,
  type FormGroup,
  type ValidationErrors,
  Validators,
} from '@angular/forms';
import { ActivatedRoute, Router, RouterLink } from '@angular/router';
import { ToastrService } from 'ngx-toastr';
import { debounceTime, Subject, takeUntil } from 'rxjs';

import type { Incident } from '../../models/incident.model';
import { CaseCategory, IssueSeverity } from '../../models/incident.model';
import { CaseService } from '../../services/case.service';
import { IncidentService } from '../../services/incident.service';

/**
 * Form model interface for type-safe form controls
 */
interface CaseFormModel {
  title: FormControl<string | null>;
  description: FormControl<string | null>;
  category: FormControl<string | null>;
  severity: FormControl<string | null>;
  assignedToUserId: FormControl<number | null>;
  slaTargetDate: FormControl<string | null>;
}

/**
 * Case Form Component
 *
 * Handles case creation and editing with incident escalation.
 * Supports linking incidents to cases for investigation tracking.
 */
@Component({
  selector: 'app-case-form',
  standalone: true,
  imports: [CommonModule, FormsModule, ReactiveFormsModule, RouterLink],
  templateUrl: './case-form.component.html',
  styleUrls: ['./case-form.component.css'],
})
export class CaseFormComponent implements OnInit, OnDestroy {
  // ============================================================
  // Dependency Injection
  // ============================================================
  private readonly caseService = inject(CaseService);
  private readonly incidentService = inject(IncidentService);
  private readonly router = inject(Router);
  private readonly route = inject(ActivatedRoute);
  private readonly fb = inject(FormBuilder);
  private readonly toastr = inject(ToastrService);

  // ============================================================
  // State Management (Signals)
  // ============================================================
  caseForm!: FormGroup<CaseFormModel>;
  caseId = signal<number | null>(null);
  linkedIncidentId = signal<number | null>(null);
  linkedIncident = signal<Incident | null>(null);
  loadingIncident = signal(false);
  loading = signal(false);
  isEditMode = signal(false);
  submitting = signal(false);
  error = signal<string | null>(null);

  // RxJS cleanup
  private destroy$ = new Subject<void>();

  // Expose enums to template
  readonly CaseCategory = CaseCategory;
  readonly IssueSeverity = IssueSeverity;

  // Computed properties for better UX
  canSubmit = computed(() => !this.submitting() && !this.loading() && this.caseForm?.valid);
  formDirty = computed(() => this.caseForm?.dirty || false);
  formTouched = computed(() => this.caseForm?.touched || false);
  hasValidationErrors = computed(() => this.caseForm?.invalid && this.formTouched());
  submitDisabledReason = computed(() => {
    if (this.submitting()) return 'Submitting...';
    if (this.loading()) return 'Loading...';
    if (!this.caseForm) return 'Form not initialized';
    if (this.caseForm.valid) return '';

    if (this.hasFieldError('title', 'required')) return 'Title is required';
    if (this.hasFieldError('category', 'required')) return 'Category is required';
    if (this.hasFieldError('severity', 'required')) return 'Severity is required';
    if (this.hasFieldError('description', 'required')) return 'Description is required';
    if (this.hasFieldError('slaTargetDate', 'pastDate'))
      return 'SLA Target Date must be in the future';
    if (this.hasFieldError('slaTargetDate', 'invalidDate'))
      return 'SLA Target Date format is invalid';

    return 'Please complete required fields';
  });

  // ============================================================
  // Configuration Data
  // ============================================================
  categoryOptions = [
    { value: 'SAFETY', label: 'Safety' },
    { value: 'CUSTOMER_ESCALATION', label: 'Customer Escalation' },
    { value: 'HR_BEHAVIOR', label: 'HR / Behavior' },
    { value: 'ACCIDENT', label: 'Accident' },
  ];

  severityOptions = [
    { value: 'LOW', label: 'Low' },
    { value: 'MEDIUM', label: 'Medium' },
    { value: 'HIGH', label: 'High' },
    { value: 'CRITICAL', label: 'Critical' },
  ];

  // ============================================================
  // Constructor & Initialization
  // ============================================================
  constructor() {
    this.initForm();
  }

  /**
   * Initialize form with validators
   */
  private initForm(): void {
    this.caseForm = this.fb.group({
      title: new FormControl<string | null>('', [Validators.required, Validators.maxLength(255)]),
      description: new FormControl<string | null>('', [
        Validators.required,
        Validators.maxLength(2000),
      ]),
      category: new FormControl<string | null>('', Validators.required),
      severity: new FormControl<string | null>('', Validators.required),
      assignedToUserId: new FormControl<number | null>(null),
      slaTargetDate: new FormControl<string | null>('', this.futureDateValidator),
    });

    // Track form changes for unsaved changes warning
    this.caseForm.valueChanges.pipe(debounceTime(300), takeUntil(this.destroy$)).subscribe(() => {
      // Form state is tracked via computed signals
    });
  }

  /**
   * Custom validator for future dates
   */
  private futureDateValidator(control: AbstractControl): ValidationErrors | null {
    if (!control.value) return null;
    const selectedDate = new Date(control.value);
    if (Number.isNaN(selectedDate.getTime())) {
      return { invalidDate: true };
    }
    const now = new Date();
    return selectedDate > now ? null : { pastDate: true };
  }

  /**
   * Initialize component data on load
   */
  ngOnInit(): void {
    const id = this.route.snapshot.paramMap.get('id');
    const incidentId = this.route.snapshot.queryParamMap.get('incidentId');

    if (id) {
      this.caseId.set(+id);
      this.isEditMode.set(true);
      this.loadCase(+id);
    }

    if (incidentId) {
      this.linkedIncidentId.set(+incidentId);
      this.loadIncident(+incidentId);
    }
  }

  /**
   * Cleanup on component destroy
   */
  ngOnDestroy(): void {
    this.destroy$.next();
    this.destroy$.complete();
  }

  // ============================================================
  // Form Control Getters (Type-safe access)
  // ============================================================
  get titleControl(): FormControl<string | null> {
    return this.caseForm.get('title') as FormControl<string | null>;
  }

  get descriptionControl(): FormControl<string | null> {
    return this.caseForm.get('description') as FormControl<string | null>;
  }

  get categoryControl(): FormControl<string | null> {
    return this.caseForm.get('category') as FormControl<string | null>;
  }

  get severityControl(): FormControl<string | null> {
    return this.caseForm.get('severity') as FormControl<string | null>;
  }

  get slaTargetDateControl(): FormControl<string | null> {
    return this.caseForm.get('slaTargetDate') as FormControl<string | null>;
  }

  // ============================================================
  // Validation Helper Methods
  // ============================================================
  /**
   * Check if a form field has a specific error
   */
  hasFieldError(fieldName: string, errorType: string): boolean {
    const control = this.caseForm.get(fieldName);
    return !!(control && control.hasError(errorType) && (control.dirty || control.touched));
  }

  /**
   * Check if a form field is valid and touched
   */
  isFieldValid(fieldName: string): boolean {
    const control = this.caseForm.get(fieldName);
    return !!(control && control.valid && (control.dirty || control.touched));
  }

  /**
   * Get error message for a field
   */
  getFieldError(fieldName: string): string {
    const control = this.caseForm.get(fieldName);
    if (!control || !control.errors || (!control.dirty && !control.touched)) {
      return '';
    }

    if (control.hasError('required')) return 'This field is required';
    if (control.hasError('maxlength')) {
      const maxLength = control.errors['maxlength'].requiredLength;
      return `Maximum ${maxLength} characters allowed`;
    }
    if (control.hasError('pastDate')) return 'Date must be in the future';
    if (control.hasError('invalidDate')) return 'Invalid date format';
    return 'Invalid value';
  }

  /**
   * Get character count for a field
   */
  getCharacterCount(fieldName: string): number {
    const control = this.caseForm.get(fieldName);
    return control?.value?.length || 0;
  }

  /**
   * Mark all fields as touched for validation
   */
  private markAllFieldsAsTouched(): void {
    Object.keys(this.caseForm.controls).forEach((key) => {
      this.caseForm.get(key)?.markAsTouched();
    });
  }

  /**
   * Scroll to first error in form
   */
  private scrollToFirstError(): void {
    setTimeout(() => {
      const firstError = document.querySelector('.is-invalid');
      firstError?.scrollIntoView({ behavior: 'smooth', block: 'center' });
    }, 100);
  }

  // ============================================================
  // Data Loading Methods
  // ============================================================
  /**
   * Load incident details for linking
   * @param id Incident ID
   */
  loadIncident(id: number): void {
    this.loadingIncident.set(true);
    this.incidentService
      .getIncident(id)
      .pipe(takeUntil(this.destroy$))
      .subscribe({
        next: (response) => {
          this.linkedIncident.set(response.data);
          this.prefillFromIncident(response.data);
          this.loadingIncident.set(false);
        },
        error: (err) => {
          const message = 'Failed to load incident details';
          this.error.set(message);
          this.toastr.error(message, 'Error');
          this.loadingIncident.set(false);
          console.error('Error loading incident:', err);
        },
      });
  }

  /**
   * Load case details for editing
   * @param id Case ID
   */
  loadCase(id: number): void {
    this.loading.set(true);
    this.caseService
      .getCase(id)
      .pipe(takeUntil(this.destroy$))
      .subscribe({
        next: (response) => {
          const caseData = response.data;
          this.caseForm.patchValue({
            title: caseData.title,
            description: caseData.description,
            category: caseData.category,
            severity: caseData.severity,
            assignedToUserId: caseData.assignedToUserId,
          });
          this.loading.set(false);
        },
        error: (err) => {
          const message = 'Failed to load case details';
          this.error.set(message);
          this.toastr.error(message, 'Error');
          this.loading.set(false);
          console.error('Error loading case:', err);
        },
      });
  }

  /**
   * Pre-fill form from incident data
   * @param incident Incident to prefill from
   */
  prefillFromIncident(incident: Incident) {
    const categoryMap: Record<string, string> = {
      CUSTOMER: 'CUSTOMER_ESCALATION',
      TRAFFIC: 'SAFETY',
      BEHAVIOR: 'HR_BEHAVIOR',
      ACCIDENT: 'ACCIDENT',
      VEHICLE: 'SAFETY',
    };

    this.caseForm.patchValue({
      title: `${incident.title}`,
      description: `Escalated from Incident ${incident.code}:\n\n${incident.description}`,
      severity: incident.severity,
      category: categoryMap[incident.incidentGroup] || 'SAFETY',
    });
  }

  // ============================================================
  // Form Submission
  // ============================================================
  /**
   * Submit case form (create or update)
   */
  onSubmit(): void {
    if (this.caseForm.invalid) {
      this.markAllFieldsAsTouched();
      this.toastr.warning('Please fill in all required fields correctly', 'Validation Error');
      this.scrollToFirstError();
      return;
    }

    if (this.submitting()) {
      return; // Prevent double submission
    }

    this.submitting.set(true);
    this.error.set(null);

    const formValue = this.caseForm.value;

    // Ensure required fields are not null/undefined
    if (!formValue.title || !formValue.category || !formValue.severity || !formValue.description) {
      this.toastr.error('Required fields are missing', 'Validation Error');
      this.submitting.set(false);
      return;
    }

    const payload: any = {
      title: formValue.title.trim(),
      description: formValue.description.trim(),
      category: formValue.category,
      severity: formValue.severity,
      assignedToUserId: formValue.assignedToUserId ? +formValue.assignedToUserId : null,
    };

    if (formValue.slaTargetDate) {
      payload.slaTargetAt = formValue.slaTargetDate;
    }

    if (this.linkedIncidentId()) {
      payload.incidentIds = [this.linkedIncidentId()];
    }

    const request = this.isEditMode()
      ? this.caseService.updateCase(this.caseId()!, payload)
      : this.caseService.createCase(payload);

    request.pipe(takeUntil(this.destroy$)).subscribe({
      next: (response) => {
        if (response.success) {
          const action = this.isEditMode() ? 'updated' : 'created';
          this.toastr.success(`Case "${payload.title}" ${action} successfully`, 'Success');
          this.router.navigate(['/cases', response.data.id]);
        } else {
          this.toastr.error('Operation failed', 'Error');
          this.submitting.set(false);
        }
      },
      error: (err) => {
        const action = this.isEditMode() ? 'update' : 'create';
        const message =
          err?.status === 403
            ? `You do not have permission to ${action} cases`
            : `Failed to ${action} case. Please try again.`;
        this.error.set(message);
        this.toastr.error(message, 'Error');
        this.submitting.set(false);
        console.error(`Error ${action}ing case:`, err);
      },
    });
  }

  // ============================================================
  // Navigation Methods
  // ============================================================
  /**
   * Navigate back to appropriate page
   */
  goBack() {
    if (this.isEditMode()) {
      this.router.navigate(['/cases', this.caseId()]);
    } else {
      this.router.navigate(['/cases']);
    }
  }

  // ============================================================
  // UI Helper Methods
  // ============================================================
  /**
   * Format driver ID for display
   * @param driverId Driver ID
   * @returns Formatted driver ID
   */
  formatDriverId(driverId: number | null | undefined): string {
    if (driverId == null) return 'N/A';
    return 'DRV-' + driverId.toString().padStart(4, '0');
  }
}
