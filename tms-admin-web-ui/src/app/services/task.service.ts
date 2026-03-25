import { Injectable } from '@angular/core';
import { HttpClient, HttpParams } from '@angular/common/http';
import { Observable } from 'rxjs';
import { environment } from '../../environments/environment';
import type { ApiResponse } from '../models/api-response.model';
import type { PagedResponse } from '../models/api-response-page.model';
import {
  WorkOrderTask,
  MaintenanceTask,
  Task,
  TaskComment,
  TaskAttachment,
  TaskStatistics,
  TaskStatus,
  TaskPriority,
  MaintenanceStatus,
  TaskFilter,
} from '../models/task.model';

@Injectable({
  providedIn: 'root',
})
export class TaskService {
  private technicianApiUrl = `${environment.apiUrl}/technician/tasks`;
  private maintenanceApiUrl = `${environment.apiUrl}/admin/maintenance-tasks`;
  private unifiedTaskApiUrl = `${environment.apiUrl}/tasks`;

  constructor(private http: HttpClient) {}

  /**
   * Get technician tasks (WorkOrderTask)
   */
  getTechnicianTasks(): Observable<WorkOrderTask[]> {
    return this.http.get<WorkOrderTask[]>(this.technicianApiUrl);
  }

  /**
   * Get technician pending tasks
   */
  getTechnicianPendingTasks(): Observable<WorkOrderTask[]> {
    return this.http.get<WorkOrderTask[]>(`${this.technicianApiUrl}/pending`);
  }

  /**
   * Get maintenance tasks (MaintenanceTask) with pagination
   */
  getMaintenanceTasks(
    page: number = 0,
    size: number = 10,
    keyword?: string,
    status?: string,
    vehicleId?: number,
  ): Observable<ApiResponse<PagedResponse<MaintenanceTask>>> {
    let params = new HttpParams().set('page', page.toString()).set('size', size.toString());

    if (keyword) params = params.set('keyword', keyword);
    if (status) params = params.set('status', status);
    if (vehicleId) params = params.set('vehicleId', vehicleId.toString());

    return this.http.get<ApiResponse<PagedResponse<MaintenanceTask>>>(this.maintenanceApiUrl, {
      params,
    });
  }

  /**
   * Get single maintenance task by ID
   */
  getMaintenanceTaskById(id: number): Observable<ApiResponse<MaintenanceTask>> {
    return this.http.get<ApiResponse<MaintenanceTask>>(`${this.maintenanceApiUrl}/${id}`);
  }

  /**
   * Create new maintenance task
   */
  createMaintenanceTask(task: MaintenanceTask): Observable<ApiResponse<MaintenanceTask>> {
    return this.http.post<ApiResponse<MaintenanceTask>>(this.maintenanceApiUrl, task);
  }

  /**
   * Update existing maintenance task
   */
  updateMaintenanceTask(
    id: number,
    task: MaintenanceTask,
  ): Observable<ApiResponse<MaintenanceTask>> {
    return this.http.put<ApiResponse<MaintenanceTask>>(`${this.maintenanceApiUrl}/${id}`, task);
  }

  /**
   * Delete maintenance task
   */
  deleteMaintenanceTask(id: number): Observable<ApiResponse<void>> {
    return this.http.delete<ApiResponse<void>>(`${this.maintenanceApiUrl}/${id}`);
  }

  /**
   * Complete maintenance task
   */
  completeMaintenanceTask(id: number): Observable<ApiResponse<MaintenanceTask>> {
    return this.http.post<ApiResponse<MaintenanceTask>>(
      `${this.maintenanceApiUrl}/${id}/complete`,
      {},
    );
  }

  /**
   * Get overdue maintenance tasks
   */
  getOverdueMaintenanceTasks(): Observable<ApiResponse<MaintenanceTask[]>> {
    return this.http.get<ApiResponse<MaintenanceTask[]>>(`${this.maintenanceApiUrl}/overdue`);
  }

