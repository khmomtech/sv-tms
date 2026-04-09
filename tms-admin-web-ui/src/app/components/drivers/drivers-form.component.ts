/* eslint-disable @typescript-eslint/consistent-type-imports */
import { FocusTrap, FocusTrapFactory } from '@angular/cdk/a11y';
import { CommonModule } from '@angular/common';
import {
  Component,
  EventEmitter,
  HostListener,
  Input,
  OnChanges,
  OnInit,
  Output,
  SimpleChanges,
  AfterViewInit,
  OnDestroy,
  ViewChild,
  ElementRef,
} from '@angular/core';
import {
  FormsModule,
  ReactiveFormsModule,
  FormBuilder,
  FormGroup,
  Validators,
} from '@angular/forms';
import { MatButtonModule } from '@angular/material/button';
import { MatFormFieldModule } from '@angular/material/form-field';
import { MatIconModule } from '@angular/material/icon';
import { MatInputModule } from '@angular/material/input';
import { MatProgressSpinnerModule } from '@angular/material/progress-spinner';

import type { Driver } from '../../models/driver.model';
import { DriverFormValidators } from '../../services/driver-form-validators';

@Component({
  selector: 'app-drivers-form',
  standalone: true,
  templateUrl: './drivers-form.component.html',
  imports: [
    CommonModule,
    FormsModule,
    ReactiveFormsModule,
    MatFormFieldModule,
    MatInputModule,
    MatIconModule,
    MatButtonModule,
    MatProgressSpinnerModule,
  ],
})
export class DriversFormComponent implements OnInit, OnChanges, OnDestroy {
  readonly allowedProfileImageExtensions = ['.jpeg', '.jpg', '.png', '.webp'];
  @Input() driver: Driver | null = null;
  @Input() isOpen = false;
  /** When true, render the form as a full page instead of a modal overlay */
  @Input() displayAsPage = false;
  @Input() isEditing = false;
  @Input() isSaving = false;
  @Output() save = new EventEmitter<Driver>();
  @Output() cancel = new EventEmitter<void>();

  // Template expects `driverForm` and `isModalOpen` / `isSubmitting` names
  driverForm!: FormGroup;
  formErrors: Record<string, string> = {};
  saveSuccess = '';
  isSubmitting = false;
  // Profile photo upload
  profilePreview: string | null = null;
  profileFile: File | null = null;
  dragging = false;
  fileError = '';
  readonly maxFileSize = 5 * 1024 * 1024; // 5MB
  // expose global Object to template (used for Object.values)
  Object = Object;
  @ViewChild('modalRoot', { static: false }) modalRoot?: ElementRef<HTMLElement>;
  private focusTrap: FocusTrap | null = null;

  ngOnInit(): void {
    this.buildForm();
  }

  ngOnDestroy(): void {
    this.releaseFocusTrap();
  }

  ngOnChanges(changes: SimpleChanges): void {
    if (changes['driver'] && this.form) {
      this.patchForm(this.driver);
    }
    if (changes['isOpen']) {
      // only treat as modal when not rendering as a page
      if (!this.displayAsPage) {
        if (this.isOpen) {
          // prevent background scroll
          try {
            document.body.style.overflow = 'hidden';
          } catch (e) {}
          // create focus trap when modal opens
          setTimeout(() => this.focusModal(), 50);
        } else {
          try {
            document.body.style.overflow = '';
          } catch (e) {}
          this.releaseFocusTrap();
        }
      }
    }
    if (changes['isSaving']) {
      // reflect saving state in local flag used by template
      this.isSubmitting = !!this.isSaving;
    }
  }

  constructor(
    private readonly fb: FormBuilder,
    private readonly focusTrapFactory: FocusTrapFactory,
  ) {}

  private buildForm(): void {
    this.driverForm = this.fb.group({
      firstName: ['', Validators.required],
      lastName: ['', Validators.required],
      email: [''],
      countryCode: ['KH'],
      phone: ['', Validators.required],
      emergencyPhone: [''],
      address: [''],
      licenseExpiryDate: [''],
      licenseClass: [''],
      dateOfBirth: [''],
      rating: [5],
      isActive: [true],
      zone: [''],
      notes: [''],
    });

    this.patchForm(this.driver);
  }

  private patchForm(driver: Driver | null): void {
    if (!driver) {
      this.driverForm.reset({ rating: 5, isActive: true, countryCode: 'KH' });
      return;
    }

    this.driverForm.patchValue({
      firstName: driver.firstName || '',
      lastName: driver.lastName || '',
      email: (driver as any).email || '',
      countryCode: (driver as any).countryCode || 'KH',
      phone: driver.phone || '',
      emergencyPhone: (driver as any).emergencyPhone || '',
      address: (driver as any).address || '',
      licenseExpiryDate: (driver as any).licenseExpiryDate || '',
      licenseClass: (driver as any).licenseClass || '',
      dateOfBirth:
        (driver as any).dateOfBirth ?? (driver as any).individualDetails?.dateOfBirth ?? '',
      rating: driver.rating ?? 5,
      isActive: driver.isActive ?? true,
      zone: driver.zone || '',
      notes: (driver as any).notes || '',
    });
  }

