#!/bin/bash
# Quick Start Script for TMS Frontend
# This script starts the Angular development server

set -e

echo "🚀 Starting TMS Frontend Development Server..."
echo ""

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Check if we're in the right directory
if [ ! -f "angular.json" ]; then
    echo -e "${RED}❌ Error: Not in tms-frontend directory${NC}"
    echo "Please run this script from /Users/sotheakh/Documents/develop/sv-tms/tms-frontend"
    exit 1
fi

# Check if port 4200 is already in use
if lsof -ti:4200 > /dev/null 2>&1; then
    echo -e "${BLUE}ℹ️  Port 4200 is already in use${NC}"
    read -p "Kill existing process and restart? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo "Killing existing process..."
        lsof -ti:4200 | xargs kill -9 2>/dev/null || true
        sleep 2
    else
        echo "Exiting..."
        exit 0
    fi
fi

# Check Node.js version
echo -e "${BLUE}📦 Checking Node.js version...${NC}"
NODE_VERSION=$(node -v)
echo "Node version: $NODE_VERSION"

# Check if node_modules exists
if [ ! -d "node_modules" ]; then
    echo -e "${BLUE}📦 Installing dependencies...${NC}"
    npm install
fi

echo ""
echo -e "${GREEN}Starting development server...${NC}"
echo ""
echo -e "${BLUE}Server will be available at:${NC}"
echo "  - Local:   http://localhost:4200"
echo "  - Network: http://0.0.0.0:4200"
echo ""
echo -e "${BLUE}Login credentials:${NC}"
echo "  Username: admin"
echo "  Password: admin123"
echo ""
echo -e "${BLUE}Customer List:${NC} http://localhost:4200/customers"
echo ""
echo -e "${RED}Press Ctrl+C to stop the server${NC}"
echo ""

# Start the server
npx ng serve --proxy-config proxy.conf.json --host 0.0.0.0 --port 4200
