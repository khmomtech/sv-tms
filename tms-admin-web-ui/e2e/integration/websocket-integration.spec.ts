import { test, expect, type Page } from '@playwright/test';

/**
 * WebSocket-flavored integration coverage for the current drivers UI.
 *
 * The low-level socket lifecycle and message parsing behavior is already covered
 * by unit tests for WebSocketService. These Playwright checks stay at the page
 * level and validate that the drivers experience still renders correctly when
 * the live-update plumbing is present in the app shell.
 */

const DRIVERS_URL = 'http://localhost:4200/drivers';
const API_BASE_URL = process.env['API_BASE_URL'] || 'http://localhost:8080';

async function authenticatePage(page: Page): Promise<void> {
  const response = await page.request.post(`${API_BASE_URL}/api/auth/login`, {
    data: {
      username: 'admin',
      password: 'admin123',
    },
  });

  expect(response.ok()).toBeTruthy();
  const payload = await response.json();
  const data = payload?.data ?? payload;

  await page.addInitScript(
    ({ token, refreshToken, user, permissions }) => {
      window.localStorage.setItem('token', token);
      if (refreshToken) {
        window.localStorage.setItem('refresh_token', refreshToken);
      }
      if (user) {
        window.localStorage.setItem('user', JSON.stringify(user));
      }
      if (permissions) {
        window.localStorage.setItem('permissions', JSON.stringify(permissions));
      }
    },
    {
      token: data.token,
      refreshToken: data.refreshToken ?? null,
      user: data.user ?? null,
      permissions: data.user?.permissions ?? [],
    },
  );
}

test.describe('WebSocket Integration Tests', () => {
  test('should load the drivers page without blocking on live connections', async ({ page }) => {
    await authenticatePage(page);
    await page.goto(DRIVERS_URL, { waitUntil: 'domcontentloaded' });

    await expect(page.getByTestId('driver-list')).toBeVisible();
    await expect(page.getByRole('heading', { name: 'Driver List', exact: true })).toBeVisible();
  });

  test('should render driver rows or empty state on the drivers page', async ({ page }) => {
    await authenticatePage(page);
    await page.goto(DRIVERS_URL, { waitUntil: 'domcontentloaded' });

    const driverTable = page.getByTestId('driver-list');
    await expect(driverTable).toBeVisible();

    const bodyRows = driverTable.locator('tbody tr');
    const rowCount = await bodyRows.count();

    if (rowCount > 0) {
      await expect(bodyRows.first()).toBeVisible();
    } else {
      await expect(page.locator('text=No drivers found for the current filters.')).toBeVisible();
    }
  });

  test('should render current driver status pills', async ({ page }) => {
    await authenticatePage(page);
    await page.goto(DRIVERS_URL, { waitUntil: 'domcontentloaded' });

    const driverTable = page.getByTestId('driver-list');
    await expect(driverTable).toBeVisible();
    await expect(page.getByText('Status', { exact: true })).toBeVisible();

    const statusCells = driverTable.locator('tbody td:nth-child(9) span');
    const statusCount = await statusCells.count();

    if (statusCount === 0) {
      await expect(driverTable.locator('tbody tr')).toHaveCount(1);
      return;
    }

    const firstStatus = (await statusCells.first().textContent())?.trim();
    expect(['Active', 'Inactive']).toContain(firstStatus || '');
  });

  test('should keep the drivers page interactive after initial live-update bootstrap', async ({
    page,
  }) => {
    await authenticatePage(page);
    await page.goto(DRIVERS_URL, { waitUntil: 'domcontentloaded' });
    await page.waitForTimeout(1500);

    await expect(page.getByRole('button', { name: 'Advanced Filters' })).toBeVisible();
    await expect(page.getByRole('button', { name: 'Columns' })).toBeVisible();
  });
});
