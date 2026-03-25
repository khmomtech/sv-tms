> [!WARNING]
> Legacy document notice: This file is kept for history and may be outdated.
> Use `/Users/sotheakh/Documents/develop/sv-tms/docs/README.md` for active documentation.

# Dispatch Module Integration Guide

## Quick Start for Developers

This guide walks through integrating the newly completed Phase 6 driver app screens into your dispatch workflow.

---

## 1. Frontend (Angular) — Admin UI Integration

### Add Sidebar Menu Items

**File:** `tms-frontend/src/app/layout/sidebar.component.ts`

```typescript
// Add to your menu items array
{
  id: 'dispatch-approvals',
  title: 'Approvals',
  description: 'Odometer, Fuel, COD approvals',
  icon: 'check_circle',
  route: '/dispatch/approvals',
  permissions: ['DISPATCH_UPDATE'],
  parent: 'dispatch'
},
{
  id: 'dispatch-closing',
  title: 'Daily Closing',
  description: 'Close/reopen dispatch day',
  icon: 'lock',
  route: '/dispatch/closing',
  permissions: ['DISPATCH_UPDATE'],
  parent: 'dispatch'
}
```

### Add Approval Badge to Dispatch Board

**File:** `tms-frontend/src/app/features/dispatch/dispatch-board.component.ts`

```typescript
// Add a service method to get pending approvals count
export class DispatchService {
  getPendingApprovalsCount(): Observable<number> {
    return this.http
      .get<{ count: number }>("/api/admin/dispatches/approvals/count")
      .pipe(map((res) => res.count || 0));
  }
}

// In dispatch-board component
export class DispatchBoardComponent {
  pendingApprovals = signal(0);

  constructor(private dispatchService: DispatchService) {
    this.dispatchService
      .getPendingApprovalsCount()
      .subscribe((count) => this.pendingApprovals.set(count));
  }

  // Add badge to navbar
  // <span class="badge badge-warning">{{ pendingApprovals() }}</span>
}
```

### Add "Go to Approvals" Link in Dispatch Detail

**File:** `tms-frontend/src/app/features/dispatch/dispatch-detail.component.html`

```html
<!-- Add action button in dispatch detail -->
<div class="action-buttons">
  <button mat-stroked-button (click)="goToApprovals()">
    <mat-icon>check_circle</mat-icon>
    View Approvals
  </button>
</div>
```

**Component TypeScript:**

```typescript
goToApprovals() {
  this.router.navigate(['/dispatch/approvals'], {
    queryParams: { dispatchId: this.dispatch.id }
  });
}
```

### Update Approvals Component Route Default

**File:** `tms-frontend/src/app/features/dispatch/dispatch.routes.ts`

```typescript
// If route has query param, auto-load it
{
  path: 'approvals',
  loadComponent: () => import('./approvals/dispatch-approvals.component')
    .then(m => m.DispatchApprovalsComponent),
  data: { permissions: ['DISPATCH_UPDATE'] }
},
{
  path: 'closing',
  loadComponent: () => import('./closing/dispatch-closing.component')
    .then(m => m.DispatchClosingComponent),
  data: { permissions: ['DISPATCH_UPDATE'] }
}
```

---

## 2. Driver App (Flutter) — Screen Integration

### Add Finance Actions to Dispatch Detail

**File:** `tms_tms_driver_app/lib/screens/dispatch/dispatch_detail_screen.dart`

```dart
@override
Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(title: const Text('Dispatch Detail')),
    body: ..., // existing body

    // Add finance FAB
    floatingActionButton: FloatingActionButton(
      onPressed: _showFinanceActions,
      tooltip: 'Finance Documents',
      child: const Icon(Icons.attach_money),
    ),
  );
}

void _showFinanceActions() {
  showModalBottomSheet<void>(
    context: context,
    builder: (_) => DispatchFinanceActionsSheet(
      dispatch: dispatch,
      onSubmitted: _refreshDispatchStatus,
    ),
  );
}

void _refreshDispatchStatus() async {
  // Refresh dispatch to show updated approval statuses
  final updated = await dispatchProvider.getDispatchDetail(dispatch.id);
  setState(() => dispatch = updated);

  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text('Data refreshed')),
  );
}
```

