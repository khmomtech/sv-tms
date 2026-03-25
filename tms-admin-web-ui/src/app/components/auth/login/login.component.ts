import { CommonModule } from '@angular/common';
import { Component } from '@angular/core';
import { FormsModule } from '@angular/forms';
import { TranslateModule, TranslateService } from '@ngx-translate/core';
import { Router } from '@angular/router';

import { environment } from '../../../environments/environment';
import { AuthService } from '../../../services/auth.service';

@Component({
  selector: 'app-login',
  standalone: true, //  Ensure it's standalone
  imports: [CommonModule, FormsModule, TranslateModule], //  Import FormsModule
  templateUrl: './login.component.html',
  styleUrls: ['./login.component.css'],
})
export class LoginComponent {
  username: string = '';
  password: string = '';
  errorMessage: string = '';

  // Expose URLs to template
  readonly privacyPolicyUrl = environment.privacyPolicyUrl;
  readonly termsOfServiceUrl = environment.termsOfServiceUrl;

  constructor(
    private authService: AuthService,
    private router: Router,
    private translate: TranslateService,
  ) {}

  onLogin(): void {
    if (!this.username || !this.password) {
      this.errorMessage = this.translate.instant('auth.login.username_and_password_required');
      return;
    }

    this.authService.login(this.username, this.password).subscribe({
      next: (response) => {
        // AuthService already persisted token + user in its tap.
        if (response?.user?.roles?.length) {
          this.redirectUser(response.user.roles);
        } else {
          this.errorMessage = this.translate.instant('auth.login.roles_missing');
        }
      },
      error: (err) => {
        const backendMsg = err?.error?.message || err?.error?.error || err?.message;
        if (err?.status === 401 || err?.status === 403) {
          this.errorMessage =
            backendMsg || this.translate.instant('auth.login.invalid_credentials');
        } else if (err?.status === 0) {
          this.errorMessage = this.translate.instant('auth.login.cannot_reach_server');
        } else {
          this.errorMessage = backendMsg || this.translate.instant('auth.login.login_failed');
        }
        console.error('[Login] Error during login:', err);
      },
    });
  }

  /**
   *  Redirect user based on their roles
   */
  redirectUser(roles: string[]): void {
    if (roles.includes('ADMIN')) {
      this.router.navigate(['/dashboard']);
    } else if (roles.includes('DRIVER')) {
      this.router.navigate(['/driver-dashboard']);
    } else {
      this.router.navigate(['/dashboard']); // Default dashboard
    }
  }
}
