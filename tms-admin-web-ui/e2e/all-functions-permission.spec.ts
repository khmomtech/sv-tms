import { test, expect } from '@playwright/test';

/**
 * E2E Test Suite: ALL_FUNCTIONS Permission Verification
 *
 * This suite verifies that users with the 'all_functions' permission
 * (typically SUPERADMIN) can access all features in the application.
 *
 * Test Coverage:
 * - Login and authentication
 * - Navigation to all major sections
 * - CRUD operations in each module
 * - Permission-gated features
 */

test.describe('ALL_FUNCTIONS Permission - Full System Access', () => {
  const SUPERADMIN_USERNAME = 'superadmin';
  const SUPERADMIN_PASSWORD = 'superadmin'; // Update with actual password
  const BASE_URL = process.env['BASE_URL'] || 'http://localhost:4200';

  test.beforeEach(async ({ page }) => {
    // Login as SUPERADMIN before each test
    await page.goto(`${BASE_URL}/login`);
    await page.fill('input[name="username"]', SUPERADMIN_USERNAME);
    await page.fill('input[name="password"]', SUPERADMIN_PASSWORD);
    await page.click('button[type="submit"]');

    // Wait for successful login (redirect to dashboard)
    await page.waitForURL(/dashboard|home/);

    // Verify user has SUPERADMIN role and all_functions
    const localStorageData = await page.evaluate(() => {
      const user = JSON.parse(window.localStorage.getItem('user') || '{}');
      const permissions = JSON.parse(window.localStorage.getItem('permissions') || '[]');
      return { user, permissions };
    });

    expect(localStorageData.user.roles).toContain('SUPERADMIN');
    expect(localStorageData.permissions).toContain('all_functions');
  });

  // ==================== NAVIGATION TESTS ====================

  test('SUPERADMIN can navigate to Dashboard', async ({ page }) => {
    await page.goto(`${BASE_URL}/dashboard`);
    await expect(page).toHaveURL(/dashboard/);
    await expect(page.locator('h1, h2')).toContainText(/dashboard/i);
  });

  test('SUPERADMIN can navigate to Fleet Management', async ({ page }) => {
    await page.goto(`${BASE_URL}/fleet`);
    await expect(page).toHaveURL(/fleet/);
    // Should not see "Permission Denied" or redirect
    await expect(page.locator('body')).not.toContainText(/permission denied|unauthorized/i);
  });

  test('SUPERADMIN can navigate to Driver Management', async ({ page }) => {
    await page.goto(`${BASE_URL}/fleet/drivers`);
    await expect(page).toHaveURL(/fleet\/drivers/);
    await expect(page.locator('body')).not.toContainText(/permission denied/i);
  });

  test('SUPERADMIN can navigate to Driver Devices', async ({ page }) => {
    await page.goto(`${BASE_URL}/fleet/drivers/devices`);
    await expect(page).toHaveURL(/fleet\/drivers\/devices/);

    // Should see device list (not permission error)
    await page.waitForTimeout(2000); // Wait for API call
    const errorText = await page.locator('body').textContent();
    expect(errorText).not.toMatch(/permission denied|403|unauthorized/i);
  });

  test('SUPERADMIN can navigate to Vehicle Management', async ({ page }) => {
    await page.goto(`${BASE_URL}/fleet/vehicles`);
    await expect(page).toHaveURL(/fleet\/vehicles/);
    await expect(page.locator('body')).not.toContainText(/permission denied/i);
  });

  test('SUPERADMIN can navigate to Dispatch', async ({ page }) => {
    await page.goto(`${BASE_URL}/dispatch`);
    await expect(page).toHaveURL(/dispatch/);
    await expect(page.locator('body')).not.toContainText(/permission denied/i);
  });

  test('SUPERADMIN can navigate to Orders', async ({ page }) => {
    await page.goto(`${BASE_URL}/orders`);
    await expect(page).toHaveURL(/orders/);
    await expect(page.locator('body')).not.toContainText(/permission denied/i);
  });

  test('SUPERADMIN can navigate to Settings', async ({ page }) => {
    await page.goto(`${BASE_URL}/settings`);
    await expect(page).toHaveURL(/settings/);
    await expect(page.locator('body')).not.toContainText(/permission denied/i);
  });

  test('SUPERADMIN can navigate to Admin Section', async ({ page }) => {
    await page.goto(`${BASE_URL}/admin`);
    await expect(page).toHaveURL(/admin/);
    await expect(page.locator('body')).not.toContainText(/permission denied/i);
  });

  test('SUPERADMIN can navigate to User Management', async ({ page }) => {
    await page.goto(`${BASE_URL}/admin/users`);
    await expect(page).toHaveURL(/admin\/users/);
    await expect(page.locator('body')).not.toContainText(/permission denied/i);
  });

  test('SUPERADMIN can navigate to Role Management', async ({ page }) => {
    await page.goto(`${BASE_URL}/admin/roles`);
    await expect(page).toHaveURL(/admin\/roles/);
    await expect(page.locator('body')).not.toContainText(/permission denied/i);
  });

  // ==================== API RESPONSE TESTS ====================

  test('SUPERADMIN receives 200 OK for Device API', async ({ page }) => {
    const response = await page.request.get(`${BASE_URL}/api/driver/device/all`, {
      headers: {
        'Authorization': `Bearer ${await getToken(page)}`
      }
    });

    expect(response.status()).toBe(200);
    const body = await response.json();
    expect(body.success).toBe(true);
  });

  test('SUPERADMIN receives 200 OK for Driver API', async ({ page }) => {
    const response = await page.request.get(`${BASE_URL}/api/drivers`, {
      headers: {
        'Authorization': `Bearer ${await getToken(page)}`
      }
    });

    expect(response.status()).toBe(200);
  });

  test('SUPERADMIN receives 200 OK for Vehicle API', async ({ page }) => {
    const response = await page.request.get(`${BASE_URL}/api/vehicles`, {
      headers: {
        'Authorization': `Bearer ${await getToken(page)}`
      }
    });

    expect(response.status()).toBe(200);
  });

  test('SUPERADMIN receives 200 OK for Dispatch API', async ({ page }) => {
    const response = await page.request.get(`${BASE_URL}/api/admin/dispatches`, {
      headers: {
        'Authorization': `Bearer ${await getToken(page)}`
      }
    });

    expect(response.status()).toBe(200);
  });

  test('SUPERADMIN receives 200 OK for User API', async ({ page }) => {
    const response = await page.request.get(`${BASE_URL}/api/users`, {
      headers: {
        'Authorization': `Bearer ${await getToken(page)}`
      }
    });

    expect(response.status()).toBe(200);
  });

  test('SUPERADMIN receives 200 OK for Role API', async ({ page }) => {
    const response = await page.request.get(`${BASE_URL}/api/roles`, {
      headers: {
        'Authorization': `Bearer ${await getToken(page)}`
      }
    });

    expect(response.status()).toBe(200);
  });

  test('SUPERADMIN receives 200 OK for Permission API', async ({ page }) => {
    const response = await page.request.get(`${BASE_URL}/api/permissions`, {
      headers: {
        'Authorization': `Bearer ${await getToken(page)}`
      }
    });

    expect(response.status()).toBe(200);
  });

  // ==================== UI ELEMENT VISIBILITY TESTS ====================

  test('SUPERADMIN sees all menu items in sidebar', async ({ page }) => {
    await page.goto(`${BASE_URL}/dashboard`);

    // Check that key menu items are visible
    const menuItems = [
      'Dashboard',
      'Fleet',
      'Drivers',
      'Vehicles',
      'Dispatch',
      'Orders',
      'Admin',
      'Settings'
    ];

    for (const menuItem of menuItems) {
      const menuLocator = page.locator(`nav, aside, [role="navigation"]`).locator(`text=${menuItem}`);
      await expect(menuLocator.first()).toBeVisible({ timeout: 5000 });
    }
  });

  test('SUPERADMIN sees Create buttons in Driver Management', async ({ page }) => {
    await page.goto(`${BASE_URL}/fleet/drivers`);
    await page.waitForTimeout(1000);

    // Should see "Add Driver" or "Create Driver" button
    const createButton = page.locator('button:has-text("Add Driver"), button:has-text("Create Driver"), button:has-text("New Driver")');
    await expect(createButton.first()).toBeVisible({ timeout: 5000 });
  });

  test('SUPERADMIN sees Edit/Delete actions in tables', async ({ page }) => {
    await page.goto(`${BASE_URL}/fleet/drivers`);
    await page.waitForTimeout(2000);

    // Look for action buttons (edit, delete, view)
    const actionButtons = page.locator('button:has-text("Edit"), button:has-text("Delete"), button:has-text("View"), svg[data-icon="edit"], svg[data-icon="trash"]');

    // If there are any rows, action buttons should be visible
    const tableRows = await page.locator('table tbody tr').count();
    if (tableRows > 0) {
      await expect(actionButtons.first()).toBeVisible({ timeout: 5000 });
    }
  });

  // ==================== PERMISSION GUARD TESTS ====================

  test('SUPERADMIN bypasses all permission guards', async ({ page }) => {
    // Test multiple permission-restricted routes
    const restrictedRoutes = [
      '/fleet/drivers/devices',
      '/fleet/drivers/documents',
      '/fleet/vehicles',
      '/dispatch',
      '/orders',
      '/admin/users',
      '/admin/roles',
      '/settings'
    ];

    for (const route of restrictedRoutes) {
      await page.goto(`${BASE_URL}${route}`);
      await page.waitForTimeout(1500);

      // Should not redirect to /unauthorized
      expect(page.url()).not.toContain('/unauthorized');
      expect(page.url()).not.toContain('/login');

      // Should not show permission denied message
      const bodyText = await page.locator('body').textContent();
      expect(bodyText).not.toMatch(/permission denied|access denied|unauthorized/i);

      console.log(`SUPERADMIN has access to ${route}`);
    }
  });

  // ==================== CRUD OPERATION TESTS ====================

  test('SUPERADMIN can view device list', async ({ page }) => {
    await page.goto(`${BASE_URL}/fleet/drivers/devices`);
    await page.waitForTimeout(2000);

    // Should see table or "no devices" message (not error)
    const content = await page.locator('body').textContent();
    expect(content).not.toMatch(/403|forbidden|permission denied/i);
  });

  test('SUPERADMIN can filter devices', async ({ page }) => {
    await page.goto(`${BASE_URL}/fleet/drivers/devices`);
    await page.waitForTimeout(2000);

    // Try to interact with filter controls if they exist
    const filterInput = page.locator('input[placeholder*="Search"], input[placeholder*="Filter"]').first();
    if (await filterInput.isVisible({ timeout: 2000 })) {
      await filterInput.fill('test');
      await page.waitForTimeout(1000);
      // Should not get permission error
      const bodyText = await page.locator('body').textContent();
      expect(bodyText).not.toMatch(/403|forbidden/i);
    }
  });

  // ==================== COMPREHENSIVE ACCESS MATRIX ====================

  test('SUPERADMIN has access to all feature categories', async ({ page }) => {
    const featureCategories = [
      { name: 'Dashboard', url: '/dashboard' },
      { name: 'Fleet Drivers', url: '/fleet/drivers' },
      { name: 'Fleet Vehicles', url: '/fleet/vehicles' },
      { name: 'Driver Devices', url: '/fleet/drivers/devices' },
      { name: 'Dispatch', url: '/dispatch' },
      { name: 'Orders', url: '/orders' },
      { name: 'Admin Users', url: '/admin/users' },
      { name: 'Admin Roles', url: '/admin/roles' },
      { name: 'Settings', url: '/settings' }
    ];

    const results: { category: string; accessible: boolean }[] = [];

    for (const feature of featureCategories) {
      await page.goto(`${BASE_URL}${feature.url}`);
      await page.waitForTimeout(1500);

      const accessible = !page.url().includes('/unauthorized') &&
                        !page.url().includes('/login');

      results.push({ category: feature.name, accessible });

      if (accessible) {
        console.log(`${feature.name}: ACCESSIBLE`);
      } else {
        console.log(`❌ ${feature.name}: NOT ACCESSIBLE`);
      }
    }

    // All features should be accessible
    const allAccessible = results.every(r => r.accessible);
    expect(allAccessible).toBe(true);
  });

  // ==================== REGRESSION TESTS ====================

  test('SUPERADMIN does not get 403 errors on any protected endpoint', async ({ page }) => {
    // Monitor network for 403 responses
    const forbidden403: string[] = [];

    page.on('response', response => {
      if (response.status() === 403) {
        forbidden403.push(response.url());
      }
    });

    // Navigate through key pages
    const pages = [
      '/dashboard',
      '/fleet/drivers',
      '/fleet/drivers/devices',
      '/fleet/vehicles',
      '/dispatch',
      '/orders'
    ];

    for (const route of pages) {
      await page.goto(`${BASE_URL}${route}`);
      await page.waitForTimeout(2000);
    }

    // Should have zero 403 errors
    expect(forbidden403.length).toBe(0);
    if (forbidden403.length > 0) {
      console.error('❌ 403 Forbidden URLs:', forbidden403);
    }
  });
});

// ==================== HELPER FUNCTIONS ====================

async function getToken(page: any): Promise<string> {
  return await page.evaluate(() => window.localStorage.getItem('token') || '');
}
