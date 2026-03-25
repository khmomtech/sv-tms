export interface Issue {
  id?: number;
  title: string;
  description: string;
  type: IssueType;
  priority: IssuePriority;
  status: IssueStatus;
  assignedTo?: string;
  assignedToId?: number;
  reportedBy?: string;
  reportedById?: number;
  createdAt?: Date;
  updatedAt?: Date;
  resolvedAt?: Date;
  closedAt?: Date;
  dueDate?: Date;
  tags?: string[];
  comments?: IssueComment[];
  attachments?: IssueAttachment[];
}

export enum IssueType {
  BUG = 'BUG',
  FEATURE = 'FEATURE',
  IMPROVEMENT = 'IMPROVEMENT',
  TASK = 'TASK',
  SUPPORT = 'SUPPORT',
  OTHER = 'OTHER',
}

export enum IssuePriority {
  LOW = 'LOW',
  MEDIUM = 'MEDIUM',
  HIGH = 'HIGH',
  CRITICAL = 'CRITICAL',
}

export enum IssueStatus {
  OPEN = 'OPEN',
  IN_PROGRESS = 'IN_PROGRESS',
  RESOLVED = 'RESOLVED',
  CLOSED = 'CLOSED',
  REOPENED = 'REOPENED',
}

export interface IssueComment {
  id?: number;
  issueId: number;
  content: string;
  createdBy?: string;
  createdById?: number;
  createdAt?: Date;
}

export interface IssueAttachment {
  id?: number;
  issueId: number;
  fileName: string;
  fileUrl: string;
  fileSize?: number;
  uploadedBy?: string;
  uploadedAt?: Date;
}

export interface IssueFilter {
  status?: IssueStatus;
  type?: IssueType;
  priority?: IssuePriority;
  assignedToId?: number;
  reportedById?: number;
  search?: string;
  fromDate?: Date;
  toDate?: Date;
}
