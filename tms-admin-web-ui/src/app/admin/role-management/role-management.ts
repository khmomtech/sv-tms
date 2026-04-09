/* eslint-disable @typescript-eslint/consistent-type-imports */
import { CommonModule } from '@angular/common';
import { OnInit } from '@angular/core';
import { Component, Inject } from '@angular/core';
import { FormGroup } from '@angular/forms';
import { ReactiveFormsModule, FormBuilder } from '@angular/forms';
import { MatButtonModule } from '@angular/material/button';
import { MatCheckboxModule } from '@angular/material/checkbox';
import { MatChipsModule } from '@angular/material/chips';
import { MatDialog, MatDialogRef } from '@angular/material/dialog';
import { MatDialogModule, MAT_DIALOG_DATA } from '@angular/material/dialog';
import { MatDividerModule } from '@angular/material/divider';
import { MatFormFieldModule } from '@angular/material/form-field';
import { MatIconModule } from '@angular/material/icon';
import { MatInputModule } from '@angular/material/input';
import { MatMenuModule } from '@angular/material/menu';
import { MatProgressSpinnerModule } from '@angular/material/progress-spinner';
import { MatSelectModule } from '@angular/material/select';
import { MatSnackBar } from '@angular/material/snack-bar';
import { MatSnackBarModule } from '@angular/material/snack-bar';
import { MatTooltipModule } from '@angular/material/tooltip';

import type { Permission } from '../../models/permission.model';
import type { Role } from '../../models/role.model';
import { PermissionService } from '../../services/permission.service';
import { RoleService } from '../../services/role.service';
import { firstValueFrom } from 'rxjs';

import { RoleDialogComponent } from './role-dialog.component';

@Component({
  selector: 'app-role-management',
  standalone: true,
  imports: [
    CommonModule,
    MatButtonModule,
    MatDialogModule,
    MatFormFieldModule,
    MatInputModule,
    MatSelectModule,
    MatIconModule,
    MatChipsModule,
    MatProgressSpinnerModule,
    MatSnackBarModule,
    MatCheckboxModule,
    MatMenuModule,
    MatDividerModule,
    MatTooltipModule,
    ReactiveFormsModule,
  ],
  templateUrl: './role-management.html',
  styleUrl: './role-management.css',
})
export class RoleManagement implements OnInit {
  roles: Role[] = [];
  permissions: Permission[] = [];
  filteredRoles: Role[] = [];
  isLoading = false;
  searchForm!: FormGroup;
  selectedRoles: Set<number> = new Set();

  // Statistics
  totalRoles = 0;
  totalPermissions = 0;

  get systemRolesCount(): number {
    return this.roles.filter((r) => r.name === 'Admin').length;
  }

  constructor(
    private roleService: RoleService,
    private permissionService: PermissionService,
    private dialog: MatDialog,
    private snackBar: MatSnackBar,
    private fb: FormBuilder,
  ) {}

  ngOnInit(): void {
    this.initializeSearchForm();
    this.loadData();
  }

  private initializeSearchForm(): void {
    this.searchForm = this.fb.group({
      search: [''],
      permissionFilter: [''],
      sortBy: ['name'],
    });

    this.searchForm.valueChanges.subscribe(() => {
      this.applyFilters();
    });
  }

  private loadData(): void {
    this.isLoading = true;
    Promise.all([this.loadRoles(), this.loadPermissions()]).finally(() => {
      this.isLoading = false;
    });
  }

  private loadRoles(): Promise<void> {
    return new Promise((resolve) => {
      this.roleService.getAllRoles().subscribe({
        next: (roles) => {
          this.roles = roles;
          this.totalRoles = roles.length;
          this.applyFilters();
          resolve();
        },
        error: (error) => {
          console.error('Error loading roles:', error);
          this.showError('Failed to load roles');
          resolve();
        },
      });
    });
  }

  private loadPermissions(): Promise<void> {
    return new Promise((resolve) => {
      this.permissionService.getAllPermissions().subscribe({
        next: (permissions) => {
          this.permissions = permissions;
          this.totalPermissions = permissions.length;
          resolve();
        },
        error: (error) => {
          console.error('Error loading permissions:', error);
          this.showError('Failed to load permissions');
          resolve();
        },
      });
    });
  }

