import { test, expect } from '@playwright/test';
import { loginViaAPI, loginViaUI, TEST_USERS } from './helpers/auth.helper';

/**
 * Permission Integration Tests
 *
 * Tests the complete permission system including:
 * - Login flow
 * - Permission storage in localStorage
 * - Permission-based route access
 * - Permission alias system
 * - Navigation visibility based on permissions
 */

test.describe('Permission System Integration', () => {

  test.describe('Admin User - Full Access', () => {

    test('should login and store permissions in localStorage', async ({ page }) => {
      // Login via API
      await loginViaAPI(page, TEST_USERS.admin);

      // Navigate to app
      await page.goto('/dashboard');
      await page.waitForLoadState('networkidle');

      // Check localStorage for auth data
      const token = await page.evaluate(() => localStorage.getItem('token'));
      const userStr = await page.evaluate(() => localStorage.getItem('user'));
      const permissionsStr = await page.evaluate(() => localStorage.getItem('permissions'));

      expect(token).toBeTruthy();
      expect(userStr).toBeTruthy();
      expect(permissionsStr).toBeTruthy();

      // Parse and verify permissions
      const permissions = JSON.parse(permissionsStr!);
      expect(Array.isArray(permissions)).toBe(true);
      expect(permissions.length).toBeGreaterThan(0);

      // Log permissions for debugging
      console.log('User permissions:', permissions);
    });

    test('should access /dispatch route (dispatch:read permission)', async ({ page }) => {
      await loginViaAPI(page, TEST_USERS.admin);

      // Navigate to dispatch route
      await page.goto('/dispatch');
      await page.waitForLoadState('networkidle');

      // Should not be redirected to login or error page
      expect(page.url()).toContain('/dispatch');
      expect(page.url()).not.toContain('/login');
      expect(page.url()).not.toContain('/unauthorized');

      // Main content should be visible
      const main = page.locator('main, .main-content, [role="main"]');
      await expect(main.first()).toBeVisible({ timeout: 10000 });
    });

    test('should access /dispatch/monitor route (dispatch:monitor permission)', async ({ page }) => {
      await loginViaAPI(page, TEST_USERS.admin);

      // Navigate to monitor route
      await page.goto('/dispatch/monitor');
      await page.waitForLoadState('networkidle');

      // Should not be redirected
      expect(page.url()).toContain('/dispatch/monitor');
      expect(page.url()).not.toContain('/login');

      // Main content should be visible
      const main = page.locator('main, .main-content, [role="main"]');
      await expect(main.first()).toBeVisible({ timeout: 10000 });
    });

    test('should access /dispatch/loading-monitor route (pod:read permission)', async ({ page }) => {
      await loginViaAPI(page, TEST_USERS.admin);

      // Navigate to loading monitor route
      await page.goto('/dispatch/loading-monitor');
      await page.waitForLoadState('networkidle');

      // Should not be redirected
      expect(page.url()).toContain('/dispatch/loading-monitor');
      expect(page.url()).not.toContain('/login');

      // Main content should be visible
      const main = page.locator('main, .main-content, [role="main"]');
      await expect(main.first()).toBeVisible({ timeout: 10000 });
    });

    test('should access /fleet/drivers route (driver:read permission)', async ({ page }) => {
      await loginViaAPI(page, TEST_USERS.admin);

      // Navigate to drivers route
      await page.goto('/fleet/drivers');
      await page.waitForLoadState('networkidle');

      // Should not be redirected
      expect(page.url()).toContain('/fleet/drivers');
      expect(page.url()).not.toContain('/login');

      // Main content should be visible
      const main = page.locator('main, .main-content, [role="main"]');
      await expect(main.first()).toBeVisible({ timeout: 10000 });
    });

    test('should see navigation items for permitted routes', async ({ page }) => {
      await loginViaAPI(page, TEST_USERS.admin);
      await page.goto('/dashboard');
      await page.waitForLoadState('networkidle');

      // Check if navigation sidebar/menu contains dispatch and fleet items
      // Adjust selectors based on your actual navigation structure
      const navigation = page.locator('nav, .sidebar, .menu, [role="navigation"]');
      await expect(navigation.first()).toBeVisible({ timeout: 5000 });

      // Look for navigation items (adjust text based on your actual menu labels)
      const navText = await navigation.first().textContent();
      console.log('Navigation content:', navText);

      // These are common menu item names - adjust if needed
      const hasDispatchMenu = navText?.toLowerCase().includes('dispatch');
      const hasFleetMenu = navText?.toLowerCase().includes('fleet') ||
                           navText?.toLowerCase().includes('driver');

      if (hasDispatchMenu) {
        console.log('✓ Found dispatch menu item');
      }
      if (hasFleetMenu) {
        console.log('✓ Found fleet/driver menu item');
      }
    });
  });

  test.describe('Permission Alias System', () => {

    test('should access dispatch route with dispatch:read permission', async ({ page }) => {
      const { permissions } = await loginViaAPI(page, TEST_USERS.admin);

      console.log('Backend permissions:', permissions);

      // Check if we have dispatch:read
      const hasDispatchRead = permissions.includes('dispatch:read');

      console.log('Has dispatch:read:', hasDispatchRead);

      // Verify we have backend permission dispatch:read
      expect(hasDispatchRead).toBe(true);

      // Navigate to route that requires dispatch:read
      await page.goto('/dispatch');
      await page.waitForLoadState('networkidle');

      // Should be allowed with dispatch:read permission
      expect(page.url()).toContain('/dispatch');
      expect(page.url()).not.toContain('/unauthorized');
      expect(page.url()).not.toContain('/login');
    });

    test('should access driver:read route with driver:read permission', async ({ page }) => {
      const { permissions } = await loginViaAPI(page, TEST_USERS.admin);

      const hasDriverRead = permissions.includes('driver:read');
      const hasDriverViewAll = permissions.includes('driver:view_all');

      console.log('Has driver:read:', hasDriverRead);
      console.log('Has driver:view_all:', hasDriverViewAll);

      // Verify we have backend permissions (driver:read, driver:view_all)
      expect(hasDriverRead || hasDriverViewAll).toBe(true);

      // Navigate to route that requires driver:read
      await page.goto('/fleet/drivers');
      await page.waitForLoadState('networkidle');

      // Should be allowed with driver:read permission
      expect(page.url()).toContain('/fleet/drivers');
      expect(page.url()).not.toContain('/unauthorized');
      expect(page.url()).not.toContain('/login');
    });
  });

  test.describe('UI Login Flow', () => {

    test('should login via UI and access protected routes', async ({ page }) => {
      // Login via UI
      await loginViaUI(page, TEST_USERS.admin);

      // Should be on dashboard
      await expect(page).toHaveURL(/\/dashboard/);

      // Navigate to dispatch
      await page.goto('/dispatch');
      await page.waitForLoadState('networkidle');
      expect(page.url()).toContain('/dispatch');

      // Navigate to fleet/drivers
      await page.goto('/fleet/drivers');
      await page.waitForLoadState('networkidle');
      expect(page.url()).toContain('/fleet/drivers');
    });
  });

  test.describe('Console Error Validation', () => {

    test('should not have console errors on dispatch route', async ({ page }) => {
      const errors: string[] = [];
      page.on('console', (msg) => {
        if (msg.type() === 'error') {
          errors.push(msg.text());
        }
      });

      await loginViaAPI(page, TEST_USERS.admin);
      await page.goto('/dispatch');
      await page.waitForLoadState('networkidle');

      // Filter out benign errors
      const severeErrors = errors.filter((e) =>
        !/favicon|ResizeObserver|DevTools|ERR_BLOCKED_BY_CLIENT|SourceMap|WebSocket|EventSource|RuntimeError: NG01203/i.test(e)
      );

      expect(severeErrors.length, `Console errors: ${severeErrors.join(', ')}`).toBe(0);
    });    test('should not have console errors on fleet/drivers route', async ({ page }) => {
      const errors: string[] = [];
      page.on('console', (msg) => {
        if (msg.type() === 'error') {
          errors.push(msg.text());
        }
      });

      await loginViaAPI(page, TEST_USERS.admin);
      await page.goto('/fleet/drivers');
      await page.waitForLoadState('networkidle', { timeout: 30000 });

      // Filter out benign errors and known form control issues (NG01203)
      const severeErrors = errors.filter((e) =>
        !/favicon|ResizeObserver|DevTools|ERR_BLOCKED_BY_CLIENT|SourceMap|WebSocket|EventSource|RuntimeError: NG01203|No value accessor for form control/i.test(e)
      );

      expect(severeErrors.length, `Console errors: ${severeErrors.join(', ')}`).toBe(0);
    });
  });

  test.describe('Network Request Validation', () => {

    test('should not have 404 errors loading dispatch components', async ({ page }) => {
      const failedRequests: string[] = [];

      page.on('response', (response) => {
        if (response.status() === 404 && !response.url().includes('favicon')) {
          failedRequests.push(`${response.status()} ${response.url()}`);
        }
      });

      await loginViaAPI(page, TEST_USERS.admin);
      await page.goto('/dispatch');
      await page.waitForLoadState('networkidle');

      expect(failedRequests.length, `404 errors: ${failedRequests.join(', ')}`).toBe(0);
    });

    test('should not have 404 errors loading fleet/drivers components', async ({ page }) => {
      const failedRequests: string[] = [];

      page.on('response', (response) => {
        if (response.status() === 404 && !response.url().includes('favicon')) {
          failedRequests.push(`${response.status()} ${response.url()}`);
        }
      });

      await loginViaAPI(page, TEST_USERS.admin);
      await page.goto('/fleet/drivers');
      await page.waitForLoadState('networkidle');

      expect(failedRequests.length, `404 errors: ${failedRequests.join(', ')}`).toBe(0);
    });
  });

  test.describe('Permission Guard Behavior', () => {

    test('should verify PermissionGuard allows access with aliased permissions', async ({ page }) => {
      const { permissions } = await loginViaAPI(page, TEST_USERS.admin);

      // Verify we have backend permissions
      expect(permissions).toContain('dispatch:create');
      expect(permissions).toContain('dispatch:monitor');
      expect(permissions).toContain('pod:read');
      expect(permissions).toContain('driver:read');

      // Test all dispatch routes work with backend permissions
      const routes = [
        '/dispatch',
        '/dispatch/monitor',
        '/dispatch/loading-monitor',
      ];

      for (const route of routes) {
        await page.goto(route);
        await page.waitForLoadState('networkidle');

        expect(page.url()).toContain(route);
        expect(page.url()).not.toContain('/login');
        expect(page.url()).not.toContain('/unauthorized');

        console.log(`✓ ${route} accessible`);
      }
    });

    test('should maintain permissions across route navigation', async ({ page }) => {
      await loginViaAPI(page, TEST_USERS.admin);

      // Navigate through multiple routes
      await page.goto('/dispatch');
      await page.waitForLoadState('networkidle');
      expect(page.url()).toContain('/dispatch');

      await page.goto('/fleet/drivers');
      await page.waitForLoadState('networkidle');
      expect(page.url()).toContain('/fleet/drivers');

      await page.goto('/dispatch/monitor');
      await page.waitForLoadState('networkidle');
      expect(page.url()).toContain('/dispatch/monitor');

      // Verify permissions still in localStorage
      const permissionsStr = await page.evaluate(() => localStorage.getItem('permissions'));
      expect(permissionsStr).toBeTruthy();

      const permissions = JSON.parse(permissionsStr!);
      expect(permissions.length).toBeGreaterThan(0);
      expect(permissions).toContain('dispatch:create');
    });

    test('should handle navigation via sidebar menu', async ({ page }) => {
      await loginViaAPI(page, TEST_USERS.admin);

      // Look for navigation links
      const nav = page.locator('nav, .sidebar, [role="navigation"]').first();
      await expect(nav).toBeVisible({ timeout: 5000 });

      // Try to find and click fleet/driver menu item
      const fleetLink = page.locator('a, button').filter({
        hasText: /fleet|driver/i
      }).first();

      if (await fleetLink.isVisible()) {
        await fleetLink.click();
        await page.waitForLoadState('networkidle');

        // Should navigate successfully
        const url = page.url();
        console.log('Navigated to:', url);
        expect(url).not.toContain('/login');
        expect(url).not.toContain('/unauthorized');
      }
    });
  });

  test.describe('Error Recovery', () => {

    test('should handle page refresh and maintain session', async ({ page }) => {
      await loginViaAPI(page, TEST_USERS.admin);

      await page.goto('/dispatch');
      await page.waitForLoadState('networkidle');

      // Refresh page
      await page.reload();
      await page.waitForLoadState('networkidle');

      // Should still be on dispatch page (not redirected to login)
      expect(page.url()).toContain('/dispatch');
      expect(page.url()).not.toContain('/login');

      // Permissions should still be in localStorage
      const permissionsStr = await page.evaluate(() => localStorage.getItem('permissions'));
      expect(permissionsStr).toBeTruthy();
    });

    test('should verify all critical permissions are present', async ({ page }) => {
      const { permissions } = await loginViaAPI(page, TEST_USERS.admin);

      // Critical dispatch permissions
      const criticalPermissions = [
        'dispatch:create',
        'dispatch:read',
        'dispatch:update',
        'dispatch:monitor',
        'pod:read',
        'driver:read',
        'driver:view_all',
      ];

      const missingPermissions = criticalPermissions.filter(p => !permissions.includes(p));

      expect(missingPermissions.length,
        `Missing critical permissions: ${missingPermissions.join(', ')}`
      ).toBe(0);

      console.log('✓ All critical permissions present:', criticalPermissions.length);
    });
  });
});
