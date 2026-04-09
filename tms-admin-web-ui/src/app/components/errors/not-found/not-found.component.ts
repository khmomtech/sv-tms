/* eslint-disable @typescript-eslint/consistent-type-imports */
import { Component } from '@angular/core';
import { MatButtonModule } from '@angular/material/button';
import { MatCardModule } from '@angular/material/card';
import { Router } from '@angular/router';

@Component({
  selector: 'app-not-found',
  standalone: true,
  imports: [MatCardModule, MatButtonModule],
  template: `
    <div class="not-found-container">
      <mat-card class="not-found-card">
        <mat-card-header>
          <mat-card-title>Page Not Found</mat-card-title>
          <mat-card-subtitle>The page you're looking for doesn't exist</mat-card-subtitle>
        </mat-card-header>
        <mat-card-content>
          <p>
            The page you requested could not be found. Please check the URL or navigate back to the
            application.
          </p>
        </mat-card-content>
        <mat-card-actions>
          <button mat-raised-button color="primary" (click)="goToDashboard()">
            Go to Dashboard
          </button>
          <button mat-button (click)="goBack()">Go Back</button>
        </mat-card-actions>
      </mat-card>
    </div>
  `,
  styles: [
    `
      .not-found-container {
        display: flex;
        justify-content: center;
        align-items: center;
        height: 100vh;
        background-color: #f5f5f5;
      }
      .not-found-card {
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
export class NotFoundComponent {
  constructor(private router: Router) {}

  goBack(): void {
    window.history.back();
  }

  goToDashboard(): void {
    this.router.navigate(['/dashboard']);
  }
}
