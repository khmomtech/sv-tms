import { CommonModule } from '@angular/common';
import { Component, inject, signal, computed } from '@angular/core';
import { ActivatedRoute, Router } from '@angular/router';

import type { ApiResponse } from '../../../../models/api-response.model';
import type { PagedResponse } from '../../../../models/api-response-page.model';
import type { Task } from '../../../../models/task.model';
import { TaskService } from '../../../../services/task.service';
import { TaskStatus, TaskPriority } from '../../../../models/task.model';
import { AuthService } from '../../../../services/auth.service';
import { PERMISSIONS } from '../../../../shared/permissions';

@Component({
  selector: 'app-incident-tasks',
  standalone: true,
  imports: [CommonModule],
  template: `
    <div class="page">
      <div class="page-header">
        <div>
          <h1>Incident Tasks</h1>
          <p class="subtitle">Track and manage investigation tasks across all incidents</p>
        </div>
      </div>

      <!-- Task Summary Cards -->
      <div class="stats-grid">
        <div class="stat-card pending">
          <div class="stat-icon"><i class="bi bi-clock"></i></div>
          <div class="stat-content">
            <div class="stat-value">{{ pendingCount() }}</div>
            <div class="stat-label">Pending Tasks</div>
          </div>
        </div>

        <div class="stat-card in-progress">
          <div class="stat-icon"><i class="bi bi-arrow-repeat"></i></div>
          <div class="stat-content">
            <div class="stat-value">{{ inProgressCount() }}</div>
            <div class="stat-label">In Progress</div>
          </div>
        </div>

        <div class="stat-card completed">
          <div class="stat-icon"><i class="bi bi-check-circle"></i></div>
          <div class="stat-content">
            <div class="stat-value">{{ completedCount() }}</div>
            <div class="stat-label">Completed</div>
          </div>
        </div>

        <div class="stat-card escalated">
          <div class="stat-icon"><i class="bi bi-arrow-up-circle"></i></div>
          <div class="stat-content">
            <div class="stat-value">{{ escalatedCount() }}</div>
            <div class="stat-label">Escalated</div>
          </div>
        </div>
      </div>

      <!-- All Tasks Table -->
      <div class="card">
        <h3 class="section-title"><i class="bi bi-list-check"></i> All Incident Tasks</h3>

        <div class="task-table-wrapper">
          <table class="task-table">
            <thead>
              <tr>
                <th>Code</th>
                <th>Task</th>
                <th>Status</th>
                <th>Priority</th>
                <th>Due</th>
                <th>Actions</th>
              </tr>
            </thead>
            <tbody>
              <ng-container *ngFor="let task of tasks()">
                <tr class="task-row" [ngClass]="getRowClass(task)">
                  <td>
                    <span class="incident-link">
                      {{ task.relationCode || 'INC-' + (task.relationId || '') }}
                    </span>
                  </td>
                  <td>
                    <strong>{{ task.title }}</strong>
                    <div class="task-subtitle">{{ task.description || 'No description' }}</div>
                  </td>
                  <td>
                    <span class="task-badge" [ngClass]="getStatusClass(task)">
                      <i [class]="getStatusIcon(task)"></i>
                      {{ getStatusLabel(task) }}
                    </span>
                  </td>
                  <td>
                    <span class="badge" [ngClass]="getPriorityClass(task.priority)">
                      {{ task.priority || 'N/A' }}
                    </span>
                  </td>
                  <td>{{ formatDate(task.dueDate || task.createdDate) }}</td>
                  <td>
                    <button
                      class="btn-icon"
                      (click)="viewIncident(task.relationId)"
                      title="View Incident"
                    >
                      <i class="bi bi-eye"></i>
                    </button>
                  </td>
                </tr>
              </ng-container>
            </tbody>
          </table>
        </div>

        <div *ngIf="loading()" class="loading-state">
          <i class="bi bi-hourglass-split"></i>
          <p>Loading tasks...</p>
        </div>

        <div *ngIf="!loading() && tasks().length === 0" class="empty-state">
          <i class="bi bi-list-check"></i>
          <p>No pending tasks</p>
        </div>

        <div *ngIf="error()" class="error-state">
          <i class="bi bi-exclamation-circle"></i>
          <p>{{ error() }}</p>
        </div>
      </div>
    </div>
  `,
  styles: [
    `
      .page {
        padding: 24px;
        background: #f4f6fa;
        min-height: 100vh;
      }

      .page-header {
        margin-bottom: 24px;
      }

      h1 {
        margin: 0 0 8px 0;
        font-size: 28px;
        font-weight: 600;
        color: #1a202c;
      }

      .subtitle {
        font-size: 14px;
        color: #6b7280;
        margin: 0;
      }

      .stats-grid {
        display: grid;
        grid-template-columns: repeat(auto-fit, minmax(240px, 1fr));
        gap: 20px;
        margin-bottom: 24px;
      }

      .stat-card {
        background: white;
        border-radius: 12px;
        padding: 20px;
        display: flex;
        gap: 16px;
        align-items: center;
        border: 2px solid #e5e7eb;
        transition: all 0.3s;
      }

      .stat-card:hover {
        transform: translateY(-2px);
        box-shadow: 0 4px 12px rgba(0, 0, 0, 0.1);
      }

      .stat-card.pending {
        border-left: 4px solid #f59e0b;
      }

      .stat-card.in-progress {
        border-left: 4px solid #3b82f6;
      }

      .stat-card.completed {
        border-left: 4px solid #22c55e;
      }

      .stat-card.escalated {
        border-left: 4px solid #a855f7;
      }

      .stat-icon {
        width: 48px;
        height: 48px;
        border-radius: 12px;
        display: flex;
        align-items: center;
        justify-content: center;
        font-size: 24px;
      }

      .pending .stat-icon {
        background: #fef3c7;
        color: #f59e0b;
      }

      .in-progress .stat-icon {
        background: #dbeafe;
        color: #3b82f6;
      }

      .completed .stat-icon {
        background: #dcfce7;
        color: #22c55e;
      }

      .escalated .stat-icon {
        background: #f3e8ff;
        color: #a855f7;
      }

      .stat-value {
        font-size: 32px;
        font-weight: 700;
        color: #1a202c;
        line-height: 1;
      }

      .stat-label {
        font-size: 13px;
        color: #6b7280;
        margin-top: 4px;
      }

      .card {
        background: white;
        border-radius: 16px;
        padding: 24px;
        box-shadow: 0 1px 3px rgba(0, 0, 0, 0.1);
      }

      .section-title {
        font-size: 18px;
        font-weight: 600;
        color: #1a202c;
        margin: 0 0 20px 0;
        display: flex;
        align-items: center;
        gap: 8px;
      }

      .task-subtitle {
        font-size: 12px;
        color: #9ca3af;
        margin-top: 4px;
      }

      .incident-link {
        color: #2563eb;
        text-decoration: none;
        font-weight: 600;
        font-size: 13px;
      }

      .incident-link:hover {
        text-decoration: underline;
      }

      .btn-icon {
        background: transparent;
        border: 1px solid #e5e7eb;
        width: 32px;
        height: 32px;
        border-radius: 6px;
        display: inline-flex;
        align-items: center;
        justify-content: center;
        cursor: pointer;
        transition: all 0.2s;
        color: #6b7280;
      }

      .btn-icon:hover {
        background: #f9fafb;
        border-color: #2563eb;
        color: #2563eb;
      }

      .loading-state,
      .empty-state {
        text-align: center;
        padding: 40px;
        color: #9ca3af;
      }

      .loading-state i,
      .empty-state i {
        font-size: 48px;
        margin-bottom: 16px;
        display: block;
      }
    `,
  ],
})
export class IncidentTasksComponent {
  private taskService = inject(TaskService);
  private authService = inject(AuthService);
  private router = inject(Router);
  private route = inject(ActivatedRoute);

