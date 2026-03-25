> [!WARNING]
> Legacy document notice: This file is kept for history and may be outdated.
> Use `/Users/sotheakh/Documents/develop/sv-tms/docs/README.md` for active documentation.

# Phase 6 Driver App - UI Screens Implementation Complete

## Summary

Driver app UI screens for finance document submission have been fully implemented. All three submission forms (Odometer, Fuel, COD) are now complete with rich UI, validation, form controls, and integration with the provider layer.

---

## Files Created

### 1. **submit_odometer_screen.dart**

**Location:** `tms_tms_driver_app/lib/screens/dispatch/submit_odometer_screen.dart`

**Features:**

- Start and end odometer reading input fields (with decimal support)
- Auto-calculated distance display (end_km - start_km)
- Dispatch detail card showing ID, status, submission time
- Form validation:
  - Both fields required
  - Values must be non-negative
  - End reading ≥ start reading
- Real-time distance calculation with info card
- Submit button with loading state
- Success/error toast notifications
- Pop return value `true` on success for parent refresh

**Component Methods:**

- `_submitOdometer()` - Calls `DispatchProvider.submitOdometer(dispatchId, startKm, endKm, recordedAt)`
- `_pickImage()` - (Future enhancement for odometer photos)
- Input validation with cross-field validation

**UI Pattern:**

```
┌─────────────────────────────────┐
│  AppBar: "Submit Odometer"      │
├─────────────────────────────────┤
│  ┌─ Dispatch Info Card ────┐   │
│  │ ID: dispatch-123        │   │
│  │ Status: LOADED          │   │
│  │ Submitted: Feb 06, 2026 │   │
│  └─────────────────────────┘   │
│                                 │
│  [Start Odometer: _______] KM   │
│  [End Odometer: _______] KM     │
│                                 │
│  ┌─ Distance: 50.00 KM ────┐  │
│  │ (info box calculated)    │  │
│  └──────────────────────────┘  │
│                                 │
│  ┌──── Submit Odometer ────┐   │
│  └──────────────────────────┘   │
└─────────────────────────────────┘
```

---

### 2. **submit_fuel_request_screen.dart**

**Location:** `tms_tms_driver_app/lib/screens/dispatch/submit_fuel_request_screen.dart`

**Features:**

- Amount field (USD) with currency support
- Liters field with decimal input
- Fuel station name field
- Receipt image capture (camera) with grid display (3-column layout)
- Image removal capability (trash icon per image)
- Auto-calculated price per liter display
- Dispatch detail card
- Form validation:
  - All fields required
  - Amount > 0
  - Liters > 0
  - Station name ≥ 2 characters
- Image preview gallery with remove buttons
- Submit button with loading state
- Success/error notifications
- Returns `true` on success

**Component Methods:**

- `_submitFuelRequest()` - Calls `DispatchProvider.submitFuelRequest(...)`
- `_pickImage()` - Opens camera via ImagePicker, saves to \_receiptImages list
- `_removeImage(index)` - Removes image from list, updates UI
- Price per liter calculation displayed live

**External Dependencies:**

- `image_picker` package for camera/gallery selection
- Support for PNG/JPG receipt images at up to 80% quality (1200x1200 max)

**UI Pattern:**

```
┌─────────────────────────────────┐
│  AppBar: "Submit Fuel Request"  │
├─────────────────────────────────┤
│  ┌─ Dispatch Info Card ────┐   │
│  │ ID: dispatch-456        │   │
│  │ Status: LOADED          │   │
│  └─────────────────────────┘   │
│                                 │
│  [Amount: 50.00 ___] USD        │
│  [Liters: 20.5 ___] L           │
│  [Station: ____________]        │
│                                 │
│  ┌─ Price/L: $2.44 ────────┐  │
│  │ (auto-calculated)        │  │
│  └──────────────────────────┘  │
│                                 │
│  Receipt Images                 │
│  ┌─ [IMG1][IMG2][IMG3] ──┐    │
│  │ (3-col grid, removable) │    │
│  └──────────────────────────┘  │
│                                 │
│  ┌──── Add Receipt Photo ──┐   │
│  ├──────────────────────────┤   │
│  │ Submit Request           │   │
│  └──────────────────────────┘   │
└─────────────────────────────────┘
```

