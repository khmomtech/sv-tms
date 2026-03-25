import { CommonModule } from '@angular/common';
import type { OnInit } from '@angular/core';
import { Component, Inject, inject } from '@angular/core';
import { ConfirmService } from '@services/confirm.service';
// eslint-disable-next-line @typescript-eslint/consistent-type-imports
import { FormBuilder, type FormGroup, ReactiveFormsModule, Validators } from '@angular/forms';
import { MatButtonModule } from '@angular/material/button';
import { MatCardModule } from '@angular/material/card';
import { MatChipsModule } from '@angular/material/chips';
// eslint-disable-next-line @typescript-eslint/consistent-type-imports
import {
  MatDialog,
  MatDialogRef,
  MatDialogModule,
  MAT_DIALOG_DATA,
} from '@angular/material/dialog';
import { MatFormFieldModule } from '@angular/material/form-field';
import { MatIconModule } from '@angular/material/icon';
import { MatInputModule } from '@angular/material/input';
import { MatSelectModule } from '@angular/material/select';
// eslint-disable-next-line @typescript-eslint/consistent-type-imports
import { MatSnackBar, MatSnackBarModule } from '@angular/material/snack-bar';
import { MatTableModule } from '@angular/material/table';

// eslint-disable-next-line @typescript-eslint/consistent-type-imports
import { DynamicPermissionService } from '../../services/dynamic-permission.service';
import type {
  DynamicPermission,
  CreatePermissionRequest,
  UpdatePermissionRequest,
} from '../../services/dynamic-permission.service';