  tasks = signal<Task[]>([]);
  loading = signal(true);
  error = signal<string | null>(null);
  canReadTasks = signal(true);
  activeIncidentId = signal<number | null>(null);
  driverIdFilter = signal<number | null>(null);

  pendingCount = computed(() => this.tasks().filter((t) => t.status === TaskStatus.OPEN).length);
  inProgressCount = computed(
    () =>
      this.tasks().filter((t) =>
        [TaskStatus.IN_PROGRESS, TaskStatus.ON_HOLD, TaskStatus.IN_REVIEW].includes(
          t.status as TaskStatus,
        ),
      ).length,
  );
  completedCount = computed(
    () => this.tasks().filter((t) => t.status === TaskStatus.COMPLETED).length,
  );
  escalatedCount = computed(
    () => this.tasks().filter((t) => (t.relationType || '').toUpperCase() === 'CASE').length,
  );

  constructor() {
    this.canReadTasks.set(this.authService.hasPermission(PERMISSIONS.TASK_READ));
    this.route.queryParamMap.subscribe((params) => {
      const incidentIdParam = Number(params.get('incidentId'));
      const driverIdParam = Number(params.get('driverId'));

      this.activeIncidentId.set(Number.isNaN(incidentIdParam) ? null : incidentIdParam);
      this.driverIdFilter.set(Number.isNaN(driverIdParam) ? null : driverIdParam);

      if (this.canReadTasks()) {
        this.loadTasks();
      } else {
        this.loading.set(false);
        this.tasks.set([]);
        this.error.set(null);
      }
    });
  }

