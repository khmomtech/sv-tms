/* eslint-disable @typescript-eslint/consistent-type-imports */
import { CommonModule } from '@angular/common';
import { OnInit } from '@angular/core';
import { Component, inject } from '@angular/core';
import { ConfirmService } from '@services/confirm.service';
import { FormsModule } from '@angular/forms';

import type { Permission } from '../../models/permission.model';
import type { Role } from '../../models/role.model';
import { PermissionService } from '../../services/permission.service';
import { RoleService } from '../../services/role.service';

@Component({
  selector: 'app-roles',
  standalone: true,
  imports: [CommonModule, FormsModule],
  templateUrl: './roles.component.html',
  styleUrls: ['./roles.component.css'],
})
export class RolesComponent implements OnInit {
  private confirm = inject(ConfirmService);

  roles: Role[] = [];
  permissions: Permission[] = [];
  newRole: Role = { id: 0, name: '', description: '', permissions: '' };
  editingRole: Role | null = null;
  selectedPermissions: number[] = [];
  loading = false;
  error: string | null = null;

  constructor(
    private roleService: RoleService,
    private permissionService: PermissionService,
  ) {}

  ngOnInit(): void {
    this.loadRoles();
    this.loadPermissions();
  }

  loadRoles(): void {
    this.loading = true;
    this.error = null;

    this.roleService.getAllRoles().subscribe({
      next: (roles) => {
        this.roles = roles;
        this.loading = false;
      },
      error: (error: any) => {
        this.error = 'Failed to load roles';
        this.loading = false;
        console.error('Error loading roles:', error);
      },
    });
  }

  loadPermissions(): void {
    this.loading = true;
    this.error = null;

    this.permissionService.getAllPermissions().subscribe({
      next: (permissions) => {
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

  createRole(): void {
    if (!this.newRole.name) {
      this.error = 'Role name is required';
      return;
    }

    this.loading = true;
    this.error = null;

    // Add selected permissions to the role
    if (this.selectedPermissions.length > 0) {
      this.newRole.permissions = this.selectedPermissions.join(',');
    }

    this.roleService.createRole(this.newRole).subscribe({
      next: (role) => {
        this.roles.push(role);
        this.newRole = { id: 0, name: '', description: '', permissions: '' };
        this.selectedPermissions = [];
        this.loading = false;
      },
      error: (error: any) => {
        this.error = 'Failed to create role';
        this.loading = false;
        console.error('Error creating role:', error);
      },
    });
  }

  updateRole(): void {
    if (!this.editingRole || !this.editingRole.name) {
      this.error = 'Role name is required';
      return;
    }

    this.loading = true;
    this.error = null;

    // Add selected permissions to the role
    if (this.selectedPermissions.length > 0) {
      this.editingRole.permissions = this.selectedPermissions.join(',');
    }

    this.roleService.updateRole(this.editingRole).subscribe({
      next: (role) => {
        const index = this.roles.findIndex((r) => r.id === role.id);
        if (index !== -1) {
          this.roles[index] = role;
        }
        this.editingRole = null;
        this.selectedPermissions = [];
        this.loading = false;
      },
      error: (error: any) => {
        this.error = 'Failed to update role';
        this.loading = false;
        console.error('Error updating role:', error);
      },
    });
  }

  async deleteRole(id: number): Promise<void> {
    if (!(await this.confirm.confirm('Are you sure you want to delete this role?'))) {
      return;
    }

    this.loading = true;
    this.error = null;

    this.roleService.deleteRole(id).subscribe({
      next: () => {
        this.roles = this.roles.filter((r) => r.id !== id);
        this.loading = false;
      },
      error: (error: any) => {
        this.error = 'Failed to delete role';
        this.loading = false;
        console.error('Error deleting role:', error);
      },
    });
  }

  startEditing(role: Role): void {
    this.editingRole = { ...role };
    // Parse permissions for editing
    if (role.permissions) {
      this.selectedPermissions = role.permissions.split(',').map(Number);
    } else {
      this.selectedPermissions = [];
    }
  }

  cancelEditing(): void {
    this.editingRole = null;
    this.selectedPermissions = [];
  }

  togglePermission(permissionId: number): void {
    const index = this.selectedPermissions.indexOf(permissionId);
    if (index > -1) {
      this.selectedPermissions.splice(index, 1);
    } else {
      this.selectedPermissions.push(permissionId);
    }
  }

  isPermissionSelected(permissionId: number): boolean {
    return this.selectedPermissions.includes(permissionId);
  }
}