@Component({
  selector: 'app-dynamic-permission-management',
  standalone: true,
  imports: [
    CommonModule,
    ReactiveFormsModule,
    MatDialogModule,
    MatButtonModule,
    MatIconModule,
    MatInputModule,
    MatFormFieldModule,
    MatSelectModule,
    MatTableModule,
    MatSnackBarModule,
    MatChipsModule,
    MatCardModule,
  ],
  template: `
    <div class="container mx-auto p-6">
      <div class="flex items-center justify-between mb-6">
        <div>
          <h2 class="text-3xl font-bold text-gray-900">Dynamic Permission Management</h2>
          <p class="text-gray-600 mt-1">Create and manage runtime permissions</p>
        </div>
        <div class="flex gap-3">
          <button
            mat-raised-button
            color="primary"
            (click)="openCreateDialog()"
            class="flex items-center gap-2"
          >
            <mat-icon>add</mat-icon>
            Create Permission
          </button>
          <button mat-stroked-button (click)="clearCache()" class="flex items-center gap-2">
            <mat-icon>refresh</mat-icon>
            Clear Cache
          </button>
        </div>
      </div>

      <!-- Resource Type Filter -->
      <mat-card class="mb-6">
        <mat-card-header>
          <mat-card-title>Filter by Resource Type</mat-card-title>
        </mat-card-header>
        <mat-card-content>
          <div class="flex flex-wrap gap-2 mt-4">
            <mat-chip-listbox>
              <mat-chip-option
                *ngFor="let resourceType of resourceTypes"
                [selected]="selectedResource === resourceType"
                (click)="filterByResource(resourceType)"
              >
                {{ resourceType }}
              </mat-chip-option>
              <mat-chip-option
                [selected]="selectedResource === null"
                (click)="clearResourceFilter()"
              >
                All
              </mat-chip-option>
            </mat-chip-listbox>
          </div>
        </mat-card-content>
      </mat-card>

      <!-- Permissions Table -->
      <mat-card>
        <mat-card-header>
          <mat-card-title>
            Available Permissions
            <span class="text-sm text-gray-500 ml-2">({{ filteredPermissions.length }} items)</span>
          </mat-card-title>
        </mat-card-header>
        <mat-card-content>
          <div class="overflow-x-auto">
            <table mat-table [dataSource]="filteredPermissions" class="w-full">
              <ng-container matColumnDef="name">
                <th mat-header-cell *matHeaderCellDef class="font-semibold">Permission Name</th>
                <td mat-cell *matCellDef="let permission">
                  <code class="bg-gray-100 px-2 py-1 rounded text-sm">{{ permission.name }}</code>
                </td>
              </ng-container>

              <ng-container matColumnDef="description">
                <th mat-header-cell *matHeaderCellDef class="font-semibold">Description</th>
                <td mat-cell *matCellDef="let permission">{{ permission.description }}</td>
              </ng-container>

              <ng-container matColumnDef="resourceType">
                <th mat-header-cell *matHeaderCellDef class="font-semibold">Resource</th>
                <td mat-cell *matCellDef="let permission">
                  <span
                    class="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-blue-100 text-blue-800"
                  >
                    {{ permission.resourceType }}
                  </span>
                </td>
              </ng-container>

              <ng-container matColumnDef="actionType">
                <th mat-header-cell *matHeaderCellDef class="font-semibold">Action</th>
                <td mat-cell *matCellDef="let permission">
                  <span
                    class="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-green-100 text-green-800"
                  >
                    {{ permission.actionType }}
                  </span>
                </td>
              </ng-container>

              <ng-container matColumnDef="actions">
                <th mat-header-cell *matHeaderCellDef class="font-semibold">Actions</th>
                <td mat-cell *matCellDef="let permission">
                  <div class="flex gap-2">
                    <button
                      mat-icon-button
                      (click)="openEditDialog(permission)"
                      matTooltip="Edit permission"
                    >
                      <mat-icon class="text-blue-600">edit</mat-icon>
                    </button>
                    <button
                      mat-icon-button
                      (click)="deletePermission(permission)"
                      matTooltip="Delete permission"
                      [disabled]="isCorePermission(permission.name)"
                    >
                      <mat-icon
                        [class]="
                          isCorePermission(permission.name) ? 'text-gray-400' : 'text-red-600'
                        "
                        >delete</mat-icon
                      >
                    </button>
                  </div>
                </td>
              </ng-container>

              <tr mat-header-row *matHeaderRowDef="displayedColumns"></tr>
              <tr mat-row *matRowDef="let row; columns: displayedColumns"></tr>
            </table>

            <div *ngIf="filteredPermissions.length === 0" class="text-center py-8 text-gray-500">
              <mat-icon class="text-6xl mb-4 text-gray-300">security</mat-icon>
              <p>No permissions found</p>
            </div>
          </div>
        </mat-card-content>
      </mat-card>
    </div>
  `,
  styleUrl: './dynamic-permission-management.component.css',
})
export class DynamicPermissionManagementComponent implements OnInit {
  private confirm = inject(ConfirmService);

  permissions: DynamicPermission[] = [];
  filteredPermissions: DynamicPermission[] = [];
  resourceTypes: string[] = [];
  selectedResource: string | null = null;
  displayedColumns = ['name', 'description', 'resourceType', 'actionType', 'actions'];

  // Core permissions that cannot be deleted
  corePermissions = [
    'all_functions',
    'user:read',
    'user:create',
    'user:update',
    'user:delete',
    'role:read',
    'role:create',
    'role:update',
    'role:delete',
    'permission:read',
    'permission:create',
    'permission:update',
    'permission:delete',
  ];

  constructor(
    private dynamicPermissionService: DynamicPermissionService,
    private dialog: MatDialog,
    private snackBar: MatSnackBar,
  ) {}

  ngOnInit(): void {
    this.loadAllPermissions();
  }

