/* eslint-disable @typescript-eslint/consistent-type-imports */
import { CommonModule } from '@angular/common';
import type { OnInit, OnChanges } from '@angular/core';
import { Component, Inject } from '@angular/core';
import type { FormGroup, AbstractControl, ValidationErrors } from '@angular/forms';
import { ReactiveFormsModule, Validators, FormBuilder } from '@angular/forms';
import { FormsModule } from '@angular/forms';
import { MatButtonModule } from '@angular/material/button';
import { MatChipsModule } from '@angular/material/chips';
import { MatDialogRef } from '@angular/material/dialog';
import { MatDialogModule, MAT_DIALOG_DATA } from '@angular/material/dialog';
import { MatFormFieldModule } from '@angular/material/form-field';
import { MatIconModule } from '@angular/material/icon';
import { MatInputModule } from '@angular/material/input';
import { MatSelectModule } from '@angular/material/select';

import type { Permission } from '../../models/permission.model';
import type { Role } from '../../models/role.model';

@Component({
  selector: 'app-role-dialog',
  standalone: true,
  imports: [
    CommonModule,
    MatDialogModule,
    MatFormFieldModule,
    MatInputModule,
    MatSelectModule,
    MatButtonModule,
    MatIconModule,
    MatChipsModule,
    ReactiveFormsModule,
    FormsModule,
  ],
  template: `
    <div class="p-6 max-h-[80vh] overflow-y-auto">
      <div class="flex items-center gap-4 mb-6">
        <div
          class="flex items-center justify-center w-14 h-14 rounded-xl"
          [class.bg-green-100]="!data.role"
          [class.text-green-600]="!data.role"
          [class.bg-blue-100]="data.role"
          [class.text-blue-600]="data.role"
          [class.shadow-lg]="true"
        >
          <mat-icon class="text-2xl">{{ data.role ? 'edit' : 'add' }}</mat-icon>
        </div>
        <div class="flex-1">
          <h2 class="text-2xl font-bold text-gray-900">
            {{ data.role ? 'Edit Role' : 'Create New Role' }}
          </h2>
          <p class="text-sm text-gray-600 mt-1">
            {{
              data.role
                ? 'Update role details and permissions'
                : 'Define a new role with specific permissions'
            }}
          </p>
          <div *ngIf="data.role" class="mt-2 flex items-center gap-2">
            <mat-chip class="text-xs bg-blue-100 text-blue-800">
              <mat-icon class="text-sm mr-1">group</mat-icon>
              {{ data.role.name }}
            </mat-chip>
          </div>
        </div>
      </div>

      <form [formGroup]="roleForm" class="space-y-8">
        <!-- Basic Information Section -->
        <div class="space-y-4">
          <div class="flex items-center gap-2 mb-4">
            <mat-icon class="text-blue-600">info</mat-icon>
            <h3 class="text-lg font-semibold text-gray-900">Basic Information</h3>
            <div class="flex-1 h-px bg-gray-200"></div>
          </div>
          <!-- Role Name -->
          <div class="space-y-2">
            <mat-form-field appearance="outline" class="w-full">
              <mat-label>Role Name <span class="text-red-500">*</span></mat-label>
              <input
                matInput
                formControlName="name"
                placeholder="e.g., Admin, Manager, Driver"
                autocomplete="off"
                maxlength="50"
              />
              <mat-icon matPrefix fontIcon="group" class="text-gray-400"></mat-icon>
              <mat-hint>Choose a descriptive name for this role (2-50 characters)</mat-hint>
              <mat-error
                *ngIf="roleForm.get('name')?.hasError('required') && roleForm.get('name')?.touched"
              >
                <mat-icon class="text-sm mr-1">error</mat-icon>
                Role name is required
              </mat-error>
              <mat-error
                *ngIf="roleForm.get('name')?.hasError('minlength') && roleForm.get('name')?.touched"
              >
                <mat-icon class="text-sm mr-1">error</mat-icon>
                Role name must be at least 2 characters long
              </mat-error>
              <mat-error
                *ngIf="roleForm.get('name')?.hasError('maxlength') && roleForm.get('name')?.touched"
              >
                <mat-icon class="text-sm mr-1">error</mat-icon>
                Role name cannot exceed 50 characters
              </mat-error>
            </mat-form-field>
          </div>

          <!-- Description -->
          <div class="space-y-2">
            <mat-form-field appearance="outline" class="w-full">
              <mat-label>Description <span class="text-red-500">*</span></mat-label>
              <textarea
                matInput
                formControlName="description"
                placeholder="Describe what this role can do..."
                rows="3"
                autocomplete="off"
                maxlength="200"
              ></textarea>
              <mat-icon matPrefix fontIcon="description" class="text-gray-400 mt-1"></mat-icon>
              <mat-hint
                >Provide a clear description of this role's responsibilities (max 200
                characters)</mat-hint
              >
              <mat-error
                *ngIf="
                  roleForm.get('description')?.hasError('required') &&
                  roleForm.get('description')?.touched
                "
              >
                <mat-icon class="text-sm mr-1">error</mat-icon>
                Description is required
              </mat-error>
              <mat-error
                *ngIf="
                  roleForm.get('description')?.hasError('maxlength') &&
                  roleForm.get('description')?.touched
                "
              >
                <mat-icon class="text-sm mr-1">error</mat-icon>
                Description cannot exceed 200 characters
              </mat-error>
            </mat-form-field>
            <div class="text-xs text-gray-500 text-right">
              {{ roleForm.get('description')?.value?.length || 0 }}/200 characters
            </div>
          </div>
        </div>

        <!-- Permissions Section -->
        <div class="space-y-4">
          <div class="flex items-center gap-2 mb-4">
            <mat-icon class="text-green-600">security</mat-icon>
            <h3 class="text-lg font-semibold text-gray-900">Permissions</h3>
            <div class="flex-1 h-px bg-gray-200"></div>
          </div>
          <div class="space-y-3">
            <div class="flex items-center justify-between">
              <label class="text-sm font-medium text-gray-700 flex items-center gap-2">
                <mat-icon class="text-gray-500">security</mat-icon>
                Permissions <span class="text-red-500">*</span>
              </label>
              <div class="flex gap-2 mb-3">
                <button
                  type="button"
                  mat-stroked-button
                  size="small"
                  (click)="selectAllPermissions()"
                  [disabled]="isSubmitting"
                  class="text-xs"
                >
                  <mat-icon class="text-sm mr-1">check_box</mat-icon>
                  Select All
                </button>
                <button
                  type="button"
                  mat-stroked-button
                  size="small"
                  (click)="clearAllPermissions()"
                  [disabled]="isSubmitting"
                  class="text-xs"
                >
                  <mat-icon class="text-sm mr-1">clear</mat-icon>
                  Clear All
                </button>
              </div>

              <!-- Permissions Search -->
              <mat-form-field appearance="outline" class="w-full mb-3">
                <mat-label>Search Permissions</mat-label>
                <input
                  matInput
                  [(ngModel)]="permissionsSearch"
                  [ngModelOptions]="{ standalone: true }"
                  placeholder="Type to search permissions..."
                  autocomplete="off"
                />
                <mat-icon matPrefix class="text-gray-400">search</mat-icon>
                <button
                  matSuffix
                  mat-icon-button
                  *ngIf="permissionsSearch"
                  (click)="permissionsSearch = ''"
                  aria-label="Clear search"
                >
                  <mat-icon>clear</mat-icon>
                </button>
              </mat-form-field>
            </div>

            <mat-form-field appearance="outline" class="w-full">
              <mat-label>Select Permissions</mat-label>
              <mat-select formControlName="permissions" multiple [compareWith]="comparePermissions">
                <mat-option
                  *ngFor="let permission of groupedPermissions | keyvalue"
                  [value]="permission.key"
                  [disabled]="true"
                  class="font-semibold text-gray-700 bg-gray-50"
                >
                  <div class="flex items-center gap-2 py-1">
                    <mat-icon class="text-sm">{{ getResourceIcon(permission.key) }}</mat-icon>
                    {{ permission.key | titlecase }} Permissions
                  </div>
                </mat-option>
                <mat-option
                  *ngFor="let permission of groupedPermissions | keyvalue"
                  [value]="permission.key"
                  [disabled]="true"
                  class="hidden"
                >
                </mat-option>
                <mat-option
                  *ngFor="let permission of filteredPermissions"
                  [value]="permission"
                  class="ml-4"
                >
                  <div class="flex items-center gap-2">
                    <mat-icon class="text-sm text-gray-500">{{
                      getActionIcon(permission.actionType)
                    }}</mat-icon>
                    <div>
                      <div class="font-medium">{{ permission.name }}</div>
                      <div class="text-xs text-gray-500">{{ permission.description }}</div>
                    </div>
                  </div>
                </mat-option>
              </mat-select>
              <mat-hint
                >{{ selectedPermissionsCount }} of {{ data.permissions.length || 0 }} permissions
                selected</mat-hint
              >
              <mat-error
                *ngIf="
                  roleForm.get('permissions')?.hasError('required') &&
                  roleForm.get('permissions')?.touched
                "
              >
                <mat-icon class="text-sm mr-1">error</mat-icon>
                At least one permission must be selected
              </mat-error>
            </mat-form-field>

            <!-- Selected Permissions Preview -->
            <div *ngIf="selectedPermissions.length > 0" class="mt-3">
              <label class="text-sm font-medium text-gray-700 mb-2 block flex items-center gap-2">
                <mat-icon class="text-sm">check_circle</mat-icon>
                Selected Permissions ({{ selectedPermissions.length }})
              </label>
              <mat-chip-set>
                <mat-chip
                  *ngFor="let perm of selectedPermissions"
                  [removable]="true"
                  (removed)="removePermission(perm)"
                  [disabled]="isSubmitting"
                  class="mb-1 mr-1"
                >
                  <mat-icon class="text-sm mr-1">{{ getActionIcon(perm.actionType) }}</mat-icon>
                  {{ perm.name }}
                  <mat-icon matChipRemove>cancel</mat-icon>
                </mat-chip>
              </mat-chip-set>
            </div>

            <!-- Permissions by Resource Type -->
            <div *ngIf="selectedPermissions.length > 0" class="mt-4 p-4 bg-gray-50 rounded-lg">
              <label class="text-sm font-medium text-gray-700 mb-3 block"
                >Permissions by Resource Type:</label
              >
              <div class="grid grid-cols-1 sm:grid-cols-2 gap-3">
                <div
                  *ngFor="let group of getGroupedSelectedPermissions()"
                  class="flex items-center gap-2 p-2 bg-white rounded border"
                >
                  <mat-icon class="text-sm text-blue-600">{{
                    getResourceIcon(group.resourceType)
                  }}</mat-icon>
                  <div class="flex-1">
                    <div class="text-sm font-medium">{{ group.resourceType }}</div>
                    <div class="text-xs text-gray-500">
                      {{ group.permissions.length }} permission{{
                        group.permissions.length !== 1 ? 's' : ''
                      }}
                    </div>
                  </div>
                </div>
              </div>
            </div>
          </div>
        </div>
      </form>

      <!-- Action Buttons -->
      <div class="flex justify-between items-center mt-8 pt-4 border-t border-gray-200">
        <div class="text-sm text-gray-500">
          <span *ngIf="roleForm.invalid" class="text-red-600 flex items-center gap-1">
            <mat-icon class="text-sm">error</mat-icon>
            Please complete all required fields
          </span>
          <span *ngIf="roleForm.valid" class="text-green-600 flex items-center gap-1">
            <mat-icon class="text-sm">check_circle</mat-icon>
            Ready to {{ data.role ? 'update' : 'create' }}
          </span>
        </div>
        <div class="flex gap-3">
          <button
            mat-button
            mat-dialog-close
            [disabled]="isSubmitting"
            class="px-4 py-2 text-gray-700 hover:bg-gray-100 transition-colors"
          >
            <mat-icon class="text-sm mr-1">close</mat-icon>
            Cancel
          </button>
          <button
            mat-raised-button
            color="primary"
            (click)="submit()"
            [disabled]="roleForm.invalid || isSubmitting"
            class="px-6 py-2 min-w-[120px]"
          >
            <mat-icon *ngIf="isSubmitting" class="animate-spin text-sm mr-1">refresh</mat-icon>
            <mat-icon *ngIf="!isSubmitting" class="text-sm mr-1">{{
              data.role ? 'save' : 'add'
            }}</mat-icon>
            {{ isSubmitting ? 'Saving...' : data.role ? 'Update Role' : 'Create Role' }}
          </button>
        </div>
      </div>
    </div>
  `,
  styles: [
    `
      .mat-mdc-chip {
        --mdc-chip-container-height: 28px;
        font-size: 12px;
      }

      .mat-mdc-chip-removal-icon {
        font-size: 16px;
      }

      mat-option.group-header {
        font-weight: 600;
        background-color: #f9fafb;
        pointer-events: none;
      }

      mat-option.group-header:hover {
        background-color: #f9fafb;
      }
    `,
  ],
})
export class RoleDialogComponent implements OnInit, OnChanges {
  roleForm!: FormGroup;
  isSubmitting = false;
  groupedPermissions: { [key: string]: Permission[] } = {};
  allPermissions: Permission[] = [];
  filteredPermissions: Permission[] = [];
  permissionsSearch = '';

