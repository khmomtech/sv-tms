/* eslint-disable @typescript-eslint/consistent-type-imports */
import { CommonModule } from '@angular/common';
import { Component, Inject, inject, OnInit } from '@angular/core';
import { FormControl, FormGroup } from '@angular/forms';
import { ReactiveFormsModule, Validators, FormBuilder } from '@angular/forms';
import { MatButtonModule } from '@angular/material/button';
import { MatDialog } from '@angular/material/dialog';
import { MatDialogModule, MAT_DIALOG_DATA } from '@angular/material/dialog';
import { MatFormFieldModule } from '@angular/material/form-field';
import { MatIconModule } from '@angular/material/icon';
import { MatInputModule } from '@angular/material/input';
import { MatSelectModule } from '@angular/material/select';
import { MatSnackBar, MatSnackBarModule } from '@angular/material/snack-bar';
import { MatTooltipModule } from '@angular/material/tooltip';

import type { Permission } from '../../models/permission.model';
import { PermissionService } from '../../services/permission.service';
import { ConfirmService } from '../../services/confirm.service';

@Component({
  selector: 'app-permission-management',
  standalone: true,
  imports: [
    CommonModule,
    MatButtonModule,
    MatDialogModule,
    MatFormFieldModule,
    MatInputModule,
    MatSelectModule,
    MatIconModule,
    MatSnackBarModule,
    MatTooltipModule,
    ReactiveFormsModule,
  ],
  templateUrl: './permission-management.html',
  styleUrl: './permission-management.css',
})
export class PermissionManagement implements OnInit {
  private confirm = inject(ConfirmService);
  private snackBar = inject(MatSnackBar);

  permissions: Permission[] = [];
  isLoading = false;

  searchControl = new FormControl('');
  resourceFilter = new FormControl('');

  constructor(
    private permissionService: PermissionService,
    private dialog: MatDialog,
    private fb: FormBuilder,
  ) {}

  ngOnInit(): void {
    this.loadPermissions();
  }

  get availableResources(): string[] {
    const resources = new Set(this.permissions.map((p) => p.resourceType).filter(Boolean));
    return Array.from(resources).sort();
  }

  get filteredPermissions(): Permission[] {
    const term = (this.searchControl.value ?? '').toLowerCase().trim();
    const resource = this.resourceFilter.value ?? '';

    return this.permissions.filter((p) => {
      const matchesSearch =
        !term ||
        p.name.toLowerCase().includes(term) ||
        (p.description ?? '').toLowerCase().includes(term) ||
        (p.resourceType ?? '').toLowerCase().includes(term) ||
        (p.actionType ?? '').toLowerCase().includes(term);

      const matchesResource = !resource || p.resourceType === resource;

      return matchesSearch && matchesResource;
    });
  }

  clearFilters(): void {
    this.searchControl.setValue('');
    this.resourceFilter.setValue('');
  }

  loadPermissions(): void {
    this.isLoading = true;
    this.permissionService.getAllPermissions().subscribe({
      next: (permissions) => {
        this.permissions = permissions;
        this.isLoading = false;
      },
      error: () => {
        this.snackBar.open('Failed to load permissions', 'Dismiss', { duration: 4000 });
        this.isLoading = false;
      },
    });
  }

  openCreateDialog(): void {
    const dialogRef = this.dialog.open(PermissionDialogComponent, {
      width: '500px',
      data: {},
    });

    dialogRef.afterClosed().subscribe((result) => {
      if (result) {
        this.permissionService.createPermission(result).subscribe({
          next: () => {
            this.loadPermissions();
            this.snackBar.open('Permission created', 'Dismiss', { duration: 3000 });
          },
          error: (err) => {
            const msg = err?.error?.error ?? 'Failed to create permission';
            this.snackBar.open(msg, 'Dismiss', { duration: 5000 });
          },
        });
      }
    });
  }

  openEditDialog(permission: Permission): void {
    const dialogRef = this.dialog.open(PermissionDialogComponent, {
      width: '500px',
      data: { permission },
    });

    dialogRef.afterClosed().subscribe((result) => {
      if (result) {
        this.permissionService.updatePermission({ ...permission, ...result }).subscribe({
          next: () => {
            this.loadPermissions();
            this.snackBar.open('Permission updated', 'Dismiss', { duration: 3000 });
          },
          error: (err) => {
            const msg = err?.error?.error ?? 'Failed to update permission';
            this.snackBar.open(msg, 'Dismiss', { duration: 5000 });
          },
        });
      }
    });
  }

