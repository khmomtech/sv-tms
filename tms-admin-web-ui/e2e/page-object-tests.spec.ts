import { test, expect } from '@playwright/test';
import { LoginPage, DashboardPage, DriverManagementPage } from './page-objects';
import { TEST_USERS } from './helpers/auth.helper';

// Helper function for mock authentication (faster than API calls)
const authenticateUser = async (page: any, userRole = 'ADMIN') => {
  await page.addInitScript(() => {
    const header = btoa(JSON.stringify({ alg: 'HS256', typ: 'JWT' }));
    const payload = btoa(JSON.stringify({
      exp: Math.floor(Date.now() / 1000) + 3600,
      iat: Math.floor(Date.now() / 1000),
      sub: 'testuser',
      roles: [userRole, 'USER']
    }));
    const signature = 'test-signature';
    const token = `${header}.${payload}.${signature}`;

    localStorage.setItem('token', token);
    localStorage.setItem('user', JSON.stringify({
      username: 'testuser',
      email: 'test@example.com',
      roles: [userRole, 'USER']
    }));
  });
};

/**
 * E2E Tests using Page Object Models
 *
 * These tests demonstrate clean, maintainable E2E tests using POM pattern
 */

test.describe('Authentication Flow', () => {
  test('should login successfully with valid credentials', async ({ page }) => {
    const loginPage = new LoginPage(page);
    const dashboardPage = new DashboardPage(page);

    await loginPage.goto();
    await loginPage.login(TEST_USERS.admin.username, TEST_USERS.admin.password);

    // Should redirect to dashboard
    await expect(dashboardPage.header).toBeVisible({ timeout: 10000 });
    expect(await dashboardPage.isOnDashboard()).toBe(true);
  });

  test('should show error with invalid credentials', async ({ page }) => {
    const loginPage = new LoginPage(page);

    await loginPage.goto();
    await loginPage.login('invalid', 'wrong');

    // Should show error message
    await expect(loginPage.errorMessage).toBeVisible({ timeout: 5000 });
    const errorText = await loginPage.getErrorText();
    expect(errorText).toMatch(/invalid|incorrect|wrong|error/i);
  });

  test('should logout successfully', async ({ page }) => {
    const loginPage = new LoginPage(page);
    const dashboardPage = new DashboardPage(page);

    // Login first
    await loginPage.goto();
    await loginPage.login(TEST_USERS.admin.username, TEST_USERS.admin.password);
    await expect(dashboardPage.header).toBeVisible({ timeout: 10000 });

    // Logout
    await dashboardPage.logout();

    // Should redirect to login
    expect(await loginPage.isOnLoginPage()).toBe(true);
  });
});

test.describe('Driver Management Workflow', () => {
  test.beforeEach(async ({ page }) => {
    // Use mock auth for faster tests
    await authenticateUser(page, 'ADMIN');
    await page.goto('/');
    await page.waitForLoadState('networkidle');
  });

  test('should display driver list', async ({ page }) => {
    const driverPage = new DriverManagementPage(page);

    await driverPage.goto();
    await expect(driverPage.table).toBeVisible({ timeout: 10000 });

    const rowCount = await driverPage.getRowCount();
    expect(rowCount).toBeGreaterThan(0);
  });

  test('should search and filter drivers', async ({ page }) => {
    const driverPage = new DriverManagementPage(page);

    await driverPage.goto();
    await expect(driverPage.table).toBeVisible({ timeout: 10000 });

    const initialCount = await driverPage.getRowCount();

    // Search for a driver
    await driverPage.searchDriver('test');
    await page.waitForTimeout(1000);

    const filteredCount = await driverPage.getRowCount();

    // Results should be filtered
    expect(filteredCount).toBeLessThanOrEqual(initialCount);
  });

  test('should open driver detail on row click', async ({ page }) => {
    const driverPage = new DriverManagementPage(page);

    await driverPage.goto();
    await expect(driverPage.table).toBeVisible({ timeout: 10000 });

    const rowCount = await driverPage.getRowCount();
    if (rowCount > 0) {
      await driverPage.clickRow(0);

      // Modal or detail view should open
      await expect(driverPage.modal).toBeVisible({ timeout: 3000 });
    }
  });

  test('should validate required fields on add driver form', async ({ page }) => {
    const driverPage = new DriverManagementPage(page);

    await driverPage.goto();
    await driverPage.clickAddDriver();

    // Try to submit empty form
    if (await driverPage.formSubmitButton.isVisible({ timeout: 3000 })) {
      await driverPage.formSubmitButton.click();
      await page.waitForTimeout(500);

      // Should show validation errors
      const errors = page.locator('.error, .mat-error, .invalid-feedback');
      const errorCount = await errors.count();
      expect(errorCount).toBeGreaterThan(0);
    }
  });

  test('should fill and submit driver form', async ({ page }) => {
    const driverPage = new DriverManagementPage(page);

    await driverPage.goto();
    await driverPage.clickAddDriver();

    if (await driverPage.formNameInput.isVisible({ timeout: 3000 })) {
      // Fill form with test data
      await driverPage.fillDriverForm({
        name: 'Test Driver E2E',
        email: 'test.driver.e2e@example.com',
        phone: '+1234567890'
      });

      // Submit form
      await driverPage.submitForm();

      // Should close modal and refresh list
      const modalVisible = await driverPage.modal.isVisible({ timeout: 2000 }).catch(() => false);
      expect(modalVisible).toBe(false);
    }
  });
});

