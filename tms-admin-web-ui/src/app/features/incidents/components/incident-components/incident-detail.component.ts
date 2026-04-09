import { CommonModule } from '@angular/common';
import { Component, inject, signal } from '@angular/core';
import {
  FormsModule,
  ReactiveFormsModule,
  FormBuilder,
  FormGroup,
  Validators,
} from '@angular/forms';
import { ActivatedRoute, Router, RouterLink } from '@angular/router';
import { catchError, forkJoin, map, of } from 'rxjs';

import type { ApiResponse, Incident } from '../../models/incident.model';
import { IncidentService } from '../../services/incident.service';
import { CaseService } from '../../services/case.service';
import { CaseCategory, IssueSeverity } from '../../models/incident.model';
import { TaskService } from '../../../../services/task.service';
import type { Task } from '../../../../models/task.model';
import { TaskStatus, TaskPriority } from '../../../../models/task.model';
import { AuthService } from '../../../../services/auth.service';
import { PERMISSIONS } from '../../../../shared/permissions';

/**
 * Incident Detail Component
 *
 * Displays comprehensive incident information and provides supervisor actions.
 *
 * Features:
 * - Full incident details with evidence and timeline
 * - Supervisor decision panel (validate, close, escalate)
 * - Escalation to case workflow with form
 * - Real-time status and SLA tracking
 * - Modal dialogs for actions
 *
 * Action Workflows:
 * - Close as Small Issue: Quick resolution with notes
 * - Validate Incident: Marks as validated for further investigation
 * - Escalate to Case: Creates formal investigation case
 *
 * Following Angular best practices:
 * - External template (incident-detail.component.html)
 * - External styles (incident-detail.component.css)
 * - Reactive forms with validation
 * - Standalone component architecture
 */
@Component({
  selector: 'app-incident-detail',
  standalone: true,
  imports: [CommonModule, FormsModule, ReactiveFormsModule, RouterLink],
  templateUrl: './incident-detail.component.html',
  styleUrls: ['./incident-detail.component.css'],
})
export class IncidentDetailComponent {
  // ============================================================
  // Dependency Injection
  // ============================================================
  private incidentService = inject(IncidentService);
  private caseService = inject(CaseService);
  private taskService = inject(TaskService);
  private authService = inject(AuthService);
  private router = inject(Router);
  private route = inject(ActivatedRoute);
  private fb = inject(FormBuilder);

  // ============================================================
  // State Management (Signals)
  // ============================================================
  incident = signal<Incident | null>(null);
  loading = signal(false);
  error = signal<string | null>(null);
  processing = signal(false);
  activeTab = signal<'overview' | 'timeline' | 'tasks' | 'attachments' | 'resolution'>('overview');
  tasks = signal<Task[]>([]);
  tasksLoading = signal(false);
  canReadTasks = signal(true);
  canCreateTasks = signal(true);
  canEscalateToCase = signal(false);
  openTaskMenuId = signal<number | null>(null);

  // ============================================================
  // UI State
  // ============================================================
  showCloseModal = false;
  showEscalateModal = false;
  resolutionNotes = '';

  // ============================================================
  // Forms
  // ============================================================
  escalateForm: FormGroup;

  // ============================================================
  // Configuration Data
  // ============================================================
  caseCategories = [
    { value: 'CUSTOMER_ESCALATION', label: 'Customer Escalation' },
    { value: 'SAFETY', label: 'Safety' },
    { value: 'HR_BEHAVIOR', label: 'HR / Behavior' },
    { value: 'ACCIDENT', label: 'Accident' },
  ];

  severityLevels = [
    { value: 'LOW', label: 'Low' },
    { value: 'MEDIUM', label: 'Medium' },
    { value: 'HIGH', label: 'High' },
    { value: 'CRITICAL', label: 'Critical' },
  ];

  // ============================================================
  // Constructor & Initialization
  // ============================================================
  constructor() {
    const id = this.route.snapshot.paramMap.get('id');
    this.canReadTasks.set(this.authService.hasPermission(PERMISSIONS.TASK_READ));
    this.canCreateTasks.set(
      this.authService.hasPermission(PERMISSIONS.TASK_CREATE) || this.canReadTasks(),
    );
    this.canEscalateToCase.set(
      this.authService.hasPermission(PERMISSIONS.CASE_CREATE) &&
        this.authService.hasPermission(PERMISSIONS.INCIDENT_ESCALATE),
    );
    if (id) {
      this.loadIncident(+id);
    }

    // Initialize escalate form
    this.escalateForm = this.fb.group({
      title: ['', [Validators.required, Validators.maxLength(255)]],
      description: ['', Validators.required],
      category: ['', Validators.required],
      severity: ['', Validators.required],
      assignedToUserId: [null],
      slaTargetDate: [''],
    });
  }

