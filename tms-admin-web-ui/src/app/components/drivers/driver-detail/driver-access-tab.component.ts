import { CommonModule } from '@angular/common';
import { Component, EventEmitter, Input, Output } from '@angular/core';
import { ReactiveFormsModule, FormGroup } from '@angular/forms';
import { MatProgressSpinnerModule } from '@angular/material/progress-spinner';

@Component({
  standalone: true,
  selector: 'app-driver-access-tab',
  imports: [CommonModule, ReactiveFormsModule, MatProgressSpinnerModule],
  template: `
    <div class="bg-white rounded-lg shadow-sm p-8">
      <form [formGroup]="accountForm" (ngSubmit)="submitAccount.emit()" class="grid grid-cols-1 gap-6 md:grid-cols-2">
        <div *ngIf="accountLoading" class="flex items-center justify-center md:col-span-2">
          <mat-progress-spinner diameter="32" mode="indeterminate"></mat-progress-spinner>
        </div>

        <div
          *ngIf="!accountLoading && accountLoadMessage"
          class="md:col-span-2 px-4 py-2 text-sm text-blue-800 bg-blue-50 border border-blue-200 rounded"
        >
          {{ accountLoadMessage }}
        </div>

        <div>
          <label for="username" class="block text-sm font-medium text-gray-700">Username</label>
          <input
            id="username"
            formControlName="username"
            type="text"
            class="w-full mt-1 border-gray-300 rounded-md shadow-sm focus:ring-blue-500 focus:border-blue-500"
            placeholder="driver01"
            [readonly]="isEditMode"
            autocomplete="off"
          />
          <div *ngIf="accountForm.get('username')?.touched && accountForm.get('username')?.invalid" class="mt-1 text-sm text-red-500">
            Username is required.
          </div>
        </div>

        <div>
          <label for="email" class="block text-sm font-medium text-gray-700">Email</label>
          <input
            id="email"
            formControlName="email"
            type="email"
            class="w-full mt-1 border-gray-300 rounded-md shadow-sm focus:ring-blue-500 focus:border-blue-500"
            placeholder="driver@example.com"
            autocomplete="off"
          />
          <div *ngIf="accountForm.get('email')?.touched && accountForm.get('email')?.invalid" class="mt-1 text-sm text-red-500">
            <span *ngIf="accountForm.get('email')?.errors?.['required']">Email is required.</span>
            <span *ngIf="accountForm.get('email')?.errors?.['email']">Invalid email format.</span>
          </div>
        </div>

        <div>
          <label for="password" class="block text-sm font-medium text-gray-700">
            Password
            <span *ngIf="isEditMode" class="text-xs text-gray-500">(leave blank to keep current password)</span>
          </label>
          <input
            id="password"
            formControlName="password"
            type="password"
            class="w-full mt-1 border-gray-300 rounded-md shadow-sm focus:ring-blue-500 focus:border-blue-500"
            placeholder="********"
            autocomplete="new-password"
          />
        </div>

        <div class="flex justify-between mt-6 md:col-span-2">
          <button
            type="button"
            (click)="cancel.emit()"
            class="px-5 py-2 text-gray-700 bg-gray-200 rounded shadow hover:bg-gray-300"
          >
            Cancel
          </button>
          <button
            type="submit"
            [disabled]="accountForm.invalid || accountForm.disabled || accountLoading"
            class="px-6 py-2 text-white bg-blue-600 rounded shadow hover:bg-blue-700 disabled:opacity-50"
          >
            Save Account
          </button>
        </div>
      </form>
    </div>
  `,
})
export class DriverAccessTabComponent {
  @Input({ required: true }) accountForm!: FormGroup;
  @Input() accountLoading = false;
  @Input() accountLoadMessage = '';
  @Input() isEditMode = false;

  @Output() submitAccount = new EventEmitter<void>();
  @Output() cancel = new EventEmitter<void>();
}
