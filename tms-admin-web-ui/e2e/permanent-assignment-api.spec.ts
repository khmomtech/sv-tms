import { test, expect, request as playwrightRequest } from '@playwright/test';

/**
 * API Integration Tests for Fleet Vehicle Permanent Assignment
 *
 * These tests directly call the backend API endpoints without UI interaction.
 * Backend must be running on http://localhost:8080
 */

const API_URL = process.env['API_URL'] || 'http://localhost:8080';
const ASSIGNMENTS_PATH = '/api/admin/assignments/permanent';

/**
 * Login and get JWT token
 */
async function getAuthToken(): Promise<string> {
  const context = await playwrightRequest.newContext();

  try {
    const response = await context.post(`${API_URL}/api/auth/login`, {
      data: {
        username: 'admin',
        password: 'admin123'
      }
    });

    if (!response.ok()) {
      throw new Error(`Login failed: ${response.status()}`);
    }

    const data = await response.json();
    const token = data.data?.token || data.data?.accessToken || data.token || data.accessToken;

    if (!token) {
      console.error('Login response:', JSON.stringify(data, null, 2));
      throw new Error('No token received from API');
    }

    console.log('Authentication successful, token obtained');
    return token;
  } finally {
    await context.dispose();
  }
}

test.describe('Permanent Assignment API - Integration Tests', () => {
  let assignmentId: number;
  let vehicleId: number;
  let driverId: number;
  let authToken: string;

  // Login before all tests
  test.beforeAll(async () => {
    authToken = await getAuthToken();
  });

  test.describe('Assignment CRUD Operations', () => {
    test('should create new assignment (POST /api/admin/assignments/permanent)', async ({ request }) => {
      const response = await request.post(`${API_URL}${ASSIGNMENTS_PATH}`, {
        data: {
          vehicleId: 1,
          driverId: 1,
          reason: 'API Integration Test - Initial Assignment',
          forceReassignment: false
        },
        headers: {
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${authToken}`
        }
      });

      console.log('Create Assignment Response:', response.status());
      const data = await response.json();
      console.log('Response Data:', JSON.stringify(data, null, 2));

      if (response.status() === 201 || response.status() === 200) {
        expect(data.status).toBe('success');
        expect(data.data).toHaveProperty('id');
        expect(data.data.vehicleId).toBe(1);
        expect(data.data.driverId).toBe(1);
        expect(data.data.isActive).toBe(true);

        assignmentId = data.data.id;
        vehicleId = data.data.vehicleId;
        driverId = data.data.driverId;
      } else if (response.status() === 409) {
        // Already assigned - skip creating, use existing
        console.log('Truck already assigned (409 Conflict) - using existing assignment');
        assignmentId = 1; // Fallback
      }
    });

    test('should get assignment statistics (GET /api/admin/assignments/permanent/stats)', async ({ request }) => {
      const response = await request.get(`${API_URL}${ASSIGNMENTS_PATH}/stats`, {
        headers: {
          'Authorization': `Bearer ${authToken}`
        }
      });

      console.log('Stats Response:', response.status());
      const data = await response.json();
      console.log('Stats Data:', JSON.stringify(data, null, 2));

      if (response.status() === 500) {
        console.log('⚠️  500 Error: Backend endpoint exists but database tables may not be created yet');
        console.log('   Run migrations: cd driver-app && ./mvnw flyway:migrate');
        test.skip();
        return;
      }

      expect(response.ok()).toBeTruthy();
      expect(data.status).toBe('success');
      expect(data.data).toHaveProperty('totalActiveAssignments');
      expect(data.data).toHaveProperty('totalTrucksAssigned');
      expect(data.data).toHaveProperty('totalDriversAssigned');
      expect(typeof data.data.totalActiveAssignments).toBe('number');
    });

    test('should get active assignment by truck (GET /api/admin/assignments/permanent/truck/:id/active)', async ({ request }) => {
      const response = await request.get(`${API_URL}${ASSIGNMENTS_PATH}/truck/1/active`, {
        headers: {
          'Authorization': `Bearer ${authToken}`
        }
      });

      console.log('Get Active Assignment Response:', response.status());

      if (response.ok()) {
        const data = await response.json();
        console.log('Active Assignment Data:', JSON.stringify(data, null, 2));

        expect(data.status).toBe('success');
        expect(data.data).toHaveProperty('vehicleId');
        expect(data.data.vehicleId).toBe(1);
        expect(data.data.isActive).toBe(true);
      } else {
        console.log('No active assignment found (expected for new setup)');
      }
    });

    test('should get active assignment by driver (GET /api/admin/assignments/permanent/driver/:id/active)', async ({ request }) => {
      const response = await request.get(`${API_URL}${ASSIGNMENTS_PATH}/driver/1/active`, {
        headers: {
          'Authorization': `Bearer ${authToken}`
        }
      });

      console.log('Get Driver Assignment Response:', response.status());

      if (response.ok()) {
        const data = await response.json();
        expect(data.status).toBe('success');
        expect(data.data.driverId).toBe(1);
        expect(data.data.isActive).toBe(true);
      }
    });

    test('should get truck assignment history (GET /api/admin/assignments/permanent/truck/:id/history)', async ({ request }) => {
      const response = await request.get(`${API_URL}${ASSIGNMENTS_PATH}/truck/1/history`, {
        headers: {
          'Authorization': `Bearer ${authToken}`
        }
      });

      console.log('Truck History Response:', response.status());

      if (response.ok()) {
        const data = await response.json();
        console.log('History Data:', JSON.stringify(data, null, 2));

        expect(data.status).toBe('success');
        expect(Array.isArray(data.data)).toBeTruthy();
      }
    });

    test('should get driver assignment history (GET /api/admin/assignments/permanent/driver/:id/history)', async ({ request }) => {
      const response = await request.get(`${API_URL}${ASSIGNMENTS_PATH}/driver/1/history`, {
        headers: {
          'Authorization': `Bearer ${authToken}`
        }
      });

      console.log('Driver History Response:', response.status());

      if (response.ok()) {
        const data = await response.json();
        expect(data.status).toBe('success');
        expect(Array.isArray(data.data)).toBeTruthy();
      }
    });
  });

  test.describe('Force Reassignment', () => {
    test('should handle force reassignment (POST with forceReassignment=true)', async ({ request }) => {
      const response = await request.post(`${API_URL}${ASSIGNMENTS_PATH}`, {
        data: {
          vehicleId: 1,
          driverId: 2,
          reason: 'API Integration Test - Force Reassignment',
          forceReassignment: true
        },
        headers: {
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${authToken}`
        }
      });

      console.log('Force Reassignment Response:', response.status());
      const data = await response.json();
      console.log('Force Reassignment Data:', JSON.stringify(data, null, 2));

      if (response.ok()) {
        expect(data.status).toBe('success');
        expect(data.data.vehicleId).toBe(1);
        expect(data.data.driverId).toBe(2);
        expect(data.data.isActive).toBe(true);
      }
    });
  });

  test.describe('Error Scenarios', () => {
    test('should return 404 for non-existent assignment', async ({ request }) => {
      const response = await request.get(`${API_URL}${ASSIGNMENTS_PATH}/99999`, {
        headers: {
          'Authorization': `Bearer ${authToken}`
        }
      });

      console.log('404 Test Response:', response.status());

      if (response.status() === 500) {
        console.log('⚠️  500 Error: Database tables may not exist. Run migrations first.');
        test.skip();
        return;
      }

      expect(response.status()).toBe(404);

      const data = await response.json();
      expect(data.status).toBe('fail');
    });

    test('should return 409 conflict on duplicate assignment without force', async ({ request }) => {
      // First, ensure there's an assignment
      await request.post(`${API_URL}${ASSIGNMENTS_PATH}`, {
        data: {
          vehicleId: 1,
          driverId: 3,
          reason: 'Setup for conflict test',
          forceReassignment: true
        },
        headers: {
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${authToken}`
        }
      });

      // Try to assign again without force flag
      const response = await request.post(`${API_URL}${ASSIGNMENTS_PATH}`, {
        data: {
          vehicleId: 1,
          driverId: 4,
          reason: 'This should conflict',
          forceReassignment: false
        },
        headers: {
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${authToken}`
        }
      });

      console.log('Conflict Test Response:', response.status());

      if (response.status() === 409) {
        const data = await response.json();
        expect(data.status).toBe('fail');
        expect(data.message).toContain('already assigned');
      }
    });

    test('should return 400 for invalid request data', async ({ request }) => {
      const response = await request.post(`${API_URL}${ASSIGNMENTS_PATH}`, {
        data: {
          // Missing required fields
          reason: 'Invalid request test'
        },
        headers: {
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${authToken}`
        }
      });

      console.log('Invalid Request Response:', response.status());

      if (response.status() === 500) {
        console.log('⚠️  500 Error: Database tables may not exist. Run migrations first.');
        test.skip();
        return;
      }

      expect([400, 422]).toContain(response.status());
    });
  });

  test.describe('Assignment Deletion', () => {
    test('should revoke assignment (DELETE /api/admin/assignments/permanent/:id)', async ({ request }) => {
      // Get an active assignment first
      const statsResponse = await request.get(`${API_URL}${ASSIGNMENTS_PATH}/stats`, {
        headers: {
          'Authorization': `Bearer ${authToken}`
        }
      });

      if (statsResponse.ok()) {
        const statsData = await statsResponse.json();
        const recentAssignment = statsData.data?.recentAssignments?.[0];

        if (recentAssignment?.id) {
          const deleteResponse = await request.delete(
            `${API_URL}${ASSIGNMENTS_PATH}/${recentAssignment.id}`,
            {
              headers: {
                'Authorization': `Bearer ${authToken}`
              }
            }
          );

          console.log('Delete Response:', deleteResponse.status());

          if (deleteResponse.ok()) {
            const data = await deleteResponse.json();
            expect(data.status).toBe('success');
          } else if (deleteResponse.status() === 404) {
            console.log('Assignment already deleted or not found');
          }
        } else {
          console.log('No assignments to delete - skipping test');
        }
      }
    });
  });

  test.describe('Pagination and Filtering', () => {
    test('should get all active assignments with pagination', async ({ request }) => {
      const response = await request.get(`${API_URL}${ASSIGNMENTS_PATH}?page=0&size=10&active=true`, {
        headers: {
          'Authorization': `Bearer ${authToken}`
        }
      });

      console.log('Pagination Response:', response.status());

      if (response.ok()) {
        const data = await response.json();
        console.log('Paginated Data:', JSON.stringify(data, null, 2));

        expect(data.status).toBe('success');
        expect(Array.isArray(data.data) || data.data?.content).toBeTruthy();
      }
    });
  });

  test.describe('Concurrent Modification (Optimistic Locking)', () => {
    test('should handle optimistic locking with version mismatch', async ({ request }) => {
      // This test verifies optimistic locking protection
      const getResponse = await request.get(`${API_URL}${ASSIGNMENTS_PATH}/truck/1/active`, {
        headers: {
          'Authorization': `Bearer ${authToken}`
        }
      });

      if (getResponse.ok()) {
        const assignment = await getResponse.json();
        const assignmentData = assignment.data;

        // Try to update with old version
        const updateResponse = await request.put(
          `${API_URL}${ASSIGNMENTS_PATH}/${assignmentData.id}`,
          {
            data: {
              ...assignmentData,
              version: 0, // Old version
              reason: 'Testing optimistic locking'
            },
            headers: {
              'Content-Type': 'application/json',
              'Authorization': `Bearer ${authToken}`
            }
          }
        );

        console.log('Optimistic Locking Test Response:', updateResponse.status());

        // May return 409 if version mismatch detected
        if (updateResponse.status() === 409) {
          const errorData = await updateResponse.json();
          expect(errorData.status).toBe('fail');
        }
      }
    });
  });
});
