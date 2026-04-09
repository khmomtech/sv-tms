import { Component, signal, inject, type OnInit, DestroyRef } from '@angular/core';
import { takeUntilDestroyed } from '@angular/core/rxjs-interop';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { ActivatedRoute, Router, RouterLink } from '@angular/router';
import { NgSelectModule } from '@ng-select/ng-select';
import { ToastrService } from 'ngx-toastr';
import { Subject, debounceTime, distinctUntilChanged, map } from 'rxjs';
import { DomSanitizer, type SafeResourceUrl } from '@angular/platform-browser';

import {
  Task,
  TaskComment,
  TaskAttachment,
  TaskStatus,
  TaskPriority,
} from '../../../models/task.model';
import { TaskService } from '../../../services/task.service';
import { AuthService } from '../../../services/auth.service';
import { ConfirmService } from '../../../services/confirm.service';
import { IncidentService } from '../../../features/incidents/services/incident.service';
import type { Incident } from '../../../features/incidents/models/incident.model';
import { EmployeeService, type EmployeeDto } from '../../../services/employee.service';

@Component({
  selector: 'app-unified-task-detail',
  standalone: true,
  imports: [CommonModule, FormsModule, RouterLink, NgSelectModule],
  templateUrl: './unified-task-detail.component.html',
  styleUrls: ['./unified-task-detail.component.css'],
})
export class UnifiedTaskDetailComponent implements OnInit {
  private taskService = inject(TaskService);
  private authService = inject(AuthService);
  private route = inject(ActivatedRoute);
  private router = inject(Router);
  private toastr = inject(ToastrService);
  private confirm = inject(ConfirmService);
  private destroyRef = inject(DestroyRef);
  private sanitizer = inject(DomSanitizer);
  private incidentService = inject(IncidentService);
  private employeeService = inject(EmployeeService);

  task = signal<Task | null>(null);
  comments = signal<TaskComment[]>([]);
  attachments = signal<TaskAttachment[]>([]);
  assigneeOptions = signal<
    Array<{ id: number; label: string; email?: string; employeeCode?: string }>
  >([]);
  loading = signal(false);
  statusSaving = signal(false);
  prioritySaving = signal(false);
  dueDateSaving = signal(false);
  assigneeSaving = signal(false);
  linkSaving = signal(false);
  attachmentUploading = signal(false);
  previewAttachment = signal<TaskAttachment | null>(null);
  linkEditorOpen = signal(false);
  relationOptions = signal<Task[]>([]);
  incidentOptions = signal<Incident[]>([]);
  relationLoading = signal(false);
  relationSearch$ = new Subject<string>();
  employeeLoading = signal(false);
  employeeSearch$ = new Subject<string>();
  relationForm = signal<{ relationType: string; relationId: number | null }>({
    relationType: 'TASK',
    relationId: null,
  });
  relationTypeOptions = [
    { value: 'TASK', label: 'Task' },
    { value: 'INCIDENT', label: 'Incident' },
    { value: 'VEHICLE', label: 'Vehicle' },
    { value: 'CASE', label: 'Case' },
    { value: 'WORK_ORDER', label: 'Work Order' },
  ];

  // Comment form
  newComment = signal('');

  // Edit mode
  editMode = signal(false);
  editedTask = signal<Partial<Task>>({});

  // Enums
  taskStatuses = Object.values(TaskStatus);
  taskPriorities = Object.values(TaskPriority);

  // Current user
  currentUser = this.authService.getCurrentUser();

  ngOnInit(): void {
    this.setupRelationSearch();
    this.setupEmployeeSearch();
    this.employeeSearch$.next('');
    this.route.paramMap
      .pipe(
        map((params) => Number(params.get('id'))),
        distinctUntilChanged(),
        takeUntilDestroyed(this.destroyRef),
      )
      .subscribe((taskId) => {
        if (!Number.isFinite(taskId) || taskId <= 0) {
          this.toastr.error('Invalid task ID', 'Error');
          this.router.navigate(['/tasks']);
          return;
        }
        this.loadTask(taskId);
        this.loadComments(taskId);
        this.loadAttachments(taskId);
      });
  }

  loadTask(taskId: number): void {
    this.loading.set(true);

    this.taskService.getTaskById(taskId).subscribe({
      next: (response) => {
        if (response.success && response.data) {
          const normalized = this.normalizeTask(response.data);
          this.task.set(normalized);
          this.editedTask.set({ ...normalized });
          this.syncRelationForm(normalized);
          this.ensureSelectedAssigneeOption(normalized);
        }
        this.loading.set(false);
      },
      error: (error) => {
        console.error('Error loading task:', error);
        this.toastr.error('Failed to load task', 'Error');
        this.loading.set(false);
        this.router.navigate(['/tasks']);
      },
    });
  }

