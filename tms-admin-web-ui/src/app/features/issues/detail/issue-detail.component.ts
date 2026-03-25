import { Component, OnInit } from '@angular/core';
import { CommonModule } from '@angular/common';
import { RouterModule, Router, ActivatedRoute } from '@angular/router';
import { FormBuilder, FormGroup, ReactiveFormsModule, Validators } from '@angular/forms';
import { IssueService } from '../../../services/issue.service';
import { Issue, IssueStatus, IssueComment } from '../../../models/issue.model';
import { ConfirmService } from '@services/confirm.service';
import { NotificationService } from '../../../services/notification.service';

@Component({
  selector: 'app-issue-detail',
  standalone: true,
  imports: [CommonModule, RouterModule, ReactiveFormsModule],
  template: `
    <div class="issue-detail-container">
      <!-- Loading State -->
      <div *ngIf="isLoading" class="loading-state">
        <i class="fas fa-spinner fa-spin"></i>
        <p>Loading issue details...</p>
      </div>

      <!-- Issue Details -->
      <div *ngIf="!isLoading && issue" class="issue-content">
        <!-- Header -->
        <div class="page-header">
          <div>
            <div class="issue-id">#{{ issue.id }}</div>
            <h1>{{ issue.title }}</h1>
            <div class="issue-badges">
              <span class="badge badge-{{ getStatusClass(issue.status) }}">
                {{ formatEnumValue(issue.status) }}
              </span>
              <span class="badge badge-{{ getPriorityClass(issue.priority) }}">
                {{ formatEnumValue(issue.priority) }}
              </span>
              <span class="badge badge-type">
                {{ formatEnumValue(issue.type) }}
              </span>
            </div>
          </div>
          <div class="action-buttons">
            <button class="btn btn-secondary" (click)="onEdit()">
              <i class="fas fa-edit"></i>
              Edit
            </button>
            <button class="btn btn-danger" (click)="onDelete()">
              <i class="fas fa-trash"></i>
              Delete
            </button>
            <button class="btn btn-secondary" routerLink="/issues">
              <i class="fas fa-arrow-left"></i>
              Back
            </button>
          </div>
        </div>

        <div class="content-grid">
          <!-- Main Content -->
          <div class="main-content">
            <!-- Description -->
            <div class="section-card">
              <h2 class="section-title">Description</h2>
              <p class="description-text">{{ issue.description }}</p>
            </div>

            <!-- Tags -->
            <div class="section-card" *ngIf="issue.tags && issue.tags.length > 0">
              <h2 class="section-title">Tags</h2>
              <div class="tags-list">
                <span *ngFor="let tag of issue.tags" class="tag">{{ tag }}</span>
              </div>
            </div>

            <!-- Comments -->
            <div class="section-card">
              <h2 class="section-title">
                Comments
                <span class="comment-count">{{ issue.comments?.length || 0 }}</span>
              </h2>

              <!-- Comment List -->
              <div class="comments-list">
                <div *ngFor="let comment of issue.comments" class="comment-item">
                  <div class="comment-header">
                    <div class="comment-author">
                      <i class="fas fa-user-circle"></i>
                      <span>{{ comment.createdBy || 'Unknown' }}</span>
                    </div>
                    <div class="comment-date">
                      {{ comment.createdAt | date: 'MMM d, y h:mm a' }}
                    </div>
                  </div>
                  <p class="comment-text">{{ comment.content }}</p>
                </div>

                <div *ngIf="!issue.comments || issue.comments.length === 0" class="empty-comments">
                  <i class="fas fa-comments"></i>
                  <p>No comments yet. Be the first to comment!</p>
                </div>
              </div>

              <!-- Add Comment Form -->
              <form [formGroup]="commentForm" (ngSubmit)="onAddComment()" class="comment-form">
                <textarea
                  formControlName="content"
                  class="form-control"
                  rows="3"
                  placeholder="Add a comment..."
                ></textarea>
                <div class="comment-form-actions">
                  <button
                    type="submit"
                    class="btn btn-primary btn-sm"
                    [disabled]="commentForm.invalid || isSubmittingComment"
                  >
                    <i class="fas fa-spinner fa-spin" *ngIf="isSubmittingComment"></i>
                    <i class="fas fa-paper-plane" *ngIf="!isSubmittingComment"></i>
                    {{ isSubmittingComment ? 'Posting...' : 'Post Comment' }}
                  </button>
                </div>
              </form>
            </div>

            <!-- Attachments -->
            <div class="section-card" *ngIf="issue.attachments && issue.attachments.length > 0">
              <h2 class="section-title">Attachments</h2>
              <div class="attachments-list">
                <div *ngFor="let attachment of issue.attachments" class="attachment-item">
                  <i class="fas fa-file"></i>
                  <span class="attachment-name">{{ attachment.fileName }}</span>
                  <span class="attachment-size">{{
                    formatFileSize(attachment.fileSize ?? 0)
                  }}</span>
                  <button class="btn-icon" title="Download">
                    <i class="fas fa-download"></i>
                  </button>
                </div>
              </div>
            </div>
          </div>

          <!-- Sidebar -->
          <div class="sidebar">
            <!-- Status Update -->
            <div class="sidebar-card">
              <h3 class="sidebar-title">Update Status</h3>
              <div class="status-buttons">
                <button
                  *ngFor="let status of statuses"
                  class="status-btn"
                  [class.active]="issue.status === status"
                  (click)="onStatusChange(status)"
                >
                  {{ formatEnumValue(status) }}
                </button>
              </div>
            </div>

            <!-- Details -->
            <div class="sidebar-card">
              <h3 class="sidebar-title">Details</h3>
              <div class="detail-item">
                <div class="detail-label">Type</div>
                <div class="detail-value">{{ formatEnumValue(issue.type) }}</div>
              </div>
              <div class="detail-item">
                <div class="detail-label">Priority</div>
                <div class="detail-value">{{ formatEnumValue(issue.priority) }}</div>
              </div>
              <div class="detail-item">
                <div class="detail-label">Reported By</div>
                <div class="detail-value">
                  <i class="fas fa-user"></i>
                  {{ issue.reportedBy || 'Unknown' }}
                </div>
              </div>
              <div class="detail-item">
                <div class="detail-label">Assigned To</div>
                <div class="detail-value">
                  <i class="fas fa-user-check"></i>
                  {{ issue.assignedTo || 'Unassigned' }}
                </div>
              </div>
              <div class="detail-item">
                <div class="detail-label">Created</div>
                <div class="detail-value">
                  <i class="fas fa-calendar"></i>
                  {{ issue.createdAt | date: 'MMM d, y h:mm a' }}
                </div>
              </div>
              <div class="detail-item" *ngIf="issue.dueDate">
                <div class="detail-label">Due Date</div>
                <div class="detail-value" [class.overdue]="isOverdue(issue.dueDate)">
                  <i class="fas fa-clock"></i>
                  {{ issue.dueDate | date: 'MMM d, y' }}
                </div>
              </div>
              <div class="detail-item" *ngIf="issue.resolvedAt">
                <div class="detail-label">Resolved</div>
                <div class="detail-value">
                  <i class="fas fa-check"></i>
                  {{ issue.resolvedAt | date: 'MMM d, y h:mm a' }}
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>

      <!-- Not Found -->
      <div *ngIf="!isLoading && !issue" class="empty-state">
        <i class="fas fa-exclamation-triangle"></i>
        <h3>Issue Not Found</h3>
        <p>The issue you're looking for doesn't exist or has been deleted.</p>
        <button class="btn btn-primary" routerLink="/issues">
          <i class="fas fa-arrow-left"></i>
          Back to Issues
        </button>
      </div>
    </div>
  `,
  styles: [
    `
      .issue-detail-container {
        padding: 2rem;
        max-width: 1400px;
        margin: 0 auto;
      }

      /* Header */
      .page-header {
        display: flex;
        justify-content: space-between;
        align-items: flex-start;
        margin-bottom: 2rem;
        gap: 2rem;
      }

      .issue-id {
        font-size: 0.875rem;
        color: #718096;
        font-weight: 500;
        margin-bottom: 0.5rem;
      }

      .page-header h1 {
        font-size: 2rem;
        font-weight: 600;
        color: #1a202c;
        margin-bottom: 1rem;
      }

      .issue-badges {
        display: flex;
        gap: 0.5rem;
        flex-wrap: wrap;
      }

      .badge {
        padding: 0.375rem 0.875rem;
        border-radius: 12px;
        font-size: 0.75rem;
        font-weight: 600;
        text-transform: uppercase;
      }

      .badge-open {
        background: #fef5e7;
        color: #f39c12;
      }
      .badge-in_progress {
        background: #e8f4fd;
        color: #3182ce;
      }
      .badge-resolved {
        background: #e6f7f0;
        color: #38a169;
      }
      .badge-closed {
        background: #e2e8f0;
        color: #718096;
      }
      .badge-reopened {
        background: #fff5f5;
        color: #e53e3e;
      }

      .badge-critical {
        background: #fff5f5;
        color: #e53e3e;
      }
      .badge-high {
        background: #fef5e7;
        color: #ed8936;
      }
      .badge-medium {
        background: #e8f4fd;
        color: #4299e1;
      }
      .badge-low {
        background: #e6f7f0;
        color: #48bb78;
      }

      .badge-type {
        background: #f7fafc;
        color: #4a5568;
      }

      .action-buttons {
        display: flex;
        gap: 0.75rem;
        flex-shrink: 0;
      }

      /* Content Grid */
      .content-grid {
        display: grid;
        grid-template-columns: 1fr 350px;
        gap: 2rem;
      }

      /* Main Content */
      .main-content {
        display: flex;
        flex-direction: column;
        gap: 1.5rem;
      }

      .section-card {
        background: white;
        border-radius: 8px;
        padding: 2rem;
        box-shadow: 0 1px 3px rgba(0, 0, 0, 0.1);
      }

      .section-title {
        font-size: 1.25rem;
        font-weight: 600;
        color: #2d3748;
        margin-bottom: 1.5rem;
        display: flex;
        align-items: center;
        gap: 0.5rem;
      }

      .comment-count {
        background: #e2e8f0;
        color: #4a5568;
        padding: 0.25rem 0.625rem;
        border-radius: 12px;
        font-size: 0.875rem;
      }

      .description-text {
        color: #4a5568;
        line-height: 1.6;
        white-space: pre-wrap;
      }

      /* Tags */
      .tags-list {
        display: flex;
        flex-wrap: wrap;
        gap: 0.5rem;
      }

      .tag {
        padding: 0.375rem 0.875rem;
        background: #e6f7ff;
        color: #0050b3;
        border-radius: 12px;
        font-size: 0.813rem;
        font-weight: 500;
      }

      /* Comments */
      .comments-list {
        margin-bottom: 2rem;
      }

      .comment-item {
        padding: 1.5rem;
        background: #f7fafc;
        border-radius: 8px;
        margin-bottom: 1rem;
      }

      .comment-header {
        display: flex;
        justify-content: space-between;
        margin-bottom: 0.75rem;
      }

      .comment-author {
        display: flex;
        align-items: center;
        gap: 0.5rem;
        font-weight: 600;
        color: #2d3748;
      }

      .comment-author i {
        color: #718096;
        font-size: 1.25rem;
      }

      .comment-date {
        color: #718096;
        font-size: 0.813rem;
      }

      .comment-text {
        color: #4a5568;
        line-height: 1.5;
        margin: 0;
      }

      .empty-comments {
        text-align: center;
        padding: 3rem;
        color: #a0aec0;
      }

      .empty-comments i {
        font-size: 3rem;
        margin-bottom: 1rem;
        color: #cbd5e0;
      }

      /* Comment Form */
      .comment-form {
        border-top: 1px solid #e2e8f0;
        padding-top: 1.5rem;
      }

      .comment-form-actions {
        display: flex;
        justify-content: flex-end;
        margin-top: 1rem;
      }

      /* Attachments */
      .attachments-list {
        display: flex;
        flex-direction: column;
        gap: 0.75rem;
      }

      .attachment-item {
        display: flex;
        align-items: center;
        gap: 1rem;
        padding: 1rem;
        background: #f7fafc;
        border-radius: 6px;
      }

      .attachment-item i.fa-file {
        color: #4299e1;
        font-size: 1.25rem;
      }

      .attachment-name {
        flex: 1;
        color: #2d3748;
        font-weight: 500;
      }

      .attachment-size {
        color: #718096;
        font-size: 0.875rem;
      }

      /* Sidebar */
      .sidebar {
        display: flex;
        flex-direction: column;
        gap: 1.5rem;
      }

      .sidebar-card {
        background: white;
        border-radius: 8px;
        padding: 1.5rem;
        box-shadow: 0 1px 3px rgba(0, 0, 0, 0.1);
      }

      .sidebar-title {
        font-size: 1rem;
        font-weight: 600;
        color: #2d3748;
        margin-bottom: 1rem;
      }

      /* Status Buttons */
      .status-buttons {
        display: flex;
        flex-direction: column;
        gap: 0.5rem;
      }

      .status-btn {
        padding: 0.625rem;
        border: 1px solid #e2e8f0;
        background: white;
        border-radius: 6px;
        font-size: 0.875rem;
        font-weight: 500;
        color: #4a5568;
        cursor: pointer;
        transition: all 0.2s;
      }

      .status-btn:hover {
        background: #f7fafc;
        border-color: #4299e1;
      }

      .status-btn.active {
        background: #4299e1;
        color: white;
        border-color: #4299e1;
      }

      /* Details */
      .detail-item {
        padding: 0.75rem 0;
        border-bottom: 1px solid #e2e8f0;
      }

      .detail-item:last-child {
        border-bottom: none;
      }

      .detail-label {
        font-size: 0.813rem;
        color: #718096;
        margin-bottom: 0.25rem;
        font-weight: 500;
      }

      .detail-value {
        color: #2d3748;
        font-size: 0.875rem;
        display: flex;
        align-items: center;
        gap: 0.5rem;
      }

      .detail-value i {
        color: #a0aec0;
      }

      .detail-value.overdue {
        color: #e53e3e;
      }

      /* Form Control */
      .form-control {
        width: 100%;
        padding: 0.625rem 0.875rem;
        border: 1px solid #e2e8f0;
        border-radius: 6px;
        font-size: 0.875rem;
        resize: vertical;
        font-family: inherit;
      }

      .form-control:focus {
        outline: none;
        border-color: #4299e1;
        box-shadow: 0 0 0 3px rgba(66, 153, 225, 0.1);
      }

      /* Buttons */
      .btn {
        padding: 0.625rem 1.25rem;
        border-radius: 6px;
        font-weight: 500;
        cursor: pointer;
        transition: all 0.2s;
        display: inline-flex;
        align-items: center;
        gap: 0.5rem;
        border: none;
        font-size: 0.875rem;
      }

      .btn:disabled {
        opacity: 0.6;
        cursor: not-allowed;
      }

      .btn-primary {
        background: #4299e1;
        color: white;
      }

      .btn-primary:hover:not(:disabled) {
        background: #3182ce;
      }

      .btn-secondary {
        background: #e2e8f0;
        color: #4a5568;
      }

      .btn-secondary:hover {
        background: #cbd5e0;
      }

      .btn-danger {
        background: #fc8181;
        color: white;
      }

      .btn-danger:hover {
        background: #f56565;
      }

      .btn-sm {
        padding: 0.5rem 1rem;
        font-size: 0.813rem;
      }

      .btn-icon {
        width: 32px;
        height: 32px;
        border: none;
        background: transparent;
        color: #4a5568;
        cursor: pointer;
        border-radius: 4px;
        transition: all 0.2s;
      }

      .btn-icon:hover {
        background: #e2e8f0;
        color: #2d3748;
      }

      /* States */
      .loading-state,
      .empty-state {
        text-align: center;
        padding: 4rem 2rem;
        color: #718096;
      }

      .loading-state i,
      .empty-state i {
        font-size: 3rem;
        margin-bottom: 1rem;
        color: #cbd5e0;
      }

      .loading-state i.fa-spin {
        color: #4299e1;
      }

      .empty-state h3 {
        color: #2d3748;
        margin: 1rem 0;
      }

      @media (max-width: 968px) {
        .content-grid {
          grid-template-columns: 1fr;
        }

        .page-header {
          flex-direction: column;
        }

        .action-buttons {
          width: 100%;
          justify-content: stretch;
        }

        .action-buttons .btn {
          flex: 1;
        }
      }
    `,
  ],
})
export class IssueDetailComponent implements OnInit {
  issue?: Issue;
  isLoading = false;
  isSubmittingComment = false;

