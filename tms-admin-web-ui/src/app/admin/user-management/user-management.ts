/* eslint-disable @typescript-eslint/consistent-type-imports */
import { CommonModule } from '@angular/common';
import { Component, Inject, inject, OnInit } from '@angular/core';
import { FormControl, FormGroup } from '@angular/forms';
import { ReactiveFormsModule, Validators, FormBuilder } from '@angular/forms';
import { MatButtonModule } from '@angular/material/button';
import { MatDialog, MatDialogModule, MAT_DIALOG_DATA } from '@angular/material/dialog';
import { MatFormFieldModule } from '@angular/material/form-field';
import { MatIconModule } from '@angular/material/icon';
import { MatInputModule } from '@angular/material/input';
import { MatSelectModule } from '@angular/material/select';
import { MatSlideToggleModule } from '@angular/material/slide-toggle';
import { MatSnackBar, MatSnackBarModule } from '@angular/material/snack-bar';
import { MatTooltipModule } from '@angular/material/tooltip';

import { RoleService } from '../../services/role.service';
import { UserService, type UserDto, type RegisterRequest } from '../../services/user.service';
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
    MatSlideToggleModule,
    MatSnackBarModule,
    MatTooltipModule,
    ReactiveFormsModule,
  ],
  templateUrl: './user-management.html',
  styleUrl: './user-management.css',
})
export class UserManagement implements OnInit {
  users: UserDto[] = [];
  roles: any[] = [];
  searchControl = new FormControl('');
  isLoading = false;

  private confirm = inject(ConfirmService);
  private snackBar = inject(MatSnackBar);

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

  get filteredUsers(): UserDto[] {
    const term = (this.searchControl.value ?? '').toLowerCase().trim();
    if (!term) return this.users;
    return this.users.filter(
      (u) =>
        u.username.toLowerCase().includes(term) ||
        u.email.toLowerCase().includes(term) ||
        u.roles.some((r) => r.toLowerCase().includes(term)),
    );
  }

  get activeCount(): number {
    return this.users.filter((u) => u.enabled).length;
  }

  get inactiveCount(): number {
    return this.users.filter((u) => !u.enabled).length;
  }

  loadUsers(): void {
    this.isLoading = true;
    this.userService.getAllUsers().subscribe({
      next: (users) => {
        this.users = users;
        this.isLoading = false;
      },
      error: () => {
        this.snackBar.open('Failed to load users', 'Dismiss', { duration: 4000 });
        this.isLoading = false;
      },
    });
  }

  loadRoles(): void {
    this.roleService.getAllRoles().subscribe({
      next: (roles) => (this.roles = roles),
      error: () => this.snackBar.open('Failed to load roles', 'Dismiss', { duration: 4000 }),
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
          next: () => {
            this.loadUsers();
            this.snackBar.open('User created successfully', 'Dismiss', { duration: 3000 });
          },
          error: (err) => {
            const msg = err?.error?.error ?? 'Failed to create user';
            this.snackBar.open(msg, 'Dismiss', { duration: 5000 });
          },
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
          next: () => {
            this.loadUsers();
            this.snackBar.open('User updated successfully', 'Dismiss', { duration: 3000 });
          },
          error: (err) => {
            const msg = err?.error?.error ?? 'Failed to update user';
            this.snackBar.open(msg, 'Dismiss', { duration: 5000 });
          },
        });
      }
    });
  }

  toggleStatus(user: UserDto): void {
    const newStatus = !user.enabled;
    this.userService.toggleStatus(user.id, newStatus).subscribe({
      next: (res) => {
        user.enabled = newStatus;
        this.snackBar.open(res.message, 'Dismiss', { duration: 3000 });
      },
      error: () =>
        this.snackBar.open(
          `Failed to ${newStatus ? 'enable' : 'disable'} user`,
          'Dismiss',
          { duration: 4000 },
        ),
    });
  }

  async deleteUser(user: UserDto): Promise<void> {
    if (!(await this.confirm.confirm(`Delete user "${user.username}"? This cannot be undone.`))) {
      return;
    }
    this.userService.deleteUser(user.id).subscribe({
      next: () => {
        this.loadUsers();
        this.snackBar.open('User deleted', 'Dismiss', { duration: 3000 });
      },
      error: () => this.snackBar.open('Failed to delete user', 'Dismiss', { duration: 4000 }),
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
        <mat-form-field appearance="outline" class="w-full">
          <mat-label>Username</mat-label>
          <input matInput formControlName="username" placeholder="Enter username" />
          <mat-icon matPrefix fontIcon="person"></mat-icon>
          <mat-error *ngIf="userForm.get('username')?.hasError('required')">Required</mat-error>
          <mat-error *ngIf="userForm.get('username')?.hasError('minlength')">Min 3 characters</mat-error>
        </mat-form-field>

        <mat-form-field appearance="outline" class="w-full">
          <mat-label>Email</mat-label>
          <input matInput formControlName="email" type="email" placeholder="Enter email" />
          <mat-icon matPrefix fontIcon="email"></mat-icon>
          <mat-error *ngIf="userForm.get('email')?.hasError('required')">Required</mat-error>
          <mat-error *ngIf="userForm.get('email')?.hasError('email')">Invalid email</mat-error>
        </mat-form-field>

        <mat-form-field appearance="outline" class="w-full">
          <mat-label>Password</mat-label>
          <input
            matInput
            formControlName="password"
            type="password"
            [placeholder]="data.user ? 'Leave blank to keep current' : 'Enter password'"
          />
          <mat-icon matPrefix fontIcon="lock"></mat-icon>
          <mat-hint *ngIf="data.user">Leave blank to keep current password</mat-hint>
          <mat-error *ngIf="userForm.get('password')?.hasError('minlength')">Min 6 characters</mat-error>
        </mat-form-field>

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
          <mat-error *ngIf="userForm.get('roles')?.hasError('required')">Select at least one role</mat-error>
        </mat-form-field>
      </form>

      <div class="flex justify-end gap-3 mt-6 pt-4 border-t">
        <button mat-button mat-dialog-close>Cancel</button>
        <button
          mat-raised-button
          color="primary"
          [mat-dialog-close]="userForm.value"
          [disabled]="userForm.invalid"
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
      password: ['', data.user ? [Validators.minLength(6)] : [Validators.required, Validators.minLength(6)]],
      roles: [data.user?.roles || [], Validators.required],
    });
  }
}
