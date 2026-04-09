import { CommonModule } from '@angular/common';
import { Component, Input, inject } from '@angular/core';
import { FormBuilder, ReactiveFormsModule, Validators } from '@angular/forms';
import { MatButtonModule } from '@angular/material/button';
import { MatCardModule } from '@angular/material/card';
import { MatCheckboxModule } from '@angular/material/checkbox';
import { MatFormFieldModule } from '@angular/material/form-field';
import { MatIconModule } from '@angular/material/icon';
import { MatInputModule } from '@angular/material/input';
import { MatSnackBar, MatSnackBarModule } from '@angular/material/snack-bar';
import { MatTableModule } from '@angular/material/table';

import type { PartnerAdmin, PartnerAdminPermissions } from '../../../models/partner.model';
import { VendorService } from '../../../services/vendor.service';

@Component({
  selector: 'app-partner-admin',
  standalone: true,
  imports: [
    CommonModule,
    ReactiveFormsModule,
    MatCardModule,
    MatTableModule,
    MatFormFieldModule,
    MatInputModule,
    MatCheckboxModule,
    MatIconModule,
    MatButtonModule,
    MatSnackBarModule,
  ],
  template: `
    <mat-card>
      <mat-card-title>Vendor Admins</mat-card-title>
      <mat-card-content>
        <table mat-table [dataSource]="admins" class="w-100">
          <ng-container matColumnDef="username">
            <th mat-header-cell *matHeaderCellDef>Username</th>
            <td mat-cell *matCellDef="let a">{{ a.user?.username || a.userId }}</td>
          </ng-container>

          <ng-container matColumnDef="email">
            <th mat-header-cell *matHeaderCellDef>Email</th>
            <td mat-cell *matCellDef="let a">{{ a.user?.email || '-' }}</td>
          </ng-container>

          <ng-container matColumnDef="permissions">
            <th mat-header-cell *matHeaderCellDef>Permissions</th>
            <td mat-cell *matCellDef="let a">
              <span class="perm" *ngIf="a.canManageDrivers">Drivers</span>
              <span class="perm" *ngIf="a.canManageCustomers">Customers</span>
              <span class="perm" *ngIf="a.canViewReports">Reports</span>
              <span class="perm" *ngIf="a.canManageSettings">Settings</span>
            </td>
          </ng-container>

          <ng-container matColumnDef="actions">
            <th mat-header-cell *matHeaderCellDef>Actions</th>
            <td mat-cell *matCellDef="let a">
              <button mat-button color="primary" (click)="togglePrimary(a)">
                <mat-icon>star</mat-icon> {{ a.isPrimary ? 'Unset Primary' : 'Set Primary' }}
              </button>
              <button mat-button color="warn" (click)="removeAdmin(a)">
                <mat-icon>delete</mat-icon> Remove
              </button>
            </td>
          </ng-container>

          <tr mat-header-row *matHeaderRowDef="displayedColumns"></tr>
          <tr mat-row *matRowDef="let row; columns: displayedColumns"></tr>
        </table>
      </mat-card-content>
    </mat-card>

    <mat-card style="margin-top: 16px">
      <mat-card-title>Add Admin</mat-card-title>
      <mat-card-content>
        <form [formGroup]="form" (submit)="addAdmin()" class="form">
          <div class="row">
            <mat-form-field appearance="outline">
              <mat-label>User ID</mat-label>
              <input matInput formControlName="userId" type="number" placeholder="Enter user ID" />
            </mat-form-field>
          </div>

          <div class="row">
            <mat-checkbox formControlName="canManageDrivers">Manage Drivers</mat-checkbox>
            <mat-checkbox formControlName="canManageCustomers">Manage Customers</mat-checkbox>
            <mat-checkbox formControlName="canViewReports">View Reports</mat-checkbox>
            <mat-checkbox formControlName="canManageSettings">Manage Settings</mat-checkbox>
            <mat-checkbox formControlName="isPrimary">Primary</mat-checkbox>
          </div>

          <div class="actions">
            <button mat-raised-button color="primary" type="submit" [disabled]="form.invalid">
              Add Admin
            </button>
          </div>
        </form>
      </mat-card-content>
    </mat-card>
  `,
  styles: [
    `
      .w-100 {
        width: 100%;
      }
      .perm {
        margin-right: 6px;
        padding: 2px 6px;
        border-radius: 4px;
        background: #eee;
        font-size: 12px;
      }
      .form {
        display: flex;
        flex-direction: column;
        gap: 16px;
      }
      .row {
        display: flex;
        flex-wrap: wrap;
        gap: 16px;
        align-items: center;
      }
      .actions {
        display: flex;
        justify-content: flex-end;
      }
    `,
  ],
})
export class PartnerAdminComponent {
  @Input() partnerCompanyId!: number;

  private readonly partnerService = inject(VendorService);
  private readonly snackBar = inject(MatSnackBar);
  private readonly fb = inject(FormBuilder);

  admins: PartnerAdmin[] = [];
  displayedColumns = ['username', 'email', 'permissions', 'actions'];

  form = this.fb.group({
    userId: [null, Validators.required],
    canManageDrivers: [true],
    canManageCustomers: [true],
    canViewReports: [true],
    canManageSettings: [false],
    isPrimary: [false],
  });

  ngOnInit(): void {
    if (!this.partnerCompanyId) return;
    this.loadAdmins();
  }

  loadAdmins(): void {
    this.partnerService.getCompanyAdmins(this.partnerCompanyId).subscribe({
      next: (list) => (this.admins = list),
      error: () => this.snackBar.open('Failed to load admins', 'Close', { duration: 3000 }),
    });
  }

  addAdmin(): void {
    if (this.form.invalid) return;

    const payload = {
      partnerCompanyId: this.partnerCompanyId,
      ...this.form.value,
    } as Partial<PartnerAdmin>;

    this.partnerService.assignAdminToCompany(payload).subscribe({
      next: () => {
        this.snackBar.open('Admin assigned', 'Close', { duration: 3000 });
        this.form.reset({
          canManageDrivers: true,
          canManageCustomers: true,
          canViewReports: true,
          canManageSettings: false,
          isPrimary: false,
        });
        this.loadAdmins();
      },
      error: () => this.snackBar.open('Failed to assign admin', 'Close', { duration: 3000 }),
    });
  }

  togglePrimary(a: PartnerAdmin): void {
    const perms: PartnerAdminPermissions = {
      canManageDrivers: a.canManageDrivers,
      canManageCustomers: a.canManageCustomers,
      canViewReports: a.canViewReports,
      canManageSettings: a.canManageSettings,
    };
    this.partnerService.updateAdminPermissions(a.id!, perms).subscribe({
      next: () => this.loadAdmins(),
      error: () => this.snackBar.open('Failed to update', 'Close', { duration: 3000 }),
    });
  }

  removeAdmin(a: PartnerAdmin): void {
    this.partnerService.removeAdmin(a.id!).subscribe({
      next: () => {
        this.snackBar.open('Admin removed', 'Close', { duration: 3000 });
        this.loadAdmins();
      },
      error: () => this.snackBar.open('Failed to remove', 'Close', { duration: 3000 }),
    });
  }
}