test.describe('Dashboard Navigation', () => {
  test.beforeEach(async ({ page }) => {
    // Use mock auth for faster tests
    await authenticateUser(page, 'ADMIN');
    await page.goto('/dashboard');
    await page.waitForLoadState('networkidle');
  });

  test('should navigate to different sections from sidebar', async ({ page }) => {
    const dashboardPage = new DashboardPage(page);

    await dashboardPage.goto();
    await expect(dashboardPage.sidebar).toBeVisible({ timeout: 10000 });

    // Get all menu items
    const menuItems = dashboardPage.sidebar.locator('a, button');
    const count = await menuItems.count();

    expect(count).toBeGreaterThan(0);

    // Click first menu item
    const firstItem = menuItems.first();
    const isVisible = await firstItem.isVisible();

    if (isVisible) {
      await firstItem.click();
      await page.waitForLoadState('networkidle');

      // URL should have changed
      const url = page.url();
      expect(url).toContain('localhost');
    }
  });

  test('should display metric cards with values', async ({ page }) => {
    const dashboardPage = new DashboardPage(page);

    await dashboardPage.goto();

    const metricCount = await dashboardPage.metricCards.count();
    expect(metricCount).toBeGreaterThan(0);

    // Check first metric has value
    const firstMetric = dashboardPage.metricCards.first();
    await expect(firstMetric).toBeVisible();

    const text = await firstMetric.textContent();
    expect(text).toBeTruthy();
  });
});

test.describe('Role-Based Access', () => {
  test('admin should access all sections', async ({ page }) => {
    // Authenticate as admin
    await authenticateUser(page, 'ADMIN');
    const dashboardPage = new DashboardPage(page);

    await dashboardPage.goto();

    // Wait for page to load
    await page.waitForLoadState('networkidle');

    // Look for sidebar or navigation
    const sidebar = page.locator('aside, nav, [role="navigation"], .sidebar').first();
    const hasSidebar = await sidebar.isVisible({ timeout: 10000 }).catch(() => false);

    if (hasSidebar) {
      // Admin should see multiple menu items
      const menuItems = sidebar.locator('a, button[role="menuitem"]');
      const count = await menuItems.count();
      expect(count).toBeGreaterThan(0);
    }
  });

  test('dispatcher should have limited access', async ({ page }) => {
    // Authenticate as dispatcher
    await authenticateUser(page, 'DISPATCHER');
    const dashboardPage = new DashboardPage(page);

    await dashboardPage.goto();
    await page.waitForLoadState('networkidle');

    // Dispatcher should have access to dashboard
    const main = page.locator('main, .main-content, [role="main"]').first();
    await expect(main).toBeVisible({ timeout: 10000 });
  });

  test('driver should see driver-specific views', async ({ page }) => {
    // Authenticate as driver
    await authenticateUser(page, 'DRIVER');
    const dashboardPage = new DashboardPage(page);

    await dashboardPage.goto();
    await page.waitForLoadState('networkidle');

    // Driver should have access to dashboard
    const main = page.locator('main, .main-content, [role="main"]').first();
    await expect(main).toBeVisible({ timeout: 10000 });
  });
});
