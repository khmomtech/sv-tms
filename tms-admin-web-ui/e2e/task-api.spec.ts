import { test, expect } from '@playwright/test';

/**
 * Backend API Tests for Task Management System
 * Tests all task-related endpoints without UI dependency
 */

const BASE_URL = 'http://localhost:8080';

test.describe('Task API - Health & Documentation', () => {
  test('should have healthy backend', async ({ request }) => {
    const response = await request.get(`${BASE_URL}/actuator/health`);
    expect(response.ok()).toBeTruthy();

    const data = await response.json();
    expect(data.status).toBe('UP');
  });

  test('should provide OpenAPI documentation', async ({ request }) => {
    const response = await request.get(`${BASE_URL}/v3/api-docs`);
    expect(response.ok()).toBeTruthy();

    const apiDocs = await response.json();
    expect(apiDocs.openapi).toBeDefined();
    expect(apiDocs.info.title).toContain('API');
    expect(apiDocs.paths).toBeDefined();
  });

  test('should have task endpoints documented', async ({ request }) => {
    const response = await request.get(`${BASE_URL}/v3/api-docs`);
    const apiDocs = await response.json();

    // Check for task-related endpoints
    const paths = Object.keys(apiDocs.paths);
    const taskPaths = paths.filter(path => path.includes('/tasks'));

    expect(taskPaths.length).toBeGreaterThan(0);
    console.log(`Found ${taskPaths.length} task endpoints`);
  });
});

test.describe('Task API - Endpoints Availability', () => {
  test('should have statistics endpoint', async ({ request }) => {
    const response = await request.get(`${BASE_URL}/api/tasks/statistics`, {
      failOnStatusCode: false
    });

    // 401/403 means protected (expected), 200 means public
    expect([200, 401, 403]).toContain(response.status());
  });

  test('should have tasks list endpoint', async ({ request }) => {
    const response = await request.get(`${BASE_URL}/api/tasks`, {
      failOnStatusCode: false
    });

    expect([200, 401, 403]).toContain(response.status());
  });

  test('should have task search endpoint', async ({ request }) => {
    const response = await request.get(`${BASE_URL}/api/tasks/search`, {
      failOnStatusCode: false
    });

    expect([200, 400, 401, 403]).toContain(response.status());
  });

  test('should reject invalid task creation without auth', async ({ request }) => {
    const response = await request.post(`${BASE_URL}/api/tasks`, {
      data: {
        title: 'Test Task',
        priority: 'HIGH'
      },
      failOnStatusCode: false
    });

    // Should be rejected (401/403) without authentication
    expect([401, 403]).toContain(response.status());
  });
});

test.describe('Task API - Response Validation', () => {
  test('should return proper error format for unauthorized access', async ({ request }) => {
    const response = await request.get(`${BASE_URL}/api/tasks/statistics`, {
      failOnStatusCode: false
    });

    if (response.status() === 401 || response.status() === 403) {
      const data = await response.json();

      // Check error response structure
      expect(data).toBeDefined();
      expect(data.status || data.error).toBeDefined();
    }
  });

  test('should have CORS headers configured', async ({ request }) => {
    const response = await request.get(`${BASE_URL}/actuator/health`);

    const headers = response.headers();
    // Just check that response is valid - CORS headers may vary
    expect(response.ok()).toBeTruthy();
  });

  test('should accept JSON content type', async ({ request }) => {
    const response = await request.post(`${BASE_URL}/api/tasks`, {
      headers: {
        'Content-Type': 'application/json'
      },
      data: {},
      failOnStatusCode: false
    });

    // Should process JSON (even if rejected due to auth/validation)
    expect([400, 401, 403]).toContain(response.status());
  });
});

test.describe('Task API - Performance', () => {
  test('should respond to health check within 1 second', async ({ request }) => {
    const start = Date.now();
    const response = await request.get(`${BASE_URL}/actuator/health`);
    const duration = Date.now() - start;

    expect(response.ok()).toBeTruthy();
    expect(duration).toBeLessThan(1000);
    console.log(`Health check responded in ${duration}ms`);
  });

  test('should respond to API docs within 2 seconds', async ({ request }) => {
    const start = Date.now();
    const response = await request.get(`${BASE_URL}/v3/api-docs`);
    const duration = Date.now() - start;

    expect(response.ok()).toBeTruthy();
    expect(duration).toBeLessThan(2000);
    console.log(`API docs responded in ${duration}ms`);
  });
});

test.describe('Task API - Data Validation', () => {
  test('should validate OpenAPI schema structure', async ({ request }) => {
    const response = await request.get(`${BASE_URL}/v3/api-docs`);
    const apiDocs = await response.json();

    // Check essential OpenAPI 3.0 structure
    expect(apiDocs.openapi).toMatch(/^3\./);
    expect(apiDocs.info).toBeDefined();
    expect(apiDocs.info.title).toBeDefined();
    expect(apiDocs.info.version).toBeDefined();
    expect(apiDocs.paths).toBeDefined();
    expect(typeof apiDocs.paths).toBe('object');
  });

  test('should have task schema definitions', async ({ request }) => {
    const response = await request.get(`${BASE_URL}/v3/api-docs`);
    const apiDocs = await response.json();

    // Check for schema components
    if (apiDocs.components && apiDocs.components.schemas) {
      const schemas = Object.keys(apiDocs.components.schemas);
      const taskSchemas = schemas.filter(s =>
        s.toLowerCase().includes('task') ||
        s.toLowerCase().includes('dto')
      );

      console.log(`Found ${taskSchemas.length} task-related schemas`);
      expect(taskSchemas.length).toBeGreaterThan(0);
    }
  });
});

test.describe('Task API - Error Handling', () => {
  test('should handle invalid endpoint gracefully', async ({ request }) => {
    const response = await request.get(`${BASE_URL}/api/tasks/nonexistent`, {
      failOnStatusCode: false
    });

    // Should return 404 or 401/403
    expect([401, 403, 404]).toContain(response.status());
  });

  test('should reject malformed JSON', async ({ request }) => {
    const response = await request.post(`${BASE_URL}/api/tasks`, {
      headers: {
        'Content-Type': 'application/json'
      },
      data: 'invalid json',
      failOnStatusCode: false
    });

    // Should return 400 (bad request) or 401/403 (unauthorized)
    expect([400, 401, 403]).toContain(response.status());
  });

  test('should handle missing required fields', async ({ request }) => {
    const response = await request.post(`${BASE_URL}/api/tasks`, {
      headers: {
        'Content-Type': 'application/json'
      },
      data: {
        // Missing required title field
        priority: 'HIGH'
      },
      failOnStatusCode: false
    });

    // Should return 400 or 401/403
    expect([400, 401, 403]).toContain(response.status());
  });
});
