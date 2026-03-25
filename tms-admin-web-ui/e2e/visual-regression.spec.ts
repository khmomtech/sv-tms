import { test, expect } from '@playwright/test';

import { loginViaAPI, TEST_USERS } from './helpers/auth.helper';

/**
 * Visual Regression Tests
 *
 * These tests capture screenshots and compare them to detect visual changes
 */

test.describe('Visual Regression - Dashboard', () => {
  test.beforeEach(async ({ page }) => {
    await loginViaAPI(page, TEST_USERS.admin);
  });

  test('should match dashboard layout snapshot', async ({ page }) => {
    await page.goto('/dashboard');
    await page.waitForLoadState('networkidle');
    await page.waitForTimeout(2000);

    // Take full page screenshot
    await expect(page).toHaveScreenshot('dashboard-full.png', {
      fullPage: true,
      timeout: 10000
    });
  });

  test('should match dashboard header snapshot', async ({ page }) => {
    await page.goto('/dashboard');
    await page.waitForLoadState('networkidle');

    // Look for header/navigation with flexible selectors
    const header = page.locator('nav, .navbar, .header, [role="banner"], header').first();
    const isVisible = await header.isVisible({ timeout: 5000 }).catch(() => false);

    if (isVisible) {
      await expect(header).toHaveScreenshot('dashboard-header.png');
    } else {
      // Skip if no header element exists
      test.skip();
    }
  });

  test('should match dashboard sidebar snapshot', async ({ page }) => {
    await page.goto('/dashboard');
    await page.waitForLoadState('networkidle');

    const sidebar = page.locator('aside[role="navigation"], app-sidebar');
    if (await sidebar.isVisible()) {
      await expect(sidebar).toHaveScreenshot('dashboard-sidebar.png');
    }
  });

  test('should match metric cards snapshot', async ({ page }) => {
    await page.goto('/dashboard');
    await page.waitForLoadState('networkidle');
    await page.waitForTimeout(2000);

    const metricsSection = page.locator('[data-testid="metrics"], .metrics, .dashboard-metrics').first();
    if (await metricsSection.isVisible({ timeout: 5000 })) {
      await expect(metricsSection).toHaveScreenshot('dashboard-metrics.png');
    }
  });
});

test.describe('Visual Regression - Driver Management', () => {
  test.beforeEach(async ({ page }) => {
    await loginViaAPI(page, TEST_USERS.admin);
  });

  test('should match driver list snapshot', async ({ page }) => {
    await page.goto('/drivers');
    await page.waitForLoadState('networkidle');
    await page.waitForTimeout(2000);

    await expect(page).toHaveScreenshot('driver-list-full.png', {
      fullPage: true,
      timeout: 10000
    });
  });

  test('should match driver table snapshot', async ({ page }) => {
    await page.goto('/drivers');
    await page.waitForLoadState('networkidle');
    await page.waitForTimeout(2000);

    const table = page.locator('table, mat-table');
    if (await table.isVisible()) {
      await expect(table).toHaveScreenshot('driver-table.png');
    }
  });

  test('should match driver form snapshot', async ({ page }) => {
    await page.goto('/drivers');
    await page.waitForLoadState('networkidle');

    const addButton = page.locator('button').filter({ hasText: /add|create|new/i }).first();
    if (await addButton.isVisible({ timeout: 5000 })) {
      await addButton.click();
      await page.waitForTimeout(1000);

      const modal = page.locator('[role="dialog"], .modal, mat-dialog-container');
      if (await modal.isVisible()) {
        await expect(modal).toHaveScreenshot('driver-form.png');
      }
    }
  });
});

test.describe('Visual Regression - Vehicle Management', () => {
  test.beforeEach(async ({ page }) => {
    await loginViaAPI(page, TEST_USERS.admin);
  });

  test('should match vehicle list snapshot', async ({ page }) => {
    await page.goto('/vehicles');
    await page.waitForLoadState('networkidle');
    await page.waitForTimeout(2000);

    await expect(page).toHaveScreenshot('vehicle-list-full.png', {
      fullPage: true,
      timeout: 10000
    });
  });

  test('should match vehicle table snapshot', async ({ page }) => {
    await page.goto('/vehicles');
    await page.waitForLoadState('networkidle');
    await page.waitForTimeout(2000);

    const table = page.locator('table, mat-table');
    if (await table.isVisible()) {
      await expect(table).toHaveScreenshot('vehicle-table.png');
    }
  });
});

