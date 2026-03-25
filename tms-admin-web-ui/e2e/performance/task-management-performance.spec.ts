import { test, expect } from '@playwright/test';
import { mockAuthentication, TEST_USERS } from '../helpers/auth.helper';
import { TaskManagementPage } from '../page-objects/task-management.page';

/**
 * Task Management - Performance Tests
 * Ensures fast load times and smooth interactions
 */

test.describe('Task Management - Performance', () => {
  test('task list should load within 2 seconds', async ({ page }) => {
    await mockAuthentication(page, TEST_USERS.admin);

    await page.route('**/api/tasks**', async (route) => {
      await route.fulfill({
        status: 200,
        contentType: 'application/json',
        body: JSON.stringify({
          success: true,
          data: { content: [], totalElements: 0 }
        })
      });
    });

    const startTime = Date.now();

    const taskPage = new TaskManagementPage(page);
    await taskPage.goto();
    await expect(taskPage.taskTable).toBeVisible();

    const loadTime = Date.now() - startTime;
    expect(loadTime).toBeLessThan(2000);

    console.log(`Task list loaded in ${loadTime}ms`);
  });

  test('should handle 100 tasks without lag', async ({ page }) => {
    await mockAuthentication(page, TEST_USERS.admin);

    // Generate 100 tasks
    const tasks = Array.from({ length: 100 }, (_, i) => ({
      id: i + 1,
      code: `TASK-2025-${String(i + 1).padStart(4, '0')}`,
      title: `Task ${i + 1}`,
      status: ['OPEN', 'IN_PROGRESS', 'COMPLETED'][i % 3],
      priority: ['LOW', 'MEDIUM', 'HIGH', 'CRITICAL'][i % 4],
      isOverdue: i % 10 === 0
    }));

    await page.route('**/api/tasks**', async (route) => {
      await route.fulfill({
        status: 200,
        contentType: 'application/json',
        body: JSON.stringify({
          success: true,
          data: { content: tasks, totalElements: 100 }
        })
      });
    });

    const taskPage = new TaskManagementPage(page);
    await taskPage.goto();

    // Check rendering time
    const startRender = Date.now();
    await expect(taskPage.taskRows.first()).toBeVisible();
    const renderTime = Date.now() - startRender;

    expect(renderTime).toBeLessThan(1000);
    console.log(`100 tasks rendered in ${renderTime}ms`);

    // Check scroll performance
    await page.evaluate(() => {
      window.scrollTo(0, document.body.scrollHeight);
    });

    // Should still be responsive
    await expect(taskPage.createTaskButton).toBeVisible();
  });

  test('filtering should respond quickly', async ({ page }) => {
    await mockAuthentication(page, TEST_USERS.admin);

    let requestCount = 0;
    await page.route('**/api/tasks**', async (route) => {
      requestCount++;
      await route.fulfill({
        status: 200,
        contentType: 'application/json',
        body: JSON.stringify({
          success: true,
          data: { content: [], totalElements: 0 }
        })
      });
    });

    const taskPage = new TaskManagementPage(page);
    await taskPage.goto();

    requestCount = 0;
    const startTime = Date.now();

    await taskPage.filterByStatus('IN_PROGRESS');

    const filterTime = Date.now() - startTime;
    expect(filterTime).toBeLessThan(500);
    expect(requestCount).toBeGreaterThan(0);

    console.log(`Filter applied in ${filterTime}ms with ${requestCount} requests`);
  });

  test('search should debounce properly', async ({ page }) => {
    await mockAuthentication(page, TEST_USERS.admin);

    let requestCount = 0;
    await page.route('**/api/tasks**', async (route) => {
      if (route.request().url().includes('keyword')) {
        requestCount++;
      }
      await route.fulfill({
        status: 200,
        contentType: 'application/json',
        body: JSON.stringify({
          success: true,
          data: { content: [], totalElements: 0 }
        })
      });
    });

    const taskPage = new TaskManagementPage(page);
    await taskPage.goto();

    // Type quickly
    await taskPage.searchInput.type('brake pads replacement');

    // Wait for debounce
    await page.waitForTimeout(1000);

    // Should only make 1-2 requests, not one per keystroke
    expect(requestCount).toBeLessThan(3);

    console.log(`Search made ${requestCount} requests (good debouncing)`);
  });

  test('modal should open instantly', async ({ page }) => {
    await mockAuthentication(page, TEST_USERS.admin);

    const taskPage = new TaskManagementPage(page);
    await taskPage.goto();

    const startTime = Date.now();
    await taskPage.openCreateModal();
    const modalTime = Date.now() - startTime;

    expect(modalTime).toBeLessThan(300);
    console.log(`Modal opened in ${modalTime}ms`);
  });

  test('should measure Core Web Vitals', async ({ page }) => {
    await mockAuthentication(page, TEST_USERS.admin);

    await page.route('**/api/tasks**', async (route) => {
      await route.fulfill({
        status: 200,
        contentType: 'application/json',
        body: JSON.stringify({
          success: true,
          data: { content: [], totalElements: 0 }
        })
      });
    });

    const taskPage = new TaskManagementPage(page);
    await taskPage.goto();

    // Wait for page to be fully loaded
    await page.waitForLoadState('networkidle');

    // Measure metrics
    const metrics = await page.evaluate(() => {
      const navigation = performance.getEntriesByType('navigation')[0] as PerformanceNavigationTiming;
      return {
        // First Contentful Paint
        fcp: performance.getEntriesByName('first-contentful-paint')[0]?.startTime || 0,
        // DOM Content Loaded
        domContentLoaded: navigation.domContentLoadedEventEnd - navigation.domContentLoadedEventStart,
        // Load Complete
        loadComplete: navigation.loadEventEnd - navigation.loadEventStart,
        // Total Page Load
        totalLoad: navigation.loadEventEnd - navigation.fetchStart
      };
    });

    console.log('Performance Metrics:', metrics);

    // Assertions (adjust thresholds as needed)
    expect(metrics.fcp).toBeLessThan(2000); // FCP < 2s
    expect(metrics.domContentLoaded).toBeLessThan(1500);
    expect(metrics.totalLoad).toBeLessThan(3000);
  });

  test('should not cause memory leaks on repeated navigation', async ({ page }) => {
    await mockAuthentication(page, TEST_USERS.admin);

    await page.route('**/api/tasks**', async (route) => {
      await route.fulfill({
        status: 200,
        contentType: 'application/json',
        body: JSON.stringify({
          success: true,
          data: { content: [], totalElements: 0 }
        })
      });
    });

    const taskPage = new TaskManagementPage(page);

    // Navigate 10 times
    for (let i = 0; i < 10; i++) {
      await taskPage.goto();
      await page.waitForTimeout(100);
      await page.goto('/dashboard');
      await page.waitForTimeout(100);
    }

    // Check memory usage (basic check)
    const memoryInfo = await page.evaluate(() => {
      return (performance as any).memory;
    });

    if (memoryInfo) {
      console.log('Memory usage:', {
        used: Math.round(memoryInfo.usedJSHeapSize / 1048576) + 'MB',
        total: Math.round(memoryInfo.totalJSHeapSize / 1048576) + 'MB'
      });

      // Should not use excessive memory
      expect(memoryInfo.usedJSHeapSize / memoryInfo.jsHeapSizeLimit).toBeLessThan(0.9);
    }
  });
});