### Alternative: Add Menu Item to Dispatch List

**File:** `tms_tms_driver_app/lib/screens/dispatch/dispatch_list_screen.dart`

```dart
// Long-press action on dispatch card
GestureDetector(
  onLongPress: () {
    showModalBottomSheet(
      context: context,
      builder: (_) => DispatchFinanceActionsSheet(
        dispatch: dispatch,
        onSubmitted: _loadDispatches,
      ),
    );
  },
  child: DispatchCard(dispatch: dispatch),
)
```

### Update Dispatch Provider (if not done)

**File:** `tms_driver_app/lib/providers/dispatch_provider.dart`

Ensure these methods exist:

```dart
Future<void> submitOdometer(
  String dispatchId,
  double startKm,
  double endKm,
  DateTime recordedAt,
) async {
  final repository = context.read<DispatchRepository>();
  await repository.submitOdometer(dispatchId, startKm, endKm, recordedAt);
  notifyListeners();
}

Future<void> submitFuelRequest(
  String dispatchId,
  double amount,
  double liters,
  String station,
  List<String>? receiptPaths,
) async {
  final repository = context.read<DispatchRepository>();
  await repository.submitFuelRequest(
    dispatchId, amount, liters, station, receiptPaths
  );
  notifyListeners();
}

Future<void> submitCodSettlement(
  String dispatchId,
  double amount,
  String currency,
  DateTime collectedAt,
) async {
  final repository = context.read<DispatchRepository>();
  await repository.submitCodSettlement(
    dispatchId, amount, currency, collectedAt
  );
  notifyListeners();
}
```

---

## 3. Backend — Enhancements (Optional)

### Add Pending Count Endpoint

**File:** `tms-backend/.../controller/DispatchApprovalsController.java`

```java
@GetMapping("/count")
@PreAuthorize("hasAnyAuthority('ROLE_ADMIN','ROLE_SUPERADMIN','ROLE_FINANCE')")
public ResponseEntity<Map<String, Integer>> getPendingApprovalsCount() {
  int odometerCount = odometerLogService.countPending();
  int fuelCount = fuelRequestService.countPending();
  int codCount = codSettlementService.countPending();

  int total = odometerCount + fuelCount + codCount;

  return ResponseEntity.ok(Map.of("count", total));
}
```

**In OdometerLogService:**

```java
public int countPending() {
  return odometerLogRepository
    .countByApprovalStatus(ApprovalStatus.PENDING);
}
```

### Add Real-time WebSocket Updates (Optional)

For real-time approval status updates to driver app:

```java
// In DispatchApprovalsController
@PostMapping("/odometer/{id}/approve")
public ResponseEntity<OdometerLogDto> approveOdometer(@PathVariable String id) {
  OdometerLog log = odometerLogService.approve(id, getCurrentUser());

  // Send WebSocket message
  messagingTemplate.convertAndSend(
    "/topic/dispatch/" + log.getDispatch().getId() + "/approvals",
    Map.of("type", "ODOMETER_APPROVED", "id", id)
  );

  return ResponseEntity.ok(OdometerLogDto.fromEntity(log));
}
```

---

## 4. Testing Checklist

### Backend Testing

- [ ] Start backend: `cd tms-backend && ./mvnw spring-boot:run`
- [ ] Driver submits odometer: `POST /api/driver/dispatches/1/odometer`
- [ ] Admin approves it: `PATCH /api/admin/dispatches/approvals/odometer/1/approve`
- [ ] Verify audit log: `SELECT * FROM dispatch_audit_logs WHERE dispatch_id = 1`

### Frontend Testing

- [ ] Run Angular: `cd tms-frontend && npm start`
- [ ] Navigate to `/dispatch/approvals`
- [ ] Load approvals for a dispatch ID
- [ ] Click "Approve" button → verify success toast
- [ ] Check backend that status changed to APPROVED

### Driver App Testing

