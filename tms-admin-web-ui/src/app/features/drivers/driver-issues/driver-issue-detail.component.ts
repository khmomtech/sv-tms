/* eslint-disable @typescript-eslint/consistent-type-imports */
import { CommonModule } from '@angular/common';
import { Component, type OnInit } from '@angular/core';
import { FormsModule } from '@angular/forms';
import { ActivatedRoute, Router, RouterModule } from '@angular/router';

// Removed DriverIssueDto import (OpenAPI generated model deleted)
import { DriverIssueService } from '../../../services/driver-issue.service';
import { ConfirmService } from '../../../services/confirm.service';
import { NotificationService } from '../../../services/notification.service';

@Component({
  selector: 'app-driver-issue-detail',
  standalone: true,
  imports: [CommonModule, RouterModule, FormsModule],
  templateUrl: './driver-issue-detail.component.html',
  styleUrls: ['./driver-issue-detail.component.css'],
})
export class DriverIssueDetailComponent implements OnInit {
  issue: any = null;
  isLoading = true;
  isUpdating = false;

  // Status update
  showStatusModal = false;
  newStatus: string = '';

  // Image preview
  showImageModal = false;
  currentImageIndex = 0;

  // Available statuses for dropdown
  availableStatuses: string[] = [];

  constructor(
    private readonly route: ActivatedRoute,
    private readonly router: Router,
    private readonly issueService: DriverIssueService,
    private readonly confirm: ConfirmService,
    private readonly notify: NotificationService,
  ) {}

  ngOnInit(): void {
    const id = this.route.snapshot.paramMap.get('id');
    if (id) {
      this.loadIssue(parseInt(id, 10));
    } else {
      this.router.navigate(['/drivers/issues']);
    }
  }

  loadIssue(id: number): void {
    this.isLoading = true;
    this.issueService.getIssueById(id).subscribe({
      next: (issue: any) => {
        this.issue = issue;
        this.availableStatuses = this.issueService.getAvailableStatuses(issue.status || 'OPEN');
        this.isLoading = false;
      },
      error: (err: any) => {
        console.error('❌ Error loading issue:', err);
        this.isLoading = false;
        this.notify.simulateNotification('Error', 'Failed to load issue details');
        this.router.navigate(['/drivers/issues']);
      },
    });
  }

  // Status Management
  openStatusModal(): void {
    this.newStatus = this.issue?.status || 'OPEN';
    this.showStatusModal = true;
  }

  closeStatusModal(): void {
    this.showStatusModal = false;
    this.newStatus = '';
  }

  updateStatus(): void {
    if (!this.issue?.id || !this.newStatus) return;

    const currentStatus = this.issue.status || 'OPEN';
    if (!this.issueService.isValidStatusTransition(currentStatus, this.newStatus)) {
      this.notify.simulateNotification(
        'Invalid status transition',
        `Invalid status transition from ${currentStatus} to ${this.newStatus}`,
      );
      return;
    }

    this.isUpdating = true;
    this.issueService.updateStatus(this.issue.id, this.newStatus).subscribe({
      next: (updated: any) => {
        this.issue = updated;
        this.availableStatuses = this.issueService.getAvailableStatuses(updated.status || 'OPEN');
        this.closeStatusModal();
        this.isUpdating = false;
      },
      error: (err: any) => {
        console.error('❌ Status update failed:', err);
        this.isUpdating = false;
      },
    });
  }

  // Image Management
  openImageModal(index: number): void {
    this.currentImageIndex = index;
    this.showImageModal = true;
  }

  closeImageModal(): void {
    this.showImageModal = false;
  }

  nextImage(): void {
    const images = this.issue?.images || this.issue?.photoUrls || [];
    this.currentImageIndex = (this.currentImageIndex + 1) % images.length;
  }

  previousImage(): void {
    const images = this.issue?.images || this.issue?.photoUrls || [];
    this.currentImageIndex = (this.currentImageIndex - 1 + images.length) % images.length;
  }

  getCurrentImage(): string {
    const images = this.issue?.images || this.issue?.photoUrls || [];
    return images[this.currentImageIndex] || '';
  }

  // Navigation
  goBack(): void {
    this.router.navigate(['/drivers/issues']);
  }

  editIssue(): void {
    if (this.issue?.id) {
      this.router.navigate(['/drivers/issues', this.issue.id, 'edit']);
    }
  }

  async deleteIssue(): Promise<void> {
    if (!this.issue?.id) return;

    if (
      !(await this.confirm.confirm(
        `Are you sure you want to delete issue #${this.issue.id} "${this.issue.title}"?`,
      ))
    )
      return;

    this.issueService.deleteIssue(this.issue.id).subscribe({
      next: () => {
        this.router.navigate(['/drivers/issues']);
      },
      error: (err: any) => console.error('❌ Delete failed:', err),
    });
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
    return d.toLocaleString('en-US', {
      year: 'numeric',
      month: 'long',
      day: 'numeric',
      hour: '2-digit',
      minute: '2-digit',
    });
  }

  hasImages(): boolean {
    return (this.issue?.images?.length || 0) > 0 || (this.issue?.photoUrls?.length || 0) > 0;
  }

  getImages(): string[] {
    return this.issue?.images || this.issue?.photoUrls || [];
  }

  getStatusBadgeText(status: string): string {
    const badges: Record<string, string> = {
      OPEN: '🔴 Open',
      IN_PROGRESS: '🟡 In Progress',
      RESOLVED: '🟢 Resolved',
      CLOSED: '⚫ Closed',
    };
    return badges[status] || status;
  }

  getSeverityBadgeText(severity: string): string {
    const badges: Record<string, string> = {
      LOW: '🔵 Low',
      MEDIUM: '🟡 Medium',
      HIGH: '🟠 High',
      CRITICAL: '🔴 Critical',
    };
    return badges[severity] || severity;
  }

  canUpdateStatus(): boolean {
    const currentStatus = this.issue?.status || 'OPEN';
    return this.availableStatuses.length > 0 && currentStatus !== 'CLOSED';
  }
}
