/**
 * API helper for E2E tests
 */
export const API_BASE_URL = process.env.API_BASE_URL || 'http://localhost:8080';
/**
 * Make authenticated API request
 */
export async function apiRequest(page, endpoint, options = {}) {
    const token = await page.evaluate(() => localStorage.getItem('token'));
    const headers = {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        ...(options.headers || {}),
    };
    if (token) {
        headers['Authorization'] = `Bearer ${token}`;
    }
    const url = endpoint.startsWith('http') ? endpoint : `${API_BASE_URL}${endpoint}`;
    const response = await fetch(url, {
        ...options,
        headers,
    });
    return response;
}
/**
 * Get drivers from API
 */
export async function getDrivers(page) {
    const response = await apiRequest(page, '/api/drivers');
    if (!response.ok)
        throw new Error(`Failed to fetch drivers: ${response.status}`);
    return response.json();
}
/**
 * Get vehicles from API
 */
export async function getVehicles(page) {
    const response = await apiRequest(page, '/api/vehicles');
    if (!response.ok)
        throw new Error(`Failed to fetch vehicles: ${response.status}`);
    return response.json();
}
/**
 * Get transport orders from API
 */
export async function getTransportOrders(page) {
    const response = await apiRequest(page, '/api/transport-orders');
    if (!response.ok)
        throw new Error(`Failed to fetch orders: ${response.status}`);
    return response.json();
}
/**
 * Create test data
 */
export async function createDriver(page, driverData) {
    const response = await apiRequest(page, '/api/drivers', {
        method: 'POST',
        body: JSON.stringify(driverData),
    });
    if (!response.ok)
        throw new Error(`Failed to create driver: ${response.status}`);
    return response.json();
}
/**
 * Delete test data
 */
export async function deleteDriver(page, driverId) {
    const response = await apiRequest(page, `/api/drivers/${driverId}`, {
        method: 'DELETE',
    });
    if (!response.ok)
        throw new Error(`Failed to delete driver: ${response.status}`);
    return response.ok;
}
/**
 * Check backend health
 */
export async function checkBackendHealth() {
    try {
        const response = await fetch(`${API_BASE_URL}/api/actuator/health`);
        if (response.ok) {
            return await response.json();
        }
        return null;
    }
    catch {
        return null;
    }
}
/**
 * Wait for backend to be ready
 */
export async function waitForBackend(maxAttempts = 10, delayMs = 2000) {
    for (let i = 0; i < maxAttempts; i++) {
        const health = await checkBackendHealth();
        if (health && health.status === 'UP') {
            console.log('Backend is ready');
            return true;
        }
        console.log(`⏳ Waiting for backend... (attempt ${i + 1}/${maxAttempts})`);
        await new Promise(resolve => setTimeout(resolve, delayMs));
    }
    throw new Error('Backend is not ready after maximum attempts');
}