  private applyFilters(): void {
    const { search, permissionFilter, sortBy } = this.searchForm.value;
    let filtered = [...this.roles];

    // Search filter
    if (search) {
      const searchLower = search.toLowerCase();
      filtered = filtered.filter(
        (role) =>
          role.name.toLowerCase().includes(searchLower) ||
          role.description?.toLowerCase().includes(searchLower),
      );
    }

    // Permission filter
    if (permissionFilter) {
      filtered = filtered.filter((role) =>
        this.getPermissionNames(role.permissions).some((perm) =>
          perm.toLowerCase().includes(permissionFilter.toLowerCase()),
        ),
      );
    }

    // Sort
    filtered.sort((a, b) => {
      switch (sortBy) {
        case 'name':
          return a.name.localeCompare(b.name);
        case 'description':
          return (a.description || '').localeCompare(b.description || '');
        case 'permissions':
          return (
            this.getPermissionNames(a.permissions).length -
            this.getPermissionNames(b.permissions).length
          );
        default:
          return 0;
      }
    });

    this.filteredRoles = filtered;
  }

  getPermissionNames(permissions: any): string[] {
    if (!permissions) return [];
    if (typeof permissions === 'string') {
      return permissions.split(',').map((p) => p.trim());
    }
    return permissions.map((p: any) => (typeof p === 'string' ? p : p.name || p));
  }

  getPermissionObjects(role: Role): Permission[] {
    const permissionNames = this.getPermissionNames(role.permissions);
    return this.permissions.filter((perm) => permissionNames.includes(perm.name));
  }

  openCreateDialog(): void {
    const dialogRef = this.dialog.open(RoleDialogComponent, {
      width: '700px',
      maxWidth: '90vw',
      maxHeight: '90vh',
      data: { permissions: this.permissions },
      disableClose: true,
    });

    dialogRef.afterClosed().subscribe((result) => {
      if (result) {
        this.createRole(result);
      }
    });
  }

  openEditDialog(role: Role): void {
    const dialogRef = this.dialog.open(RoleDialogComponent, {
      width: '700px',
      maxWidth: '90vw',
      maxHeight: '90vh',
      data: { role, permissions: this.permissions },
      disableClose: true,
    });

    dialogRef.afterClosed().subscribe((result) => {
      if (result) {
        this.updateRole(role, result);
      }
    });
  }

  private createRole(roleData: any): void {
    this.isLoading = true;
    this.roleService
      .createRole(roleData)
      .subscribe({
        next: () => {
          this.showSuccess('Role created successfully');
          this.loadRoles();
        },
        error: (error) => {
          console.error('Error creating role:', error);
          this.showError('Failed to create role');
        },
      })
      .add(() => {
        this.isLoading = false;
      });
  }

  private updateRole(role: Role, roleData: any): void {
    this.isLoading = true;
    this.roleService
      .updateRole({ ...role, ...roleData })
      .subscribe({
        next: () => {
          this.showSuccess('Role updated successfully');
          this.loadRoles();
        },
        error: (error) => {
          console.error('Error updating role:', error);
          this.showError('Failed to update role');
        },
      })
      .add(() => {
        this.isLoading = false;
      });
  }

  deleteRole(role: Role): void {
    const dialogRef = this.dialog.open(ConfirmDialogComponent, {
      width: '400px',
      data: {
        title: 'Delete Role',
        message: `Are you sure you want to delete the role "${role.name}"?`,
        confirmText: 'Delete',
        confirmColor: 'warn',
      },
    });

    dialogRef.afterClosed().subscribe((confirmed) => {
      if (confirmed) {
        this.isLoading = true;
        this.roleService
          .deleteRole(role.id)
          .subscribe({
            next: () => {
              this.showSuccess('Role deleted successfully');
              this.loadRoles();
            },
            error: (error) => {
              console.error('Error deleting role:', error);
              this.showError('Failed to delete role');
            },
          })
          .add(() => {
            this.isLoading = false;
          });
      }
    });
  }

  toggleRoleSelection(roleId: number, checked: boolean): void {
    if (checked) {
      this.selectedRoles.add(roleId);
    } else {
      this.selectedRoles.delete(roleId);
    }
  }

  isRoleSelected(roleId: number): boolean {
    return this.selectedRoles.has(roleId);
  }

  selectAllRoles(): void {
    if (this.selectedRoles.size === this.filteredRoles.length) {
      this.selectedRoles.clear();
    } else {
      this.selectedRoles = new Set(this.filteredRoles.map((r) => r.id));
    }
  }

  bulkDelete(): void {
    if (this.selectedRoles.size === 0) return;

    const dialogRef = this.dialog.open(ConfirmDialogComponent, {
      width: '400px',
      data: {
        title: 'Delete Multiple Roles',
        message: `Are you sure you want to delete ${this.selectedRoles.size} role(s)?`,
        confirmText: 'Delete All',
        confirmColor: 'warn',
      },
    });

    dialogRef.afterClosed().subscribe((confirmed) => {
      if (confirmed) {
        this.isLoading = true;
        const deletePromises = Array.from(this.selectedRoles).map((roleId) =>
          firstValueFrom(this.roleService.deleteRole(roleId)),
        );

        Promise.all(deletePromises)
          .then(() => {
            this.showSuccess(`${this.selectedRoles.size} role(s) deleted successfully`);
            this.selectedRoles.clear();
            this.loadRoles();
          })
          .catch((error) => {
            console.error('Error deleting roles:', error);
            this.showError('Failed to delete some roles');
          })
          .finally(() => {
            this.isLoading = false;
          });
      }
    });
  }

