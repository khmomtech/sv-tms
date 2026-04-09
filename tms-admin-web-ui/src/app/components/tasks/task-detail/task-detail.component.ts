import { Component, inject, OnInit, signal } from '@angular/core';
import { ConfirmService } from '@services/confirm.service';
import { CommonModule } from '@angular/common';
import { ActivatedRoute, Router, RouterLink } from '@angular/router';
import { TaskService } from '../../../services/task.service';
import { MaintenanceTask, MaintenanceStatus } from '../../../models/task.model';
import { AuthService } from '../../../services/auth.service';
import { ToastrService } from 'ngx-toastr';

@Component({
  selector: 'app-task-detail',
  standalone: true,
  imports: [CommonModule, RouterLink],
  templateUrl: './task-detail.component.html',
  styleUrls: ['./task-detail.component.css'],
})
export class TaskDetailComponent implements OnInit {
  task = signal<MaintenanceTask | null>(null);
  loading = signal(false);
  taskId = signal<number | null>(null);
  isAdmin = signal(false);
  private confirm = inject(ConfirmService);

  // Enums for dropdowns
  maintenanceStatuses = Object.values(MaintenanceStatus);

  constructor(
    private taskService: TaskService,
    private authService: AuthService,
    private route: ActivatedRoute,
    private router: Router,
    private toastr: ToastrService,
  ) {}

  ngOnInit(): void {
    this.checkUserRole();
    const id = this.route.snapshot.paramMap.get('id');
    if (id) {
      this.taskId.set(+id);
      this.loadTask(+id);
    }
  }

  private checkUserRole(): void {
    const user = this.authService.getCurrentUser();
    this.isAdmin.set(
      user?.roles?.includes('ROLE_ADMIN') || user?.roles?.includes('ROLE_SUPERADMIN') || false,
    );

    if (!this.isAdmin()) {
      this.toastr.error('Access denied. Maintenance tasks require admin role.', 'Error');
      this.router.navigate(['/dashboard']);
    }
  }

  loadTask(id: number): void {
    if (!this.isAdmin()) return;

    this.loading.set(true);
    this.taskService.getMaintenanceTaskById(id).subscribe({
      next: (response) => {
        if (response.success && response.data) {
          this.task.set(response.data);
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

  async completeTask(): Promise<void> {
    const task = this.task();
    if (!task || !task.id) return;

    if (!(await this.confirm.confirm(`Mark task "${task.title}" as completed?`))) {
      return;
    }

    this.taskService.completeMaintenanceTask(task.id).subscribe({
      next: (response) => {
        if (response.success) {
          this.toastr.success('Task marked as completed', 'Success');
          this.loadTask(task.id!);
        }
      },
      error: (error) => {
        console.error('Error completing task:', error);
        this.toastr.error('Failed to complete task', 'Error');
      },
    });
  }

  async deleteTask(): Promise<void> {
    const task = this.task();
    if (!task || !task.id) return;

    if (!(await this.confirm.confirm(`Are you sure you want to delete task "${task.title}"?`))) {
      return;
    }

    this.taskService.deleteMaintenanceTask(task.id).subscribe({
      next: (response) => {
        if (response.success) {
          this.toastr.success('Task deleted successfully', 'Success');
          this.router.navigate(['/tasks']);
        }
      },
      error: (error) => {
        console.error('Error deleting task:', error);
        this.toastr.error('Failed to delete task', 'Error');
      },
    });
  }

  getStatusBadgeClass(status: MaintenanceStatus): string {
    return this.taskService.getStatusBadgeClass(status);
  }

  getStatusLabel(status: MaintenanceStatus): string {
    return this.taskService.getStatusLabel(status);
  }

  isOverdue(task: MaintenanceTask): boolean {
    return this.taskService.isOverdue(task);
  }

  formatDate(dateString?: string): string {
    if (!dateString) return '-';
    return new Date(dateString).toLocaleString('en-US', {
      year: 'numeric',
      month: 'short',
      day: 'numeric',
      hour: '2-digit',
      minute: '2-digit',
    });
  }

  formatDateOnly(dateString?: string): string {
    if (!dateString) return '-';
    return new Date(dateString).toLocaleDateString('en-US', {
      year: 'numeric',
      month: 'short',
      day: 'numeric',
    });
  }
}
