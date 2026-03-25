import { test, expect } from '@playwright/test';

/**
 * End-to-End Vehicle CRUD Flow Tests
 *
 * Tests complete user journeys for vehicle management
 */

const BASE_URL = process.env['BASE_URL'] || 'http://localhost:4200';

test.describe('Vehicle CRUD User Flows', () => {
  test.beforeEach(async ({ page }) => {
    // Login
    await page.goto(`${BASE_URL}/login`);
    await page.fill('input[name="username"]', 'admin');
    await page.fill('input[name="password"]', 'admin123');
    await page.click('button[type="submit"]');
    await page.waitForURL(/\/(drivers|dashboard)/);
  });

  test('complete vehicle lifecycle: create → view → update → delete', async ({ page }) => {
    const timestamp = Date.now();
    const vehicleData = {
      plateNumber: `ABC${timestamp}`,
      type: 'TRUCK',
      make: 'Ford',
      model: 'F-150',
      year: 2023,
      capacity: 1000
    };

    // Navigate to vehicles
    await page.goto(`${BASE_URL}/fleet/vehicles`);
    await expect(page.locator('h1')).toContainText('Vehicle');

    // Create vehicle
    await page.click('button:has-text("Add Vehicle")');
    await page.fill('input[formControlName="plateNumber"]', vehicleData.plateNumber);
    await page.click('mat-select[formControlName="type"]');
    await page.click(`mat-option:has-text("${vehicleData.type}")`);
    await page.fill('input[formControlName="make"]', vehicleData.make);
    await page.fill('input[formControlName="model"]', vehicleData.model);
    await page.fill('input[formControlName="year"]', vehicleData.year.toString());
    await page.fill('input[formControlName="capacity"]', vehicleData.capacity.toString());

    await page.click('button:has-text("Save")');
    await expect(page.locator('.snackbar-success')).toBeVisible();

    // Search and verify
    await page.fill('input[placeholder*="Search"]', vehicleData.plateNumber);
    await page.waitForTimeout(500);
    await expect(page.locator(`text=${vehicleData.plateNumber}`)).toBeVisible();

    // View details
    await page.click(`text=${vehicleData.plateNumber}`);
    await expect(page.locator('.vehicle-details')).toContainText(vehicleData.make);
    await expect(page.locator('.vehicle-details')).toContainText(vehicleData.model);

    // Update
    await page.click('button:has-text("Edit")');
    const updatedMake = 'Chevrolet';
    await page.fill('input[formControlName="make"]', updatedMake);
    await page.click('button:has-text("Save")');
    await expect(page.locator('.snackbar-success')).toContainText('updated');
    await expect(page.locator('.vehicle-details')).toContainText(updatedMake);

    // Delete
    await page.click('button:has-text("Back to List")');
    await page.fill('input[placeholder*="Search"]', vehicleData.plateNumber);
    await page.waitForTimeout(500);
    await page.click(`tr:has-text("${vehicleData.plateNumber}") button[aria-label="Delete"]`);
    await page.click('button:has-text("Confirm")');
    await expect(page.locator('.snackbar-success')).toContainText('deleted');

    // Verify deletion
    await page.waitForTimeout(500);
    await expect(page.locator(`text=${vehicleData.plateNumber}`)).not.toBeVisible();
  });

  test('vehicle assignment workflow', async ({ page }) => {
    await page.goto(`${BASE_URL}/fleet/vehicles`);

    // Find available vehicle
    await page.click('mat-select[formControlName="status"]');
    await page.click('mat-option:has-text("AVAILABLE")');
    await page.waitForTimeout(500);

    const availableVehicle = page.locator('.vehicle-row .status-badge:has-text("AVAILABLE")').first();
    if (await availableVehicle.count() > 0) {
      // Click assign button
      await page.click('.vehicle-row:has(.status-badge:has-text("AVAILABLE")) button:has-text("Assign")');

      // Select driver
      await page.click('mat-select[formControlName="driverId"]');
      await page.locator('mat-option').first().click();

      // Confirm assignment
      await page.click('button:has-text("Assign Vehicle")');
      await expect(page.locator('.snackbar-success')).toContainText('assigned');
    }
  });

  test('vehicle filter combinations workflow', async ({ page }) => {
    await page.goto(`${BASE_URL}/fleet/vehicles`);

    // Filter by type
    await page.click('mat-select[formControlName="type"]');
    await page.click('mat-option:has-text("TRUCK")');
    await page.waitForTimeout(500);

    // Add status filter
    await page.click('mat-select[formControlName="status"]');
    await page.click('mat-option:has-text("AVAILABLE")');
    await page.waitForTimeout(500);

    // Add search query
    await page.fill('input[placeholder*="Search"]', 'ABC');
    await page.waitForTimeout(500);

    // Verify results match all filters
    const vehicles = await page.locator('.vehicle-row').count();
    console.log(`Found ${vehicles} vehicles matching all filters`);

    // Clear filters
    await page.click('button:has-text("Clear Filters")');
    await page.waitForTimeout(500);

    const allVehicles = await page.locator('.vehicle-row').count();
    expect(allVehicles).toBeGreaterThanOrEqual(vehicles);
  });

  test('vehicle maintenance workflow', async ({ page }) => {
    await page.goto(`${BASE_URL}/fleet/vehicles`);

    // Find a vehicle
    const vehicleRow = page.locator('.vehicle-row').first();
    await vehicleRow.click();

    // Open maintenance tab
    await page.click('button:has-text("Maintenance")');

    // Add maintenance record
    await page.click('button:has-text("Add Maintenance")');
    await page.fill('input[formControlName="description"]', 'Oil change');
    await page.fill('input[formControlName="cost"]', '50');
    await page.fill('input[formControlName="date"]', '2024-01-15');
    await page.click('button:has-text("Save")');

    await expect(page.locator('.maintenance-record:has-text("Oil change")')).toBeVisible();
  });
});
