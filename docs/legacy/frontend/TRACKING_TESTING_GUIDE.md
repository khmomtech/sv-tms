> [!WARNING]
> Legacy document notice: This file is kept for history and may be outdated.
> Use `/Users/sotheakh/Documents/develop/sv-tms/docs/README.md` for active documentation.

# 🧪 Tracking System - Testing Guide

## Overview
Comprehensive testing strategy for the public shipment tracking system covering backend API, frontend components, and end-to-end integration.

---

## 📁 Test Files Created

### Backend Tests
- [`PublicTrackingControllerTest.java`](tms-backend/src/test/java/com/svtrucking/logistics/controller/PublicTrackingControllerTest.java) - Unit tests for tracking API

### Frontend Tests  
- [`shipment-tracking.component.spec.ts`](tms-frontend/src/app/components/shipment-tracking/shipment-tracking.component.spec.ts) - Component tests

### Integration Tests
- [`test-tracking-api.sh`](test-tracking-api.sh) - Automated API integration tests
- [`test-tracking-data.sql`](test-tracking-data.sql) - Test data setup script

---

## 🚀 Quick Start

### 1. Setup Test Data
```bash
# Load test data into database
mysql -u root -p tms_db < test-tracking-data.sql

# Verify test data
mysql -u root -p tms_db -e "SELECT order_reference, status FROM transport_orders WHERE order_reference LIKE 'BK-2026-001%'"
```

### 2. Run Backend Unit Tests
```bash
cd tms-backend

# Run all tests
./mvnw test

# Run only tracking controller tests
./mvnw test -Dtest=PublicTrackingControllerTest

# Run with coverage report
./mvnw clean verify
# Report: target/site/jacoco/index.html
```

### 3. Run Frontend Tests
```bash
cd tms-frontend

# Run all tests (watch mode)
npm test

# Run tests once with coverage
npm run test:ci

# Run specific test file
npm test -- --include='**/shipment-tracking.component.spec.ts'
```

### 4. Run Integration Tests
```bash
# Start backend and database first
docker compose -f docker-compose.dev.yml up mysql redis -d
cd tms-backend && ./mvnw spring-boot:run

# In another terminal, run integration tests
./test-tracking-api.sh

# Test with custom reference
TEST_REFERENCE=BK-2026-00126 ./test-tracking-api.sh
```

---

## 📊 Test Coverage

### Backend Tests (PublicTrackingControllerTest.java)

#### ✅ Endpoint Tests
- [x] GET /api/public/tracking/{reference} - Valid reference
- [x] GET /api/public/tracking/{reference} - Invalid reference
- [x] GET /api/public/tracking/{reference} - Case insensitive
- [x] GET /api/public/tracking/{reference} - No dispatch assigned
- [x] GET /api/public/tracking/{reference}/location - Valid
- [x] GET /api/public/tracking/{reference}/location - No dispatch
- [x] GET /api/public/tracking/{reference}/history - Valid
- [x] GET /api/public/tracking/{reference}/history - Empty history
- [x] GET /api/public/tracking/{reference}/proof-of-delivery - Delivered
- [x] GET /api/public/tracking/{reference}/proof-of-delivery - Not delivered

#### ✅ Response Structure Tests
- [x] Response contains success field
- [x] Response contains data object
- [x] Response contains orderReference
- [x] Response contains dispatch details
- [x] Response contains driver information
- [x] Dispatch includes vehicle number

#### ✅ Security Tests
- [x] Endpoints work without authentication
- [x] Public access allowed

**Total: 17 tests**

---

### Frontend Tests (shipment-tracking.component.spec.ts)

#### ✅ Component Initialization
- [x] Component creates successfully
- [x] Initializes with empty search reference
- [x] Subscribes to service observables
- [x] Unsubscribes on destroy
- [x] Clears memoization cache on destroy

#### ✅ Search Functionality
- [x] Calls trackShipment with valid reference
- [x] Does not call with empty reference
- [x] Trims whitespace from input
- [x] Accepts uppercase references
- [x] Accepts lowercase references

#### ✅ Loading States
- [x] Disables input when loading
- [x] Disables button when loading
- [x] Shows loading spinner

