#!/bin/bash

# E2E Test Runner Script
# Validates environment and runs E2E tests with proper setup

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

echo "🧪 TMS Frontend E2E Test Runner"
echo "================================"
echo ""

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check if node_modules exists
if [ ! -d "node_modules" ]; then
    echo -e "${YELLOW}⚠️  node_modules not found. Running npm install...${NC}"
    npm install
fi

# Check if Playwright browsers are installed
if ! npx playwright --version &> /dev/null; then
    echo -e "${YELLOW}⚠️  Playwright not found. Installing...${NC}"
    npm install --save-dev @playwright/test
fi

# Check for Playwright browsers
PLAYWRIGHT_CACHE="$HOME/.cache/ms-playwright"
if [ ! -d "$PLAYWRIGHT_CACHE" ] || [ -z "$(ls -A $PLAYWRIGHT_CACHE)" ]; then
    echo -e "${YELLOW}⚠️  Playwright browsers not installed. Installing...${NC}"
    npx playwright install --with-deps
fi

# Environment check
echo "🔍 Environment Check"
echo "-------------------"

# Check backend
BACKEND_URL="${API_BASE_URL:-http://localhost:8080}"
echo -n "Backend ($BACKEND_URL): "
if curl -s -f -o /dev/null "$BACKEND_URL/actuator/health" 2>/dev/null || \
   curl -s -f -o /dev/null "$BACKEND_URL/api/actuator/health" 2>/dev/null; then
    echo -e "${GREEN}✓ Running${NC}"
    BACKEND_RUNNING=true
else
    echo -e "${YELLOW}✗ Not running${NC}"
    BACKEND_RUNNING=false
fi

# Check frontend
FRONTEND_URL="${BASE_URL:-http://localhost:4200}"
echo -n "Frontend ($FRONTEND_URL): "
if curl -s -f -o /dev/null "$FRONTEND_URL" 2>/dev/null; then
    echo -e "${GREEN}✓ Running${NC}"
    FRONTEND_RUNNING=true
else
    echo -e "${YELLOW}✗ Not running${NC}"
    FRONTEND_RUNNING=false
fi

echo ""

# Determine test suite to run
TEST_SUITE="${1:-all}"

case "$TEST_SUITE" in
    "integration"|"int")
        echo "📋 Running: Integration Tests"
        if [ "$BACKEND_RUNNING" != true ]; then
            echo -e "${RED}❌ Backend is not running. Integration tests require backend.${NC}"
            echo ""
            echo "Start backend with:"
            echo "  cd ../driver-app && ./mvnw spring-boot:run"
            exit 1
        fi
        npm run test:integration
        ;;

    "api")
        echo "📋 Running: API Contract Tests"
        if [ "$BACKEND_RUNNING" != true ]; then
            echo -e "${RED}❌ Backend is not running. API tests require backend.${NC}"
            exit 1
        fi
        npm run test:integration:api
        ;;

    "ws"|"websocket")
        echo "📋 Running: WebSocket Integration Tests"
        if [ "$BACKEND_RUNNING" != true ]; then
            echo -e "${RED}❌ Backend is not running. WebSocket tests require backend.${NC}"
            exit 1
        fi
        npm run test:integration:ws
        ;;

    "flows"|"e2e")
        echo "📋 Running: E2E User Flow Tests"
        if [ "$FRONTEND_RUNNING" != true ]; then
            echo -e "${RED}❌ Frontend is not running. E2E tests require frontend dev server.${NC}"
            echo ""
            echo "Start frontend with:"
            echo "  npm run start"
            exit 1
        fi
        npm run test:flows
        ;;

    "driver"|"drivers")
        echo "📋 Running: Driver Flow Tests"
        if [ "$FRONTEND_RUNNING" != true ]; then
            echo -e "${RED}❌ Frontend is not running.${NC}"
            exit 1
        fi
        npm run test:flows:driver
        ;;

    "vehicle"|"vehicles")
        echo "📋 Running: Vehicle Flow Tests"
        if [ "$FRONTEND_RUNNING" != true ]; then
            echo -e "${RED}❌ Frontend is not running.${NC}"
            exit 1
        fi
        npm run test:flows:vehicle
        ;;

    "perf"|"performance")
        echo "📋 Running: Performance Tests"
        if [ "$FRONTEND_RUNNING" != true ]; then
            echo -e "${RED}❌ Frontend is not running.${NC}"
            exit 1
        fi
        npm run test:performance
        ;;

    "visual")
        echo "📋 Running: Visual Regression Tests"
        if [ "$FRONTEND_RUNNING" != true ]; then
            echo -e "${RED}❌ Frontend is not running.${NC}"
            exit 1
        fi
        npm run test:visual
        ;;

    "quick")
        echo "📋 Running: Quick Smoke Tests"
        if [ "$BACKEND_RUNNING" != true ]; then
            echo -e "${YELLOW}⚠️  Backend not running. Skipping API tests.${NC}"
        else
            npm run test:integration:api
        fi
        ;;

    "all")
        echo "📋 Running: Full Test Suite"

        WARNINGS=""
        if [ "$BACKEND_RUNNING" != true ]; then
            WARNINGS="${WARNINGS}⚠️  Backend not running - Integration tests will be skipped\n"
        fi
        if [ "$FRONTEND_RUNNING" != true ]; then
            WARNINGS="${WARNINGS}⚠️  Frontend not running - E2E tests will be skipped\n"
        fi

        if [ -n "$WARNINGS" ]; then
            echo -e "${YELLOW}${WARNINGS}${NC}"
            read -p "Continue anyway? (y/n) " -n 1 -r
            echo
            if [[ ! $REPLY =~ ^[Yy]$ ]]; then
                exit 1
            fi
        fi

        npm run test:all
        ;;

    "help"|"-h"|"--help")
        echo "Usage: $0 [suite]"
        echo ""
        echo "Test Suites:"
        echo "  all           - Run all tests (default)"
        echo "  integration   - API + WebSocket integration tests"
        echo "  api           - API contract tests only"
        echo "  ws            - WebSocket tests only"
        echo "  flows         - All E2E user flow tests"
        echo "  driver        - Driver flow tests only"
        echo "  vehicle       - Vehicle flow tests only"
        echo "  performance   - Performance benchmarks"
        echo "  visual        - Visual regression tests"
        echo "  quick         - Quick smoke tests"
        echo ""
        echo "Examples:"
        echo "  $0              # Run all tests"
        echo "  $0 api          # Run API tests only"
        echo "  $0 flows        # Run E2E flow tests"
        echo ""
        exit 0
        ;;

    *)
        echo -e "${RED}❌ Unknown test suite: $TEST_SUITE${NC}"
        echo "Run '$0 help' for usage information"
        exit 1
        ;;
esac

# Show report if tests passed
if [ $? -eq 0 ]; then
    echo ""
    echo -e "${GREEN}Tests completed successfully!${NC}"
    echo ""
    echo "View HTML report:"
    echo "  npx playwright show-report"
else
    echo ""
    echo -e "${RED}❌ Tests failed. Check the output above.${NC}"
    exit 1
fi
