import { Page, Locator, expect } from '@playwright/test';

/**
 * Page Object Model for Task Management
 * Encapsulates all task-related UI interactions
 */
export class TaskManagementPage {
  readonly page: Page;

  // List view locators
  readonly createTaskButton: Locator;
  readonly searchInput: Locator;
  readonly statusFilter: Locator;
  readonly priorityFilter: Locator;
  readonly overdueCheckbox: Locator;
  readonly applyFilterButton: Locator;
  readonly clearFilterButton: Locator;
  readonly taskTable: Locator;
  readonly taskRows: Locator;

  // Statistics dashboard locators
  readonly totalTasksCard: Locator;
  readonly openTasksCard: Locator;
  readonly inProgressTasksCard: Locator;
  readonly overdueTasksCard: Locator;

  // Modal locators
  readonly modal: Locator;
  readonly modalTitle: Locator;
  readonly titleInput: Locator;
  readonly descriptionInput: Locator;
  readonly statusSelect: Locator;
  readonly prioritySelect: Locator;
  readonly estimatedMinutesInput: Locator;
  readonly dueDateInput: Locator;
  readonly saveButton: Locator;
  readonly cancelButton: Locator;

  // Detail view locators
  readonly taskCode: Locator;
  readonly taskTitle: Locator;
  readonly taskDescription: Locator;
  readonly progressBar: Locator;
  readonly editButton: Locator;
  readonly completeButton: Locator;
  readonly deleteButton: Locator;

  // Comments section
  readonly commentsSection: Locator;
  readonly commentInput: Locator;
  readonly addCommentButton: Locator;
  readonly commentsList: Locator;

  // Attachments section
  readonly attachmentsSection: Locator;
  readonly attachmentsList: Locator;
  readonly uploadButton: Locator;

  constructor(page: Page) {
    this.page = page;

    // List view
    this.createTaskButton = page.locator('button:has-text("Create Task"), button:has-text("New Task")');
    this.searchInput = page.locator('input[type="search"], input[placeholder*="Search"]');
    this.statusFilter = page.locator('select[name="status"], #statusFilter');
    this.priorityFilter = page.locator('select[name="priority"], #priorityFilter');
    this.overdueCheckbox = page.locator('input[type="checkbox"][name="overdue"], #overdueOnly');
    this.applyFilterButton = page.locator('button:has-text("Apply"), button:has-text("Search")');
    this.clearFilterButton = page.locator('button:has-text("Clear"), button:has-text("Reset")');
    this.taskTable = page.locator('table, .task-list');
    this.taskRows = page.locator('tbody tr, .task-item');

    // Statistics
    this.totalTasksCard = page.locator('[data-testid="total-tasks"], .stat-card:has-text("Total")');
    this.openTasksCard = page.locator('[data-testid="open-tasks"], .stat-card:has-text("Open")');
    this.inProgressTasksCard = page.locator('[data-testid="in-progress-tasks"]');
    this.overdueTasksCard = page.locator('[data-testid="overdue-tasks"], .stat-card:has-text("Overdue")');

    // Modal
    this.modal = page.locator('.modal-dialog, [role="dialog"]');
    this.modalTitle = page.locator('.modal-title, [role="dialog"] h1, [role="dialog"] h2');
    this.titleInput = page.locator('input[name="title"], #title');
    this.descriptionInput = page.locator('textarea[name="description"], #description');
    this.statusSelect = page.locator('select[name="status"], #status');
    this.prioritySelect = page.locator('select[name="priority"], #priority');
    this.estimatedMinutesInput = page.locator('input[name="estimatedMinutes"], #estimatedMinutes');
    this.dueDateInput = page.locator('input[name="dueDate"], #dueDate');
    this.saveButton = page.locator('button[type="submit"]:has-text("Save"), button:has-text("Create")');
    this.cancelButton = page.locator('button:has-text("Cancel")');

    // Detail view
    this.taskCode = page.locator('[data-testid="task-code"], .task-code');
    this.taskTitle = page.locator('[data-testid="task-title"], .task-title, h1');
    this.taskDescription = page.locator('[data-testid="task-description"], .task-description');
    this.progressBar = page.locator('.progress-bar, [role="progressbar"]');
    this.editButton = page.locator('button:has-text("Edit"), .edit-btn');
    this.completeButton = page.locator('button:has-text("Complete"), button:has-text("Mark Complete")');
    this.deleteButton = page.locator('button:has-text("Delete")');

    // Comments
    this.commentsSection = page.locator('[data-testid="comments-section"], .comments-section');
    this.commentInput = page.locator('textarea[name="comment"], #commentContent');
    this.addCommentButton = page.locator('button:has-text("Add Comment"), button:has-text("Post")');
    this.commentsList = page.locator('.comment-item, .comment');

    // Attachments
    this.attachmentsSection = page.locator('[data-testid="attachments-section"], .attachments-section');
    this.attachmentsList = page.locator('.attachment-item, .attachment');
    this.uploadButton = page.locator('button:has-text("Upload"), input[type="file"]');
  }

