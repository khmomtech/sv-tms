/* eslint-disable @typescript-eslint/consistent-type-imports */
import { CommonModule } from '@angular/common';
import { Component, Inject, inject, OnInit } from '@angular/core';
import { FormGroup } from '@angular/forms';
import { ReactiveFormsModule, Validators, FormBuilder } from '@angular/forms';
import { MatButtonModule } from '@angular/material/button';
import { MatDialog, MatDialogModule, MAT_DIALOG_DATA } from '@angular/material/dialog';
import { MatFormFieldModule } from '@angular/material/form-field';
import { MatIconModule } from '@angular/material/icon';
import { MatInputModule } from '@angular/material/input';
import { MatSelectModule } from '@angular/material/select';

import { RoleService } from '../../services/role.service';
import { UserService, type UserDto, RegisterRequest } from '../../services/user.service';
import { ConfirmService } from '../../services/confirm.service';

@Component({
  selector: 'app-user-management',
  standalone: true,
  imports: [
    CommonModule,
    MatDialogModule,
    MatFormFieldModule,
    MatInputModule,
    MatSelectModule,
    MatIconModule,
    MatButtonModule,
    ReactiveFormsModule,
  ],
  templateUrl: './user-management.html',
  styleUrl: './user-management.css',
})
export class UserManagement implements OnInit {
  users: UserDto[] = [];
  roles: any[] = [];
  private confirm = inject(ConfirmService);

  constructor(
    private userService: UserService,
    private roleService: RoleService,
    private dialog: MatDialog,
    private fb: FormBuilder,
  ) {}

  ngOnInit(): void {
    this.loadUsers();
    this.loadRoles();
  }

  loadUsers(): void {
    this.userService.getAllUsers().subscribe({
      next: (users) => (this.users = users),
      error: (error) => console.error('Error loading users:', error),
    });
  }

  loadRoles(): void {
    this.roleService.getAllRoles().subscribe({
      next: (roles) => (this.roles = roles),
      error: (error) => console.error('Error loading roles:', error),
    });
  }

  openCreateDialog(): void {
    const dialogRef = this.dialog.open(UserDialogComponent, {
      width: '500px',
      data: { roles: this.roles },
    });

    dialogRef.afterClosed().subscribe((result) => {
      if (result) {
        this.userService.createUser(result).subscribe({
          next: () => this.loadUsers(),
          error: (error) => console.error('Error creating user:', error),
        });
      }
    });
  }

  openEditDialog(user: UserDto): void {
    const dialogRef = this.dialog.open(UserDialogComponent, {
      width: '500px',
      data: { user, roles: this.roles },
    });

    dialogRef.afterClosed().subscribe((result) => {
      if (result) {
        this.userService.updateUser(user.id, result).subscribe({
          next: () => this.loadUsers(),
          error: (error) => console.error('Error updating user:', error),
        });
      }
    });
  }

  async deleteUser(user: UserDto): Promise<void> {
    if (!(await this.confirm.confirm(`Are you sure you want to delete user "${user.username}"?`))) {
      return;
    }
    this.userService.deleteUser(user.id).subscribe({
      next: () => this.loadUsers(),
      error: (error) => console.error('Error deleting user:', error),
    });
  }
}

@Component({
  selector: 'app-user-dialog',
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
        <mat-icon>{{ data.user ? 'edit' : 'add' }}</mat-icon>
        {{ data.user ? 'Edit User' : 'Create User' }}
      </h2>

      <form [formGroup]="userForm" class="space-y-4">
        <div>
          <mat-form-field appearance="outline" class="w-full">
            <mat-label>Username</mat-label>
            <input matInput formControlName="username" placeholder="Enter username" />
            <mat-icon matPrefix fontIcon="person"></mat-icon>
          </mat-form-field>
        </div>

        <div>
          <mat-form-field appearance="outline" class="w-full">
            <mat-label>Email</mat-label>
            <input
              matInput
              formControlName="email"
              type="email"
              placeholder="Enter email address"
            />
            <mat-icon matPrefix fontIcon="email"></mat-icon>
          </mat-form-field>
        </div>

        <div>
          <mat-form-field appearance="outline" class="w-full">
            <mat-label>Password</mat-label>
            <input
              matInput
              formControlName="password"
              type="password"
              [placeholder]="data.user ? 'Leave blank to keep current password' : 'Enter password'"
            />
            <mat-icon matPrefix fontIcon="lock"></mat-icon>
          </mat-form-field>
        </div>

        <div>
          <mat-form-field appearance="outline" class="w-full">
            <mat-label>Roles</mat-label>
            <mat-select formControlName="roles" multiple placeholder="Select roles">
              <mat-option *ngFor="let role of data.roles" [value]="role.name">
                <div class="flex items-center gap-2">
                  <mat-icon fontIcon="group" class="text-sm"></mat-icon>
                  {{ role.name }}
                </div>
              </mat-option>
            </mat-select>
          </mat-form-field>
        </div>
      </form>

      <div class="flex justify-end gap-3 mt-6 pt-4 border-t">
        <button mat-button mat-dialog-close class="px-4 py-2">Cancel</button>
        <button
          mat-raised-button
          color="primary"
          [mat-dialog-close]="userForm.value"
          [disabled]="userForm.invalid"
          class="px-6 py-2"
        >
          {{ data.user ? 'Update' : 'Create' }}
        </button>
      </div>
    </div>
  `,
})
export class UserDialogComponent {
  userForm: FormGroup;

  constructor(
    private fb: FormBuilder,
    @Inject(MAT_DIALOG_DATA) public data: any,
  ) {
    this.userForm = this.fb.group({
      username: [data.user?.username || '', [Validators.required, Validators.minLength(3)]],
      email: [data.user?.email || '', [Validators.required, Validators.email]],
      password: ['', data.user ? [] : [Validators.required, Validators.minLength(6)]],
      roles: [data.user?.roles || [], Validators.required],
    });
  }
}
