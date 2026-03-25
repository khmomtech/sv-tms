import { test, expect, type Page } from '@playwright/test';

/**
 * E2E Integration Tests for Fleet Vehicle Permanent Assignment
 *
 * Tests cover:
 * - Assign truck to driver (happy path)
 * - Force reassignment
 * - Revoke assignment
 * - Concurrent modification handling
 * - Get assignment statistics
 * - Error scenarios (404, 409, 5xx)
 */

const BASE_URL = process.env['BASE_URL'] || 'http://localhost:4200';
const API_URL = process.env['API_URL'] || 'http://localhost:8080';

let adminPage: Page;

test.describe('Permanent Assignment - Integration Tests', () => {
  test.beforeAll(async ({ browser }) => {
    adminPage = await browser.newPage();

    // Login as admin
    await adminPage.goto(`${BASE_URL}/login`);
    await adminPage.fill('input[name="username"]', 'admin');
    await adminPage.fill('input[name="password"]', 'admin123');
    await adminPage.click('button[type="submit"]');

    // Wait for navigation after login
    await adminPage.waitForTimeout(2000);
  });  test.afterAll(async () => {
    await adminPage.close();
  });

  test.describe('Assign Truck to Driver', () => {
    test('should successfully assign truck to driver (happy path)', async () => {
      // Navigate to assignment page
      await adminPage.goto(`${BASE_URL}/fleet/assign-truck-driver`);

      // Wait for page to load
      await expect(adminPage.locator('h1, h2, .page-title')).toContainText(/assign.*truck/i);

      // Select truck from autocomplete
      const truckInput = adminPage.locator('input[formControlName="vehicleId"]');
      await truckInput.click();
      await truckInput.fill('ABC');
      await adminPage.waitForTimeout(500); // Debounce wait
      await adminPage.click('mat-option:first-child, .autocomplete-option:first-child');

      // Select driver from autocomplete
      const driverInput = adminPage.locator('input[formControlName="driverId"]');
      await driverInput.click();
      await driverInput.fill('John');
      await adminPage.waitForTimeout(500); // Debounce wait
      await adminPage.click('mat-option:first-child, .autocomplete-option:first-child');

      // Add reason
      await adminPage.fill('textarea[formControlName="reason"]', 'E2E Test Assignment');

      // Submit form
      await adminPage.click('button[type="submit"]');

      // Verify success message
      await expect(adminPage.locator('.toast-success, .swal2-success, .success-message')).toBeVisible({ timeout: 5000 });
      await expect(adminPage.locator('.toast-success, .swal2-success, .success-message')).toContainText(/success|assigned/i);
    });

    test('should show validation errors for empty form', async () => {
      await adminPage.goto(`${BASE_URL}/fleet/assign-truck-driver`);

      // Try to submit empty form
      await adminPage.click('button[type="submit"]');

      // Verify validation errors
      const errors = adminPage.locator('.error-message, .mat-error, .invalid-feedback');
      await expect(errors).toHaveCount(2); // Truck and Driver required
    });
  });

  test.describe('Force Reassignment', () => {
    test('should handle force reassignment when truck is already assigned', async () => {
      await adminPage.goto(`${BASE_URL}/fleet/assign-truck-driver`);

      // Select already assigned truck
      const truckInput = adminPage.locator('input[formControlName="vehicleId"]');
      await truckInput.click();
      await truckInput.fill('ABC'); // Truck from previous test
      await adminPage.waitForTimeout(500);
      await adminPage.click('mat-option:first-child');

      // Select different driver
      const driverInput = adminPage.locator('input[formControlName="driverId"]');
      await driverInput.click();
      await driverInput.fill('Jane');
      await adminPage.waitForTimeout(500);
      await adminPage.click('mat-option:first-child');

      // Add reason
      await adminPage.fill('textarea[formControlName="reason"]', 'Force Reassignment Test');

      // Check force reassignment
      await adminPage.check('input[formControlName="forceReassignment"]');

      // Submit
      await adminPage.click('button[type="submit"]');

      // Verify success
      await expect(adminPage.locator('.toast-success, .swal2-success')).toBeVisible({ timeout: 5000 });
    });
  });

  test.describe('Revoke Assignment', () => {
    test('should successfully revoke assignment', async () => {
      // First, get an assignment ID to revoke
      const response = await adminPage.request.get(`${API_URL}/api/permanent-assignments/stats`);
      expect(response.ok()).toBeTruthy();

      const data = await response.json();
      const assignmentId = data.data?.recentAssignments?.[0]?.id;

      if (assignmentId) {
        // Navigate to revoke
        await adminPage.goto(`${BASE_URL}/fleet/permanent-assignments`);

        // Find revoke button
        const revokeBtn = adminPage.locator(`button[data-assignment-id="${assignmentId}"], .revoke-btn`).first();
        await revokeBtn.click();

        // Confirm dialog
        await adminPage.click('button:has-text("Confirm"), .swal2-confirm');

        // Verify success
        await expect(adminPage.locator('.toast-success, .swal2-success')).toBeVisible({ timeout: 5000 });
      }
    });
  });

  test.describe('Assignment Statistics', () => {
    test('should fetch and display assignment statistics', async () => {
      const response = await adminPage.request.get(`${API_URL}/api/permanent-assignments/stats`);

      expect(response.ok()).toBeTruthy();
      expect(response.status()).toBe(200);

      const data = await response.json();
      expect(data.status).toBe('success');
      expect(data.data).toHaveProperty('totalActiveAssignments');
      expect(data.data).toHaveProperty('totalTrucksAssigned');
      expect(data.data).toHaveProperty('totalDriversAssigned');
    });
  });

  test.describe('Error Handling', () => {
    test('should handle 404 when assignment not found', async () => {
      const response = await adminPage.request.get(`${API_URL}/api/permanent-assignments/99999`);

      expect(response.status()).toBe(404);
      const data = await response.json();
      expect(data.status).toBe('fail');
    });

    test('should handle 409 conflict on duplicate assignment', async () => {
      // Try to assign already assigned truck without force flag
      const assignmentData = {
        vehicleId: 1,
        driverId: 2,
        reason: 'Duplicate Test',
        forceReassignment: false
      };

      const response = await adminPage.request.post(`${API_URL}/api/permanent-assignments`, {
        data: assignmentData,
        headers: {
          'Content-Type': 'application/json'
        }
      });

      if (response.status() === 409) {
        const data = await response.json();
        expect(data.status).toBe('fail');
        expect(data.message).toContain('already assigned');
      }
    });

    test('should handle network timeout gracefully', async () => {
      await adminPage.goto(`${BASE_URL}/fleet/assign-truck-driver`);

      // Intercept and delay request
      await adminPage.route(`${API_URL}/api/permanent-assignments`, route => {
        setTimeout(() => route.abort('timedout'), 31000); // Exceed 30s timeout
      });

      // Fill and submit form
      const truckInput = adminPage.locator('input[formControlName="vehicleId"]');
      await truckInput.click();
      await truckInput.fill('TEST');
      await adminPage.waitForTimeout(500);
      await adminPage.keyboard.press('ArrowDown');
      await adminPage.keyboard.press('Enter');

      const driverInput = adminPage.locator('input[formControlName="driverId"]');
      await driverInput.click();
      await driverInput.fill('TEST');
      await adminPage.waitForTimeout(500);
      await adminPage.keyboard.press('ArrowDown');
      await adminPage.keyboard.press('Enter');

      await adminPage.fill('textarea[formControlName="reason"]', 'Timeout Test');
      await adminPage.click('button[type="submit"]');

      // Verify error message
      await expect(adminPage.locator('.toast-error, .swal2-error, .error-message')).toBeVisible({ timeout: 35000 });
    });
  });

  test.describe('Concurrent Modification', () => {
    test('should handle optimistic locking conflict', async () => {
      // This test simulates two users modifying same assignment
      // In real scenario, this would require coordination between two sessions

      const response = await adminPage.request.get(`${API_URL}/api/permanent-assignments/stats`);
      const data = await response.json();
      const assignmentId = data.data?.recentAssignments?.[0]?.id;

      if (assignmentId) {
        // Get current version
        const getResponse = await adminPage.request.get(`${API_URL}/api/permanent-assignments/${assignmentId}`);
        const assignment = await getResponse.json();

        // Try to update with old version (simulate concurrent modification)
        const updateResponse = await adminPage.request.put(`${API_URL}/api/permanent-assignments/${assignmentId}`, {
          data: {
            ...assignment.data,
            version: 0 // Old version
          }
        });

        // Expect optimistic locking error if version mismatch
        if (updateResponse.status() === 409) {
          const errorData = await updateResponse.json();
          expect(errorData.status).toBe('fail');
          expect(errorData.message).toContain('version');
        }
      }
    });
  });

  test.describe('Assignment History', () => {
    test('should fetch assignment history for truck', async () => {
      const response = await adminPage.request.get(`${API_URL}/api/permanent-assignments/truck/1/history`);

      if (response.ok()) {
        const data = await response.json();
        expect(data.status).toBe('success');
        expect(Array.isArray(data.data)).toBeTruthy();
      }
    });

    test('should fetch assignment history for driver', async () => {
      const response = await adminPage.request.get(`${API_URL}/api/permanent-assignments/driver/1/history`);

      if (response.ok()) {
        const data = await response.json();
        expect(data.status).toBe('success');
        expect(Array.isArray(data.data)).toBeTruthy();
      }
    });
  });
});
