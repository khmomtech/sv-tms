# Quick Test Execution Guide

## Prerequisites Check

All services must be running:
```bash
docker compose -f docker-compose.dev.yml ps
# Should show: svtms-mysql, svtms-redis, svtms-backend all UP
```

Backend health check:
```bash
curl http://localhost:8080/actuator/health
# Should return: {"status":"UP"}
```

## 🚀 Run Integration Tests

### Standard Run (All Browsers)
```bash
cd /Users/sotheakh/Documents/develop/sv-tms/tms-frontend
SKIP_FRONTEND_CHECK=true npm run test:integration:api
```

### View HTML Report
```bash
npx playwright show-report
```

### Run Single Browser
```bash
# Chromium only (fastest)
SKIP_FRONTEND_CHECK=true npx playwright test e2e/integration/api-contracts.spec.ts --project=chromium

# Firefox
SKIP_FRONTEND_CHECK=true npx playwright test e2e/integration/api-contracts.spec.ts --project=firefox

# WebKit (Safari)
SKIP_FRONTEND_CHECK=true npx playwright test e2e/integration/api-contracts.spec.ts --project=webkit
```

### Debug Mode
```bash
SKIP_FRONTEND_CHECK=true npx playwright test e2e/integration/api-contracts.spec.ts --debug
```

### Watch Mode
```bash
SKIP_FRONTEND_CHECK=true npx playwright test e2e/integration/api-contracts.spec.ts --ui
```

## 📊 Current Status

**40 passing tests** (57%)  
❌ **30 failing tests** (43%) - POST/PUT/DELETE operations  
🎯 **All GET operations working**

## 🔧 Troubleshooting

### Backend Not Running
```bash
docker compose -f docker-compose.dev.yml up -d backend
docker compose -f docker-compose.dev.yml logs backend --tail=50
```

### Auth Failures
Check admin credentials:
```bash
curl -X POST 'http://localhost:8080/api/auth/login' \
  -H 'Content-Type: application/json' \
  -d '{"username":"admin","password":"admin123"}' | jq '.'
```

### Clear Test Results
```bash
rm -rf playwright-report test-results
```

### Reinstall Dependencies
```bash
npm ci
npx playwright install
```

## 📚 Documentation

- Full status: `/INTEGRATION_TESTS_FINAL_STATUS.md`
- Infrastructure: `/TEST_INFRASTRUCTURE_README.md`
- Setup guide: `/FINAL_COMPLETION_SUMMARY.md`
