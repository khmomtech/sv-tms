import { test, expect } from '@playwright/test';
import { mockAuthentication, TEST_USERS } from './helpers/auth.helper';

// Generic helper to assert a route loads without console errors
async function assertRouteLoads(page: any, path: string, opts?: { expectHeaderText?: RegExp }) {
  const errors: string[] = [];
  page.on('console', (msg: any) => {
    if (msg.type() === 'error') {
      errors.push(msg.text());
    }
  });

  await page.goto(path);
  await page.waitForLoadState('domcontentloaded');

  // Visible main content area
  const main = page.locator('main, .main-content, [role="main"], .container, .content');
  await expect(main.first()).toBeVisible({ timeout: 10000 });

  // Optional checks
  if (opts?.expectHeaderText) {
    await expect(page.locator(`text=${opts.expectHeaderText.source}`)).toBeVisible({ timeout: 5000 });
  }

  // Optional content hint (best-effort); do not fail if missing
  const contentCandidate = page.locator('table, .table, mat-table, tbody tr, [data-testid*="list" i], .empty, [data-testid*="empty" i]').first();
  try {
    await expect(contentCandidate).toBeVisible({ timeout: 5000 });
  } catch {}

  // Allow some benign third‑party noise, but fail on obvious app errors
  const severe = errors.filter((e) => !/favicon|ResizeObserver|Download the React DevTools|ERR_BLOCKED_BY_CLIENT|SourceMap|WebSocket connection|EventSource/i.test(e));
  expect(severe.length, `Console errors on ${path}:\n${severe.join('\n')}`).toBe(0);
}

test.describe('Smoke Routes', () => {
  test.beforeEach(async ({ page }) => {
    // Mock auth as admin for access to all routes
    await mockAuthentication(page, TEST_USERS.admin);

    // Stub backend APIs so smoke tests are backend-agnostic
    const emptyPage = {
      data: { content: [], totalElements: 0, totalPages: 1, number: 0, size: 10 },
    };
    const emptyList = { data: [] };

    await page.route('**/api/public/counts/**', async (route) => {
      await route.fulfill({ status: 200, contentType: 'application/json', body: JSON.stringify({ count: 0 }) });
    });
    await page.route('**/api/notifications/**', async (route) => {
      await route.fulfill({ status: 200, contentType: 'application/json', body: JSON.stringify({ data: 0 }) });
    });
    await page.route('**/api/admin/vehicles/search**', async (route) => {
      await route.fulfill({ status: 200, contentType: 'application/json', body: JSON.stringify(emptyPage) });
    });
    await page.route('**/api/admin/maintenance/requests**', async (route) => {
      await route.fulfill({ status: 200, contentType: 'application/json', body: JSON.stringify(emptyPage) });
    });
    await page.route('**/api/admin/maintenance/failure-codes/active**', async (route) => {
      await route.fulfill({ status: 200, contentType: 'application/json', body: JSON.stringify(emptyList) });
    });
    await page.route('**/api/admin/maintenance/failure-codes**', async (route) => {
      await route.fulfill({ status: 200, contentType: 'application/json', body: JSON.stringify(emptyPage) });
    });
    await page.route('**/api/admin/maintenance/pm-plans/vehicle/**', async (route) => {
      await route.fulfill({ status: 200, contentType: 'application/json', body: JSON.stringify(emptyList) });
    });
    await page.route('**/api/admin/maintenance/pm-plans/due**', async (route) => {
      await route.fulfill({ status: 200, contentType: 'application/json', body: JSON.stringify(emptyList) });
    });
    await page.route('**/api/admin/maintenance/pm-plans/calendar**', async (route) => {
      await route.fulfill({ status: 200, contentType: 'application/json', body: JSON.stringify(emptyList) });
    });
    await page.route('**/api/admin/maintenance/pm-plans**', async (route) => {
      await route.fulfill({ status: 200, contentType: 'application/json', body: JSON.stringify(emptyPage) });
    });
    await page.route('**/api/maintenance/work-orders/filter**', async (route) => {
      await route.fulfill({ status: 200, contentType: 'application/json', body: JSON.stringify(emptyPage) });
    });
    await page.route(/\/api\/(partners|vendors).*/, async (route) => {
      await route.fulfill({ status: 200, contentType: 'application/json', body: JSON.stringify([]) });
    });
    await page.route(/\/api\/admin\/(partners|vendors).*/, async (route) => {
      await route.fulfill({ status: 200, contentType: 'application/json', body: JSON.stringify([]) });
    });
    await page.route('**/api/customers**', async (route) => {
      await route.fulfill({ status: 200, contentType: 'application/json', body: JSON.stringify([]) });
    });
    await page.route('**/api/drivers**', async (route) => {
      await route.fulfill({ status: 200, contentType: 'application/json', body: JSON.stringify([]) });
    });
    await page.route('**/api/**', async (route) => {
      await route.fulfill({ status: 200, contentType: 'application/json', body: JSON.stringify({}) });
    });
    await page.route('**/ws-sockjs/**', async (route) => {
      await route.fulfill({ status: 200, contentType: 'application/json', body: JSON.stringify({}) });
    });
  });

  test('dashboard loads', async ({ page }) => {
    await assertRouteLoads(page, '/dashboard');
    await expect(page).toHaveURL(/\/dashboard/);
  });

  test('drivers route loads', async ({ page }) => {
    await assertRouteLoads(page, '/drivers');
    await expect(page).toHaveURL(/\/drivers/);
  });

  test('customers route loads', async ({ page }) => {
    await assertRouteLoads(page, '/customers');
    await expect(page).toHaveURL(/\/customers/);
  });

  test('partners route loads', async ({ page }) => {
    await assertRouteLoads(page, '/partners');
    await expect(page).toHaveURL(/\/(partners|vendors)/);
  });

  test('fleet vehicles route loads', async ({ page }) => {
    await assertRouteLoads(page, '/fleet/vehicles');
    await expect(page).toHaveURL(/\/fleet\/vehicles/);
  });

  test('maintenance requests route loads', async ({ page }) => {
    await assertRouteLoads(page, '/fleet/maintenance/requests');
    await expect(page).toHaveURL(/\/fleet\/maintenance\/requests/);
  });

  test('maintenance work orders route loads', async ({ page }) => {
    await assertRouteLoads(page, '/fleet/maintenance/work-orders');
    await expect(page).toHaveURL(/\/fleet\/maintenance\/work-orders/);
  });

  test('maintenance pm plans route loads', async ({ page }) => {
    await assertRouteLoads(page, '/fleet/maintenance/pm-plans');
    await expect(page).toHaveURL(/\/fleet\/maintenance\/pm-plans/);
  });

  test('maintenance schedule route loads', async ({ page }) => {
    await assertRouteLoads(page, '/fleet/maintenance/schedule');
    await expect(page).toHaveURL(/\/fleet\/maintenance\/schedule/);
  });

  test('maintenance failure codes route loads', async ({ page }) => {
    await assertRouteLoads(page, '/fleet/maintenance/failure-codes');
    await expect(page).toHaveURL(/\/fleet\/maintenance\/failure-codes/);
  });
});