  loadComments(taskId: number): void {
    this.taskService.getTaskComments(taskId).subscribe({
      next: (response) => {
        if (response.success && response.data) {
          const mapped = response.data.map((c) => ({
            ...c,
            comment: (c as any).comment ?? (c as any).content ?? '',
            authorName: (c as any).authorName ?? (c as any).userName ?? (c as any).authorUsername,
            authorUsername: (c as any).authorUsername ?? (c as any).userName,
          }));
          this.comments.set(mapped);
        }
      },
      error: (error) => {
        console.error('Error loading comments:', error);
      },
    });
  }

  loadAttachments(taskId: number): void {
    this.taskService.getTaskAttachments(taskId).subscribe({
      next: (response) => {
        if (response.success && response.data) {
          this.attachments.set(
            response.data.map((file) => ({
              ...file,
              fileType: file.fileType ?? file.mimeType,
              fileSize: file.fileSize ?? file.fileSizeBytes,
              uploadedByName: file.uploadedByName ?? file.uploadedByUsername,
            })),
          );
        }
      },
      error: (error) => {
        console.error('Error loading attachments:', error);
      },
    });
  }

  addComment(): void {
    const comment = this.newComment().trim();
    if (!comment || !this.task()?.id) return;

    this.taskService.addTaskComment(this.task()!.id!, comment).subscribe({
      next: (response) => {
        if (response.success) {
          this.toastr.success('Comment added', 'Success');
          this.newComment.set('');
          this.loadComments(this.task()!.id!);
        }
      },
      error: (error) => {
        console.error('Error adding comment:', error);
        this.toastr.error('Failed to add comment', 'Error');
      },
    });
  }

  uploadAttachment(event: Event): void {
    const input = event.target as HTMLInputElement;
    if (!input.files?.length || !this.task()?.id) return;

    const file = input.files[0];
    const maxSizeBytes = 15 * 1024 * 1024;
    if (file.size > maxSizeBytes) {
      this.toastr.error('File is too large. Max size is 15 MB.', 'Error');
      input.value = '';
      return;
    }

    this.attachmentUploading.set(true);
    this.taskService.uploadTaskAttachment(this.task()!.id!, file).subscribe({
      next: (response) => {
        if (response.success) {
          this.toastr.success('Attachment uploaded', 'Success');
          this.loadAttachments(this.task()!.id!);
          input.value = ''; // Reset input
        }
      },
      error: (error) => {
        console.error('Error uploading attachment:', error);
        this.toastr.error('Failed to upload attachment', 'Error');
      },
      complete: () => this.attachmentUploading.set(false),
    });
  }

  toggleEditMode(): void {
    this.goToEditPage();
  }

  goToEditPage(): void {
    const id = this.task()?.id;
    if (!id) return;
    this.router.navigate(['/tasks', id, 'edit']);
  }

  saveTask(): void {
    const edited = this.editedTask();
    if (!this.task()?.id || !edited.title) return;

    this.loading.set(true);

    this.taskService.updateTask(this.task()!.id!, edited as Task).subscribe({
      next: (response) => {
        if (response.success && response.data) {
          const normalized = this.normalizeTask(response.data);
          this.task.set(normalized);
          this.editedTask.set({ ...normalized });
          this.editMode.set(false);
          this.toastr.success('Task updated', 'Success');
        }
        this.loading.set(false);
      },
      error: (error) => {
        console.error('Error updating task:', error);
        this.toastr.error('Failed to update task', 'Error');
        this.loading.set(false);
      },
    });
  }

  updateStatus(status: TaskStatus): void {
    if (!this.task()?.id) return;

    this.taskService.updateTaskStatus(this.task()!.id!, status).subscribe({
      next: (response) => {
        if (response.success && response.data) {
          const normalized = this.normalizeTask(response.data);
          this.task.set(normalized);
          this.editedTask.set({ ...normalized });
          this.toastr.success('Status updated', 'Success');
        }
      },
      error: (error) => {
        if (error?.status === 404) {
          const payload: Task = { ...(this.task() as Task), status };
          this.taskService.updateTask(this.task()!.id!, payload).subscribe({
            next: (resp) => {
              if (resp.success && resp.data) {
                const normalized = this.normalizeTask(resp.data);
                this.task.set(normalized);
                this.editedTask.set({ ...normalized });
                this.toastr.success('Status updated', 'Success');
              }
            },
            error: (err) => {
              console.error('Error updating status (fallback):', err);
              this.toastr.error('Failed to update status', 'Error');
            },
          });
          return;
        }
        console.error('Error updating status:', error);
        this.toastr.error('Failed to update status', 'Error');
      },
    });
  }

