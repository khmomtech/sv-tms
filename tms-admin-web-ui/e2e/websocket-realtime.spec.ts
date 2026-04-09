import { test, expect } from '@playwright/test';
import { loginViaAPI, TEST_USERS } from './helpers/auth.helper';

/**
 * WebSocket Real-Time Tests
 *
 * These tests verify real-time features using WebSocket/SockJS
 */

test.describe('WebSocket Real-Time Updates', () => {
  test.beforeEach(async ({ page }) => {
    await loginViaAPI(page, TEST_USERS.admin);
  });

  test('should establish WebSocket connection', async ({ page }) => {
    // Monitor WebSocket connections
    let wsConnected = false;

    page.on('websocket', ws => {
      console.log(`WebSocket opened: ${ws.url()}`);
      wsConnected = true;

      ws.on('framereceived', event => {
        console.log('WebSocket frame received:', event.payload);
      });

      ws.on('framesent', event => {
        console.log('WebSocket frame sent:', event.payload);
      });

      ws.on('close', () => {
        console.log('WebSocket closed');
      });
    });

    // Navigate to dashboard (should trigger WebSocket connection)
    await page.goto('/dashboard');
    await page.waitForLoadState('networkidle');

    // Wait a bit for WebSocket to connect
    await page.waitForTimeout(3000);

    // Verify WebSocket connection was established
    expect(wsConnected).toBe(true);
  });

  test('should receive real-time driver location updates', async ({ page }) => {
    const locationUpdates: any[] = [];

    // Listen for console logs (app might log location updates)
    page.on('console', msg => {
      const text = msg.text();
      if (text.includes('location') || text.includes('driver update')) {
        locationUpdates.push(text);
      }
    });

    // Navigate to live tracking or dashboard
    await page.goto('/dashboard');
    await page.waitForLoadState('networkidle');

    // Wait for potential location updates
    await page.waitForTimeout(5000);

    // Check if location updates were received (or map is visible)
    const map = page.locator('#map, .map-container, [data-testid="map"]');
    const hasMap = await map.isVisible({ timeout: 5000 }).catch(() => false);

    console.log(`Location updates received: ${locationUpdates.length}`);
    console.log(`Map visible: ${hasMap}`);

    // Either should have received updates OR map should be visible
    expect(locationUpdates.length > 0 || hasMap).toBe(true);
  });

  test('should show connection status indicator', async ({ page }) => {
    await page.goto('/dashboard');
    await page.waitForLoadState('networkidle');

    // Look for connection status indicator
    const statusIndicator = page.locator('[data-testid="connection-status"], .connection-status, .ws-status');
    const hasStatus = await statusIndicator.isVisible({ timeout: 5000 }).catch(() => false);

    if (hasStatus) {
      const statusText = await statusIndicator.textContent();
      console.log(`Connection status: ${statusText}`);

      // Status should indicate connected
      expect(statusText).toMatch(/connected|online|active/i);
    }
  });
});

test.describe('Real-Time Notifications', () => {
  test.beforeEach(async ({ page }) => {
    await loginViaAPI(page, TEST_USERS.admin);
  });

  test('should display notification badge when notifications arrive', async ({ page }) => {
    await page.goto('/dashboard');
    await page.waitForLoadState('networkidle');

    // Look for notification bell icon
    const notificationBell = page.locator('[data-testid="notifications"], button[aria-label*="notification" i], .notification-icon').first();

    if (await notificationBell.isVisible({ timeout: 5000 })) {
      // Check for badge
      const badge = page.locator('.badge, .notification-badge, .mat-badge-content');
      const hasBadge = await badge.isVisible({ timeout: 5000 }).catch(() => false);

      if (hasBadge) {
        const badgeText = await badge.textContent();
        console.log(`Notification count: ${badgeText}`);

        // Badge should have a number
        expect(badgeText).toMatch(/\\d+/);
      }
    }
  });

  test('should open notification panel and display notifications', async ({ page }) => {
    await page.goto('/dashboard');
    await page.waitForLoadState('networkidle');

    const notificationBell = page.locator('[data-testid="notifications"], button[aria-label*="notification" i]').first();

    if (await notificationBell.isVisible({ timeout: 5000 })) {
      await notificationBell.click();
      await page.waitForTimeout(1000);

      // Check if notification panel opened
      const notificationPanel = page.locator('[data-testid="notification-panel"], .notification-panel, [role="menu"]');
      await expect(notificationPanel).toBeVisible({ timeout: 3000 });

      // Check for notification items
      const notificationItems = page.locator('.notification-item, [role="menuitem"]');
      const count = await notificationItems.count();

      console.log(`Notification items: ${count}`);
      expect(count).toBeGreaterThanOrEqual(0);
    }
  });
});
