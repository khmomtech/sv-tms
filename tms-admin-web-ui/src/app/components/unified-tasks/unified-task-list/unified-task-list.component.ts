import { Component, signal, inject, type OnInit } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { Router, RouterLink, ActivatedRoute } from '@angular/router';
import { ToastrService } from 'ngx-toastr';
import { debounceTime, Subject } from 'rxjs';

import { Task, TaskStatus, TaskPriority, TaskStatistics } from '../../../models/task.model';
import { TaskService } from '../../../services/task.service';
import { AuthService } from '../../../services/auth.service';
import { PERMISSIONS } from '../../../shared/permissions';

@Component({
  selector: 'app-unified-task-list',
  standalone: true,
  imports: [CommonModule, FormsModule, RouterLink],
  templateUrl: './unified-task-list.component.html',
  styleUrls: ['./unified-task-list.component.css'],
})
export class UnifiedTaskListComponent implements OnInit {
  private taskService = inject(TaskService);
  private authService = inject(AuthService);
  private toastr = inject(ToastrService);
  private router = inject(Router);
  private route = inject(ActivatedRoute);

  tasks = signal<Task[]>([]);
  statistics = signal<TaskStatistics | null>(null);
  loading = signal(false);

  // Pagination
  currentPage = signal(0);
  pageSize = signal(10);
  totalPages = signal(0);
  totalElements = signal(0);

  // Filters
  searchKeyword = signal('');
  selectedStatus = signal<TaskStatus | ''>('');
  selectedPriority = signal<TaskPriority | ''>('');
  selectedRelationType = signal<string>('');
  showOnlyOverdue = signal(false);

  // Search debounce
  private searchSubject = new Subject<string>();

  // Enums for dropdowns
  taskStatuses = Object.values(TaskStatus);
  taskPriorities = Object.values(TaskPriority);

  // Modal state
  showAdvancedFilters = signal(false);
  taskToDelete: Task | null = null;
  canReadTasks = signal(true);
  canCreateTasks = signal(true);
  openMenuTaskId = signal<number | null>(null);

  // Math for template
  readonly Math = Math;

  ngOnInit(): void {
    const allowedRead = this.authService.hasPermission(PERMISSIONS.TASK_READ);
    const allowedCreate = this.authService.hasPermission(PERMISSIONS.TASK_CREATE);
    this.canReadTasks.set(allowedRead);
    this.canCreateTasks.set(allowedCreate || allowedRead); // superadmin fallback
    if (allowedRead) {
      this.loadStatistics();
      this.loadTasks();
      this.setupSearchDebounce();
    } else {
      this.loading.set(false);
    }
    this.handleQueryPrefill();
  }

  private setupSearchDebounce(): void {
    this.searchSubject.pipe(debounceTime(500)).subscribe((keyword) => {
      this.searchKeyword.set(keyword);
      this.currentPage.set(0);
      this.loadTasks();
    });
  }

  onSearchInput(event: Event): void {
    const keyword = (event.target as HTMLInputElement).value;
    this.searchSubject.next(keyword);
  }

  loadStatistics(): void {
    if (!this.canReadTasks()) return;
    this.taskService.getTaskStatistics().subscribe({
      next: (response) => {
        if (response.success && response.data) {
          this.statistics.set(response.data);
        }
      },
      error: (error) => {
        if (error?.status === 403) {
          // Gracefully degrade when user lacks task permissions
          this.statistics.set(null);
          return;
        }
        console.error('Error loading task statistics:', error);
      },
    });
  }

  loadTasks(): void {
    if (!this.canReadTasks()) {
      this.tasks.set([]);
      this.totalPages.set(0);
      this.totalElements.set(0);
      this.loading.set(false);
      return;
    }
    this.loading.set(true);

    this.taskService
      .getUnifiedTasks(
        this.currentPage(),
        this.pageSize(),
        this.searchKeyword() || undefined,
        this.selectedStatus() || undefined,
        this.selectedPriority() || undefined,
        this.selectedRelationType() || undefined,
        undefined, // assignedToId
        undefined, // createdById
        this.showOnlyOverdue() || undefined,
      )
      .subscribe({
        next: (response) => {
          if (response.success && response.data) {
            this.tasks.set(response.data.content);
            this.totalPages.set(response.data.totalPages);
            this.totalElements.set(response.data.totalElements);
          }
          this.loading.set(false);
        },
        error: (error) => {
          if (error?.status === 403) {
            // No permission: show empty state without toasts
            this.tasks.set([]);
            this.totalPages.set(0);
            this.totalElements.set(0);
            this.loading.set(false);
            return;
          }
          console.error('Error loading tasks:', error);
          this.toastr.error('Failed to load tasks', 'Error');
          this.loading.set(false);
        },
      });
  }