  constructor(
    private fb: FormBuilder,
    private dialogRef: MatDialogRef<RoleDialogComponent>,
    @Inject(MAT_DIALOG_DATA) public data: { role?: Role; permissions: Permission[] },
  ) {
    this.initializeForm();
    this.groupPermissions();
  }

  ngOnInit() {
    this.updateFilteredPermissions();
  }

  ngOnChanges() {
    this.updateFilteredPermissions();
  }

  private initializeForm(): void {
    const selectedPermissions = this.data.role
      ? this.getSelectedPermissionsFromRole(this.data.role)
      : [];

    this.roleForm = this.fb.group({
      name: [
        this.data.role?.name || '',
        [Validators.required, Validators.minLength(2), Validators.maxLength(50)],
      ],
      description: [
        this.data.role?.description || '',
        [Validators.required, Validators.maxLength(200)],
      ],
      permissions: [selectedPermissions, [Validators.required, this.permissionsRequiredValidator]],
    });
  }

  private permissionsRequiredValidator(control: AbstractControl): ValidationErrors | null {
    const value = control.value;
    if (!value || !Array.isArray(value) || value.length === 0) {
      return { required: true };
    }
    return null;
  }

  private groupPermissions(): void {
    this.allPermissions = this.data.permissions || [];
    this.groupedPermissions = this.allPermissions.reduce(
      (groups, permission) => {
        const resourceType = permission.resourceType || 'General';
        if (!groups[resourceType]) {
          groups[resourceType] = [];
        }
        groups[resourceType].push(permission);
        return groups;
      },
      {} as { [key: string]: Permission[] },
    );
  }