  // Navigation
  async goto() {
    await this.page.goto('/tasks');
    await this.page.waitForLoadState('networkidle');
  }

  async gotoTaskDetail(taskId: number) {
    await this.page.goto(`/tasks/${taskId}`);
    await this.page.waitForLoadState('networkidle');
  }

  // List operations
  async searchTasks(keyword: string) {
    await this.searchInput.fill(keyword);
    await this.page.waitForTimeout(500); // Debounce
  }

  async filterByStatus(status: string) {
    await this.statusFilter.selectOption(status);
    await this.applyFilterButton.click();
  }

  async filterByPriority(priority: string | string[]) {
    await this.priorityFilter.selectOption(priority);
    await this.applyFilterButton.click();
  }

  async showOnlyOverdue() {
    await this.overdueCheckbox.check();
  }

  async clearFilters() {
    await this.clearFilterButton.click();
  }

  async getTaskCount(): Promise<number> {
    return await this.taskRows.count();
  }

  async clickTask(taskCode: string) {
    await this.page.click(`text=${taskCode}`);
  }

  // CRUD operations
  async openCreateModal() {
    await this.createTaskButton.click();
    await expect(this.modal).toBeVisible();
  }

  async createTask(data: {
    title: string;
    description?: string;
    status?: string;
    priority?: string;
    estimatedMinutes?: number;
    dueDate?: string;
  }) {
    await this.openCreateModal();

    await this.titleInput.fill(data.title);

    if (data.description) {
      await this.descriptionInput.fill(data.description);
    }

    if (data.status) {
      await this.statusSelect.selectOption(data.status);
    }

    if (data.priority) {
      await this.prioritySelect.selectOption(data.priority);
    }

    if (data.estimatedMinutes) {
      await this.estimatedMinutesInput.fill(data.estimatedMinutes.toString());
    }

    if (data.dueDate) {
      await this.dueDateInput.fill(data.dueDate);
    }

    await this.saveButton.click();
  }

  async editTask() {
    await this.editButton.click();
  }

  async completeTask() {
    await this.completeButton.click();
    // Confirm dialog if exists
    const confirmButton = this.page.locator('button:has-text("Confirm"), button:has-text("Yes")');
    if (await confirmButton.isVisible()) {
      await confirmButton.click();
    }
  }

  async deleteTask() {
    await this.deleteButton.click();
    // Confirm deletion
    const confirmButton = this.page.locator('button:has-text("Confirm"), button:has-text("Delete")');
    await confirmButton.click();
  }

  // Comments
  async addComment(content: string) {
    await this.commentInput.fill(content);
    await this.addCommentButton.click();
  }

  async getCommentsCount(): Promise<number> {
    return await this.commentsList.count();
  }

  // Attachments
  async uploadAttachment(filePath: string) {
    const fileInput = this.page.locator('input[type="file"]');
    await fileInput.setInputFiles(filePath);
  }

  async getAttachmentsCount(): Promise<number> {
    return await this.attachmentsList.count();
  }

  // Statistics
  async getStatistic(name: 'total' | 'open' | 'inProgress' | 'overdue'): Promise<string> {
    let locator: Locator;

    switch (name) {
      case 'total':
        locator = this.totalTasksCard;
        break;
      case 'open':
        locator = this.openTasksCard;
        break;
      case 'inProgress':
        locator = this.inProgressTasksCard;
        break;
      case 'overdue':
        locator = this.overdueTasksCard;
        break;
    }

    return await locator.textContent() || '0';
  }

  // Assertions
  async expectTaskVisible(taskCode: string) {
    await expect(this.page.locator(`text=${taskCode}`)).toBeVisible();
  }

  async expectStatusBadge(status: string) {
    const badge = this.page.locator(`.badge:has-text("${status}")`);
    await expect(badge).toBeVisible();
  }

  async expectPriorityBadge(priority: string) {
    const badge = this.page.locator(`.badge:has-text("${priority}")`);
    await expect(badge).toBeVisible();
  }

  async expectSuccessMessage(message?: string) {
    const locator = message
      ? this.page.locator(`text=${message}`)
      : this.page.locator('.alert-success, .toast-success, text=Success');
    await expect(locator).toBeVisible({ timeout: 5000 });
  }

  async expectErrorMessage(message?: string) {
    const locator = message
      ? this.page.locator(`text=${message}`)
      : this.page.locator('.alert-danger, .toast-error, text=Error');
    await expect(locator).toBeVisible({ timeout: 5000 });
  }
}
