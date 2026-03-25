#!/bin/bash
# Verify DispatchStateMachine covers all DispatchStatus enum values

echo "🔍 Verifying DispatchStateMachine coverage..."
echo ""

# Extract all enum values from DispatchStatus.java
ENUM_FILE="tms-backend/src/main/java/com/svtrucking/logistics/enums/DispatchStatus.java"
STATE_MACHINE="tms-backend/src/main/java/com/svtrucking/logistics/workflow/DispatchStateMachine.java"

echo "📋 All DispatchStatus enum values:"
grep -E "^  [A-Z_]+," "$ENUM_FILE" | sed 's/,//g' | awk '{print "  " $1}' | sort

echo ""
echo "🗺️  Statuses in TRANSITIONS map:"
grep -E "Map\.entry\(DispatchStatus\." "$STATE_MACHINE" | \
  sed -E 's/.*DispatchStatus\.([A-Z_]+).*/\1/' | \
  sort | uniq

echo ""
echo "📊 Coverage Summary:"
ENUM_COUNT=$(grep -E "^  [A-Z_]+," "$ENUM_FILE" | wc -l | tr -d ' ')
MAP_COUNT=$(grep -E "Map\.entry\(DispatchStatus\." "$STATE_MACHINE" | wc -l | tr -d ' ')

echo "  Enum values: $ENUM_COUNT"
echo "  Map entries: $MAP_COUNT"

if [ "$ENUM_COUNT" -eq "$MAP_COUNT" ]; then
    echo "  ✅ All statuses covered!"
else
    echo "  ❌ Coverage incomplete!"
    echo ""
    echo "Missing statuses:"
    comm -23 \
      <(grep -E "^  [A-Z_]+," "$ENUM_FILE" | sed 's/,//g' | awk '{print $1}' | sort) \
      <(grep -E "Map\.entry\(DispatchStatus\." "$STATE_MACHINE" | sed -E 's/.*DispatchStatus\.([A-Z_]+).*/\1/' | sort | uniq)
fi

echo ""
echo "🎯 Testing API endpoint..."
# Test if backend is running
if curl -s http://localhost:8080/actuator/health > /dev/null 2>&1; then
    echo "  ✅ Backend is running (port 8080)"
else
    echo "  ❌ Backend is not running"
    exit 1
fi

echo ""
echo "✅ Verification complete!"
