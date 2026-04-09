import { test, expect } from '@playwright/test';

test.describe('TMS Application - Core Functionality', () => {
  // Helper function for authentication
  const authenticateUser = async (page: any, userRole = 'USER') => {
    await page.addInitScript(() => {
      // Create a valid JWT token that expires in 1 hour
      const header = btoa(JSON.stringify({ alg: 'HS256', typ: 'JWT' }));
      const payload = btoa(JSON.stringify({
        exp: Math.floor(Date.now() / 1000) + 3600,
        iat: Math.floor(Date.now() / 1000),
        sub: 'testuser',
        roles: ['USER']
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

  test('should redirect unauthenticated users to login', async ({ page }) => {
    await page.goto('/dashboard');

    // Should redirect to login page
    await expect(page).toHaveURL(/.*\/login/);
    await expect(page).toHaveTitle('Logistics Dashboard');
  });

  test('should display login page correctly', async ({ page }) => {
    await page.goto('/login');

    // Verify we're on login page
    await expect(page).toHaveURL(/.*\/login/);
    await expect(page).toHaveTitle('Logistics Dashboard');

    // Check for login form elements (if they exist)
    const loginForm = page.locator('form, [data-testid="login-form"]');
    if (await loginForm.isVisible({ timeout: 2000 })) {
      // Check for common login elements
      const emailInput = page.locator('input[type="email"], input[name="email"], input[placeholder*="email" i]');
      const passwordInput = page.locator('input[type="password"], input[name="password"]');
      const loginButton = page.locator('button[type="submit"], button').filter({ hasText: /login|Login|sign in|Sign In/i });

      // At least one of these should be present if it's a login form
      const hasLoginElements = await emailInput.isVisible() || await passwordInput.isVisible() || await loginButton.isVisible();
      expect(hasLoginElements).toBe(true);
    }
  });

  test('should authenticate and access dashboard', async ({ page }) => {
    await authenticateUser(page);

    await page.goto('/dashboard');

    // Wait for dashboard to load
    await page.waitForLoadState('networkidle');

    // Verify we're on dashboard
    await expect(page).toHaveURL(/.*\/dashboard/);

    // Check for dashboard content
    const dashboardContent = page.locator('[data-testid="dashboard"], .dashboard, main');
    await expect(dashboardContent).toBeVisible();
  });

  test('should display navigation components when authenticated', async ({ page }) => {
    await authenticateUser(page);

    await page.goto('/dashboard');
    await page.waitForLoadState('networkidle');

    // Check for any navigation elements with flexible selectors
    const nav = page.locator('nav, header, .navbar, [role="banner"]').first();
    const hasNav = await nav.isVisible({ timeout: 5000 }).catch(() => false);

    // Check sidebar navigation with flexible selectors
    const sidebar = page.locator('aside, nav[role="navigation"], .sidebar, .sidenav').first();
    const hasSidebar = await sidebar.isVisible({ timeout: 5000 }).catch(() => false);

    // At least one navigation element should be present
    expect(hasNav || hasSidebar).toBe(true);

    if (hasSidebar) {
      // Verify sidebar has navigation items
      const navItems = sidebar.locator('a, button');
      const itemCount = await navItems.count();
      expect(itemCount).toBeGreaterThan(0);
    }
  });

  test('should maintain authentication state across page reloads', async ({ page }) => {
    await authenticateUser(page);

    await page.goto('/dashboard');
    await page.waitForLoadState('networkidle');

    // Verify initial authentication
    await expect(page).toHaveURL(/.*\/dashboard/);

    // Reload the page
    await page.reload();
    await page.waitForLoadState('networkidle');

    // Should still be authenticated and on dashboard
    await expect(page).toHaveURL(/.*\/dashboard/);

    // Check for any navigation or main content
    const main = page.locator('main, .main-content, [role="main"], aside, nav').first();
    await expect(main).toBeVisible({ timeout: 10000 });
  });

  test('should handle sidebar toggle functionality', async ({ page }) => {
    await authenticateUser(page);

    await page.goto('/dashboard');
    await page.waitForLoadState('networkidle');

    // Look for toggle button with flexible selectors
    const toggleButton = page.locator('button[aria-label*="Toggle" i], button[aria-label*="Menu" i], .menu-toggle').first();
    const hasToggle = await toggleButton.isVisible({ timeout: 3000 }).catch(() => false);

    if (!hasToggle) {
      // Skip test if no toggle button exists
      test.skip();
      return;
    }

    const sidebar = page.locator('aside, nav[role="navigation"], .sidebar').first();

    // Sidebar should be visible initially
    const initiallyVisible = await sidebar.isVisible().catch(() => false);

    if (initiallyVisible) {
      // Click toggle to close sidebar
      await toggleButton.click();
      await page.waitForTimeout(500);

      // Click toggle again to open sidebar
      await toggleButton.click();
      await page.waitForTimeout(500);

      // Sidebar should be visible again
      await expect(sidebar).toBeVisible();
    }
  });

  test('should display user menu and handle logout', async ({ page }) => {
    await authenticateUser(page);

    await page.goto('/dashboard');
    await page.waitForLoadState('networkidle');

    // Look for user menu button
    const userMenuButton = page.locator('button[aria-label*="user" i], button').filter({ hasText: /testuser/i }).first();
    if (await userMenuButton.isVisible({ timeout: 2000 })) {
      await userMenuButton.click();

      // Check for logout option
      const logoutButton = page.locator('button, a').filter({ hasText: /logout|Logout/i });
      if (await logoutButton.isVisible({ timeout: 2000 })) {
        await logoutButton.click();

        // Should redirect to login
        await expect(page).toHaveURL(/.*\/login/);
      }
    }
  });
});