  private getSelectedPermissionsFromRole(role: Role): Permission[] {
    if (!role.permissions) return [];

    const permissionNames =
      typeof role.permissions === 'string' ? role.permissions.split(',') : role.permissions;

    return this.allPermissions.filter((perm) =>
      permissionNames.some((name) =>
        typeof name === 'string' ? name.trim() === perm.name : name === perm.name,
      ),
    );
  }

  get selectedPermissions(): Permission[] {
    return this.roleForm.get('permissions')?.value || [];
  }

  get selectedPermissionsCount(): number {
    return this.selectedPermissions.length;
  }

  comparePermissions(a: Permission, b: Permission): boolean {
    return a && b ? a.id === b.id : a === b;
  }

  selectAllPermissions(): void {
    this.roleForm.patchValue({
      permissions: [...this.allPermissions],
    });
  }

  clearAllPermissions(): void {
    this.roleForm.patchValue({
      permissions: [],
    });
  }

  removePermission(permission: Permission): void {
    const currentPermissions = this.selectedPermissions;
    const updatedPermissions = currentPermissions.filter((p) => p.id !== permission.id);
    this.roleForm.patchValue({
      permissions: updatedPermissions,
    });
  }

  getResourceIcon(resourceType: string): string {
    const iconMap: { [key: string]: string } = {
      user: 'person',
      role: 'group',
      permission: 'security',
      document: 'description',
      vehicle: 'local_shipping',
      trip: 'route',
      location: 'location_on',
      report: 'analytics',
      system: 'settings',
      general: 'apps',
    };
    return iconMap[resourceType.toLowerCase()] || 'apps';
  }

