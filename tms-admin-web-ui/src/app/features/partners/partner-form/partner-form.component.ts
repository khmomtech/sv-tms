import { CommonModule } from '@angular/common';
import { Component, Inject, inject } from '@angular/core';
import type { FormGroup } from '@angular/forms';
import { FormBuilder, ReactiveFormsModule, Validators } from '@angular/forms';
import { MatButtonModule } from '@angular/material/button';
import { MAT_DIALOG_DATA, MatDialogModule, MatDialogRef } from '@angular/material/dialog';
import { MatFormFieldModule } from '@angular/material/form-field';
import { MatInputModule } from '@angular/material/input';
import { MatSelectModule } from '@angular/material/select';
import { MatSnackBar, MatSnackBarModule } from '@angular/material/snack-bar';

import type { PartnerCompany } from '../../../models/partner.model';
import { PartnershipType, PartnerStatus } from '../../../models/partner.model';
import { VendorService } from '../../../services/vendor.service';

interface DialogData {
  mode: 'create' | 'edit';
  partner?: PartnerCompany;
}

@Component({
  selector: 'app-partner-form',
  standalone: true,
  imports: [
    CommonModule,
    ReactiveFormsModule,
    MatDialogModule,
    MatButtonModule,
    MatFormFieldModule,
    MatInputModule,
    MatSelectModule,
    MatSnackBarModule,
  ],
  template: `
    <h2 mat-dialog-title>{{ data.mode === 'create' ? 'Create Vendor' : 'Edit Vendor' }}</h2>

    <form [formGroup]="form" class="form" (ngSubmit)="onSubmit()">
      <div class="row">
        <mat-form-field appearance="outline">
          <mat-label>Company Name</mat-label>
          <input matInput formControlName="companyName" required />
        </mat-form-field>

        <mat-form-field appearance="outline">
          <mat-label>Business License</mat-label>
          <input matInput formControlName="businessLicense" />
        </mat-form-field>
      </div>

      <div class="row">
        <mat-form-field appearance="outline">
          <mat-label>Contact Person</mat-label>
          <input matInput formControlName="contactPerson" />
        </mat-form-field>

        <mat-form-field appearance="outline">
          <mat-label>Email</mat-label>
          <input matInput formControlName="email" type="email" />
        </mat-form-field>

        <mat-form-field appearance="outline">
          <mat-label>Phone</mat-label>
          <input matInput formControlName="phone" />
        </mat-form-field>
      </div>

      <mat-form-field appearance="outline" class="full">
        <mat-label>Address</mat-label>
        <input matInput formControlName="address" />
      </mat-form-field>

      <div class="row">
        <mat-form-field appearance="outline">
          <mat-label>Partnership Type</mat-label>
          <mat-select formControlName="partnershipType" required>
            <mat-option *ngFor="let t of partnershipTypes" [value]="t">
              {{ t.replace('_', ' ') }}
            </mat-option>
          </mat-select>
        </mat-form-field>

        <mat-form-field appearance="outline">
          <mat-label>Status</mat-label>
          <mat-select formControlName="status">
            <mat-option [value]="PartnerStatus.ACTIVE">ACTIVE</mat-option>
            <mat-option [value]="PartnerStatus.INACTIVE">INACTIVE</mat-option>
          </mat-select>
        </mat-form-field>
      </div>

      <div class="row">
        <mat-form-field appearance="outline">
          <mat-label>Commission Rate (%)</mat-label>
          <input
            matInput
            formControlName="commissionRate"
            type="number"
            min="0"
            max="100"
            step="0.1"
          />
        </mat-form-field>

        <mat-form-field appearance="outline">
          <mat-label>Credit Limit (USD)</mat-label>
          <input matInput formControlName="creditLimit" type="number" min="0" step="1" />
        </mat-form-field>
      </div>

      <div class="actions">
        <button mat-stroked-button type="button" (click)="close()">Cancel</button>
        <button mat-raised-button color="primary" type="submit" [disabled]="form.invalid || saving">
          {{ data.mode === 'create' ? 'Create' : 'Save Changes' }}
        </button>
      </div>
    </form>
  `,
  styles: [
    `
      .form {
        display: flex;
        flex-direction: column;
        gap: 16px;
        padding: 8px 0;
      }
      .row {
        display: grid;
        grid-template-columns: repeat(3, 1fr);
        gap: 16px;
      }
      .full {
        width: 100%;
      }
      .actions {
        display: flex;
        justify-content: flex-end;
        gap: 12px;
        margin-top: 8px;
      }
      @media (max-width: 900px) {
        .row {
          grid-template-columns: 1fr;
        }
      }
    `,
  ],
})
export class PartnerFormComponent {
  private readonly fb = inject(FormBuilder);
  private readonly partnerService = inject(VendorService);
  private readonly snackBar = inject(MatSnackBar);
  private readonly dialogRef = inject(MatDialogRef<PartnerFormComponent>);

  constructor(@Inject(MAT_DIALOG_DATA) public data: DialogData) {}

  saving = false;
  PartnerStatus = PartnerStatus;
  partnershipTypes = Object.values(PartnershipType);

  form: FormGroup = this.fb.group({
    companyName: ['', [Validators.required, Validators.minLength(2)]],
    businessLicense: [''],
    contactPerson: [''],
    email: ['', [Validators.email]],
    phone: [''],
    address: [''],
    partnershipType: [PartnershipType.DRIVER_FLEET, Validators.required],
    status: [PartnerStatus.ACTIVE, Validators.required],
    commissionRate: [null, [Validators.min(0), Validators.max(100)]],
    creditLimit: [null, [Validators.min(0)]],
  });

  ngOnInit(): void {
    if (this.data.mode === 'edit' && this.data.partner) {
      this.form.patchValue(this.data.partner);
    }
  }

  close(): void {
    this.dialogRef.close(false);
  }

  onSubmit(): void {
    if (this.form.invalid) return;

    this.saving = true;
    const payload = this.form.value as PartnerCompany;

    const request$ =
      this.data.mode === 'create' || !this.data.partner?.id
        ? this.partnerService.createPartner(payload)
        : this.partnerService.updatePartner(this.data.partner!.id!, payload);

    request$.subscribe({
      next: () => {
        this.snackBar.open(
          this.data.mode === 'create' ? 'Vendor created' : 'Vendor updated',
          'Close',
          { duration: 3000 },
        );
        this.dialogRef.close(true);
      },
      error: (err) => {
        console.error('Vendor save failed', err);
        this.snackBar.open('Failed to save vendor', 'Close', { duration: 3000 });
        this.saving = false;
      },
    });
  }
}
