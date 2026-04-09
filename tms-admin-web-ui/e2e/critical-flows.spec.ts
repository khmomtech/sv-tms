import { test, expect, Page } from '@playwright/test';

/**
 * Phase 3 Testing - Week 3: E2E Critical User Flows
 *
 * Tests complete user journeys through the application including:
 * - Authentication flows
 * - Driver management workflows
 * - Vehicle management workflows
 * - Realtime tracking and updates
 * - Error recovery scenarios
 */

test.describe('Authentication Flows', () => {
  test.beforeEach(async ({ page }) => {
    await page.goto('http://localhost:4200');
  });

  test('should login successfully with valid credentials', async ({ page }) => {
    await page.fill('[data-test="username-input"]', 'dispatcher@test.com');
    await page.fill('[data-test="password-input"]', 'password123');
    await page.click('[data-test="login-button"]');

    await expect(page).toHaveURL(/.*dashboard/);
    await expect(page.locator('[data-test="user-menu"]')).toBeVisible();
  });

  test('should show error for invalid credentials', async ({ page }) => {
    await page.fill('[data-test="username-input"]', 'invalid@test.com');
    await page.fill('[data-test="password-input"]', 'wrongpassword');
    await page.click('[data-test="login-button"]');

    await expect(page.locator('[data-test="error-message"]')).toContainText('Invalid credentials');
  });

  test('should logout and redirect to login', async ({ page }) => {
    // Login first
    await page.fill('[data-test="username-input"]', 'dispatcher@test.com');
    await page.fill('[data-test="password-input"]', 'password123');
    await page.click('[data-test="login-button"]');
    await page.waitForURL(/.*dashboard/);

    // Logout
    await page.click('[data-test="user-menu"]');
    await page.click('[data-test="logout-button"]');

    await expect(page).toHaveURL(/.*login/);
  });

  test('should persist session after page refresh', async ({ page }) => {
    await page.fill('[data-test="username-input"]', 'dispatcher@test.com');
    await page.fill('[data-test="password-input"]', 'password123');
    await page.click('[data-test="login-button"]');
    await page.waitForURL(/.*dashboard/);

    await page.reload();

    await expect(page).toHaveURL(/.*dashboard/);
    await expect(page.locator('[data-test="user-menu"]')).toBeVisible();
  });

  test('should redirect to login for protected routes', async ({ page }) => {
    await page.goto('http://localhost:4200/drivers');

    await expect(page).toHaveURL(/.*login/);
  });
});

test.describe('Driver Management Workflow', () => {
  test.beforeEach(async ({ page }) => {
    await loginAsDispatcher(page);
    await page.goto('http://localhost:4200/drivers');
  });

  test('should display driver list with filters', async ({ page }) => {
    await expect(page.locator('[data-test="drivers-table"]')).toBeVisible();
    await expect(page.locator('[data-test="search-input"]')).toBeVisible();
    await expect(page.locator('[data-test="status-filter"]')).toBeVisible();
  });

  test('should filter drivers by search term', async ({ page }) => {
    await page.fill('[data-test="search-input"]', 'John');
    await page.waitForTimeout(500); // Debounce

    const rows = page.locator('[data-test="driver-row"]');
    await expect(rows.first()).toContainText('John');
  });

  test('should create new driver successfully', async ({ page }) => {
    await page.click('[data-test="add-driver-button"]');
    await expect(page.locator('[data-test="driver-modal"]')).toBeVisible();

    await page.fill('[data-test="name-input"]', 'Test Driver');
    await page.fill('[data-test="license-input"]', 'DL123456');
    await page.fill('[data-test="phone-input"]', '+1234567890');
    await page.selectOption('[data-test="status-select"]', 'AVAILABLE');

    await page.click('[data-test="save-button"]');

    await expect(page.locator('[data-test="success-message"]')).toContainText('Driver created');
    await expect(page.locator('[data-test="driver-modal"]')).not.toBeVisible();
  });

  test('should update existing driver', async ({ page }) => {
    // await page.click('[data-test="driver-row"]').first();
    await page.click('[data-test="edit-button"]');

    await page.fill('[data-test="phone-input"]', '+9876543210');
    await page.click('[data-test="save-button"]');

    await expect(page.locator('[data-test="success-message"]')).toContainText('updated');
  });

  test('should delete driver with confirmation', async ({ page }) => {
    const initialCount = await page.locator('[data-test="driver-row"]').count();

    page.on('dialog', dialog => dialog.accept());

    // await page.click('[data-test="driver-row"]').first();
    await page.click('[data-test="delete-button"]');

    await expect(page.locator('[data-test="driver-row"]')).toHaveCount(initialCount - 1);
  });

  test('should paginate through drivers', async ({ page }) => {
    const firstDriverName = await page.locator('[data-test="driver-row"]').first().textContent();

    await page.click('[data-test="next-page-button"]');

    const newFirstDriverName = await page.locator('[data-test="driver-row"]').first().textContent();
    expect(firstDriverName).not.toBe(newFirstDriverName);
  });

  test('should handle driver creation validation errors', async ({ page }) => {
    await page.click('[data-test="add-driver-button"]');

    await page.click('[data-test="save-button"]');

    await expect(page.locator('[data-test="validation-error"]')).toBeVisible();
  });
});

