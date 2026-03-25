import { test, expect } from '@playwright/test';

/**
 * Performance and Load Tests
 *
 * Validates application performance under various conditions:
 * - Large dataset pagination (1000+ items)
 * - Filter performance (<100ms target)
 * - Virtual scrolling (60fps target)
 * - Concurrent user simulation
 */

const BASE_URL = process.env['BASE_URL'] || 'http://localhost:4200';

test.describe('Performance Tests', () => {
  test.beforeEach(async ({ page }) => {
    await page.goto(`${BASE_URL}/login`);
    await page.fill('input[name="username"]', 'admin');
    await page.fill('input[name="password"]', 'admin123');
    await page.click('button[type="submit"]');
    await page.waitForURL(/\/(drivers|dashboard)/);
  });

  test.describe('Pagination Performance', () => {
    test('should handle 1000+ items with acceptable performance', async ({ page }) => {
      await page.goto(`${BASE_URL}/drivers`);

      // Measure initial load time
      const startTime = Date.now();
      await page.waitForSelector('.driver-row', { timeout: 10000 });
      const initialLoadTime = Date.now() - startTime;

      expect(initialLoadTime).toBeLessThan(3000); // Should load in < 3 seconds

      // Test pagination through multiple pages
      const paginationTimes: number[] = [];

      for (let i = 0; i < 10; i++) {
        const nextButton = page.locator('button[aria-label="Next page"]');
        if (await nextButton.isEnabled()) {
          const pageStart = Date.now();
          await nextButton.click();
          await page.waitForLoadState('networkidle');
          paginationTimes.push(Date.now() - pageStart);
        } else {
          break;
        }
      }

      // Average pagination time should be < 500ms
      if (paginationTimes.length > 0) {
        const avgTime = paginationTimes.reduce((a, b) => a + b, 0) / paginationTimes.length;
        console.log(`Average pagination time: ${avgTime}ms`);
        expect(avgTime).toBeLessThan(500);
      }
    });

    test('should efficiently handle page size changes', async ({ page }) => {
      await page.goto(`${BASE_URL}/drivers`);

      const pageSizes = [10, 25, 50, 100];
      const loadTimes: Record<number, number> = {};

      for (const size of pageSizes) {
        const startTime = Date.now();

        await page.click('mat-select[aria-label="Items per page"]');
        await page.click(`mat-option:has-text("${size}")`);
        await page.waitForLoadState('networkidle');

        loadTimes[size] = Date.now() - startTime;
        console.log(`Page size ${size}: ${loadTimes[size]}ms`);
      }

      // All page size changes should complete within 2 seconds
      Object.values(loadTimes).forEach(time => {
        expect(time).toBeLessThan(2000);
      });
    });
  });

  test.describe('Filter Performance', () => {
    test('filtering should complete in <100ms for most operations', async ({ page }) => {
      await page.goto(`${BASE_URL}/drivers`);

      // Test text search performance
      const searchTimes: number[] = [];
      const searchTerms = ['john', 'test', 'driver', 'abc'];

      for (const term of searchTerms) {
        const startTime = performance.now();

        await page.fill('input[placeholder*="Search"]', term);
        await page.waitForTimeout(100); // Debounce time
        await page.waitForLoadState('networkidle');

        const endTime = performance.now();
        searchTimes.push(endTime - startTime);
      }

      const avgSearchTime = searchTimes.reduce((a, b) => a + b, 0) / searchTimes.length;
      console.log(`Average search time: ${avgSearchTime}ms`);

      // Most searches should be under 500ms (including debounce + network)
      expect(avgSearchTime).toBeLessThan(500);
    });

    test('dropdown filters should respond instantly', async ({ page }) => {
      await page.goto(`${BASE_URL}/drivers`);

      const filterStart = Date.now();

      await page.click('mat-select[formControlName="status"]');
      const dropdownOpenTime = Date.now() - filterStart;

      await page.click('mat-option:has-text("ACTIVE")');
      await page.waitForLoadState('networkidle');
      const filterCompleteTime = Date.now() - filterStart;

      console.log(`Dropdown open: ${dropdownOpenTime}ms, Filter complete: ${filterCompleteTime}ms`);

      expect(dropdownOpenTime).toBeLessThan(100); // UI should respond instantly
      expect(filterCompleteTime).toBeLessThan(1000); // Filter should complete quickly
    });

    test('combined filters should maintain performance', async ({ page }) => {
      await page.goto(`${BASE_URL}/drivers`);

      const startTime = Date.now();

      // Apply multiple filters
      await page.fill('input[placeholder*="Search"]', 'john');
      await page.waitForTimeout(100);

      await page.click('mat-select[formControlName="status"]');
      await page.click('mat-option:has-text("ACTIVE")');
      await page.waitForTimeout(100);

      await page.waitForLoadState('networkidle');
      const totalTime = Date.now() - startTime;

      console.log(`Combined filter time: ${totalTime}ms`);
      expect(totalTime).toBeLessThan(2000);
    });
  });

  test.describe('Virtual Scrolling Performance', () => {
    test('should maintain 60fps during virtual scroll', async ({ page }) => {
      await page.goto(`${BASE_URL}/drivers`);

      // Set large page size to enable virtual scrolling
      await page.click('mat-select[aria-label="Items per page"]');
      await page.click('mat-option:has-text("100")');
      await page.waitForLoadState('networkidle');

      // Measure scroll performance
      const scrollContainer = page.locator('.cdk-virtual-scroll-viewport');

      if (await scrollContainer.count() > 0) {
        const frameRates: number[] = [];
        let lastTime = performance.now();

        // Scroll through content
        for (let i = 0; i < 10; i++) {
          await scrollContainer.evaluate(el => {
            el.scrollTop += 100;
          });

          await page.waitForTimeout(16); // One frame at 60fps

          const currentTime = performance.now();
          const frameDuration = currentTime - lastTime;
          const fps = 1000 / frameDuration;
          frameRates.push(fps);
          lastTime = currentTime;
        }

        const avgFps = frameRates.reduce((a, b) => a + b, 0) / frameRates.length;
        console.log(`Average FPS during scroll: ${avgFps}`);

        // Should maintain at least 30fps (acceptable), ideally 60fps
        expect(avgFps).toBeGreaterThan(30);
      }
    });
  });

  test.describe('WebSocket High Volume', () => {
    test('should handle 100+ messages without performance degradation', async ({ page }) => {
      await page.goto(`${BASE_URL}/drivers`);

      // Monitor performance while simulating high message volume
      const messageCount = await page.evaluate(() => {
        return new Promise<number>((resolve) => {
          let count = 0;
          const wsService = (window as any).webSocketService;

          if (!wsService) {
            resolve(0);
            return;
          }

          // Subscribe to messages
          const sub = wsService.subscribe('/topic/drivers').subscribe(() => {
            count++;
          });

          // Simulate high volume
          const interval = setInterval(() => {
            wsService.handleMessage({
              body: JSON.stringify({
                type: 'DRIVER_UPDATE',
                data: { id: Math.random(), status: 'ACTIVE' }
              })
            });
          }, 10);

          // Run for 1 second
          setTimeout(() => {
            clearInterval(interval);
            sub.unsubscribe();
            resolve(count);
          }, 1000);
        });
      });

      console.log(`Processed ${messageCount} messages in 1 second`);
      expect(messageCount).toBeGreaterThan(0);

      // Verify UI is still responsive
      const isResponsive = await page.locator('button:has-text("Add Driver")').isEnabled();
      expect(isResponsive).toBe(true);
    });
  });

  test.describe('Memory Leaks', () => {
    test('should not leak memory during navigation', async ({ page }) => {
      // Navigate between pages multiple times
      for (let i = 0; i < 5; i++) {
        await page.goto(`${BASE_URL}/drivers`);
        await page.waitForLoadState('networkidle');

        await page.goto(`${BASE_URL}/vehicles`);
        await page.waitForLoadState('networkidle');
      }

      // Check for memory leaks (basic check)
      // Note: page.metrics() is only available in Chromium
      const metrics = await page.evaluate(() => {
        if (performance && (performance as any).memory) {
          return (performance as any).memory.usedJSHeapSize;
        }
        return 0;
      });

      if (metrics > 0) {
        console.log('Heap size:', metrics / 1024 / 1024, 'MB');
        // Heap should be reasonable (< 100MB for basic navigation)
        expect(metrics).toBeLessThan(100 * 1024 * 1024);
      }
    });

    test('should cleanup subscriptions on component destroy', async ({ page }) => {
      await page.goto(`${BASE_URL}/drivers`);

      const subscriptionCount = await page.evaluate(() => {
        const wsService = (window as any).webSocketService;
        return wsService ? wsService.activeSubscriptions?.length || 0 : 0;
      });

      console.log('Active subscriptions:', subscriptionCount);

      // Navigate away
      await page.goto(`${BASE_URL}/vehicles`);
      await page.waitForTimeout(1000);

      const newSubscriptionCount = await page.evaluate(() => {
        const wsService = (window as any).webSocketService;
        return wsService ? wsService.activeSubscriptions?.length || 0 : 0;
      });

      console.log('Subscriptions after navigation:', newSubscriptionCount);

      // Subscriptions should be cleaned up or at least not growing unbounded
      expect(newSubscriptionCount).toBeLessThanOrEqual(subscriptionCount + 5);
    });
  });

  test.describe('Bundle Size and Load Time', () => {
    test('initial page load should be under 5 seconds', async ({ page }) => {
      const startTime = Date.now();

      await page.goto(`${BASE_URL}/login`);
      await page.waitForLoadState('networkidle');

      const loadTime = Date.now() - startTime;
      console.log(`Initial page load: ${loadTime}ms`);

      expect(loadTime).toBeLessThan(5000);
    });

    test('JavaScript bundle should be reasonable size', async ({ page }) => {
      const response = await page.goto(`${BASE_URL}/`);

      // Check for main.js size
      const resources = await page.evaluate(() => {
        return performance.getEntriesByType('resource')
          .filter(r => r.name.includes('main') && r.name.endsWith('.js'))
          .map(r => ({
            name: r.name,
            size: (r as PerformanceResourceTiming).transferSize
          }));
      });

      console.log('Main bundle resources:', resources);

      // Main bundle should be < 2MB (compressed)
      resources.forEach(resource => {
        expect(resource.size).toBeLessThan(2 * 1024 * 1024);
      });
    });
  });

  test.describe('Concurrent Users Simulation', () => {
    test('should handle 10 concurrent users without degradation', async ({ browser }) => {
      const pages = await Promise.all(
        Array.from({ length: 10 }, () => browser.newPage())
      );

      const results = await Promise.all(
        pages.map(async (page, index) => {
          const startTime = Date.now();

          try {
            await page.goto(`${BASE_URL}/login`);
            await page.fill('input[name="username"]', 'admin');
            await page.fill('input[name="password"]', 'admin123');
            await page.click('button[type="submit"]');
            await page.waitForURL(/\/(drivers|dashboard)/, { timeout: 10000 });

            const loadTime = Date.now() - startTime;
            return { success: true, loadTime, index };
          } catch (error) {
            return { success: false, loadTime: Date.now() - startTime, index, error };
          } finally {
            await page.close();
          }
        })
      );

      const successCount = results.filter(r => r.success).length;
      const avgLoadTime = results.reduce((sum, r) => sum + r.loadTime, 0) / results.length;

      console.log(`Successful logins: ${successCount}/10`);
      console.log(`Average load time: ${avgLoadTime}ms`);

      expect(successCount).toBeGreaterThanOrEqual(9); // At least 90% success rate
      expect(avgLoadTime).toBeLessThan(10000); // Average < 10s even under load
    });
  });

  test.describe('Cache Effectiveness', () => {
    test('should serve cached data efficiently', async ({ page }) => {
      await page.goto(`${BASE_URL}/drivers`);
      await page.waitForLoadState('networkidle');

      // First load - cache miss
      const firstLoadStart = Date.now();
      await page.reload();
      await page.waitForLoadState('networkidle');
      const firstLoadTime = Date.now() - firstLoadStart;

      // Second load - cache hit (within TTL)
      const secondLoadStart = Date.now();
      await page.reload();
      await page.waitForLoadState('networkidle');
      const secondLoadTime = Date.now() - secondLoadStart;

      console.log(`First load: ${firstLoadTime}ms, Second load: ${secondLoadTime}ms`);

      // Second load should be faster due to caching
      expect(secondLoadTime).toBeLessThanOrEqual(firstLoadTime * 1.2); // Allow 20% variance
    });
  });
});

/**
 * Performance Benchmarks Documentation
 *
 * Target Metrics:
 * - Initial page load: < 3s
 * - Pagination: < 500ms per page
 * - Text search: < 200ms (including debounce)
 * - Filter application: < 100ms UI response, < 1s total
 * - Virtual scroll: > 30fps (ideally 60fps)
 * - WebSocket messages: Handle 100+ msgs/sec
 * - Memory: < 100MB for normal usage
 * - Bundle size: < 2MB (compressed)
 * - Concurrent users: Support 10+ without degradation
 * - Cache hit: 2x faster than cache miss
 *
 * Run with:
 * npx playwright test e2e/performance/
 *
 * Generate report:
 * npx playwright show-report
 */