  // ============================================================
  // Form Helper Methods
  // ============================================================
  /**
   * Get current title field length for character counter
   */
  getTitleLength(): number {
    return this.escalateForm.get('title')?.value?.length || 0;
  }

  /**
   * Get current description field length for character counter
   */
  getDescriptionLength(): number {
    return this.escalateForm.get('description')?.value?.length || 0;
  }

  // ============================================================
  // Data Loading Methods
  // ============================================================
  /**
   * Load incident details by ID
   * @param id Incident ID
   */
  loadIncident(id: number) {
    this.loading.set(true);
    this.error.set(null);

    this.incidentService.getIncident(id).subscribe({
      next: (response: ApiResponse<Incident>) => {
        this.incident.set(response.data);
        this.loading.set(false);

        // Pre-fill escalation form when incident loads
        this.prefillEscalateForm(response.data);

        // Load related tasks
        this.loadTasksForIncident(response.data.id!);
      },
      error: (err: any) => {
        this.error.set('Failed to load incident details');
        this.loading.set(false);
        console.error('Error loading incident:', err);
      },
    });
  }

  /**
   * Load tasks related to this incident
   */
  loadTasksForIncident(incidentId: number) {
    if (!this.canReadTasks()) {
      this.tasks.set([]);
      this.tasksLoading.set(false);
      return;
    }
    this.tasksLoading.set(true);
    const driverId = this.incident()?.driverId;
    const vehicleId = this.incident()?.vehicleId;

    const requests = [
      this.taskService
        .getTasks({ relationType: 'INCIDENT', relationId: incidentId, sortBy: 'dueDate' }, 0, 200)
        .pipe(
          map((resp) => (resp.data?.content as Task[]) ?? []),
          catchError((err) => {
            this.handleTaskError(err);
            return of([]);
          }),
        ),
    ];

    if (driverId) {
      requests.push(
        this.taskService.getTasks({ driverId, sortBy: 'dueDate' }, 0, 200).pipe(
          map((resp) => (resp.data?.content as Task[]) ?? []),
          catchError((err) => {
            this.handleTaskError(err);
            return of([]);
          }),
        ),
      );
    }

    if (vehicleId) {
      requests.push(
        this.taskService.getTasks({ vehicleId, sortBy: 'dueDate' }, 0, 200).pipe(
          map((resp) => (resp.data?.content as Task[]) ?? []),
          catchError((err) => {
            this.handleTaskError(err);
            return of([]);
          }),
        ),
      );
    }

    forkJoin(requests).subscribe((taskSets) => {
      const merged = this.mergeTasksUnique(taskSets.flat());
      this.tasks.set(merged);
      this.tasksLoading.set(false);
    });
  }

  /**
   * Pre-fill escalation form with incident data
   * @param incident Incident to prefill from
   */
  prefillEscalateForm(incident: Incident) {
    // Smart pre-filling based on incident
    const suggestedCategory = this.mapIncidentGroupToCategory(incident.incidentGroup);

    this.escalateForm.patchValue({
      title: `${incident.title}`,
      description: `Escalated from Incident ${incident.code}:\n\n${incident.description}`,
      severity: incident.severity,
      category: suggestedCategory,
    });
  }

  /**
   * Map incident group to suggested case category
   * @param group Incident group
   * @returns Suggested case category
   */
  mapIncidentGroupToCategory(group: string): string {
    const mapping: Record<string, string> = {
      CUSTOMER: 'CUSTOMER_ESCALATION',
      TRAFFIC: 'SAFETY',
      BEHAVIOR: 'HR_BEHAVIOR',
      ACCIDENT: 'ACCIDENT',
      VEHICLE: 'SAFETY',
    };
    return mapping[group] || 'SAFETY';
  }

  // ============================================================
  // Incident Action Methods
  // ============================================================
  /**
   * Validate incident (supervisor action)
   */
  validateIncident() {
    const inc = this.incident();
    if (!inc?.id) return;

    this.processing.set(true);
    this.incidentService.validateIncident(inc.id!).subscribe({
      next: (response: ApiResponse<Incident>) => {
        this.loadIncident(inc.id!);
        this.processing.set(false);
      },
      error: (err: any) => {
        this.error.set('Failed to validate incident');
        this.processing.set(false);
        console.error('Error validating incident:', err);
      },
    });
  }

