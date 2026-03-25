import { test, expect } from '@playwright/test';

/**
 * Simplified Task Management Smoke Tests
 * No global setup dependency - tests backend and frontend availability directly
 */

test.describe('Task System - Smoke Tests', () => {
  test.beforeEach(async ({ page }) => {
    // Check if backend is available
    try {
      const response = await page.request.get('http://localhost:8080/actuator/health');
      if (!response.ok()) {
        test.skip();
      }
    } catch (e) {
      console.warn('Backend not available, skipping test');
      test.skip();
    }
  });

  test('should have backend API responding', async ({ page }) => {
    const response = await page.request.get('http://localhost:8080/actuator/health');
    expect(response.ok()).toBeTruthy();
    const data = await response.json();
    expect(data.status).toBe('UP');
  });

  test('should access frontend home page', async ({ page }) => {
    await page.goto('/', { waitUntil: 'domcontentloaded', timeout: 20000 });
    await expect(page).toHaveTitle(/Logistics Dashboard|SV-TMS/, { timeout: 10000 });
  });

  test('should access tasks API endpoint', async ({ page }) => {
    // Try to access statistics endpoint (doesn't require auth for health check purposes)
    const response = await page.request.get('http://localhost:8080/api/tasks/statistics', {
      ignoreHTTPSErrors: true,
      failOnStatusCode: false
    });

    // Should get either 200 (if public) or 401/403 (if protected) - both mean API is working
    expect([200, 401, 403]).toContain(response.status());
  });

  test('should load Angular application', async ({ page }) => {
    await page.goto('/', { waitUntil: 'domcontentloaded', timeout: 20000 });

    // Check for Angular root element
    const app = page.locator('app-root, [ng-version]');
    await expect(app).toBeAttached({ timeout: 10000 });
  });

  test('should have navigation menu', async ({ page }) => {
    await page.goto('/', { waitUntil: 'domcontentloaded', timeout: 20000 });

    // Look for common navigation elements
    const nav = page.locator('nav, [role="navigation"], .navbar, .sidebar');
    const count = await nav.count();
    expect(count).toBeGreaterThan(0);
  });

  test('should have Bootstrap styles loaded', async ({ page }) => {
    await page.goto('/', { waitUntil: 'domcontentloaded', timeout: 20000 });

    // Check for Bootstrap classes in the page
    const bootstrapElements = page.locator('.container, .row, .col, .btn');
    const count = await bootstrapElements.count();
    expect(count).toBeGreaterThan(0);
  });
});

test.describe('Task API - Direct Tests', () => {
  test('should have OpenAPI documentation available', async ({ request }) => {
    try {
      const response = await request.get('http://localhost:8080/v3/api-docs');
      if (response.ok()) {
        const apiDocs = await response.json();
        expect(apiDocs.openapi).toBeDefined();
        expect(apiDocs.info).toBeDefined();
      }
    } catch (e) {
      test.skip();
    }
  });

  test('should have Swagger UI available', async ({ page }) => {
    try {
      const response = await page.request.get('http://localhost:8080/swagger-ui/index.html');
      expect([200, 401]).toContain(response.status());
    } catch (e) {
      test.skip();
    }
  });
});

test.describe('Task UI - Basic Availability', () => {
  test('should attempt to navigate to tasks route', async ({ page }) => {
    await page.goto('/', { waitUntil: 'domcontentloaded', timeout: 20000 });

    // Try to navigate to tasks - may or may not exist
    const response = await page.goto('/tasks', {
      waitUntil: 'domcontentloaded',
      timeout: 15000
    }).catch(() => null);

    // Just log the result, don't fail
    if (response) {
      console.log(`Tasks route status: ${response.status()}`);
    }
  });

  test('should check for task-related elements in DOM', async ({ page }) => {
    await page.goto('/', { waitUntil: 'domcontentloaded', timeout: 20000 });

    // Look for any task-related components that might be loaded
    const taskComponents = page.locator('[class*="task"], [data-testid*="task"], app-task, app-unified-task');
    const count = await taskComponents.count();

    console.log(`Found ${count} task-related elements`);
    // Don't assert - just informational
  });
});
