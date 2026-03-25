/* eslint-disable @typescript-eslint/consistent-type-imports */
import { Component } from '@angular/core';
import { MatButtonModule } from '@angular/material/button';
import { MatCardModule } from '@angular/material/card';
import { Router } from '@angular/router';

@Component({
  selector: 'app-unauthorized',
  standalone: true,
  imports: [MatCardModule, MatButtonModule],
  template: `
    <div class="unauthorized-container">
      <mat-card class="unauthorized-card">
        <mat-card-header>
          <mat-card-title>Access Denied</mat-card-title>
          <mat-card-subtitle>You don't have permission to access this page</mat-card-subtitle>
        </mat-card-header>
        <mat-card-content>
          <p>Please contact your administrator if you believe this is an error.</p>
        </mat-card-content>
        <mat-card-actions>
          <button mat-raised-button color="primary" (click)="goBack()">Go Back</button>
          <button mat-button (click)="goToDashboard()">Go to Dashboard</button>
        </mat-card-actions>
      </mat-card>
    </div>
  `,
  styles: [
    `
      .unauthorized-container {
        display: flex;
        justify-content: center;
        align-items: center;
        height: 100vh;
        background-color: #f5f5f5;
      }
      .unauthorized-card {
        max-width: 400px;
        width: 100%;
        text-align: center;
      }
      mat-card-actions {
        justify-content: center;
        gap: 16px;
      }
    `,
  ],
})
export class UnauthorizedComponent {
  constructor(private router: Router) {}

  goBack(): void {
    window.history.back();
  }

  goToDashboard(): void {
    this.router.navigate(['/dashboard']);
  }
}
