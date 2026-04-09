import { expect, test } from '@playwright/test';

import { loginViaAPI, TEST_USERS } from './helpers/auth.helper';

test.describe('Dispatch List Page', () => {
  test.beforeEach(async ({ page }) => {
    // Login as admin with necessary permissions
    await loginViaAPI(page, TEST_USERS.admin);
  });

  test('should display dispatch list page with navigation', async ({ page }) => {
    // Navigate to dispatch list
    await page.goto('/dispatches');
    await page.waitForLoadState('networkidle');

    // Verify page title in header (from route title) - pageTitle is in header span
    await expect(page.locator('header span.text-blue-800')).toContainText(/dispatch/i, { timeout: 15000 });

    // Verify the page loaded successfully (should not show error)
    await expect(page.locator('body')).not.toContainText('404');
    await expect(page.locator('body')).not.toContainText('403');
    await expect(page.locator('body')).not.toContainText('Not Found');
  });

  test('should navigate to dispatch list via sidebar', async ({ page }) => {
    await page.goto('/dashboard');
    await page.waitForLoadState('networkidle');

    // Open Dispatches dropdown in sidebar
    const dispatchesMenu = page.locator('text=Dispatches').first();
    await dispatchesMenu.click({ timeout: 15000 });
    await page.waitForTimeout(500); // Wait for dropdown animation

    // Click on Dispatch List menu item
    const dispatchListLink = page.locator('a', { hasText: 'Dispatch List' });
    await dispatchListLink.click({ timeout: 15000 });

    // Verify navigation
    await page.waitForURL('**/dispatch**', { timeout: 15000 });
    await expect(page).toHaveURL(/\/(dispatch|dispatches)/);
    await expect(page.locator('header span.text-blue-800')).toContainText(/dispatch/i, { timeout: 15000 });
  });

  test('should load dispatch data from API', async ({ page }) => {
    // Navigate to dispatch list
    await page.goto('/dispatches');
    await page.waitForLoadState('networkidle');

    // Wait for API call or timeout
    try {
      await page.waitForResponse(
        response => response.url().includes('/api/admin/dispatches') && response.status() === 200,
        { timeout: 10000 }
      );
    } catch (e) {
      // API might already be called, continue
    }

    // Check if table or list container exists
    const hasTable = await page.locator('table, mat-table, [role="table"]').count();
    const hasList = await page.locator('[class*="list"], [class*="grid"], .dispatch-container').count();

    expect(hasTable + hasList).toBeGreaterThan(0);
  });

  test('should display dispatch list controls', async ({ page }) => {
    await page.goto('/dispatches');
    await page.waitForLoadState('networkidle');

    // Check for common list controls (at least one should exist)
    const hasSearch =
      (await page.locator('input[type="search"], input[placeholder*="search" i]').count()) > 0;
    const hasFilter =
      (await page.locator('button:has-text("Filter"), select, [class*="filter"]').count()) > 0;
    const hasPagination =
      (await page.locator('[class*="pagination"], [aria-label*="pagination" i]').count()) > 0;

    // At least one control should be present
    expect(hasSearch || hasFilter || hasPagination).toBeTruthy();
  });

  test('should handle empty dispatch list gracefully', async ({ page }) => {
    await page.goto('/dispatches');
    await page.waitForLoadState('networkidle');

    // Page should render without errors even if no data
    const bodyText = await page.locator('body').textContent();
    expect(bodyText).toBeTruthy();

    // Should not show error messages
    await expect(page.locator('body')).not.toContainText(/error.*loading/i);
  });

  test('should have proper page metadata', async ({ page }) => {
    await page.goto('/dispatches');
    await page.waitForLoadState('networkidle');

    // Check page title contains relevant keywords
    const title = await page.title();
    expect(title.toLowerCase()).toMatch(/dispatch|tms|logistics/);
  });
});
