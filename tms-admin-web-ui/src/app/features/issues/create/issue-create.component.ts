import { Component, OnInit } from '@angular/core';
import { CommonModule } from '@angular/common';
import { RouterModule, Router, ActivatedRoute } from '@angular/router';
import { FormBuilder, FormGroup, ReactiveFormsModule, Validators } from '@angular/forms';
import { IssueService } from '../services/issue.service';
import { Issue, IssueStatus, IssueCategory, IssuePriority } from '../models/issue.model';

@Component({
  selector: 'app-issue-create',
  standalone: true,
  imports: [CommonModule, RouterModule, ReactiveFormsModule],
  template: `
    <div class="issue-create-container">
      <!-- Header -->
      <div class="page-header">
        <div>
          <h1>{{ isEditMode ? 'Edit Issue' : 'Create New Issue' }}</h1>
          <p>{{ isEditMode ? 'Update issue details' : 'Report a new issue or feature request' }}</p>
        </div>
      </div>

      <!-- Form Card -->
      <div class="form-card">
        <form [formGroup]="issueForm" (ngSubmit)="onSubmit()">
          <div class="form-grid">
            <!-- Title -->
            <div class="form-group full-width">
              <label for="title">Title <span class="required">*</span></label>
              <input
                type="text"
                id="title"
                formControlName="title"
                class="form-control"
                placeholder="Brief description of the issue"
                [class.is-invalid]="
                  issueForm.get('title')?.invalid && issueForm.get('title')?.touched
                "
                [class.is-valid]="issueForm.get('title')?.valid && issueForm.get('title')?.touched"
              />
              <div
                class="invalid-feedback"
                *ngIf="issueForm.get('title')?.invalid && issueForm.get('title')?.touched"
              >
                <span *ngIf="issueForm.get('title')?.errors?.['required']">Title is required</span>
                <span *ngIf="issueForm.get('title')?.errors?.['maxlength']"
                  >Title cannot exceed 200 characters</span
                >
              </div>
            </div>

            <!-- Description -->
            <div class="form-group full-width">
              <label for="description">Description <span class="required">*</span></label>
              <textarea
                id="description"
                formControlName="description"
                class="form-control"
                rows="5"
                placeholder="Detailed description of the issue, steps to reproduce, or feature requirements"
                [class.is-invalid]="
                  issueForm.get('description')?.invalid && issueForm.get('description')?.touched
                "
                [class.is-valid]="
                  issueForm.get('description')?.valid && issueForm.get('description')?.touched
                "
              ></textarea>
              <div
                class="invalid-feedback"
                *ngIf="
                  issueForm.get('description')?.invalid && issueForm.get('description')?.touched
                "
              >
                <span *ngIf="issueForm.get('description')?.errors?.['required']"
                  >Description is required</span
                >
              </div>
            </div>

            <!-- Category -->
            <div class="form-group">
              <label for="category">Category <span class="required">*</span></label>
              <select
                id="category"
                formControlName="category"
                class="form-select"
                [class.is-invalid]="
                  issueForm.get('category')?.invalid && issueForm.get('category')?.touched
                "
                [class.is-valid]="
                  issueForm.get('category')?.valid && issueForm.get('category')?.touched
                "
              >
                <option value="">Select category...</option>
                <option *ngFor="let category of categories" [value]="category">
                  {{ formatEnumValue(category) }}
                </option>
              </select>
              <div
                class="invalid-feedback"
                *ngIf="issueForm.get('category')?.invalid && issueForm.get('category')?.touched"
              >
                <span>Category is required</span>
              </div>
            </div>

            <!-- Priority -->
            <div class="form-group">
              <label for="priority">Priority <span class="required">*</span></label>
              <select
                id="priority"
                formControlName="priority"
                class="form-select"
                [class.is-invalid]="
                  issueForm.get('priority')?.invalid && issueForm.get('priority')?.touched
                "
                [class.is-valid]="
                  issueForm.get('priority')?.valid && issueForm.get('priority')?.touched
                "
              >
                <option value="">Select priority...</option>
                <option *ngFor="let priority of priorities" [value]="priority">
                  {{ formatEnumValue(priority) }}
                </option>
              </select>
              <div
                class="invalid-feedback"
                *ngIf="issueForm.get('priority')?.invalid && issueForm.get('priority')?.touched"
              >
                <span>Priority is required</span>
              </div>
            </div>

            <!-- Status (Edit mode only) -->
            <div class="form-group" *ngIf="isEditMode">
              <label for="status">Status</label>
              <select id="status" formControlName="status" class="form-select">
                <option *ngFor="let status of statuses" [value]="status">
                  {{ formatEnumValue(status) }}
                </option>
              </select>
            </div>

            <!-- Assigned To -->
            <div class="form-group" [class.full-width]="!isEditMode">
              <label for="assignedTo">Assign To</label>
              <select id="assignedTo" formControlName="assignedTo" class="form-select">
                <option value="">Unassigned</option>
                <option *ngFor="let user of users" [value]="user">{{ user }}</option>
              </select>
            </div>

            <!-- Due Date -->
            <div class="form-group">
              <label for="dueDate">Due Date</label>
              <input
                type="date"
                id="dueDate"
                formControlName="dueDate"
                class="form-control"
                [min]="today"
              />
            </div>

            <!-- Tags -->
            <div class="form-group full-width">
              <label for="tags">Tags</label>
              <input
                type="text"
                id="tags"
                formControlName="tagsInput"
                class="form-control"
                placeholder="Enter tags separated by commas (e.g., bug, urgent, ui)"
              />
              <div class="tags-display" *ngIf="displayTags.length > 0">
                <span *ngFor="let tag of displayTags" class="tag">
                  {{ tag }}
                  <button type="button" (click)="removeTag(tag)" class="tag-remove">×</button>
                </span>
              </div>
            </div>
          </div>

          <!-- Form Actions -->
          <div class="form-actions">
            <button type="button" class="btn btn-secondary" (click)="onCancel()">
              <i class="fas fa-times"></i>
              Cancel
            </button>
            <button
              type="submit"
              class="btn btn-primary"
              [disabled]="issueForm.invalid || isSubmitting"
            >
              <i class="fas fa-spinner fa-spin" *ngIf="isSubmitting"></i>
              <i class="fas fa-check" *ngIf="!isSubmitting"></i>
              {{ isSubmitting ? 'Saving...' : isEditMode ? 'Update Issue' : 'Create Issue' }}
            </button>
          </div>
        </form>
      </div>

      <!-- Success Message -->
      <div class="success-message" *ngIf="showSuccess">
        <i class="fas fa-check-circle"></i>
        <span>Issue {{ isEditMode ? 'updated' : 'created' }} successfully!</span>
      </div>

      <!-- Error Message -->
      <div class="error-notification" *ngIf="errorMessage">
        <i class="fas fa-exclamation-circle"></i>
        <span>{{ errorMessage }}</span>
      </div>
    </div>
  `,
  styles: [
    `
      /* Modern Tailwind-inspired Form Styling */
      .issue-create-container {
        padding: 2rem;
        max-width: 1200px;
        margin: 0 auto;
      }

      /* Page Header */
      .page-header {
        margin-bottom: 2rem;
      }

      .page-header h1 {
        font-size: 1.5rem;
        font-weight: 700;
        color: #111827;
        margin-bottom: 0.5rem;
      }

      .page-header p {
        color: #6b7280;
        font-size: 0.9375rem;
      }

      /* Form Card */
      .form-card {
        background: #ffffff;
        border-radius: 12px;
        padding: 2rem;
        box-shadow:
          0 1px 3px rgba(0, 0, 0, 0.1),
          0 1px 2px rgba(0, 0, 0, 0.06);
      }

      .form-grid {
        display: grid;
        grid-template-columns: repeat(2, 1fr);
        gap: 1.5rem;
      }

      .form-group {
        display: flex;
        flex-direction: column;
      }

      .form-group.full-width {
        grid-column: 1 / -1;
      }

      /* Form Labels */
      label {
        font-weight: 600;
        font-size: 0.875rem;
        margin-bottom: 0.5rem;
        color: #1f2937;
        display: block;
      }

      .required {
        color: #ef4444;
      }

      /* Form Controls - Modern Style */
      .form-control,
      .form-select {
        width: 100%;
        font-size: 0.9375rem;
        padding: 0.625rem 0.875rem;
        border: 1.5px solid #e5e7eb;
        border-radius: 8px;
        transition: all 0.2s ease;
        background: #ffffff;
      }

      .form-control:focus,
      .form-select:focus {
        outline: none;
        border-color: #2563eb;
        box-shadow: 0 0 0 3px rgba(37, 99, 235, 0.1);
      }

      .form-control::placeholder {
        color: #9ca3af;
      }

      /* Validation States - Minimal */
      .is-valid {
        border-color: #10b981;
        background-image: none;
        padding-right: 0.875rem;
      }

      .is-valid:focus {
        border-color: #10b981;
        box-shadow: 0 0 0 3px rgba(16, 185, 129, 0.1);
      }

      .is-invalid {
        border-color: #ef4444;
        background-image: none;
        padding-right: 0.875rem;
      }

      .is-invalid:focus {
        border-color: #ef4444;
        box-shadow: 0 0 0 3px rgba(239, 68, 68, 0.1);
      }

      .valid-feedback {
        display: block;
        color: #10b981;
        font-size: 0.8125rem;
        margin-top: 0.375rem;
        font-weight: 500;
      }

      .invalid-feedback {
        display: block;
        font-size: 0.8125rem;
        color: #ef4444;
        margin-top: 0.375rem;
        font-weight: 500;
      }

      textarea.form-control {
        resize: vertical;
        min-height: 120px;
        font-family: inherit;
      }

      /* Tags */
      .tags-display {
        display: flex;
        flex-wrap: wrap;
        gap: 0.5rem;
        margin-top: 0.75rem;
      }

      .tag {
        display: inline-flex;
        align-items: center;
        gap: 0.5rem;
        padding: 0.375rem 0.75rem;
        background: #dbeafe;
        color: #1e40af;
        border-radius: 12px;
        font-size: 0.8125rem;
        font-weight: 500;
      }

      .tag-remove {
        background: none;
        border: none;
        color: #1e40af;
        cursor: pointer;
        font-size: 1.125rem;
        padding: 0;
        width: 16px;
        height: 16px;
        display: flex;
        align-items: center;
        justify-content: center;
        transition: all 0.2s;
      }

      .tag-remove:hover {
        color: #ef4444;
      }

      /* Form Actions */
      .form-actions {
        display: flex;
        justify-content: flex-end;
        gap: 1rem;
        margin-top: 2rem;
        padding-top: 2rem;
        border-top: 1.5px solid #e5e7eb;
      }

      /* Buttons - Modern */
      .btn {
        padding: 0.625rem 1.25rem;
        border-radius: 8px;
        font-weight: 500;
        font-size: 0.9375rem;
        cursor: pointer;
        transition: all 0.15s ease;
        display: inline-flex;
        align-items: center;
        gap: 0.5rem;
        border: 1.5px solid transparent;
      }

      .btn:disabled {
        opacity: 0.6;
        cursor: not-allowed;
        transform: none;
      }

      .btn-primary {
        background: #2563eb;
        border-color: #2563eb;
        color: #ffffff;
      }

      .btn-primary:hover:not(:disabled) {
        background: #1d4ed8;
        border-color: #1d4ed8;
        transform: translateY(-1px);
        box-shadow: 0 4px 12px rgba(37, 99, 235, 0.4);
      }

      .btn-primary:active:not(:disabled) {
        transform: translateY(0);
      }

      .btn-secondary {
        background: transparent;
        border-color: #d1d5db;
        color: #374151;
      }

      .btn-secondary:hover {
        background: #f9fafb;
        border-color: #9ca3af;
        color: #1f2937;
      }

      /* Notifications */
      .success-message,
      .error-notification {
        position: fixed;
        top: 2rem;
        right: 2rem;
        padding: 0.875rem 1rem;
        border-radius: 8px;
        display: flex;
        align-items: center;
        gap: 0.75rem;
        font-weight: 500;
        font-size: 0.875rem;
        box-shadow: 0 4px 12px rgba(0, 0, 0, 0.15);
        z-index: 1000;
        animation: slideIn 0.3s ease-out;
      }

      .success-message {
        background: #d1fae5;
        color: #065f46;
      }

      .error-notification {
        background: #fee2e2;
        color: #991b1b;
      }

      /* Animations */
      @keyframes slideIn {
        from {
          transform: translateX(100%);
          opacity: 0;
        }
        to {
          transform: translateX(0);
          opacity: 1;
        }
      }

      /* Responsive */
      @media (max-width: 768px) {
        .issue-create-container {
          padding: 1rem;
        }

        .form-card {
          padding: 1.5rem;
        }

        .page-header h1 {
          font-size: 1.25rem;
        }

        .form-grid {
          grid-template-columns: 1fr;
        }

        .form-group.full-width {
          grid-column: 1;
        }

        .btn {
          width: 100%;
        }

        .form-actions {
          flex-direction: column;
          gap: 0.75rem;
        }
      }

      /* Remove extra effects */
      *:focus-visible {
        outline: none;
      }
    `,
  ],
})
export class IssueCreateComponent implements OnInit {
  issueForm: FormGroup;
  isEditMode = false;
  issueId?: number;
  isSubmitting = false;
  showSuccess = false;
  errorMessage = '';