- [ ] Run driver app: `cd tms_driver_app && flutter run --flavor dev`
- [ ] Open dispatch detail
- [ ] Tap finance FAB → bottom sheet opens
- [ ] Tap odometer → form opens
- [ ] Enter start/end km → distance calculates
- [ ] Tap submit → success toast
- [ ] Go to admin UI → verify it appears in approvals list

### End-to-End Testing

1. Driver submits odometer
2. Admin approves via `/dispatch/approvals`
3. Driver refreshes → sees APPROVED status
4. Driver submits fuel request with photo
5. Finance approves fuel
6. Driver submits COD settlement
7. Admin closes dispatch day → locks all records
8. Verify audit log has entries for each action

---

## 5. Common Integration Issues & Solutions

### Issue: "Cannot find module" import errors in Driver App

**Solution:** Run `flutter pub get` to fetch dependencies

```bash
cd tms_driver_app && flutter pub get
```

### Issue: Frontend routes not working (404)

**Solution:** Check that dispatch.routes.ts includes the new routes and they're imported in the parent routes

```typescript
// In app.routes.ts
export const routes: Routes = [
  {
    path: "dispatch",
    loadChildren: () =>
      import("./features/dispatch/dispatch.routes").then(
        (m) => m.DISPATCH_ROUTES,
      ),
  },
];
```

### Issue: Backend returns 401 Unauthorized

**Solution:** Ensure token is being sent in Authorization header

- Angular: Check `AuthInterceptor` is adding `Authorization: Bearer <token>`
- Driver app: Check `GeneratedApiService.setAuthToken(token)` was called after login

### Issue: Images not uploading in Fuel Request

**Solution:** Verify `image_picker` is installed and permissions are set

```bash
# Driver app - check pubspec.yaml has image_picker
flutter pub add image_picker

# iOS - ensure NSCameraUsageDescription in Info.plist
# Android - ensure CAMERA permission in AndroidManifest.xml
```

### Issue: Dispatch ID query param not loading

**Solution:** Update DispatchApprovalsComponent to read from route params

```typescript
constructor(private route: ActivatedRoute) {
  this.route.queryParams.subscribe(params => {
    this.dispatchId = params['dispatchId'] || '';
  });
}
```

---

## 6. Deployment Checklist

Before deploying to production:

- [ ] **Backend:**
  - [ ] Run migrations: `./mvnw flyway:migrate`
  - [ ] Test all 3 endpoints (odometer, fuel, cod) with valid/invalid data
  - [ ] Verify RBAC: non-FINANCE user cannot approve
  - [ ] Check audit logs created for all actions

- [ ] **Frontend:**
  - [ ] Test approvals list with 10+ items (pagination)
  - [ ] Test date picker in closing component
  - [ ] Test reopen button disabled for non-ADMIN users
  - [ ] Run linting: `npm run lint`
  - [ ] Build for production: `npm run build`

- [ ] **Driver App:**
  - [ ] Test on Android emulator: `flutter run --flavor prod`
  - [ ] Test on iOS simulator: `flutter run --flavor prod`
  - [ ] Test offline submission (disable network, submit, re-enable)
  - [ ] Verify receipt image compression (max 1MB per image)
  - [ ] Build APK: `flutter build apk --release --flavor prod`

- [ ] **Integration:**
  - [ ] E2E: Submit odometer → approve → verify driver sees it
  - [ ] E2E: Close day → verify locked, then reopen → verify unlocked
  - [ ] E2E: Fuel with photo → capture, upload, approve

---

## 7. Monitoring & Alerting (Post-Deployment)

### Metrics to Monitor

- Dispatch submission success rate
- Approval processing time (avg, p95)
- Odometer reading discrepancies (e.g., end < start)
- Daily closing failures (should be 0)
- Offline submission retry rate

### Logs to Watch

- `dispatch_audit_logs` - should have entry per state change
- Backend error logs - watch for validation failures
- Frontend console - watch for API 401/403 errors

### Alerts to Set Up

- [ ] Approval stuck in PENDING > 24 hours
- [ ] Fuel request with photo > 5 failed upload attempts
- [ ] Daily close endpoint 500 errors
- [ ] Driver app offline queue size > 100 items

