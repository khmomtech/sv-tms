import { CommonModule } from '@angular/common';
import { Component, inject, type OnInit, signal } from '@angular/core';
import { FormBuilder, ReactiveFormsModule, Validators } from '@angular/forms';
import { ActivatedRoute, Router } from '@angular/router';
import { NgSelectModule } from '@ng-select/ng-select';
import { ToastrService } from 'ngx-toastr';

import { type MaintenanceTask, MaintenanceStatus } from '../../../models/task.model';
import { TaskService } from '../../../services/task.service';
import { AuthService } from '../../../services/auth.service';
import { ConfirmService } from '../../../services/confirm.service';

@Component({
  selector: 'app-task-form',
  standalone: true,
  imports: [CommonModule, ReactiveFormsModule, NgSelectModule],
  templateUrl: './task-form.component.html',
  styleUrls: ['./task-form.component.css'],
})
export class TaskFormComponent implements OnInit {
  private fb = inject(FormBuilder);
  private taskService = inject(TaskService);
  private authService = inject(AuthService);
  private router = inject(Router);
  private route = inject(ActivatedRoute);
  private toastr = inject(ToastrService);
  private confirm = inject(ConfirmService);

  isEditMode = signal(false);
  taskId = signal<number | null>(null);
  loading = signal(false);
  submitting = signal(false);
  isAdmin = signal(false);

  maintenanceStatuses = Object.values(MaintenanceStatus);

  taskForm = this.fb.group({
    title: ['', [Validators.required, Validators.maxLength(200)]],
    description: ['', [Validators.maxLength(1000)]],
    dueDate: [''],
    status: [MaintenanceStatus.SCHEDULED, [Validators.required]],
    taskTypeId: [null as number | null],
    vehicleId: [null as number | null],
  });

  ngOnInit(): void {
    this.checkUserRole();

    const id = this.route.snapshot.paramMap.get('id');
    if (id) {
      this.isEditMode.set(true);
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
          this.patchFormValues(response.data);
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

  private patchFormValues(task: MaintenanceTask): void {
    this.taskForm.patchValue({
      title: task.title,
      description: task.description || '',
      dueDate: task.dueDate ? this.toDateTimeLocal(task.dueDate) : '',
      status: task.status,
      taskTypeId: task.taskTypeId || null,
      vehicleId: task.vehicleId || null,
    });
  }

  onSubmit(): void {
    if (this.taskForm.invalid || !this.isAdmin()) {
      this.markFormGroupTouched();
      this.toastr.warning('Please fill in all required fields correctly', 'Validation Error');
      return;
    }

    this.submitting.set(true);

    const formValue = this.taskForm.value;
    const taskData: MaintenanceTask = {
      title: formValue.title!,
      description: formValue.description || undefined,
      dueDate: formValue.dueDate ? this.toBackendDateTime(formValue.dueDate) : undefined,
      status: formValue.status!,
      taskTypeId: formValue.taskTypeId || undefined,
      vehicleId: formValue.vehicleId || undefined,
    };

    const request = this.isEditMode()
      ? this.taskService.updateMaintenanceTask(this.taskId()!, taskData)
      : this.taskService.createMaintenanceTask(taskData);

    request.subscribe({
      next: (response) => {
        if (response.success) {
          const message = this.isEditMode()
            ? 'Task updated successfully'
            : 'Task created successfully';
          this.toastr.success(message, 'Success');
          this.router.navigate(['/tasks'], { queryParams: { created: 'true' } });
        }
        this.submitting.set(false);
      },
      error: (error) => {
        console.error('Error saving task:', error);
        const message = this.isEditMode() ? 'Failed to update task' : 'Failed to create task';
        this.toastr.error(message, 'Error');
        this.submitting.set(false);
      },
    });
  }

  async onCancel(): Promise<void> {
    if (this.taskForm.dirty) {
      if (await this.confirm.confirm('You have unsaved changes. Are you sure you want to leave?')) {
        this.router.navigate(['/tasks']);
      }
    } else {
      this.router.navigate(['/tasks']);
    }
  }

  private markFormGroupTouched(): void {
    Object.keys(this.taskForm.controls).forEach((key) => {
      const control = this.taskForm.get(key);
      control?.markAsTouched();
    });
  }

  hasFieldError(fieldName: string): boolean {
    const field = this.taskForm.get(fieldName);
    return !!(field && field.invalid && (field.dirty || field.touched));
  }

  isFieldValid(fieldName: string): boolean {
    const field = this.taskForm.get(fieldName);
    return !!(field && field.valid && (field.dirty || field.touched));
  }

  getFieldError(fieldName: string): string {
    const field = this.taskForm.get(fieldName);
    if (!field || !field.errors) return '';

    if (field.errors['required']) return `${this.formatFieldName(fieldName)} is required`;
    if (field.errors['maxlength']) {
      const maxLength = field.errors['maxlength'].requiredLength;
      return `${this.formatFieldName(fieldName)} cannot exceed ${maxLength} characters`;
    }

    return 'Invalid value';
  }

  private formatFieldName(fieldName: string): string {
    return fieldName.replace(/([A-Z])/g, ' $1').replace(/^./, (str) => str.toUpperCase());
  }

  private toDateTimeLocal(value: string): string {
    // Ensure value fits datetime-local format (YYYY-MM-DDTHH:mm)
    if (!value) return '';
    return value.length >= 16 ? value.slice(0, 16) : value;
  }

  private toBackendDateTime(localValue: string): string {
    // Ensure seconds are present to satisfy LocalDateTime parsing server-side
    if (!localValue) return localValue;
    return localValue.length === 16 ? `${localValue}:00` : localValue;
  }

  getStatusLabel(status: MaintenanceStatus): string {
    return this.taskService.getStatusLabel(status);
  }
}
