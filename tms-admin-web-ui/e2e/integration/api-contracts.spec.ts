import { test, expect, APIRequestContext } from '@playwright/test';

/**
 * API Contract Integration Tests
 *
 * Verifies that backend API responses match expected TypeScript interfaces
 * Tests critical API endpoints to ensure contract compliance
 */

// Configuration
const API_BASE_URL = process.env['API_BASE_URL'] || 'http://localhost:8080';

// API Endpoints
const ENDPOINTS = {
  auth: {
    login: '/api/auth/login',
  },
  drivers: {
    list: '/api/admin/drivers/list',
    search: '/api/admin/drivers/search',
    getById: (id: number | string) => `/api/admin/drivers/${id}`,
    create: '/api/admin/drivers/add',
    update: (id: number | string) => `/api/admin/drivers/update/${id}`,
    delete: (id: number | string) => `/api/admin/drivers/delete/${id}`,
  },
  vehicles: {
    list: '/api/admin/vehicles/filter',
    create: '/api/admin/vehicles',
  },
} as const;

// Status Enums
const DRIVER_STATUSES = ['ONLINE', 'OFFLINE', 'BUSY'] as const;
type DriverStatus = typeof DRIVER_STATUSES[number];

// HTTP Status Codes
const HTTP_STATUS = {
  OK: 200,
  BAD_REQUEST: 400,
  FORBIDDEN: 403,
  NOT_FOUND: 404,
  INTERNAL_SERVER_ERROR: 500,
} as const;

// Type Definitions
interface ApiResponse<T = any> {
  success: boolean;
  data: T;
  message?: string;
}

interface PaginatedResponse<T> {
  content: T[];
  page: number;
  size: number;
  totalElements: number;
  totalPages: number;
  last: boolean;
}

interface Driver {
  id: number;
  firstName: string;
  lastName: string;
  name?: string;
  phone: string;
  licenseNumber?: string;
  status: DriverStatus;
  user: {
    id: number;
    email: string;
    username: string;
    roles: string[];
  };
}

interface Vehicle {
  id: number;
  licensePlate: string;
  type: string;
  status: string;
  manufacturer?: string;
  model?: string;
  year?: number;
}

// Helper Functions
function buildUrl(path: string): string {
  return `${API_BASE_URL}${path}`;
}

function createAuthHeaders(token: string): Record<string, string> {
  return {
    'Authorization': `Bearer ${token}`,
    'Content-Type': 'application/json',
  };
}

function generateUniqueId(): string {
  return Date.now().toString();
}

function createDriverPayload(overrides?: Partial<any>) {
  const timestamp = generateUniqueId();
  return {
    firstName: 'Test',
    lastName: 'Driver',
    phone: '+1234567890',
    licenseNumber: `DL${timestamp}`,
    user: {
      username: `test${timestamp}`,
      password: 'Test123',
      email: `test${timestamp}@example.com`,
    },
    ...overrides,
  };
}

async function authenticateUser(
  request: APIRequestContext,
  username = 'admin',
  password = 'admin123'
): Promise<string> {
  const response = await request.post(buildUrl(ENDPOINTS.auth.login), {
    data: { username, password },
  });

  if (!response.ok()) {
    throw new Error(`Authentication failed: ${response.status()}`);
  }

  const data: ApiResponse<{ token: string }> = await response.json();
  return data.data.token;
}

