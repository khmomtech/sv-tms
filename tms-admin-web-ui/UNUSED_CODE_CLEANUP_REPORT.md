# TMS Frontend - Unused Code Cleanup Report

**Generated**: Nov 27, 2025  
**Analysis Status**: Complete  
**Ready for Cleanup**: Yes

---

## 📊 Executive Summary

| Category | Found | Action Required |
|----------|-------|-----------------|
| **Commented Out Files** | 2 files | DELETE |
| **Duplicate Services** | 3 duplicates | CONSOLIDATE |
| **Unused Services** | 1 service | DELETE |
| **Unused Data Files** | 2 files | DELETE |
| **Unused Modal Imports** | 3 imports | REMOVE |
| **Unused Components** | 1 component | DELETE |
| **ESLint Warnings** | ~100+ warnings | FIX |

**Total Cleanup**: ~12 files to delete/modify  
**Estimated Impact**: -500+ lines of dead code  
**Risk Level**: 🟢 LOW (no active usage found)

---

## 🔴 CRITICAL: Files to Delete

### 1. Commented Out Component
```
📁 src/app/components/customer/import/customer-import.component.ts
```
**Status**: Entire file commented out (108 lines)  
**Reason**: Complete component implementation commented out  
**Action**: DELETE entire file  
**Risk**: 🟢 None - already commented

---

### 2. Commented Out Service
```
📁 src/app/services/TransportOrderService.ts
```
**Status**: Entire file commented out (50+ lines)  
**Reason**: Duplicate of transport-order.service.ts  
**Action**: DELETE entire file  
**Risk**: 🟢 None - already commented, real service exists

---

## 🟡 DUPLICATE SERVICES (Consolidate)

### 1. Admin Notification Services (2 duplicates)

**Empty Service (DELETE):**
```typescript
📁 src/app/services/admin-notifications.service.ts
- Only contains empty class (9 lines)
- No implementation
- Exported in services/index.ts
```

**Active Service (KEEP):**
```typescript
📁 src/app/services/admin-notification.service.ts
- Full implementation (228 lines)
- Used in NotificationComponent
- Has WebSocket integration
```

**Action**:
1. Delete `admin-notifications.service.ts`
2. Remove export from `services/index.ts`
3. Verify no imports exist

---

### 2. KHB Upload Services (2 versions)

**Duplicate Services:**
```typescript
📁 src/app/services/khb-upload.service.ts
- Class name: KhbSoUploadService
- Used by: khb-upload.component.ts

📁 src/app/services/khb-so-upload.service.ts
- Class name: KhbSoUploadService
- Used by: trip-plan-report.component.ts
```

**Issue**: Same class name in two files!

**Action**:
1. Audit which service has correct implementation
2. Consolidate to single service
3. Update component imports
4. Delete duplicate

---

### 3. SoUploadService (Potentially Unused)

```typescript
📁 src/app/services/so-upload.service.ts
- Minimal implementation (10 lines)
- No active usage found in codebase
```

**Action**:
1. Search for any hidden usages
2. Delete if truly unused
3. Remove from services/index.ts

---

## 🗑️ UNUSED DATA FILES

### 1. Truck Vehicles Master Data
```
📁 src/app/data/truck-vehicles-master.ts
```
**Status**: Exported but never imported  
**Search Results**: 0 usages found  
**Action**: DELETE if not needed for future features  
**Risk**: 🟢 Low - static data, easily recreated

---

### 2. Distributor Master Data
```
📁 src/app/data/distributor-master.ts
```
**Status**: Exported but never imported  
**Search Results**: 0 usages found  
**Action**: DELETE if not needed  
**Risk**: 🟢 Low - static data

---

### 3. SKU Master Data (KEEP - Used)
```
📁 src/app/data/sku-master.ts
```
**Status**: KEEP - Likely used in templates  
**Reason**: More complex, may be used in data binding

---

## 🧩 UNUSED MODAL IMPORTS

### File: `dispatch-monitor.component.ts`

