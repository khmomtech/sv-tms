#!/bin/bash
# Quick GPS Service Test Script
# Run this after driver logs in to verify background GPS is working

set -e

echo "🧪 Testing Background GPS Service..."
echo ""

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Test 1: Service Running
echo "Test 1: Checking if LocationService is running..."
if adb shell dumpsys activity services | grep -q "LocationService"; then
    echo -e "${GREEN}✅ PASS${NC} - LocationService is running"
else
    echo -e "${RED}❌ FAIL${NC} - LocationService NOT running"
    echo "   Try: Login again or manually start service"
    exit 1
fi
echo ""

# Test 2: Foreground Service Notification
echo "Test 2: Checking foreground service notification..."
if adb shell dumpsys notification | grep -q "sv_driver_notifications"; then
    echo -e "${GREEN}✅ PASS${NC} - Notification channel active"
else
    echo -e "${YELLOW}⚠️  WARN${NC} - No notification found (may be dismissed by user)"
fi
echo ""

# Test 3: Location Permission
echo "Test 3: Checking location permissions..."
LOCATION_PERM=$(adb shell dumpsys package com.svtrucking.svdriverapp | grep "android.permission.ACCESS_FINE_LOCATION" | grep "granted=true" || echo "")
if [ -n "$LOCATION_PERM" ]; then
    echo -e "${GREEN}✅ PASS${NC} - Fine location permission granted"
else
    echo -e "${RED}❌ FAIL${NC} - Fine location permission NOT granted"
fi

BG_LOCATION_PERM=$(adb shell dumpsys package com.svtrucking.svdriverapp | grep "android.permission.ACCESS_BACKGROUND_LOCATION" | grep "granted=true" || echo "")
if [ -n "$BG_LOCATION_PERM" ]; then
    echo -e "${GREEN}✅ PASS${NC} - Background location permission granted"
else
    echo -e "${RED}❌ FAIL${NC} - Background location permission NOT granted"
    echo "   Settings → Apps → Location → Allow all the time"
fi
echo ""

# Test 4: Battery Optimization
echo "Test 4: Checking battery optimization..."
if adb shell dumpsys deviceidle whitelist | grep -q "svtrucking"; then
    echo -e "${GREEN}✅ PASS${NC} - App is whitelisted from battery optimization"
else
    echo -e "${YELLOW}⚠️  WARN${NC} - App NOT whitelisted (may be killed on some devices)"
    echo "   Settings → Apps → Battery → Unrestricted"
fi
echo ""

# Test 5: Live Location Updates
echo "Test 5: Monitoring live location updates (15 seconds)..."
echo "   Watching for GPS coordinates in logs..."
timeout 15s adb logcat -s LocationService:I | grep "📍" || true
echo ""

# Test 6: REST API Calls
echo "Test 6: Checking REST API location posts..."
if adb logcat -d -s LocationService:* | grep -q "postLocationRest"; then
    echo -e "${GREEN}✅ PASS${NC} - REST API fallback is active"
    LAST_RESPONSE=$(adb logcat -d -s LocationService:* | grep "REST response" | tail -1)
    echo "   Last response: $LAST_RESPONSE"
else
    echo -e "${YELLOW}⚠️  WARN${NC} - No REST API calls detected yet"
fi
echo ""

# Summary
echo "======================================"
echo "📊 Quick Test Summary"
echo "======================================"
echo ""
echo "Next steps:"
echo "1. Close the app (Home button)"
echo "2. Wait 30 seconds"
echo "3. Run: adb logcat -s LocationService:I"
echo "4. Verify GPS updates every 15 seconds"
echo ""
echo "To test app kill survival:"
echo "  adb shell am force-stop com.svtrucking.svdriverapp"
echo "  adb shell dumpsys activity services | grep LocationService"
echo ""
echo "Expected: Service should STILL be running after force-stop"
echo ""
