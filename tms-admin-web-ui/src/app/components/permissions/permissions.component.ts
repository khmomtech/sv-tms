/* eslint-disable @typescript-eslint/consistent-type-imports */
import { CommonModule } from '@angular/common';
import { OnInit } from '@angular/core';
import { Component, inject } from '@angular/core';
import { ConfirmService } from '@services/confirm.service';
import { FormsModule } from '@angular/forms';

import type { Permission } from '../../models/permission.model';
import { PermissionService } from '../../services/permission.service';
@Component({
  selector: 'app-permissions',
  standalone: true,
  imports: [CommonModule, FormsModule],
  templateUrl: './permissions.component.html',
  styleUrls: ['./permissions.component.css'],
})
export class PermissionsComponent implements OnInit {
  private confirm = inject(ConfirmService);

  permissions: Permission[] = [];
  newPermission: Permission = {
    id: 0,
    name: '',
    description: '',
    resourceType: '',
    actionType: '',
  };
  editingPermission: Permission | null = null;
  loading = false;
  error: string | null = null;

  constructor(private permissionService: PermissionService) {}

  ngOnInit(): void {
    this.loadPermissions();
  }

  loadPermissions(): void {
    this.loading = true;
    this.error = null;

    this.permissionService.getAllPermissions().subscribe({
      next: (permissions: any) => {
        this.permissions = permissions;
        this.loading = false;
      },
      error: (error: any) => {
        this.error = 'Failed to load permissions';
        this.loading = false;
        console.error('Error loading permissions:', error);
      },
    });
  }

  createPermission(): void {
    if (!this.newPermission.name) {
      this.error = 'Permission name is required';
      return;
    }

    this.loading = true;
    this.error = null;

    this.permissionService.createPermission(this.newPermission).subscribe({
      next: (permission: any) => {
        this.permissions.push(permission);
        this.newPermission = { id: 0, name: '', description: '', resourceType: '', actionType: '' };
        this.loading = false;
      },
      error: (error: any) => {
        this.error = 'Failed to create permission';
        this.loading = false;
        console.error('Error creating permission:', error);
      },
    });
  }

  updatePermission(): void {
    if (!this.editingPermission || !this.editingPermission.name) {
      this.error = 'Permission name is required';
      return;
    }

    this.loading = true;
    this.error = null;

    this.permissionService.updatePermission(this.editingPermission).subscribe({
      next: (permission: any) => {
        const index = this.permissions.findIndex((p) => p.id === permission.id);
        if (index !== -1) {
          this.permissions[index] = permission;
        }
        this.editingPermission = null;
        this.loading = false;
      },
      error: (error: any) => {
        this.error = 'Failed to update permission';
        this.loading = false;
        console.error('Error updating permission:', error);
      },
    });
  }

  async deletePermission(id: number): Promise<void> {
    if (!(await this.confirm.confirm('Are you sure you want to delete this permission?'))) {
      return;
    }

    this.loading = true;
    this.error = null;

    this.permissionService.deletePermission(id).subscribe({
      next: () => {
        this.permissions = this.permissions.filter((p) => p.id !== id);
        this.loading = false;
      },
      error: (error: any) => {
        this.error = 'Failed to delete permission';
        this.loading = false;
        console.error('Error deleting permission:', error);
      },
    });
  }

  startEditing(permission: Permission): void {
    this.editingPermission = { ...permission };
  }

  cancelEditing(): void {
    this.editingPermission = null;
  }
}
