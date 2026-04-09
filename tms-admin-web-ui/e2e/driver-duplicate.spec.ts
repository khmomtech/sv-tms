import { test, expect } from '@playwright/test';
import { mockAuthentication, TEST_USERS } from './helpers/auth.helper';

/*
  Verifies the new driver creation form detects duplicate phone numbers
  and surfaces the warning message added in driver-detail.component.html.
*/
test.describe('Driver duplicate warning', () => {
  test('warns when phone already exists while creating a driver', async ({ page }) => {
    await mockAuthentication(page, TEST_USERS.admin);
    await page.goto('/drivers');
    await page.waitForLoadState('networkidle');

    const newDriverButton = page.getByRole('button', { name: /new driver/i }).first();
    await expect(newDriverButton).toBeVisible();
    await newDriverButton.click();

    await expect(page.getByLabel('First Name')).toBeVisible();
    await page.getByLabel('First Name').fill('Duplicate');
    await page.getByLabel('Last Name').fill('Driver');

    const phoneInput = page.getByLabel('Phone');
    await phoneInput.fill('+855123456789');

    // Inline warning should appear within ~400ms after debounce time
    const warning = page.getByText(/A driver already exists with this number/i);
    await expect(warning).toBeVisible({ timeout: 2000 });

    // Attempt to submit -- the feature blocks the request and shows the same message again
    await page.getByRole('button', { name: /save|update/i }).click();
    await expect(warning).toBeVisible({ timeout: 2000 });

    // Ensure the form stays open (phone value still set)
    await expect(phoneInput).toHaveValue('+855123456789');
  });
});