  /**
   * Open close incident modal
   */
  closeAsSmallIssue() {
    this.showCloseModal = true;
  }

  /**
   * Close incident with resolution notes
   */
  closeIncident() {
    const inc = this.incident();
    if (!inc?.id || !this.resolutionNotes.trim()) {
      this.error.set('Resolution notes are required');
      return;
    }

    this.processing.set(true);
    this.incidentService.closeIncident(inc.id!, this.resolutionNotes).subscribe({
      next: (response: ApiResponse<Incident>) => {
        this.showCloseModal = false;
        this.loadIncident(inc.id!);
        this.processing.set(false);
        this.resolutionNotes = '';
      },
      error: (err: any) => {
        this.error.set('Failed to close incident');
        this.processing.set(false);
        console.error('Error closing incident:', err);
      },
    });
  }

  /**
   * Navigate to case creation (legacy fallback — superseded by submitEscalation())
   */
  createCase() {
    const inc = this.incident();
    if (!inc?.id) return;
    if (!this.canEscalateToCase()) {
      this.error.set('You do not have permission to create and link cases from incidents');
      return;
    }

    this.processing.set(true);
    this.router.navigate(['/cases/create'], {
      queryParams: { incidentId: inc.id },
    });
    this.showEscalateModal = false;
    this.processing.set(false);
  }

  /**
   * Submit escalation form and create case
   */
  submitEscalation() {
    if (!this.canEscalateToCase()) {
      this.error.set('You do not have permission to escalate incidents to cases');
      return;
    }
    if (this.escalateForm.invalid) {
      this.escalateForm.markAllAsTouched();
      return;
    }

    const inc = this.incident();
    if (!inc?.id) return;

    this.processing.set(true);
    this.error.set(null);

    const assignedRaw = this.escalateForm.value.assignedToUserId;
    const parsedAssignedId =
      assignedRaw == null || assignedRaw === '' ? null : Number.parseInt(String(assignedRaw), 10);
    const caseData = {
      title: (this.escalateForm.value.title ?? '').trim(),
      description: (this.escalateForm.value.description ?? '').trim(),
      category: this.escalateForm.value.category,
      severity: this.escalateForm.value.severity,
      assignedToUserId:
        Number.isFinite(parsedAssignedId as number) && parsedAssignedId != null
          ? parsedAssignedId
          : undefined,
      slaTargetAt: this.escalateForm.value.slaTargetDate || undefined,
    };

    // Create the case
    this.caseService.createCase(caseData).subscribe({
      next: (response) => {
        const newCaseId = response.data.id!;

        // Link the incident to the case
        this.caseService.linkIncident(newCaseId, inc.id!).subscribe({
          next: () => {
            this.processing.set(false);
            this.showEscalateModal = false;
            this.router.navigate(['/cases', newCaseId]);
          },
          error: (err) => {
            console.error('Error linking incident:', err);
            this.processing.set(false);
            // Still navigate even if linking fails
            this.router.navigate(['/cases', newCaseId]);
          },
        });
      },
      error: (err) => {
        const backendMessage = err?.error?.message;
        this.error.set(backendMessage || 'Failed to create case. Please try again.');
        this.processing.set(false);
        console.error('Error creating case:', err);
      },
    });
  }

  /**
   * Close escalation modal and reset form
   */
  closeEscalateModal() {
    this.showEscalateModal = false;
    // Reset form when closing
    if (this.incident()) {
      this.prefillEscalateForm(this.incident()!);
    }
  }

  // ============================================================
  // Navigation Methods
  // ============================================================
  /**
   * Navigate back to incident list
   */
  goBack() {
    this.router.navigate(['/incidents']);
  }

  // ============================================================
  // UI Helper Methods
  // ============================================================
  /**
   * Set the active tab
   * @param tab Tab identifier
   */
  setActiveTab(tab: 'overview' | 'timeline' | 'tasks' | 'attachments' | 'resolution') {
    this.activeTab.set(tab);
  }

  /**
   * Get icon class for incident status
   * @param status Incident status
   * @returns Bootstrap icon class
   */
  getStatusIconClass(status: string): string {
    const icons: Record<string, string> = {
      NEW: 'bi-circle',
      VALIDATED: 'bi-check-circle',
      IN_PROGRESS: 'bi-arrow-repeat',
      RESOLVED: 'bi-check-circle-fill',
      CLOSED: 'bi-x-circle',
      ESCALATED: 'bi-arrow-up-circle',
    };
    return icons[status] || 'bi-circle';
  }