  commentForm: FormGroup;
  statuses = Object.values(IssueStatus);

  constructor(
    private readonly issueService: IssueService,
    private readonly router: Router,
    private readonly route: ActivatedRoute,
    private readonly fb: FormBuilder,
    private readonly confirm: ConfirmService,
    private readonly notify: NotificationService,
  ) {
    this.commentForm = this.fb.group({
      content: ['', Validators.required],
    });
  }

  ngOnInit(): void {
    this.route.paramMap.subscribe((params) => {
      const id = params.get('id');
      if (id) {
        this.loadIssue(+id);
      }
    });
  }

  loadIssue(id: number): void {
    this.isLoading = true;
    this.issueService.getIssueById(id).subscribe({
      next: (issue) => {
        this.issue = issue;
        this.isLoading = false;
      },
      error: (err) => {
        console.error('Error loading issue:', err);
        this.isLoading = false;
      },
    });
  }

  onEdit(): void {
    if (this.issue && this.issue.id != null) {
      this.router.navigate(['/issues/edit', this.issue.id!]);
    }
  }

  async onDelete(): Promise<void> {
    if (!this.issue || this.issue.id == null) return;

    if (!(await this.confirm.confirm(`Are you sure you want to delete issue #${this.issue.id}?`)))
      return;

    this.issueService.deleteIssue(this.issue.id!).subscribe({
      next: () => {
        this.router.navigate(['/issues']);
      },
      error: (err) => {
        console.error('Error deleting issue:', err);
        this.notify.simulateNotification('Delete Failed', 'Failed to delete issue');
      },
    });
  }

