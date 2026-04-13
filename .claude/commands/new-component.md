---
name: new-component
description: UI/UX — scaffold a new Angular feature component with Material + Tailwind
---

Create a new Angular feature component for: $ARGUMENTS

Steps:
1. Determine the feature name and target directory under `tms-admin-web-ui/src/app/features/`.
2. Create the component files:
   - `{feature}/{feature}.component.ts` — standalone component or with module
   - `{feature}/{feature}.component.html` — Angular Material + Tailwind markup
   - `{feature}/{feature}.component.scss` — scoped styles (minimal, prefer Tailwind utilities)
3. Follow these conventions:
   - Use `@services/`, `@models/`, `@env/` path aliases — no `../../` imports
   - Use `ReactiveFormsModule` if the component has a form
   - Use `TranslatePipe` for all user-visible strings (`{{ 'key' | translate }}`)
   - Use Angular Material components (`mat-card`, `mat-table`, `mat-button`, etc.) — no Bootstrap
   - HTTP calls go through an injected service — never call `HttpClient` directly in a component
   - Do not add the component to `src/app/components/` — that folder is deprecated
4. If a service is needed, create `{feature}/{feature}.service.ts` with a `BehaviorSubject` for shared state.
5. Add the component to the appropriate routing module or lazy-loaded route.
6. Output the file paths created and a summary of the component's structure.
