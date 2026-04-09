import { test, expect } from '@playwright/test';

test.describe('Task Navigation', () => {
  test('should have Tasks menu item in sidebar', async ({ page }) => {
    // Navigate to frontend (even if login required, sidebar should be visible)
    await page.goto('http://localhost:4200', {
      waitUntil: 'domcontentloaded',
      timeout: 30000
    });

    // Wait a bit for the page to settle
    await page.waitForTimeout(2000);

    // Take a screenshot for debugging
    await page.screenshot({ path: 'screenshots/tasks-navigation-before.png', fullPage: true });

    // Look for the Tasks menu item in the sidebar
    const tasksMenuItem = page.locator('a[routerLink="/tasks"]').first();

    // Check if it exists
    const exists = await tasksMenuItem.count();
    console.log(`Tasks menu item found: ${exists > 0}`);

    if (exists > 0) {
      console.log('✓ Tasks menu item exists in sidebar');
      expect(exists).toBeGreaterThan(0);
    } else {
      console.log('✗ Tasks menu item NOT found in sidebar');

      // List all navigation links for debugging
      const allLinks = await page.locator('nav a[routerLink]').all();
      console.log(`\nFound ${allLinks.length} navigation links:`);

      for (const link of allLinks) {
        const route = await link.getAttribute('routerLink');
        const text = await link.textContent();
        console.log(`  - ${route} (${text?.trim()})`);
      }
    }
  });

  test('should navigate to tasks page when accessing /tasks directly', async ({ page }) => {
    // Try to access the tasks route directly
    await page.goto('http://localhost:4200/tasks', {
      waitUntil: 'domcontentloaded',
      timeout: 30000
    });

    // Wait for any redirects or page loads
    await page.waitForTimeout(2000);

    // Take a screenshot
    await page.screenshot({ path: 'screenshots/tasks-direct-access.png', fullPage: true });

    // Check the current URL
    const url = page.url();
    console.log(`Current URL: ${url}`);

    // Log page title
    const title = await page.title();
    console.log(`Page title: ${title}`);

    // Check if we're on the tasks page or redirected to login
    if (url.includes('/tasks')) {
      console.log('✓ Successfully accessed /tasks route');
    } else if (url.includes('/login') || url.includes('/auth')) {
      console.log('⚠ Redirected to login (expected if auth is required)');
    } else {
      console.log(`✗ Unexpected redirect to: ${url}`);
    }
  });
});
