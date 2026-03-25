import { CommonModule } from '@angular/common';
import { Component } from '@angular/core';
import { MatIconModule } from '@angular/material/icon';
import { MatTabsModule } from '@angular/material/tabs';

import { DynamicPermissionManagementComponent } from '../../components/dynamic-permission-management/dynamic-permission-management.component';
import { PermissionManagement } from '../permission-management/permission-management';
import { RoleManagement } from '../role-management/role-management';
import { UserManagement } from '../user-management/user-management';
// import { ImageManagementComponent } from '../image-management/image-management.component';

@Component({
  selector: 'app-admin',
  standalone: true,
  imports: [
    CommonModule,
    MatTabsModule,
    MatIconModule,
    UserManagement,
    RoleManagement,
    PermissionManagement,
    DynamicPermissionManagementComponent,
    // ImageManagementComponent,
  ],
  templateUrl: './admin.html',
  styleUrl: './admin.css',
})
export class Admin {}