  /**
   * Unified tasks with filtering/pagination (TaskDto)
   */
  getTasks(
    filter?: TaskFilter,
    page: number = 0,
    size: number = 20,
  ): Observable<ApiResponse<PagedResponse<Task>>> {
    let params = new HttpParams().set('page', page.toString()).set('size', size.toString());

    if (filter) {
      if (filter.keyword) params = params.set('keyword', filter.keyword);
      if (filter.assigneeIds?.length)
        params = params.set('assigneeIds', filter.assigneeIds.join(','));
      if (filter.priorities?.length) params = params.set('priorities', filter.priorities.join(','));
      if (filter.statuses?.length) params = params.set('statuses', filter.statuses.join(','));
      if (filter.dueBefore) params = params.set('dueBefore', filter.dueBefore);
      if (filter.dueAfter) params = params.set('dueAfter', filter.dueAfter);
      if (filter.createdBefore) params = params.set('createdBefore', filter.createdBefore);
      if (filter.createdAfter) params = params.set('createdAfter', filter.createdAfter);
      if (filter.overdue !== undefined) params = params.set('overdue', filter.overdue);
      if (filter.urgent !== undefined) params = params.set('urgent', filter.urgent);
      if (filter.relationType) params = params.set('relationType', filter.relationType);
      if (filter.relationId) params = params.set('relationId', filter.relationId);
      if (filter.driverId) params = params.set('driverId', filter.driverId);
      if (filter.vehicleId) params = params.set('vehicleId', filter.vehicleId);
      if (filter.caseId) params = params.set('caseId', filter.caseId);
      if (filter.sortBy) params = params.set('sortBy', filter.sortBy);
      if (filter.sortDirection) params = params.set('sortDirection', filter.sortDirection);
    }

    return this.http.get<ApiResponse<PagedResponse<Task>>>(this.unifiedTaskApiUrl, { params });
  }

  /**
   * Update technician task status
   */
  updateTechnicianTaskStatus(taskId: number, status: TaskStatus): Observable<WorkOrderTask> {
    const params = new HttpParams().set('status', status);
    return this.http.patch<WorkOrderTask>(`${this.technicianApiUrl}/${taskId}/status`, null, {
      params,
    });
  }

  /**
   * Update technician task hours
   */
  updateTechnicianTaskHours(taskId: number, actualHours: number): Observable<WorkOrderTask> {
    const params = new HttpParams().set('actualHours', actualHours.toString());
    return this.http.patch<WorkOrderTask>(`${this.technicianApiUrl}/${taskId}/hours`, null, {
      params,
    });
  }

  /**
   * Get status label for display
   */
  getStatusLabel(status: TaskStatus | MaintenanceStatus): string {
    const taskLabels: Record<TaskStatus, string> = {
      [TaskStatus.OPEN]: 'Open',
      [TaskStatus.IN_PROGRESS]: 'In Progress',
      [TaskStatus.BLOCKED]: 'Blocked',
      [TaskStatus.ON_HOLD]: 'On Hold',
      [TaskStatus.IN_REVIEW]: 'In Review',
      [TaskStatus.COMPLETED]: 'Completed',
      [TaskStatus.CANCELLED]: 'Cancelled',
    };

    const maintenanceLabels: Record<MaintenanceStatus, string> = {
      [MaintenanceStatus.SCHEDULED]: 'Scheduled',
      [MaintenanceStatus.IN_PROGRESS]: 'In Progress',
      [MaintenanceStatus.COMPLETED]: 'Completed',
      [MaintenanceStatus.OVERDUE]: 'Overdue',
      [MaintenanceStatus.CANCELLED]: 'Cancelled',
    };

    return (
      taskLabels[status as TaskStatus] || maintenanceLabels[status as MaintenanceStatus] || status
    );
  }