  loadAllPermissions(): void {
    // Load all permissions by getting all resource types
    const resourceTypesToLoad = [
      'User',
      'Role',
      'Permission',
      'Driver',
      'Vehicle',
      'Job',
      'Item',
      'Audit',
      'Report',
      'Notification',
      'Settings',
      'Global',
    ];

    this.permissions = [];
    let loadCount = 0;

    resourceTypesToLoad.forEach((resourceType) => {
      this.dynamicPermissionService.getPermissionsByResource(resourceType).subscribe({
        next: (permissions) => {
          this.permissions.push(...permissions);
          loadCount++;

          if (loadCount === resourceTypesToLoad.length) {
            this.updateResourceTypes();
            this.applyFilter();
          }
        },
        error: (error) => {
          console.error('Error loading permissions for resource:', resourceType, error);
          loadCount++;

          if (loadCount === resourceTypesToLoad.length) {
            this.updateResourceTypes();
            this.applyFilter();
          }
        },
      });
    });
  }

  updateResourceTypes(): void {
    this.resourceTypes = [...new Set(this.permissions.map((p) => p.resourceType))].sort();
  }

  filterByResource(resourceType: string): void {
    this.selectedResource = resourceType;
    this.applyFilter();
  }

  clearResourceFilter(): void {
    this.selectedResource = null;
    this.applyFilter();
  }

  applyFilter(): void {
    if (this.selectedResource) {
      this.filteredPermissions = this.permissions.filter(
        (p) => p.resourceType === this.selectedResource,
      );
    } else {
      this.filteredPermissions = [...this.permissions];
    }
  }

  openCreateDialog(): void {
    const dialogRef = this.dialog.open(PermissionDialogComponent, {
      width: '600px',
      data: { resourceTypes: this.resourceTypes },
    });

    dialogRef.afterClosed().subscribe((result) => {
      if (result) {
        this.createPermission(result);
      }
    });
  }

  openEditDialog(permission: DynamicPermission): void {
    const dialogRef = this.dialog.open(PermissionDialogComponent, {
      width: '600px',
      data: {
        permission,
        resourceTypes: this.resourceTypes,
        isEdit: true,
      },
    });

    dialogRef.afterClosed().subscribe((result) => {
      if (result && permission.id) {
        this.updatePermission(permission.id, result);
      }
    });
  }

  createPermission(request: CreatePermissionRequest): void {
    this.dynamicPermissionService.createPermission(request).subscribe({
      next: () => {
        this.snackBar.open('Permission created successfully', 'Close', { duration: 3000 });
        this.loadAllPermissions();
      },
      error: (error) => {
        console.error('Error creating permission:', error);
        this.snackBar.open('Failed to create permission', 'Close', { duration: 3000 });
      },
    });
  }

  updatePermission(id: number, request: UpdatePermissionRequest): void {
    this.dynamicPermissionService.updatePermission(id, request).subscribe({
      next: () => {
        this.snackBar.open('Permission updated successfully', 'Close', { duration: 3000 });
        this.loadAllPermissions();
      },
      error: (error) => {
        console.error('Error updating permission:', error);
        this.snackBar.open('Failed to update permission', 'Close', { duration: 3000 });
      },
    });
  }

  async deletePermission(permission: DynamicPermission): Promise<void> {
    if (this.isCorePermission(permission.name)) {
      this.snackBar.open('Cannot delete core system permission', 'Close', { duration: 3000 });
      return;
    }

    if (
      !(await this.confirm.confirm(
        `Are you sure you want to delete permission "${permission.name}"?`,
      ))
    ) {
      return;
    }

    if (permission.id) {
      this.dynamicPermissionService.deletePermission(permission.id).subscribe({
        next: () => {
          this.snackBar.open('Permission deleted successfully', 'Close', { duration: 3000 });
          this.loadAllPermissions();
        },
        error: (error) => {
          console.error('Error deleting permission:', error);
          this.snackBar.open('Failed to delete permission', 'Close', { duration: 3000 });
        },
      });
    }
  }

  clearCache(): void {
    this.dynamicPermissionService.clearCache().subscribe({
      next: () => {
        this.snackBar.open('Permission cache cleared', 'Close', { duration: 3000 });
      },
      error: (error) => {
        console.error('Error clearing cache:', error);
        this.snackBar.open('Failed to clear cache', 'Close', { duration: 3000 });
      },
    });
  }

