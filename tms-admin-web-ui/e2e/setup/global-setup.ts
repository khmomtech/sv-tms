/**
 * Playwright Global Setup
 *
 * Runs once before all tests to prepare the test environment.
 * Ensures all required services are healthy and authentication is ready.
 */

import { chromium, FullConfig } from '@playwright/test';
import { testUsers } from '../fixtures/test-data';

// Configuration
const DEFAULT_TIMEOUT = 30000; // 30 seconds
const HEALTH_CHECK_INTERVAL = 1000; // 1 second

async function globalSetup(config: FullConfig): Promise<void> {
  console.log('🚀 Starting global test setup...\n');

  const { baseURL } = config.projects[0].use;
  const apiBaseUrl = process.env['API_BASE_URL'] || 'http://localhost:8080';
  const skipFrontendCheck = process.env['SKIP_FRONTEND_CHECK'] === 'true';

  try {
    // 1. Verify backend is ready
    console.log('⏳ Checking backend API health...');
    await waitForBackend(apiBaseUrl, DEFAULT_TIMEOUT);
    console.log('Backend API is healthy\n');

    // 2. Verify frontend (optional for API-only tests)
    if (baseURL && !skipFrontendCheck) {
      console.log('⏳ Checking frontend availability...');
      const frontendReady = await waitForFrontend(baseURL, DEFAULT_TIMEOUT);
      if (frontendReady) {
        console.log('Frontend is available\n');
      } else {
        console.log('⚠️  Frontend not available (continuing with API tests only)\n');
      }
    }

    // 3. Setup test database (optional)
    console.log('🗄️  Preparing test database...');
    await setupDatabase(apiBaseUrl);
    console.log('Database setup complete\n');

    // 4. Create test users (optional)
    console.log('👤 Verifying test users...');
    await setupTestUsers(apiBaseUrl);
    console.log('Test users ready\n');

    // 5. Save authentication state
    if (baseURL && !skipFrontendCheck) {
      console.log('🔐 Saving authentication state...');
      await saveAuthState(baseURL, apiBaseUrl);
      console.log('Authentication state saved\n');
    }

    console.log('✨ Global setup complete!\n');
  } catch (error) {
    console.error('❌ Global setup failed:', error);
    throw error;
  }
}

/**
 * Health check for backend API
 * Polls /actuator/health endpoint until service is ready
 */
async function waitForBackend(apiUrl: string, timeout: number): Promise<void> {
  const startTime = Date.now();
  const healthUrl = `${apiUrl}/actuator/health`;
  let lastError: Error | null = null;

  while (Date.now() - startTime < timeout) {
    try {
      const response = await fetch(healthUrl, {
        method: 'GET',
        headers: { 'Accept': 'application/json' }
      });

      if (response.ok) {
        const data = await response.json();
        if (data.status === 'UP') {
          return; // Backend is healthy
        }
      }

      lastError = new Error(`Backend health check failed: ${response.status}`);
    } catch (error) {
      lastError = error as Error;
    }

    await sleep(HEALTH_CHECK_INTERVAL);
  }

  throw new Error(
    `Backend not available after ${timeout}ms. Last error: ${lastError?.message || 'Unknown'}`
  );
}

/**
 * Health check for frontend application
 * Verifies frontend is serving content
 */
async function waitForFrontend(frontendUrl: string, timeout: number): Promise<boolean> {
  const startTime = Date.now();

  while (Date.now() - startTime < timeout) {
    try {
      const response = await fetch(frontendUrl, { method: 'HEAD' });
      if (response.ok || response.status === 304) {
        return true;
      }
    } catch {
      // Frontend not ready, continue waiting
    }
    await sleep(HEALTH_CHECK_INTERVAL);
  }

  return false;
}

/**
 * Reset test database to clean state
 * Calls backend endpoint to truncate/seed test data
 */
async function setupDatabase(apiUrl: string): Promise<void> {
  try {
    const response = await fetch(`${apiUrl}/api/test/reset`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
    });

    if (response.status === 404) {
      console.log('  ℹ️  Database reset endpoint not implemented (optional)');
    } else if (!response.ok) {
      console.warn('  ⚠️  Database reset returned:', response.status);
    }
  } catch (error) {
    console.log('  ℹ️  Database reset skipped (endpoint not available)');
  }
}

/**
 * Create test users for authentication
 * Ensures required test users exist in database
 */
async function setupTestUsers(apiUrl: string): Promise<void> {
  try {
    for (const [role, user] of Object.entries(testUsers)) {
      const response = await fetch(`${apiUrl}/api/test/users`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(user),
      });

      // 409 Conflict means user already exists (which is fine)
      if (response.ok || response.status === 409) {
        continue;
      }

      if (response.status === 404) {
        console.log(`  ℹ️  Test user creation endpoint not implemented (using existing users)`);
        break;
      }
    }
  } catch {
    console.log('  ℹ️  Test user creation skipped (using existing users)');
  }
}

/**
 * Save authenticated session state for reuse across tests
 * Reduces test execution time by avoiding repeated logins
 */
async function saveAuthState(frontendUrl: string, apiUrl: string): Promise<void> {
  const browser = await chromium.launch({ headless: true });
  const context = await browser.newContext();
  const page = await context.newPage();

  try {
    await page.goto(`${frontendUrl}/login`, {
      waitUntil: 'networkidle',
      timeout: 10000
    });

    // Fill login form with admin credentials
    const { username, password } = testUsers.admin;

    await page.fill(
      'input[type="email"], input[name="username"], input[formControlName="username"]',
      username
    );
    await page.fill(
      'input[type="password"], input[name="password"], input[formControlName="password"]',
      password
    );

    // Submit and wait for redirect
    await page.click('button[type="submit"]');
    await page.waitForURL(/\/(dashboard|home|drivers)/, { timeout: 10000 });

    // Save session to file
    await context.storageState({ path: 'playwright/.auth/admin.json' });

  } catch (error) {
    console.log('  ℹ️  Could not save auth state (login page not ready)');
  } finally {
    await browser.close();
  }
}

/**
 * Utility: Sleep for specified milliseconds
 */
function sleep(ms: number): Promise<void> {
  return new Promise(resolve => setTimeout(resolve, ms));
}

export default globalSetup;