  /**
   * Get status badge class
   */
  getStatusBadgeClass(status: TaskStatus | MaintenanceStatus): string {
    const taskClasses: Record<TaskStatus, string> = {
      [TaskStatus.OPEN]: 'badge bg-secondary',
      [TaskStatus.IN_PROGRESS]: 'badge bg-primary',
      [TaskStatus.BLOCKED]: 'badge bg-warning text-dark',
      [TaskStatus.ON_HOLD]: 'badge bg-info',
      [TaskStatus.IN_REVIEW]: 'badge bg-purple text-white',
      [TaskStatus.COMPLETED]: 'badge bg-success',
      [TaskStatus.CANCELLED]: 'badge bg-danger',
    };

    const maintenanceClasses: Record<MaintenanceStatus, string> = {
      [MaintenanceStatus.SCHEDULED]: 'badge bg-info',
      [MaintenanceStatus.IN_PROGRESS]: 'badge bg-primary',
      [MaintenanceStatus.COMPLETED]: 'badge bg-success',
      [MaintenanceStatus.OVERDUE]: 'badge bg-warning text-dark',
      [MaintenanceStatus.CANCELLED]: 'badge bg-danger',
    };

    return (
      taskClasses[status as TaskStatus] ||
      maintenanceClasses[status as MaintenanceStatus] ||
      'badge bg-secondary'
    );
  }

  /**
   * Check if maintenance task is overdue
   */
  isOverdue(task: MaintenanceTask): boolean {
    if (
      !task.dueDate ||
      task.status === MaintenanceStatus.COMPLETED ||
      task.status === MaintenanceStatus.CANCELLED
    ) {
      return false;
    }
    return new Date(task.dueDate) < new Date();
  }

  // ===== UNIFIED TASK SYSTEM API METHODS =====

  /**
   * Get unified tasks with filtering and pagination
   */
  getUnifiedTasks(
    page: number = 0,
    size: number = 10,
    keyword?: string,
    status?: TaskStatus,
    priority?: TaskPriority,
    relationType?: string,
    assignedToId?: number,
    createdById?: number,
    isOverdue?: boolean,
    sortBy?: string,
    sortDirection?: string,
  ): Observable<ApiResponse<PagedResponse<Task>>> {
    let params = new HttpParams().set('page', page.toString()).set('size', size.toString());

    if (keyword) params = params.set('keyword', keyword);
    if (status) params = params.set('status', status);
    if (priority) params = params.set('priority', priority);
    if (relationType) params = params.set('relationType', relationType);
    if (assignedToId) params = params.set('assignedToId', assignedToId.toString());
    if (createdById) params = params.set('createdById', createdById.toString());
    if (isOverdue !== undefined) params = params.set('isOverdue', isOverdue.toString());
    if (sortBy) params = params.set('sortBy', sortBy);
    if (sortDirection) params = params.set('sortDirection', sortDirection);

    return this.http.get<ApiResponse<PagedResponse<Task>>>(this.unifiedTaskApiUrl, { params });
  }

  /**
   * Get task statistics
   */
  getTaskStatistics(): Observable<ApiResponse<TaskStatistics>> {
    return this.http.get<ApiResponse<TaskStatistics>>(`${this.unifiedTaskApiUrl}/statistics`);
  }

  /**
   * Get single task by ID
   */
  getTaskById(id: number): Observable<ApiResponse<Task>> {
    return this.http.get<ApiResponse<Task>>(`${this.unifiedTaskApiUrl}/${id}`);
  }

  /**
   * Create new task
   */
  createTask(task: Task): Observable<ApiResponse<Task>> {
    return this.http.post<ApiResponse<Task>>(this.unifiedTaskApiUrl, task);
  }

  /**
   * Update existing task
   */
  updateTask(id: number, task: Task): Observable<ApiResponse<Task>> {
    return this.http.put<ApiResponse<Task>>(`${this.unifiedTaskApiUrl}/${id}`, task);
  }

  /**
   * Delete task (soft delete)
   */
  deleteTask(id: number): Observable<ApiResponse<void>> {
    return this.http.delete<ApiResponse<void>>(`${this.unifiedTaskApiUrl}/${id}`);
  }

  /**
   * Complete task
   */
  completeTask(id: number): Observable<ApiResponse<Task>> {
    return this.http.post<ApiResponse<Task>>(`${this.unifiedTaskApiUrl}/${id}/complete`, {});
  }