  isCorePermission(name: string): boolean {
    return this.corePermissions.includes(name);
  }
}

@Component({
  selector: 'app-permission-dialog',
  standalone: true,
  imports: [
    CommonModule,
    ReactiveFormsModule,
    MatDialogModule,
    MatButtonModule,
    MatIconModule,
    MatInputModule,
    MatFormFieldModule,
    MatSelectModule,
  ],
  template: `
    <div class="p-6">
      <h2 class="text-xl font-bold mb-4 flex items-center gap-2">
        <mat-icon>{{ data.isEdit ? 'edit' : 'add' }}</mat-icon>
        {{ data.isEdit ? 'Edit Permission' : 'Create Permission' }}
      </h2>

      <form [formGroup]="permissionForm" class="space-y-4">
        <div *ngIf="!data.isEdit">
          <mat-form-field appearance="outline" class="w-full">
            <mat-label>Permission Name</mat-label>
            <input
              matInput
              formControlName="name"
              placeholder="resource:action (e.g., customer:read)"
            />
            <mat-icon matPrefix>key</mat-icon>
            <mat-hint>Format: resource:action</mat-hint>
          </mat-form-field>
        </div>

        <div>
          <mat-form-field appearance="outline" class="w-full">
            <mat-label>Description</mat-label>
            <textarea
              matInput
              formControlName="description"
              rows="3"
              placeholder="Describe what this permission allows"
            ></textarea>
            <mat-icon matPrefix>description</mat-icon>
          </mat-form-field>
        </div>

        <div>
          <mat-form-field appearance="outline" class="w-full">
            <mat-label>Resource Type</mat-label>
            <mat-select formControlName="resourceType">
              <mat-option *ngFor="let resourceType of data.resourceTypes" [value]="resourceType">
                {{ resourceType }}
              </mat-option>
              <mat-option value="Custom">Custom Resource</mat-option>
            </mat-select>
            <mat-icon matPrefix>category</mat-icon>
          </mat-form-field>
        </div>

        <div>
          <mat-form-field appearance="outline" class="w-full">
            <mat-label>Action Type</mat-label>
            <mat-select formControlName="actionType">
              <mat-option value="read">Read</mat-option>
              <mat-option value="create">Create</mat-option>
              <mat-option value="update">Update</mat-option>
              <mat-option value="delete">Delete</mat-option>
              <mat-option value="manage">Manage</mat-option>
              <mat-option value="execute">Execute</mat-option>
            </mat-select>
            <mat-icon matPrefix>play_arrow</mat-icon>
          </mat-form-field>
        </div>
      </form>

      <div class="flex justify-end gap-3 mt-6 pt-4 border-t">
        <button mat-button mat-dialog-close>Cancel</button>
        <button
          mat-raised-button
          color="primary"
          [mat-dialog-close]="permissionForm.value"
          [disabled]="permissionForm.invalid"
        >
          {{ data.isEdit ? 'Update' : 'Create' }}
        </button>
      </div>
    </div>
  `,
})
export class PermissionDialogComponent {
  permissionForm: FormGroup;

  constructor(
    private fb: FormBuilder,
    public dialogRef: MatDialogRef<PermissionDialogComponent>,
    @Inject(MAT_DIALOG_DATA) public data: any,
  ) {
    this.permissionForm = this.fb.group({
      name: [
        { value: data.permission?.name || '', disabled: data.isEdit },
        [
          Validators.required,
          Validators.pattern(/^(all_functions|[a-zA-Z][a-zA-Z0-9_]*:[a-zA-Z][a-zA-Z0-9_]*)$/),
        ],
      ],
      description: [data.permission?.description || '', Validators.required],
      resourceType: [data.permission?.resourceType || '', Validators.required],
      actionType: [data.permission?.actionType || '', Validators.required],
    });
  }
}
