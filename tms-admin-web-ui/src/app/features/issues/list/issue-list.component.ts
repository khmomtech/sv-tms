import { Component, OnInit } from '@angular/core';
import { CommonModule } from '@angular/common';
import { RouterModule, ActivatedRoute, Router } from '@angular/router';
import { FormsModule } from '@angular/forms';
import { IssueService } from '../services/issue.service';
import { ConfirmService } from '../../../services/confirm.service';
import {
  Issue,
  IssueStatus,
  IssueCategory,
  IssuePriority,
  IssueFilter,
} from '../models/issue.model';

@Component({
  selector: 'app-issue-list',
  standalone: true,
  imports: [CommonModule, RouterModule, FormsModule],
  template: `
    <div class="issue-list-container">
      <!-- Header -->
      <div class="page-header">
        <div class="header-content">
          <div>
            <h1>{{ pageTitle }}</h1>
            <p class="subtitle">Track and manage system issues and requests</p>
          </div>
          <button class="btn btn-primary" routerLink="/issues/create">
            <i class="fas fa-plus"></i>
            Create Issue
          </button>
        </div>
      </div>

      <!-- Filters -->
      <div class="filters-card">
        <div class="filters-grid">
          <div class="filter-group">
            <label>Search</label>
            <input
              type="text"
              [(ngModel)]="searchQuery"
              (input)="applyFilters()"
              placeholder="Search issues..."
              class="form-control"
            />
          </div>

          <div class="filter-group">
            <label>Status</label>
            <select [(ngModel)]="selectedStatus" (change)="applyFilters()" class="form-control">
              <option value="">All Statuses</option>
              <option *ngFor="let status of statuses" [value]="status">{{ status }}</option>
            </select>
          </div>

          <div class="filter-group">
            <label>Category</label>
            <select [(ngModel)]="selectedCategory" (change)="applyFilters()" class="form-control">
              <option value="">All Categories</option>
              <option *ngFor="let category of categories" [value]="category">{{ category }}</option>
            </select>
          </div>

          <div class="filter-group">
            <label>Priority</label>
            <select [(ngModel)]="selectedPriority" (change)="applyFilters()" class="form-control">
              <option value="">All Priorities</option>
              <option *ngFor="let priority of priorities" [value]="priority">{{ priority }}</option>
            </select>
          </div>

          <div class="filter-group filter-actions">
            <button class="btn btn-secondary btn-sm" (click)="clearFilters()">
              <i class="fas fa-times"></i> Clear
            </button>
          </div>
        </div>
      </div>

      <!-- Stats -->
      <div class="stats-grid">
        <div class="stat-card">
          <div class="stat-icon bg-blue">
            <i class="fas fa-clipboard-list"></i>
          </div>
          <div class="stat-content">
            <div class="stat-value">{{ totalElements }}</div>
            <div class="stat-label">Total Issues</div>
          </div>
        </div>

        <div class="stat-card">
          <div class="stat-icon bg-yellow">
            <i class="fas fa-exclamation-circle"></i>
          </div>
          <div class="stat-content">
            <div class="stat-value">{{ getCountByStatus('OPEN') }}</div>
            <div class="stat-label">Open</div>
          </div>
        </div>

        <div class="stat-card">
          <div class="stat-icon bg-orange">
            <i class="fas fa-spinner"></i>
          </div>
          <div class="stat-content">
            <div class="stat-value">{{ getCountByStatus('IN_PROGRESS') }}</div>
            <div class="stat-label">In Progress</div>
          </div>
        </div>

        <div class="stat-card">
          <div class="stat-icon bg-green">
            <i class="fas fa-check-circle"></i>
          </div>
          <div class="stat-content">
            <div class="stat-value">{{ getCountByStatus('RESOLVED') }}</div>
            <div class="stat-label">Resolved</div>
          </div>
        </div>
      </div>

      <!-- Issues Table -->
      <div class="issues-card">
        <div *ngIf="isLoading" class="loading-state">
          <i class="fas fa-spinner fa-spin"></i>
          <p>Loading issues...</p>
        </div>

        <div *ngIf="!isLoading && issues.length === 0" class="empty-state">
          <i class="fas fa-inbox"></i>
          <h3>No issues found</h3>
          <p>Try adjusting your filters or create a new issue</p>
          <button class="btn btn-primary" routerLink="/issues/create">
            <i class="fas fa-plus"></i>
            Create First Issue
          </button>
        </div>

        <div *ngIf="!isLoading && issues.length > 0" class="table-responsive">
          <table class="issues-table">
            <thead>
              <tr>
                <th>ID</th>
                <th>Title</th>
                <th>Category</th>
                <th>Priority</th>
                <th>Status</th>
                <th>Reported By</th>
                <th>Assigned To</th>
                <th>Created</th>
                <th>Actions</th>
              </tr>
            </thead>
            <tbody>
              <tr *ngFor="let issue of issues">
                <td class="issue-id-cell">#{{ issue.id }}</td>
                <td class="issue-title-cell">
                  <div class="title-wrapper">
                    <strong>{{ issue.title }}</strong>
                    <small class="description-preview">{{ issue.description }}</small>
                  </div>
                </td>
                <td>
                  <span class="badge badge-category">{{ issue.category }}</span>
                </td>
                <td>
                  <span class="badge badge-{{ getPriorityClass(issue.priority) }}">
                    {{ issue.priority }}
                  </span>
                </td>
                <td>
                  <span class="badge badge-{{ getStatusClass(issue.status) }}">
                    {{ issue.status }}
                  </span>
                </td>
                <td>{{ issue.reportedBy || '-' }}</td>
                <td>{{ issue.assignedTo || '-' }}</td>
                <td>{{ issue.createdAt | date: 'MMM d, y' }}</td>
                <td class="actions-cell">
                  <button
                    class="action-btn view-btn"
                    [routerLink]="['/issues', issue.id]"
                    title="View"
                  >
                    View
                  </button>
                  <button class="action-btn edit-btn" (click)="editIssue(issue)" title="Edit">
                    Edit
                  </button>
                  <button class="action-btn delete-btn" (click)="deleteIssue(issue)" title="Delete">
                    Delete
                  </button>
                </td>
              </tr>
            </tbody>
          </table>
        </div>

        <!-- Pagination Footer -->
        <div *ngIf="!isLoading && issues.length > 0" class="pagination-footer">
          <div class="pagination-info">
            <label for="pageSize">Show:</label>
            <select
              id="pageSize"
              [(ngModel)]="pageSize"
              (change)="onPageSizeChange()"
              class="page-size-select"
            >
              <option [value]="10">10</option>
              <option [value]="25">25</option>
              <option [value]="50">50</option>
              <option [value]="100">100</option>
            </select>
            <span>records per page</span>
          </div>

          <div class="pagination-center">
            <span
              >Showing {{ getStartRecord() }} - {{ getEndRecord() }} of {{ totalElements }}</span
            >
            <span class="page-indicator">Page {{ currentPage + 1 }} of {{ totalPages }}</span>
          </div>

          <div class="pagination-controls">
            <label for="gotoPage">Go to page:</label>
            <input
              type="number"
              id="gotoPage"
              [(ngModel)]="gotoPageNumber"
              (keyup.enter)="goToPage()"
              min="1"
              [max]="totalPages"
              class="goto-page-input"
            />
            <button class="btn btn-primary btn-sm" (click)="goToPage()">Go</button>
          </div>
        </div>
      </div>
    </div>
  `,
  styles: [
    `
      .issue-list-container {
        padding: 2rem;
        max-width: 1400px;
        margin: 0 auto;
      }

      .page-header {
        margin-bottom: 2rem;
      }

      .header-content {
        display: flex;
        justify-content: space-between;
        align-items: flex-start;
      }

      .page-header h1 {
        font-size: 2rem;
        font-weight: 600;
        color: #1a202c;
        margin-bottom: 0.5rem;
      }

      .subtitle {
        color: #718096;
        font-size: 1rem;
      }

      /* Filters */
      .filters-card {
        background: white;
        border-radius: 8px;
        padding: 1.5rem;
        margin-bottom: 2rem;
        box-shadow: 0 1px 3px rgba(0, 0, 0, 0.1);
      }

      .filters-grid {
        display: grid;
        grid-template-columns: 2fr 1fr 1fr 1fr auto;
        gap: 1rem;
        align-items: end;
      }

      .filter-group label {
        display: block;
        margin-bottom: 0.5rem;
        font-weight: 500;
        color: #4a5568;
        font-size: 0.875rem;
      }

      .form-control {
        width: 100%;
        padding: 0.5rem 0.75rem;
        border: 1px solid #e2e8f0;
        border-radius: 6px;
        font-size: 0.875rem;
      }

      .form-control:focus {
        outline: none;
        border-color: #4299e1;
        box-shadow: 0 0 0 3px rgba(66, 153, 225, 0.1);
      }

      /* Stats */
      .stats-grid {
        display: grid;
        grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
        gap: 1rem;
        margin-bottom: 2rem;
      }

      .stat-card {
        background: white;
        border-radius: 8px;
        padding: 1.5rem;
        display: flex;
        align-items: center;
        gap: 1rem;
        box-shadow: 0 1px 3px rgba(0, 0, 0, 0.1);
      }

      .stat-icon {
        width: 48px;
        height: 48px;
        border-radius: 8px;
        display: flex;
        align-items: center;
        justify-content: center;
        font-size: 1.5rem;
        color: white;
      }

      .stat-icon.bg-blue {
        background: #4299e1;
      }
      .stat-icon.bg-yellow {
        background: #f6ad55;
      }
      .stat-icon.bg-orange {
        background: #ed8936;
      }
      .stat-icon.bg-green {
        background: #48bb78;
      }

      .stat-value {
        font-size: 1.75rem;
        font-weight: 700;
        color: #1a202c;
      }

      .stat-label {
        font-size: 0.875rem;
        color: #718096;
      }

      /* Issues Table */
      .issues-card {
        background: white;
        border-radius: 8px;
        overflow: hidden;
        box-shadow: 0 1px 3px rgba(0, 0, 0, 0.1);
      }

      .table-responsive {
        overflow-x: auto;
      }

      .issues-table {
        width: 100%;
        border-collapse: collapse;
      }

      .issues-table thead {
        background: #f7fafc;
        border-bottom: 2px solid #e2e8f0;
      }

      .issues-table th {
        padding: 1rem;
        text-align: left;
        font-weight: 600;
        font-size: 0.875rem;
        color: #2d3748;
        white-space: nowrap;
      }

      .issues-table tbody tr {
        border-bottom: 1px solid #e2e8f0;
        transition: background-color 0.2s;
      }

      .issues-table tbody tr:hover {
        background: #f7fafc;
      }

      .issues-table td {
        padding: 1rem;
        font-size: 0.875rem;
        color: #4a5568;
        vertical-align: middle;
      }

      .issue-id-cell {
        font-weight: 600;
        color: #718096;
        white-space: nowrap;
      }

      .issue-title-cell {
        min-width: 250px;
        max-width: 350px;
      }

      .title-wrapper {
        display: flex;
        flex-direction: column;
        gap: 0.25rem;
      }

      .title-wrapper strong {
        color: #2d3748;
        font-weight: 600;
      }

      .description-preview {
        color: #718096;
        font-size: 0.813rem;
        display: -webkit-box;
        -webkit-line-clamp: 2;
        -webkit-box-orient: vertical;
        overflow: hidden;
        text-overflow: ellipsis;
      }

      .actions-cell {
        white-space: nowrap;
      }

      .action-btn {
        padding: 0.375rem 0.75rem;
        border: none;
        border-radius: 4px;
        font-size: 0.813rem;
        font-weight: 500;
        cursor: pointer;
        margin-right: 0.5rem;
        transition: all 0.2s;
      }

      .view-btn {
        background: transparent;
        color: #4299e1;
      }

      .view-btn:hover {
        color: #2b6cb0;
        text-decoration: underline;
      }

      .edit-btn {
        background: transparent;
        color: #48bb78;
      }

      .edit-btn:hover {
        color: #2f855a;
        text-decoration: underline;
      }

      .delete-btn {
        background: transparent;
        color: #f56565;
      }

      .delete-btn:hover {
        color: #c53030;
        text-decoration: underline;
      }

      /* Pagination Footer */
      .pagination-footer {
        display: flex;
        justify-content: space-between;
        align-items: center;
        padding: 1rem 1.5rem;
        background: white;
        border-top: 1px solid #e2e8f0;
        gap: 1rem;
        flex-wrap: wrap;
      }

      .pagination-info {
        display: flex;
        align-items: center;
        gap: 0.5rem;
        font-size: 0.875rem;
        color: #4a5568;
      }

      .page-size-select {
        padding: 0.375rem 2rem 0.375rem 0.75rem;
        border: 1px solid #cbd5e0;
        border-radius: 4px;
        font-size: 0.875rem;
        background: white;
        cursor: pointer;
      }

      .pagination-center {
        display: flex;
        align-items: center;
        gap: 1rem;
        font-size: 0.875rem;
        color: #4a5568;
      }

      .page-indicator {
        font-weight: 500;
        color: #2d3748;
      }

      .pagination-controls {
        display: flex;
        align-items: center;
        gap: 0.5rem;
        font-size: 0.875rem;
        color: #4a5568;
      }

      .goto-page-input {
        width: 60px;
        padding: 0.375rem 0.5rem;
        border: 1px solid #cbd5e0;
        border-radius: 4px;
        font-size: 0.875rem;
        text-align: center;
      }

      .goto-page-input:focus {
        outline: none;
        border-color: #4299e1;
        box-shadow: 0 0 0 3px rgba(66, 153, 225, 0.1);
      }

      .badge {
        padding: 0.25rem 0.75rem;
        border-radius: 12px;
        font-size: 0.75rem;
        font-weight: 600;
        text-transform: uppercase;
        white-space: nowrap;
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

      .badge-category {
        background: #f7fafc;
        color: #4a5568;
        text-transform: capitalize;
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

      /* Pagination */
      .pagination {
        display: flex;
        justify-content: center;
        align-items: center;
        gap: 1rem;
        margin-top: 2rem;
        padding-top: 2rem;
        border-top: 1px solid #e2e8f0;
      }

      .page-info {
        color: #4a5568;
        font-weight: 500;
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

      .btn-primary {
        background: #4299e1;
        color: white;
      }

      .btn-primary:hover {
        background: #3182ce;
      }

      .btn-secondary {
        background: #e2e8f0;
        color: #4a5568;
      }

      .btn-secondary:hover {
        background: #cbd5e0;
      }

      .btn-secondary:disabled {
        opacity: 0.5;
        cursor: not-allowed;
      }

      .btn-sm {
        padding: 0.5rem 1rem;
        font-size: 0.813rem;
      }

      @media (max-width: 768px) {
        .filters-grid {
          grid-template-columns: 1fr;
        }

        .stats-grid {
          grid-template-columns: repeat(2, 1fr);
        }

        .pagination-footer {
          flex-direction: column;
          align-items: stretch;
        }

        .pagination-center,
        .pagination-controls {
          justify-content: center;
        }

        .table-responsive {
          overflow-x: scroll;
        }
      }
    `,
  ],
})
export class IssueListComponent implements OnInit {
  issues: Issue[] = [];
  allIssues: Issue[] = [];