  async deletePermission(permission: Permission): Promise<void> {
    if (
      !(await this.confirm.confirm(
        `Delete permission "${permission.name}"? Roles using it will lose this permission.`,
      ))
    ) {
      return;
    }
    this.permissionService.deletePermission(permission.id).subscribe({
      next: () => {
        this.loadPermissions();
        this.snackBar.open('Permission deleted', 'Dismiss', { duration: 3000 });
      },
      error: () => this.snackBar.open('Failed to delete permission', 'Dismiss', { duration: 4000 }),
    });
  }
}

@Component({
  selector: 'app-permission-dialog',
  standalone: true,
  imports: [
    CommonModule,
    MatDialogModule,
    MatFormFieldModule,
    MatInputModule,
    MatSelectModule,
    MatButtonModule,
    MatIconModule,
    ReactiveFormsModule,
  ],
  template: `
    <div class="p-6">
      <h2 class="text-xl font-bold mb-4 flex items-center gap-2">
        <mat-icon>{{ data.permission ? 'edit' : 'add' }}</mat-icon>
        {{ data.permission ? 'Edit Permission' : 'Create Permission' }}
      </h2>

      <form [formGroup]="permissionForm" class="space-y-4">
        <mat-form-field appearance="outline" class="w-full">
          <mat-label>Permission Name</mat-label>
          <input matInput formControlName="name" placeholder="e.g. user:read" [readonly]="!!data.permission" />
          <mat-icon matPrefix fontIcon="security"></mat-icon>
          <mat-hint>Format: resource:action</mat-hint>
          <mat-error *ngIf="permissionForm.get('name')?.hasError('required')">Required</mat-error>
          <mat-error *ngIf="permissionForm.get('name')?.hasError('pattern')">
            Must follow resource:action format
          </mat-error>
        </mat-form-field>

        <mat-form-field appearance="outline" class="w-full">
          <mat-label>Resource Type</mat-label>
          <input matInput formControlName="resourceType" placeholder="e.g. user, driver, order" />
          <mat-icon matPrefix fontIcon="category"></mat-icon>
          <mat-error *ngIf="permissionForm.get('resourceType')?.hasError('required')">Required</mat-error>
        </mat-form-field>

        <mat-form-field appearance="outline" class="w-full">
          <mat-label>Action Type</mat-label>
          <input matInput formControlName="actionType" placeholder="e.g. read, create, update, delete" />
          <mat-icon matPrefix fontIcon="bolt"></mat-icon>
          <mat-error *ngIf="permissionForm.get('actionType')?.hasError('required')">Required</mat-error>
        </mat-form-field>

        <mat-form-field appearance="outline" class="w-full">
          <mat-label>Description</mat-label>
          <textarea matInput formControlName="description" rows="2" placeholder="What does this permission allow?"></textarea>
          <mat-icon matPrefix fontIcon="description"></mat-icon>
          <mat-error *ngIf="permissionForm.get('description')?.hasError('required')">Required</mat-error>
        </mat-form-field>
      </form>

      <div class="flex justify-end gap-3 mt-6 pt-4 border-t">
        <button mat-button mat-dialog-close>Cancel</button>
        <button
          mat-raised-button
          color="primary"
          [mat-dialog-close]="permissionForm.value"
          [disabled]="permissionForm.invalid"
        >
          {{ data.permission ? 'Update' : 'Create' }}
        </button>
      </div>
    </div>
  `,
})
export class PermissionDialogComponent {
  permissionForm: FormGroup;

  constructor(
    private fb: FormBuilder,
    @Inject(MAT_DIALOG_DATA) public data: any,
  ) {
    this.permissionForm = this.fb.group({
      name: [
        data.permission?.name || '',
        [
          Validators.required,
          Validators.minLength(3),
          Validators.pattern(/^[a-z0-9_]+:[a-z0-9_]+$|^all_functions$/),
        ],
      ],
      resourceType: [data.permission?.resourceType || '', Validators.required],
      actionType: [data.permission?.actionType || '', Validators.required],
      description: [data.permission?.description || '', Validators.required],
    });
  }
}
