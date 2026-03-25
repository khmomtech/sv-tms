# Status Synchronization Review - Flutter vs Backend

## Overview

After refactoring to move status filtering from Flutter to backend (`/me/pending`, `/me/in-progress`, `/me/completed` endpoints), there are still **status mismatches** between client and server that need to be fixed.

## 🔴 Critical Issues Found

### 1. Status Filter Mismatches

#### **Backend Endpoint Statuses (Source of Truth)**

```java
// /api/driver/dispatches/me/pending
DispatchStatus.ASSIGNED

// /api/driver/dispatches/me/in-progress
DispatchStatus.DRIVER_CONFIRMED
DispatchStatus.ARRIVED_LOADING
DispatchStatus.LOADING
DispatchStatus.LOADED
DispatchStatus.IN_TRANSIT
DispatchStatus.ARRIVED_UNLOADING
DispatchStatus.UNLOADING
DispatchStatus.UNLOADED

// /api/driver/dispatches/me/completed
DispatchStatus.DELIVERED
DispatchStatus.CLOSED
DispatchStatus.CANCELLED
```

#### **Flutter Provider Statuses (Inconsistent!)**

```dart
// lib/providers/dispatch_provider.dart

static const Set<String> _pendingStatusSet = {
  'PENDING',   // ❌ Backend only uses ASSIGNED
  'ASSIGNED',  // ✅ Correct
};

static const Set<String> _inProgressStatusSet = {
  'DRIVER_CONFIRMED',     // ✅ Correct
  'APPROVED',             // ❌ NOT in backend in-progress list
  'SCHEDULED',            // ❌ NOT in backend in-progress list
  'ARRIVED_LOADING',      // ✅ Correct
  'LOADING',              // ✅ Correct
  'LOADED',               // ✅ Correct
  'IN_TRANSIT',           // ✅ Correct
  'ARRIVED_UNLOADING',    // ✅ Correct
  'UNLOADING',            // ✅ Correct
  'UNLOADED',             // ✅ Correct
};

static const Set<String> _completedStatusSet = {
  'DELIVERED',  // ✅ Correct
  'COMPLETED',  // ❌ Backend uses CLOSED, not COMPLETED for this endpoint
  'CANCELLED',  // ✅ Correct
  'CLOSED',     // ✅ Correct
};
```

### 2. Redundant Client-Side Filtering

**Problem**: After fetching from backend (which already filters by status), Flutter re-filters the results:

```dart
// lib/providers/dispatch_provider.dart - Lines 625, 659, 684, 731

// fetchPendingDispatches
_pendingDispatches = dispatches.where(_isPendingDispatch).toList();

// fetchInProgressDispatches
_inProgressDispatches = activeDispatches.where(_isInProgressDispatch).toList();

// fetchCompletedDispatches
_completedDispatches = dispatches.where(_isCompletedDispatch).toList();
```

**Impact**: This could filter out **valid dispatches** if the backend sends a status not in Flutter's hardcoded sets (e.g., backend fixed a bug or added new status).

### 3. Status Display Issues

The status filter chips/buttons shown in the screenshot rely on these status constants, which may show states that don't exist in the filtered results or hide valid statuses.

## ✅ Recommended Fixes

### Fix 1: Update Status Constants to Match Backend

```dart
// lib/providers/dispatch_provider.dart

// Update to match backend EXACTLY
static const Set<String> _pendingStatusSet = {
  'ASSIGNED',  // Only ASSIGNED for pending
};

static const Set<String> _inProgressStatusSet = {
  'DRIVER_CONFIRMED',
  'ARRIVED_LOADING',
  'LOADING',
  'LOADED',
  'IN_TRANSIT',
  'ARRIVED_UNLOADING',
  'UNLOADING',
  'UNLOADED',
  // REMOVED: 'APPROVED', 'SCHEDULED' - not in backend in-progress list
};

static const Set<String> _completedStatusSet = {
  'DELIVERED',
  'CLOSED',
  'CANCELLED',
  // REMOVED: 'COMPLETED' - backend uses CLOSED
};
```

### Fix 2: Remove Redundant Client-Side Filtering

Since backend already filters, we should trust the backend response:

```dart
// lib/providers/dispatch_provider.dart

// BEFORE (redundant filtering):
_pendingDispatches = dispatches.where(_isPendingDispatch).toList();

// AFTER (trust backend):
_pendingDispatches = dispatches;  // Backend already filtered by ASSIGNED
```

Apply to all three methods:

- `fetchPendingDispatches` - line ~625
- `fetchInProgressDispatches` - line ~659
- `fetchCompletedDispatches` - lines ~684, ~731

### Fix 3: Add Missing Status Colors

