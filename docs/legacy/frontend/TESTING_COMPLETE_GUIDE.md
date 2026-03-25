> [!WARNING]
> Legacy document notice: This file is kept for history and may be outdated.
> Use `/Users/sotheakh/Documents/develop/sv-tms/docs/README.md` for active documentation.

# Testing Complete Guide for SV-TMS

## 📋 Overview

This guide covers all testing aspects of the SV-TMS project, from unit tests to end-to-end tests, performance testing, and visual regression testing.

## 🎯 Test Coverage

### Current Test Statistics (as of latest run)

- **Unit Tests**: 650+ tests
  - Service tests: 390+ tests
  - Component tests: 260+ tests
- **Integration Tests**: 240+ tests
  - API contract tests: 160+ tests
  - WebSocket tests: 80+ tests
- **E2E Flow Tests**: 230+ tests
  - Driver CRUD flows: 150+ tests
  - Vehicle CRUD flows: 80+ tests
- **Performance Tests**: 120+ benchmarks
- **Visual Regression Tests**: 100+ snapshots

**Total**: 1,340+ automated tests

## 🚀 Quick Start

### Prerequisites

```bash
# Ensure you have the correct Node version
node --version  # Should be >= 20.19.0

# Install dependencies
cd tms-frontend
npm install

# Install Playwright browsers
npx playwright install
```

### Running Tests

#### 1. Unit Tests (Fastest - ~2-3 minutes)

```bash
# Run all unit tests with coverage
npm run test:coverage

# Run in watch mode (for development)
npm test

# Run specific test file
npm run test:unit:one -- --include="src/app/services/driver.service.spec.ts"

# CI mode (headless, no watch)
npm run test:ci
```

#### 2. Integration Tests (~5 minutes)

**Requires backend running on port 8080**

```bash
# Start backend first
cd ../driver-app
./mvnw spring-boot:run

# In another terminal, run integration tests
cd tms-frontend
npm run test:integration

# Or run specific suites
npm run test:integration:api      # API contract tests
npm run test:integration:ws       # WebSocket tests
```

#### 3. E2E Flow Tests (~10 minutes)

**Requires both backend and frontend running**

```bash
# Run all E2E flow tests
npm run test:flows

# Or run specific flows
npm run test:flows:driver    # Driver CRUD flows
npm run test:flows:vehicle   # Vehicle CRUD flows

# Debug mode (opens browser)
npm run test:e2e:debug

# UI mode (interactive)
npm run test:e2e:ui
```

#### 4. Performance Tests (~15 minutes)

```bash
# Run performance benchmarks
npm run test:performance
```

#### 5. Visual Regression Tests (~20 minutes)

```bash
# Run visual regression tests
npm run test:visual

# Update snapshots (after intentional UI changes)
npm run test:visual:update
```

#### 6. Run Everything (~30 minutes)

```bash
# Run all tests sequentially
npm run test:all

# Quick smoke test (unit + API integration)
npm run test:quick
```

## 🐳 Running Tests with Docker

### Using Docker Compose Test Environment

```bash
# From project root
./run-e2e-docker.sh all          # Run all tests
./run-e2e-docker.sh api          # API tests only
./run-e2e-docker.sh flows        # Flow tests only
./run-e2e-docker.sh --help       # Show help

# Keep containers running for debugging
./run-e2e-docker.sh all --no-cleanup

# Show container logs
./run-e2e-docker.sh all --logs
```

### Manual Docker Setup

```bash
# Start test environment
docker compose -f docker-compose.test.yml up -d

# Wait for services to be ready
curl http://localhost:8081/actuator/health  # Backend
curl http://localhost:4201                   # Frontend

# Run tests
cd tms-frontend
API_BASE_URL=http://localhost:8081 BASE_URL=http://localhost:4201 npm run test:e2e

# Cleanup
docker compose -f docker-compose.test.yml down -v
```

## 🔧 Test Configuration

### Playwright Configuration

Located in `tms-frontend/playwright.config.js`

Key settings:

- **Timeout**: 30 seconds per test
- **Retries**: 2 on CI, 0 locally
- **Workers**: 1 on CI, 4 locally (parallel)
- **Browsers**: Chromium, Firefox, WebKit, Mobile Chrome, Mobile Safari

### Environment Variables

```bash
# Backend API URL (for integration/E2E tests)
API_BASE_URL=http://localhost:8080

# Frontend URL (for E2E tests)
BASE_URL=http://localhost:4200

# CI mode (affects retries, parallelism)
CI=true
```

### Test Fixtures

Reusable test data available in `e2e/fixtures/test-data.ts`:

- `validDrivers` - Sample driver data
- `validVehicles` - Sample vehicle data
- `testUsers` - Test users (admin, dispatcher, driver)
- `generateBulkDrivers(count)` - Generate bulk data for performance tests
- `performanceThresholds` - Performance targets
- `viewports` - Responsive design breakpoints

## 📊 Test Reports

### After Running Tests

#### Unit Test Coverage

```bash
# Open coverage report in browser
open tms-frontend/coverage/lcov-report/index.html
```

#### Playwright HTML Report

```bash
# Auto-opens after test run, or manually:
npx playwright show-report
```

#### CI/CD Reports

- **GitHub Actions**: Test results uploaded as artifacts
- **JUnit XML**: `test-results/junit.xml` (for CI integration)
- **JSON**: `test-results/results.json` (for parsing)

## 🎭 Test Fixtures & Helpers

### Authentication

Global setup handles authentication automatically. Auth state saved to:

- `playwright/.auth/admin.json`

### Mock Data

Use fixtures from `e2e/fixtures/test-data.ts`:

```typescript
import { validDrivers, testUsers } from "../fixtures/test-data";

// In your test
const driver = validDrivers[0];
await page.fill("#name", driver.fullName);
```

### Performance Helpers

```typescript
import { performanceThresholds } from "../fixtures/test-data";

// Assert response time
const startTime = Date.now();
await page.goto("/drivers");
const loadTime = Date.now() - startTime;
expect(loadTime).toBeLessThan(performanceThresholds.pageLoad);
```

## 🚨 Troubleshooting

### Backend Not Available

```bash
# Check backend health
curl http://localhost:8080/actuator/health

# Check logs
cd driver-app
tail -f logs/spring-boot-application.log

# Restart backend
./mvnw spring-boot:run
```

### Frontend Not Starting

```bash
# Check if port 4200 is in use
lsof -i :4200

# Kill process and restart
kill -9 <PID>
npm run start
```

### Test Failures

#### TimeoutError

- Increase timeout in test: `test.setTimeout(60000);`
- Check if services are running
- Network issues?

#### Element Not Found

- Check if UI has changed
- Wait for element: `await page.waitForSelector('#element')`
- Check responsive design (viewport size)

#### Visual Regression Failures

- Intentional UI change? Update snapshots: `npm run test:visual:update`
- Font rendering differences? Review snapshot diff
- Animation timing? Add wait before snapshot

### Docker Issues

```bash
# Check Docker status
docker ps

# View logs
docker compose -f docker-compose.test.yml logs backend-test
docker compose -f docker-compose.test.yml logs frontend-test

# Rebuild images
docker compose -f docker-compose.test.yml up -d --build

# Clean everything
docker compose -f docker-compose.test.yml down -v
docker system prune -a
```

## 🔄 CI/CD Integration

### GitHub Actions Workflow

Located in `.github/workflows/e2e-tests.yml`

**Triggers:**

- Push to `main` or `develop`
- Pull requests to `main` or `develop`
- Manual workflow dispatch

**Jobs:**

1. **Unit Tests** - Runs on every commit
2. **Integration Tests** - Runs with MySQL/Redis services
3. **E2E Tests** - Full stack with backend + frontend
4. **Performance Tests** - Only on `main` branch pushes
5. **Test Report** - Aggregates results

### Pre-commit Hooks

Located in `.pre-commit-config.yaml`

**Runs before commit:**

- Unit tests (fast subset)
- ESLint
- Prettier format check
- Trailing whitespace fix
- Large file check

**Setup:**

```bash
# Install pre-commit
pip install pre-commit

# Install git hooks
pre-commit install

# Run manually
pre-commit run --all-files
```

## 📚 Writing New Tests

### Unit Test Template

```typescript
import { TestBed } from "@angular/core/testing";
import { MyService } from "./my.service";

describe("MyService", () => {
  let service: MyService;

  beforeEach(() => {
    TestBed.configureTestingModule({});
    service = TestBed.inject(MyService);
  });

  it("should be created", () => {
    expect(service).toBeTruthy();
  });

  it("should perform action", () => {
    const result = service.performAction();
    expect(result).toBe(expected);
  });
});
```

### E2E Test Template

```typescript
import { test, expect } from "@playwright/test";
import { validDrivers } from "../fixtures/test-data";

test.describe("Feature Name", () => {
  test("should perform user action", async ({ page }) => {
    // Arrange
    await page.goto("/feature");
    const testData = validDrivers[0];

    // Act
    await page.fill("#input", testData.value);
    await page.click('button[type="submit"]');

    // Assert
    await expect(page.locator(".success-message")).toBeVisible();
  });
});
```

### Integration Test Template

```typescript
import { test, expect } from "@playwright/test";

test.describe("API Contract: /api/endpoint", () => {
  const apiUrl = process.env["API_BASE_URL"] || "http://localhost:8080";

  test("GET /api/endpoint returns 200", async ({ request }) => {
    const response = await request.get(`${apiUrl}/api/endpoint`);
    expect(response.ok()).toBeTruthy();

    const data = await response.json();
    expect(data).toHaveProperty("expectedField");
  });
});
```

## 🎯 Best Practices

### 1. Test Organization

- Group related tests with `describe()`
- Use clear, descriptive test names
- Follow AAA pattern (Arrange, Act, Assert)

### 2. Test Independence

- Each test should be independent
- Don't rely on test execution order
- Clean up after tests (use global teardown)

### 3. Performance

- Use fixtures to avoid duplication
- Parallelize when possible (`fullyParallel: true`)
- Mock external services in unit tests

### 4. Maintainability

- Use Page Object Model for E2E tests
- Extract common helpers
- Keep tests DRY (Don't Repeat Yourself)

### 5. CI/CD

- Run fast tests first (unit → integration → E2E)
- Fail fast on critical issues
- Upload artifacts for debugging

## 📖 Additional Resources

- [Playwright Documentation](https://playwright.dev/)
- [Jasmine Documentation](https://jasmine.github.io/)
- [Karma Documentation](https://karma-runner.github.io/)
- [Angular Testing Guide](https://angular.io/guide/testing)

## 🆘 Getting Help

1. Check this guide first
2. Review test logs and reports
3. Check GitHub Actions logs (for CI failures)
4. Ask team members in Slack/Teams
5. Create GitHub issue with reproduction steps

---

**Last Updated**: 2025-01-XX
**Maintained By**: Development Team
