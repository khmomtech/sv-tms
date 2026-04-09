# SV-TMS Angular Admin App

Product‑ready Angular 20 dispatcher/admin UI for SV‑TMS. Implements fleet, drivers, dispatch, orders, reports, notifications and settings with real‑time location + status updates.

## Prerequisites

- Node.js v20.19 or higher (v22.1+ recommended)
- npm or yarn

## Quick Start

```bash
git clone <repo>
cd tms-frontend
npm install
npm start
```

Dev server: http://localhost:4200 (proxying `/api` and WebSocket endpoints to backend).

## Scripts

| Command | Purpose |
|---------|---------|
| `npm start` | Dev server + proxy |
| `npm run build` | Production build (optimized) |
| `npm test` | Unit tests (Karma/Jasmine) |
| `npm run lint` | ESLint (style + rules) |
| `npm run format` | Prettier formatting |
| `npm run test:ci` | Headless tests w/ coverage |
| `npm run prepare` | Install git hooks (husky) |

Pre‑commit hook runs lint + formatting check.

## Features

- Real-time driver tracking with Google Maps
- Job management and dispatch
- Vehicle management
- Customer management
- Admin dashboard with charts
- WebSocket integration for live updates
- Responsive design with Tailwind CSS

## Architecture Overview

```
src/app/
   core/                # Singletons: auth, websocket, environment, guards
   shared/              # Reusable UI pieces, utilities, pipes, directives
   models/              # TypeScript interfaces / enums (API contracts)
   features/            # Domain feature folders (lazy loaded)
      drivers/
         attendance/      # Driver attendance permissions UI (standalone)
      fleet/
      dispatch/
      orders/
      reports/
      settings/
      notifications/
      errors/            # 404 / unauthorized pages
   routing/ (optional)  # Centralize future advanced routing utilities
   app.routes.ts        # Root route definitions (lazy loading)
   app.config.ts        # Global provider wiring (router + coreProviders)
```

### Principles

1. Feature Isolation: Components/services live inside their domain folder.
2. Path Aliases: `@core/*`, `@shared/*`, `@features/*`, `@services/*`, `@models/*`, `@env/*` for clean imports.
3. Standalone Components: Prefer Angular standalone + functional providers.
4. Minimal Shared Layer: Only generic, UI-agnostic utilities belong in `shared/`.
5. No Deep Cross Imports: Features should not import other feature internals.
6. Centralized Providers: `coreProviders` registers interceptors + HttpClient once.
7. Idempotent API Calls: WebSocket reconnect logic lives in core services.

## Backend Integration

Primary backend: Spring Boot (`driver-app`).

| Concern | Implementation |
|---------|----------------|
| REST API | `HttpClient` calls in domain services under `@services` |
| Auth | JWT handled by `AuthService` + `AuthInterceptor` |
| WebSocket | STOMP/SockJS via `SocketService` and `ConnectionMonitorService` |
| Runtime Config | `EnvironmentService` wraps `environment.*` values |

### Environment & Runtime Overrides

Runtime env injection via global `__env` object (optional). See `src/app/environments/*.ts` for details.

### Note about permissions: `all_functions`

- **Wildcard permission:** The backend may include a special permission named `all_functions` which acts as a wildcard granting effectively all application permissions. The Angular frontend treats `all_functions` as full access when evaluating client-side guards.
- **Dev seeder:** In development the backend can be configured to seed `all_functions` and attach it to admin roles (see `driver-app` dev compose/migration instructions). For local checks, log in as `admin`/`superadmin` and inspect the login response for `user.permissions`.

Example quick check (replace credentials):

```bash
curl -s -X POST http://localhost:8080/api/auth/login \
   -H "Content-Type: application/json" \
   -d '{"username":"admin","password":"<ADMIN_PASSWORD>","deviceId":"cli"}' \
   | jq '.data.user.permissions'
```


## Code Quality

| Tool | Purpose |
|------|---------|
| ESLint | Lint + import order + selector rules |
| Prettier | Formatting (100 column, single quotes) |
| Husky | Pre‑commit safeguard |
| Strict TS | Enabled (`strictTemplates`, `strictInjectionParameters`) |

Restricted imports: legacy `components/` path flagged to enforce migration to `features/`.

## Testing Strategy

Short‑term: Keep unit tests focused on pure services & pipes. As migration proceeds, add spec files inside each feature folder.

Suggested additions (future):
1. Cypress or Playwright for e2e smoke flows.
2. Jest + ng-jest for faster unit test runs (optional migration).

## Development Conventions

| Area | Convention |
|------|------------|
| Component Naming | `PascalCase` class, selector `app-*` kebab |
| Service Naming | Suffix `Service` |
| DTO/Model | Singular, suffix `Dto` only for write models |
| Imports | Group + alphabetize (enforced) |
| Styling | Tailwind first; avoid inline styles |
| Date Handling | Use ISO strings; convert at API boundary |
| WebSocket Topics | Keep centralized in socket service constants |

## Refactor Status

✔ Path aliases established
✔ Core providers (`coreProviders`) added
✔ Environment service wrapper
✔ Driver attendance feature migrated to `features/drivers/attendance`
✔ Prettier + ESLint enhancements
✔ Husky pre‑commit hook
⧗ Remaining: Migrate remaining legacy `components/` into domain feature folders; add `drivers.routes.ts` & additional feature route modules; increase unit/e2e test coverage.

## Roadmap (Optional Next Steps)

1. Introduce state management layer (`signal-store` or `@ngrx/signals`).
2. Replace scattered modal implementations with a unified modal service + portal component.
3. Add accessibility audit (axe-core) in CI.
4. Implement performance budgets for largest features (custom route-level code splitting).
5. Add error boundary component for failed feature module loads.

## License

Internal proprietary application – not for public redistribution.
