import type { Routes } from '@angular/router';

export const TASK_ROUTES: Routes = [
  {
    path: '',
    loadComponent: () =>
      import('../../components/unified-tasks/unified-task-list/unified-task-list.component').then(
        (m) => m.UnifiedTaskListComponent,
      ),
    data: {
      title: 'Task Management',
      breadcrumb: 'Tasks',
    },
  },
  {
    path: 'create',
    loadComponent: () =>
      import('../../components/unified-tasks/unified-task-form/unified-task-form.component').then(
        (m) => m.UnifiedTaskFormComponent,
      ),
    data: {
      title: 'Create Task',
      breadcrumb: 'Create',
    },
  },
  {
    path: ':id/edit',
    loadComponent: () =>
      import('../../components/unified-tasks/unified-task-form/unified-task-form.component').then(
        (m) => m.UnifiedTaskFormComponent,
      ),
    data: {
      title: 'Edit Task',
      breadcrumb: 'Edit',
    },
  },
  {
    path: ':id',
    loadComponent: () =>
      import('../../components/unified-tasks/unified-task-detail/unified-task-detail.component').then(
        (m) => m.UnifiedTaskDetailComponent,
      ),
    data: {
      title: 'Task Details',
      breadcrumb: 'Details',
    },
  },
  // Legacy maintenance tasks routes (keep for backwards compatibility)
  {
    path: 'maintenance/list',
    loadComponent: () =>
      import('../../components/tasks/task-list/task-list.component').then(
        (m) => m.TaskListComponent,
      ),
    data: {
      title: 'Maintenance Tasks',
      breadcrumb: 'Maintenance Tasks',
    },
  },
  {
    path: 'maintenance/create',
    loadComponent: () =>
      import('../../components/tasks/task-form/task-form.component').then(
        (m) => m.TaskFormComponent,
      ),
    data: {
      title: 'Create Maintenance Task',
      breadcrumb: 'Create',
    },
  },
  {
    path: 'maintenance/:id/edit',
    loadComponent: () =>
      import('../../components/tasks/task-form/task-form.component').then(
        (m) => m.TaskFormComponent,
      ),
    data: {
      title: 'Edit Maintenance Task',
      breadcrumb: 'Edit',
    },
  },
  {
    path: 'maintenance/:id',
    loadComponent: () =>
      import('../../components/tasks/task-detail/task-detail.component').then(
        (m) => m.TaskDetailComponent,
      ),
    data: {
      title: 'Maintenance Task Details',
      breadcrumb: 'Details',
    },
  },
];