  validateForm(): boolean {
    this.formErrors = {};
    const v = this.form.value;

    const firstNameResult = DriverFormValidators.validateFirstName(v.firstName || '');
    if (!firstNameResult.isValid)
      this.formErrors['firstName'] = firstNameResult.message || 'Invalid first name';

    const lastNameResult = DriverFormValidators.validateLastName(v.lastName || '');
    if (!lastNameResult.isValid)
      this.formErrors['lastName'] = lastNameResult.message || 'Invalid last name';

    const phoneResult = DriverFormValidators.validatePhone(v.phone || '', v.countryCode || 'KH');
    if (!phoneResult.isValid) this.formErrors['phone'] = phoneResult.message || 'Invalid phone';

    const emailResult = DriverFormValidators.validateEmail(v.email || '');
    if (!emailResult.isValid) this.formErrors['email'] = emailResult.message || '';

    // Phone is required but format validation is not enforced here

    return Object.keys(this.formErrors).length === 0;
  }

  submit(): void {
    if (this.isSaving) return;
    if (!this.validateForm()) return;

    const payload: any = { ...(this.driver || {}), ...this.form.value };
    if (this.profileFile) payload.profileFile = this.profileFile;
    this.save.emit(payload as Driver);
  }

  onFileSelected(event: Event): void {
    const input = event.target as HTMLInputElement;
    this.onFileFromList(input.files || null);
  }

  onDrop(event: DragEvent): void {
    event.preventDefault();
    this.dragging = false;
    this.onFileFromList(event.dataTransfer ? event.dataTransfer.files : null);
  }

  onDragOver(event: DragEvent): void {
    event.preventDefault();
    this.dragging = true;
    if (event.dataTransfer) event.dataTransfer.dropEffect = 'copy';
  }

  onDragLeave(_event: DragEvent): void {
    this.dragging = false;
  }

  private onFileFromList(files: FileList | null): void {
    this.fileError = '';
    if (!files || files.length === 0) return;
    const file = files[0];
    const lowerName = (file.name || '').toLowerCase();
    const hasAllowedExtension = this.allowedProfileImageExtensions.some((ext) =>
      lowerName.endsWith(ext),
    );
    if (!file.type.startsWith('image/') || !hasAllowedExtension) {
      this.fileError = 'Invalid file type. Allowed: JPEG, JPG, PNG, WEBP.';
      return;
    }
    if (file.size > this.maxFileSize) {
      this.fileError = 'File is too large. Maximum 5MB.';
      return;
    }
    this.profileFile = file;
    try {
      if (this.profilePreview) URL.revokeObjectURL(this.profilePreview);
    } catch (e) {}
    this.profilePreview = URL.createObjectURL(file);
  }

  removeProfile(): void {
    try {
      if (this.profilePreview) URL.revokeObjectURL(this.profilePreview);
    } catch (e) {}
    this.profilePreview = null;
    this.profileFile = null;
    this.fileError = '';
  }

  // Aliases and template-compatible methods
  get isModalOpen(): boolean {
    return this.isOpen || this.displayAsPage;
  }

  get selectedDriver(): Driver | null {
    return this.driver;
  }

  // driverForm aliases for template
  get form(): FormGroup {
    return this.driverForm;
  }

  onSubmit(): void {
    // Mark all controls as touched to show validation errors
    try {
      this.form.markAllAsTouched();
    } catch (e) {}
    this.isSubmitting = true;
    this.submit();
  }

  closeModal(): void {
    // reset local state and form
    try {
      this.driverForm.reset({ rating: 5, isActive: true, countryCode: 'KH' });
    } catch (e) {}
    this.isSubmitting = false;
    this.onCancel();
  }

  @HostListener('document:keydown.escape', ['$event'])
  // Accept both generic Event and KeyboardEvent to satisfy template/host-listener typing
  handleEscape(event: Event | KeyboardEvent): void {
    // Only handle escape for modal mode (not when rendered as a full page)
    if (this.displayAsPage) return;
    const k = event as KeyboardEvent;
    if (this.isModalOpen) {
      try {
        k.preventDefault();
      } catch (e) {}
      this.closeModal();
    }
  }

  private focusModal(): void {
    try {
      if (this.modalRoot && this.modalRoot.nativeElement) {
        // create focus trap
        this.focusTrap = this.focusTrapFactory.create(this.modalRoot.nativeElement);
        this.focusTrap.focusInitialElementWhenReady();
        // attempt to focus first input if present
        const first = this.modalRoot.nativeElement.querySelector(
          'input,button,select,textarea',
        ) as HTMLElement | null;
        if (first) first.focus();
      }
    } catch (e) {
      // noop
    }
  }

