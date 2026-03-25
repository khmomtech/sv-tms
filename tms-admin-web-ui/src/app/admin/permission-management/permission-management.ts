/* eslint-disable @typescript-eslint/consistent-type-imports */
import { CommonModule } from '@angular/common';
import { Component, Inject, inject, OnInit } from '@angular/core';
import { ConfirmService } from '../../services/confirm.service';
import { FormGroup } from '@angular/forms';
import { ReactiveFormsModule, Validators, FormBuilder } from '@angular/forms';
import { MatButtonModule } from '@angular/material/button';
import { MatDialog } from '@angular/material/dialog';
import { MatDialogModule, MAT_DIALOG_DATA } from '@angular/material/dialog';
import { MatFormFieldModule } from '@angular/material/form-field';
import { MatIconModule } from '@angular/material/icon';
import { MatInputModule } from '@angular/material/input';
import { MatSelectModule } from '@angular/material/select';

import type { Permission } from '../../models/permission.model';
import { PermissionService } from '../../services/permission.service';

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
    ReactiveFormsModule,
  ],
  templateUrl: './permission-management.html',
  styleUrl: './permission-management.css',
})
export class PermissionManagement implements OnInit {
  private confirm = inject(ConfirmService);
  permissions: Permission[] = [];

  constructor(
    private permissionService: PermissionService,
    private dialog: MatDialog,
    private fb: FormBuilder,
  ) {}

  ngOnInit(): void {
    this.loadPermissions();
  }

  loadPermissions(): void {
    this.permissionService.getAllPermissions().subscribe({
      next: (permissions) => (this.permissions = permissions),
      error: (error) => console.error('Error loading permissions:', error),
    });
  }

  openCreateDialog(): void {
    const dialogRef = this.dialog.open(PermissionDialogComponent, {
      width: '500px',
    });

    dialogRef.afterClosed().subscribe((result) => {
      if (result) {
        this.permissionService.createPermission(result).subscribe({
          next: () => this.loadPermissions(),
          error: (error) => console.error('Error creating permission:', error),
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
          next: () => this.loadPermissions(),
          error: (error) => console.error('Error updating permission:', error),
        });
      }
    });
  }

  async deletePermission(permission: Permission): Promise<void> {
    if (
      !(await this.confirm.confirm(
        `Are you sure you want to delete permission "${permission.name}"?`,
      ))
    ) {
      return;
    }
    this.permissionService.deletePermission(permission.id).subscribe({
      next: () => this.loadPermissions(),
      error: (error) => console.error('Error deleting permission:', error),
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
        <div>
          <mat-form-field appearance="outline" class="w-full">
            <mat-label>Permission Name</mat-label>
            <input matInput formControlName="name" placeholder="Enter permission name" />
            <mat-icon matPrefix fontIcon="security"></mat-icon>
          </mat-form-field>
        </div>

        <div>
          <mat-form-field appearance="outline" class="w-full">
            <mat-label>Description</mat-label>
            <input
              matInput
              formControlName="description"
              placeholder="Enter permission description"
            />
            <mat-icon matPrefix fontIcon="description"></mat-icon>
          </mat-form-field>
        </div>

        <div>
          <mat-form-field appearance="outline" class="w-full">
            <mat-label>Resource Type</mat-label>
            <input
              matInput
              formControlName="resourceType"
              placeholder="e.g., user, role, permission"
            />
            <mat-icon matPrefix fontIcon="category"></mat-icon>
          </mat-form-field>
        </div>

        <div>
          <mat-form-field appearance="outline" class="w-full">
            <mat-label>Action Type</mat-label>
            <input matInput formControlName="actionType" placeholder="e.g., read, write, delete" />
            <mat-icon matPrefix fontIcon="settings"></mat-icon>
          </mat-form-field>
        </div>
      </form>

      <div class="flex justify-end gap-3 mt-6 pt-4 border-t">
        <button mat-button mat-dialog-close class="px-4 py-2">Cancel</button>
        <button
          mat-raised-button
          color="primary"
          [mat-dialog-close]="permissionForm.value"
          [disabled]="permissionForm.invalid"
          class="px-6 py-2"
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
      name: [data.permission?.name || '', [Validators.required, Validators.minLength(3)]],
      description: [data.permission?.description || '', Validators.required],
      resourceType: [data.permission?.resourceType || '', Validators.required],
      actionType: [data.permission?.actionType || '', Validators.required],
    });
  }
}
