import { Component, type OnInit, type OnDestroy, inject, signal, computed } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { ActivatedRoute, Router, RouterLink } from '@angular/router';
import { Subject, takeUntil } from 'rxjs';

import type { Case, CaseTask } from '../../models/incident.model';
import {
  CaseStatus,
  CaseCategory,
  IssueSeverity,
  CaseTaskStatus,
  CaseTimelineEntry,
} from '../../models/incident.model';
import { CaseService } from '../../services/case.service';
import { ConfirmService } from '../../../../services/confirm.service';

/**
 * Case Detail Component - Salesforce Lightning Design System (SLDS) Style
 *
 * Displays comprehensive case information with:
 * - Case header with status, severity, and metadata
 * - Linked incidents and tasks management
 * - Activity timeline
 * - Resource links (driver, vehicle)
 * - Statistics dashboard
 *
 * Following Angular best practices:
 * - External template (case-detail.component.html)
 * - External styles (case-detail.component.css)
 * - Reactive signals for state management
 * - Standalone component architecture
 */
@Component({
  selector: 'app-case-detail',
  standalone: true,
  imports: [CommonModule, RouterLink, FormsModule],
  templateUrl: './case-detail.component.html',
  styleUrls: ['./case-detail.component.css'],
})
export class CaseDetailComponent implements OnInit, OnDestroy {
  // Dependency Injection
  private readonly caseService = inject(CaseService);
  private readonly route = inject(ActivatedRoute);
  private readonly router = inject(Router);
  private readonly confirm = inject(ConfirmService);

  // Subscription Management
  private readonly destroy$ = new Subject<void>();

  // Reactive State Management with Signals
  caseData = signal<Case | null>(null);
  tasks = signal<CaseTask[]>([]);
  loading = signal(true);
  error = signal<string | null>(null);
  editMode = signal(false);
  processing = signal(false);

  // Enum Arrays for Templates
  statuses = Object.values(CaseStatus);
  categories = Object.values(CaseCategory);
  severities = Object.values(IssueSeverity);
  taskStatuses = Object.values(CaseTaskStatus);

  // Expose enums to template
  CaseTaskStatus = CaseTaskStatus;

  // Form Data
  editedCase: Partial<Case> = {};
  newTask: Partial<CaseTask> = {
    status: CaseTaskStatus.PENDING,
  };

  // Modal States
  showTaskModal = false;
  showDeleteModal = false;

  // Computed Values
  completedTasksCount = computed(() => {
    return this.tasks().filter((t) => t.status === CaseTaskStatus.COMPLETED).length;
  });

  ngOnInit() {
    const id = this.route.snapshot.paramMap.get('id');
    if (id) {
      this.loadCase(+id);
      this.loadTasks(+id);
    }
  }

  ngOnDestroy() {
    this.destroy$.next();
    this.destroy$.complete();
  }

  /**
   * Load case details from backend
   */
  loadCase(id: number) {
    this.loading.set(true);
    this.error.set(null);

    this.caseService
      .getCase(id, true, false, true)
      .pipe(takeUntil(this.destroy$))
      .subscribe({
        next: (response) => {
          this.caseData.set(response.data);
          this.loading.set(false);
        },
        error: (err) => {
          this.error.set(err.error?.message || 'Failed to load case details. Please try again.');
          this.loading.set(false);
          console.error('Error loading case:', err);
        },
      });
  }

  /**
   * Load tasks associated with this case
   */
  loadTasks(caseId: number) {
    this.caseService
      .getCaseTasks(caseId)
      .pipe(takeUntil(this.destroy$))
      .subscribe({
        next: (response) => {
          const mapped = (response.data || []).map((t) => ({
            ...t,
            status: this.normalizeTaskStatus(t.status),
          }));
          this.tasks.set(mapped);
        },
        error: (err) => {
          console.error('Error loading tasks:', err);
        },
      });
  }

  private normalizeTaskStatus(status?: CaseTaskStatus | string | null): CaseTaskStatus {
    if (!status) return CaseTaskStatus.PENDING;
    const val = String(status).toUpperCase();
    switch (val) {
      case 'TODO':
      case 'PENDING':
        return CaseTaskStatus.PENDING;
      case 'IN_PROGRESS':
        return CaseTaskStatus.IN_PROGRESS;
      case 'DONE':
      case 'COMPLETED':
        return CaseTaskStatus.COMPLETED;
      case 'CANCELLED':
        return CaseTaskStatus.CANCELLED;
      default:
        return CaseTaskStatus.PENDING;
    }
  }

  /**
   * Toggle edit mode
   */
  toggleEdit() {
    if (this.editMode()) {
      this.cancelEdit();
    } else {
      this.editMode.set(true);
      this.editedCase = { ...this.caseData() } as Partial<Case>;
    }
  }

