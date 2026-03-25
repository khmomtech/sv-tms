#!/bin/bash
# Regression Test Runner Script
# 
# Usage:
#   ./run-regression-tests.sh              (uses default http://localhost:8080)
#   ./run-regression-tests.sh http://prod.example.com:8080
#   API_BASE_URL=http://staging:8080 ./run-regression-tests.sh
#
# Prerequisites:
#   - Node.js 18+
#   - npm install (to install Jest and dependencies)
#   - Backend running and healthy

set -e

# Configuration
API_BASE_URL="${1:-${API_BASE_URL:-http://localhost:8080}}"
TIMESTAMP=$(date +%Y-%m-%d_%H-%M-%S)
REPORT_DIR="test-results/${TIMESTAMP}"
REPORT_FILE="${REPORT_DIR}/regression-results.json"

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${YELLOW}========================================${NC}"
echo -e "${YELLOW}DISPATCH LIFECYCLE REGRESSION TEST SUITE${NC}"
echo -e "${YELLOW}========================================${NC}"
echo ""
echo "API_BASE_URL: $API_BASE_URL"
echo "Report:       $REPORT_FILE"
echo ""

# Check if backend is reachable
echo "🔍 Checking backend health..."
if ! curl -s "$API_BASE_URL/actuator/health" > /dev/null 2>&1; then
  echo -e "${RED}❌ Backend not reachable at $API_BASE_URL${NC}"
  echo "   Please ensure:"
  echo "   1. Backend is running: ./mvnw spring-boot:run"
  echo "   2. API_BASE_URL is correct"
  echo "   3. Port 8080 is not blocked"
  exit 1
fi
echo -e "${GREEN}✅ Backend is healthy${NC}"
echo ""

# Create report directory
mkdir -p "$REPORT_DIR"

# Install dependencies if needed
if [ ! -d "node_modules" ]; then
  echo "📦 Installing dependencies..."
  npm install --save-dev jest @types/jest ts-jest axios typescript @types/node --legacy-peer-deps
fi

# Run tests
echo "▶️  Starting test suite..."
echo ""

API_BASE_URL="$API_BASE_URL" \
npm test -- \
  --testPathPattern="DISPATCH_LIFECYCLE_REGRESSION" \
  --json \
  --outputFile="$REPORT_FILE" \
  --coverage \
  --detectOpenHandles \
  || TEST_FAILED=1

# Print report
echo ""
echo -e "${YELLOW}========================================${NC}"
echo -e "${YELLOW}TEST REPORT${NC}"
echo -e "${YELLOW}========================================${NC}"

if [ -z "$TEST_FAILED" ]; then
  echo -e "${GREEN}✅ All tests passed!${NC}"
  echo ""
  echo "Report saved to: $REPORT_FILE"
  exit 0
else
  echo -e "${RED}❌ Some tests failed${NC}"
  echo ""
  echo "Report saved to: $REPORT_FILE"
  echo ""
  echo "For details, run:"
  echo "  cat $REPORT_FILE | jq '.testResults'"
  exit 1
fi