  updateProgress(progress: number): void {
    if (!this.task()?.id) return;

    this.taskService.updateTaskProgress(this.task()!.id!, progress).subscribe({
      next: (response) => {
        if (response.success && response.data) {
          this.task.set(response.data);
          this.toastr.success('Progress updated', 'Success');
        }
      },
      error: (error) => {
        console.error('Error updating progress:', error);
        this.toastr.error('Failed to update progress', 'Error');
      },
    });
  }

  completeTask(): void {
    if (!this.task()?.id) return;

    this.taskService.completeTask(this.task()!.id!).subscribe({
      next: (response) => {
        if (response.success && response.data) {
          this.task.set(response.data);
          this.toastr.success('Task completed', 'Success');
        }
      },
      error: (error) => {
        console.error('Error completing task:', error);
        this.toastr.error('Failed to complete task', 'Error');
      },
    });
  }

  async deleteTask(): Promise<void> {
    if (!this.task()?.id) return;

    if (await this.confirm.confirm(`Are you sure you want to delete task ${this.task()!.code}?`)) {
      this.taskService.deleteTask(this.task()!.id!).subscribe({
        next: (response) => {
          if (response.success) {
            this.toastr.success('Task deleted', 'Success');
            this.router.navigate(['/tasks']);
          }
        },
        error: (error) => {
          console.error('Error deleting task:', error);
          this.toastr.error('Failed to delete task', 'Error');
        },
      });
    }
  }

  getStatusLabel(status: TaskStatus): string {
    return this.taskService.getStatusLabel(status);
  }

  getStatusBadgeClass(status: TaskStatus): string {
    const base = 'inline-flex items-center gap-1 rounded-full px-3 py-1 text-xs font-semibold';
    const map: Record<TaskStatus, string> = {
      [TaskStatus.OPEN]: 'bg-blue-100 text-blue-700',
      [TaskStatus.IN_PROGRESS]: 'bg-indigo-100 text-indigo-700',
      [TaskStatus.BLOCKED]: 'bg-orange-100 text-orange-700',
      [TaskStatus.ON_HOLD]: 'bg-amber-100 text-amber-800',
      [TaskStatus.IN_REVIEW]: 'bg-purple-100 text-purple-700',
      [TaskStatus.COMPLETED]: 'bg-emerald-100 text-emerald-700',
      [TaskStatus.CANCELLED]: 'bg-rose-100 text-rose-700',
    };
    return `${base} ${map[status] || 'bg-gray-100 text-gray-700'}`;
  }

  getPriorityLabel(priority: TaskPriority): string {
    return this.taskService.getPriorityLabel(priority);
  }

  /**
   * Ensure status/priority values align with enum strings so select bindings render.
   */
  private normalizeTask(task: Task): Task {
    const normalizedStatus = (task.status as string | undefined)?.toUpperCase() as
      | TaskStatus
      | undefined;
    const normalizedPriority = (task.priority as string | undefined)?.toUpperCase() as
      | TaskPriority
      | undefined;
    return {
      ...task,
      createdDate: task.createdDate ?? task.createdAt,
      updatedDate: task.updatedDate ?? task.updatedAt,
      createdByFullName: task.createdByFullName ?? task.createdByName ?? task.createdByUsername,
      status:
        normalizedStatus && TaskStatus[normalizedStatus as keyof typeof TaskStatus]
          ? normalizedStatus
          : TaskStatus.OPEN,
      priority:
        normalizedPriority && TaskPriority[normalizedPriority as keyof typeof TaskPriority]
          ? normalizedPriority
          : TaskPriority.MEDIUM,
    };
  }

  getPriorityBadgeClass(priority: TaskPriority): string {
    const base = 'inline-flex items-center gap-1 rounded-full px-3 py-1 text-xs font-semibold';
    const map: Record<TaskPriority, string> = {
      [TaskPriority.LOW]: 'bg-emerald-50 text-emerald-700',
      [TaskPriority.MEDIUM]: 'bg-blue-50 text-blue-700',
      [TaskPriority.HIGH]: 'bg-amber-50 text-amber-800',
      [TaskPriority.CRITICAL]: 'bg-rose-50 text-rose-700',
    };
    return `${base} ${map[priority] || 'bg-gray-100 text-gray-700'}`;
  }