  onStatusChange(newStatus: IssueStatus): void {
    if (!this.issue || this.issue.id == null || this.issue.status === newStatus) return;

    this.issueService.updateStatus(this.issue.id!, newStatus).subscribe({
      next: (updatedIssue) => {
        this.issue = updatedIssue;
      },
      error: (err) => {
        console.error('Error updating status:', err);
        this.notify.simulateNotification('Update Failed', 'Failed to update status');
      },
    });
  }

  onAddComment(): void {
    if (this.commentForm.invalid || !this.issue || this.issue.id == null) return;

    this.isSubmittingComment = true;

    const commentText = this.commentForm.value.content;

    this.issueService.addComment(this.issue.id!, commentText).subscribe({
      next: (newComment) => {
        if (this.issue) {
          this.issue.comments = this.issue.comments || [];
          this.issue.comments.push(newComment);
        }
        this.commentForm.reset();
        this.isSubmittingComment = false;
      },
      error: (err) => {
        console.error('Error adding comment:', err);
        this.notify.simulateNotification('Comment Failed', 'Failed to add comment');
        this.isSubmittingComment = false;
      },
    });
  }

  formatEnumValue(value: string): string {
    return value.replace(/_/g, ' ').replace(/\b\w/g, (l) => l.toUpperCase());
  }

  getStatusClass(status: IssueStatus): string {
    return status.toLowerCase();
  }

  getPriorityClass(priority: string): string {
    return priority.toLowerCase();
  }

  formatFileSize(bytes: number): string {
    if (bytes < 1024) return bytes + ' B';
    if (bytes < 1024 * 1024) return (bytes / 1024).toFixed(1) + ' KB';
    return (bytes / (1024 * 1024)).toFixed(1) + ' MB';
  }

  isOverdue(dueDate: Date): boolean {
    return new Date(dueDate) < new Date();
  }
}
