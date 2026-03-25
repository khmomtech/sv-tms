import { test, expect } from '@playwright/test';
import { mockAuthentication, TEST_USERS } from './helpers/auth.helper';

/**
 * Unified Task Management System - E2E Tests
 * Tests CRUD operations, filtering, search, and UI/UX interactions
 */

test.describe('Task Management - CRUD Operations', () => {
  test.beforeEach(async ({ page }) => {
    await mockAuthentication(page, TEST_USERS.admin);

    // Mock API responses
    await page.route('**/api/tasks**', async (route) => {
      const url = route.request().url();
      const method = route.request().method();

      if (method === 'GET' && url.includes('/statistics')) {
        await route.fulfill({
          status: 200,
          contentType: 'application/json',
          body: JSON.stringify({
            success: true,
            data: {
              totalTasks: 150,
              openTasks: 45,
              inProgressTasks: 32,
              completedTasks: 58,
              blockedTasks: 5,
              onHoldTasks: 3,
              inReviewTasks: 4,
              cancelledTasks: 3,
              criticalPriorityTasks: 12,
              highPriorityTasks: 28,
              mediumPriorityTasks: 85,
              lowPriorityTasks: 25,
              overdueTasks: 8,
              tasksAssignedToMe: 15,
              tasksCreatedByMe: 22,
              tasksWatchedByMe: 18,
              standaloneTasks: 35
            }
          })
        });
      } else if (method === 'GET') {
        await route.fulfill({
          status: 200,
          contentType: 'application/json',
          body: JSON.stringify({
            success: true,
            data: {
              content: [
                {
                  id: 1,
                  code: 'TASK-2025-0001',
                  title: 'Replace brake pads on V-123',
                  description: 'Annual maintenance task',
                  status: 'OPEN',
                  priority: 'HIGH',
                  relationType: 'WORK_ORDER',
                  relationId: 567,
                  dueDate: '2025-12-15T10:00:00',
                  estimatedMinutes: 120,
                  assignedToUsername: 'john.doe',
                  createdByUsername: 'admin',
                  isOverdue: false,
                  commentsCount: 2,
                  attachmentsCount: 1,
                  watchersCount: 3
                },
                {
                  id: 2,
                  code: 'TASK-2025-0002',
                  title: 'Emergency coolant replacement',
                  description: 'Incident response task',
                  status: 'IN_PROGRESS',
                  priority: 'CRITICAL',
                  relationType: 'INCIDENT',
                  relationId: 89,
                  dueDate: '2025-12-10T14:00:00',
                  estimatedMinutes: 60,
                  actualMinutes: 45,
                  assignedToUsername: 'jane.smith',
                  createdByUsername: 'dispatcher',
                  isOverdue: true,
                  commentsCount: 5,
                  attachmentsCount: 2,
                  watchersCount: 4
                }
              ],
              totalElements: 2,
              totalPages: 1,
              number: 0,
              size: 20
            }
          })
        });
      } else if (method === 'POST') {
        const postData = await route.request().postDataJSON();
        await route.fulfill({
          status: 201,
          contentType: 'application/json',
          body: JSON.stringify({
            success: true,
            message: 'Task created successfully',
            data: {
              id: 999,
              code: 'TASK-2025-0999',
              ...postData,
              createdAt: new Date().toISOString()
            }
          })
        });
      }
    });
  });

  test('should display task list with statistics dashboard', async ({ page }) => {
    await page.goto('/tasks');
    await page.waitForLoadState('networkidle');

    // Check statistics cards are visible
    await expect(page.locator('text=Total Tasks')).toBeVisible();
    await expect(page.locator('text=150')).toBeVisible(); // Total count
    await expect(page.locator('text=Open Tasks')).toBeVisible();
    await expect(page.locator('text=45')).toBeVisible();

    // Check priority breakdown - use more specific selector to avoid strict mode
    await expect(page.locator('[data-testid="stats-card"]:has-text("Critical")').first()).toBeVisible();
    await expect(page.locator('text=12')).toBeVisible();

    // Check overdue indicator
    await expect(page.locator('text=Overdue')).toBeVisible();
    await expect(page.locator('text=8')).toBeVisible();
  });

  test('should display task list table with correct columns', async ({ page }) => {
    await page.goto('/tasks');
    await page.waitForLoadState('networkidle');

    // Check table headers
    await expect(page.locator('th:has-text("Code")')).toBeVisible();
    await expect(page.locator('th:has-text("Title")')).toBeVisible();
    await expect(page.locator('th:has-text("Status")')).toBeVisible();
    await expect(page.locator('th:has-text("Priority")')).toBeVisible();
    await expect(page.locator('th:has-text("Assigned To")')).toBeVisible();
    await expect(page.locator('th:has-text("Due Date")')).toBeVisible();

    // Check task data is displayed
    await expect(page.locator('text=TASK-2025-0001')).toBeVisible();
    await expect(page.locator('text=Replace brake pads on V-123')).toBeVisible();
    await expect(page.locator('text=john.doe')).toBeVisible();
  });

  test('should show status badges with correct styling', async ({ page }) => {
    await page.goto('/tasks');
    await page.waitForLoadState('networkidle');

    // Check OPEN status badge
    const openBadge = page.locator('.badge.bg-secondary:has-text("Open")');
    await expect(openBadge).toBeVisible();

    // Check IN_PROGRESS status badge
    const inProgressBadge = page.locator('.badge.bg-primary:has-text("In Progress")');
    await expect(inProgressBadge).toBeVisible();

    // Check HIGH priority
    const highPriorityBadge = page.locator('.badge:has-text("High")');
    await expect(highPriorityBadge).toBeVisible();

    // Check CRITICAL priority
    const criticalPriorityBadge = page.locator('.badge:has-text("Critical")');
    await expect(criticalPriorityBadge).toBeVisible();
  });

  test('should highlight overdue tasks', async ({ page }) => {
    await page.goto('/tasks');
    await page.waitForLoadState('networkidle');

    // Check for overdue indicator (usually red text or icon)
    const overdueRow = page.locator('tr:has-text("Emergency coolant replacement")');
    await expect(overdueRow).toBeVisible();

    // Should have some visual indicator (class, icon, or color)
    const overdueIndicator = overdueRow.locator('.text-danger, .overdue-badge, .bi-exclamation-triangle');
    const count = await overdueIndicator.count();
    expect(count).toBeGreaterThan(0);
  });

  test('should open create task modal', async ({ page }) => {
    await page.goto('/tasks');
    await page.waitForLoadState('networkidle');

    // Click create button
    await page.click('button:has-text("Create Task"), button:has-text("New Task")');

    // Modal should appear - use .first() to avoid strict mode violation
    await expect(page.locator('.modal-dialog, [role="dialog"]').first()).toBeVisible();
    await expect(page.locator('.modal-title, h5:has-text("Create")').first()).toBeVisible();

    // Check form fields
    await expect(page.locator('input[name="title"], #title').first()).toBeVisible();
    await expect(page.locator('select[name="status"], #status').first()).toBeVisible();
    await expect(page.locator('select[name="priority"], #priority').first()).toBeVisible();
  });

  test('should create a new standalone task', async ({ page }) => {
    await page.goto('/tasks');
    await page.waitForLoadState('networkidle');

    // Open create modal
    await page.click('button:has-text("Create Task"), button:has-text("New Task")');
    await page.waitForSelector('.modal-dialog, [role="dialog"]');

    // Fill form
    await page.fill('input[name="title"], #title', 'Review security vulnerabilities');
    await page.fill('textarea[name="description"], #description', 'Conduct security audit');
    await page.selectOption('select[name="priority"], #priority', 'HIGH');
    await page.fill('input[type="number"][name="estimatedMinutes"], #estimatedMinutes', '180');

    // Submit
    await page.click('button[type="submit"]:has-text("Create"), button:has-text("Save")');

    // Should show success message
    await expect(page.locator('text=Task created successfully, Success')).toBeVisible({ timeout: 5000 });
  });

  test('should validate required fields', async ({ page }) => {
    await page.goto('/tasks');
    await page.waitForLoadState('networkidle');

    // Open create modal
    await page.click('button:has-text("Create Task"), button:has-text("New Task")');
    await page.waitForSelector('.modal-dialog, [role="dialog"]', { timeout: 10000 });

    // Try to submit without title - look for any submit button in the modal
    const submitButton = page.locator('.modal button[type="submit"]').first();
    await expect(submitButton).toBeVisible({ timeout: 10000 });
    await submitButton.click();

    // Should show validation error
    await expect(page.locator('text=/required|Title is required/i')).toBeVisible();
  });
});

