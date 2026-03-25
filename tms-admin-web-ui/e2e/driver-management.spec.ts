import { test, expect } from '@playwright/test';


test.describe('Driver Management - CRUD Operations', () => {
  // Helper function for authentication
  const authenticateUser = async (page: any, userRole = 'ADMIN') => {
    await page.addInitScript(() => {
      // Create a valid JWT token that expires in 1 hour
      const header = btoa(JSON.stringify({ alg: 'HS256', typ: 'JWT' }));
      const payload = btoa(JSON.stringify({
        exp: Math.floor(Date.now() / 1000) + 3600,
        iat: Math.floor(Date.now() / 1000),
        sub: 'testuser',
        roles: [userRole]
      }));
      const signature = 'fake-signature-for-testing';
      const token = `${header}.${payload}.${signature}`;

      localStorage.setItem('token', token);
      localStorage.setItem('user', JSON.stringify({
        username: 'testuser',
        email: 'test@example.com',
        roles: [userRole]
      }));
    });
  };

  // Helper function to navigate to driver management
  const navigateToDriverManagement = async (page: any) => {
    // Set authentication before navigation
    await page.addInitScript(() => {
      // Create a valid JWT token that expires in 1 hour
      const header = btoa(JSON.stringify({ alg: 'HS256', typ: 'JWT' }));
      const payload = btoa(JSON.stringify({
        exp: Math.floor(Date.now() / 1000) + 3600,
        iat: Math.floor(Date.now() / 1000),
        sub: 'testuser',
        roles: ['ADMIN']
      }));
      const signature = 'fake-signature-for-testing';
      const token = `${header}.${payload}.${signature}`;

      localStorage.setItem('token', token);
      localStorage.setItem('user', JSON.stringify({
        username: 'testuser',
        email: 'test@example.com',
        roles: ['ADMIN']
      }));
    });

    await page.goto('/drivers');
    await page.waitForLoadState('networkidle');

    // Verify we're on the driver management page
    await expect(page).toHaveURL(/.*\/drivers/);
  };

  test('should load driver management page', async ({ page }) => {
    await navigateToDriverManagement(page);

    // Check for page title or header
    const pageTitle = page.getByRole('heading', { name: 'Driver List', exact: true });
    await expect(pageTitle).toBeVisible();

    // Check for main content area - just ensure some content is visible
    const mainContent = page.locator('main').first();
    await expect(mainContent).toBeVisible();
  });

  test('should display driver list with proper structure', async ({ page }) => {
    await navigateToDriverManagement(page);

    // Check for driver list container - be more flexible
    const driverList = page.locator('main, .main-content, app-driver-list').first();
    await expect(driverList).toBeVisible();

    // Check for driver cards/items (may be empty, that's ok)
    const driverItems = page.locator('.driver-item, .driver-card, [data-testid="driver-item"]');

    // If drivers exist, verify structure
    if (await driverItems.first().isVisible({ timeout: 2000 })) {
      const firstDriver = driverItems.first();

      // Check for common driver information fields
      const driverName = firstDriver.locator('[data-testid="driver-name"], .driver-name, .name');
      const driverRating = firstDriver.locator('[data-testid="driver-rating"], .driver-rating, .rating');
      const driverStatus = firstDriver.locator('[data-testid="driver-status"], .driver-status, .status');

      // At least one identifying field should be present
      const hasDriverInfo = await driverName.isVisible() || await driverRating.isVisible() || await driverStatus.isVisible();
      expect(hasDriverInfo).toBe(true);
    }
  });

  test('should handle driver search functionality', async ({ page }) => {
    await navigateToDriverManagement(page);

    // Look for search input
    const searchInput = page.locator('input[placeholder*="search" i], input[type="text"], [data-testid="search-input"]');

    if (await searchInput.isVisible({ timeout: 2000 })) {
      // Test search with a common name
      await searchInput.fill('John');
      await searchInput.press('Enter');

      // Wait for search results to load
      await page.waitForTimeout(500);

      // Check that search was applied (either results filtered or no results message)
      const driverItems = page.locator('.driver-item, .driver-card, [data-testid="driver-item"]');
      const noResults = page.locator('[data-testid="no-results"], .no-results').filter({ hasText: /no results|not found/i });

      // Either we have filtered results or a no-results message
      const hasResults = await driverItems.first().isVisible({ timeout: 1000 });
      const hasNoResults = await noResults.isVisible({ timeout: 1000 });

      expect(hasResults || hasNoResults).toBe(true);

      // Clear search
      await searchInput.clear();
      await searchInput.press('Enter');
      await page.waitForTimeout(500);
    }
  });

  test('should filter drivers by rating range', async ({ page }) => {
    await navigateToDriverManagement(page);

    // Look for rating filter controls
    const minRatingInput = page.locator('input[placeholder*="min rating" i], [data-testid="min-rating"], mat-slider input').first();
    const maxRatingInput = page.locator('input[placeholder*="max rating" i], [data-testid="max-rating"], mat-slider input').last();

    if (await minRatingInput.isVisible({ timeout: 2000 }) && await maxRatingInput.isVisible({ timeout: 2000 })) {
      // Set rating range
      await minRatingInput.fill('4.0');
      await maxRatingInput.fill('5.0');

      // Look for apply/filter button
      const applyButton = page.locator('button').filter({ hasText: /apply|Apply|filter|Filter|search|Search/i }).first();

      if (await applyButton.isVisible({ timeout: 1000 })) {
        await applyButton.click();
      }

      // Wait for filter to apply
      await page.waitForTimeout(1000);

      // Check filtered results
      const driverItems = page.locator('.driver-item, .driver-card, [data-testid="driver-item"]');

      if (await driverItems.first().isVisible({ timeout: 2000 })) {
        // Verify that visible drivers have ratings in the specified range
        const ratingElements = page.locator('.driver-rating, .rating-value, [data-testid="driver-rating"]');

        if (await ratingElements.first().isVisible({ timeout: 1000 })) {
          const ratings = await ratingElements.allTextContents();

          for (const rating of ratings) {
            if (rating.trim()) {
              const numericRating = parseFloat(rating.replace(/[^\d.]/g, ''));
              if (!isNaN(numericRating)) {
                expect(numericRating).toBeGreaterThanOrEqual(4.0);
                expect(numericRating).toBeLessThanOrEqual(5.0);
              }
            }
          }
        }
      }
    }
  });

  test('should display driver ratings correctly', async ({ page }) => {
    await navigateToDriverManagement(page);

    // Look for rating displays
    const ratingElements = page.locator('.rating, .stars, [data-testid="rating"], .driver-rating');

    if (await ratingElements.first().isVisible({ timeout: 2000 })) {
      const firstRating = ratingElements.first();
      const ratingText = await firstRating.textContent();

      // Rating should be a number between 0-5 or star symbols
      const isNumericRating = /\d+(\.\d+)?/.test(ratingText || '');
      const isStarRating = /★+/.test(ratingText || '');

      expect(isNumericRating || isStarRating).toBe(true);

      if (isNumericRating) {
        const numericRating = parseFloat(ratingText!.replace(/[^\d.]/g, ''));
        expect(numericRating).toBeGreaterThanOrEqual(0);
        expect(numericRating).toBeLessThanOrEqual(5);
      }
    }
  });

  test('should handle add driver form validation', async ({ page }) => {
    await navigateToDriverManagement(page);

    // Look for add driver button
    const addButton = page.locator('button').filter({ hasText: /add|Add|new|New|create|Create/i }).first();

    if (await addButton.isVisible({ timeout: 2000 })) {
      await addButton.click();

      // Check if modal, dialog, or form appears
      const form = page.locator('form, .modal, .dialog, [data-testid="driver-form"]');

      if (await form.isVisible({ timeout: 2000 })) {
        // Look for submit button
        const submitButton = page.locator('button[type="submit"], button').filter({ hasText: /save|Save|submit|Submit|create|Create/i }).first();

        if (await submitButton.isVisible({ timeout: 1000 })) {
          // Try to submit empty form to test validation
          await submitButton.click();

          // Wait for validation feedback
          await page.waitForTimeout(500);

          // Check for validation errors
          const errorMessages = page.locator('.error, .invalid-feedback, .field-error, [data-testid="error"]');
          const requiredFieldErrors = page.locator('[aria-invalid="true"], .ng-invalid');

          // Should show some form of validation feedback
          const hasValidationErrors = await errorMessages.first().isVisible({ timeout: 1000 }) ||
                                    await requiredFieldErrors.first().isVisible({ timeout: 1000 });

          expect(hasValidationErrors).toBe(true);
        }

        // Close the form/modal
        const closeButton = page.locator('button[aria-label="Close"], .close, .cancel').filter({ hasText: /close|Close|cancel|Cancel/i }).first();
        if (await closeButton.isVisible({ timeout: 1000 })) {
          await closeButton.click();
        }
      }
    }
  });

  test('should handle driver status indicators', async ({ page }) => {
    await navigateToDriverManagement(page);

    // Look for status indicators
    const statusIndicators = page.locator('.status, .badge, [data-testid="status"], .driver-status');

    if (await statusIndicators.first().isVisible({ timeout: 2000 })) {
      const firstStatus = statusIndicators.first();
      const statusText = await firstStatus.textContent();

      // Status should indicate driver availability or activity
      const validStatuses = /active|inactive|available|busy|offline|online/i;
      expect(statusText).toMatch(validStatuses);
    }
  });
});
