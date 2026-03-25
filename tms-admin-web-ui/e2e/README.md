# E2E Integration Tests - Architecture & Best Practices

## 📚 Table of Contents
- [Overview](#overview)
- [Architecture](#architecture)
- [Best Practices](#best-practices)
- [Test Organization](#test-organization)
- [Running Tests](#running-tests)
- [Maintenance](#maintenance)

## Overview

This test suite provides comprehensive API contract testing for the SV-TMS backend. It follows industry best practices for test organization, maintainability, and reliability.

### Key Features
- **Type-safe**: Full TypeScript support with strict typing
- **DRY Principle**: Reusable helpers and factories
- **Clean Code**: Separation of concerns, constants extraction
- **Real-world**: Follows production testing patterns
- **Fast**: Parallel execution, auth state reuse
- **Reliable**: Proper error handling, timeouts, retries

### Test Coverage
- **65/70 tests passing** (93% success rate)
- 5 browsers: chromium, firefox, webkit, Mobile Chrome, Mobile Safari
- Comprehensive CRUD operations
- Pagination, filtering, error handling
- Authentication and authorization

## Architecture

### Directory Structure
```
e2e/
├── fixtures/
│   └── test-data.ts          # Type-safe test data & factories
├── integration/
│   └── api-contracts.spec.ts # API contract tests
├── setup/
│   ├── global-setup.ts       # Pre-test initialization
│   └── global-teardown.ts    # Post-test cleanup
└── README.md                 # This file
```

### Design Patterns

#### 1. **Factory Pattern** (Test Data)
```typescript
// Bad: Hardcoded test data
const driver = {
  firstName: 'Test',
  lastName: 'Driver',
  phone: '+1234567890',
  // ... repeated everywhere
};

// Good: Factory function
const driver = createTestDriver({ 
  firstName: 'Custom',
  lastName: 'Name' 
});
```

#### 2. **Constants Extraction**
```typescript
// Bad: Magic strings
await request.get('http://localhost:8080/api/admin/drivers/list');

// Good: Named constants
await request.get(buildUrl(ENDPOINTS.drivers.list));
```

#### 3. **Helper Functions**
```typescript
// Bad: Repeated authentication
const response = await request.post(`${API_BASE_URL}/api/auth/login`, {
  data: { username: 'admin', password: 'admin123' }
});
const token = (await response.json()).data.token;

// Good: Extracted helper
const token = await authenticateUser(request);
```

#### 4. **Type Safety**
```typescript
// Bad: Untyped responses
const data = await response.json();
expect(data.data.id).toBe(1); // No autocomplete, no type checking

// Good: Typed responses
const result: ApiResponse<Driver> = await response.json();
expect(result.data.id).toBe(1); // Full IDE support
```

## Best Practices

### 1. Test Structure (AAA Pattern)

```typescript
test('should update driver', async ({ request }) => {
  // Arrange: Setup test data
  const driver = await createDriver(request);
  
  // Act: Perform action
  const response = await updateDriver(request, driver.id, { firstName: 'Updated' });
  
  // Assert: Verify outcome
  expect(response.data.firstName).toBe('Updated');
});
```

### 2. Data Isolation

```typescript
// Each test creates its own data
const timestamp = generateUniqueId();
const driver = createTestDriver({ licenseNumber: `DL${timestamp}` });

// ❌ Never rely on existing data
const response = await request.get('/api/admin/drivers/1'); // Brittle!
```

### 3. Error Handling

```typescript
// Explicit status code checks
expect(response.status()).toBe(HTTP_STATUS.NOT_FOUND);

// Typed error responses
const result: ApiResponse = await response.json();
expect(result.success).toBe(false);

// ❌ Generic error catching
try { ... } catch { /* ignored */ }
```

### 4. Assertions

```typescript
// Specific assertions
expect(driver.id).toBeGreaterThan(0);
expect(driver.status).toBe('ONLINE');
expect(driver.user.email).toMatch(/^[^\s@]+@[^\s@]+\.[^\s@]+$/);

// ❌ Generic assertions
expect(driver).toHaveProperty('id');
expect(driver.status).toBeTruthy();
```

### 5. Constants vs Magic Values

```typescript
// Named constants
const DRIVER_STATUSES = ['ONLINE', 'OFFLINE', 'BUSY'] as const;
expect(DRIVER_STATUSES).toContain(driver.status);

// ❌ Magic arrays
expect(['ONLINE', 'OFFLINE', 'BUSY']).toContain(driver.status);
```

## Test Organization

### 1. Naming Conventions

```typescript
// Test files: *.spec.ts
api-contracts.spec.ts
performance.spec.ts

// Test suites: Describe business feature
test.describe('Driver API Contracts', () => {
  // Tests: Should describe expected behavior
  test('should return paginated driver list', async ({ request }) => {
    // ...
  });
});
```

### 2. Test Independence

Each test should:
- Create its own test data
- Clean up after itself (via global teardown)
- Not depend on execution order
- Be runnable in isolation

```bash
# Run single test
npx playwright test api-contracts.spec.ts:30 --project=chromium
```

### 3. Parallel Execution

Tests run in parallel across 4 workers. Ensure:
- No shared state between tests
- Unique identifiers (timestamps)
- Proper database isolation

## Running Tests

### Quick Start
```bash
cd tms-frontend
SKIP_FRONTEND_CHECK=true npm run test:integration:api
```

### Development
```bash
# Run specific test
npx playwright test api-contracts.spec.ts:30

# Run with UI mode (debugging)
npx playwright test --ui

# Run in headed mode
npx playwright test --headed

# Generate report
npx playwright show-report
```

### CI/CD
```bash
npm ci
SKIP_FRONTEND_CHECK=true npm run test:integration:api
```

### Environment Variables
- `API_BASE_URL`: Backend URL (default: http://localhost:8080)
- `SKIP_FRONTEND_CHECK`: Skip frontend health check for API-only tests

## Maintenance

### Adding New Tests

1. **Define types** in `fixtures/test-data.ts`:
```typescript
export interface TestEntity {
  id?: number;
  name: string;
  // ... other fields
}
```

2. **Create factory** in `fixtures/test-data.ts`:
```typescript
export function createTestEntity(overrides?: Partial<TestEntity>): TestEntity {
  return {
    name: 'Default Name',
    ...overrides,
  };
}
```

3. **Add endpoint** in `integration/api-contracts.spec.ts`:
```typescript
const ENDPOINTS = {
  // ...
  entities: {
    list: '/api/entities',
    create: '/api/entities',
    // ...
  },
};
```

4. **Write test** following AAA pattern:
```typescript
test('should create entity', async ({ request }) => {
  // Arrange
  const payload = createTestEntity({ name: 'Test' });
  
  // Act
  const response = await request.post(buildUrl(ENDPOINTS.entities.create), {
    data: payload,
    headers: createAuthHeaders(authToken),
  });
  
  // Assert
  expect(response.ok()).toBeTruthy();
  const result: ApiResponse<TestEntity> = await response.json();
  expect(result.data.name).toBe('Test');
});
```

### Updating Test Data

When backend schema changes:

1. Update interfaces in `fixtures/test-data.ts`
2. Update factory functions
3. Update existing tests that use changed fields
4. Run tests to verify: `npm run test:integration:api`

### Common Issues

#### Tests failing after backend changes?
1. Check if API contract changed (new required fields, different endpoints)
2. Update types and factories in `test-data.ts`
3. Update assertions in test specs

#### Tests timing out?
1. Verify services are running: `docker ps`
2. Check backend health: `curl http://localhost:8080/actuator/health`
3. Increase timeout if needed in `playwright.config.ts`

#### Authentication failures?
1. Verify admin credentials in `test-data.ts` match backend
2. Check token extraction path in `authenticateUser()`
3. Ensure token is passed in headers: `createAuthHeaders(token)`

## Code Quality Standards

### TypeScript
- Strict mode enabled
- No `any` types (use proper interfaces)
- Explicit return types for functions
- Const assertions for literal types

### Code Style
- Descriptive variable names
- Single responsibility per function
- DRY - Don't Repeat Yourself
- Comments for "why", not "what"
- Consistent formatting (Prettier)

### Testing
- One assertion per test (where possible)
- Arrange-Act-Assert pattern
- Descriptive test names
- Test isolation (no dependencies)
- Proper error handling

## Resources

- [Playwright Documentation](https://playwright.dev)
- [API Testing Best Practices](https://playwright.dev/docs/api-testing)
- [TypeScript Handbook](https://www.typescriptlang.org/docs/handbook/)
- Project Documentation: `/INTEGRATION_TESTS_FINAL_STATUS.md`

---

**Last Updated**: December 4, 2025  
**Test Suite Version**: 1.0.0  
**Playwright Version**: 1.57.0