test.describe('Task Management - Filtering & Search', () => {
  test.beforeEach(async ({ page }) => {
    await mockAuthentication(page, TEST_USERS.admin);

    await page.route('**/api/tasks**', async (route) => {
      await route.fulfill({
        status: 200,
        contentType: 'application/json',
        body: JSON.stringify({
          success: true,
          data: {
            content: [],
            totalElements: 0
          }
        })
      });
    });
  });

  test('should filter by status', async ({ page }) => {
    await page.goto('/tasks');
    await page.waitForLoadState('networkidle');

    // Open filter dropdown
    await page.click('button:has-text("Filter"), select[name="status"], #statusFilter');

    // Select IN_PROGRESS
    await page.selectOption('select[name="status"], #statusFilter', 'IN_PROGRESS');

    // Should trigger API call with status filter
    const apiCall = page.waitForRequest(req =>
      req.url().includes('/api/tasks') &&
      req.url().includes('status=IN_PROGRESS')
    );

    await page.click('button:has-text("Apply Filter"), button:has-text("Search")');
    await apiCall;
  });

  test('should filter by priority', async ({ page }) => {
    await page.goto('/tasks');
    await page.waitForLoadState('networkidle');

    // Select multiple priorities
    const prioritySelect = page.locator('select[name="priority"], #priorityFilter');
    if (await prioritySelect.isVisible()) {
      await prioritySelect.selectOption(['CRITICAL', 'HIGH']);
    }

    // Apply filter
    await page.click('button:has-text("Apply"), button:has-text("Search")');

    // Check URL has filter params
    await expect(page).toHaveURL(/priority=(CRITICAL|HIGH)/);
  });

  test('should search by keyword', async ({ page }) => {
    await page.goto('/tasks');
    await page.waitForLoadState('networkidle');

    // Type in search box
    const searchInput = page.locator('input[type="search"], input[placeholder*="Search"]');
    await searchInput.fill('brake');

    // Should debounce and trigger search
    await page.waitForTimeout(500);

    const apiCall = page.waitForRequest(req =>
      req.url().includes('/api/tasks') &&
      req.url().includes('keyword=brake')
    );
    await apiCall;
  });

  test('should show overdue tasks only', async ({ page }) => {
    await page.goto('/tasks');
    await page.waitForLoadState('networkidle');

    // Click overdue filter
    const overdueCheckbox = page.locator('input[type="checkbox"][name="overdue"], #overdueOnly');
    await overdueCheckbox.check();

    // Should filter to overdue
    const apiCall = page.waitForRequest(req =>
      req.url().includes('/api/tasks') &&
      req.url().includes('overdue=true')
    );
    await apiCall;
  });

  test('should filter by relation type (Work Orders)', async ({ page }) => {
    await page.goto('/tasks');
    await page.waitForLoadState('networkidle');

    // Select relation type
    const relationSelect = page.locator('select[name="relationType"], #relationType');
    if (await relationSelect.isVisible()) {
      await relationSelect.selectOption('WORK_ORDER');
      await page.click('button:has-text("Apply")');
    }

    // Should show only work order tasks
    await expect(page).toHaveURL(/relationType=WORK_ORDER/);
  });

  test('should clear all filters', async ({ page }) => {
    await page.goto('/tasks?status=OPEN&priority=HIGH&overdue=true');
    await page.waitForLoadState('networkidle');

    // Click clear filters
    await page.click('button:has-text("Clear"), button:has-text("Reset")');

    // URL should reset
    await expect(page).toHaveURL(/\/tasks$/);
  });
});