  /**
   * Update task status
   */
  updateTaskStatus(id: number, status: TaskStatus): Observable<ApiResponse<Task>> {
    return this.http.put<ApiResponse<Task>>(`${this.unifiedTaskApiUrl}/${id}/status`, { status });
  }

  /**
   * Update task progress
   */
  updateTaskProgress(id: number, progressPercentage: number): Observable<ApiResponse<Task>> {
    return this.http.put<ApiResponse<Task>>(`${this.unifiedTaskApiUrl}/${id}/progress`, {
      progressPercentage,
    });
  }

  /**
   * Assign task to user
   */
  assignTask(id: number, userId: number): Observable<ApiResponse<Task>> {
    return this.http.post<ApiResponse<Task>>(`${this.unifiedTaskApiUrl}/${id}/assign`, { userId });
  }

  /**
   * Get task comments
   */
  getTaskComments(taskId: number): Observable<ApiResponse<TaskComment[]>> {
    return this.http.get<ApiResponse<TaskComment[]>>(
      `${this.unifiedTaskApiUrl}/${taskId}/comments`,
    );
  }

  /**
   * Add comment to task
   */
  addTaskComment(taskId: number, content: string): Observable<ApiResponse<TaskComment>> {
    return this.http.post<ApiResponse<TaskComment>>(
      `${this.unifiedTaskApiUrl}/${taskId}/comments`,
      {
        taskId,
        content,
      },
    );
  }

  /**
   * Get task attachments
   */
  getTaskAttachments(taskId: number): Observable<ApiResponse<TaskAttachment[]>> {
    return this.http.get<ApiResponse<TaskAttachment[]>>(
      `${this.unifiedTaskApiUrl}/${taskId}/attachments`,
    );
  }

  /**
   * Upload attachment to task
   */
  uploadTaskAttachment(taskId: number, file: File): Observable<ApiResponse<TaskAttachment>> {
    const formData = new FormData();
    formData.append('file', file);
    return this.http.post<ApiResponse<TaskAttachment>>(
      `${this.unifiedTaskApiUrl}/${taskId}/attachments`,
      formData,
    );
  }

  /**
   * Add watcher to task
   */
  addWatcher(taskId: number, userId: number): Observable<ApiResponse<void>> {
    return this.http.post<ApiResponse<void>>(
      `${this.unifiedTaskApiUrl}/${taskId}/watchers/${userId}`,
      {},
    );
  }

  /**
   * Remove watcher from task
   */
  removeWatcher(taskId: number, userId: number): Observable<ApiResponse<void>> {
    return this.http.delete<ApiResponse<void>>(
      `${this.unifiedTaskApiUrl}/${taskId}/watchers/${userId}`,
    );
  }

  /**
   * Get priority label
   */
  getPriorityLabel(priority: TaskPriority): string {
    const labels: Record<TaskPriority, string> = {
      [TaskPriority.LOW]: 'Low',
      [TaskPriority.MEDIUM]: 'Medium',
      [TaskPriority.HIGH]: 'High',
      [TaskPriority.CRITICAL]: 'Critical',
    };
    return labels[priority] || priority;
  }

  /**
   * Get priority badge class
   */
  getPriorityBadgeClass(priority: TaskPriority): string {
    const classes: Record<TaskPriority, string> = {
      [TaskPriority.LOW]: 'badge bg-secondary',
      [TaskPriority.MEDIUM]: 'badge bg-info',
      [TaskPriority.HIGH]: 'badge bg-warning text-dark',
      [TaskPriority.CRITICAL]: 'badge bg-danger',
    };
    return classes[priority] || 'badge bg-secondary';
  }

  /**
   * Check if unified task is overdue
   */
  isTaskOverdue(task: Task): boolean {
    if (
      !task.dueDate ||
      task.status === TaskStatus.COMPLETED ||
      task.status === TaskStatus.CANCELLED
    ) {
      return false;
    }
    return new Date(task.dueDate) < new Date();
  }
}