  isOverdue(): boolean {
    return this.task()?.isOverdue || this.taskService.isTaskOverdue(this.task()!);
  }

  copyRelationCode(): void {
    const task = this.task();
    const code = task?.relationCode || (task?.relationId ? String(task.relationId) : '');
    if (!code) {
      this.toastr.info('No related code to copy', 'Info');
      return;
    }
    if (!navigator?.clipboard) {
      this.toastr.error('Clipboard not available', 'Error');
      return;
    }
    navigator.clipboard
      .writeText(code)
      .then(() => this.toastr.success('Copied related code', 'Success'))
      .catch(() => this.toastr.error('Copy failed', 'Error'));
  }

  updateStatusInline(status: TaskStatus | string): void {
    if (!this.task()?.id || this.statusSaving()) return;
    this.statusSaving.set(true);
    const nextStatus = status as TaskStatus;
    this.taskService.updateTaskStatus(this.task()!.id!, nextStatus).subscribe({
      next: (response) => {
        if (response.success && response.data) {
          const normalized = this.normalizeTask(response.data);
          this.task.set(normalized);
          this.editedTask.set({ ...normalized });
          this.toastr.success('Status updated', 'Success');
        }
      },
      error: (error) => {
        if (error?.status === 404) {
          const payload: Task = { ...(this.task() as Task), status: nextStatus };
          this.taskService.updateTask(this.task()!.id!, payload).subscribe({
            next: (resp) => {
              if (resp.success && resp.data) {
                const normalized = this.normalizeTask(resp.data);
                this.task.set(normalized);
                this.editedTask.set({ ...normalized });
                this.toastr.success('Status updated', 'Success');
              }
            },
            error: (err) => {
              console.error('Error updating status (fallback):', err);
              this.toastr.error('Failed to update status', 'Error');
            },
            complete: () => this.statusSaving.set(false),
          });
          return;
        }
        console.error('Error updating status:', error);
        this.toastr.error('Failed to update status', 'Error');
      },
      complete: () => this.statusSaving.set(false),
    });
  }

  updatePriorityInline(priority: TaskPriority | string): void {
    if (!this.task()?.id || this.prioritySaving()) return;
    this.prioritySaving.set(true);
    const nextPriority = priority as TaskPriority;
    const payload: Task = { ...(this.task() as Task), priority: nextPriority };
    this.taskService.updateTask(this.task()!.id!, payload).subscribe({
      next: (response) => {
        if (response.success && response.data) {
          const normalized = this.normalizeTask(response.data);
          this.task.set(normalized);
          this.editedTask.set({ ...normalized });
          this.toastr.success('Priority updated', 'Success');
        }
      },
      error: (error) => {
        console.error('Error updating priority:', error);
        this.toastr.error('Failed to update priority', 'Error');
      },
      complete: () => this.prioritySaving.set(false),
    });
  }

  updateDueDateInline(dateValue: string): void {
    if (!this.task()?.id || this.dueDateSaving()) return;
    this.dueDateSaving.set(true);
    const iso = this.parseDateToIso(dateValue);
    if (dateValue && !iso) {
      this.toastr.error('Invalid due date', 'Error');
      this.dueDateSaving.set(false);
      return;
    }
    const payload: Task = { ...(this.task() as Task), dueDate: iso || undefined };
    this.taskService.updateTask(this.task()!.id!, payload).subscribe({
      next: (response) => {
        if (response.success && response.data) {
          const normalized = this.normalizeTask(response.data);
          this.task.set(normalized);
          this.editedTask.set({ ...normalized });
          this.toastr.success('Due date updated', 'Success');
        }
      },
      error: (error) => {
        console.error('Error updating due date:', error);
        this.toastr.error('Failed to update due date', 'Error');
      },
      complete: () => this.dueDateSaving.set(false),
    });
  }

  clearDueDateInline(): void {
    this.updateDueDateInline('');
  }

