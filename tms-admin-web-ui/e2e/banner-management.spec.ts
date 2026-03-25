import { test, expect } from '@playwright/test';

test.describe('Banner Management E2E Tests', () => {
  test.beforeEach(async ({ page }) => {
    // Navigate directly to banner management page
    await page.goto('/admin/banner-management');
    await page.waitForLoadState('networkidle');

    // Wait for the page to load completely
    await expect(page.getByRole('heading', { name: 'Banner Management' })).toBeVisible({ timeout: 10000 });
    await page.waitForTimeout(1000); // Additional stability wait
  });

  test('should display the banner list and allow creation, editing, and deletion', async ({ page }) => {
    // 1. Verify initial state
    await expect(page.locator('table')).toBeVisible();
    const initialRowCount = await page.locator('tbody tr').count();

    // 2. Create a new banner
    await page.getByRole('button', { name: 'Create New Banner' }).click();
    await expect(page.getByRole('heading', { name: 'Create New Banner' })).toBeVisible();

    const newBannerTitle = `Test Banner ${Date.now()}`;
    await page.getByLabel('Title (English) *').fill(newBannerTitle);
    await page.getByLabel('Title (Khmer)').fill('តេស្តបដា');
    await page.getByLabel('Category *').selectOption('promotion');

    // Mock upload
    await page.getByLabel('Banner Image *').fill('/uploads/images/banners/test-image.jpg');

    await page.getByRole('button', { name: 'Create Banner' }).click();

    // 3. Verify the new banner is in the table
    await expect(page.getByRole('heading', { name: 'Banner Management' })).toBeVisible();
    await expect(page.locator('table')).toContainText(newBannerTitle);
    const newRowCount = await page.locator('tbody tr').count();
    expect(newRowCount).toBe(initialRowCount + 1);

    // 4. Edit the banner
    const bannerRow = page.locator('tbody tr').filter({ hasText: newBannerTitle });
    await bannerRow.getByRole('button', { name: 'Edit' }).click();

    await expect(page.getByRole('heading', { name: 'Edit Banner' })).toBeVisible();
    const updatedBannerTitle = `${newBannerTitle} - Edited`;
    await page.getByLabel('Title (English) *').fill(updatedBannerTitle);
    await page.getByRole('button', { name: '💾 Update Banner' }).click();

    // 5. Verify the edit
    await expect(page.locator('table')).toContainText(updatedBannerTitle);
    await expect(page.locator('table')).not.toContainText(newBannerTitle);

    // 6. Filter banners
    await page.getByLabel('Filter by Category').selectOption('promotion');
    await expect(page.locator('tbody tr').filter({ hasText: updatedBannerTitle })).toBeVisible();

    await page.getByLabel('Filter by Category').selectOption('safety');
    await expect(page.locator('tbody tr').filter({ hasText: updatedBannerTitle })).not.toBeVisible();

    await page.getByLabel('Filter by Category').selectOption(''); // All

    // 7. Toggle active status
    const updatedBannerRow = page.locator('tbody tr').filter({ hasText: updatedBannerTitle });
    const initialStatus = await updatedBannerRow.locator('td:nth-child(4) span').textContent();
    await updatedBannerRow.getByRole('button', { name: initialStatus.trim() === 'Active' ? 'Deactivate' : 'Activate' }).click();
    // Wait for potential async update, then check status
    await page.waitForTimeout(500);
    const newStatus = await updatedBannerRow.locator('td:nth-child(4) span').textContent();
    expect(newStatus.trim()).not.toBe(initialStatus.trim());

    // 8. Delete the banner
    page.on('dialog', dialog => dialog.accept());
    await updatedBannerRow.getByRole('button', { name: 'Delete' }).click();

    // 9. Verify deletion
    await expect(page.locator('table')).not.toContainText(updatedBannerTitle);
    const finalRowCount = await page.locator('tbody tr').count();
    expect(finalRowCount).toBe(initialRowCount);
  });
});