  /**
   * Get badge CSS class for severity level
   * @param severity Severity level
   * @returns CSS class name
   */
  getSeverityBadgeClass(severity: string): string {
    const classes: Record<string, string> = {
      LOW: 'badge-severity-low',
      MEDIUM: 'badge-severity-medium',
      HIGH: 'badge-severity-high',
      CRITICAL: 'badge-severity-critical',
    };
    return classes[severity] || 'badge-severity-medium';
  }

  /**
   * Get task count by status for summary cards
   * @param status Task status
   * @returns Number of tasks with that status
   */
  getTaskCount(status: string): number {
    const list = this.tasks();
    switch (status) {
      case 'NOT_STARTED':
        return list.filter((t) => t.status === TaskStatus.OPEN).length;
      case 'IN_PROGRESS':
        return list.filter((t) =>
          [TaskStatus.IN_PROGRESS, TaskStatus.IN_REVIEW, TaskStatus.ON_HOLD].includes(
            t.status as TaskStatus,
          ),
        ).length;
      case 'TESTING':
        return list.filter((t) => t.status === TaskStatus.IN_REVIEW).length;
      case 'AWAITING_FEEDBACK':
        return list.filter((t) => t.status === TaskStatus.BLOCKED).length;
      case 'COMPLETED':
        return list.filter((t) => t.status === TaskStatus.COMPLETED).length;
      default:
        return 0;
    }
  }

  /**
   * Check if supervisor actions can be taken on this incident
   * @returns True if actions are allowed
   */
  canTakeAction(): boolean {
    if (!this.incident()) return false;
    const status = this.incident()!.incidentStatus;
    return status !== 'CLOSED' && status !== 'ESCALATED';
  }

  /**
   * Check if incident has evidence attachments
   * @returns True if evidence exists
   */
  hasEvidence(): boolean {
    return (this.incident()?.photoUrls?.length ?? 0) > 0;
  }

  /**
   * View photo in modal or new tab
   * @param photoUrl Photo URL to view
   */
  viewPhoto(photoUrl: string) {
    window.open(photoUrl, '_blank');
  }

  /**
   * Navigate to unified task detail
   */
  viewTask(taskId?: number) {
    if (!taskId) return;
    this.router.navigate(['/tasks', taskId]);
  }

  toggleTaskMenu(id: number): void {
    this.openTaskMenuId.set(this.openTaskMenuId() === id ? null : id);
  }

  closeTaskMenu(): void {
    this.openTaskMenuId.set(null);
  }

  /**
   * Navigate to task creation pre-filled with incident relation
   */
  createTask() {
    const inc = this.incident();
    if (!inc?.id) return;
    this.router.navigate(['/tasks/create'], {
      queryParams: {
        relationType: 'INCIDENT',
        relationId: inc.id,
        relationCode: inc.code || `INC-${inc.id}`,
        title: inc.title,
      },
    });
  }

  /**
   * Get task priority badge class
   */
  getPriorityClass(priority?: TaskPriority | string): string {
    switch (priority) {
      case TaskPriority.CRITICAL:
        return 'badge badge-severity-critical';
      case TaskPriority.HIGH:
        return 'badge badge-severity-high';
      case TaskPriority.MEDIUM:
        return 'badge badge-severity-medium';
      case TaskPriority.LOW:
        return 'badge badge-severity-low';
      default:
        return 'badge badge-severity-medium';
    }
  }

  /**
   * User-friendly status label
   */
  getTaskStatusLabel(status?: TaskStatus | string): string {
    return this.taskService.getStatusLabel((status as TaskStatus) || TaskStatus.OPEN);
  }

  /**
   * User-friendly priority label
   */
  getTaskPriorityLabel(priority?: TaskPriority | string): string {
    return this.taskService.getPriorityLabel((priority as TaskPriority) || TaskPriority.MEDIUM);
  }

  /**
   * Task status badge class
   */
  getTaskStatusClass(status?: TaskStatus | string): string {
    switch (status) {
      case TaskStatus.OPEN:
        return 'badge-status-new';
      case TaskStatus.IN_PROGRESS:
      case TaskStatus.IN_REVIEW:
        return 'badge-status-in-progress';
      case TaskStatus.ON_HOLD:
      case TaskStatus.BLOCKED:
        return 'badge-status-escalated';
      case TaskStatus.COMPLETED:
        return 'badge-status-closed';
      case TaskStatus.CANCELLED:
        return 'badge-status-validated';
      default:
        return 'badge-status-new';
    }
  }

