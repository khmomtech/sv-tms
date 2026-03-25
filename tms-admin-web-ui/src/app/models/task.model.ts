// WorkOrderTask - aligned with backend WorkOrderTaskDto
export interface WorkOrderTask {
  id?: number;
  workOrderId: number;
  taskName: string;
  description?: string;
  status: TaskStatus;
  assignedTechnicianId?: number;
  assignedTechnicianName?: string;
  estimatedHours?: number;
  actualHours?: number;
  completedAt?: string;
  notes?: string;
}

// MaintenanceTask - aligned with backend MaintenanceTaskDto
export interface MaintenanceTask {
  id?: number;
  title: string;
  description?: string;
  dueDate?: string;
  completedAt?: string;
  status: MaintenanceStatus;
  taskTypeId?: number;
  taskTypeName?: string;
  vehicleId?: number;
  vehicleName?: string;
  createdBy?: number;
  createdByUsername?: string;
  createdDate?: string;
  updatedDate?: string;
}

// Backend TaskStatus enum (unified - matches backend)
export enum TaskStatus {
  OPEN = 'OPEN',
  IN_PROGRESS = 'IN_PROGRESS',
  BLOCKED = 'BLOCKED',
  ON_HOLD = 'ON_HOLD',
  IN_REVIEW = 'IN_REVIEW',
  COMPLETED = 'COMPLETED',
  CANCELLED = 'CANCELLED',
}

// Backend MaintenanceStatus enum
export enum MaintenanceStatus {
  SCHEDULED = 'SCHEDULED',
  IN_PROGRESS = 'IN_PROGRESS',
  COMPLETED = 'COMPLETED',
  OVERDUE = 'OVERDUE',
  CANCELLED = 'CANCELLED',
}

// Legacy - kept for compatibility
export enum TaskPriority {
  LOW = 'LOW',
  MEDIUM = 'MEDIUM',
  HIGH = 'HIGH',
  CRITICAL = 'CRITICAL',
}

export enum TaskType {
  ASSESSMENT = 'ASSESSMENT',
  EVIDENCE = 'EVIDENCE',
  VALIDATION = 'VALIDATION',
  REVIEW = 'REVIEW',
  RESOLUTION = 'RESOLUTION',
  ESCALATION = 'ESCALATION',
  INVESTIGATION = 'INVESTIGATION',
}

export interface TaskComment {
  id?: number;
  taskId: number;
  userId?: number;
  userName?: string;
  authorId?: number;
  authorUsername?: string;
  authorName?: string;
  userAvatar?: string;
  comment: string;
  createdAt?: string;
  updatedAt?: string;
}

export interface TaskAttachment {
  id?: number;
  taskId: number;
  fileName: string;
  fileUrl: string;
  fileType?: string;
  mimeType?: string;
  fileSize?: number;
  fileSizeBytes?: number;
  uploadedById?: number;
  uploadedByName?: string;
  uploadedByUsername?: string;
  uploadedAt?: string;
  description?: string;
}

export interface TaskStatistics {
  totalTasks: number;
  openTasks: number;
  inProgressTasks: number;
  completedTasks: number;
  cancelledTasks: number;
  overdueTasks: number;
  dueTodayTasks: number;
  dueThisWeekTasks: number;
  myTasks: number;
  unassignedTasks: number;
  blockedTasks?: number;
  onHoldTasks?: number;
  inReviewTasks?: number;
  criticalPriorityTasks?: number;
  highPriorityTasks?: number;
  mediumPriorityTasks?: number;
  lowPriorityTasks?: number;
  tasksCreatedByMe?: number;
  tasksAssignedToMe?: number;
  tasksWatchedByMe?: number;
  standaloneTasks?: number;
}

// Unified Task entity (matches backend TaskDto)
export interface Task {
  id?: number;
  code?: string;
  title: string;
  description?: string;
  status: TaskStatus;
  priority: TaskPriority;
  relationType?: string;
  relationId?: number;
  relationCode?: string;
  dueDate?: string;
  estimatedMinutes?: number;
  actualMinutes?: number;
  progressPercentage?: number;
  assignedToId?: number;
  assignedToUsername?: string;
  assignedToFullName?: string;
  createdById?: number;
  createdByUsername?: string;
  createdByName?: string;
  createdByFullName?: string;
  modifiedById?: number;
  modifiedByUsername?: string;
  modifiedByName?: string;
  modifiedAt?: string;
  completedAt?: string;
  isOverdue?: boolean;
  isDeleted?: boolean;
  createdDate?: string;
  updatedDate?: string;
  createdAt?: string;
  updatedAt?: string;
  estimatedDate?: string;
  actualDate?: string;

  // Counts
  commentsCount?: number;
  attachmentsCount?: number;
  tagsCount?: number;
  watchersCount?: number;

  // Related data
  comments?: TaskComment[];
  attachments?: TaskAttachment[];
  tags?: string[];
  watchers?: TaskWatcher[];
}

export interface TaskWatcher {
  id?: number;
  userId: number;
  username?: string;
  fullName?: string;
  addedAt?: string;
}

export interface TaskTag {
  id?: number;
  taskId: number;
  tagName: string;
  tagColor?: string;
}

export interface TaskActivityLog {
  id?: number;
  taskId: number;
  userId?: number;
  username?: string;
  action: string;
  oldValue?: string;
  newValue?: string;
  createdAt?: string;
}

export interface TaskFilter {
  keyword?: string;
  assigneeIds?: number[];
  priorities?: TaskPriority[];
  statuses?: TaskStatus[];
  dueBefore?: string;
  dueAfter?: string;
  createdBefore?: string;
  createdAfter?: string;
  overdue?: boolean;
  urgent?: boolean;
  relationType?: string;
  relationId?: number;
  driverId?: number;
  vehicleId?: number;
  caseId?: number;
  sortBy?: string;
  sortDirection?: 'asc' | 'desc';
  page?: number;
  size?: number;
}