---

## 8. Next Phase (Phase 7 — Finance Logic)

When ready to continue, the following Phase 7 work can start:

1. **KM Incentive Calculation**
   - Add `rate_per_km` config parameter
   - Calculate incentive = (end_km - start_km) \* rate_per_km
   - Store in `odometer_logs.incentive_amount`

2. **Fuel Approval Workflow**
   - Add email notification on fuel request
   - Implement receipt validation (OCR or manual check)
   - Generate fuel reconciliation report

3. **COD Settlement Workflow**
   - Match collected amount vs. order COD
   - Flag discrepancies > 5% for audit
   - Auto-approve if within 5%

4. **Daily Closing Report**
   - Summary card: total KM, total fuel approved, total COD collected
   - Export as PDF
   - Email to finance team

---

## 9. Dispatch Finance Edge Case Architecture (Phase 8–10)

### Overview

This section documents the edge-case finance workflows added in Phase 8–10, including partial delivery, reassignment, breakdown, unavailability, holiday/overtime, and customer refunds.

### Core Components

- **EdgeCaseController**: REST API facade for all edge-case calculations and actions.
- **HolidayRateService**: Holiday + overtime multiplier logic (stacking multipliers).
- **CustomerRefundService**: Refund policies, service credits, COD adjustments, approvals.
- **DispatchFinanceRepository**: Edge-case analytics, reporting, and audit queries.
- **FinanceNotificationService**: Customer/finance notifications for approvals and refunds.

### High-Level Flow

1. **API request** arrives at `EdgeCaseController` (admin scope).
2. **Compensation/refund logic** executes in service layer.
3. **Audit + analytics** are persisted and reported via `DispatchFinanceRepository`.
4. **Notifications** are sent for approvals, refunds, and escalations.
5. **Manual review** is triggered for low completion or high-value refunds.

### Authorization Scopes

- `EDGE_CASE_CALCULATE`
- `EDGE_CASE_VIEW`
- `INCIDENT_REPORT_CREATE`
- `REFUND_PROCESS`

### Rules & Thresholds (Key)

- **Partial delivery**: < 50% completion → manual review.
- **Reassignment**: > 60 min delay → penalty applies.
- **Holiday/overtime**: multipliers stack (max 3.0x).
- **Refunds**: > $50 requires manual approval.

### API Endpoint Groups

- Partial delivery (single + multi-leg)
- Vehicle reassignment
- Emergency breakdown (calculate + incident report)
- Driver unavailability (calculate + incident report)
- Complex scenarios (combined events)
- Dispatch impact analysis
- Holiday/overtime compensation
- Refund calculation + processing + COD adjustment

### Operational Notes

- Preserve client boundaries: Admin-only access to `/api/admin/*`.
- Keep refund approvals auditable; record reason codes and resolution.
- Review dashboard should surface manual-review cases daily.

---

## Quick Reference

| Component            | Location                                                                      | Status  |
| -------------------- | ----------------------------------------------------------------------------- | ------- |
| Backend Entities     | `tms-backend/src/main/java/.../model/`                                        | ✅ Done |
| Backend APIs         | `tms-backend/src/main/java/.../controller/`                                   | ✅ Done |
| Frontend Components  | `tms-frontend/src/app/features/dispatch/{approvals,closing}/`                 | ✅ Done |
| Frontend Routes      | `tms-frontend/src/app/features/dispatch/dispatch.routes.ts`                   | ✅ Done |
| Driver Screens       | `tms_tms_driver_app/lib/screens/dispatch/submit_*.dart`                       | ✅ Done |
| Driver Actions Sheet | `tms_tms_driver_app/lib/screens/dispatch/dispatch_finance_actions_sheet.dart` | ✅ Done |
| Database Migrations  | `tms-backend/src/main/resources/db/migration/V20260206_*.sql`                 | ✅ Done |

---

**Integration Status:** Ready for development team onboarding  
**Last Updated:** February 6, 2026  
**Phase Complete:** 10/10
