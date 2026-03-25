# Dependencies: Status and Plan

This document tracks notable frontend dependencies, their status with Angular 20, and follow‑ups.

- Angular 20 alignment: All core Angular packages are on v20.x and build succeeds.
- Removed deprecated/unused:
  - `@google/markerclustererplus` (unused; replaced by `@googlemaps/markerclusterer` already in use)
  - `@stomp/ng2-stompjs` (unused; using `@stomp/stompjs` directly)
  - `angular-split` (unused)
  - `xlsx-js-style` (unused)

## Vulnerabilities

- `xlsx@0.18.5`: High severity advisory reported by `npm audit`.
  - GHSA references indicate issues fixed in >= 0.19.3 and >= 0.20.2.
  - Our current registry mirror did not provide 0.19.x/0.20.x during upgrade attempts; install failed with `ETARGET`.
  - Impact: Used for client‑side Excel import in:
    - `src/app/components/order-list/bulk-order-upload/bulk-order-upload.component.ts`
    - `src/app/pages/bulk-dispatch-upload/bulk-dispatch-upload.component.ts`
    - `src/app/components/so-upload/so-upload.component.ts`

### Mitigation Plan

1. Preferred: Upgrade `xlsx` to a patched version as soon as the registry provides `0.19.3+` or `0.20.2+`.
2. Alternative: Migrate Excel reading to `exceljs` (already used for writes in `so-upload`).
   - Implement header row parsing and row mapping with `exceljs.Workbook().xlsx.load(arrayBuffer)`.
   - Replace all XLSX read usages and remove the `xlsx` package.
3. Interim: Inputs are limited by size/type and parsed via ArrayBuffer to reduce risk; does not remove the audit finding.

## How to Re‑check

```bash
cd tms-frontend
npm ci
npm audit
```

## Next Actions

- Try `xlsx` upgrade again later. If available, bump and re‑run build.
- If upgrade remains blocked, schedule the migration to `exceljs` for reading.
