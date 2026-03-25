import { test, expect } from '@playwright/test';
import { loginViaAPI, TEST_USERS } from './helpers/auth.helper';

test.describe('Vehicle Filters', () => {
  test.beforeEach(async ({ page }) => {
    await loginViaAPI(page, TEST_USERS.dispatcher);
    await page.goto('/vehicles');
    await page.waitForSelector('[data-test="vehicle-search-input"]', { timeout: 10000 });
  });

  test('should include search + dropdown filters in API request', async ({ page }) => {
    await page.fill('[data-test="vehicle-search-input"]', 'E2E123');
    await page.selectOption('[data-test="vehicle-status-filter"]', 'MAINTENANCE');
    await page.selectOption('[data-test="vehicle-truck-size-filter"]', 'MEDIUM_TRUCK');
    await page.selectOption('[data-test="vehicle-assignment-filter"]', 'assigned');

    const requestPromise = page.waitForRequest('**/api/admin/vehicles/search**');
    await page.click('[data-test="vehicle-apply-filters"]');
    const request = await requestPromise;

    const url = new URL(request.url());
    expect(url.pathname).toContain('/api/admin/vehicles/search');
    expect(url.searchParams.get('search')).toBe('E2E123');
    expect(url.searchParams.get('status')).toBe('MAINTENANCE');
    expect(url.searchParams.get('truckSize')).toBe('MEDIUM_TRUCK');
    expect(url.searchParams.get('assigned')).toBe('true');
    expect(url.searchParams.get('page')).toBe('0');
  });

  test('reset filters clears inputs and re-fetches defaults', async ({ page }) => {
    await page.fill('[data-test="vehicle-search-input"]', 'RESET');
    await page.selectOption('[data-test="vehicle-status-filter"]', 'AVAILABLE');
    const firstRequest = page.waitForRequest('**/api/admin/vehicles/search**');
    await page.click('[data-test="vehicle-apply-filters"]');
    await firstRequest;

    await page.click('[data-test="vehicle-reset-filters"]');

    expect(await page.locator('[data-test="vehicle-search-input"]').inputValue()).toBe('');
    expect(await page.locator('[data-test="vehicle-status-filter"]').inputValue()).toBe('');
    expect(await page.locator('[data-test="vehicle-truck-size-filter"]').inputValue()).toBe('');
    expect(await page.locator('[data-test="vehicle-assignment-filter"]').inputValue()).toBe('');

    const resetRequestPromise = page.waitForRequest('**/api/admin/vehicles/search**');
    await page.click('[data-test="vehicle-apply-filters"]');
    const resetRequest = await resetRequestPromise;

    const resetUrl = new URL(resetRequest.url());
    expect(resetUrl.searchParams.has('search')).toBe(false);
    expect(resetUrl.searchParams.has('status')).toBe(false);
    expect(resetUrl.searchParams.has('truckSize')).toBe(false);
    expect(resetUrl.searchParams.has('assigned')).toBe(false);
    expect(resetUrl.searchParams.get('page')).toBe('0');
  });
});