  getActionIcon(actionType: string): string {
    if (!actionType) {
      return 'security'; // Default icon for null/undefined actionType
    }

    const iconMap: { [key: string]: string } = {
      create: 'add',
      read: 'visibility',
      update: 'edit',
      delete: 'delete',
      manage: 'admin_panel_settings',
      view: 'visibility',
      edit: 'edit',
      all: 'all_inclusive',
    };
    return iconMap[actionType.toLowerCase()] || 'security';
  }

  getRoleData(): any {
    if (this.roleForm.invalid) return null;

    const formValue = this.roleForm.value;
    return {
      name: formValue.name,
      description: formValue.description,
      permissions: formValue.permissions.map((p: Permission) => p.name).join(','),
    };
  }

  submit(): void {
    if (this.roleForm.valid) {
      this.isSubmitting = true;
      // Close the dialog with the form data
      this.dialogRef.close(this.getRoleData());
    }
  }

  private updateFilteredPermissions(): void {
    if (!this.permissionsSearch.trim()) {
      this.filteredPermissions = [...this.allPermissions];
    } else {
      const searchTerm = this.permissionsSearch.toLowerCase();
      this.filteredPermissions = this.allPermissions.filter(
        (perm) =>
          perm.name.toLowerCase().includes(searchTerm) ||
          (perm.description && perm.description.toLowerCase().includes(searchTerm)) ||
          (perm.resourceType && perm.resourceType.toLowerCase().includes(searchTerm)) ||
          (perm.actionType && perm.actionType.toLowerCase().includes(searchTerm)),
      );
    }
  }

  getGroupedSelectedPermissions(): { resourceType: string; permissions: Permission[] }[] {
    const groups: { [key: string]: Permission[] } = {};
    this.selectedPermissions.forEach((perm) => {
      const resourceType = perm.resourceType || 'General';
      if (!groups[resourceType]) {
        groups[resourceType] = [];
      }
      groups[resourceType].push(perm);
    });

    return Object.keys(groups).map((resourceType) => ({
      resourceType,
      permissions: groups[resourceType],
    }));
  }
}
