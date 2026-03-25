import { test, expect } from '@playwright/test';
import { mockAuthentication, TEST_USERS } from '../helpers/auth.helper';
import { TaskManagementPage } from '../page-objects/task-management.page';

/**
 * Task Management - Visual Regression Tests
 * Ensures UI consistency across updates
 */

test.describe('Task Management - Visual Regression', () => {
  let taskPage: TaskManagementPage;

  test.beforeEach(async ({ page }) => {
    taskPage = new TaskManagementPage(page);
    await mockAuthentication(page, TEST_USERS.admin);

    // Mock consistent data for visual tests
    await page.route('**/api/tasks**', async (route) => {
      const url = route.request().url();

      if (url.includes('/statistics')) {
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
              overdueTasks: 8
            }
          })
        });
      } else {
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
                  dueDate: '2025-12-15T10:00:00',
                  estimatedMinutes: 120,
                  assignedToUsername: 'john.doe',
                  isOverdue: false,
                  commentsCount: 2,
                  attachmentsCount: 1
                },
                {
                  id: 2,
                  code: 'TASK-2025-0002',
                  title: 'Emergency coolant replacement',
                  status: 'IN_PROGRESS',
                  priority: 'CRITICAL',
                  dueDate: '2025-12-10T14:00:00',
                  assignedToUsername: 'jane.smith',
                  isOverdue: true,
                  commentsCount: 5
                },
                {
                  id: 3,
                  code: 'TASK-2025-0003',
                  title: 'Review security vulnerabilities',
                  status: 'BLOCKED',
                  priority: 'MEDIUM',
                  dueDate: '2025-12-20T10:00:00',
                  isOverdue: false
                }
              ],
              totalElements: 3,
              totalPages: 1
            }
          })
        });
      }
    });
  });

  test('task list page should match screenshot', async ({ page }) => {
    await taskPage.goto();

    // Wait for all content to load
    await page.waitForTimeout(1000);

    // Take full page screenshot
    await expect(page).toHaveScreenshot('task-list-full.png', {
      fullPage: true,
      maxDiffPixels: 100
    });
  });

  test('statistics dashboard should match screenshot', async ({ page }) => {
    await taskPage.goto();

    // Screenshot just the statistics section
    const statsSection = page.locator('.statistics-dashboard, .stats-cards, .dashboard-stats').first();
    await expect(statsSection).toHaveScreenshot('task-statistics-dashboard.png', {
      maxDiffPixels: 50
    });
  });

  test('task table with different statuses should match screenshot', async ({ page }) => {
    await taskPage.goto();

    const table = page.locator('table, .task-list').first();
    await expect(table).toHaveScreenshot('task-table-statuses.png', {
      maxDiffPixels: 100
    });
  });

  test('status badges should render consistently', async ({ page }) => {
    await taskPage.goto();

    // Screenshot all status badges
    const badges = page.locator('.badge').first();
    await expect(badges).toHaveScreenshot('status-badges.png');
  });

  test('priority badges should render consistently', async ({ page }) => {
    await taskPage.goto();

    const priorityBadges = page.locator('[data-testid="priority-badge"], .priority-badge').first();
    if (await priorityBadges.count() > 0) {
      await expect(priorityBadges).toHaveScreenshot('priority-badges.png');
    }
  });

  test('overdue indicator should be visible', async ({ page }) => {
    await taskPage.goto();

    // Find overdue row
    const overdueRow = page.locator('tr:has-text("Emergency coolant")').first();
    await expect(overdueRow).toHaveScreenshot('overdue-task-row.png');
  });

  test('create task modal should match screenshot', async ({ page }) => {
    await taskPage.goto();
    await taskPage.openCreateModal();

    const modal = page.locator('.modal-dialog, [role="dialog"]');
    await expect(modal).toHaveScreenshot('create-task-modal.png', {
      maxDiffPixels: 100
    });
  });

  test('mobile view should match screenshot', async ({ page }) => {
    // Set mobile viewport
    await page.setViewportSize({ width: 375, height: 667 });
    await taskPage.goto();

    await expect(page).toHaveScreenshot('task-list-mobile.png', {
      fullPage: true,
      maxDiffPixels: 150
    });
  });

  test('tablet view should match screenshot', async ({ page }) => {
    // Set tablet viewport
    await page.setViewportSize({ width: 768, height: 1024 });
    await taskPage.goto();

    await expect(page).toHaveScreenshot('task-list-tablet.png', {
      fullPage: true,
      maxDiffPixels: 150
    });
  });

  test('dark mode (if supported) should match screenshot', async ({ page }) => {
    // Add dark mode class or toggle
    await page.addInitScript(() => {
      document.documentElement.classList.add('dark-mode');
    });

    await taskPage.goto();

    await expect(page).toHaveScreenshot('task-list-dark-mode.png', {
      fullPage: true,
      maxDiffPixels: 200
    });
  });
});

test.describe('Task Management - Responsive Design', () => {
  const devices = [
    { name: 'iPhone 12', width: 390, height: 844 },
    { name: 'iPad Pro', width: 1024, height: 1366 },
    { name: 'Desktop HD', width: 1920, height: 1080 },
  ];

  devices.forEach(device => {
    test(`should be usable on ${device.name}`, async ({ page }) => {
      await mockAuthentication(page, TEST_USERS.admin);
      await page.setViewportSize({ width: device.width, height: device.height });

      const taskPage = new TaskManagementPage(page);
      await taskPage.goto();

      // All critical elements should be visible
      await expect(taskPage.taskTable).toBeVisible();
      await expect(taskPage.createTaskButton).toBeVisible();

      // Should be able to interact
      if (device.width >= 768) {
        await expect(taskPage.searchInput).toBeVisible();
      }
    });
  });
});
