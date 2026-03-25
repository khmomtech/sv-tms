#!/bin/bash

echo "=== Component File Organization Verification ==="
echo ""
echo "Case Components:"
ls -1 src/app/features/incidents/components/case-components/*.{ts,html,css} 2>/dev/null | wc -l | xargs echo "  Files found:"
echo ""
echo "Incident Components:"
ls -1 src/app/features/incidents/components/incident-components/*.{ts,html,css} 2>/dev/null | wc -l | xargs echo "  Files found:"
echo ""
echo "Archive Files:"
ls -1 src/app/features/incidents/components/archive/* 2>/dev/null | wc -l | xargs echo "  Files archived:"
echo ""
echo "=== Structure Summary ==="
find src/app/features/incidents/components -name "*.component.*" -type f | awk -F/ '{print $NF}' | sort | uniq -c