  clearFilters(): void {
    this.searchForm.reset({
      search: '',
      permissionFilter: '',
      sortBy: 'name',
    });
  }

  clearSearchFilter(): void {
    this.searchForm.patchValue({ search: '' });
  }

  resetSort(): void {
    this.searchForm.patchValue({ sortBy: 'name' });
  }

  getSortLabel(sortValue: string): string {
    const labels: { [key: string]: string } = {
      name: 'Name',
      description: 'Description',
      permissions: 'Permissions Count',
    };
    return labels[sortValue] || 'Name';
  }

  hasActiveFilters(): boolean {
    const { search, permissionFilter } = this.searchForm.value;
    return !!(search || permissionFilter);
  }

  trackByRoleId(index: number, role: Role): number {
    return role.id;
  }

  duplicateRole(role: Role): void {
    // Create role data without id for duplication
    const roleData = {
      name: `${role.name} (Copy)`,
      description: role.description,
      permissions: role.permissions,
    };

    this.isLoading = true;
    // Cast to any to bypass TypeScript checking since the API might accept partial data
    this.roleService
      .createRole(roleData as any)
      .subscribe({
        next: () => {
          this.showSuccess('Role duplicated successfully');
          this.loadRoles();
        },
        error: (error) => {
          console.error('Error duplicating role:', error);
          this.showError('Failed to duplicate role');
        },
      })
      .add(() => {
        this.isLoading = false;
      });
  }

  private showSuccess(message: string): void {
    this.snackBar.open(message, 'Close', {
      duration: 3000,
      panelClass: ['snackbar-success'],
    });
  }

  private showError(message: string): void {
    this.snackBar.open(message, 'Close', {
      duration: 5000,
      panelClass: ['snackbar-error'],
    });
  }

  viewAllPermissions(role: Role): void {
    // Open a dialog showing all permissions for this role
    const dialogRef = this.dialog.open(PermissionsDialogComponent, {
      width: '600px',
      maxWidth: '90vw',
      data: { role, permissions: this.getPermissionObjects(role) },
      disableClose: false,
    });
  }

  viewRoleDetails(role: Role): void {
    // Open a detailed view of the role
    const dialogRef = this.dialog.open(RoleDetailsDialogComponent, {
      width: '700px',
      maxWidth: '90vw',
      data: { role, permissions: this.getPermissionObjects(role) },
      disableClose: false,
    });

    dialogRef.afterClosed().subscribe((result) => {
      if (result === 'edit') {
        this.openEditDialog(role);
      }
    });
  }
}

// Permissions Dialog Component
@Component({
  selector: 'app-permissions-dialog',
  standalone: true,
  imports: [CommonModule, MatDialogModule, MatButtonModule, MatIconModule, MatChipsModule],
  template: `
    <div class="p-6 max-h-[80vh] overflow-y-auto">
      <div class="flex items-center gap-3 mb-6">
        <div
          class="flex items-center justify-center w-12 h-12 rounded-full bg-blue-100 text-blue-600"
        >
          <mat-icon>security</mat-icon>
        </div>
        <div>
          <h2 class="text-xl font-bold text-gray-900">Permissions for {{ data.role.name }}</h2>
          <p class="text-sm text-gray-600 mt-1">All permissions assigned to this role</p>
        </div>
      </div>

      <div class="space-y-4">
        <div
          *ngFor="let perm of data.permissions"
          class="flex items-center gap-3 p-3 rounded-lg bg-gray-50"
        >
          <div
            class="flex items-center justify-center w-8 h-8 rounded-lg bg-blue-100 text-blue-600"
          >
            <mat-icon class="text-sm">{{ getActionIcon(perm.actionType) }}</mat-icon>
          </div>
          <div class="flex-1">
            <div class="font-medium text-gray-900">{{ perm.name }}</div>
            <div class="text-sm text-gray-600">{{ perm.description }}</div>
          </div>
          <mat-chip class="text-xs">{{ perm.resourceType }}</mat-chip>
        </div>
      </div>

      <div class="flex justify-end mt-6">
        <button mat-button mat-dialog-close class="px-4 py-2">Close</button>
      </div>
    </div>
  `,
})
export class PermissionsDialogComponent {
  constructor(@Inject(MAT_DIALOG_DATA) public data: { role: Role; permissions: Permission[] }) {}

