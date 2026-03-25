import { Component, signal, inject, type OnInit } from '@angular/core';
import { ConfirmService } from '@services/confirm.service';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { Router, RouterLink, ActivatedRoute } from '@angular/router';
import { ToastrService } from 'ngx-toastr';

import { type MaintenanceTask, MaintenanceStatus } from '../../../models/task.model';
import { TaskService } from '../../../services/task.service';
import { AuthService } from '../../../services/auth.service';

@Component({
  selector: 'app-task-list',
  standalone: true,
  imports: [CommonModule, FormsModule, RouterLink],
  templateUrl: './task-list.component.html',
  styleUrls: ['./task-list.component.css'],
})
export class TaskListComponent implements OnInit {
  private taskService = inject(TaskService);
  private authService = inject(AuthService);
  private toastr = inject(ToastrService);
  private route = inject(ActivatedRoute);
  private router = inject(Router);
  private confirm = inject(ConfirmService);

  tasks = signal<MaintenanceTask[]>([]);
  loading = signal(false);

  // Pagination
  currentPage = signal(0);
  pageSize = signal(10);
  totalPages = signal(0);
  totalElements = signal(0);

  // Filters
  searchKeyword = signal('');
  selectedStatus = signal<string>('');
  selectedVehicleId = signal<number | undefined>(undefined);

  // Enums for dropdowns
  maintenanceStatuses = Object.values(MaintenanceStatus);

  // Role check
  isAdmin = signal(false);

  // Math for template
  readonly Math = Math;

  ngOnInit(): void {
    this.checkUserRole();
    this.checkForSuccessMessage();
    this.loadTasks();
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

  private checkForSuccessMessage(): void {
    this.route.queryParams.subscribe((params) => {
      if (params['created'] === 'true') {
        this.toastr.success('Task created successfully!', 'Success', {
          timeOut: 5000,
          progressBar: true,
        });
      }
    });
  }

  loadTasks(): void {
    if (!this.isAdmin()) return;

    this.loading.set(true);

    this.taskService
      .getMaintenanceTasks(
        this.currentPage(),
        this.pageSize(),
        this.searchKeyword() || undefined,
        this.selectedStatus() || undefined,
        this.selectedVehicleId(),
      )
      .subscribe({
        next: (response) => {
          if (response.success && response.data) {
            this.tasks.set(response.data.content);
            this.currentPage.set(response.data.page ?? 0);
            this.pageSize.set(response.data.size ?? 10);
            this.totalPages.set(response.data.totalPages ?? 0);
            this.totalElements.set(response.data.totalElements ?? 0);
          }
          this.loading.set(false);
        },
        error: (error) => {
          console.error('Error loading tasks:', error);
          this.toastr.error('Failed to load tasks', 'Error');
          this.loading.set(false);
        },
      });
  }

  onSearch(): void {
    this.currentPage.set(0);
    this.loadTasks();
  }

  onFilterChange(): void {
    this.currentPage.set(0);
    this.loadTasks();
  }

  clearFilters(): void {
    this.searchKeyword.set('');
    this.selectedStatus.set('');
    this.selectedVehicleId.set(undefined);
    this.currentPage.set(0);
    this.loadTasks();
  }

  onPageChange(page: number): void {
    this.currentPage.set(page);
    this.loadTasks();
  }

  onPageSizeChange(size: string): void {
    this.pageSize.set(Number(size));
    this.currentPage.set(0);
    this.loadTasks();
  }

  getStatusCount(status: string): number {
    return this.tasks().filter((task) => task.status === status).length;
  }

  async deleteTask(id: number, title: string): Promise<void> {
    if (!(await this.confirm.confirm(`Are you sure you want to delete task "${title}"?`))) {
      return;
    }

    this.taskService.deleteMaintenanceTask(id!).subscribe({
      next: (response) => {
        if (response.success) {
          this.toastr.success('Task deleted successfully', 'Success');
          this.loadTasks();
        }
      },
      error: (error) => {
        console.error('Error deleting task:', error);
        this.toastr.error('Failed to delete task', 'Error');
      },
    });
  }

  async completeTask(id: number, title: string): Promise<void> {
    if (!(await this.confirm.confirm(`Mark task "${title}" as completed?`))) {
      return;
    }

    this.taskService.completeMaintenanceTask(id!).subscribe({
      next: (response) => {
        if (response.success) {
          this.toastr.success('Task marked as completed', 'Success');
          this.loadTasks();
        }
      },
      error: (error) => {
        console.error('Error completing task:', error);
        this.toastr.error('Failed to complete task', 'Error');
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
    const date = new Date(dateString);
    if (isNaN(date.getTime())) return '-';

    return date.toLocaleDateString('en-US', {
      year: 'numeric',
      month: 'short',
      day: 'numeric',
    });
  }

  getPageNumbers(): number[] {
    return Array.from({ length: this.totalPages() }, (_, i) => i);
  }
}
