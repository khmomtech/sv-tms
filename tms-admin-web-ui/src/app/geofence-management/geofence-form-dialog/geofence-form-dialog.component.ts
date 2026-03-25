import { Component, inject } from '@angular/core';
import type { OnInit, OnDestroy } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormBuilder, Validators, ReactiveFormsModule } from '@angular/forms';
import type { FormGroup } from '@angular/forms';
import { MAT_DIALOG_DATA, MatDialogModule, MatDialogRef } from '@angular/material/dialog';
import { Subject } from 'rxjs';
import { takeUntil } from 'rxjs/operators';

import {
  AlertTypeEnum,
  GeofenceType,
  type Geofence,
  type GeofenceCreateRequest,
} from '../../models/geofence.model';
import {
  latitudeValidator,
  longitudeValidator,
  radiusValidator,
  geoJsonValidator,
  speedLimitValidator,
} from '../geofence-validators';

export interface GeofenceFormDialogData {
  geofence?: Geofence;
  type?: GeofenceType;
  centerLat?: number;
  centerLng?: number;
  radiusMeters?: number;
  coordinates?: [number, number][];
  companyId: number;
}

@Component({
  selector: 'app-geofence-form-dialog',
  standalone: true,
  imports: [CommonModule, ReactiveFormsModule, MatDialogModule],
  templateUrl: './geofence-form-dialog.component.html',
  styleUrls: ['./geofence-form-dialog.component.css'],
})
export class GeofenceFormDialogComponent implements OnInit, OnDestroy {
  private readonly dialogRef = inject(MatDialogRef<GeofenceFormDialogComponent>);
  private readonly fb = inject(FormBuilder);
  public readonly data = inject<GeofenceFormDialogData>(MAT_DIALOG_DATA);

  form!: FormGroup;
  editMode = false;
  saving = false;

  GeofenceType = GeofenceType;

  readonly alertTypeOptions: Array<{ value: AlertTypeEnum; label: string; icon: string }> = [
    { value: AlertTypeEnum.ENTER, label: 'Entry', icon: 'login' },
    { value: AlertTypeEnum.EXIT, label: 'Exit', icon: 'logout' },
    { value: AlertTypeEnum.BOTH, label: 'Both', icon: 'swap_horiz' },
    { value: AlertTypeEnum.NONE, label: 'None', icon: 'notifications_off' },
  ];

  private destroy$ = new Subject<void>();

  ngOnInit(): void {
    this.editMode = !!this.data.geofence;
    this.buildForm();
    this.setupTypeChangeListener();
  }

  ngOnDestroy(): void {
    this.destroy$.next();
    this.destroy$.complete();
  }

  private buildForm(): void {
    const geofence = this.data.geofence;

    // Join existing tags array into comma-separated string for the text field
    const tagsString = geofence?.tags ? geofence.tags.join(', ') : '';

    this.form = this.fb.group({
      name: [geofence?.name || '', [Validators.required, Validators.maxLength(100)]],
      description: [geofence?.description || '', [Validators.maxLength(500)]],
      type: [geofence?.type || this.data.type || GeofenceType.CIRCLE, [Validators.required]],
      centerLatitude: [
        geofence?.centerLatitude ?? this.data.centerLat ?? null,
        [latitudeValidator()],
      ],
      centerLongitude: [
        geofence?.centerLongitude ?? this.data.centerLng ?? null,
        [longitudeValidator()],
      ],
      radiusMeters: [geofence?.radiusMeters ?? this.data.radiusMeters ?? 500, [radiusValidator()]],
      geoJsonCoordinates: [
        geofence?.geoJsonCoordinates || this.formatCoordinates(this.data.coordinates),
        [geoJsonValidator()],
      ],
      alertType: [geofence?.alertType || AlertTypeEnum.BOTH, [Validators.required]],
      speedLimitKmh: [geofence?.speedLimitKmh || null, [speedLimitValidator()]],
      active: [geofence?.active ?? true],
      tags: [tagsString, [Validators.maxLength(200)]],
    });

    // Set initial validators based on type
    this.updateValidators(this.form.get('type')?.value);
  }

