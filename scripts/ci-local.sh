#!/bin/bash
################################################################################
# CI Local Test Script
# Run all CI checks locally before pushing to GitHub
################################################################################

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Project root
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$PROJECT_ROOT"

echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}🔍 Running CI Checks Locally${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# Track failures
FAILED_CHECKS=()

################################################################################
# Backend CI
################################################################################
if [ -d "driver-app" ]; then
    echo -e "${YELLOW}📦 Backend CI (Java Spring Boot)${NC}"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    
    cd driver-app
    
    # Clean and compile
    echo "→ Cleaning and compiling..."
    if ./mvnw clean compile -B -q; then
        echo -e "${GREEN}✓${NC} Compilation successful"
    else
        echo -e "${RED}✗${NC} Compilation failed"
        FAILED_CHECKS+=("Backend compilation")
    fi
    
    # Run tests
    echo "→ Running tests..."
    if ./mvnw test -B; then
        echo -e "${GREEN}✓${NC} Tests passed"
    else
        echo -e "${RED}✗${NC} Tests failed"
        FAILED_CHECKS+=("Backend tests")
    fi
    
    # Package
    echo "→ Packaging JAR..."
    if ./mvnw package -DskipTests -B -q; then
        echo -e "${GREEN}✓${NC} Package created"
    else
        echo -e "${RED}✗${NC} Package failed"
        FAILED_CHECKS+=("Backend package")
    fi
    
    cd "$PROJECT_ROOT"
    echo ""
else
    echo -e "${YELLOW}⚠ Skipping Backend CI (driver-app not found)${NC}"
    echo ""
fi

################################################################################
# Angular CI
################################################################################
if [ -d "tms-frontend" ]; then
    echo -e "${YELLOW}🅰️  Angular CI (Frontend)${NC}"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    
    cd tms-frontend
    
    # Install dependencies
    echo "→ Installing dependencies..."
    if npm ci --quiet > /dev/null 2>&1; then
        echo -e "${GREEN}✓${NC} Dependencies installed"
    else
        echo -e "${RED}✗${NC} Dependency installation failed"
        FAILED_CHECKS+=("Angular dependencies")
    fi
    
    # Build
    echo "→ Building production bundle..."
    if npm run build --if-present > /dev/null 2>&1; then
        echo -e "${GREEN}✓${NC} Build successful"
    else
        echo -e "${RED}✗${NC} Build failed"
        FAILED_CHECKS+=("Angular build")
    fi
    
    # Lint (if configured)
    if grep -q "\"lint\"" package.json; then
        echo "→ Running linter..."
        if npm run lint > /dev/null 2>&1; then
            echo -e "${GREEN}✓${NC} Lint passed"
        else
            echo -e "${YELLOW}⚠${NC} Lint warnings (not blocking)"
        fi
    fi
    
    cd "$PROJECT_ROOT"
    echo ""
else
    echo -e "${YELLOW}⚠ Skipping Angular CI (tms-frontend not found)${NC}"
    echo ""
fi

################################################################################
# Flutter CI
################################################################################
if [ -d "driver_app" ]; then
    echo -e "${YELLOW}📱 Flutter CI (Driver App)${NC}"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    
    cd driver_app
    
    # Check if Flutter is installed
    if command -v flutter &> /dev/null; then
        # Get dependencies
        echo "→ Getting dependencies..."
        if flutter pub get > /dev/null 2>&1; then
            echo -e "${GREEN}✓${NC} Dependencies fetched"
        else
            echo -e "${RED}✗${NC} Pub get failed"
            FAILED_CHECKS+=("Flutter dependencies")
        fi
        
        # Analyze
        echo "→ Analyzing code..."
        if flutter analyze --no-pub > /dev/null 2>&1; then
            echo -e "${GREEN}✓${NC} Analysis passed"
        else
            echo -e "${YELLOW}⚠${NC} Analysis warnings (check manually)"
        fi
        
        # Run tests
        echo "→ Running tests..."
        if flutter test > /dev/null 2>&1; then
            echo -e "${GREEN}✓${NC} Tests passed"
        else
            echo -e "${YELLOW}⚠${NC} Tests failed (not blocking in CI)"
        fi
    else
        echo -e "${YELLOW}⚠ Flutter not installed (skipping Flutter checks)${NC}"
    fi
    
    cd "$PROJECT_ROOT"
    echo ""
else
    echo -e "${YELLOW}⚠ Skipping Flutter CI (driver_app not found)${NC}"
    echo ""
fi

################################################################################
# Docker Build Test (Optional)
################################################################################
if command -v docker &> /dev/null; then
    echo -e "${YELLOW}🐳 Docker Build Test${NC}"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    
    # Backend Docker build
    if [ -f "driver-app/Dockerfile" ]; then
        echo "→ Building backend Docker image..."
        if docker build -t driver-app:ci-test driver-app > /dev/null 2>&1; then
            echo -e "${GREEN}✓${NC} Backend Docker build successful"
            # Clean up
            docker rmi driver-app:ci-test > /dev/null 2>&1 || true
        else
            echo -e "${RED}✗${NC} Backend Docker build failed"
            FAILED_CHECKS+=("Backend Docker build")
        fi
    fi
    
    echo ""
else
    echo -e "${YELLOW}⚠ Docker not installed (skipping Docker checks)${NC}"
    echo ""
fi

################################################################################
# Code Quality Checks
################################################################################
echo -e "${YELLOW}📊 Code Quality Checks${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Check for secrets (basic check)
echo "→ Checking for potential secrets..."
if git ls-files | xargs grep -i -E "(password|secret|api_key|apikey|token|private_key)" | grep -v -E "(test|example|sample|HANDBOOK|README)" > /dev/null 2>&1; then
    echo -e "${RED}✗${NC} Potential secrets found in code!"
    echo "  Please review and use environment variables instead."
    FAILED_CHECKS+=("Potential secrets in code")
else
    echo -e "${GREEN}✓${NC} No obvious secrets found"
fi

# Check for large files
echo "→ Checking for large files..."
LARGE_FILES=$(git ls-files | xargs du -h 2>/dev/null | awk '$1 ~ /M$/ {print $0}' | head -5)
if [ -n "$LARGE_FILES" ]; then
    echo -e "${YELLOW}⚠${NC} Large files found (consider Git LFS):"
    echo "$LARGE_FILES"
else
    echo -e "${GREEN}✓${NC} No large files"
fi

echo ""

################################################################################
# Summary
################################################################################
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}📋 Summary${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

if [ ${#FAILED_CHECKS[@]} -eq 0 ]; then
    echo -e "${GREEN}All checks passed!${NC}"
    echo ""
    echo "You can safely push your changes:"
    echo "  git push origin $(git branch --show-current)"
    echo ""
    exit 0
else
    echo -e "${RED}❌ Some checks failed:${NC}"
    for check in "${FAILED_CHECKS[@]}"; do
        echo -e "  ${RED}✗${NC} $check"
    done
    echo ""
    echo "Please fix the issues before pushing."
    echo ""
    exit 1
fi