  private releaseFocusTrap(): void {
    try {
      if (this.focusTrap) {
        this.focusTrap.destroy();
        this.focusTrap = null;
      }
    } catch (e) {
      // noop
    }
  }

  hasFieldError(field: string): boolean {
    return !!this.formErrors[field];
  }

  getFieldError(field: string): string {
    return this.formErrors[field] || '';
  }

  validateSingleField(field: string): void {
    // reuse validateForm for the specific field by running validators
    // This component uses DriverFormValidators similarly to parent
    const v = this.form.value;
    switch (field) {
      case 'firstName':
        const firstNameResult = DriverFormValidators.validateFirstName(v.firstName || '');
        if (!firstNameResult.isValid)
          this.formErrors['firstName'] = firstNameResult.message || 'Invalid first name';
        else delete this.formErrors['firstName'];
        break;
      case 'lastName':
        const lastNameResult = DriverFormValidators.validateLastName(v.lastName || '');
        if (!lastNameResult.isValid)
          this.formErrors['lastName'] = lastNameResult.message || 'Invalid last name';
        else delete this.formErrors['lastName'];
        break;
      case 'phone':
        const phoneResult = DriverFormValidators.validatePhone(
          v.phone || '',
          v.countryCode || 'KH',
        );
        if (!phoneResult.isValid) this.formErrors['phone'] = phoneResult.message || 'Invalid phone';
        else delete this.formErrors['phone'];
        break;
      case 'email':
        const emailResult = DriverFormValidators.validateEmail(v.email || '');
        if (!emailResult.isValid) this.formErrors['email'] = emailResult.message || '';
        else delete this.formErrors['email'];
        break;
      // licenseNumber removed: no per-field validation
      default:
        break;
    }
  }

  hasFieldWarning(_field: string): boolean {
    return false;
  }

  getFieldWarning(_field: string): string {
    return '';
  }

  getFieldValue(field: string): any {
    try {
      return this.driverForm?.get(field)?.value;
    } catch (e) {
      return null;
    }
  }

  // Safe getters/setters for template to avoid null issues
  getSelectedRating(): number {
    return this.driver?.rating ?? this.driverForm?.get('rating')?.value ?? 0;
  }

  getStars(): string {
    const r = Math.max(0, Math.floor(this.getSelectedRating()));
    return '★'.repeat(r);
  }

  setRating(i: number): void {
    if (this.driver) {
      this.driver.rating = i;
    }
    try {
      this.driverForm?.patchValue({ rating: i });
    } catch (e) {
      // noop
    }
  }

  /**
   * Format phone value on blur and set it back into the FormControl without
   * triggering additional value-change events.
   */
  formatAndSetPhone(field: string): void {
    // No-op: remove automatic formatting to avoid rejecting valid raw inputs.
    // The validator now accepts digit-only and international formats without enforcing a visual mask.
    return;
  }

  /**
   * Lightweight phone formatter. Keeps digits and an optional leading '+',
   * applies a simple grouping pattern. This is forgiving and won't block
   * valid international numbers — it's purely cosmetic on blur.
   */
  private formatPhone(value: string, countryCode: string | undefined): string {
    if (!value) return '';
    const keepPlus = value.trim().startsWith('+');
    const digits = value.replace(/\D/g, '');
    // simple heuristic for common formats
    if (countryCode === 'US' || countryCode === 'SG') {
      // (123) 456-7890
      const p = digits;
      if (p.length <= 3) return (keepPlus ? '+' : '') + p;
      if (p.length <= 6) return (keepPlus ? '+' : '') + `(${p.slice(0, 3)}) ${p.slice(3)}`;
      return (keepPlus ? '+' : '') + `(${p.slice(0, 3)}) ${p.slice(3, 6)}-${p.slice(6, 10)}`;
    }

    if (countryCode === 'KH' || countryCode === 'TH') {
      // Group small blocks: 3-3-4 for readability
      const p = digits;
      if (p.length <= 3) return (keepPlus ? '+' : '') + p;
      if (p.length <= 6) return (keepPlus ? '+' : '') + `${p.slice(0, 3)} ${p.slice(3)}`;
      if (p.length <= 10)
        return (keepPlus ? '+' : '') + `${p.slice(0, 3)} ${p.slice(3, 6)} ${p.slice(6, 10)}`;
      // fallback: group in 3s
      const groups = p.match(/.{1,3}/g);
      const grouped = groups ? groups.join(' ') : p;
      return (keepPlus ? '+' : '') + grouped;
    }

    // Generic grouping in blocks of 3 for longer numbers
    const p = digits;
    if (p.length <= 3) return (keepPlus ? '+' : '') + p;
    const groups = p.match(/.{1,3}/g);
    const grouped = groups ? groups.join(' ') : p;
    return (keepPlus ? '+' : '') + grouped;
  }

  onCancel(): void {
    this.cancel.emit();
  }
}