  /**
   * Save changes to the case
   */
  saveChanges() {
    if (!this.caseData()) return;

    this.processing.set(true);
    this.error.set(null);

    this.caseService
      .updateCase(this.caseData()!.id!, this.editedCase)
      .pipe(takeUntil(this.destroy$))
      .subscribe({
        next: (response) => {
          this.caseData.set(response.data);
          this.editMode.set(false);
          this.processing.set(false);
        },
        error: (err) => {
          this.error.set(err.error?.message || 'Failed to update case. Please try again.');
          this.processing.set(false);
          console.error('Error updating case:', err);
        },
      });
  }

  /**
   * Cancel edit mode
   */
  cancelEdit() {
    this.editMode.set(false);
    this.editedCase = {};
    this.error.set(null);
  }

  /**
   * Unlink an incident from this case
   */
  async unlinkIncident(incidentId: number) {
    if (
      !this.caseData() ||
      !(await this.confirm.confirm('Are you sure you want to unlink this incident from the case?'))
    )
      return;

    this.processing.set(true);
    this.error.set(null);

    this.caseService
      .unlinkIncident(this.caseData()!.id!, incidentId)
      .pipe(takeUntil(this.destroy$))
      .subscribe({
        next: () => {
          this.loadCase(this.caseData()!.id!);
          this.processing.set(false);
        },
        error: (err) => {
          this.error.set(err.error?.message || 'Failed to unlink incident. Please try again.');
          this.processing.set(false);
          console.error('Error unlinking incident:', err);
        },
      });
  }

  /**
   * Open task creation modal
   */
  openTaskModal() {
    this.showTaskModal = true;
    this.newTask = { status: CaseTaskStatus.PENDING };
    this.error.set(null);
  }

  /**
   * Close task creation modal
   */
  closeTaskModal() {
    this.showTaskModal = false;
    this.newTask = { status: CaseTaskStatus.PENDING };
  }

  /**
   * Create a new task
   */
  createTask() {
    if (!this.caseData() || !this.newTask.title) return;

    this.processing.set(true);
    this.error.set(null);

    const payload = {
      title: this.newTask.title,
      description: this.newTask.description,
      status: this.mapToBackendStatus(this.newTask.status),
      ownerUserId: (this.newTask as any).ownerUserId,
      dueAt: (this.newTask as any).dueDate || (this.newTask as any).dueAt,
    };

    this.caseService
      .createCaseTask(this.caseData()!.id!, payload as unknown as CaseTask)
      .pipe(takeUntil(this.destroy$))
      .subscribe({
        next: (response) => {
          const mapped = {
            ...response.data,
            status: this.normalizeTaskStatus(response.data.status),
          };
          this.tasks.update((tasks) => [...tasks, mapped]);
          this.showTaskModal = false;
          this.newTask = { status: CaseTaskStatus.PENDING };
          this.processing.set(false);
        },
        error: (err) => {
          this.error.set(err.error?.message || 'Failed to create task. Please try again.');
          this.processing.set(false);
          console.error('Error creating task:', err);
        },
      });
  }

  private mapToBackendStatus(status?: CaseTaskStatus): string {
    if (!status) return 'TODO';
    switch (status) {
      case CaseTaskStatus.PENDING:
        return 'TODO';
      case CaseTaskStatus.IN_PROGRESS:
        return 'IN_PROGRESS';
      case CaseTaskStatus.COMPLETED:
        return 'DONE';
      case CaseTaskStatus.CANCELLED:
        return 'CANCELLED';
      default:
        return 'TODO';
    }
  }

  /**
   * Delete a task
   */
  async deleteTask(taskId: number) {
    if (
      !this.caseData() ||
      !(await this.confirm.confirm('Are you sure you want to delete this task?'))
    )
      return;

    this.processing.set(true);
    this.error.set(null);

    this.caseService
      .deleteCaseTask(this.caseData()!.id!, taskId)
      .pipe(takeUntil(this.destroy$))
      .subscribe({
        next: () => {
          this.tasks.update((tasks) => tasks.filter((t) => t.id !== taskId));
          this.processing.set(false);
        },
        error: (err) => {
          this.error.set(err.error?.message || 'Failed to delete task. Please try again.');
          this.processing.set(false);
          console.error('Error deleting task:', err);
        },
      });
  }

  viewTask(taskId: number) {
    if (!taskId) return;
    this.router.navigate(['/tasks', taskId]);
  }

