export interface Issue {
  id?: number;
  title: string;
  description: string;
  status: IssueStatus;
  priority: IssuePriority;
  category: IssueCategory;
  assignedTo?: number;
  assignedToName?: string;
  reportedBy?: number;
  reportedByName?: string;
  createdAt?: string;
  updatedAt?: string;
  resolvedAt?: string;
  dueDate?: string;
  tags?: string[];
  attachments?: string[];
  comments?: IssueComment[];
}

export interface IssueComment {
  id?: number;
  issueId: number;
  userId: number;
  userName: string;
  comment: string;
  createdAt: string;
}

export enum IssueStatus {
  OPEN = 'OPEN',
  IN_PROGRESS = 'IN_PROGRESS',
  RESOLVED = 'RESOLVED',
  CLOSED = 'CLOSED',
  REOPENED = 'REOPENED',
}

export enum IssuePriority {
  LOW = 'LOW',
  MEDIUM = 'MEDIUM',
  HIGH = 'HIGH',
  CRITICAL = 'CRITICAL',
}

export enum IssueCategory {
  BUG = 'BUG',
  FEATURE = 'FEATURE',
  IMPROVEMENT = 'IMPROVEMENT',
  TASK = 'TASK',
  QUESTION = 'QUESTION',
}

export interface IssueFilter {
  status?: IssueStatus | IssueStatus[];
  priority?: IssuePriority | IssuePriority[];
  category?: IssueCategory | IssueCategory[];
  assignedTo?: number;
  reportedBy?: number;
  search?: string;
  dateFrom?: string;
  dateTo?: string;
}