  /**
   * Normalize a date string from backend or input into yyyy-MM-dd for form controls.
   */
  formatDateForInput(value?: unknown): string {
    if (value === null || value === undefined) return '';

    // Date object
    if (typeof value === 'object' && value instanceof Date) {
      if (!Number.isNaN(value.getTime())) return this.formatDateParts(value);
    }

    // Array format [yyyy, mm, dd, hh?, mm?]
    if (Array.isArray(value)) {
      const [y, m, d, hh = 0, mm = 0] = value as any[];
      const parsedArr = new Date(Number(y), Number(m) - 1, Number(d), Number(hh), Number(mm));
      if (!Number.isNaN(parsedArr.getTime())) return this.formatDateParts(parsedArr);
    }

    // String formats
    if (typeof value === 'string') {
      const parsed = new Date(value);
      if (!Number.isNaN(parsed.getTime())) {
        return this.formatDateParts(parsed);
      }
      // Fallback for comma-separated formats like "2025,12,23,0,0"
      const parts = String(value)
        .split(',')
        .map((p) => Number(p.trim()));
      if (parts.length >= 3 && parts.every((n) => !Number.isNaN(n))) {
        const fallback = new Date(
          parts[0],
          (parts[1] ?? 1) - 1,
          parts[2] ?? 1,
          parts[3] ?? 0,
          parts[4] ?? 0,
        );
        if (!Number.isNaN(fallback.getTime())) {
          return this.formatDateParts(fallback);
        }
      }
    }

    return '';
  }

  /**
   * Convert an input date (yyyy-MM-dd) to ISO string; return null to clear.
   */
  private parseDateToIso(dateValue: string | null | undefined): string | null {
    if (!dateValue) return null;
    const [year, month, day] = dateValue.split('-').map(Number);
    if (!year || !month || !day) return null;
    const parsed = new Date(year, month - 1, day, 0, 0, 0, 0);
    if (!Number.isNaN(parsed.getTime())) {
      return parsed.toISOString();
    }
    return null;
  }

  private formatDateParts(value: Date): string {
    const year = value.getFullYear();
    const month = (value.getMonth() + 1).toString().padStart(2, '0');
    const day = value.getDate().toString().padStart(2, '0');
    return `${year}-${month}-${day}`;
  }

  /**
   * Human-friendly date display like 09-Dec-2025.
   */
  formatDateHuman(value?: unknown): string {
    if (!value) return '';
    const dateObj = this.toDate(value);
    if (!dateObj || Number.isNaN(dateObj.getTime())) return '';

    const day = dateObj.getDate().toString().padStart(2, '0');
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    const month = months[dateObj.getMonth()];
    const year = dateObj.getFullYear();
    return `${day}-${month}-${year}`;
  }

  /**
   * Human-friendly datetime display like 20-Dec-2025 17:44.
   */
  formatDateTime(value?: unknown, includeSeconds = false): string {
    const dateObj = this.toDate(value);
    if (!dateObj || Number.isNaN(dateObj.getTime())) return '';

    const pad = (n: number) => n.toString().padStart(2, '0');
    const day = pad(dateObj.getDate());
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    const month = months[dateObj.getMonth()];
    const year = dateObj.getFullYear();
    const hh = pad(dateObj.getHours());
    const mm = pad(dateObj.getMinutes());
    const ss = pad(dateObj.getSeconds());
    return includeSeconds
      ? `${day}-${month}-${year} ${hh}:${mm}:${ss}`
      : `${day}-${month}-${year} ${hh}:${mm}`;
  }

  /**
   * Safely convert backend date shapes (Date, array, string, comma-separated) into a Date.
   */
  private toDate(value?: unknown): Date | null {
    if (value === null || value === undefined) return null;
    if (typeof value === 'object' && value instanceof Date) {
      return value;
    }
    if (Array.isArray(value)) {
      const [y, m, d, hh = 0, mm = 0, ss = 0, ms = 0] = value as any[];
      const parsedArr = new Date(
        Number(y),
        Number(m) - 1,
        Number(d),
        Number(hh),
        Number(mm),
        Number(ss),
        Number(ms),
      );
      return Number.isNaN(parsedArr.getTime()) ? null : parsedArr;
    }
    if (typeof value === 'string') {
      const parsed = new Date(value);
      if (!Number.isNaN(parsed.getTime())) return parsed;
      const parts = value.split(',').map((p) => Number(p.trim()));
      if (parts.length >= 3) {
        const parsedParts = new Date(
          parts[0],
          (parts[1] ?? 1) - 1,
          parts[2] ?? 1,
          parts[3] ?? 0,
          parts[4] ?? 0,
          parts[5] ?? 0,
          parts[6] ?? 0,
        );
        return Number.isNaN(parsedParts.getTime()) ? null : parsedParts;
      }
    }
    return null;
  }