  currentPage = 0;
  pageSize = 10;
  totalPages = 0;
  totalElements = 0;
  gotoPageNumber = 1;

  searchQuery = '';
  selectedStatus: IssueStatus | '' = '';
  selectedCategory: IssueCategory | '' = '';
  selectedPriority: IssuePriority | '' = '';

  isLoading = false;
  pageTitle = 'All Issues';

  statuses = Object.values(IssueStatus);
  categories = Object.values(IssueCategory);
  priorities = Object.values(IssuePriority);

  constructor(
    private readonly issueService: IssueService,
    private readonly route: ActivatedRoute,
    private readonly confirm: ConfirmService,
    private readonly router: Router,
  ) {}

  ngOnInit(): void {
    this.route.url.subscribe((url) => {
      const path = url[0]?.path;
      if (path === 'my') {
        this.pageTitle = 'My Issues';
        this.selectedStatus = '';
      } else if (path === 'open') {
        this.pageTitle = 'Open Issues';
        this.selectedStatus = IssueStatus.OPEN;
      } else if (path === 'closed') {
        this.pageTitle = 'Closed Issues';
        this.selectedStatus = IssueStatus.CLOSED;
      }
      this.loadIssues();
    });
  }

  loadIssues(): void {
    this.isLoading = true;

    const filter: IssueFilter = {
      status: this.selectedStatus || undefined,
      category: this.selectedCategory || undefined,
      priority: this.selectedPriority || undefined,
      search: this.searchQuery || undefined,
    };

    this.issueService.getAllIssues(this.currentPage, this.pageSize, filter).subscribe({
      next: (response) => {
        this.issues = response.content;
        this.allIssues = response.content;
        this.totalElements = response.totalElements;
        this.totalPages = response.totalPages;
        this.isLoading = false;
      },
      error: (err) => {
        console.error('Error loading issues:', err);
        this.isLoading = false;
      },
    });
  }

