export const TEST_USERS = {
    admin: {
        username: 'admin',
        password: 'admin123',
        email: 'admin@svlogistics.com',
        roles: ['ADMIN', 'SUPERADMIN'],
    },
    dispatcher: {
        username: 'dispatcher',
        password: 'dispatcher123',
        email: 'dispatcher@svlogistics.com',
        roles: ['DISPATCHER'],
    },
    driver: {
        username: 'driver',
        password: 'driver123',
        email: 'driver@svlogistics.com',
        roles: ['DRIVER'],
    },
};
/**
 * Login via UI
 */
export async function loginViaUI(page, user) {
    await page.goto('/login');
    // Fill in login form
    await page.fill('input[name="username"], input[type="email"]', user.username);
    await page.fill('input[name="password"], input[type="password"]', user.password);
    // Submit form
    await page.click('button[type="submit"]');
    // Wait for navigation to dashboard
    await page.waitForURL('**/dashboard', { timeout: 10000 });
    // Wait for dashboard to load
    await page.waitForLoadState('networkidle');
}
/**
 * Login via API and set token
 */
export async function loginViaAPI(page, user) {
    const apiBaseUrl = process.env['API_BASE_URL'] || 'http://localhost:8080';
    try {
        const response = await fetch(`${apiBaseUrl}/api/auth/login`, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
            },
            body: JSON.stringify({
                username: user.username,
                password: user.password,
            }),
        });
        if (!response.ok) {
            throw new Error(`Login failed: ${response.status}`);
        }
        const data = await response.json();
        // Backend returns: { success: true, data: { token, user, ... } }
        const token = data.data?.token || data.data?.accessToken || data.token || data.accessToken;
        const userData = data.data?.user || data.user;
        const permissions = userData?.permissions || [];
        if (!token) {
            console.error('Login response:', JSON.stringify(data, null, 2));
            throw new Error('No token received from API');
        }
        // Set token, user, and permissions in localStorage before navigating
        await page.addInitScript((authData) => {
            localStorage.setItem('token', authData.token);
            localStorage.setItem('user', JSON.stringify(authData.user));
            localStorage.setItem('permissions', JSON.stringify(authData.permissions));
        }, { token, user: userData || user, permissions });
        // Navigate to a page to ensure localStorage is accessible
        await page.goto('/dashboard', { waitUntil: 'domcontentloaded', timeout: 30000 });
        await page.waitForLoadState('domcontentloaded');
        return { token, permissions, user: userData || user };
    }
    catch (error) {
        console.error('API login failed:', error);
        throw error;
    }
}
/**
 * Mock authentication (for testing without backend)
 */
export async function mockAuthentication(page, user) {
    await page.addInitScript((authData) => {
        // Create a mock JWT token
        const header = btoa(JSON.stringify({ alg: 'HS256', typ: 'JWT' }));
        const payload = btoa(JSON.stringify({
            exp: Math.floor(Date.now() / 1000) + 3600,
            iat: Math.floor(Date.now() / 1000),
            sub: authData.user.username,
            roles: authData.user.roles,
        }));
        const signature = 'mock-signature-for-testing';
        const token = `${header}.${payload}.${signature}`;
        localStorage.setItem('token', token);
        localStorage.setItem('user', JSON.stringify(authData.user));
    }, { user });
}
/**
 * Logout
 */
export async function logout(page) {
    // Click user menu
    const userMenuButton = page.locator('button[aria-label*="user" i], [data-testid="user-menu"]').first();
    await userMenuButton.click();
    // Click logout
    const logoutButton = page.locator('button, a').filter({ hasText: /logout|sign out/i });
    await logoutButton.click();
    // Wait for redirect to login
    await page.waitForURL('**/login', { timeout: 5000 });
}
/**
 * Check if user is authenticated
 */
export async function isAuthenticated(page) {
    const token = await page.evaluate(() => localStorage.getItem('token'));
    return !!token;
}
/**
 * Get current user from localStorage
 */
export async function getCurrentUser(page) {
    const userStr = await page.evaluate(() => localStorage.getItem('user'));
    return userStr ? JSON.parse(userStr) : null;
}
