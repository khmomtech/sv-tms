import { test, expect } from '@playwright/test';

/**
 * Visual Regression Tests
 *
 * Captures screenshots of key UI states for visual comparison
 * Integrates with Percy or Chromatic for visual diff tracking
 *
 * Setup:
 * 1. Install Percy: npm install --save-dev @percy/cli @percy/playwright
 * 2. Set PERCY_TOKEN environment variable
 * 3. Run: npx percy exec -- npx playwright test e2e/visual/
 *
 * Or for Chromatic:
 * 1. Install: npm install --save-dev chromatic
 * 2. Run: npx chromatic --playwright
 */

const BASE_URL = process.env['BASE_URL'] || 'http://localhost:4200';

test.describe('Visual Regression Tests', () => {
  test.beforeEach(async ({ page }) => {
    await page.goto(`${BASE_URL}/login`);
    await page.fill('input[name="username"]', 'admin');
    await page.fill('input[name="password"]', 'admin123');
    await page.click('button[type="submit"]');
    await page.waitForURL(/\/(drivers|dashboard)/);
  });

  test.describe('Driver List Page', () => {
    test('should match baseline - empty state', async ({ page }) => {
      await page.goto(`${BASE_URL}/drivers`);

      // Apply filter that returns no results
      await page.fill('input[placeholder*="Search"]', 'NONEXISTENT_DRIVER_XYZ123');
      await page.waitForTimeout(500);

      await expect(page).toHaveScreenshot('driver-list-empty-state.png', {
        fullPage: true,
        animations: 'disabled'
      });
    });

    test('should match baseline - with data', async ({ page }) => {
      await page.goto(`${BASE_URL}/drivers`);
      await page.waitForSelector('.driver-row', { timeout: 5000 });

      await expect(page).toHaveScreenshot('driver-list-with-data.png', {
        fullPage: true,
        animations: 'disabled'
      });
    });

    test('should match baseline - filtered view', async ({ page }) => {
      await page.goto(`${BASE_URL}/drivers`);

      await page.click('mat-select[formControlName="status"]');
      await page.click('mat-option:has-text("ACTIVE")');
      await page.waitForTimeout(500);

      await expect(page).toHaveScreenshot('driver-list-filtered-active.png', {
        fullPage: true,
        animations: 'disabled'
      });
    });

    test('should match baseline - search results', async ({ page }) => {
      await page.goto(`${BASE_URL}/drivers`);

      await page.fill('input[placeholder*="Search"]', 'john');
      await page.waitForTimeout(500);

      await expect(page).toHaveScreenshot('driver-list-search-results.png', {
        fullPage: true,
        animations: 'disabled'
      });
    });

    test('should match baseline - pagination controls', async ({ page }) => {
      await page.goto(`${BASE_URL}/drivers`);
      await page.waitForSelector('.mat-paginator');

      // Focus on pagination area
      await expect(page.locator('.mat-paginator')).toHaveScreenshot('driver-list-pagination.png', {
        animations: 'disabled'
      });
    });

    test('should match baseline - bulk selection mode', async ({ page }) => {
      await page.goto(`${BASE_URL}/drivers`);

      // Select first two drivers
      await page.locator('mat-checkbox.row-checkbox').first().click();
      await page.locator('mat-checkbox.row-checkbox').nth(1).click();

      await expect(page).toHaveScreenshot('driver-list-bulk-selection.png', {
        fullPage: true,
        animations: 'disabled'
      });
    });
  });

  test.describe('Driver Create/Edit Dialog', () => {
    test('should match baseline - create dialog', async ({ page }) => {
      await page.goto(`${BASE_URL}/drivers`);
      await page.click('button:has-text("Add Driver")');
      await page.waitForSelector('.mat-dialog-container');

      await expect(page.locator('.mat-dialog-container')).toHaveScreenshot('driver-create-dialog.png', {
        animations: 'disabled'
      });
    });

    test('should match baseline - create dialog with validation errors', async ({ page }) => {
      await page.goto(`${BASE_URL}/drivers`);
      await page.click('button:has-text("Add Driver")');

      // Trigger validation errors
      await page.fill('input[formControlName="email"]', 'invalid-email');
      await page.fill('input[formControlName="phone"]', '123');
      await page.click('button:has-text("Save")');

      await expect(page.locator('.mat-dialog-container')).toHaveScreenshot('driver-create-dialog-validation-errors.png', {
        animations: 'disabled'
      });
    });

    test('should match baseline - edit dialog with data', async ({ page }) => {
      await page.goto(`${BASE_URL}/drivers`);

      // Click first driver
      await page.locator('.driver-row').first().click();
      await page.click('button:has-text("Edit")');
      await page.waitForSelector('.mat-dialog-container');

      await expect(page.locator('.mat-dialog-container')).toHaveScreenshot('driver-edit-dialog.png', {
        animations: 'disabled'
      });
    });
  });

  test.describe('Vehicle List Page', () => {
    test('should match baseline - vehicle list', async ({ page }) => {
      await page.goto(`${BASE_URL}/vehicles`);
      await page.waitForSelector('.vehicle-row', { timeout: 5000 });

      await expect(page).toHaveScreenshot('vehicle-list.png', {
        fullPage: true,
        animations: 'disabled'
      });
    });

    test('should match baseline - vehicle filters', async ({ page }) => {
      await page.goto(`${BASE_URL}/vehicles`);

      await page.click('mat-select[formControlName="type"]');
      await page.click('mat-option:has-text("TRUCK")');
      await page.waitForTimeout(500);

      await expect(page).toHaveScreenshot('vehicle-list-filtered.png', {
        fullPage: true,
        animations: 'disabled'
      });
    });

    test('should match baseline - vehicle status badges', async ({ page }) => {
      await page.goto(`${BASE_URL}/vehicles`);

      // Focus on status badges
      const firstRow = page.locator('.vehicle-row').first();
      await expect(firstRow).toHaveScreenshot('vehicle-status-badges.png', {
        animations: 'disabled'
      });
    });
  });

  test.describe('Conflict Resolution Dialog', () => {
    test('should match baseline - conflict dialog', async ({ page }) => {
      // Note: This requires setting up a conflict scenario
      // For visual testing, we can use component preview or mock

      await page.goto(`${BASE_URL}/drivers`);

      // Simulate conflict (if conflict detection is implemented in UI)
      // Otherwise, skip or use component preview mode

      // Placeholder for actual conflict dialog screenshot
      console.log('Conflict dialog visual test - requires conflict setup');
    });
  });

  test.describe('Error States', () => {
    test('should match baseline - error boundary', async ({ page, context }) => {
      await page.goto(`${BASE_URL}/drivers`);

      // Trigger error by going offline and trying to load
      await context.setOffline(true);
      await page.reload({ waitUntil: 'networkidle' });

      // Wait for error state
      await page.waitForTimeout(2000);

      await expect(page).toHaveScreenshot('error-boundary-offline.png', {
        fullPage: true,
        animations: 'disabled'
      });

      await context.setOffline(false);
    });

    test('should match baseline - 404 page', async ({ page }) => {
      await page.goto(`${BASE_URL}/nonexistent-page-xyz`);
      await page.waitForTimeout(1000);

      await expect(page).toHaveScreenshot('404-page.png', {
        fullPage: true,
        animations: 'disabled'
      });
    });

    test('should match baseline - validation errors', async ({ page }) => {
      await page.goto(`${BASE_URL}/drivers`);
      await page.click('button:has-text("Add Driver")');

      // Click save without filling form
      await page.click('button:has-text("Save")');

      await expect(page.locator('.mat-dialog-container')).toHaveScreenshot('form-validation-errors.png', {
        animations: 'disabled'
      });
    });
  });

  test.describe('Responsive Design', () => {
    test('should match baseline - mobile view (375px)', async ({ page }) => {
      await page.setViewportSize({ width: 375, height: 667 });
      await page.goto(`${BASE_URL}/drivers`);

      await expect(page).toHaveScreenshot('driver-list-mobile-375.png', {
        fullPage: true,
        animations: 'disabled'
      });
    });

    test('should match baseline - tablet view (768px)', async ({ page }) => {
      await page.setViewportSize({ width: 768, height: 1024 });
      await page.goto(`${BASE_URL}/drivers`);

      await expect(page).toHaveScreenshot('driver-list-tablet-768.png', {
        fullPage: true,
        animations: 'disabled'
      });
    });

    test('should match baseline - desktop view (1920px)', async ({ page }) => {
      await page.setViewportSize({ width: 1920, height: 1080 });
      await page.goto(`${BASE_URL}/drivers`);

      await expect(page).toHaveScreenshot('driver-list-desktop-1920.png', {
        fullPage: true,
        animations: 'disabled'
      });
    });

    test('should match baseline - mobile dialog full-screen', async ({ page }) => {
      await page.setViewportSize({ width: 375, height: 667 });
      await page.goto(`${BASE_URL}/drivers`);
      await page.click('button:has-text("Add Driver")');

      await expect(page).toHaveScreenshot('driver-dialog-mobile.png', {
        fullPage: true,
        animations: 'disabled'
      });
    });
  });

  test.describe('Loading States', () => {
    test('should match baseline - skeleton loading', async ({ page }) => {
      // Slow down network to capture loading state
      await page.route('**/api/admin/drivers**', route => {
        setTimeout(() => route.continue(), 2000);
      });

      const navigation = page.goto(`${BASE_URL}/drivers`);

      // Wait a bit for skeleton to show
      await page.waitForTimeout(500);

      await expect(page).toHaveScreenshot('driver-list-loading-skeleton.png', {
        animations: 'disabled'
      });

      await navigation;
    });

    test('should match baseline - infinite scroll loading', async ({ page }) => {
      await page.goto(`${BASE_URL}/drivers`);

      // Scroll to bottom to trigger loading
      await page.evaluate(() => window.scrollTo(0, document.body.scrollHeight));
      await page.waitForTimeout(300);

      await expect(page.locator('.loading-indicator')).toHaveScreenshot('infinite-scroll-loading.png', {
        animations: 'disabled'
      });
    });
  });

  test.describe('Theme Variations', () => {
    test('should match baseline - dark mode', async ({ page }) => {
      // Enable dark mode (if implemented)
      await page.goto(`${BASE_URL}/drivers`);

      // Toggle dark mode
      await page.evaluate(() => {
        document.body.classList.add('dark-theme');
      });

      await expect(page).toHaveScreenshot('driver-list-dark-mode.png', {
        fullPage: true,
        animations: 'disabled'
      });
    });

    test('should match baseline - high contrast mode', async ({ page }) => {
      await page.goto(`${BASE_URL}/drivers`);

      await page.evaluate(() => {
        document.body.classList.add('high-contrast-theme');
      });

      await expect(page).toHaveScreenshot('driver-list-high-contrast.png', {
        fullPage: true,
        animations: 'disabled'
      });
    });
  });

  test.describe('Cross-browser Consistency', () => {
    test('should match baseline - Chrome', async ({ page, browserName }) => {
      test.skip(browserName !== 'chromium', 'Chromium only');

      await page.goto(`${BASE_URL}/drivers`);
      await expect(page).toHaveScreenshot('driver-list-chrome.png', {
        fullPage: true,
        animations: 'disabled'
      });
    });

    test('should match baseline - Firefox', async ({ page, browserName }) => {
      test.skip(browserName !== 'firefox', 'Firefox only');

      await page.goto(`${BASE_URL}/drivers`);
      await expect(page).toHaveScreenshot('driver-list-firefox.png', {
        fullPage: true,
        animations: 'disabled'
      });
    });

    test('should match baseline - WebKit/Safari', async ({ page, browserName }) => {
      test.skip(browserName !== 'webkit', 'WebKit only');

      await page.goto(`${BASE_URL}/drivers`);
      await expect(page).toHaveScreenshot('driver-list-webkit.png', {
        fullPage: true,
        animations: 'disabled'
      });
    });
  });
});

/**
 * Visual Regression Testing Setup Guide
 *
 * Option 1: Percy (Recommended for teams)
 * ```bash
 * npm install --save-dev @percy/cli @percy/playwright
 * export PERCY_TOKEN=your-token-here
 * npx percy exec -- npx playwright test e2e/visual/
 * ```
 *
 * Option 2: Chromatic (Built by Storybook team)
 * ```bash
 * npm install --save-dev chromatic
 * npx chromatic --playwright --project-token=your-token
 * ```
 *
 * Option 3: Playwright Built-in (Free, local)
 * ```bash
 * npx playwright test e2e/visual/ --update-snapshots  # Update baselines
 * npx playwright test e2e/visual/                     # Run tests
 * ```
 *
 * Screenshot Storage:
 * - Baselines: e2e/visual/__screenshots__/
 * - Diffs: test-results/
 *
 * CI/CD Integration:
 * - Store baselines in git
 * - Run visual tests on PR
 * - Auto-comment with diffs
 * - Require approval for visual changes
 */
