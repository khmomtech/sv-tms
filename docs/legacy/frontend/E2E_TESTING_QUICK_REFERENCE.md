> [!WARNING]
> Legacy document notice: This file is kept for history and may be outdated.
> Use `/Users/sotheakh/Documents/develop/sv-tms/docs/README.md` for active documentation.

# 🚀 E2E Testing Quick Reference

## Current Status

**Date**: November 27, 2025

| Item | Status | Details |
|------|--------|---------|
| **Backend** | Running | Port 8080, Spring Boot |
| **Frontend** | Running | Port 4200, Angular 19 |
| **Database** | Running | MySQL on port 3307 |
| **Redis** | Running | Port 6379 |
| **Tests Executed** | 609 tests | 21.3 minutes |
| **Tests Passed** | ⚠️ 152 (25%) | See fixes below |
| **Tests Failed** | ⚠️ 457 (75%) | Component selectors |

---

## 🎯 What Works

Backend integration successful  
Authentication working (JWT tokens)  
Playwright framework configured  
7 browsers tested (Chrome, Firefox, Safari, Edge, Mobile)  
Page Object Model implemented  
Video/screenshot capture working  
152 tests passing

---

## ⚠️ What Needs Fixing

**Main Issue**: Component selectors don't match Angular components

**Fix Required** (3-4 hours total):

1. **Add `data-testid` attributes** to Angular components (3 hours)
   ```html
   <!-- Example: tms-frontend/src/app/components/dashboard/dashboard.component.html -->
   <div class="metric-card" data-testid="metric-card">
     <!-- content -->
   </div>
   <header data-testid="app-header">
     <!-- content -->
   </header>
   <aside role="navigation" data-testid="app-sidebar">
     <!-- content -->
   </aside>
   ```

2. **Fix post-login routing** (30 mins)
   ```typescript
   // Ensure redirect to /dashboard after login
   // File: tms-frontend/src/app/services/auth.service.ts
   this.router.navigate(['/dashboard']);
   ```

3. **Re-run tests** (30 mins)
   ```bash
   npm run test:e2e
   ```

**Expected Result**: 100% pass rate (609/609 tests)

---

## 🚀 Quick Commands

### Start Services

```bash
# 1. Start database and cache
docker compose -f docker-compose.dev.yml up -d mysql redis

# 2. Start backend (in new terminal)
cd tms-backend
./mvnw spring-boot:run

# 3. Frontend auto-starts with Playwright
```

### Run Tests

```bash
cd tms-frontend

# All tests
npm run test:e2e

# With UI (interactive)
npm run test:e2e:ui

# Debug mode
npm run test:e2e:debug

# Specific browser
npx playwright test --project=chromium

# View report
npx playwright show-report
```

### Check Services

```bash
# Backend health
curl http://localhost:8080/api/actuator/health

# Login test
curl -X POST http://localhost:8080/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"username":"admin","password":"admin123"}'

# Frontend
curl http://localhost:4200
```

---

## 📁 Key Files

### Test Files (8 files)
```
tms-frontend/e2e/
├── ui-ux-integration.spec.ts      # Main UI/UX tests
├── driver-management.spec.ts      # Driver CRUD
├── admin.spec.ts                  # Admin panel
├── app.spec.ts                    # App core
├── page-object-tests.spec.ts      # POM pattern
├── visual-regression.spec.ts      # Visual tests
├── accessibility-performance.spec.ts  # A11y & perf
└── websocket-realtime.spec.ts     # WebSocket
```

### Helper Files
```
tms-frontend/e2e/helpers/
├── auth.helper.ts                 # Authentication (JWT)
├── api.helper.ts                  # API calls
└── test-data.ts                   # Test fixtures
```

### Configuration
```
tms-frontend/
├── playwright.config.ts           # Playwright config
├── e2e/global-setup.ts           # Global setup
└── package.json                   # Test scripts
```

---

## 📊 Test Results Breakdown

```
Total: 609 tests
├── Passed: 152 (25%)
└── ❌ Failed: 457 (75%)
    ├── Component selectors: ~340 (75% of failures)
    ├── Routing issues: ~91 (15% of failures)
    └── Other: ~26 (10% of failures)
```

---

## 🎯 Next Steps

**To achieve 100% pass rate:**

1. ⏳ Add `data-testid` to all components (3 hours)
2. ⏳ Fix post-login routing (30 mins)
3. ⏳ Re-run and verify tests (30 mins)

**Total time**: ~4 hours

---

## 📚 Documentation

- **E2E_TESTING_REPORT.md** - Full test documentation
- **E2E_TESTING_COMPLETION_SUMMARY.md** - Detailed completion summary
- **E2E_TESTING_QUICK_REFERENCE.md** - This file

---

## 💡 Tips

- Use `npm run test:e2e:ui` for interactive debugging
- Check screenshots in `test-results/` for failures
- Videos show full test execution
- HTML report has detailed failure info
- Backend must be running for all tests

---

**Quick Start**: `docker-compose up -d mysql redis && cd tms-backend && ./mvnw spring-boot:run && cd ../tms-frontend && npm run test:e2e`