  categories = Object.values(IssueCategory);
  priorities = Object.values(IssuePriority);
  statuses = Object.values(IssueStatus);

  users = ['John Doe', 'Jane Smith', 'Mike Johnson', 'Sarah Williams'];
  displayTags: string[] = [];
  today = new Date().toISOString().split('T')[0];

  constructor(
    private readonly fb: FormBuilder,
    private readonly issueService: IssueService,
    private readonly router: Router,
    private readonly route: ActivatedRoute,
  ) {
    this.issueForm = this.fb.group({
      title: ['', [Validators.required, Validators.maxLength(200)]],
      description: ['', Validators.required],
      category: ['', Validators.required],
      priority: ['', Validators.required],
      status: [IssueStatus.OPEN],
      assignedTo: [''],
      dueDate: [''],
      tagsInput: [''],
    });
  }

  ngOnInit(): void {
    this.route.paramMap.subscribe((params) => {
      const id = params.get('id');
      if (id) {
        this.isEditMode = true;
        this.issueId = +id;
        this.loadIssue();
      }
    });

    // Watch tags input for changes
    this.issueForm.get('tagsInput')?.valueChanges.subscribe((value) => {
      if (value && value.includes(',')) {
        this.processTags(value);
      }
    });
  }

  loadIssue(): void {
    if (!this.issueId) return;

    this.issueService.getIssueById(this.issueId).subscribe({
      next: (issue) => {
        this.issueForm.patchValue({
          title: issue.title,
          description: issue.description,
          category: issue.category,
          priority: issue.priority,
          status: issue.status,
          assignedTo: issue.assignedTo || '',
          dueDate: issue.dueDate ? new Date(issue.dueDate).toISOString().split('T')[0] : '',
          tagsInput: '',
        });
        this.displayTags = issue.tags || [];
      },
      error: (err) => {
        console.error('Error loading issue:', err);
        this.errorMessage = 'Failed to load issue details';
      },
    });
  }