  loadTasks() {
    if (!this.canReadTasks()) {
      this.tasks.set([]);
      this.loading.set(false);
      return;
    }
    this.loading.set(true);
    const filter: any = { relationType: 'INCIDENT', sortBy: 'createdAt', sortDirection: 'desc' };
    if (this.activeIncidentId()) {
      filter.relationId = this.activeIncidentId();
    }
    if (this.driverIdFilter()) {
      filter.driverId = this.driverIdFilter();
    }
    this.taskService.getTasks(filter, 0, 200).subscribe({
      next: (response: ApiResponse<PagedResponse<Task>>) => {
        const content = (response.data?.content as Task[]) ?? [];
        this.tasks.set(content);
        this.loading.set(false);
        this.error.set(null);
      },
      error: (err: unknown) => {
        const status = (err as any)?.status;
        if (status === 403) {
          this.tasks.set([]);
          this.error.set(null);
          this.loading.set(false);
          return;
        }
        this.loading.set(false);
        this.error.set('Failed to load tasks');
        console.error('Task load failed', err);
      },
    });
  }

  getStatusLabel(task: Task): string {
    switch (task.status) {
      case TaskStatus.OPEN:
        return 'Not Started';
      case TaskStatus.IN_PROGRESS:
      case TaskStatus.IN_REVIEW:
        return 'In Progress';
      case TaskStatus.BLOCKED:
      case TaskStatus.ON_HOLD:
        return 'Blocked';
      case TaskStatus.COMPLETED:
        return 'Complete';
      case TaskStatus.CANCELLED:
        return 'Cancelled';
      default:
        return task.status || 'Pending';
    }
  }

  getStatusClass(task: Task): string {
    switch (task.status) {
      case TaskStatus.OPEN:
        return 'pending';
      case TaskStatus.IN_PROGRESS:
      case TaskStatus.IN_REVIEW:
        return 'in-progress';
      case TaskStatus.BLOCKED:
      case TaskStatus.ON_HOLD:
        return 'blocked';
      case TaskStatus.COMPLETED:
        return 'completed';
      case TaskStatus.CANCELLED:
        return 'cancelled';
      default:
        return 'pending';
    }
  }

  getStatusIcon(task: Task): string {
    switch (task.status) {
      case TaskStatus.OPEN:
        return 'bi bi-clock';
      case TaskStatus.IN_PROGRESS:
      case TaskStatus.IN_REVIEW:
        return 'bi bi-arrow-repeat';
      case TaskStatus.BLOCKED:
      case TaskStatus.ON_HOLD:
        return 'bi bi-pause-circle';
      case TaskStatus.COMPLETED:
        return 'bi bi-check-circle';
      case TaskStatus.CANCELLED:
        return 'bi bi-x-circle';
      default:
        return 'bi bi-circle';
    }
  }

  getRowClass(task: Task): string {
    return this.getStatusClass(task);
  }

  getPriorityClass(priority?: TaskPriority | string): string {
    switch (priority) {
      case TaskPriority.CRITICAL:
        return 'badge bg-danger';
      case TaskPriority.HIGH:
        return 'badge bg-warning text-dark';
      case TaskPriority.MEDIUM:
        return 'badge bg-primary';
      case TaskPriority.LOW:
        return 'badge bg-secondary';
      default:
        return 'badge bg-light text-dark';
    }
  }

  formatDate(date: any): string {
    if (!date) return 'N/A';

    let dateObj: Date;
    if (Array.isArray(date)) {
      const [year, month, day] = date;
      dateObj = new Date(year, month - 1, day);
    } else {
      dateObj = new Date(date);
    }

    if (isNaN(dateObj.getTime())) return 'Invalid Date';

    const day = dateObj.getDate();
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
    const month = months[dateObj.getMonth()];
    const year = dateObj.getFullYear();

    return `${day.toString().padStart(2, '0')}-${month}-${year}`;
  }

  viewIncident(id: number | undefined) {
    if (id) {
      this.router.navigate(['/incidents', id]);
    }
  }
}