---

### 3. **submit_cod_settlement_screen.dart**

**Location:** `tms_tms_driver_app/lib/screens/dispatch/submit_cod_settlement_screen.dart`

**Features:**

- Currency dropdown selector (USD, KHR, THB, VND)
- Amount collected field with currency suffix
- Expected vs. actual amount comparison (if expectedAmount provided)
- Mismatch warning card (orange) when collected ≠ expected
- Dispatch detail card
- Informational card with settlement notes
- Form validation:
  - Amount required
  - Amount ≥ 0
  - Currency selection required
- Live discrepancy detection and display
- Submit button with loading state
- Success/error notifications
- Returns `true` on success

**Component Methods:**

- `_submitSettlement()` - Calls `DispatchProvider.submitCodSettlement(...)`
- Automatic expected amount pre-fill if provided
- Real-time mismatch detection on amount change

**Optional Prop:**

- `expectedAmount` - Pre-fills form and enables discrepancy detection

**UI Pattern:**

```
┌─────────────────────────────────┐
│  AppBar: "COD Settlement"       │
├─────────────────────────────────┤
│  ┌─ Dispatch Info Card ────┐   │
│  │ ID: dispatch-789        │   │
│  │ Status: DELIVERED       │   │
│  │ Delivered: Feb 06, 2026 │   │
│  └─────────────────────────┘   │
│                                 │
│  ┌─ Expected: USD 50.00 ────┐ │
│  │ (info box, if provided)   │ │
│  └──────────────────────────┘  │
│                                 │
│  [Currency: USD ▼]              │
│  [Amount: 50.00 ___] USD        │
│                                 │
│  ┌─ Amount Mismatch ─────────┐ │
│  │ ⚠️ Expected: 50.00        │ │
│  │ Actual: 49.50             │ │
│  └──────────────────────────┘  │
│                                 │
│  Settlement Notes:              │
│  • Verify amount before submit  │
│  • Include discounts            │
│  • Report discrepancies         │
│                                 │
│  ┌──── Submit Settlement ──┐   │
│  └──────────────────────────┘   │
└─────────────────────────────────┘
```

---

### 4. **dispatch_finance_actions_sheet.dart**

**Location:** `tms_tms_driver_app/lib/screens/dispatch/dispatch_finance_actions_sheet.dart`

**Purpose:** Bottom sheet providing quick access to all three finance document submission screens.

**Features:**

- Bottom sheet modal with smooth entry/exit
- 3-button grid layout (Odometer, Fuel, COD)
- Icons for each action type
- Description text under each button
- Auto-dismissal after successful submission (callback)
- Close button
- Header with dispatch ID reference

**Component Methods:**

- `_showScreen(context, screen)` - Navigates to screen, handles result callback
- Listens for return value `true` and triggers `onSubmitted()` callback

**Usage in Dispatch Detail Screen:**

```dart
// Show actions sheet from dispatch detail
showModalBottomSheet(
  context: context,
  builder: (_) => DispatchFinanceActionsSheet(
    dispatch: currentDispatch,
    onSubmitted: () => _refreshDispatchStatus(), // Refresh after submit
  ),
);
```

**UI Pattern:**

```
┌─────────────────────────────┐
│ ─────────────────────────── │  (drag handle)
│ Dispatch Finance            │
│ Submit docs for dispatch-1  │
│                             │
│ ┌───────┬───────┬────────┐ │
│ │ Speed │  Fuel │Payment │ │
│ │ KM    │Request│COD     │ │
│ │Readng │       │Settle  │ │
│ └───────┴───────┴────────┘ │
│                             │
│ ┌──────── Close ─────────┐ │
│ └─────────────────────────┘ │
└─────────────────────────────┘
```

---

## Integration Points

### 1. **Dispatch Detail Screen Enhancement**

Add action button to dispatch detail to show finance actions:

```dart
// In dispatch_detail_screen.dart
FloatingActionButton(
  onPressed: () => showModalBottomSheet(
    context: context,
    builder: (_) => DispatchFinanceActionsSheet(
      dispatch: dispatch,
      onSubmitted: _refreshStatus,
    ),
  ),
  tooltip: 'Finance Documents',
  child: const Icon(Icons.attach_money),
),
```

