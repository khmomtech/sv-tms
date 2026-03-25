import { Injectable } from '@angular/core';
import { HttpClient, HttpParams } from '@angular/common/http';
import { Observable, of } from 'rxjs';
import { Issue, IssueFilter, IssueStatus, IssueType, IssuePriority } from '../models/issue.model';

@Injectable({
  providedIn: 'root',
})
export class IssueService {
  private readonly apiUrl = '/api/issues';

  constructor(private readonly http: HttpClient) {}

  getAllIssues(page: number = 0, size: number = 20, filter?: IssueFilter): Observable<any> {
    // For now, return mock data until backend API is ready
    return of(this.getMockIssues(page, size, filter));
  }

  getIssueById(id: number): Observable<Issue> {
    // return this.http.get<Issue>(`${this.apiUrl}/${id}`);
    const mockIssues = this.generateMockIssues();
    const issue = mockIssues.find((i) => i.id === id);
    return of(issue || mockIssues[0]);
  }

  createIssue(issue: Issue): Observable<Issue> {
    // return this.http.post<Issue>(this.apiUrl, issue);
    return of({ ...issue, id: Math.floor(Math.random() * 1000), createdAt: new Date() });
  }

  updateIssue(id: number, issue: Partial<Issue>): Observable<Issue> {
    // return this.http.put<Issue>(`${this.apiUrl}/${id}`, issue);
    return of({ ...issue, id, updatedAt: new Date() } as Issue);
  }

  deleteIssue(id: number): Observable<void> {
    // return this.http.delete<void>(`${this.apiUrl}/${id}`);
    return of(undefined);
  }

  assignIssue(id: number, userId: number): Observable<Issue> {
    // return this.http.post<Issue>(`${this.apiUrl}/${id}/assign`, { userId });
    return of({} as Issue);
  }

  updateStatus(id: number, status: IssueStatus): Observable<Issue> {
    // return this.http.patch<Issue>(`${this.apiUrl}/${id}/status`, { status });
    return of({} as Issue);
  }

  addComment(issueId: number, content: string): Observable<any> {
    // return this.http.post(`${this.apiUrl}/${issueId}/comments`, { content });
    return of({ id: Date.now(), issueId, content, createdAt: new Date() });
  }

  private getMockIssues(page: number, size: number, filter?: IssueFilter) {
    let issues = this.generateMockIssues();

    // Apply filters
    if (filter) {
      if (filter.status) {
        issues = issues.filter((i) => i.status === filter.status);
      }
      if (filter.type) {
        issues = issues.filter((i) => i.type === filter.type);
      }
      if (filter.priority) {
        issues = issues.filter((i) => i.priority === filter.priority);
      }
      if (filter.search) {
        const search = filter.search.toLowerCase();
        issues = issues.filter(
          (i) =>
            i.title.toLowerCase().includes(search) || i.description.toLowerCase().includes(search),
        );
      }
    }

    const start = page * size;
    const end = start + size;
    const pageData = issues.slice(start, end);

    return {
      content: pageData,
      totalElements: issues.length,
      totalPages: Math.ceil(issues.length / size),
      number: page,
      size: size,
    };
  }

