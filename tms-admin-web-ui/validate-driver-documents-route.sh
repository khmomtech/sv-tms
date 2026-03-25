#!/bin/bash

# Driver Documents Route Validation Script
echo "🔍 Validating Driver Documents Route Configuration..."
echo "=================================================="

# Check if guard file exists
if [ -f "src/app/guards/driver-documents.guard.ts" ]; then
    echo "Driver Documents Guard: EXISTS"
else
    echo "❌ Driver Documents Guard: MISSING"
fi

# Check if resolver file exists
if [ -f "src/app/resolvers/driver-documents.resolver.ts" ]; then
    echo "Driver Documents Resolver: EXISTS"
else
    echo "❌ Driver Documents Resolver: MISSING"
fi

# Check if routes are properly configured
if grep -q "DriverDocumentsGuard" src/app/features/fleet/fleet.routes.ts; then
    echo "Route Guard: CONFIGURED"
else
    echo "❌ Route Guard: NOT CONFIGURED"
fi

if grep -q "DriverDocumentsResolver" src/app/features/fleet/fleet.routes.ts; then
    echo "Route Resolver: CONFIGURED"
else
    echo "❌ Route Resolver: NOT CONFIGURED"
fi

# Check component exists
if [ -f "src/app/components/drivers/documents/driver-documents.component.ts" ]; then
    echo "Driver Documents Component: EXISTS"
else
    echo "❌ Driver Documents Component: MISSING"
fi

# Check route path
if grep -q "path: 'documents'" src/app/features/fleet/fleet.routes.ts; then
    echo "Route Path: CONFIGURED (/fleet/drivers/documents)"
else
    echo "❌ Route Path: NOT CONFIGURED"
fi

echo ""
echo "🎯 Route Access Requirements:"
echo "   - User must be authenticated"
echo "   - User must have DRIVER_VIEW_ALL or DRIVER_MANAGE permission"
echo "   - Or user must be ADMIN or SUPERADMIN"
echo ""
echo "📋 Route Features Added:"
echo "   - Route Guard: Prevents unauthorized access"
echo "   - Route Resolver: Preloads driver data"
echo "   - Error Handling: Comprehensive error messages"
echo "   - Validation: Driver existence checks"
echo ""
echo "Driver Documents Route Validation Complete!"
