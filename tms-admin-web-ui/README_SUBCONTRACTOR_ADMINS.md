# Subcontractor Admins Flow

This document summarizes the current implementation and improvements applied to the Subcontractor Admins feature.

## Overview
The feature lists partner companies (vendors/subcontractors) and displays assigned admin users with their permissions. It uses a standalone Angular component `subcontractor-admins.component.ts` loaded via the route `/subcontractors/admins`.

## Key Files
- Route: `src/app/app.routes.ts` (lazy loaded standalone component route)
- Component: `src/app/features/vendors/subcontractors/admins/subcontractor-admins.component.ts`
- Service: `src/app/services/partner.service.ts` (exposed via `vendor.service.ts` alias)
- Models: `src/app/models/partner.model.ts` (`PartnerCompany`, `PartnerAdmin`)

## Data Flow
1. Component initializes and calls `PartnerService.getAllPartners()` to populate companies list.
2. User selects a company; component calls `PartnerService.getCompanyAdmins(companyId)`.
3. Response mapped to `PartnerAdmin[]` and rendered in table with permission flags.
4. Errors are captured and displayed; loading state managed by signals.

## Recent Improvements
- Corrected import path for `PartnerAdmin` (use consolidated model file).
- Replaced non-existent `getAdminsByCompany` call with `getCompanyAdmins`.
- Added explicit typing for subscription handlers (resolved implicit `any`).
- Updated template bindings to match nested `user.username` and `user.email` structure.
- Added error resets before new loads and ensured loading flag clears on failure.
- Added `trackByAdmin` for improved rendering performance on large lists.
- Added unit tests for `getCompanyAdmins` URL and mapping logic (`partner.service.spec.ts`).

## Future Enhancements
- Add UI for assigning/removing admins (form + permission toggles).
- Integrate optimistic updates or refresh button debounce.
- Display audit metadata (created/updated timestamps with relative date pipe).
- Introduce reusable permission badge component.
- Cache partner companies list in a signal store to avoid duplicate network requests.

## Testing
Run unit tests:
```bash
npm run test:unit:one
```
Or full suite:
```bash
npm run test:unit
```

## Troubleshooting
- Ensure backend reachable at `http://localhost:8080` or run Docker stack for hostname `backend`.
- If list empty, verify API endpoints `/partners` and `/partner-admins/company/{id}` respond with data.
- Check auth token / login flow if 401 errors occur.

---
This file is auto-generated as part of improving subcontractor admin flow.