  processTags(input: string): void {
    const tags = input
      .split(',')
      .map((t) => t.trim())
      .filter((t) => t.length > 0);
    tags.forEach((tag) => {
      if (!this.displayTags.includes(tag)) {
        this.displayTags.push(tag);
      }
    });
    this.issueForm.patchValue({ tagsInput: '' });
  }

  removeTag(tag: string): void {
    this.displayTags = this.displayTags.filter((t) => t !== tag);
  }

  formatEnumValue(value: string): string {
    return value.replace(/_/g, ' ').replace(/\b\w/g, (l) => l.toUpperCase());
  }

  onSubmit(): void {
    if (this.issueForm.invalid || this.isSubmitting) return;

    this.isSubmitting = true;
    this.errorMessage = '';

    const formValue = this.issueForm.value;
    const issueData: Issue = {
      title: formValue.title,
      description: formValue.description,
      category: formValue.category,
      priority: formValue.priority,
      status: formValue.status,
      assignedTo: formValue.assignedTo || undefined,
      dueDate: formValue.dueDate || undefined,
      tags: this.displayTags,
      reportedBy: 1, // Replace with actual user ID
    };

    const operation =
      this.isEditMode && this.issueId
        ? this.issueService.updateIssue(this.issueId, issueData)
        : this.issueService.createIssue(issueData);

    operation.subscribe({
      next: () => {
        this.showSuccess = true;
        setTimeout(() => {
          this.router.navigate(['/issues']);
        }, 1500);
      },
      error: (err) => {
        console.error('Error saving issue:', err);
        this.errorMessage = `Failed to ${this.isEditMode ? 'update' : 'create'} issue`;
        this.isSubmitting = false;
      },
    });
  }

  onCancel(): void {
    this.router.navigate(['/issues']);
  }
}
