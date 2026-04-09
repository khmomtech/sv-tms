import { Injectable } from '@angular/core';
import { HttpClient, HttpParams } from '@angular/common/http';
import { Observable, of } from 'rxjs';
import { delay } from 'rxjs/operators';
import {
  Issue,
  IssueComment,
  IssueFilter,
  IssueStatus,
  IssuePriority,
  IssueCategory,
} from '../models/issue.model';

@Injectable({
  providedIn: 'root',
})
export class IssueService {
  private apiUrl = '/api/issues';

  // Mock data for demo
  private mockIssues: Issue[] = [
    {
      id: 1,
      title: 'Fix driver assignment bug',
      description: 'Drivers are not being properly assigned to trips in the dispatch module',
      status: IssueStatus.OPEN,
      priority: IssuePriority.HIGH,
      category: IssueCategory.BUG,
      assignedToName: 'John Doe',
      reportedByName: 'Admin User',
      createdAt: '2025-12-05T10:30:00',
      tags: ['dispatch', 'drivers'],
      comments: [],
    },
    {
      id: 2,
      title: 'Add export feature to reports',
      description: 'Users need ability to export reports to PDF and Excel formats',
      status: IssueStatus.IN_PROGRESS,
      priority: IssuePriority.MEDIUM,
      category: IssueCategory.FEATURE,
      assignedToName: 'Jane Smith',
      reportedByName: 'Manager',
      createdAt: '2025-12-04T14:20:00',
      dueDate: '2025-12-15',
      tags: ['reports', 'export'],
      comments: [],
    },
    {
      id: 3,
      title: 'Improve dashboard loading speed',
      description: 'Dashboard takes too long to load with large datasets',
      status: IssueStatus.RESOLVED,
      priority: IssuePriority.MEDIUM,
      category: IssueCategory.IMPROVEMENT,
      assignedToName: 'John Doe',
      reportedByName: 'Admin User',
      createdAt: '2025-12-01T09:00:00',
      resolvedAt: '2025-12-05T16:30:00',
      tags: ['performance', 'dashboard'],
      comments: [],
    },
  ];

  constructor(private http: HttpClient) {}

  getAllIssues(
    page: number = 0,
    size: number = 10,
    filter?: IssueFilter,
  ): Observable<{ content: Issue[]; totalElements: number; totalPages: number }> {
    // For demo, return mock data with pagination
    let filtered = [...this.mockIssues];

    if (filter) {
      if (filter.status) {
        const statusArray = Array.isArray(filter.status) ? filter.status : [filter.status];
        filtered = filtered.filter((i) => statusArray.includes(i.status));
      }
      if (filter.priority) {
        const priorityArray = Array.isArray(filter.priority) ? filter.priority : [filter.priority];
        filtered = filtered.filter((i) => priorityArray.includes(i.priority));
      }
      if (filter.category) {
        const categoryArray = Array.isArray(filter.category) ? filter.category : [filter.category];
        filtered = filtered.filter((i) => categoryArray.includes(i.category));
      }
      if (filter.search) {
        const search = filter.search.toLowerCase();
        filtered = filtered.filter(
          (i) =>
            i.title.toLowerCase().includes(search) || i.description.toLowerCase().includes(search),
        );
      }
    }

    const totalElements = filtered.length;
    const totalPages = Math.ceil(totalElements / size);
    const start = page * size;
    const end = start + size;
    const content = filtered.slice(start, end);

    return of({ content, totalElements, totalPages }).pipe(delay(300));

    // Real implementation:
    // let params = new HttpParams()
    //   .set('page', page.toString())
    //   .set('size', size.toString());
    // if (filter) {
    //   Object.keys(filter).forEach(key => {
    //     const value = (filter as any)[key];
    //     if (value) params = params.set(key, value);
    //   });
    // }
    // return this.http.get<{ content: Issue[], totalElements: number, totalPages: number }>(this.apiUrl, { params });
  }

  getIssueById(id: number): Observable<Issue> {
    const issue = this.mockIssues.find((i) => i.id === id);
    return of(issue || this.mockIssues[0]).pipe(delay(200));
    // return this.http.get<Issue>(`${this.apiUrl}/${id}`);
  }

  createIssue(issue: Issue): Observable<Issue> {
    const newIssue = {
      ...issue,
      id: Math.max(...this.mockIssues.map((i) => i.id || 0)) + 1,
      createdAt: new Date().toISOString(),
      reportedByName: 'Current User',
    };
    this.mockIssues.unshift(newIssue);
    return of(newIssue).pipe(delay(300));
    // return this.http.post<Issue>(this.apiUrl, issue);
  }

  updateIssue(id: number, issue: Partial<Issue>): Observable<Issue> {
    const index = this.mockIssues.findIndex((i) => i.id === id);
    if (index !== -1) {
      this.mockIssues[index] = {
        ...this.mockIssues[index],
        ...issue,
        updatedAt: new Date().toISOString(),
      };
      return of(this.mockIssues[index]).pipe(delay(300));
    }
    return of({} as Issue);
    // return this.http.put<Issue>(`${this.apiUrl}/${id}`, issue);
  }

  deleteIssue(id: number): Observable<void> {
    this.mockIssues = this.mockIssues.filter((i) => i.id !== id);
    return of(void 0).pipe(delay(200));
    // return this.http.delete<void>(`${this.apiUrl}/${id}`);
  }

  assignIssue(id: number, userId: number): Observable<Issue> {
    return this.updateIssue(id, { assignedTo: userId });
    // return this.http.post<Issue>(`${this.apiUrl}/${id}/assign`, { userId });
  }

  resolveIssue(id: number): Observable<Issue> {
    return this.updateIssue(id, {
      status: IssueStatus.RESOLVED,
      resolvedAt: new Date().toISOString(),
    });
    // return this.http.post<Issue>(`${this.apiUrl}/${id}/resolve`, {});
  }

  addComment(issueId: number, comment: string): Observable<IssueComment> {
    const newComment: IssueComment = {
      id: Date.now(),
      issueId,
      userId: 1,
      userName: 'Current User',
      comment,
      createdAt: new Date().toISOString(),
    };
    return of(newComment).pipe(delay(200));
    // return this.http.post<IssueComment>(`${this.apiUrl}/${issueId}/comments`, { comment });
  }

  getMyIssues(): Observable<{ content: Issue[]; totalElements: number; totalPages: number }> {
    return this.getAllIssues(0, 10, { assignedTo: 1 }); // Mock current user ID = 1
  }

  getOpenIssues(): Observable<{ content: Issue[]; totalElements: number; totalPages: number }> {
    return this.getAllIssues(0, 10, { status: [IssueStatus.OPEN, IssueStatus.REOPENED] });
  }

  getClosedIssues(): Observable<{ content: Issue[]; totalElements: number; totalPages: number }> {
    return this.getAllIssues(0, 10, { status: [IssueStatus.CLOSED, IssueStatus.RESOLVED] });
  }
}