  applyFilters(): void {
    this.currentPage = 0;
    this.loadIssues();
  }

  clearFilters(): void {
    this.searchQuery = '';
    this.selectedStatus = '';
    this.selectedCategory = '';
    this.selectedPriority = '';
    this.applyFilters();
  }

  nextPage(): void {
    if (this.currentPage < this.totalPages - 1) {
      this.currentPage++;
      this.loadIssues();
    }
  }

  previousPage(): void {
    if (this.currentPage > 0) {
      this.currentPage--;
      this.loadIssues();
    }
  }

  onPageSizeChange(): void {
    this.currentPage = 0;
    this.loadIssues();
  }

  goToPage(): void {
    if (this.gotoPageNumber >= 1 && this.gotoPageNumber <= this.totalPages) {
      this.currentPage = this.gotoPageNumber - 1;
      this.loadIssues();
    }
  }

  getStartRecord(): number {
    return this.currentPage * this.pageSize + 1;
  }

  getEndRecord(): number {
    const end = (this.currentPage + 1) * this.pageSize;
    return end > this.totalElements ? this.totalElements : end;
  }

  getCountByStatus(status: string): number {
    return this.allIssues.filter((i) => i.status === status).length;
  }

  getStatusClass(status: IssueStatus): string {
    return status.toLowerCase();
  }

  getPriorityClass(priority: IssuePriority): string {
    return priority.toLowerCase();
  }

  viewIssue(event: Event, issue: Issue): void {
    event.stopPropagation();
    // Navigation handled by routerLink
  }

  editIssue(issue: Issue): void {
    this.router.navigate(['/issues', issue.id, 'edit']);
  }

  async deleteIssue(issue: Issue): Promise<void> {
    if (!(await this.confirm.confirm(`Are you sure you want to delete issue #${issue.id}?`)))
      return;
    this.issueService.deleteIssue(issue.id!).subscribe({
      next: () => {
        console.log('Issue deleted successfully');
        this.loadIssues();
      },
      error: (err) => {
        console.error('Error deleting issue:', err);
      },
    });
  }
}