**Unused Imports (Lines 23-25):**
```typescript
// ❌ REMOVE - These imports are NOT in the component's imports array
import { AssignDriverModalComponent } from './assign-driver-modal/assign-driver-modal.component';
import { AssignTruckModalComponent } from './assign-truck-modal/assign-truck-modal.component';
import { ChangeDriverModalComponent } from './change-driver-modal/change-driver-modal.component';
```

**Evidence**:
- Components NOT listed in `@Component.imports`
- Only `ImagePreviewModalComponent` is imported
- These modals ARE used in `dispatch-list.component.ts`

**Action**: Remove 3 unused imports from dispatch-monitor

---

## 📦 UNUSED COMPONENT (Not in Routes)

### Trip Plan Report Component
```
📁 src/app/components/trip-plan-report/
```

**Files**:
- trip-plan-report.component.ts
- trip-plan-report.component.html (commented out)
- trip-plan-report.component.css
- trip-plan-report.component.spec.ts

**Status**: 
- ❌ NOT in app.routes.ts
- ❌ NOT in any feature routes
- ❌ HTML is entirely commented out
- Service imported: `KhbSoUploadService`

**Options**:
1. **Delete** if feature is deprecated
2. **Add to routes** if feature is needed
3. **Keep** if work-in-progress

**Action**: User decision needed (likely DELETE)

---

## ⚠️ ESLINT WARNINGS (~100+ instances)

### Issue: Inconsistent Type Imports

**Pattern**:
```typescript
// ❌ Current (warning)
import { OnInit } from '@angular/core';

// Should be
import type { OnInit } from '@angular/core';
```

**Files Affected**: ~40+ component files

**Auto-Fix Available**: YES
```bash
npm run lint -- --fix
```

**Action**: Run auto-fix after file deletions

---

## 🎯 CLEANUP ACTION PLAN

### Phase 1: Safe Deletions (5 minutes)

```bash
# 1. Delete commented out files
rm src/app/components/customer/import/customer-import.component.ts
rm src/app/services/TransportOrderService.ts

# 2. Delete empty service
rm src/app/services/admin-notifications.service.ts

# 3. Delete unused data files (if confirmed)
rm src/app/data/truck-vehicles-master.ts
rm src/app/data/distributor-master.ts
```

### Phase 2: Service Consolidation (10 minutes)

**KHB Service Audit**:
```bash
# Check current usage
grep -r "khb-upload.service" src/app/
grep -r "khb-so-upload.service" src/app/

# Decision:
# - Keep ONE service (determine which has correct API)
# - Update all component imports
# - Delete duplicate
```

**SoUploadService Audit**:
```bash
# Deep search for usage
grep -r "SoUploadService" src/app/
grep -r "so-upload.service" src/app/

# If no results: DELETE
rm src/app/services/so-upload.service.ts
```

### Phase 3: Update Index Exports (2 minutes)

**File**: `src/app/services/index.ts`

Remove exports:
```typescript
// ❌ REMOVE
export * from './admin-notifications.service';
export * from './so-upload.service'; // if deleted
// Keep only one KHB service export
```

### Phase 4: Clean Unused Imports (2 minutes)

**File**: `src/app/components/dispatch-monitor.component.ts`

Remove lines 23-25:
```typescript
// ❌ DELETE
import { AssignDriverModalComponent } from './assign-driver-modal/assign-driver-modal.component';
import { AssignTruckModalComponent } from './assign-truck-modal/assign-truck-modal.component';
import { ChangeDriverModalComponent } from './change-driver-modal/change-driver-modal.component';
```

### Phase 5: Auto-Fix ESLint (3 minutes)

```bash
cd /Users/sotheakh/Documents/develop/sv-tms/tms-frontend
npm run lint -- --fix
```

### Phase 6: Verification (5 minutes)

```bash
# Build check
npm run build

# Test check
npm test

# Git status
git status
git diff
```

---

## 📝 DETAILED FILE CHANGES

### Files to DELETE (7 files):

