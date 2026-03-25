/* eslint-disable @typescript-eslint/consistent-type-imports */
import { CommonModule } from '@angular/common';
import { Component } from '@angular/core';
import { FormsModule } from '@angular/forms';

import { SsoService } from '../../services/sso.service';

@Component({
  selector: 'app-sso',
  standalone: true,
  imports: [CommonModule, FormsModule],
  templateUrl: './sso.component.html',
  styleUrls: ['./sso.component.css'],
})
export class SsoComponent {
  ssoToken: string = '';
  username: string = '';
  validationResult: any = null;
  loading = false;
  error: string | null = null;
  success: string | null = null;

  constructor(private ssoService: SsoService) {}

  validateToken(): void {
    if (!this.ssoToken) {
      this.error = 'Please enter an SSO token';
      return;
    }

    this.loading = true;
    this.error = null;
    this.success = null;

    this.ssoService.validateSsoToken(this.ssoToken).subscribe({
      next: (result: any) => {
        this.validationResult = result;
        this.loading = false;
        this.success = 'Token is valid';
      },
      error: (error: any) => {
        this.error = 'Invalid or expired SSO token';
        this.validationResult = null;
        this.loading = false;
        console.error('Error validating SSO token:', error);
      },
    });
  }

  createToken(): void {
    if (!this.username) {
      this.error = 'Please enter a username';
      return;
    }

    this.loading = true;
    this.error = null;
    this.success = null;

    this.ssoService.createSsoToken(this.username).subscribe({
      next: (result: any) => {
        this.ssoToken = result.ssoToken;
        this.loading = false;
        this.success = 'SSO token created successfully';
      },
      error: (error: any) => {
        this.error = 'Failed to create SSO token';
        this.loading = false;
        console.error('Error creating SSO token:', error);
      },
    });
  }

  clearToken(): void {
    this.ssoToken = '';
    this.validationResult = null;
    this.error = null;
    this.success = null;
  }

  copyToken(): void {
    if (this.ssoToken) {
      navigator.clipboard
        .writeText(this.ssoToken)
        .then(() => {
          this.success = 'Token copied to clipboard';
        })
        .catch(() => {
          this.error = 'Failed to copy token';
        });
    }
  }
}