test.describe('Visual Regression - Mobile Views', () => {
  test.beforeEach(async ({ page }) => {
    await loginViaAPI(page, TEST_USERS.admin);
    await page.setViewportSize({ width: 375, height: 667 }); // iPhone SE
  });

  test('should match mobile dashboard snapshot', async ({ page }) => {
    await page.goto('/dashboard');
    await page.waitForLoadState('networkidle');
    await page.waitForTimeout(2000);

    await expect(page).toHaveScreenshot('dashboard-mobile.png', {
      fullPage: true,
      timeout: 10000
    });
  });

  test('should match mobile driver list snapshot', async ({ page }) => {
    await page.goto('/drivers');
    await page.waitForLoadState('networkidle');
    await page.waitForTimeout(2000);

    await expect(page).toHaveScreenshot('driver-list-mobile.png', {
      fullPage: true,
      timeout: 10000
    });
  });

  test('should match mobile navigation menu snapshot', async ({ page }) => {
    await page.goto('/dashboard');
    await page.waitForLoadState('networkidle');

    // Try to open mobile menu
    const menuToggle = page.locator('button[aria-label*="menu" i], .menu-toggle, .hamburger').first();
    if (await menuToggle.isVisible()) {
      await menuToggle.click();
      await page.waitForTimeout(500);

      await expect(page).toHaveScreenshot('mobile-menu-open.png');
    }
  });
});

test.describe('Visual Regression - Dark Mode', () => {
  test.beforeEach(async ({ page }) => {
    await loginViaAPI(page, TEST_USERS.admin);

    // Enable dark mode (if theme toggle exists)
    await page.goto('/dashboard');
    await page.waitForLoadState('networkidle');

    const themeToggle = page.locator('[data-testid="theme-toggle"], button[aria-label*="theme" i], .theme-toggle').first();
    if (await themeToggle.isVisible({ timeout: 3000 })) {
      await themeToggle.click();
      await page.waitForTimeout(1000);
    } else {
      // Manually add dark mode class
      await page.evaluate(() => {
        document.documentElement.classList.add('dark', 'dark-theme');
        document.body.classList.add('dark', 'dark-theme');
      });
    }
  });

  test('should match dark mode dashboard snapshot', async ({ page }) => {
    await page.waitForTimeout(1000);

    await expect(page).toHaveScreenshot('dashboard-dark-mode.png', {
      fullPage: true,
      timeout: 10000
    });
  });

  test('should match dark mode driver list snapshot', async ({ page }) => {
    await page.goto('/drivers');
    await page.waitForLoadState('networkidle');
    await page.waitForTimeout(1000);

    await expect(page).toHaveScreenshot('driver-list-dark-mode.png', {
      fullPage: true,
      timeout: 10000
    });
  });
});

test.describe('Visual Regression - Responsive Breakpoints', () => {
  const breakpoints = [
    { name: 'mobile', width: 375, height: 667 },
    { name: 'tablet', width: 768, height: 1024 },
    { name: 'laptop', width: 1366, height: 768 },
    { name: 'desktop', width: 1920, height: 1080 }
  ];

  breakpoints.forEach(({ name, width, height }) => {
    test(`should match dashboard at ${name} breakpoint`, async ({ page }) => {
      await loginViaAPI(page, TEST_USERS.admin);
      await page.setViewportSize({ width, height });

      await page.goto('/dashboard');
      await page.waitForLoadState('networkidle');
      await page.waitForTimeout(2000);

      await expect(page).toHaveScreenshot(`dashboard-${name}.png`, {
        fullPage: true,
        timeout: 10000
      });
    });
  });
});

test.describe('Visual Regression - Component States', () => {
  test.beforeEach(async ({ page }) => {
    await loginViaAPI(page, TEST_USERS.admin);
  });

  test('should match button hover states', async ({ page }) => {
    await page.goto('/dashboard');
    await page.waitForLoadState('networkidle');

    const button = page.locator('button').first();
    if (await button.isVisible()) {
      await button.hover();
      await page.waitForTimeout(300);

      await expect(button).toHaveScreenshot('button-hover.png');
    }
  });

  test('should match input focus states', async ({ page }) => {
    await page.goto('/drivers');
    await page.waitForLoadState('networkidle');

    const searchInput = page.locator('input[type="search"], input[placeholder*="search" i]').first();
    if (await searchInput.isVisible()) {
      await searchInput.focus();
      await page.waitForTimeout(300);

      await expect(searchInput).toHaveScreenshot('input-focus.png');
    }
  });

  test('should match error state validation', async ({ page }) => {
    await page.goto('/drivers');
    await page.waitForLoadState('networkidle');

    const addButton = page.locator('button').filter({ hasText: /add|create/i }).first();
    if (await addButton.isVisible({ timeout: 5000 })) {
      await addButton.click();
      await page.waitForTimeout(1000);

      const emailInput = page.locator('input[type="email"]').first();
      if (await emailInput.isVisible()) {
        await emailInput.fill('invalid-email');
        await emailInput.blur();
        await page.waitForTimeout(500);

        const formGroup = emailInput.locator('xpath=ancestor::*[contains(@class, "form-group") or contains(@class, "mat-form-field")]').first();
        if (await formGroup.isVisible()) {
          await expect(formGroup).toHaveScreenshot('input-error-state.png');
        }
      }
    }
  });
});