  updateAssigneeInline(userId: string | number | null): void {
    if (!this.task()?.id || this.assigneeSaving()) return;
    const parsed = userId === null || userId === '' ? null : Number(userId);
    this.assigneeSaving.set(true);

    if (parsed === null || Number.isNaN(parsed)) {
      const payload: Task = {
        ...(this.task() as Task),
        assignedToId: undefined,
        assignedToFullName: undefined,
        assignedToUsername: undefined,
      };
      this.taskService.updateTask(this.task()!.id!, payload).subscribe({
        next: (response) => {
          if (response.success && response.data) {
            const normalized = this.normalizeTask(response.data);
            this.task.set(normalized);
            this.editedTask.set({ ...normalized });
            this.ensureSelectedAssigneeOption(normalized);
            this.toastr.success('Assignee cleared', 'Success');
          }
        },
        error: (error) => {
          console.error('Error clearing assignee:', error);
          this.toastr.error('Failed to clear assignee', 'Error');
        },
        complete: () => this.assigneeSaving.set(false),
      });
      return;
    }

    this.taskService.assignTask(this.task()!.id!, parsed).subscribe({
      next: (response) => {
        if (response.success && response.data) {
          const normalized = this.normalizeTask(response.data);
          this.task.set(normalized);
          this.editedTask.set({ ...normalized });
          this.ensureSelectedAssigneeOption(normalized);
          this.toastr.success('Assignee updated', 'Success');
        }
      },
      error: (error) => {
        // Fallback for older backends that don't expose /assign endpoint
        if (error?.status === 404) {
          const payload: Task = {
            ...(this.task() as Task),
            assignedToId: parsed,
          };
          this.taskService.updateTask(this.task()!.id!, payload).subscribe({
            next: (resp) => {
              if (resp.success && resp.data) {
                const normalized = this.normalizeTask(resp.data);
                this.task.set(normalized);
                this.editedTask.set({ ...normalized });
                this.ensureSelectedAssigneeOption(normalized);
                this.toastr.success('Assignee updated', 'Success');
              }
            },
            error: (err) => {
              console.error('Error updating assignee (fallback):', err);
              this.toastr.error('Failed to update assignee', 'Error');
            },
            complete: () => this.assigneeSaving.set(false),
          });
          return;
        }
        console.error('Error updating assignee:', error);
        this.toastr.error('Failed to update assignee', 'Error');
      },
      complete: () => this.assigneeSaving.set(false),
    });
  }

  clearAssigneeInline(): void {
    this.updateAssigneeInline(null);
  }

  toggleLinkEditor(): void {
    const current = this.task();
    if (!current) return;

    const next = !this.linkEditorOpen();
    this.linkEditorOpen.set(next);
    if (next) {
      this.syncRelationForm(current);
      if (this.isSearchableRelationType(this.relationForm().relationType)) {
        this.relationSearch$.next('');
      } else {
        this.relationOptions.set([]);
        this.incidentOptions.set([]);
      }
    }
  }

  saveLinkedEntity(): void {
    const current = this.task();
    if (!current?.id || this.linkSaving()) return;
    const currentId = current.id;

    const form = this.relationForm();
    const nextRelationId =
      form.relationId === null || Number.isNaN(Number(form.relationId))
        ? null
        : Number(form.relationId);

    const payload: Task = {
      ...(current as Task),
      relationType: this.normalizeRelationType(form.relationType),
      relationId: nextRelationId ?? undefined,
    };
    const relationCode = this.getSelectedRelationCode(payload.relationType, nextRelationId);
    const optimisticTask: Task = {
      ...(current as Task),
      relationType: payload.relationType,
      relationId: payload.relationId,
      relationCode: relationCode || (nextRelationId ? String(nextRelationId) : undefined),
    };

    this.linkSaving.set(true);
    this.taskService.updateTask(currentId, payload).subscribe({
      next: (response) => {
        if (response.success) {
          const merged = {
            ...optimisticTask,
            ...(response.data || {}),
          } as Task;
          const normalized = this.normalizeTask(merged);
          this.task.set(normalized);
          this.editedTask.set({ ...normalized });
          this.syncRelationForm(normalized);
          this.linkEditorOpen.set(false);
          this.toastr.success('Linked entity updated', 'Success');
          // Ensure we show authoritative backend data even if update response is partial
          this.loadTask(currentId);
        }
      },
      error: (error) => {
        console.error('Error updating linked entity:', error);
        this.toastr.error('Failed to update linked entity', 'Error');
      },
      complete: () => this.linkSaving.set(false),
    });
  }