  getActionIcon(actionType: string): string {
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
}

// Role Details Dialog Component
@Component({
  selector: 'app-role-details-dialog',
  standalone: true,
  imports: [CommonModule, MatDialogModule, MatButtonModule, MatIconModule, MatChipsModule],
  template: `
    <div class="p-6 max-h-[80vh] overflow-y-auto">
      <div class="flex items-center gap-3 mb-6">
        <div
          class="flex items-center justify-center w-12 h-12 rounded-full bg-blue-100 text-blue-600"
        >
          <mat-icon>visibility</mat-icon>
        </div>
        <div>
          <h2 class="text-xl font-bold text-gray-900">{{ data.role.name }}</h2>
          <p class="text-sm text-gray-600 mt-1">Role details and permissions overview</p>
        </div>
      </div>

      <div class="space-y-6">
        <!-- Basic Info -->
        <div class="grid grid-cols-2 gap-4">
          <div class="p-4 rounded-lg bg-gray-50">
            <div class="text-sm text-gray-600 mb-1">Role ID</div>
            <div class="font-semibold text-gray-900">{{ data.role.id }}</div>
          </div>
          <div class="p-4 rounded-lg bg-gray-50">
            <div class="text-sm text-gray-600 mb-1">Total Permissions</div>
            <div class="font-semibold text-gray-900">{{ data.permissions.length }}</div>
          </div>
        </div>

        <!-- Description -->
        <div>
          <label class="text-sm font-medium text-gray-700 mb-2 block">Description</label>
          <p class="text-gray-600 bg-gray-50 p-3 rounded-lg">
            {{ data.role.description || 'No description provided.' }}
          </p>
        </div>

        <!-- Permissions by Resource Type -->
        <div>
          <label class="text-sm font-medium text-gray-700 mb-3 block"
            >Permissions by Resource Type</label
          >
          <div class="space-y-3">
            <div *ngFor="let group of getGroupedPermissions()" class="p-4 rounded-lg bg-gray-50">
              <div class="flex items-center gap-2 mb-2">
                <mat-icon class="text-sm text-blue-600">{{
                  getResourceIcon(group.resourceType)
                }}</mat-icon>
                <span class="font-medium text-gray-900">{{ group.resourceType }}</span>
                <mat-chip class="text-xs ml-auto">{{ group.permissions.length }}</mat-chip>
              </div>
              <div class="flex flex-wrap gap-2">
                <mat-chip *ngFor="let perm of group.permissions.slice(0, 3)" class="text-xs">
                  {{ perm.name }}
                </mat-chip>
                <mat-chip *ngIf="group.permissions.length > 3" class="text-xs">
                  +{{ group.permissions.length - 3 }} more
                </mat-chip>
              </div>
            </div>
          </div>
        </div>
      </div>

      <div class="flex justify-end gap-3 mt-6 pt-4 border-t border-gray-200">
        <button mat-button mat-dialog-close class="px-4 py-2">Close</button>
        <button mat-raised-button color="primary" (click)="editRole()" class="px-4 py-2">
          <mat-icon class="text-sm mr-1">edit</mat-icon>
          Edit Role
        </button>
      </div>
    </div>
  `,
})
export class RoleDetailsDialogComponent {
  constructor(
    private dialogRef: MatDialogRef<RoleDetailsDialogComponent>,
    @Inject(MAT_DIALOG_DATA) public data: { role: Role; permissions: Permission[] },
  ) {}

  getGroupedPermissions(): { resourceType: string; permissions: Permission[] }[] {
    const groups: { [key: string]: Permission[] } = {};
    this.data.permissions.forEach((perm) => {
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

  editRole(): void {
    this.dialogRef.close('edit');
  }
}

// Confirmation Dialog Component
@Component({
  selector: 'app-confirm-dialog',
  standalone: true,
  imports: [CommonModule, MatDialogModule, MatButtonModule, MatIconModule],
  template: `
    <div class="p-6">
      <div class="flex items-center gap-3 mb-4">
        <div
          class="flex items-center justify-center w-10 h-10 rounded-full bg-red-100 text-red-600"
        >
          <mat-icon>warning</mat-icon>
        </div>
        <div>
          <h2 class="text-lg font-semibold text-gray-900">{{ data.title }}</h2>
        </div>
      </div>

      <p class="text-gray-600 mb-6">{{ data.message }}</p>

      <div class="flex justify-end gap-3">
        <button mat-button mat-dialog-close class="px-4 py-2">Cancel</button>
        <button
          mat-raised-button
          [color]="data.confirmColor || 'primary'"
          [mat-dialog-close]="true"
          class="px-4 py-2"
        >
          {{ data.confirmText || 'Confirm' }}
        </button>
      </div>
    </div>
  `,
})
export class ConfirmDialogComponent {
  constructor(@Inject(MAT_DIALOG_DATA) public data: any) {}
}
