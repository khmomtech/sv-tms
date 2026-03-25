# Manual Testing Guide - GPS Tracking Alert System

**Quick Start Testing - March 2, 2026**

Dev server running at: http://localhost:4200 ✅

## Pre-Testing Checklist

- [x] Dev server running on port 4200
- [x] Build passing with 0 TypeScript errors
- [x] Event handlers wired (snoozed, dismissed)
- [ ] Browser DevTools console open (F12)

---

## Test Scenario 1: Speeding Alert (Yellow Toast)

**Duration: 2 minutes**

### Steps:

1. Navigate to http://localhost:4200/live/drivers
2. Open Chrome/Safari DevTools (F12 or Cmd+Option+I)
3. Click **Console** tab
4. Paste and run:

```javascript
const comp = ng.getComponent(document.querySelector('app-driver-gps-tracking'));
console.log('Component loaded:', comp ? '✅' : '❌');
```

5. Trigger speeding alert:

```javascript
comp.driverAlertService.checkAndEmitAlerts(1, { speed: 95 });
```

### Expected Result:

- **Yellow toast** appears **top-right corner**
- Message: "Driver speeding: 95 km/h"
- Two buttons visible: "Snooze (5m)" and "✕"
- Toast has slide-in animation from right

### Test Actions:

```javascript
// Click "Snooze" button → toast should disappear for 5 minutes
// OR manually snooze via console:
comp.driverAlertService.snoozeAlert('alert_1_speeding');

// Click "✕" (dismiss) button → toast should remove immediately
// OR manually dismiss:
comp.driverAlertService.dismissAlert('alert_1_speeding');
```

---

## Test Scenario 2: Battery Low Alert (Red Toast)

**Duration: 1 minute**

### Steps:

```javascript
comp.driverAlertService.checkAndEmitAlerts(2, { batteryLevel: 10 });
```

### Expected Result:

- **Red toast** appears (critical severity)
- Message: "Low battery: 10%"
- Positioned below any existing toasts

---

## Test Scenario 3: Cooldown Enforcement (30 seconds)

**Duration: 1 minute**

### Steps:

```javascript
// First alert
comp.driverAlertService.checkAndEmitAlerts(1, { speed: 100 });
console.log('First speeding alert triggered');

// Immediate duplicate (should be blocked)
comp.driverAlertService.checkAndEmitAlerts(1, { speed: 105 });
console.log('Duplicate blocked by cooldown');

// Check active alerts count
console.log('Active alerts:', comp.driverAlertService.activeAlerts$.value.size);
// Expected: 1 (duplicate blocked)
```

### Expected Result:

- Only **ONE** toast appears
- Second call does NOT create new toast (cooldown active)
- Console shows only 1 active alert

---

## Test Scenario 4: Multiple Drivers Simultaneously

**Duration: 2 minutes**

### Steps:

```javascript
// Trigger alerts for 3 different drivers
comp.driverAlertService.checkAndEmitAlerts(1, { speed: 95 });
comp.driverAlertService.checkAndEmitAlerts(2, { batteryLevel: 8 });
comp.driverAlertService.checkAndEmitAlerts(3, { speed: 110 });

// Check total active
console.log('Active alerts:', comp.driverAlertService.activeAlerts$.value.size);
// Expected: 3
```

### Expected Result:

- **3 toasts stacked vertically** in top-right
- Each toast has different message (driver 1, 2, 3)
- Colors: Yellow (speeding), Red (battery), Yellow (speeding)

---

## Test Scenario 5: Alert History Limit (100 max)

**Duration: 1 minute**

### Steps:

```javascript
// Check current history
console.log('Alert history:', comp.driverAlertService.alerts$.value.length);

// Generate 10 alerts rapidly (different drivers to bypass cooldown)
for (let i = 10; i < 20; i++) {
  comp.driverAlertService.checkAndEmitAlerts(i, { speed: 90 + i });
}

console.log('After batch:', comp.driverAlertService.alerts$.value.length);
// Should be <= 100 (FIFO eviction)
```

---

## Test Scenario 6: Real WebSocket Integration

**Duration: 3 minutes**

### Prerequisites:

- Backend running on localhost:8080
- Real driver sending GPS updates with speed data

### Steps:

1. Ensure driver telemetry includes `speed` field
2. Watch for automatic alerts when driver exceeds 80 km/h
3. Check console for WebSocket messages:

```javascript
// Enable WebSocket logging
comp.driverLocationService.connect(); // Should already be connected
```

### Expected Behavior:

- Toast appears **automatically** when real driver speeds
- No manual `checkAndEmitAlerts()` call needed
- Integration point: `applyLiveUpdate()` method calls alert service

---

## Debug Commands

### Check Service State:

```javascript
const comp = ng.getComponent(document.querySelector('app-driver-gps-tracking'));

// Active alerts
console.table(Array.from(comp.driverAlertService.activeAlerts$.value.entries()));

// Alert history
console.log('History:', comp.driverAlertService.alerts$.value);

// Alert rules
console.log('Rules:', comp.driverAlertService.alertRules$.value);
```

### Check DOM Rendering:

```javascript
// Count visible toasts
document.querySelectorAll('app-driver-alert-toast').length;

// Inspect toast styles
document.querySelector('app-driver-alert-toast')?.classList;
```

### Force Clear All Alerts:

```javascript
comp.driverAlertService.activeAlerts$.value.forEach((alert, id) => {
  comp.driverAlertService.dismissAlert(id);
});
```

---

## Success Criteria

- ✅ Yellow toast for speeding (>80 km/h)
- ✅ Red toast for battery (<15%)
- ✅ Cooldown prevents duplicates (30s)
- ✅ Snooze button works (5 min default)
- ✅ Dismiss button removes toast immediately
- ✅ Multiple toasts stack vertically
- ✅ Slide-in animation smooth (300ms)
- ✅ No console errors during testing

---

## Troubleshooting

### Toast Not Appearing:

```javascript
// Check if component reference valid
console.log('Component:', ng.getComponent(document.querySelector('app-driver-gps-tracking')));

// Check if service initialized
console.log('Service:', comp.driverAlertService);

// Check activeAlerts observable
comp.driverAlertService.activeAlerts$.subscribe((alerts) => {
  console.log('Active alerts changed:', alerts.size);
});
```

### Styling Issues:

- Verify Tailwind CSS loaded: `getComputedStyle(document.body).fontFamily`
- Check toast positioning: Should be `position: fixed; top: 1rem; right: 1rem; z-index: 50`

### Event Handlers Not Working:

- Verify template bindings: `(snoozed)` and `(dismissed)` present in HTML
- Check if methods exist: `comp.driverAlertService.snoozeAlert` and `dismissAlert`

---

## Next Steps After Manual Testing

1. **If all tests pass**:
   - Deploy to staging environment
   - Run load test with 400+ drivers
   - Monitor for 24 hours

2. **If issues found**:
   - Document in GitHub issue
   - Check browser console for errors
   - Review `.github/PHASE3-COMPLETE.md` for implementation details

3. **Production deployment**:
   - Use deployment guide in `DELIVERY-SUMMARY.md`
   - Enable feature flag for gradual rollout
   - Monitor WebSocket uptime and alert frequency

---

**Estimated Total Testing Time: 12-15 minutes**

Last updated: March 2, 2026