  private setupTypeChangeListener(): void {
    this.form
      .get('type')
      ?.valueChanges.pipe(takeUntil(this.destroy$))
      .subscribe((type) => {
        this.updateValidators(type);
      });
  }

  private updateValidators(type: GeofenceType): void {
    const centerLat = this.form.get('centerLatitude');
    const centerLng = this.form.get('centerLongitude');
    const radius = this.form.get('radiusMeters');
    const geoJson = this.form.get('geoJsonCoordinates');

    if (type === GeofenceType.CIRCLE) {
      // Circle requires center and radius
      centerLat?.setValidators([Validators.required, latitudeValidator()]);
      centerLng?.setValidators([Validators.required, longitudeValidator()]);
      radius?.setValidators([Validators.required, radiusValidator()]);
      geoJson?.clearValidators();
    } else {
      // Polygon requires GeoJSON coordinates
      centerLat?.clearValidators();
      centerLng?.clearValidators();
      radius?.clearValidators();
      geoJson?.setValidators([Validators.required, geoJsonValidator()]);
    }

    centerLat?.updateValueAndValidity();
    centerLng?.updateValueAndValidity();
    radius?.updateValueAndValidity();
    geoJson?.updateValueAndValidity();
  }

  private formatCoordinates(coords?: [number, number][]): string {
    if (!coords || coords.length === 0) return '';
    return JSON.stringify(coords, null, 2);
  }

  getErrorMessage(fieldName: string): string {
    const control = this.form.get(fieldName);
    if (!control || !control.errors) return '';

    const errors = control.errors;

    if (errors['required']) return 'This field is required';
    if (errors['maxlength'])
      return `Maximum ${errors['maxlength'].requiredLength} characters allowed`;
    if (errors['invalidNumber']) return 'Must be a valid number';
    if (errors['latitudeRange']) return `Latitude must be between -90 and 90`;
    if (errors['longitudeRange']) return `Longitude must be between -180 and 180`;
    if (errors['radiusRange']) return `Radius must be between 50m and 50,000m (50km)`;
    if (errors['speedLimitRange']) return `Speed limit must be between 0 and 200 km/h`;
    if (errors['invalidGeoJson'])
      return errors['invalidGeoJson'].message || 'Invalid GeoJSON format';

    return 'Invalid value';
  }

  onCancel(): void {
    this.dialogRef.close();
  }

  onSave(): void {
    if (this.form.invalid) {
      Object.keys(this.form.controls).forEach((key) => {
        this.form.get(key)?.markAsTouched();
      });
      return;
    }

    const formValue = this.form.value;

    // Parse comma-separated tags string into trimmed array (filtering empty entries)
    const tags: string[] = formValue.tags
      ? formValue.tags
          .split(',')
          .map((t: string) => t.trim())
          .filter((t: string) => t.length > 0)
      : [];

    const request: GeofenceCreateRequest = {
      partnerCompanyId: this.data.companyId,
      name: formValue.name,
      description: formValue.description,
      type: formValue.type,
      alertType: formValue.alertType,
      speedLimitKmh: formValue.speedLimitKmh || undefined,
      active: formValue.active,
      centerLatitude: formValue.type === GeofenceType.CIRCLE ? formValue.centerLatitude : undefined,
      centerLongitude:
        formValue.type === GeofenceType.CIRCLE ? formValue.centerLongitude : undefined,
      radiusMeters: formValue.type === GeofenceType.CIRCLE ? formValue.radiusMeters : undefined,
      geoJsonCoordinates:
        formValue.type === GeofenceType.POLYGON ? formValue.geoJsonCoordinates : undefined,
      tags: tags.length > 0 ? tags : undefined,
    };

    this.dialogRef.close(request);
  }

  get isCircleType(): boolean {
    return this.form.get('type')?.value === GeofenceType.CIRCLE;
  }

  get isPolygonType(): boolean {
    return this.form.get('type')?.value === GeofenceType.POLYGON;
  }
}
