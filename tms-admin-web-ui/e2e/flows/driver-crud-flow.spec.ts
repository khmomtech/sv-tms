import { test, expect } from '@playwright/test';

/**
 * End-to-End Driver CRUD Flow Tests
 *
 * Tests complete user journeys for driver management:
 * - Create → View → Update → Delete
 * - Search and filter workflows
 * - Error recovery scenarios
 */

const BASE_URL = process.env['BASE_URL'] || 'http://localhost:4200';

test.describe('Driver CRUD User Flows', () => {
  test.beforeEach(async ({ page }) => {
    // Login before each test
    await page.goto(`${BASE_URL}/login`);
    await page.fill('input[name="username"]', 'admin');
    await page.fill('input[name="password"]', 'admin123');
    await page.click('button[type="submit"]');
    await page.waitForURL(`${BASE_URL}/drivers`);
  });

  test('complete driver lifecycle: create → view → update → delete', async ({ page }) => {
    const timestamp = Date.now();
    const driverData = {
      firstName: 'John',
      lastName: 'Doe',
      email: `john.doe.${timestamp}@example.com`,
      phone: '+1234567890',
      licenseNumber: `DL${timestamp}`
    };

    // Step 1: Navigate to drivers page
    await page.goto(`${BASE_URL}/drivers`);
    await expect(page.locator('h1')).toContainText('Driver');

    // Step 2: Click "Add Driver" button
    await page.click('button:has-text("Add Driver")');
    await expect(page.locator('.dialog-title')).toContainText('Add Driver');

    // Step 3: Fill in driver form
    await page.fill('input[formControlName="firstName"]', driverData.firstName);
    await page.fill('input[formControlName="lastName"]', driverData.lastName);
    await page.fill('input[formControlName="email"]', driverData.email);
    await page.fill('input[formControlName="phone"]', driverData.phone);
    await page.fill('input[formControlName="licenseNumber"]', driverData.licenseNumber);

    // Step 4: Submit form
    await page.click('button:has-text("Save")');

    // Step 5: Verify success message
    await expect(page.locator('.snackbar-success')).toBeVisible({ timeout: 5000 });
    await expect(page.locator('.snackbar-success')).toContainText('Driver created successfully');

    // Step 6: Search for newly created driver
    await page.fill('input[placeholder*="Search"]', driverData.email);
    await page.waitForTimeout(500); // Debounce

    // Step 7: Verify driver appears in list
    const driverRow = page.locator(`text=${driverData.email}`).first();
    await expect(driverRow).toBeVisible({ timeout: 5000 });

    // Step 8: Click to view driver details
    await driverRow.click();

    // Step 9: Verify details page shows correct information
    await expect(page.locator('.driver-details')).toBeVisible();
    await expect(page.locator('.driver-details')).toContainText(driverData.firstName);
    await expect(page.locator('.driver-details')).toContainText(driverData.lastName);
    await expect(page.locator('.driver-details')).toContainText(driverData.email);

    // Step 10: Click "Edit" button
    await page.click('button:has-text("Edit")');
    await expect(page.locator('.dialog-title')).toContainText('Edit Driver');

    // Step 11: Update driver information
    const updatedFirstName = 'Jane';
    await page.fill('input[formControlName="firstName"]', updatedFirstName);
    await page.click('button:has-text("Save")');

    // Step 12: Verify update success
    await expect(page.locator('.snackbar-success')).toContainText('Driver updated successfully');
    await expect(page.locator('.driver-details')).toContainText(updatedFirstName);

    // Step 13: Navigate back to list
    await page.click('button:has-text("Back to List")');
    await page.waitForURL(`${BASE_URL}/drivers`);

    // Step 14: Search for updated driver
    await page.fill('input[placeholder*="Search"]', driverData.email);
    await page.waitForTimeout(500);

    // Step 15: Click delete button
    await page.click(`tr:has-text("${driverData.email}") button[aria-label="Delete"]`);

    // Step 16: Confirm deletion in dialog
    await expect(page.locator('.confirmation-dialog')).toBeVisible();
    await page.click('button:has-text("Confirm")');

    // Step 17: Verify deletion success
    await expect(page.locator('.snackbar-success')).toContainText('Driver deleted successfully');

    // Step 18: Verify driver no longer appears in search
    await page.fill('input[placeholder*="Search"]', driverData.email);
    await page.waitForTimeout(500);
    await expect(page.locator(`text=${driverData.email}`)).not.toBeVisible();
  });

  test('search and filter workflow', async ({ page }) => {
    await page.goto(`${BASE_URL}/drivers`);

    // Test 1: Text search
    await page.fill('input[placeholder*="Search"]', 'john');
    await page.waitForTimeout(500);

    const searchResults = await page.locator('.driver-row').count();
    console.log(`Found ${searchResults} drivers matching 'john'`);

    // Test 2: Status filter
    await page.click('mat-select[formControlName="status"]');
    await page.click('mat-option:has-text("ACTIVE")');
    await page.waitForTimeout(500);

    const activeDrivers = await page.locator('.driver-row .status-badge:has-text("ACTIVE")').count();
    const totalDrivers = await page.locator('.driver-row').count();
    expect(activeDrivers).toBe(totalDrivers); // All should be ACTIVE

    // Test 3: Clear filters
    await page.click('button:has-text("Clear Filters")');
    await page.waitForTimeout(500);

    const searchInput = await page.inputValue('input[placeholder*="Search"]');
    expect(searchInput).toBe('');

    // Test 4: Pagination
    const nextButton = page.locator('button[aria-label="Next page"]');
    if (await nextButton.isEnabled()) {
      await nextButton.click();
      await page.waitForTimeout(500);

      // Verify page changed
      const pageInfo = await page.locator('.mat-paginator-range-label').textContent();
      expect(pageInfo).toContain('11'); // Should show items 11-20
    }
  });

  test('bulk operations workflow', async ({ page }) => {
    await page.goto(`${BASE_URL}/drivers`);

    // Step 1: Select multiple drivers
    const checkboxes = page.locator('mat-checkbox.row-checkbox').first();
    await checkboxes.click();
    await page.locator('mat-checkbox.row-checkbox').nth(1).click();

    // Step 2: Verify bulk action toolbar appears
    await expect(page.locator('.bulk-actions-toolbar')).toBeVisible();
    await expect(page.locator('.bulk-actions-toolbar')).toContainText('2 selected');

    // Step 3: Click bulk status change
    await page.click('button:has-text("Change Status")');
    await page.click('mat-option:has-text("INACTIVE")');

    // Step 4: Verify success
    await expect(page.locator('.snackbar-success')).toContainText('2 drivers updated');

    // Step 5: Deselect all
    await page.click('button:has-text("Clear Selection")');
    await expect(page.locator('.bulk-actions-toolbar')).not.toBeVisible();
  });

  test('validation error recovery workflow', async ({ page }) => {
    await page.goto(`${BASE_URL}/drivers`);

    // Step 1: Open create dialog
    await page.click('button:has-text("Add Driver")');

    // Step 2: Try to submit empty form
    await page.click('button:has-text("Save")');

    // Step 3: Verify validation errors
    await expect(page.locator('.mat-error:has-text("First name is required")')).toBeVisible();
    await expect(page.locator('.mat-error:has-text("Last name is required")')).toBeVisible();
    await expect(page.locator('.mat-error:has-text("Email is required")')).toBeVisible();

    // Step 4: Fill in invalid email
    await page.fill('input[formControlName="email"]', 'invalid-email');
    await page.locator('input[formControlName="email"]').blur();
    await expect(page.locator('.mat-error:has-text("Invalid email")')).toBeVisible();

    // Step 5: Fill in invalid phone
    await page.fill('input[formControlName="phone"]', '123'); // Too short
    await page.locator('input[formControlName="phone"]').blur();
    await expect(page.locator('.mat-error')).toContainText('phone');

    // Step 6: Fix errors and submit successfully
    await page.fill('input[formControlName="firstName"]', 'Test');
    await page.fill('input[formControlName="lastName"]', 'User');
    await page.fill('input[formControlName="email"]', `test.${Date.now()}@example.com`);
    await page.fill('input[formControlName="phone"]', '+1234567890');
    await page.fill('input[formControlName="licenseNumber"]', `DL${Date.now()}`);

    await page.click('button:has-text("Save")');
    await expect(page.locator('.snackbar-success')).toBeVisible();
  });

  test('network error recovery workflow', async ({ page, context }) => {
    await page.goto(`${BASE_URL}/drivers`);

    // Step 1: Go offline
    await context.setOffline(true);

    // Step 2: Try to create driver
    await page.click('button:has-text("Add Driver")');
    await page.fill('input[formControlName="firstName"]', 'Offline');
    await page.fill('input[formControlName="lastName"]', 'Test');
    await page.fill('input[formControlName="email"]', `offline.${Date.now()}@example.com`);
    await page.fill('input[formControlName="phone"]', '+1234567890');
    await page.click('button:has-text("Save")');

    // Step 3: Verify error message
    await expect(page.locator('.snackbar-error')).toBeVisible({ timeout: 10000 });
    await expect(page.locator('.snackbar-error')).toContainText('network');

    // Step 4: Go back online
    await context.setOffline(false);

    // Step 5: Retry operation
    await page.click('button:has-text("Retry")');

    // Step 6: Verify success after retry
    await expect(page.locator('.snackbar-success')).toBeVisible({ timeout: 10000 });
  });

  test('concurrent editing conflict resolution workflow', async ({ page, context }) => {
    // This test simulates optimistic locking conflict

    await page.goto(`${BASE_URL}/drivers`);

    // Step 1: Find and edit a driver
    const driverRow = page.locator('.driver-row').first();
    await driverRow.click();
    await page.click('button:has-text("Edit")');

    // Step 2: Get current driver ID and version
    const driverId = await page.getAttribute('[data-driver-id]', 'data-driver-id');
    const currentVersion = await page.getAttribute('[data-version]', 'data-version');

    // Step 3: Simulate concurrent edit by making API call directly
    const apiContext = await context.newPage();
    const authToken = await page.evaluate(() => localStorage.getItem('authToken'));

    // Make concurrent update via API
    await apiContext.request.put(`http://localhost:8080/api/admin/drivers/${driverId}`, {
      data: {
        id: driverId,
        version: parseInt(currentVersion || '0'),
        firstName: 'Concurrent',
        lastName: 'Update'
      },
      headers: {
        'Authorization': `Bearer ${authToken}`
      }
    });

    // Step 4: Try to save from UI (should trigger conflict)
    await page.fill('input[formControlName="firstName"]', 'UI Update');
    await page.click('button:has-text("Save")');

    // Step 5: Verify conflict resolution dialog appears
    await expect(page.locator('.conflict-dialog')).toBeVisible({ timeout: 5000 });
    await expect(page.locator('.conflict-dialog')).toContainText('Conflict detected');

    // Step 6: Choose resolution strategy (use server version)
    await page.click('button:has-text("Use Server Version")');

    // Step 7: Verify data refreshed with server version
    await expect(page.locator('input[formControlName="firstName"]')).toHaveValue('Concurrent');

    await apiContext.close();
  });

  test('real-time updates workflow', async ({ page, context }) => {
    await page.goto(`${BASE_URL}/drivers`);

    // Step 1: Open second browser window
    const page2 = await context.newPage();
    await page2.goto(`${BASE_URL}/login`);
    await page2.fill('input[name="username"]', 'admin');
    await page2.fill('input[name="password"]', 'admin123');
    await page2.click('button[type="submit"]');
    await page2.waitForURL(`${BASE_URL}/drivers`);

    // Step 2: Create driver in first window
    await page.click('button:has-text("Add Driver")');
    const email = `realtime.${Date.now()}@example.com`;
    await page.fill('input[formControlName="firstName"]', 'Realtime');
    await page.fill('input[formControlName="lastName"]', 'Test');
    await page.fill('input[formControlName="email"]', email);
    await page.fill('input[formControlName="phone"]', '+1234567890');
    await page.click('button:has-text("Save")');

    // Step 3: Wait and verify update appears in second window
    await page2.waitForTimeout(2000); // Wait for WebSocket update
    await page2.fill('input[placeholder*="Search"]', email);
    await page2.waitForTimeout(500);

    // Should see the new driver in second window
    await expect(page2.locator(`text=${email}`)).toBeVisible({ timeout: 5000 });

    await page2.close();
  });

  test('accessibility workflow - keyboard navigation', async ({ page }) => {
    await page.goto(`${BASE_URL}/drivers`);

    // Step 1: Tab through interactive elements
    await page.keyboard.press('Tab'); // Focus search input
    await expect(page.locator('input[placeholder*="Search"]')).toBeFocused();

    await page.keyboard.press('Tab'); // Focus filter dropdown
    await page.keyboard.press('Tab'); // Focus "Add Driver" button

    // Step 2: Activate "Add Driver" with keyboard
    await page.keyboard.press('Enter');
    await expect(page.locator('.dialog-title')).toBeVisible();

    // Step 3: Navigate form with Tab
    await page.keyboard.type('John');
    await page.keyboard.press('Tab');
    await page.keyboard.type('Doe');

    // Step 4: Cancel with Escape
    await page.keyboard.press('Escape');
    await expect(page.locator('.dialog-title')).not.toBeVisible();
  });

  test('mobile responsive workflow', async ({ page }) => {
    // Set mobile viewport
    await page.setViewportSize({ width: 375, height: 667 });
    await page.goto(`${BASE_URL}/drivers`);

    // Step 1: Verify mobile menu
    await expect(page.locator('.mobile-menu-button')).toBeVisible();
    await page.click('.mobile-menu-button');
    await expect(page.locator('.mobile-menu')).toBeVisible();

    // Step 2: Verify table is responsive (cards view)
    const hasCards = await page.locator('.driver-card').count() > 0;
    const hasTable = await page.locator('.driver-row').count() > 0;
    expect(hasCards || hasTable).toBe(true);

    // Step 3: Verify mobile dialog
    await page.click('button:has-text("Add Driver")');
    const dialog = page.locator('.mat-dialog-container');
    await expect(dialog).toBeVisible();

    // Dialog should be full-screen on mobile
    const boundingBox = await dialog.boundingBox();
    expect(boundingBox?.width).toBeGreaterThan(350);
  });
});