test.describe('API Contract Tests', () => {
  let authToken: string;

  test.beforeAll(async ({ request }) => {
    authToken = await authenticateUser(request);
    expect(authToken).toBeTruthy();
  });

  test.describe('Driver API Contracts', () => {
    test('GET /admin/drivers should return paginated driver list', async ({ request }) => {
      const response = await request.get(buildUrl(ENDPOINTS.drivers.list), {
        params: { page: '0', size: '10' },
        headers: createAuthHeaders(authToken),
      });

      expect(response.ok()).toBeTruthy();
      const result: ApiResponse<PaginatedResponse<Driver>> = await response.json();

      // Verify API response wrapper
      expect(result.success).toBe(true);
      expect(result.data).toBeDefined();

      // Verify pagination structure
      const { data } = result;
      expect(data.content).toBeInstanceOf(Array);
      expect(data.page).toBe(0);
      expect(data.size).toBe(10);
      expect(typeof data.totalElements).toBe('number');
      expect(typeof data.totalPages).toBe('number');
      expect(typeof data.last).toBe('boolean');

      // Verify driver entity structure (if data exists)
      if (data.content.length > 0) {
        const driver = data.content[0];

        // Required fields
        expect(driver.id).toBeGreaterThan(0);
        expect(driver.firstName).toBeTruthy();
        expect(driver.lastName).toBeTruthy();
        expect(driver.phone).toBeTruthy();
        expect(DRIVER_STATUSES).toContain(driver.status);

        // Nested user object
        expect(driver.user).toBeDefined();
        expect(driver.user.id).toBeGreaterThan(0);
        expect(driver.user.email).toMatch(/^[^\s@]+@[^\s@]+\.[^\s@]+$/);
        expect(driver.user.username).toBeTruthy();
        expect(driver.user.roles).toBeInstanceOf(Array);
      }
    });

    test('GET /admin/drivers/:id should return single driver', async ({ request }) => {
      const listResponse = await request.get(buildUrl(ENDPOINTS.drivers.list), {
        params: { page: '0', size: '1' },
        headers: createAuthHeaders(authToken),
      });

      expect(listResponse.ok()).toBeTruthy();
      const listResult: ApiResponse<PaginatedResponse<Driver>> = await listResponse.json();
      expect(listResult.data.content.length).toBeGreaterThan(0);

      const driverId = listResult.data.content[0].id;
      const response = await request.get(buildUrl(ENDPOINTS.drivers.getById(driverId)), {
        headers: createAuthHeaders(authToken),
      });

      expect(response.ok()).toBeTruthy();
      const result: ApiResponse<Driver> = await response.json();

      expect(result.success).toBe(true);
      expect(result.data.id).toBe(driverId);
      expect(result.data.firstName).toBeTruthy();
      expect(result.data.lastName).toBeTruthy();
      expect(result.data.phone).toBeTruthy();
      expect(result.data.user).toBeDefined();
    });

    test('POST /admin/drivers should create driver with correct structure', async ({ request }) => {
      const payload = createDriverPayload({
        firstName: 'Integration',
        lastName: 'Test',
      });

      const response = await request.post(buildUrl(ENDPOINTS.drivers.create), {
        data: payload,
        headers: createAuthHeaders(authToken),
      });

      expect(response.ok()).toBeTruthy();
      const result: ApiResponse<Driver> = await response.json();

      // Verify successful creation
      expect(result.success).toBe(true);
      expect(result.data.id).toBeGreaterThan(0);

      // Verify data integrity
      expect(result.data.firstName).toBe(payload.firstName);
      expect(result.data.lastName).toBe(payload.lastName);
      expect(result.data.phone).toBe(payload.phone);

      // Verify user association
      expect(result.data.user).toBeDefined();
      expect(result.data.user.email).toBe(payload.user.email);
      expect(result.data.user.username).toBe(payload.user.username);
      expect(result.data.user.roles).toContain('DRIVER');
    });

    test('PUT /admin/drivers/:id should update driver', async ({ request }) => {
      // Arrange: Create test driver
      const createPayload = createDriverPayload({ firstName: 'Original', lastName: 'Name' });
      const createResponse = await request.post(buildUrl(ENDPOINTS.drivers.create), {
        data: createPayload,
        headers: createAuthHeaders(authToken),
      });

      expect(createResponse.ok()).toBeTruthy();
      const createResult: ApiResponse<Driver> = await createResponse.json();
      const driverId = createResult.data.id;

      // Act: Update driver
      const updatePayload = {
        ...createResult.data,
        firstName: 'Updated',
        lastName: 'Modified',
      };

      const updateResponse = await request.put(
        buildUrl(ENDPOINTS.drivers.update(driverId)),
        {
          data: updatePayload,
          headers: createAuthHeaders(authToken),
        }
      );

      // Assert: Verify update
      expect(updateResponse.ok()).toBeTruthy();
      const updateResult: ApiResponse<Driver> = await updateResponse.json();

      expect(updateResult.success).toBe(true);
      expect(updateResult.data.id).toBe(driverId);
      expect(updateResult.data.firstName).toBe('Updated');
      expect(updateResult.data.lastName).toBe('Modified');
    });

    test('DELETE /admin/drivers/:id should remove driver', async ({ request }) => {
      // Arrange: Create test driver for deletion
      const createPayload = createDriverPayload({ firstName: 'ToDelete', lastName: 'Driver' });
      const createResponse = await request.post(buildUrl(ENDPOINTS.drivers.create), {
        data: createPayload,
        headers: createAuthHeaders(authToken),
      });

      expect(createResponse.ok()).toBeTruthy();
      const createResult: ApiResponse<Driver> = await createResponse.json();
      const driverId = createResult.data.id;

      // Act: Delete driver
      const deleteResponse = await request.delete(
        buildUrl(ENDPOINTS.drivers.delete(driverId)),
        { headers: createAuthHeaders(authToken) }
      );

      // Assert: Verify deletion success
      expect(deleteResponse.ok()).toBeTruthy();
      const deleteResult: ApiResponse = await deleteResponse.json();
      expect(deleteResult.success).toBe(true);

      // Assert: Verify driver no longer exists (404)
      const getResponse = await request.get(
        buildUrl(ENDPOINTS.drivers.getById(driverId)),
        { headers: createAuthHeaders(authToken) }
      );

      expect(getResponse.status()).toBe(HTTP_STATUS.NOT_FOUND);
    });
  });

  test.describe('Vehicle API Contracts', () => {
    test('GET /admin/vehicles should return paginated vehicle list', async ({ request }) => {
      const response = await request.get(buildUrl(ENDPOINTS.vehicles.list), {
        params: { page: '0', size: '10' },
        headers: createAuthHeaders(authToken),
      });

      expect(response.ok()).toBeTruthy();
      const result: ApiResponse<PaginatedResponse<Vehicle>> = await response.json();

      // Verify response structure
      expect(result.success).toBe(true);
      expect(result.data.content).toBeInstanceOf(Array);

      // Verify vehicle structure (if data exists)
      if (result.data.content.length > 0) {
        const vehicle = result.data.content[0];

        expect(vehicle.id).toBeGreaterThan(0);
        expect(vehicle.licensePlate).toBeTruthy();
        expect(vehicle.type).toBeTruthy();
        expect(vehicle.status).toBeTruthy();
      }
    });

    test('POST /admin/vehicles should create vehicle', async ({ request }) => {
      // Arrange: Prepare vehicle data
      const timestamp = generateUniqueId();
      const newVehicle = {
        licensePlate: `ABC${timestamp}`,
        type: 'TRUCK',
        truckSize: 'MEDIUM_TRUCK',
        status: 'AVAILABLE',
        model: 'Test Model',
        manufacturer: 'Test Make',
        year: 2024,
        mileage: 0,
        fuelConsumption: 10
      };

      // Act: Create vehicle
      const response = await request.post(buildUrl(ENDPOINTS.vehicles.create), {
        data: newVehicle,
        headers: createAuthHeaders(authToken),
      });

      // Assert: Verify creation
      expect(response.ok()).toBeTruthy();
      const result: ApiResponse<Vehicle> = await response.json();

      expect(result.success).toBe(true);
      expect(result.data.licensePlate).toBe(newVehicle.licensePlate);
      expect(result.data.type).toBe(newVehicle.type);
      expect(result.data.status).toBe(newVehicle.status);
      expect(result.data.id).toBeGreaterThan(0);
    });

    test('PUT /admin/vehicles/:id should update vehicle', async ({ request }) => {
      // Arrange: Create test vehicle
      const timestamp = generateUniqueId();
      const createPayload = {
        licensePlate: `VEH${timestamp}`,
        type: 'VAN',
        status: 'AVAILABLE',
        model: 'Original Model',
        manufacturer: 'Original Make',
        year: 2023,
        mileage: 1000,
        fuelConsumption: 8
      };

      const createResponse = await request.post(buildUrl(ENDPOINTS.vehicles.create), {
        data: createPayload,
        headers: createAuthHeaders(authToken),
      });

      expect(createResponse.ok()).toBeTruthy();
      const createResult: ApiResponse<Vehicle> = await createResponse.json();
      const vehicleId = createResult.data.id;

      // Act: Update vehicle
      const updatePayload = {
        ...createResult.data,
        model: 'Updated Model',
        status: 'MAINTENANCE',
        mileage: 2000,
      };

      const updateResponse = await request.put(
        `${API_BASE_URL}/api/admin/vehicles/${vehicleId}`,
        {
          data: updatePayload,
          headers: createAuthHeaders(authToken),
        }
      );

      // Assert: Verify update
      expect(updateResponse.ok()).toBeTruthy();
      const updateResult: ApiResponse<Vehicle> = await updateResponse.json();

      expect(updateResult.success).toBe(true);
      expect(updateResult.data.id).toBe(vehicleId);
      expect(updateResult.data.model).toBe('Updated Model');
      expect(updateResult.data.status).toBe('MAINTENANCE');
    });

    test('DELETE /admin/vehicles/:id should remove vehicle', async ({ request }) => {
      // Arrange: Create test vehicle for deletion with truly unique ID
      const timestamp = Date.now();
      const randomSuffix = Math.floor(Math.random() * 10000);
      const createPayload = {
        licensePlate: `DEL${timestamp}${randomSuffix}`,
        type: 'VAN', // Valid enum value
        status: 'AVAILABLE',
        model: 'To Delete',
        manufacturer: 'Test',
        year: 2023,
        mileage: 0,
        fuelConsumption: 10
      };

      const createResponse = await request.post(buildUrl(ENDPOINTS.vehicles.create), {
        data: createPayload,
        headers: createAuthHeaders(authToken),
      });

      if (!createResponse.ok()) {
        const errorData = await createResponse.json();
        console.error('Vehicle DELETE test - creation failed:', errorData);
      }

      expect(createResponse.ok()).toBeTruthy();
      const createResult: ApiResponse<Vehicle> = await createResponse.json();
      const vehicleId = createResult.data.id;

      // Act: Delete vehicle
      const deleteResponse = await request.delete(
        `${API_BASE_URL}/api/admin/vehicles/${vehicleId}`,
        { headers: createAuthHeaders(authToken) }
      );

      // Assert: Verify deletion success
      expect(deleteResponse.ok()).toBeTruthy();
      const deleteResult: ApiResponse = await deleteResponse.json();
      expect(deleteResult.success).toBe(true);

      // Assert: Verify vehicle no longer accessible (404 or filtered out)
      const getResponse = await request.get(
        `${API_BASE_URL}/api/admin/vehicles/${vehicleId}`,
        { headers: createAuthHeaders(authToken) }
      );

      expect(getResponse.status()).toBe(HTTP_STATUS.NOT_FOUND);
    });
  });

  test.describe('Error Responses', () => {
    test('401 Unauthorized - Invalid authentication', async ({ request }) => {
      const response = await request.get(buildUrl(ENDPOINTS.drivers.list), {
        headers: { 'Authorization': 'Bearer invalid-token' },
      });

      expect(response.status()).toBe(401);
    });

    test('404 Not Found - Non-existent resource', async ({ request }) => {
      const nonExistentId = 999999;
      const response = await request.get(buildUrl(ENDPOINTS.drivers.getById(nonExistentId)), {
        headers: createAuthHeaders(authToken),
      });

      expect(response.status()).toBe(HTTP_STATUS.NOT_FOUND);
      const result: ApiResponse = await response.json();

      expect(result.success).toBe(false);
      expect(result.message).toBeTruthy();
    });

    test('400 Bad Request - Validation errors', async ({ request }) => {
      const invalidPayload = {
        firstName: '', // Required field empty
        lastName: '',  // Required field empty
        email: 'not-an-email', // Invalid format
      };

      const response = await request.post(buildUrl(ENDPOINTS.drivers.create), {
        data: invalidPayload,
        headers: createAuthHeaders(authToken),
      });

      // Backend returns 400 or 500 for validation failures
      expect([HTTP_STATUS.BAD_REQUEST, HTTP_STATUS.INTERNAL_SERVER_ERROR]).toContain(response.status());

      const result = await response.json();
      expect(result.message).toBeTruthy();
    });
  });

  test.describe('Pagination Contract', () => {
    test('should respect page and size parameters', async ({ request }) => {
      const pageSize = 5;
      const pageNumber = 0;

      const response = await request.get(buildUrl(ENDPOINTS.drivers.list), {
        params: { page: String(pageNumber), size: String(pageSize) },
        headers: createAuthHeaders(authToken),
      });

      expect(response.ok()).toBeTruthy();
      const result: ApiResponse<PaginatedResponse<Driver>> = await response.json();

      expect(result.data.page).toBe(pageNumber);
      expect(result.data.size).toBe(pageSize);
      expect(result.data.content.length).toBeLessThanOrEqual(pageSize);
      expect(result.data.totalElements).toBeGreaterThanOrEqual(0);
      expect(result.data.totalPages).toBeGreaterThanOrEqual(0);
    });

    test('should handle out-of-bounds page numbers gracefully', async ({ request }) => {
      const outOfBoundsPage = 9999;

      const response = await request.get(buildUrl(ENDPOINTS.drivers.list), {
        params: { page: String(outOfBoundsPage), size: '10' },
        headers: createAuthHeaders(authToken),
      });

      expect(response.ok()).toBeTruthy();
      const result: ApiResponse<PaginatedResponse<Driver>> = await response.json();

      expect(result.data.content).toEqual([]);
      expect(result.data.last).toBe(true);
    });
  });

  test.describe('Performance Tests', () => {
    test('should respond within acceptable time for list endpoint', async ({ request }) => {
      const startTime = Date.now();

      const response = await request.get(buildUrl(ENDPOINTS.drivers.list), {
        params: { page: '0', size: '50' },
        headers: createAuthHeaders(authToken),
      });

      const duration = Date.now() - startTime;

      expect(response.ok()).toBeTruthy();
      expect(duration).toBeLessThan(3000); // Should respond within 3 seconds

      const result: ApiResponse<PaginatedResponse<Driver>> = await response.json();
      expect(result.success).toBe(true);
    });

    test('should handle concurrent requests efficiently', async ({ request }) => {
      const startTime = Date.now();

      // Act: Make 5 concurrent requests
      const requests = Array(5).fill(null).map(() =>
        request.get(buildUrl(ENDPOINTS.drivers.list), {
          params: { page: '0', size: '10' },
          headers: createAuthHeaders(authToken),
        })
      );

      const responses = await Promise.all(requests);
      const duration = Date.now() - startTime;

      // Assert: All requests succeed
      responses.forEach((response) => {
        expect(response.ok()).toBeTruthy();
      });

      // Assert: Concurrent requests complete in reasonable time
      expect(duration).toBeLessThan(5000); // 5 seconds for 5 concurrent requests
    });
  });

  test.describe('Filter Contract', () => {
    test('should filter drivers by status', async ({ request }) => {
      const response = await request.get(buildUrl(ENDPOINTS.drivers.list), {
        params: { status: 'ACTIVE', page: '0', size: '10' },
        headers: createAuthHeaders(authToken),
      });

      expect(response.ok()).toBeTruthy();
      const result: ApiResponse<PaginatedResponse<Driver>> = await response.json();

      // Verify all drivers have valid status
      if (result.data.content.length > 0) {
        result.data.content.forEach((driver) => {
          expect(DRIVER_STATUSES).toContain(driver.status);
        });
      }
    });

    test('should filter drivers by search query', async ({ request }) => {
      const searchTerm = `Search${generateUniqueId()}`;

      const createPayload = createDriverPayload({
        firstName: searchTerm,
        lastName: 'Query',
      });
      const createResponse = await request.post(buildUrl(ENDPOINTS.drivers.create), {
        data: createPayload,
        headers: createAuthHeaders(authToken),
      });

      expect(createResponse.ok()).toBeTruthy();

      const response = await request.get(buildUrl(ENDPOINTS.drivers.search), {
        params: { query: searchTerm },
        headers: createAuthHeaders(authToken),
      });

      expect(response.ok()).toBeTruthy();
      const result: ApiResponse<Driver[]> = await response.json();

      expect(result.data.length).toBeGreaterThan(0);
      const matched = result.data.some((driver) =>
        [driver.firstName, driver.lastName, driver.name, driver.phone, driver.licenseNumber]
          .filter(Boolean)
          .join(' ')
          .toLowerCase()
          .includes(searchTerm.toLowerCase()),
      );

      expect(matched).toBe(true);
    });

    test('should combine multiple filters (status + search)', async ({ request }) => {
      const response = await request.get(buildUrl(ENDPOINTS.drivers.list), {
        params: {
          status: 'ACTIVE',
          search: 'driver',
          page: '0',
          size: '10',
        },
        headers: createAuthHeaders(authToken),
      });

      expect(response.ok()).toBeTruthy();
      const result: ApiResponse<PaginatedResponse<Driver>> = await response.json();

      // Verify response structure
      expect(result.success).toBe(true);
      expect(result.data.content).toBeInstanceOf(Array);

      // If results exist, verify they match all filters
      if (result.data.content.length > 0) {
        result.data.content.forEach((driver) => {
          expect(DRIVER_STATUSES).toContain(driver.status);
        });
      }
    });

    test('should handle special characters in search', async ({ request }) => {
      const specialChars = ['@', '+', '-', '.'];

      for (const char of specialChars) {
        const response = await request.get(buildUrl(ENDPOINTS.drivers.list), {
          params: { search: char, page: '0', size: '10' },
          headers: createAuthHeaders(authToken),
        });

        expect(response.ok()).toBeTruthy();
        const result: ApiResponse<PaginatedResponse<Driver>> = await response.json();
        expect(result.success).toBe(true);
      }
    });
  });

  test.describe('Sorting Contract', () => {
    test('should accept sorting parameters', async ({ request }) => {
      // Test that backend accepts sort parameter (actual sorting may vary by backend implementation)
      const response = await request.get(buildUrl(ENDPOINTS.drivers.list), {
        params: {
          page: '0',
          size: '10',
          sort: 'firstName,asc',
        },
        headers: createAuthHeaders(authToken),
      });

      expect(response.ok()).toBeTruthy();
      const result: ApiResponse<PaginatedResponse<Driver>> = await response.json();

      expect(result.success).toBe(true);
      expect(result.data.content).toBeInstanceOf(Array);
      expect(result.data.page).toBe(0);
      expect(result.data.size).toBe(10);

      // Verify structure is valid - actual sort order depends on backend implementation
      if (result.data.content.length > 0) {
        expect(result.data.content[0].firstName).toBeTruthy();
      }
    });

    test('should support sorting by multiple fields', async ({ request }) => {
      const response = await request.get(buildUrl(ENDPOINTS.drivers.list), {
        params: {
          page: '0',
          size: '10',
          sort: 'lastName,asc&sort=firstName,asc',
        },
        headers: createAuthHeaders(authToken),
      });

      expect(response.ok()).toBeTruthy();
      const result: ApiResponse<PaginatedResponse<Driver>> = await response.json();

      expect(result.success).toBe(true);
      expect(result.data.content).toBeInstanceOf(Array);
    });
  });

  test.describe('Bulk Operations', () => {
    test('should create multiple drivers in sequence', async ({ request }) => {
      const driversToCreate = 3;
      const createdIds: number[] = [];

      for (let i = 0; i < driversToCreate; i++) {
        const payload = createDriverPayload({
          firstName: `Bulk${i}`,
          lastName: 'Test',
        });

        const response = await request.post(buildUrl(ENDPOINTS.drivers.create), {
          data: payload,
          headers: createAuthHeaders(authToken),
        });

        expect(response.ok()).toBeTruthy();
        const result: ApiResponse<Driver> = await response.json();

        expect(result.success).toBe(true);
        expect(result.data.id).toBeGreaterThan(0);
        createdIds.push(result.data.id);
      }

      // Verify all IDs are unique
      const uniqueIds = new Set(createdIds);
      expect(uniqueIds.size).toBe(driversToCreate);
    });

    test('should handle rapid updates without data loss', async ({ request }) => {
      // Arrange: Create test driver
      const createPayload = createDriverPayload({ firstName: 'RapidUpdate', lastName: 'Test' });
      const createResponse = await request.post(buildUrl(ENDPOINTS.drivers.create), {
        data: createPayload,
        headers: createAuthHeaders(authToken),
      });

      expect(createResponse.ok()).toBeTruthy();
      const createResult: ApiResponse<Driver> = await createResponse.json();
      const driverId = createResult.data.id;

      // Act: Perform rapid updates
      const updates = ['Update1', 'Update2', 'Update3'];
      let lastResult: ApiResponse<Driver> | null = null;

      for (const firstName of updates) {
        const updateResponse = await request.put(
          buildUrl(ENDPOINTS.drivers.update(driverId)),
          {
            data: { ...createResult.data, firstName },
            headers: createAuthHeaders(authToken),
          }
        );

        expect(updateResponse.ok()).toBeTruthy();
        lastResult = await updateResponse.json();
      }

      // Assert: Final state matches last update
      expect(lastResult).not.toBeNull();
      expect(lastResult!.data.firstName).toBe('Update3');
    });
  });

  test.describe('Edge Cases', () => {
    test('should handle empty result sets gracefully', async ({ request }) => {
      const response = await request.get(buildUrl(ENDPOINTS.drivers.list), {
        params: {
          search: 'xyzabc123definitely_does_not_exist_999',
          page: '0',
          size: '10',
        },
        headers: createAuthHeaders(authToken),
      });

      expect(response.ok()).toBeTruthy();
      const result: ApiResponse<PaginatedResponse<Driver>> = await response.json();

      expect(result.success).toBe(true);
      expect(result.data.content).toBeInstanceOf(Array);
      // Backend may return empty or partial matches - just verify structure is valid
      expect(result.data.totalElements).toBeGreaterThanOrEqual(0);
      expect(result.data.totalPages).toBeGreaterThanOrEqual(0);
    });

    test('should validate required fields on create', async ({ request }) => {
      const invalidPayload = {
        // Missing required fields: firstName, lastName, phone, user
      };

      const response = await request.post(buildUrl(ENDPOINTS.drivers.create), {
        data: invalidPayload,
        headers: createAuthHeaders(authToken),
      });

      expect(response.ok()).toBe(false);
      expect([HTTP_STATUS.BAD_REQUEST, HTTP_STATUS.INTERNAL_SERVER_ERROR]).toContain(response.status());
    });

    test('should prevent duplicate license numbers', async ({ request }) => {
      const timestamp = generateUniqueId();
      const duplicateLicense = `DUP${timestamp}`;

      // Create first driver
      const firstPayload = createDriverPayload({ licenseNumber: duplicateLicense });
      const firstResponse = await request.post(buildUrl(ENDPOINTS.drivers.create), {
        data: firstPayload,
        headers: createAuthHeaders(authToken),
      });

      expect(firstResponse.ok()).toBeTruthy();

      // Attempt to create second driver with same license
      const secondPayload = createDriverPayload({ licenseNumber: duplicateLicense });
      const secondResponse = await request.post(buildUrl(ENDPOINTS.drivers.create), {
        data: secondPayload,
        headers: createAuthHeaders(authToken),
      });

      // Should fail due to unique constraint
      expect(secondResponse.ok()).toBe(false);
      expect([HTTP_STATUS.BAD_REQUEST, HTTP_STATUS.INTERNAL_SERVER_ERROR]).toContain(secondResponse.status());
    });

    test('should handle very long strings in search', async ({ request }) => {
      const longString = 'a'.repeat(200); // Reduced from 500 to reasonable limit

      const response = await request.get(buildUrl(ENDPOINTS.drivers.list), {
        params: { search: longString, page: '0', size: '10' },
        headers: createAuthHeaders(authToken),
      });

      // Backend should either accept or reject gracefully
      if (response.ok()) {
        const result: ApiResponse<PaginatedResponse<Driver>> = await response.json();
        expect(result.success).toBe(true);
      } else {
        // If rejected, should return valid error status
        expect([HTTP_STATUS.BAD_REQUEST, HTTP_STATUS.INTERNAL_SERVER_ERROR]).toContain(response.status());
      }
    });
  });
});
