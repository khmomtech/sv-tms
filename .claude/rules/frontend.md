---
description: UI/UX and Angular frontend conventions for tms-admin-web-ui
paths:
  - "tms-admin-web-ui/**"
---

# Frontend (Angular) Conventions

## Design System

- **Angular Material + Tailwind** — standard. Use these for all new components.
- **Bootstrap is legacy** — do not add Bootstrap to new components. Existing legacy components in `src/app/components/` may still use it.
- When in doubt about a UI pattern, match the existing feature in `src/app/features/`.

## Component Structure

```
src/app/features/{feature-name}/
├── {feature-name}.component.ts
├── {feature-name}.component.html
├── {feature-name}.component.scss
└── {feature-name}.module.ts  (or standalone component)
```

- New components go in `src/app/features/`, never in `src/app/components/` (that folder is deprecated).
- Use `@services/`, `@models/`, `@env/` path aliases — never relative `../../` imports.

## State Management

- **No NgRx.** Use RxJS `BehaviorSubject` in services for shared state.
- Component-local state can use signals (Angular 17+) or plain class properties.

## HTTP and Auth

- All API calls use relative paths (`/api/...`) — the dev proxy in `proxy.conf.cjs` routes to port 8086.
- Never call `http://localhost:808x` directly from Angular code.
- `AuthInterceptor` automatically injects Bearer token — do not add Authorization headers manually.
- On 401: `authService.refreshToken()` is called automatically. If it fails, user is logged out.

## i18n

- All user-visible strings must use `TranslatePipe` — `{{ 'key' | translate }}`.
- Translation keys live in `src/assets/i18n/`.
- Never hardcode English strings in templates.

## Reactive Forms

- Use `ReactiveFormsModule` (not template-driven) for all forms.
- Validators go in the component class, not inline in the template.

## Dev Server

```bash
cd tms-admin-web-ui
npm ci --legacy-peer-deps
npm start          # http://localhost:4200 — proxies /api/* to port 8086
```
