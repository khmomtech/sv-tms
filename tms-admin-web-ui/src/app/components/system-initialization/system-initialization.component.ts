import { CommonModule } from '@angular/common';
import type { OnInit } from '@angular/core';
import { Component } from '@angular/core';
import { MatButtonModule } from '@angular/material/button';
import { MatCardModule } from '@angular/material/card';
import { MatDividerModule } from '@angular/material/divider';
import { MatIconModule } from '@angular/material/icon';
import { MatListModule } from '@angular/material/list';
import { MatProgressSpinnerModule } from '@angular/material/progress-spinner';
// eslint-disable-next-line @typescript-eslint/consistent-type-imports
import { MatSnackBar, MatSnackBarModule } from '@angular/material/snack-bar';

// eslint-disable-next-line @typescript-eslint/consistent-type-imports
import { SystemInitializationService } from '../../services/system-initialization.service';
import type { SystemStatus } from '../../services/system-initialization.service';

@Component({
  selector: 'app-system-initialization',
  standalone: true,
  imports: [
    CommonModule,
    MatCardModule,
    MatButtonModule,
    MatIconModule,
    MatSnackBarModule,
    MatProgressSpinnerModule,
    MatListModule,
    MatDividerModule,
  ],
  template: `
    <div class="container mx-auto p-6">
      <div class="mb-6">
        <h2 class="text-3xl font-bold text-gray-900 mb-2">System Initialization</h2>
        <p class="text-gray-600">Initialize and manage system permissions, roles, and users</p>
      </div>

      <!-- System Status Card -->
      <mat-card class="mb-6">
        <mat-card-header>
          <mat-card-title class="flex items-center gap-2">
            <mat-icon [class]="systemStatus?.initialized ? 'text-green-600' : 'text-red-600'">
              {{ systemStatus?.initialized ? 'check_circle' : 'error' }}
            </mat-icon>
            System Status
          </mat-card-title>
        </mat-card-header>
        <mat-card-content>
          <div *ngIf="loading" class="flex items-center gap-2 py-4">
            <mat-spinner diameter="20"></mat-spinner>
            <span>Loading system status...</span>
          </div>

          <div *ngIf="!loading && systemStatus">
            <p class="mb-4">{{ systemStatus.message }}</p>
            <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
              <div class="bg-blue-50 p-4 rounded-lg">
                <h4 class="font-semibold text-blue-900 mb-2">Available Operations</h4>
                <ul class="text-sm text-blue-800 space-y-1">
                  <li>• Full System Initialization</li>
                  <li>• Permissions Management</li>
                  <li>• Roles Configuration</li>
                  <li>• Default Users Setup</li>
                </ul>
              </div>
              <div class="bg-green-50 p-4 rounded-lg">
                <h4 class="font-semibold text-green-900 mb-2">System Health</h4>
                <div class="flex items-center gap-2 text-sm">
                  <mat-icon class="text-green-600" style="font-size: 16px;">{{
                    systemStatus.initialized ? 'check' : 'close'
                  }}</mat-icon>
                  <span class="text-green-800">
                    {{ systemStatus.initialized ? 'System Operational' : 'Needs Initialization' }}
                  </span>
                </div>
              </div>
            </div>
          </div>
        </mat-card-content>
      </mat-card>

      <!-- Initialization Actions -->
      <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6 mb-6">
        <!-- Full System Initialization -->
        <mat-card class="initialization-card">
          <mat-card-header>
            <mat-card-title class="text-lg">
              <mat-icon class="text-purple-600 mr-2">settings_suggest</mat-icon>
              Complete Setup
            </mat-card-title>
          </mat-card-header>
          <mat-card-content>
            <p class="text-sm text-gray-600 mb-4">
              Initialize the entire system with all permissions, roles, and default users.
            </p>
            <button
              mat-raised-button
              color="primary"
              [disabled]="initializingSystem"
              (click)="initializeSystem()"
              class="w-full"
            >
              <mat-spinner *ngIf="initializingSystem" diameter="16" class="mr-2"></mat-spinner>
              <mat-icon *ngIf="!initializingSystem" class="mr-2">play_arrow</mat-icon>
              Initialize System
            </button>
          </mat-card-content>
        </mat-card>

        <!-- Permissions Only -->
        <mat-card class="initialization-card">
          <mat-card-header>
            <mat-card-title class="text-lg">
              <mat-icon class="text-blue-600 mr-2">security</mat-icon>
              Permissions
            </mat-card-title>
          </mat-card-header>
          <mat-card-content>
            <p class="text-sm text-gray-600 mb-4">
              Initialize all system permissions including core and extended permissions.
            </p>
            <button
              mat-raised-button
              color="accent"
              [disabled]="initializingPermissions"
              (click)="initializePermissions()"
              class="w-full"
            >
              <mat-spinner *ngIf="initializingPermissions" diameter="16" class="mr-2"></mat-spinner>
              <mat-icon *ngIf="!initializingPermissions" class="mr-2">key</mat-icon>
              Setup Permissions
            </button>
          </mat-card-content>
        </mat-card>

        <!-- Roles Only -->
        <mat-card class="initialization-card">
          <mat-card-header>
            <mat-card-title class="text-lg">
              <mat-icon class="text-green-600 mr-2">groups</mat-icon>
              Roles
            </mat-card-title>
          </mat-card-header>
          <mat-card-content>
            <p class="text-sm text-gray-600 mb-4">
              Setup all user roles (SUPERADMIN, ADMIN, MANAGER, DRIVER, CUSTOMER, USER).
            </p>
            <button
              mat-raised-button
              color="accent"
              [disabled]="initializingRoles"
              (click)="initializeRoles()"
              class="w-full"
            >
              <mat-spinner *ngIf="initializingRoles" diameter="16" class="mr-2"></mat-spinner>
              <mat-icon *ngIf="!initializingRoles" class="mr-2">admin_panel_settings</mat-icon>
              Setup Roles
            </button>
          </mat-card-content>
        </mat-card>

        <!-- Users Only -->
        <mat-card class="initialization-card">
          <mat-card-header>
            <mat-card-title class="text-lg">
              <mat-icon class="text-orange-600 mr-2">people</mat-icon>
              Users
            </mat-card-title>
          </mat-card-header>
          <mat-card-content>
            <p class="text-sm text-gray-600 mb-4">
              Create default users for testing and initial system access.
            </p>
            <button
              mat-raised-button
              color="accent"
              [disabled]="initializingUsers"
              (click)="initializeUsers()"
              class="w-full"
            >
              <mat-spinner *ngIf="initializingUsers" diameter="16" class="mr-2"></mat-spinner>
              <mat-icon *ngIf="!initializingUsers" class="mr-2">person_add</mat-icon>
              Create Users
            </button>
          </mat-card-content>
        </mat-card>
      </div>

      <!-- Default Users Information -->
      <mat-card>
        <mat-card-header>
          <mat-card-title class="flex items-center gap-2">
            <mat-icon class="text-blue-600">info</mat-icon>
            Default User Credentials
          </mat-card-title>
        </mat-card-header>
        <mat-card-content>
          <p class="text-sm text-gray-600 mb-4">
            After initialization, the following default users will be available:
          </p>

          <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
            <div class="bg-red-50 border border-red-200 p-4 rounded-lg">
              <h4 class="font-semibold text-red-900 mb-2 flex items-center gap-2">
                <mat-icon style="font-size: 16px;">admin_panel_settings</mat-icon>
                Super Administrator
              </h4>
              <div class="text-sm text-red-800">
                <p><strong>Username:</strong> superadmin</p>
                <p><strong>Password:</strong> super123</p>
                <p><strong>Role:</strong> SUPERADMIN</p>
                <p><strong>Access:</strong> All functions</p>
              </div>
            </div>

            <div class="bg-orange-50 border border-orange-200 p-4 rounded-lg">
              <h4 class="font-semibold text-orange-900 mb-2 flex items-center gap-2">
                <mat-icon style="font-size: 16px;">settings</mat-icon>
                Administrator
              </h4>
              <div class="text-sm text-orange-800">
                <p><strong>Username:</strong> admin</p>
                <p><strong>Password:</strong> admin123</p>
                <p><strong>Role:</strong> ADMIN</p>
                <p><strong>Access:</strong> System management</p>
              </div>
            </div>

            <div class="bg-blue-50 border border-blue-200 p-4 rounded-lg">
              <h4 class="font-semibold text-blue-900 mb-2 flex items-center gap-2">
                <mat-icon style="font-size: 16px;">supervisor_account</mat-icon>
                Manager
              </h4>
              <div class="text-sm text-blue-800">
                <p><strong>Username:</strong> manager</p>
                <p><strong>Password:</strong> manager123</p>
                <p><strong>Role:</strong> MANAGER</p>
                <p><strong>Access:</strong> Operations oversight</p>
              </div>
            </div>

            <div class="bg-green-50 border border-green-200 p-4 rounded-lg">
              <h4 class="font-semibold text-green-900 mb-2 flex items-center gap-2">
                <mat-icon style="font-size: 16px;">local_shipping</mat-icon>
                Driver
              </h4>
              <div class="text-sm text-green-800">
                <p><strong>Username:</strong> driver1</p>
                <p><strong>Password:</strong> driver123</p>
                <p><strong>Role:</strong> DRIVER</p>
                <p><strong>Access:</strong> Driver functions</p>
              </div>
            </div>

            <div class="bg-purple-50 border border-purple-200 p-4 rounded-lg">
              <h4 class="font-semibold text-purple-900 mb-2 flex items-center gap-2">
                <mat-icon style="font-size: 16px;">business</mat-icon>
                Customer
              </h4>
              <div class="text-sm text-purple-800">
                <p><strong>Username:</strong> customer1</p>
                <p><strong>Password:</strong> customer123</p>
                <p><strong>Role:</strong> CUSTOMER</p>
                <p><strong>Access:</strong> Customer portal</p>
              </div>
            </div>
          </div>

          <div class="mt-4 p-4 bg-yellow-50 border border-yellow-200 rounded-lg">
            <div class="flex items-start gap-2">
              <mat-icon class="text-yellow-600 mt-0.5" style="font-size: 16px;">warning</mat-icon>
              <div class="text-sm text-yellow-800">
                <p>
                  <strong>Security Notice:</strong> Please change these default passwords in
                  production environments.
                </p>
              </div>
            </div>
          </div>
        </mat-card-content>
      </mat-card>
    </div>
  `,
  styleUrl: './system-initialization.component.css',
})
export class SystemInitializationComponent implements OnInit {
  systemStatus: SystemStatus | null = null;
  loading = false;
  initializingSystem = false;
  initializingPermissions = false;
  initializingRoles = false;
  initializingUsers = false;