test.describe('Vehicle Management Workflow', () => {
  test.beforeEach(async ({ page }) => {
    await loginAsDispatcher(page);
    await page.goto('http://localhost:4200/vehicles');
  });

  test('should display vehicle grid with filters', async ({ page }) => {
    await expect(page.locator('[data-test="vehicle-grid"]')).toBeVisible();
    await expect(page.locator('[data-test="status-filter"]')).toBeVisible();
  });

  test('should filter vehicles by status', async ({ page }) => {
    await page.selectOption('[data-test="status-filter"]', 'AVAILABLE');

    const vehicles = page.locator('[data-test="vehicle-card"]');
    const count = await vehicles.count();

    for (let i = 0; i < count; i++) {
      await expect(vehicles.nth(i)).toContainText('AVAILABLE');
    }
  });

  test('should create new vehicle', async ({ page }) => {
    await page.click('[data-test="add-vehicle-button"]');

    await page.fill('[data-test="plate-input"]', 'XYZ-789');
    await page.selectOption('[data-test="type-select"]', 'TRUCK');
    await page.fill('[data-test="capacity-input"]', '2000');
    await page.selectOption('[data-test="truck-size-select"]', 'LARGE');

    await page.click('[data-test="save-button"]');

    await expect(page.locator('[data-test="success-message"]')).toBeVisible();
  });

  test('should update vehicle status', async ({ page }) => {
    // await page.click('[data-test="vehicle-card"]').first();
    await page.selectOption('[data-test="status-select"]', 'IN_USE');
    await page.click('[data-test="save-button"]');

    await expect(page.locator('[data-test="vehicle-card"]').first()).toContainText('IN_USE');
  });

  test('should virtual scroll through large vehicle list', async ({ page }) => {
    const viewport = page.locator('[data-test="vehicle-scroll-viewport"]');

    await viewport.evaluate(el => el.scrollTo(0, 5000));
    await page.waitForTimeout(300);

    const vehicleLocator = page.locator('[data-test="vehicle-card"]');
    const total = await vehicleLocator.count();
    let visibleVehicles = 0;
    for (let i = 0; i < total; i++) {
      if (await vehicleLocator.nth(i).isVisible()) visibleVehicles++;
    }
    expect(visibleVehicles).toBeGreaterThan(0);
  });
});

test.describe('Realtime Updates via WebSocket', () => {
  test.beforeEach(async ({ page }) => {
    await loginAsDispatcher(page);
  });

  test('should receive driver location updates', async ({ page }) => {
    await page.goto('http://localhost:4200/tracking');

    // Simulate WebSocket message
    await page.evaluate(() => {
      const event = new MessageEvent('message', {
        data: JSON.stringify({
          type: 'LOCATION_UPDATE',
          driverId: 1,
          latitude: 11.5564,
          longitude: 104.9282
        })
      });
      window.dispatchEvent(event);
    });

    await page.waitForTimeout(500);

    const marker = page.locator('[data-test="driver-marker-1"]');
    await expect(marker).toBeVisible();
  });

  test('should update driver status in realtime', async ({ page }) => {
    await page.goto('http://localhost:4200/drivers');

    const driverRow = page.locator('[data-test="driver-row-1"]');
    const initialStatus = await driverRow.locator('[data-test="status"]').textContent();

    // Simulate status change
    await page.evaluate(() => {
      const event = new CustomEvent('driver-status-change', {
        detail: { driverId: 1, status: 'ON_TRIP' }
      });
      window.dispatchEvent(event);
    });

    await page.waitForTimeout(500);

    const newStatus = await driverRow.locator('[data-test="status"]').textContent();
    expect(newStatus).not.toBe(initialStatus);
  });

  test('should reconnect WebSocket on connection loss', async ({ page }) => {
    await page.goto('http://localhost:4200/dashboard');

    // Simulate connection loss
    await page.evaluate(() => {
      (window as any).webSocketService?.disconnect();
    });

    await expect(page.locator('[data-test="connection-status"]')).toContainText('Disconnected');

    // Should auto-reconnect
    await page.waitForTimeout(3000);

    await expect(page.locator('[data-test="connection-status"]')).toContainText('Connected');
  });
});