  /**
   * Delete the case
   */
  deleteCase() {
    if (!this.caseData()) return;

    this.processing.set(true);
    this.error.set(null);
    this.showDeleteModal = false;

    this.caseService
      .deleteCase(this.caseData()!.id!)
      .pipe(takeUntil(this.destroy$))
      .subscribe({
        next: () => {
          this.router.navigate(['/cases']);
        },
        error: (err) => {
          this.error.set(err.error?.message || 'Failed to delete case. Please try again.');
          this.processing.set(false);
          console.error('Error deleting case:', err);
        },
      });
  }

  // ============================================
  // Helper Methods for Template Formatting
  // ============================================

  /**
   * Get CSS class for case status badge
   */
  getStatusBadgeClass(status?: CaseStatus): string {
    const safeStatus = status ?? CaseStatus.OPEN;
    const statusLower = safeStatus.toLowerCase().replace(/_/g, '-');
    return `status-${statusLower}`;
  }

  /**
   * Format case status for display
   */
  formatStatus(status?: CaseStatus): string {
    const safeStatus = status ?? CaseStatus.OPEN;
    return safeStatus.replace(/_/g, ' ');
  }

  /**
   * Get CSS class for severity badge
   */
  getSeverityBadgeClass(severity?: IssueSeverity): string {
    const safeSeverity = severity ?? IssueSeverity.MEDIUM;
    const severityLower = safeSeverity.toLowerCase();
    return `sev-${severityLower}`;
  }

  /**
   * Format severity for display
   */
  formatSeverity(severity?: IssueSeverity): string {
    const safeSeverity = severity ?? IssueSeverity.MEDIUM;
    return safeSeverity.charAt(0).toUpperCase() + safeSeverity.slice(1).toLowerCase();
  }

  /**
   * Format category for display
   */
  formatCategory(category?: CaseCategory): string {
    if (!category) return 'N/A';
    const categoryMap: Record<CaseCategory, string> = {
      [CaseCategory.ACCIDENT]: 'Accident',
      [CaseCategory.THEFT]: 'Theft',
      [CaseCategory.DAMAGE]: 'Damage',
      [CaseCategory.COMPLAINT]: 'Complaint',
      [CaseCategory.VIOLATION]: 'Violation',
      [CaseCategory.FRAUD]: 'Fraud',
      [CaseCategory.OTHER]: 'Other',
    };
    return categoryMap[category] || category;
  }

  /**
   * Format file size in human-readable format
   */
  formatFileSize(bytes: number): string {
    if (!bytes) return '0 B';
    const sizes = ['B', 'KB', 'MB', 'GB'];
    const i = Math.floor(Math.log(bytes) / Math.log(1024));
    return Math.round((bytes / Math.pow(1024, i)) * 10) / 10 + ' ' + sizes[i];
  }

  /**
   * View attachment (to be implemented)
   */
  viewAttachment(id: number) {
    console.log('View attachment:', id);
    // TODO: Implement attachment viewer
  }

  /**
   * Download attachment (to be implemented)
   */
  downloadAttachment(id: number) {
    console.log('Download attachment:', id);
    // TODO: Implement attachment download
  }

  /**
   * Delete attachment with confirmation
   */
  async deleteAttachmentConfirm(id: number) {
    if (
      !this.caseData() ||
      !(await this.confirm.confirm(
        'Are you sure you want to delete this attachment? This action cannot be undone.',
      ))
    )
      return;

    this.processing.set(true);
    this.error.set(null);

    this.caseService
      .deleteAttachment(this.caseData()!.id!, id)
      .pipe(takeUntil(this.destroy$))
      .subscribe({
        next: () => {
          this.loadCase(this.caseData()!.id!);
          this.processing.set(false);
        },
        error: (err) => {
          this.error.set(err.error?.message || 'Failed to delete attachment. Please try again.');
          this.processing.set(false);
          console.error('Error deleting attachment:', err);
        },
      });
  }

  /**
   * Get CSS class for incident status badge
   */
  getIncidentStatusBadgeClass(status: string): string {
    const statusMap: Record<string, string> = {
      NEW: 'status-open',
      VALIDATED: 'status-investigation',
      UNDER_INVESTIGATION: 'status-investigation',
      RESOLVED: 'status-resolved',
      CLOSED: 'status-closed',
      ESCALATED: 'status-escalated',
    };
    return statusMap[status] || 'status-open';
  }

  /**
   * Get CSS class for task status badge
   */
  getTaskStatusBadgeClass(status?: CaseTaskStatus): string {
    const safeStatus = status || CaseTaskStatus.PENDING;
    const statusLower = safeStatus.toLowerCase().replace(/_/g, '-');
    return `task-${statusLower}`;
  }

  /**
   * Format task status for display
   */
  formatTaskStatus(status?: CaseTaskStatus): string {
    const safeStatus = status || CaseTaskStatus.PENDING;
    return safeStatus.replace(/_/g, ' ');
  }
}