  /**
   * Format date with flexible format support
   * @param date Date to format (ISO string or array format)
   * @param format Format pattern (DD-MMM-YYYY, DD/MM/YYYY, YYYY-MM-DD, etc.)
   * @returns Formatted date string
   */
  formatDate(date: any, format: string = 'DD-MMM-YYYY'): string {
    if (!date) return 'N/A';

    let dateObj: Date;

    // Handle array format from backend [2025, 12, 6, 14, 30, 0]
    if (Array.isArray(date)) {
      const [year, month, day, hour = 0, minute = 0, second = 0] = date;
      dateObj = new Date(year, month - 1, day, hour, minute, second);
    } else {
      // Handle ISO string format
      dateObj = new Date(date);
    }

    if (isNaN(dateObj.getTime())) return 'Invalid Date';

    const pad = (n: number) => n.toString().padStart(2, '0');
    const months = [
      'JAN',
      'FEB',
      'MAR',
      'APR',
      'MAY',
      'JUN',
      'JUL',
      'AUG',
      'SEP',
      'OCT',
      'NOV',
      'DEC',
    ];

    const day = dateObj.getDate();
    const month = dateObj.getMonth();
    const year = dateObj.getFullYear();
    const hour = dateObj.getHours();
    const minute = dateObj.getMinutes();

    // Format mapping
    const replacements: Record<string, string> = {
      DD: pad(day),
      MMM: months[month],
      MM: pad(month + 1),
      YYYY: year.toString(),
      YY: year.toString().slice(-2),
      HH: pad(hour),
      mm: pad(minute),
    };

    let result = format;
    for (const [key, value] of Object.entries(replacements)) {
      result = result.replace(key, value);
    }

    return result;
  }

  /**
   * Format incident group for display
   * @param group Incident group enum value
   * @returns Formatted display string
   */
  formatGroup(group: string): string {
    return group?.replace(/_/g, ' ') || 'N/A';
  }

  /**
   * Format incident status for display
   * @param status Incident status enum value
   * @returns Formatted display string
   */
  formatStatus(status: string): string {
    return status?.replace(/_/g, ' ') || 'N/A';
  }

  /**
   * Get CSS class for severity badge
   * @param severity Severity level
   * @returns CSS class name
   */
  getSeverityClass(severity: string): string {
    return severity?.toLowerCase() || 'medium';
  }

  /**
   * Merge task arrays without duplicates
   */
  private mergeTasksUnique(list: Task[]): Task[] {
    const seen = new Set<string>();
    const merged: Task[] = [];

    list.forEach((task) => {
      const key = task.id ? `id-${task.id}` : task.code ? `code-${task.code}` : task.title;
      if (key && !seen.has(key)) {
        seen.add(key);
        merged.push(task);
      }
    });

    return merged;
  }

  /**
   * Handle task load errors gracefully
   */
  private handleTaskError(err: any) {
    if (err?.status === 403) {
      return;
    }
    this.error.set('Failed to load tasks');
    console.error('Failed to load tasks', err);
  }

  /**
   * Get CSS class for status badge
   * @param status Incident status
   * @returns CSS class name
   */
  getStatusClass(status: string): string {
    return status?.toLowerCase().replace(/_/g, '_') || 'new';
  }

  /**
   * Get SLA status text
   * @param incident Incident to check
   * @returns SLA status text
   */
  getSLAStatus(incident: Incident): string {
    if (incident.resolvedAt) return 'Resolved';
    // Placeholder - implement actual SLA calculation
    return 'On Time';
  }

  /**
   * Get SLA status CSS class
   * @param incident Incident to check
   * @returns CSS class for SLA status
   */
  getSLAClass(incident: Incident): string {
    if (incident.resolvedAt) return 'ontime';
    // Placeholder - implement actual SLA calculation
    return 'ontime';
  }

  completeTask(taskId: number): void {
    this.taskService.completeTask(taskId).subscribe({
      next: () => {
        const incId = this.incident()?.id;
        if (incId) this.loadTasksForIncident(incId);
      },
      error: (err) => console.error('Error completing task', err),
    });
  }

  deleteTask(taskId: number): void {
    this.taskService.deleteTask(taskId).subscribe({
      next: () => {
        const incId = this.incident()?.id;
        if (incId) this.loadTasksForIncident(incId);
      },
      error: (err) => console.error('Error deleting task', err),
    });
  }
}