test.describe('Task Management - Detail View & Actions', () => {
  test.beforeEach(async ({ page }) => {
    await mockAuthentication(page, TEST_USERS.admin);

    await page.route('**/api/tasks/1', async (route) => {
      await route.fulfill({
        status: 200,
        contentType: 'application/json',
        body: JSON.stringify({
          success: true,
          data: {
            id: 1,
            code: 'TASK-2025-0001',
            title: 'Replace brake pads',
            description: 'Complete brake system maintenance',
            status: 'IN_PROGRESS',
            priority: 'HIGH',
            estimatedMinutes: 120,
            actualMinutes: 90,
            progressPercentage: 75,
            dueDate: '2025-12-15T10:00:00',
            relationType: 'WORK_ORDER',
            relationId: 567
          }
        })
      });
    });

    await page.route('**/api/tasks/1/comments', async (route) => {
      await route.fulfill({
        status: 200,
        contentType: 'application/json',
        body: JSON.stringify({
          success: true,
          data: [
            {
              id: 1,
              content: 'Started work on this task',
              authorUsername: 'john.doe',
              createdAt: '2025-12-09T08:00:00',
              isInternal: false
            }
          ]
        })
      });
    });

    await page.route('**/api/tasks/1/attachments', async (route) => {
      await route.fulfill({
        status: 200,
        contentType: 'application/json',
        body: JSON.stringify({
          success: true,
          data: [
            {
              id: 1,
              fileName: 'brake_inspection_photo.jpg',
              fileUrl: '/uploads/tasks/1/photo.jpg',
              mimeType: 'image/jpeg',
              fileSizeBytes: 245678
            }
          ]
        })
      });
    });
  });

  test('should display task detail view', async ({ page }) => {
    await page.goto('/tasks/1');
    await page.waitForLoadState('networkidle');

    // Check task info
    await expect(page.locator('text=TASK-2025-0001')).toBeVisible();
    await expect(page.locator('text=Replace brake pads')).toBeVisible();
    await expect(page.locator('text=Complete brake system maintenance')).toBeVisible();

    // Check progress bar
    const progressBar = page.locator('.progress-bar, [role="progressbar"]');
    await expect(progressBar).toBeVisible();
    await expect(progressBar).toHaveText(/75%/);
  });

  test('should show comments section', async ({ page }) => {
    await page.goto('/tasks/1');
    await page.waitForLoadState('networkidle');

    // Comments section
    await expect(page.locator('text=Comments')).toBeVisible();
    await expect(page.locator('text=Started work on this task')).toBeVisible();
    await expect(page.locator('text=john.doe')).toBeVisible();
  });

  test('should add a comment', async ({ page }) => {
    await page.route('**/api/tasks/1/comments', async (route) => {
      if (route.request().method() === 'POST') {
        await route.fulfill({
          status: 200,
          contentType: 'application/json',
          body: JSON.stringify({
            success: true,
            message: 'Comment added',
            data: { id: 2, content: 'Test comment' }
          })
        });
      }
    });

    await page.goto('/tasks/1');
    await page.waitForLoadState('networkidle');

    // Add comment
    await page.fill('textarea[name="comment"], #commentContent', 'Work is progressing well');
    await page.click('button:has-text("Add Comment"), button:has-text("Post")');

    // Success message
    await expect(page.locator('text=Comment added')).toBeVisible({ timeout: 5000 });
  });

  test('should display attachments', async ({ page }) => {
    await page.goto('/tasks/1');
    await page.waitForLoadState('networkidle');

    // Attachments section
    await expect(page.locator('text=Attachments')).toBeVisible();
    await expect(page.locator('text=brake_inspection_photo.jpg')).toBeVisible();
  });

  test('should complete task', async ({ page }) => {
    await page.route('**/api/tasks/1/complete', async (route) => {
      await route.fulfill({
        status: 200,
        contentType: 'application/json',
        body: JSON.stringify({
          success: true,
          message: 'Task completed successfully'
        })
      });
    });

    await page.goto('/tasks/1');
    await page.waitForLoadState('networkidle');

    // Click complete button
    await page.click('button:has-text("Complete Task"), button:has-text("Mark Complete")');

    // Confirm dialog
    await page.click('button:has-text("Confirm"), button:has-text("Yes")');

    // Success message
    await expect(page.locator('text=Task completed')).toBeVisible({ timeout: 5000 });
  });

  test('should update task status', async ({ page }) => {
    await page.route('**/api/tasks/1', async (route) => {
      if (route.request().method() === 'PUT') {
        await route.fulfill({
          status: 200,
          contentType: 'application/json',
          body: JSON.stringify({
            success: true,
            message: 'Task updated'
          })
        });
      }
    });

    await page.goto('/tasks/1');
    await page.waitForLoadState('networkidle');

    // Change status
    await page.click('button:has-text("Edit"), .edit-btn');
    await page.selectOption('select[name="status"]', 'COMPLETED');
    await page.click('button:has-text("Save")');

    // Success
    await expect(page.locator('text=Task updated')).toBeVisible({ timeout: 5000 });
  });
});

test.describe('Task Management - Accessibility', () => {
  test('should be keyboard navigable', async ({ page }) => {
    await mockAuthentication(page, TEST_USERS.admin);
    await page.goto('/tasks');
    await page.waitForLoadState('networkidle');

    // Tab through elements
    await page.keyboard.press('Tab');
    await page.keyboard.press('Tab');
    await page.keyboard.press('Tab');

    // Should be able to focus on interactive elements
    const focusedElement = await page.evaluate(() => document.activeElement?.tagName);
    expect(['BUTTON', 'A', 'INPUT', 'SELECT']).toContain(focusedElement);
  });

  test('should have proper ARIA labels', async ({ page }) => {
    await mockAuthentication(page, TEST_USERS.admin);
    await page.goto('/tasks');
    await page.waitForLoadState('networkidle');

    // Check for ARIA labels on important elements
    const createButton = page.locator('button:has-text("Create Task")');
    if (await createButton.count() > 0) {
      const ariaLabel = await createButton.getAttribute('aria-label');
      expect(ariaLabel).toBeTruthy();
    }
  });
});