#### ✅ Error Handling
- [x] Displays error messages
- [x] Clears errors on retry

#### ✅ Data Display
- [x] Shows shipment summary
- [x] Displays booking reference
- [x] Shows current status
- [x] Displays driver information
- [x] Shows shipment details

#### ✅ Timeline & Map
- [x] Passes timeline data to child component
- [x] Memoizes timeline calculations
- [x] Passes location to map component
- [x] Handles missing location

#### ✅ Location Polling
- [x] Starts polling for IN_TRANSIT
- [x] Stops polling on destroy
- [x] Does not poll for DELIVERED

#### ✅ Status Display
- [x] Returns correct color for each status
- [x] Uses STATUS_COLORS constant

#### ✅ Accessibility
- [x] Has ARIA labels on inputs
- [x] Announces errors to screen readers

**Total: 33 tests**

---

### Integration Tests (test-tracking-api.sh)

#### ✅ Basic Tracking
- [x] Valid tracking reference returns 200
- [x] Invalid reference returns 404
- [x] Case insensitive reference works

#### ✅ Location Endpoint
- [x] Valid reference returns location
- [x] Invalid reference returns 404

#### ✅ History Endpoint
- [x] Valid reference returns history
- [x] Invalid reference returns 404

#### ✅ Proof of Delivery
- [x] Valid reference returns POD status
- [x] Invalid reference returns 404

#### ✅ Response Structure
- [x] Response has success field
- [x] Response has data field
- [x] Data contains orderReference

#### ✅ Performance
- [x] Response time < 2 seconds
- [x] Handles 5 concurrent requests

**Total: 14 tests**

---

## 🎯 Test Scenarios

### Test Data Available

| Order Reference | Status | Dispatch | Driver | POD |
|----------------|--------|----------|--------|-----|
| BK-2026-00125 | IN_TRANSIT | Yes | John Doe | No |
| BK-2026-00126 | PENDING | No | - | No |
| BK-2026-00127 | DELIVERED | Yes | John Doe | Yes |

### Manual Test Cases

#### 1. Happy Path - Active Shipment
```bash
# Search for active shipment
curl http://localhost:8080/api/public/tracking/BK-2026-00125

# Expected:
# - Status: IN_TRANSIT
# - Driver: John Doe
# - Vehicle: PP-1234
# - Location: Available
# - Timeline: 4 status updates
```

#### 2. Pending Order (No Dispatch)
```bash
# Search for pending order
curl http://localhost:8080/api/public/tracking/BK-2026-00126

# Expected:
# - Status: PENDING
# - No dispatch info
# - No driver assigned
```

#### 3. Delivered Order (Complete History)
```bash
# Search for delivered order
curl http://localhost:8080/api/public/tracking/BK-2026-00127

# Expected:
# - Status: DELIVERED
# - Complete timeline (6 steps)
# - Proof of delivery available
```

#### 4. Invalid Reference
```bash
# Search with invalid reference
curl http://localhost:8080/api/public/tracking/INVALID-REF

# Expected:
# - HTTP 404
# - Error message: "Order not found"
```

---

## 🔧 Running Specific Test Suites

### Backend - By Test Class
```bash
# Public tracking tests only
./mvnw test -Dtest=PublicTrackingControllerTest

# All controller tests
./mvnw test -Dtest=*Controller*Test

# With detailed output
./mvnw test -Dtest=PublicTrackingControllerTest -X
```

### Frontend - By Test Suite
```bash
# Component initialization tests only
npm test -- --include='**/shipment-tracking.component.spec.ts' --grep='Component Initialization'

# Search functionality tests
npm test -- --include='**/shipment-tracking.component.spec.ts' --grep='Search Functionality'

# Error handling tests
npm test -- --include='**/shipment-tracking.component.spec.ts' --grep='Error Handling'
```

### Integration - Custom Scenarios
```bash
# Test specific endpoint
curl -i http://localhost:8080/api/public/tracking/BK-2026-00125

# Test with different reference
TEST_REFERENCE=BK-2026-00127 ./test-tracking-api.sh

# Test against different environment
API_BASE_URL=https://staging.example.com ./test-tracking-api.sh
```