  constructor(
    private systemInitService: SystemInitializationService,
    private snackBar: MatSnackBar,
  ) {}

  ngOnInit(): void {
    this.loadSystemStatus();
  }

  loadSystemStatus(): void {
    this.loading = true;
    this.systemInitService.getSystemStatus().subscribe({
      next: (response) => {
        this.systemStatus = response.data || {
          initialized: false,
          message: response.message || 'Unknown status',
        };
        this.loading = false;
      },
      error: (error) => {
        console.error('Error loading system status:', error);
        this.loading = false;
        this.snackBar.open('Failed to load system status', 'Close', { duration: 3000 });
      },
    });
  }

  initializeSystem(): void {
    this.initializingSystem = true;
    this.systemInitService.initializeSystem().subscribe({
      next: () => {
        this.initializingSystem = false;
        this.snackBar.open('System initialized successfully!', 'Close', {
          duration: 5000,
          panelClass: ['success-snackbar'],
        });
        this.loadSystemStatus();
      },
      error: (error) => {
        console.error('Error initializing system:', error);
        this.initializingSystem = false;
        this.snackBar.open('Failed to initialize system', 'Close', { duration: 3000 });
      },
    });
  }

  initializePermissions(): void {
    this.initializingPermissions = true;
    this.systemInitService.initializePermissions().subscribe({
      next: () => {
        this.initializingPermissions = false;
        this.snackBar.open('Permissions initialized successfully!', 'Close', { duration: 3000 });
      },
      error: (error) => {
        console.error('Error initializing permissions:', error);
        this.initializingPermissions = false;
        this.snackBar.open('Failed to initialize permissions', 'Close', { duration: 3000 });
      },
    });
  }

  initializeRoles(): void {
    this.initializingRoles = true;
    this.systemInitService.initializeRoles().subscribe({
      next: () => {
        this.initializingRoles = false;
        this.snackBar.open('Roles initialized successfully!', 'Close', { duration: 3000 });
      },
      error: (error) => {
        console.error('Error initializing roles:', error);
        this.initializingRoles = false;
        this.snackBar.open('Failed to initialize roles', 'Close', { duration: 3000 });
      },
    });
  }

  initializeUsers(): void {
    this.initializingUsers = true;
    this.systemInitService.initializeUsers().subscribe({
      next: () => {
        this.initializingUsers = false;
        this.snackBar.open('Users initialized successfully!', 'Close', { duration: 3000 });
      },
      error: (error) => {
        console.error('Error initializing users:', error);
        this.initializingUsers = false;
        this.snackBar.open('Failed to initialize users', 'Close', { duration: 3000 });
      },
    });
  }
}
