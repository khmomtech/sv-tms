/* eslint-disable @typescript-eslint/consistent-type-imports */
import { CommonModule } from '@angular/common';
import { Component, type OnInit } from '@angular/core';
import { FormsModule } from '@angular/forms';
import { Router, RouterModule } from '@angular/router';

// Removed DriverIssueDto import (OpenAPI generated model deleted)
import type { Driver } from '../../../models/driver.model';
import { DriverIssueService } from '../../../services/driver-issue.service';
import { DriverService } from '../../../services/driver.service';
import { ConfirmService } from '../../../services/confirm.service';
import { NotificationService } from '../../../services/notification.service';

@Component({
  selector: 'app-driver-issue-list',
  standalone: true,
  imports: [CommonModule, FormsModule, RouterModule],
  templateUrl: './driver-issue-list.component.html',
  styleUrls: ['./driver-issue-list.component.css'],
})
export class DriverIssueListComponent implements OnInit {
  // Data
  issues: any[] = [];
  drivers: Driver[] = [];

  // Pagination
  currentPage = 0;
  pageSize = 20;
  totalPages = 0;
  totalElements = 0;

  // Filters
  selectedDriverId: number | null = null;
  selectedStatus: string = '';
  selectedType: string = '';
  searchQuery: string = '';
  fromDate: string = '';
  toDate: string = '';

  // UI State
  isLoading = false;
  dropdownOpen: number | null = null;

  // Constants
  readonly statuses = ['OPEN', 'IN_PROGRESS', 'RESOLVED', 'CLOSED'];
  readonly issueTypes = [
    'Mechanical Issue',
    'Accident',
    'Flat Tire',
    'Engine Problem',
    'Brake Issue',
    'Electrical Problem',
    'Fuel Issue',
    'Customer Complaint',
    'Traffic Delay',
    'Other',
  ];

  constructor(
    private readonly issueService: DriverIssueService,
    private readonly driverService: DriverService,
    private readonly router: Router,
    private readonly notify: NotificationService,
    private readonly confirm: ConfirmService,
  ) {}

  ngOnInit(): void {
    this.loadDrivers();
    this.loadIssues();
  }

  loadDrivers(): void {
    this.driverService.getAllDriversModal().subscribe({
      next: (response) => {
        this.drivers = response.data || [];
      },
      error: (err) => console.error('❌ Error loading drivers:', err),
    });
  }

  loadIssues(): void {
    this.isLoading = true;

    // If a specific driver is selected, load their issues
    if (this.selectedDriverId) {
      this.loadIssuesByDriver(this.selectedDriverId);
    } else {
      // Load all issues (requires admin endpoint - fallback to first driver for demo)
      this.isLoading = false;
      this.issues = [];
      console.warn('⚠️ No driver selected. Please select a driver to view issues.');
    }
  }

  loadIssuesByDriver(driverId: number): void {
    const fromDateObj = this.fromDate ? new Date(this.fromDate) : undefined;
    const toDateObj = this.toDate ? new Date(this.toDate) : undefined;

    this.issueService
      .getIssuesByDriver(
        driverId,
        this.currentPage,
        this.pageSize,
        this.selectedStatus || undefined,
        this.selectedType || undefined,
        fromDateObj,
        toDateObj,
      )
      .subscribe({
        next: (response: any) => {
          const pageData = response.data;
          this.issues = pageData?.content || [];
          this.totalPages = pageData?.totalPages || 0;
          this.totalElements = pageData?.totalElements || 0;
          this.isLoading = false;
          console.log('Loaded issues:', this.issues);
        },
        error: (err: any) => {
          console.error('❌ Error loading issues:', err);
          this.isLoading = false;
        },
      });
  }

  // Filter Actions
  onFilterChange(): void {
    this.currentPage = 0;
    this.loadIssues();
  }

  onDriverChange(): void {
    this.currentPage = 0;
    this.loadIssues();
  }

  clearFilters(): void {
    this.selectedStatus = '';
    this.selectedType = '';
    this.fromDate = '';
    this.toDate = '';
    this.searchQuery = '';
    this.currentPage = 0;
    this.loadIssues();
  }

  // Pagination
  previousPage(): void {
    if (this.currentPage > 0) {
      this.currentPage--;
      this.loadIssues();
    }
  }

  nextPage(): void {
    if (this.currentPage < this.totalPages - 1) {
      this.currentPage++;
      this.loadIssues();
    }
  }

  // Navigation
  viewIssueDetail(issue: any): void {
    this.router.navigate(['/drivers/issues', issue.id]);
    this.dropdownOpen = null;
  }

  createNewIssue(): void {
    this.router.navigate(['/drivers/issues/new']);
  }

  // Dropdown
  toggleDropdown(issueId: number): void {
    this.dropdownOpen = this.dropdownOpen === issueId ? null : issueId;
  }

  closeDropdown(): void {
    this.dropdownOpen = null;
  }

  // Quick Actions
  quickUpdateStatus(issue: any, newStatus: string): void {
    if (!issue.id) return;

    const currentStatus = issue.status || 'OPEN';
    if (!this.issueService.isValidStatusTransition(currentStatus, newStatus)) {
      this.notify.simulateNotification(
        'Invalid status transition',
        `Invalid status transition from ${currentStatus} to ${newStatus}`,
      );
      return;
    }

    this.issueService.updateStatus(issue.id, newStatus).subscribe({
      next: () => {
        this.loadIssues(); // Reload to show updated status
      },
      error: (err: any) => console.error('❌ Status update failed:', err),
    });
    this.dropdownOpen = null;
  }

  async deleteIssue(issue: any): Promise<void> {
    if (!issue.id) return;
    if (!(await this.confirm.confirm(`Are you sure you want to delete issue "${issue.title}"?`))) {
      this.dropdownOpen = null;
      return;
    }
    this.issueService.deleteIssue(issue.id).subscribe({
      next: () => {
        this.loadIssues(); // Reload list
      },
      error: (err: any) => console.error('❌ Delete failed:', err),
    });
    this.dropdownOpen = null;
  }

  // Utility
  getStatusColor(status: string): string {
    return this.issueService.getStatusColor(status);
  }

  getSeverityColor(severity: string): string {
    return this.issueService.getSeverityColor(severity);
  }

  formatIssueType(title: string): string {
    return this.issueService.formatIssueType(title);
  }

  formatDate(date: Date | undefined): string {
    if (!date) return 'N/A';
    const d = new Date(date);
    return d.toLocaleDateString('en-US', {
      year: 'numeric',
      month: 'short',
      day: 'numeric',
      hour: '2-digit',
      minute: '2-digit',
    });
  }

  getDriverName(driverId: number): string {
    return this.drivers.find((d) => d.id === driverId)?.name || `Driver #${driverId}`;
  }

  getThumbnailUrl(images: string[] | undefined): string {
    if (!images || images.length === 0) return '/assets/images/no-image.png';
    return images[0];
  }

  hasImages(issue: any): boolean {
    return (issue.images?.length || 0) > 0 || (issue.photoUrls?.length || 0) > 0;
  }
}