  clearLinkedEntity(): void {
    const current = this.task();
    if (!current?.id || this.linkSaving()) return;

    const payload: Task = {
      ...(current as Task),
      relationType: undefined,
      relationId: undefined,
      relationCode: undefined,
    };

    this.linkSaving.set(true);
    this.taskService.updateTask(current.id, payload).subscribe({
      next: (response) => {
        if (response.success && response.data) {
          const normalized = this.normalizeTask(response.data);
          this.task.set(normalized);
          this.editedTask.set({ ...normalized });
          this.syncRelationForm(normalized);
          this.linkEditorOpen.set(false);
          this.toastr.success('Linked entity removed', 'Success');
        }
      },
      error: (error) => {
        console.error('Error clearing linked entity:', error);
        this.toastr.error('Failed to remove linked entity', 'Error');
      },
      complete: () => this.linkSaving.set(false),
    });
  }

  updateRelationType(value: string): void {
    const normalized = this.normalizeRelationType(value);
    this.relationForm.update((form) => ({ ...form, relationType: normalized, relationId: null }));
    if (this.isSearchableRelationType(normalized)) {
      this.relationSearch$.next('');
    } else {
      this.relationOptions.set([]);
      this.incidentOptions.set([]);
    }
  }

  updateRelationId(value: string | number | null): void {
    if (value === null || value === '' || value === undefined) {
      this.relationForm.update((form) => ({ ...form, relationId: null }));
      return;
    }
    const parsed = Number(value);
    this.relationForm.update((form) => ({
      ...form,
      relationId: Number.isNaN(parsed) ? null : parsed,
    }));
  }

  canSaveLinkedEntity(): boolean {
    if (this.linkSaving()) return false;
    const form = this.relationForm();
    if (!form.relationType) return false;
    return form.relationId !== null && !Number.isNaN(Number(form.relationId));
  }

  private syncRelationForm(task: Task): void {
    this.relationForm.set({
      relationType: this.normalizeRelationType(task.relationType),
      relationId: task.relationId ?? null,
    });
  }

  private normalizeRelationType(value?: string | null): string {
    if (!value) return 'TASK';
    return String(value).toUpperCase();
  }

  private setupRelationSearch(): void {
    this.relationSearch$
      .pipe(debounceTime(250), distinctUntilChanged(), takeUntilDestroyed(this.destroyRef))
      .subscribe((term) => {
        const type = this.relationForm().relationType;
        if (type === 'TASK') {
          this.searchTaskRelations(term);
          return;
        }
        if (type === 'INCIDENT') {
          this.searchIncidentRelations(term);
          return;
        }
      });
  }

  private setupEmployeeSearch(): void {
    this.employeeSearch$
      .pipe(debounceTime(250), distinctUntilChanged(), takeUntilDestroyed(this.destroyRef))
      .subscribe((term) => this.searchEmployees(term));
  }

  private searchEmployees(term: string): void {
    this.employeeLoading.set(true);
    this.employeeService.list({ search: term || '', page: 0, size: 50 }).subscribe({
      next: (response) => {
        const content = (response.data?.content ?? []) as EmployeeDto[];
        const mapped = content
          .filter((e) => e.userId !== null && e.userId !== undefined)
          .map((e) => ({
            id: Number(e.userId),
            label: this.getEmployeeLabel(e),
            email: e.email,
            employeeCode: e.employeeCode,
          }));
        const dedup = mapped.filter(
          (item, index, arr) => arr.findIndex((x) => x.id === item.id) === index,
        );
        this.assigneeOptions.set(dedup);
        this.ensureSelectedAssigneeOption(this.task());
      },
      error: (error) => {
        console.error('Error loading employees for assignee:', error);
        this.assigneeOptions.set([]);
      },
      complete: () => this.employeeLoading.set(false),
    });
  }

  private getEmployeeLabel(employee: EmployeeDto): string {
    const fullName = `${employee.firstName || ''} ${employee.lastName || ''}`.trim();
    if (employee.employeeCode && fullName) return `${employee.employeeCode} - ${fullName}`;
    if (fullName) return fullName;
    if (employee.email) return employee.email;
    return `Employee #${employee.id ?? ''}`;
  }

  private ensureSelectedAssigneeOption(task: Task | null): void {
    if (!task?.assignedToId) return;
    const assignedId = Number(task.assignedToId);
    if (!Number.isFinite(assignedId)) return;
    this.assigneeOptions.update((options) => {
      if (options.some((o) => o.id === assignedId)) return options;
      const label =
        (task.assignedToFullName && task.assignedToFullName.trim()) ||
        task.assignedToUsername ||
        `User #${assignedId}`;
      return [{ id: assignedId, label }, ...options];
    });
  }

