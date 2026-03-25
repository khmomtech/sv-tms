/**
 * Test Data Fixtures for E2E Tests
 *
 * Provides type-safe, reusable test data aligned with backend API schema.
 * Keep this file synchronized with backend DTOs and database schema.
 */
// ============================================================================
// Test Data Factories
// ============================================================================
/**
 * Create a test driver with default values
 * @param overrides - Custom values to override defaults
 */
export function createTestDriver(overrides) {
    const timestamp = Date.now();
    return {
        firstName: 'Test',
        lastName: 'Driver',
        phone: '+1234567890',
        licenseNumber: `DL${timestamp}`,
        status: 'ONLINE',
        rating: 4.5,
        isActive: true,
        isPartner: false,
        user: {
            username: `driver${timestamp}`,
            password: 'Driver123!',
            email: `driver${timestamp}@test.com`,
            role: 'DRIVER',
        },
        ...overrides,
    };
}
/**
 * Create a test vehicle with default values
 * @param overrides - Custom values to override defaults
 */
export function createTestVehicle(overrides) {
    const timestamp = Date.now();
    return {
        licensePlate: `TST-${timestamp}`,
        manufacturer: 'Toyota',
        model: 'Camry',
        year: 2024,
        type: 'TRUCK',
        status: 'AVAILABLE',
        mileage: 0,
        fuelConsumption: 10,
        qtyPalletsCapacity: 20,
        ...overrides,
    };
}
// ============================================================================
// Test Users (for authentication)
// ============================================================================
export const testUsers = {
    admin: {
        username: 'admin',
        password: 'admin123',
        email: 'admin@svtms.com',
        role: 'ADMIN',
        firstName: 'Admin',
        lastName: 'User',
    },
    dispatcher: {
        username: 'dispatcher',
        password: 'dispatcher123',
        email: 'dispatcher@svtms.com',
        role: 'DISPATCHER',
        firstName: 'Dispatcher',
        lastName: 'User',
    },
    driver: {
        username: 'testdriver',
        password: 'driver123',
        email: 'driver@svtms.com',
        role: 'DRIVER',
        firstName: 'Test',
        lastName: 'Driver',
    },
};
// ============================================================================
// Bulk Data Generation (for performance testing)
// ============================================================================
/**
 * Generate multiple test drivers
 * @param count - Number of drivers to generate
 */
export function generateBulkDrivers(count) {
    return Array.from({ length: count }, (_, i) => createTestDriver({
        firstName: `Driver`,
        lastName: `${i + 1}`,
        phone: `+1-555-${String(i).padStart(4, '0')}`,
        licenseNumber: `DL${String(i).padStart(8, '0')}`,
    }));
}
/**
 * Generate multiple test vehicles
 * @param count - Number of vehicles to generate
 */
export function generateBulkVehicles(count) {
    const manufacturers = ['Toyota', 'Ford', 'Honda', 'Chevrolet'];
    const models = ['Sedan', 'SUV', 'Truck', 'Van'];
    return Array.from({ length: count }, (_, i) => createTestVehicle({
        licensePlate: `TST-${String(i).padStart(4, '0')}`,
        manufacturer: manufacturers[i % manufacturers.length],
        model: models[i % models.length],
        year: 2020 + (i % 5),
    }));
}
// ============================================================================
// Test Configuration Constants
// ============================================================================
/**
 * API response time thresholds (milliseconds)
 */
export const PERFORMANCE_THRESHOLDS = {
    API_RESPONSE: 2000, // Maximum API response time
    PAGE_LOAD: 3000, // Maximum page load time
    SEARCH_FILTER: 500, // Maximum search/filter time
};
/**
 * Common wait times (milliseconds)
 */
export const WAIT_TIMES = {
    SHORT: 500,
    MEDIUM: 2000,
    LONG: 5000,
    VERY_LONG: 10000,
};
/**
 * Test viewport configurations
 */
export const VIEWPORTS = {
    mobile: { width: 375, height: 667 },
    tablet: { width: 768, height: 1024 },
    desktop: { width: 1920, height: 1080 },
};