  onFilterChange(): void {
    this.currentPage.set(0);
    this.loadTasks();
  }

  clearFilters(): void {
    this.searchKeyword.set('');
    this.selectedStatus.set('');
    this.selectedPriority.set('');
    this.selectedRelationType.set('');
    this.showOnlyOverdue.set(false);
    this.currentPage.set(0);
    this.loadTasks();
  }

  /**
   * If navigated with query params (e.g., from an incident), prefill and open create modal.
   */
  private handleQueryPrefill(): void {
    const params = this.route.snapshot.queryParams;
    // Modal auto-open disabled in favor of dedicated create route
  }

  confirmDelete(task: Task): void {
    this.taskToDelete = task;
  }

  cancelDelete(): void {
    this.taskToDelete = null;
  }

  deleteTask(): void {
    if (!this.taskToDelete?.id) return;

    this.taskService.deleteTask(this.taskToDelete.id).subscribe({
      next: (response) => {
        if (response.success) {
          this.toastr.success('Task deleted successfully', 'Success');
          this.taskToDelete = null;
          this.loadTasks();
          this.loadStatistics();
        }
      },
      error: (error) => {
        console.error('Error deleting task:', error);
        this.toastr.error('Failed to delete task', 'Error');
        this.taskToDelete = null;
      },
    });
  }

  completeTask(task: Task): void {
    if (!task.id) return;

    this.taskService.completeTask(task.id).subscribe({
      next: (response) => {
        if (response.success) {
          this.toastr.success('Task marked as completed', 'Success');
          this.loadTasks();
          this.loadStatistics();
        }
      },
      error: (error) => {
        console.error('Error completing task:', error);
        this.toastr.error('Failed to complete task', 'Error');
      },
    });
  }

  getStatusLabel(status: TaskStatus): string {
    return this.taskService.getStatusLabel(status);
  }

  getStatusBadgeClass(status: TaskStatus): string {
    return this.taskService.getStatusBadgeClass(status);
  }

  getPriorityLabel(priority: TaskPriority): string {
    return this.taskService.getPriorityLabel(priority);
  }

  getPriorityBadgeClass(priority: TaskPriority): string {
    return this.taskService.getPriorityBadgeClass(priority);
  }

  formatDateHuman(value?: any): string {
    const dateObj = this.toDate(value);
    if (!dateObj || Number.isNaN(dateObj.getTime())) return 'No due date';
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
    const day = dateObj.getDate().toString().padStart(2, '0');
    const month = months[dateObj.getMonth()];
    const year = dateObj.getFullYear();
    return `${month} ${day}, ${year}`;
  }

  private toDate(value?: any): Date | null {
    if (!value) return null;
    if (value instanceof Date) return value;
    if (Array.isArray(value)) {
      const [y, m, d, hh = 0, mm = 0, ss = 0, ms = 0] = value;
      const parsed = new Date(
        Number(y),
        Number(m) - 1,
        Number(d),
        Number(hh),
        Number(mm),
        Number(ss),
        Number(ms),
      );
      return Number.isNaN(parsed.getTime()) ? null : parsed;
    }
    const parsed = new Date(value);
    return Number.isNaN(parsed.getTime()) ? null : parsed;
  }

  isOverdue(task: Task): boolean {
    return task.isOverdue || this.taskService.isTaskOverdue(task);
  }

  getPageRange(): number[] {
    const length = Math.min(this.totalPages(), 10);
    return Array.from({ length }, (_, idx) => idx);
  }

  goToPage(page: number): void {
    if (page >= 0 && page < this.totalPages()) {
      this.currentPage.set(page);
      this.loadTasks();
    }
  }

  viewTaskDetail(task: Task): void {
    if (task.id) {
      this.router.navigate(['/tasks', task.id]);
    }
  }

  toggleMenu(taskId: number): void {
    this.openMenuTaskId.set(this.openMenuTaskId() === taskId ? null : taskId);
  }

  isMenuOpen(taskId: number): boolean {
    return this.openMenuTaskId() === taskId;
  }

  closeMenu(): void {
    this.openMenuTaskId.set(null);
  }

  editTask(task: Task): void {
    if (task.id) {
      this.router.navigate(['/tasks', task.id, 'edit']);
    }
  }
}