  private searchTaskRelations(term: string): void {
    if (this.relationForm().relationType !== 'TASK') return;

    this.relationLoading.set(true);
    this.taskService.getTasks({ keyword: term || '' }, 0, 20).subscribe({
      next: (response) => {
        const items = (response.data?.content ?? []) as Task[];
        const currentTaskId = this.task()?.id;
        this.relationOptions.set(items.filter((item) => item.id !== currentTaskId));
      },
      error: (error) => {
        console.error('Error searching relation tasks:', error);
        this.relationOptions.set([]);
      },
      complete: () => this.relationLoading.set(false),
    });
  }

  private searchIncidentRelations(term: string): void {
    if (this.relationForm().relationType !== 'INCIDENT') return;

    this.relationLoading.set(true);
    this.incidentService.listIncidents({ search: term || '' }, 0, 20).subscribe({
      next: (response) => {
        const items = (response.data?.content ?? []) as Incident[];
        this.incidentOptions.set(items);
      },
      error: (error) => {
        console.error('Error searching relation incidents:', error);
        this.incidentOptions.set([]);
      },
      complete: () => this.relationLoading.set(false),
    });
  }

  private isSearchableRelationType(type: string): boolean {
    return type === 'TASK' || type === 'INCIDENT';
  }

  private getSelectedRelationCode(
    type: string | undefined,
    relationId: number | null,
  ): string | undefined {
    if (!relationId) return undefined;
    if (type === 'TASK') {
      return this.relationOptions().find((item) => item.id === relationId)?.code;
    }
    if (type === 'INCIDENT') {
      return this.incidentOptions().find((item) => item.id === relationId)?.code;
    }
    return undefined;
  }

  isImageAttachment(file: TaskAttachment): boolean {
    const type = (file.fileType || '').toLowerCase();
    const name = (file.fileName || '').toLowerCase();
    return (
      type.startsWith('image/') ||
      ['.jpg', '.jpeg', '.png', '.gif', '.webp', '.bmp', '.svg'].some((ext) => name.endsWith(ext))
    );
  }

  isPdfAttachment(file: TaskAttachment): boolean {
    const type = (file.fileType || '').toLowerCase();
    const name = (file.fileName || '').toLowerCase();
    return type === 'application/pdf' || name.endsWith('.pdf');
  }

  isTextAttachment(file: TaskAttachment): boolean {
    const type = (file.fileType || '').toLowerCase();
    const name = (file.fileName || '').toLowerCase();
    return (
      type.startsWith('text/') ||
      ['.txt', '.md', '.json', '.csv', '.log', '.xml'].some((ext) => name.endsWith(ext))
    );
  }

  canPreviewAttachment(file: TaskAttachment): boolean {
    return (
      this.isImageAttachment(file) || this.isPdfAttachment(file) || this.isTextAttachment(file)
    );
  }

  openAttachmentPreview(file: TaskAttachment): void {
    if (!this.canPreviewAttachment(file)) {
      window.open(file.fileUrl, '_blank', 'noopener,noreferrer');
      return;
    }
    this.previewAttachment.set(file);
  }

  closeAttachmentPreview(): void {
    this.previewAttachment.set(null);
  }

  formatFileSize(size?: number): string {
    if (size === null || size === undefined || Number.isNaN(size)) return '';
    if (size < 1024) return `${size} B`;
    const kb = size / 1024;
    if (kb < 1024) return `${kb.toFixed(1)} KB`;
    const mb = kb / 1024;
    if (mb < 1024) return `${mb.toFixed(1)} MB`;
    const gb = mb / 1024;
    return `${gb.toFixed(1)} GB`;
  }

  sortedAttachments(): TaskAttachment[] {
    return [...this.attachments()].sort((a, b) => {
      const ta = a.uploadedAt ? new Date(a.uploadedAt).getTime() : 0;
      const tb = b.uploadedAt ? new Date(b.uploadedAt).getTime() : 0;
      if (tb !== ta) return tb - ta;
      const ia = a.id ?? 0;
      const ib = b.id ?? 0;
      return ib - ia;
    });
  }

  getAttachmentIconClass(file: TaskAttachment): string {
    if (this.isImageAttachment(file)) return 'bi bi-file-earmark-image text-blue-600';
    if (this.isPdfAttachment(file)) return 'bi bi-file-earmark-pdf text-red-600';
    if (this.isTextAttachment(file)) return 'bi bi-file-earmark-text text-indigo-600';
    return 'bi bi-file-earmark text-gray-500';
  }

  getPreviewUrl(file: TaskAttachment | null): SafeResourceUrl | null {
    if (!file?.fileUrl) return null;
    return this.sanitizer.bypassSecurityTrustResourceUrl(file.fileUrl);
  }
}
