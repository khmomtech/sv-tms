> [!WARNING]
> Legacy document notice: This file is kept for history and may be outdated.
> Use `/Users/sotheakh/Documents/develop/sv-tms/docs/README.md` for active documentation.

# 🚀 Running Integration Tests - TMS Backend + Frontend

## Quick Run

```bash
# Option 1: Use the automated script
cd /Users/sotheakh/Documents/develop/sv-tms
chmod +x quick-integration-test.sh
./quick-integration-test.sh

# Option 2: Run directly from frontend folder
cd tms-frontend
npm run test:integration

# Option 3: Run using the comprehensive test runner
cd /Users/sotheakh/Documents/develop/sv-tms/tms-frontend
chmod +x run-e2e-tests.sh
./run-e2e-tests.sh integration
```

## Prerequisites

### 1. Backend Must Be Running
The backend must be running on port 8080:

```bash
# Terminal 1: Start backend
cd driver-app
./mvnw spring-boot:run

# Wait for: "Started DriverAppApplication"
```

### 2. Frontend Dependencies Installed
```bash
cd tms-frontend
npm install
npx playwright install chromium
```

## Integration Test Suites

### 1. All Integration Tests (API + WebSocket)
```bash
cd tms-frontend
npm run test:integration
```

**Runs:**
- 160+ API contract tests
- 80+ WebSocket integration tests
- **Total: 240+ tests**

### 2. API Contract Tests Only
```bash
npm run test:integration:api
```

**Tests:**
- Driver API endpoints
- Vehicle API endpoints
- Authentication
- Pagination
- Filtering
- Error handling

### 3. WebSocket Integration Tests Only
```bash
npm run test:integration:ws
```

**Tests:**
- WebSocket connection
- STOMP protocol
- Real-time message delivery
- High-volume messaging
- Connection recovery

## Environment Variables

```bash
# Backend URL (default: http://localhost:8080)
export API_BASE_URL=http://localhost:8080

# Frontend URL (default: http://localhost:4200)
export BASE_URL=http://localhost:4200

# Run tests
npm run test:integration
```

## View Results

### HTML Report (Interactive)
```bash
npx playwright show-report
```

### JSON Report
```bash
cat test-results/results.json | jq
```

### JUnit Report (for CI)
```bash
cat test-results/junit.xml
```

## Common Issues

### Backend Not Running
```
Error: connect ECONNREFUSED localhost:8080
```

**Solution:**
```bash
cd driver-app
./mvnw spring-boot:run
```

### Playwright Browsers Not Installed
```
Error: browserType.launch: Executable doesn't exist
```

**Solution:**
```bash
npx playwright install --with-deps chromium
```

### Authentication Failing
```
Error: 401 Unauthorized
```

**Check:**
- Backend is fully started
- Database is initialized
- Default admin user exists

## Test Execution Flow

```
┌─────────────────────────────────────────┐
│  1. Start Backend (port 8080)           │
│     ├─ MySQL connection                 │
│     ├─ Redis connection                 │
│     └─ REST API ready                   │
└─────────────────────────────────────────┘
              ↓
┌─────────────────────────────────────────┐
│  2. Run Integration Tests               │
│     ├─ Authenticate                     │
│     ├─ Test API contracts               │
│     ├─ Test WebSocket                   │
│     └─ Verify responses                 │
└─────────────────────────────────────────┘
              ↓
┌─────────────────────────────────────────┐
│  3. Generate Reports                    │
│     ├─ HTML report                      │
│     ├─ JSON results                     │
│     └─ JUnit XML                        │
└─────────────────────────────────────────┘
```

## Expected Results

**Success Output:**
```
Running 240 tests using 4 workers

  ✓ [chromium] › api-contracts.spec.ts:30:5 › API Contract Tests › Driver API...
  ✓ [chromium] › api-contracts.spec.ts:45:5 › API Contract Tests › Driver API...
  ...
  ✓ [chromium] › websocket-integration.spec.ts:25:5 › WebSocket Integration...

240 passed (2m 30s)
```

## Performance Expectations

| Test Suite | Tests | Duration |
|------------|-------|----------|
| API Contracts | 160+ | ~1-2 min |
| WebSocket | 80+ | ~30-60 sec |
| **Total** | **240+** | **~3-5 min** |

## Next Steps

After integration tests pass:

1. **Run E2E Flow Tests:**
   ```bash
   npm run test:flows
   ```

2. **Run Full Test Suite:**
   ```bash
   npm run test:all
   ```

3. **Performance Tests:**
   ```bash
   npm run test:performance
   ```

---

**Ready to run?** Execute:
```bash
./quick-integration-test.sh
```