1. `src/app/components/customer/import/customer-import.component.ts`
2. `src/app/services/TransportOrderService.ts`
3. `src/app/services/admin-notifications.service.ts`
4. ⚠️ `src/app/services/so-upload.service.ts` (verify first)
5. ⚠️ `src/app/data/truck-vehicles-master.ts` (if not needed)
6. ⚠️ `src/app/data/distributor-master.ts` (if not needed)
7. ⚠️ `src/app/components/trip-plan-report/**` (if feature deprecated)

### Files to MODIFY (2 files):

1. **src/app/services/index.ts**
   - Remove: `admin-notifications.service` export
   - Remove: `so-upload.service` export (if deleted)
   - Keep only one KHB service export

2. **src/app/components/dispatch-monitor.component.ts**
   - Remove: 3 unused modal component imports (lines 23-25)

### Files to CONSOLIDATE (2 services):

1. **KHB Upload Service** (choose one):
   - `src/app/services/khb-upload.service.ts`
   - `src/app/services/khb-so-upload.service.ts`

---

## VERIFICATION CHECKLIST

Before cleanup:
- [ ] Backup workspace: `git add -A && git commit -m "backup before cleanup"`
- [ ] Read this report completely
- [ ] Confirm trip-plan-report component status

After cleanup:
- [ ] Build passes: `npm run build`
- [ ] Lint clean: `npm run lint`
- [ ] Tests pass: `npm test`
- [ ] App runs: `npm start`
- [ ] Manual smoke test of key features
- [ ] Git diff review
- [ ] Create cleanup commit

---

## 🎯 EXPECTED RESULTS

**Lines Removed**: ~500+ lines  
**Files Deleted**: 5-7 files  
**Services Consolidated**: 2 pairs  
**Imports Cleaned**: 3+ unused imports  
**ESLint Warnings**: -100+ warnings

**Benefits**:
- Smaller bundle size
- Cleaner codebase
- Faster builds
- Less confusion for developers
- Easier maintenance

---

## 🚨 RISKS & MITIGATION

### Risk 1: Hidden Usages
**Mitigation**: 
- Use comprehensive grep searches
- Check HTML templates
- Review route configs

### Risk 2: Future Features
**Mitigation**:
- Git history preserves deleted code
- Documentation of removed features
- Can restore if needed

### Risk 3: Breaking Changes
**Mitigation**:
- Run full build after each deletion
- Test suite verification
- Manual smoke testing

---

## 🎬 ONE-COMMAND CLEANUP (Use with caution!)

```bash
#!/bin/bash
# Auto-cleanup script - Review before running!

cd /Users/sotheakh/Documents/develop/sv-tms/tms-frontend

# Backup
git add -A
git commit -m "backup: before unused code cleanup"

# Delete commented files
rm src/app/components/customer/import/customer-import.component.ts
rm src/app/services/TransportOrderService.ts
rm src/app/services/admin-notifications.service.ts

# Verify build still works
npm run build || { echo "Build failed!"; exit 1; }

# Auto-fix ESLint
npm run lint -- --fix

# Final build
npm run build

echo "Cleanup complete! Review changes with: git diff"
```

---

## 📞 NEXT STEPS

1. **Review this report** thoroughly
2. **Decide on trip-plan-report** component (keep/delete?)
3. **Audit KHB services** to determine which to keep
4. **Run cleanup** (manual or scripted)
5. **Verify build** and tests
6. **Commit changes** with detailed message

---

## 💡 RECOMMENDATIONS

### Immediate (This Session):
1. Delete commented out files (safe)
2. Delete empty admin-notifications.service.ts (safe)
3. Remove unused modal imports (safe)
4. Run ESLint auto-fix (safe)

### Next Session:
1. ⚠️ Audit and consolidate KHB services
2. ⚠️ Decide on data files (truck-vehicles, distributor)
3. ⚠️ Decide on trip-plan-report component

### Future:
1. 🔵 Add ESLint rule to prevent commented code commits
2. 🔵 Add pre-commit hook for unused imports
3. 🔵 Regular code cleanup reviews

---

**End of Report**
