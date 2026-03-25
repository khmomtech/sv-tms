import { test, expect } from '@playwright/test';

const BASE_URL = process.env['BASE_URL'] || 'http://localhost:4200';

test.describe('Vehicle Duplicate License Plate Handling', () => {
  test.beforeEach(async ({ page }) => {
    await page.goto(`${BASE_URL}/login`);
    await page.fill('input[name="username"]', 'admin');
    await page.fill('input[name="password"]', 'admin123');
    await page.click('button[type="submit"]');
    await page.waitForURL(/\/(drivers|dashboard)/);
  });

  test('shows field error and focuses license plate on duplicate', async ({ page }) => {
    // Create a vehicle with a unique plate
    const timestamp = Date.now();
    const plate = `DUPLICATE${timestamp}`;
    await page.goto(`${BASE_URL}/fleet/vehicles`);
    await page.click('button:has-text("Add Vehicle")');
    await page.fill('input[formControlName="licensePlate"]', plate);
    await page.fill('input[formControlName="vin"]', `1HGCM82633A${timestamp}`.slice(0, 17));
    await page.fill('input[formControlName="model"]', 'TestModel');
    await page.fill('input[formControlName="manufacturer"]', 'TestManu');
    await page.fill('input[formControlName="year"]', '2024');
    await page.click('button[type="submit"]');
    await expect(page.locator('.text-green-800')).toBeVisible();
    // Try to create again with the same plate
    await page.click('button:has-text("Add Vehicle")');
    await page.fill('input[formControlName="licensePlate"]', plate);
    await page.fill('input[formControlName="vin"]', `1HGCM82633B${timestamp}`.slice(0, 17));
    await page.fill('input[formControlName="model"]', 'TestModel2');
    await page.fill('input[formControlName="manufacturer"]', 'TestManu2');
    await page.fill('input[formControlName="year"]', '2024');
    await page.click('button[type="submit"]');
    // Should see field error and input focused
    const error = page.locator('input[formControlName="licensePlate"] + p.text-red-600');
    await expect(error).toContainText('already exists');
    const isFocused = await page.evaluate(() => document.activeElement?.getAttribute('formcontrolname'));
    expect(isFocused).toBe('licensePlate');
  });
});