---

## 📈 Coverage Reports

### Backend Coverage
```bash
cd tms-backend
./mvnw clean verify

# Open report
open target/site/jacoco/index.html

# Coverage targets:
# - Line coverage: > 80%
# - Branch coverage: > 70%
# - Method coverage: > 90%
```

### Frontend Coverage
```bash
cd tms-frontend
npm run test:ci

# Open report
open coverage/index.html

# Coverage targets:
# - Statements: > 80%
# - Branches: > 75%
# - Functions: > 80%
# - Lines: > 80%
```

---

## 🐛 Debugging Tests

### Backend Test Debugging
```bash
# Run with debug output
./mvnw test -Dtest=PublicTrackingControllerTest -X

# Run in debug mode (attach debugger on port 5005)
./mvnw test -Dtest=PublicTrackingControllerTest -Dmaven.surefire.debug
```

### Frontend Test Debugging
```bash
# Run tests in browser for debugging
npm test -- --browsers=Chrome

# Run with console logs
npm test -- --log-level=debug

# Run single test
npm test -- --include='**/shipment-tracking.component.spec.ts' --grep='should create'
```

---

## ✅ Pre-Deployment Checklist

- [ ] All backend unit tests pass
- [ ] All frontend component tests pass  
- [ ] Integration tests pass with real data
- [ ] Coverage meets minimum thresholds
- [ ] Manual smoke tests completed
- [ ] Performance tests pass (< 2s response)
- [ ] Error scenarios tested
- [ ] Accessibility tests pass
- [ ] Security scan clean (no auth required for public endpoints)

---

## 🔄 Continuous Integration

### GitHub Actions Workflow
```yaml
# .github/workflows/test-tracking.yml
name: Tracking System Tests

on: [push, pull_request]

jobs:
  backend-tests:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      - name: Set up JDK 21
        uses: actions/setup-java@v2
        with:
          java-version: '21'
      - name: Run Backend Tests
        run: cd tms-backend && ./mvnw test
        
  frontend-tests:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      - name: Set up Node
        uses: actions/setup-node@v2
        with:
          node-version: '18'
      - name: Install dependencies
        run: cd tms-frontend && npm ci
      - name: Run Frontend Tests
        run: cd tms-frontend && npm run test:ci
        
  integration-tests:
    runs-on: ubuntu-latest
    services:
      mysql:
        image: mysql:8.0
        env:
          MYSQL_ROOT_PASSWORD: password
          MYSQL_DATABASE: tms_db
        ports:
          - 3306:3306
    steps:
      - uses: actions/checkout@v2
      - name: Load Test Data
        run: mysql -h 127.0.0.1 -u root -ppassword tms_db < test-tracking-data.sql
      - name: Start Backend
        run: cd tms-backend && ./mvnw spring-boot:run &
      - name: Wait for Backend
        run: sleep 30
      - name: Run Integration Tests
        run: ./test-tracking-api.sh
```

---

## 📝 Adding New Tests

### Backend Test Template
```java
@Test
@DisplayName("GET /api/public/tracking/{reference} - Your test case")
void yourTestMethod() throws Exception {
    // Arrange
    when(mockRepository.method()).thenReturn(mockData);
    
    // Act & Assert
    mockMvc.perform(get("/api/public/tracking/REF"))
        .andExpect(status().isOk())
        .andExpect(jsonPath("$.data.field").value("expected"));
}
```

### Frontend Test Template
```typescript
it('should do something', () => {
    // Arrange
    component.searchReference = 'BK-2026-00125';
    
    // Act
    component.onTrack();
    
    // Assert
    expect(mockService.trackShipment).toHaveBeenCalledWith('BK-2026-00125');
});
```

---

## 📚 Resources

- [Spring Boot Testing Guide](https://spring.io/guides/gs/testing-web/)
- [Angular Testing Guide](https://angular.io/guide/testing)
- [Jest Documentation](https://jestjs.io/docs/getting-started)
- [JUnit 5 User Guide](https://junit.org/junit5/docs/current/user-guide/)

---

**Last Updated:** January 9, 2026