  private generateMockIssues(): Issue[] {
    return [
      {
        id: 1,
        title: 'GPS tracking not updating in real-time',
        description:
          'Driver locations are not updating frequently enough, causing delays in dispatch decisions.',
        type: IssueType.BUG,
        priority: IssuePriority.HIGH,
        status: IssueStatus.OPEN,
        assignedTo: 'John Doe',
        assignedToId: 1,
        reportedBy: 'Sarah Admin',
        reportedById: 2,
        createdAt: new Date('2025-12-05T08:30:00'),
        dueDate: new Date('2025-12-10'),
        tags: ['GPS', 'Real-time', 'Critical'],
        comments: [
          {
            id: 1,
            issueId: 1,
            content: 'Investigating the WebSocket connection',
            createdBy: 'John Doe',
            createdAt: new Date('2025-12-05T09:00:00'),
          },
        ],
      },
      {
        id: 2,
        title: 'Add bulk upload feature for shipments',
        description: 'Need ability to upload multiple shipments at once via CSV/Excel file',
        type: IssueType.FEATURE,
        priority: IssuePriority.MEDIUM,
        status: IssueStatus.IN_PROGRESS,
        assignedTo: 'Mike Developer',
        assignedToId: 3,
        reportedBy: 'Operations Team',
        reportedById: 4,
        createdAt: new Date('2025-12-04T10:00:00'),
        updatedAt: new Date('2025-12-05T14:30:00'),
        dueDate: new Date('2025-12-15'),
        tags: ['Shipments', 'Bulk Upload', 'Enhancement'],
      },
      {
        id: 3,
        title: 'Dashboard loading performance is slow',
        description: 'Dashboard takes 5-10 seconds to load, need to optimize queries',
        type: IssueType.IMPROVEMENT,
        priority: IssuePriority.HIGH,
        status: IssueStatus.OPEN,
        reportedBy: 'Performance Team',
        reportedById: 5,
        createdAt: new Date('2025-12-03T11:00:00'),
        tags: ['Performance', 'Dashboard', 'Optimization'],
      },
      {
        id: 4,
        title: 'Driver app crashes on Android 12',
        description:
          'Multiple reports of app crashes on Android 12 devices during route navigation',
        type: IssueType.BUG,
        priority: IssuePriority.CRITICAL,
        status: IssueStatus.IN_PROGRESS,
        assignedTo: 'Mobile Team',
        assignedToId: 6,
        reportedBy: 'Support',
        reportedById: 7,
        createdAt: new Date('2025-12-02T09:00:00'),
        updatedAt: new Date('2025-12-05T16:00:00'),
        dueDate: new Date('2025-12-07'),
        tags: ['Mobile', 'Android', 'Crash', 'Critical'],
      },
      {
        id: 5,
        title: 'Add export to PDF for trip reports',
        description: 'Dispatchers need ability to export trip reports as PDF for client sharing',
        type: IssueType.FEATURE,
        priority: IssuePriority.LOW,
        status: IssueStatus.OPEN,
        reportedBy: 'Dispatch Team',
        reportedById: 8,
        createdAt: new Date('2025-12-01T13:00:00'),
        tags: ['Reports', 'Export', 'PDF'],
      },
      {
        id: 6,
        title: 'Email notifications not being sent',
        description: 'Users are not receiving email notifications for trip updates',
        type: IssueType.BUG,
        priority: IssuePriority.HIGH,
        status: IssueStatus.RESOLVED,
        assignedTo: 'Backend Team',
        assignedToId: 9,
        reportedBy: 'Customer Success',
        reportedById: 10,
        createdAt: new Date('2025-11-28T10:00:00'),
        updatedAt: new Date('2025-12-04T15:00:00'),
        resolvedAt: new Date('2025-12-04T15:00:00'),
        tags: ['Email', 'Notifications', 'SMTP'],
      },
      {
        id: 7,
        title: 'Improve driver onboarding documentation',
        description: 'Create comprehensive guide for new drivers on how to use the mobile app',
        type: IssueType.TASK,
        priority: IssuePriority.MEDIUM,
        status: IssueStatus.CLOSED,
        assignedTo: 'Documentation Team',
        assignedToId: 11,
        reportedBy: 'HR',
        reportedById: 12,
        createdAt: new Date('2025-11-25T09:00:00'),
        updatedAt: new Date('2025-11-30T17:00:00'),
        resolvedAt: new Date('2025-11-30T16:00:00'),
        closedAt: new Date('2025-11-30T17:00:00'),
        tags: ['Documentation', 'Onboarding', 'Training'],
      },
      {
        id: 8,
        title: 'Integration with accounting system',
        description: 'Need to integrate with QuickBooks for automated invoicing',
        type: IssueType.FEATURE,
        priority: IssuePriority.MEDIUM,
        status: IssueStatus.OPEN,
        reportedBy: 'Finance Team',
        reportedById: 13,
        createdAt: new Date('2025-11-20T11:00:00'),
        dueDate: new Date('2025-12-31'),
        tags: ['Integration', 'QuickBooks', 'Invoicing'],
      },
      {
        id: 9,
        title: 'Customer support ticket system',
        description: 'Need help desk integration for customer support tickets',
        type: IssueType.SUPPORT,
        priority: IssuePriority.LOW,
        status: IssueStatus.OPEN,
        reportedBy: 'Support Manager',
        reportedById: 14,
        createdAt: new Date('2025-11-15T14:00:00'),
        tags: ['Support', 'Help Desk', 'Customer Service'],
      },
      {
        id: 10,
        title: 'Route optimization algorithm improvements',
        description: 'Current routing can be improved to reduce fuel costs and delivery time',
        type: IssueType.IMPROVEMENT,
        priority: IssuePriority.HIGH,
        status: IssueStatus.IN_PROGRESS,
        assignedTo: 'Algorithm Team',
        assignedToId: 15,
        reportedBy: 'Operations',
        reportedById: 16,
        createdAt: new Date('2025-11-10T10:00:00'),
        updatedAt: new Date('2025-12-01T12:00:00'),
        dueDate: new Date('2025-12-20'),
        tags: ['Routing', 'Optimization', 'Algorithm'],
      },
    ];
  }
}