### 2. **Dispatch List Context Menu**

Add long-press or swipe action to show finance options from dispatch list.

### 3. **Driver App Navigation Routes**

Add routes to `main.dart` or `app.dart` (if needed for direct navigation):

```dart
// Example: routes map
'/dispatch/:id/odometer': (context, params) =>
  SubmitOdometerScreen(dispatch: params['dispatch']),
'/dispatch/:id/fuel': (context, params) =>
  SubmitFuelRequestScreen(dispatch: params['dispatch']),
'/dispatch/:id/cod': (context, params) =>
  SubmitCodSettlementScreen(dispatch: params['dispatch']),
```

---

## Component Hierarchy

```
dispatch_list_screen
  ├─ Dispatch Card [long-press]
  │  └─ dispatch_finance_actions_sheet
  │      ├─ submit_odometer_screen (push)
  │      ├─ submit_fuel_request_screen (push)
  │      └─ submit_cod_settlement_screen (push)
  └─ dispatch_detail_screen
     ├─ FAB (Finance button)
     └─ dispatch_finance_actions_sheet (bottom sheet)
         ├─ submit_odometer_screen (push)
         ├─ submit_fuel_request_screen (push)
         └─ submit_cod_settlement_screen (push)
```

---

## Shared State Management

All screens use `DispatchProvider` (already implemented):

- `submitOdometer(dispatchId, startKm, endKm, recordedAt)`
- `submitFuelRequest(dispatchId, amount, liters, station, receiptPaths)`
- `submitCodSettlement(dispatchId, amount, currency, collectedAt)`

**No additional provider methods needed.** Screens call provider methods directly via:

```dart
await context.read<DispatchProvider>().submitOdometer(...)
```

---

## Validation Features

### Odometer Screen

✅ Both fields required  
✅ Non-negative values only  
✅ End ≥ Start  
✅ Decimal support (km.mm format)  
✅ Distance auto-calculation

### Fuel Request Screen

✅ Amount > 0  
✅ Liters > 0  
✅ Station name ≥ 2 chars  
✅ Price per liter calculation  
✅ Image count display  
✅ Image removal capability

### COD Settlement Screen

✅ Amount ≥ 0  
✅ Currency selection required  
✅ Expected vs. actual comparison  
✅ Mismatch warning with details  
✅ Pre-fill from expectedAmount prop

---

## Error Handling

All screens implement:

1. **Try-catch** for API errors
2. **Toast notifications** for success/failure
3. **Loading state** on submit button (disabled + progress indicator)
4. **Pop with return value** on success (`true` for parent refresh)
5. **Form validation** before submission (prevent invalid data)

---

## Next Steps (Optional Enhancements)

1. **Add photo capture for odometer** (optional proof)
2. **Add signature capture** (optional on COD)
3. **Add offline support** (queue submissions if no connectivity)
4. **Add receipt preview/zoom** in fuel screen
5. **Add GPS location tagging** on submissions
6. **Add receipt OCR** (extract amount from image)
7. **Add barcode scanning** (for fuel receipt number)

---

## Testing Checklist

- [ ] Validate form submission with valid data
- [ ] Validate form rejection with invalid data (negative, missing fields)
- [ ] Test image upload/removal flow
- [ ] Test discrepancy warning display on COD
- [ ] Test loading state and button disable during submit
- [ ] Test success toast and screen pop
- [ ] Test error toast on API failure
- [ ] Test offline retry logic (via DispatchRepository.executeWithRetry)
- [ ] Test back button cancels form (confirm discard dialog?)
- [ ] Verify return value bubbles up to parent for refresh

---

## Phase 6 Status: ✅ COMPLETE

**Backend API:** ✅ Complete (Phase 4)  
**Repository Layer:** ✅ Complete (Phase 4)  
**Provider Wrappers:** ✅ Complete (Phase 4)  
**UI Screens:** ✅ Complete (Phase 6 - THIS)  
**Integration Points:** ⏳ Pending (add to dispatch detail/list)

**Ready for next phase:** Phase 7 - Finance Logic (KM incentives, approval workflows, email notifications)