```dart
// lib/screens/shipment/trips_screen.dart - getStatusColor method

// Add these if they appear in backend responses:
case 'CLOSED':
  return Colors.green.shade900;  // Same as COMPLETED
case 'AT_HUB':
  return Colors.purple;
case 'HUB_LOADING':
  return Colors.purple.shade300;
case 'FINANCIAL_LOCKED':
  return Colors.amber.shade700;
```

### Fix 4: Update Translation Keys

Ensure all backend statuses have translations:

```json
// assets/translations/en.json & km.json

"dispatch": {
  "status": {
    "ASSIGNED": "Assigned",
    "DRIVER_CONFIRMED": "Confirmed by Driver",
    "ARRIVED_LOADING": "Arrived at Loading",
    "LOADING": "Loading",
    "LOADED": "Loaded",
    "IN_TRANSIT": "In Transit",
    "ARRIVED_UNLOADING": "Arrived at Unloading",
    "UNLOADING": "Unloading",
    "UNLOADED": "Unloaded",
    "DELIVERED": "Delivered",
    "CLOSED": "Closed",
    "CANCELLED": "Cancelled",
    "AT_HUB": "At Hub",
    "HUB_LOADING": "Hub Loading",
    "FINANCIAL_LOCKED": "Financially Locked"
  }
}
```

## 🔧 Implementation Priority

### High Priority (Must Fix):

1. ✅ Remove `'APPROVED'`, `'SCHEDULED'` from `_inProgressStatusSet`
2. ✅ Remove `'COMPLETED'` from `_completedStatusSet` (backend uses `'CLOSED'`)
3. ✅ Remove or simplify redundant `.where()` filtering after backend calls

### Medium Priority (Should Fix):

4. ⚠️ Add `'PENDING'` endpoint if backend supports it, or remove from `_pendingStatusSet`
5. ⚠️ Add color for `'CLOSED'` status
6. ⚠️ Ensure Khmer translations exist for all statuses

### Low Priority (Nice to Have):

7. 📝 Add status colors for hub/financial statuses if they appear
8. 📝 Document status lifecycle in code comments

## 📋 Testing Checklist

After fixes:

- [ ] Pending dispatches show only `ASSIGNED` status
- [ ] In-progress dispatches show 8 valid statuses (DRIVER_CONFIRMED through UNLOADED)
- [ ] Completed dispatches show DELIVERED, CLOSED, CANCELLED
- [ ] No dispatches disappear after backend returns them
- [ ] All status chips/buttons have correct colors
- [ ] All statuses display translated text (EN and KM)
- [ ] Status filter buttons work correctly
- [ ] No console errors about missing translations

## 🎯 Expected Behavior After Fixes

| Endpoint          | Statuses Returned            | Flutter Processing          |
| ----------------- | ---------------------------- | --------------------------- |
| `/me/pending`     | ASSIGNED only                | Display as-is, no filtering |
| `/me/in-progress` | 8 in-progress statuses       | Display as-is, no filtering |
| `/me/completed`   | DELIVERED, CLOSED, CANCELLED | Display as-is, no filtering |

## 🔍 Files to Update

1. `/Users/sotheakh/Documents/develop/sv-tms/tms_driver_app/lib/providers/dispatch_provider.dart`
   - Lines 57-78: Update status constant sets
   - Lines 625, 659, 684, 731: Remove redundant filtering

2. `/Users/sotheakh/Documents/develop/sv-tms/tms_driver_app/lib/screens/shipment/trips_screen.dart`
   - Lines 647-691: Add CLOSED color case

3. `/Users/sotheakh/Documents/develop/sv-tms/tms_driver_app/assets/translations/en.json`
4. `/Users/sotheakh/Documents/develop/sv-tms/tms_driver_app/assets/translations/km.json`
   - Add missing status translation keys

## 📊 Status Lifecycle Reference

```
ASSIGNED
  ↓
DRIVER_CONFIRMED
  ↓
ARRIVED_LOADING → LOADING → LOADED
  ↓
IN_TRANSIT
  ↓
ARRIVED_UNLOADING → UNLOADING → UNLOADED
  ↓
DELIVERED
  ↓
CLOSED

(CANCELLED can happen at any point)
```

## ⚠️ Breaking Changes

None - these are bug fixes to align client with server truth.

## 🚀 Rollout Plan

1. Apply fixes to `dispatch_provider.dart`
2. Test with real backend data
3. Verify no dispatches are filtered out incorrectly
4. Deploy to UAT for driver testing
5. Monitor for missing translations
6. Deploy to production

---

**Created**: 2026-03-03  
**Last Updated**: 2026-03-03  
**Status**: Ready for Implementation