test.describe('Error Recovery Scenarios', () => {
  test.beforeEach(async ({ page }) => {
    await loginAsDispatcher(page);
  });

  test('should display error boundary on component error', async ({ page }) => {
    await page.goto('http://localhost:4200/drivers');

    // Trigger an error
    await page.evaluate(() => {
      throw new Error('Test component error');
    });

    await expect(page.locator('[data-test="error-boundary"]')).toBeVisible();
    await expect(page.locator('[data-test="retry-button"]')).toBeVisible();
  });

  test('should retry after error', async ({ page }) => {
    await page.goto('http://localhost:4200/drivers');

    // Trigger error
    await page.evaluate(() => {
      throw new Error('Test error');
    });

    await page.click('[data-test="retry-button"]');

    await expect(page.locator('[data-test="drivers-table"]')).toBeVisible();
  });

  test('should handle API errors gracefully', async ({ page }) => {
    // Intercept API and return error
    await page.route('**/api/drivers*', route =>
      route.fulfill({ status: 500, body: JSON.stringify({ error: 'Server error' }) })
    );

    await page.goto('http://localhost:4200/drivers');

    await expect(page.locator('[data-test="error-message"]')).toContainText('error');
  });

  test('should resolve optimistic locking conflicts', async ({ page }) => {
    await page.goto('http://localhost:4200/drivers/1');

    // Simulate conflict
    await page.route('**/api/drivers/1', route =>
      route.fulfill({
        status: 409,
        body: JSON.stringify({
          error: 'Conflict',
          localVersion: { name: 'Local Name' },
          serverVersion: { name: 'Server Name' }
        })
      })
    );

    await page.fill('[data-test="name-input"]', 'Updated Name');
    await page.click('[data-test="save-button"]');

    await expect(page.locator('[data-test="conflict-dialog"]')).toBeVisible();

    await page.click('[data-test="use-server-button"]');

    await expect(page.locator('[data-test="conflict-dialog"]')).not.toBeVisible();
  });

  test('should handle network timeout', async ({ page }) => {
    await page.route('**/api/drivers*', route =>
      new Promise(() => {}) // Never resolve
    );

    await page.goto('http://localhost:4200/drivers');

    await expect(page.locator('[data-test="loading-spinner"]')).toBeVisible();
    await page.waitForTimeout(10000); // Wait for timeout

    await expect(page.locator('[data-test="timeout-error"]')).toBeVisible();
  });
});

test.describe('Performance and Load Testing', () => {
  test('should render 1000 drivers with virtual scrolling', async ({ page }) => {
    await loginAsDispatcher(page);
    await page.goto('http://localhost:4200/drivers');

    const startTime = Date.now();

    // Wait for initial render
    await page.waitForSelector('[data-test="driver-row"]');

    const renderTime = Date.now() - startTime;

    expect(renderTime).toBeLessThan(3000); // Should render in < 3s
  });

  test('should handle rapid filter changes', async ({ page }) => {
    await loginAsDispatcher(page);
    await page.goto('http://localhost:4200/drivers');

    // Rapidly change filters
    for (let i = 0; i < 10; i++) {
      await page.fill('[data-test="search-input"]', `test${i}`);
      await page.waitForTimeout(50);
    }

    // Should still show results without crashing
    await page.waitForTimeout(1000);
    await expect(page.locator('[data-test="drivers-table"]')).toBeVisible();
  });

  test('should cache API responses', async ({ page }) => {
    await loginAsDispatcher(page);

    let apiCallCount = 0;
    await page.route('**/api/drivers*', route => {
      apiCallCount++;
      route.continue();
    });

    await page.goto('http://localhost:4200/drivers');
    await page.waitForTimeout(500);

    const firstCallCount = apiCallCount;

    // Navigate away and back
    await page.goto('http://localhost:4200/dashboard');
    await page.goto('http://localhost:4200/drivers');
    await page.waitForTimeout(500);

    // Should use cache (no new API call within TTL)
    expect(apiCallCount).toBe(firstCallCount);
  });
});

// Helper functions
async function loginAsDispatcher(page: Page) {
  await page.goto('http://localhost:4200/login');
  await page.fill('[data-test="username-input"]', 'dispatcher@test.com');
  await page.fill('[data-test="password-input"]', 'password123');
  await page.click('[data-test="login-button"]');
  await page.waitForURL(/.*dashboard/);
}
