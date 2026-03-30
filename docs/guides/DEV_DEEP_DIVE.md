# SV-TMS Deep Dive: Databases, Backend & Angular

> For each layer, we explain **what it is**, **how it connects**, and **the rules you must follow**.

---

## Part 1 — Databases

### Think of it like this

Imagine a warehouse with 4 storage rooms:

| Room | Database | What's stored inside |
|---|---|---|
| Main room | **MySQL 8** (`svlogistics_tms_db`) | Drivers, vehicles, dispatches, orders, customers |
| Tracking room | **PostgreSQL 16** (`svlogistics_telematics`) | GPS coordinates, geofences, live location history |
| Fast memory shelf | **Redis 7** | Login tokens, sessions, short-lived cache |
| Flexible drawer | **MongoDB 6** | Location history documents, flexible telemetry data |
| Message queue | **Kafka** | Events between services (e.g. "dispatch updated") |

---

### Which service uses which database

| Service | Database |
|---|---|
| tms-core-api | MySQL + MongoDB |
| tms-auth-api | MySQL + Redis |
| tms-telematics-api | PostgreSQL + MongoDB |
| tms-driver-app-api | MySQL |
| tms-safety-api | MySQL |
| tms-message-api | H2 (in-memory, for messaging state) + Kafka |

---

### How the schema is managed — Flyway

Flyway is like a recipe book for the database. Every change to the schema is a numbered recipe (migration file). Flyway runs all recipes in order, once, and never repeats them.

**Migration files live here:**

```
tms-core-api/src/main/resources/db/migration/
```

**Naming rule — strictly follow this:**

```
V{YYYYMMDD}__{snake_case_description}.sql
```

Examples from the real codebase:
```
V20260303__add_approval_workflow.sql
V20260308__pre_entry_safety_photos_table.sql
```

**What a migration looks like** (from the real codebase):

```sql
-- Always use IF NOT EXISTS guards
ALTER TABLE dispatch ADD COLUMN IF NOT EXISTS approval_status VARCHAR(50) DEFAULT 'NONE';

CREATE TABLE IF NOT EXISTS dispatch_approval_history (
    id         BIGINT PRIMARY KEY AUTO_INCREMENT,
    dispatch_id BIGINT NOT NULL,
    to_status  VARCHAR(50) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_dispatch_approval_history_dispatch
        FOREIGN KEY (dispatch_id) REFERENCES dispatch(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
```

**The golden rules:**

- **Never edit** a migration that has already run on production — create a new one instead.
- Always use `IF NOT EXISTS` guards so migrations are safe to run again.
- Destructive changes (DROP, TRUNCATE) must have a paired rollback script.
- Add indexes on foreign keys and frequently filtered columns.

**Add a new migration:**

```bash
/new-migration add_customer_field
# or manually:
touch tms-core-api/src/main/resources/db/migration/V20260327__add_customer_field.sql
```

---

### Starting databases locally

```bash
cd infra
docker compose -f docker-compose.prod.yml up -d mysql postgres mongo redis kafka-1
```

Wait for healthy status:

```bash
docker compose -f docker-compose.prod.yml ps
# All should show: healthy
```

Connect directly for debugging:

```bash
# MySQL
docker exec -it svtms-mysql mysql -u svtms_app -p svlogistics_tms_db

# Redis
docker exec -it svtms-redis redis-cli

# PostgreSQL
docker exec -it svtms-postgres psql -U telematics_app -d svlogistics_telematics
```

---

## Part 2 — Backend (Spring Boot)

### How the services are organized

Think of the backend like a company with different departments — each department has one job:

```
api-gateway  :8086   ← Security guard at the front door
     │
     ├── tms-core-api      :8080   ← Main office (orders, dispatch, drivers)
     ├── tms-auth-api      :8083   ← HR (login, tokens, sessions)
     ├── tms-driver-app-api :8084  ← Driver department
     ├── tms-telematics-api :8082  ← GPS tracking room
     ├── tms-safety-api    :8087   ← Safety inspector
     └── tms-message-api   :8088   ← Internal mail room
```

All requests enter through `api-gateway`. It checks auth, then routes to the correct department.

---

### Building the backend

The project is a **Maven multi-module monorepo**. The root `pom.xml` is the boss — it knows about all modules.

```bash
# Build everything from repo root (always start here)
./mvnw clean package -DskipTests

# Build only one module (but include its dependencies with -am)
./mvnw -pl tms-core-api -am clean package -DskipTests
```

> Always use `./mvnw` — never bare `mvn`. The wrapper pins the Maven version.

**After any Lombok or MapStruct change, always clean:**

```bash
./mvnw clean package -DskipTests
```

Lombok generates code at compile time (getters/setters/builders). If you skip `clean`, old generated files can conflict.

---

### Running a service locally

```bash
# From the service's directory
cd tms-core-api
./mvnw spring-boot:run -Dspring-boot.run.profiles=local
```

The `local` profile loads `application-local.yml` which overrides database URLs, disables SSL, etc.

**Start order matters:**

```
1. Databases (Docker)
2. tms-auth-api     — core-api needs auth to start cleanly
3. tms-core-api     — main business logic
4. api-gateway      — start last, it connects to everything
```

---

### How a request flows through the backend

Example: Admin opens the dispatch list in the browser.

```
1. Browser → GET /api/admin/dispatches
2. api-gateway receives request
3. Gateway validates JWT token (talks to tms-auth-api)
4. Gateway routes to tms-core-api :8080
5. tms-core-api → DispatchController → DispatchService → DispatchRepository
6. Repository queries MySQL
7. Response travels back: MySQL → Repository → Service → Controller → Gateway → Browser
```

---

### API boundary rules — critical

| Client | Allowed URL prefix |
|---|---|
| Admin UI | `/api/admin/*` and `/api/auth/*` |
| Driver app | `/api/driver/*` and `/api/auth/*` |
| Customer app | `/api/customer/{customerId}/*` and `/api/auth/*` |

**Breaking these rules is a security violation.** The gateway enforces them at runtime.

Check for violations:

```bash
/check-boundaries
```

---

### Controller → Service → Repository pattern

Every feature follows the same 3-layer structure:

```
DispatchController.java     ← handles HTTP, validates input
       ↓
DispatchService.java        ← business logic, transactions
       ↓
DispatchRepository.java     ← JPA queries to MySQL
```

When adding an endpoint:

1. Add the route in `*Controller.java`
2. Add business logic in `*Service.java`
3. Add any new queries in `*Repository.java`
4. If the schema changes, add a new Flyway migration

---

### Running backend tests

```bash
# All tests for all modules
./mvnw test

# Single module only
./mvnw -pl tms-core-api test
```

Integration tests require MySQL + Redis to be running:

```bash
docker compose -f docker-compose.prod.yml up -d mysql redis
./mvnw -pl tms-core-api test
```

> Do not mock the database in integration tests. Real DB divergence has caused prod failures before.

---

### Health check

```bash
# Gateway health (the one public endpoint)
curl http://localhost:8086/actuator/health

# Individual service health
curl http://localhost:8080/actuator/health   # core-api
curl http://localhost:8083/actuator/health   # auth-api
```

---

## Part 3 — Angular Admin UI

### Think of it like this

The Angular app is like a smart dashboard screen. It:
1. Shows data fetched from the backend
2. Lets admins take actions (approve dispatches, manage drivers, etc.)
3. Never stores real data itself — it always asks the backend

---

### Folder structure

```
tms-admin-web-ui/src/app/
├── features/          ← Feature pages (NEW code goes here)
│   ├── dispatch/
│   ├── drivers/
│   ├── bookings/
│   ├── safety/
│   └── ...
├── components/        ← Legacy shared components (do NOT add new code here)
├── services/          ← HTTP services — one per domain
│   ├── dispatch.service.ts
│   ├── driver.service.ts
│   └── ...
└── assets/
    └── i18n/          ← Translation files (English + Khmer)
```

**New features always go in `features/`**, never in `components/` (that folder is deprecated).

---

### How the dev proxy works

When you run `npm start`, Angular starts at `localhost:4200`. But all API calls go to `localhost:8086` (the gateway). The proxy config handles the translation automatically:

```
Browser at :4200
   → calls /api/admin/dispatches
   → proxy.conf.cjs catches it
   → forwards to http://127.0.0.1:8086/api/admin/dispatches
```

**That is why you must always use relative paths** in Angular code:

```typescript
// CORRECT
this.http.get('/api/admin/dispatches')

// WRONG — never hardcode ports
this.http.get('http://localhost:8080/api/admin/dispatches')
```

The proxy config ([proxy.conf.cjs](../../tms-admin-web-ui/proxy.conf.cjs)) maps specific paths to specific services:

```
/api/auth           → tms-auth-api  :8083
/api/driver-app     → tms-driver-app-api :8084
/api/admin/telematics → tms-telematics-api :8082
/api/*              → tms-core-api  :8080  (default)
/ws, /ws-sockjs     → tms-core-api  :8080  (WebSocket)
```

---

### Auth — how it works automatically

You never manually add `Authorization` headers in Angular. The `AuthInterceptor` does it for every request:

```
Component calls service.getDispatches()
   → HttpClient sends request
   → AuthInterceptor adds: Authorization: Bearer <token>
   → Request goes to backend
   → If 401 → AuthInterceptor calls refreshToken()
   → If refresh fails → user is logged out automatically
```

---

### How to make an HTTP call the right way

```typescript
// In your service file
import { HttpClient } from '@angular/common/http';
import { Injectable } from '@angular/core';
import { Observable } from 'rxjs';

@Injectable({ providedIn: 'root' })
export class DispatchService {
  constructor(private http: HttpClient) {}

  getDispatches(): Observable<any[]> {
    return this.http.get<any[]>('/api/admin/dispatches');
  }
}
```

```typescript
// In your component — subscribe to the observable
this.dispatchService.getDispatches().subscribe({
  next: (data) => this.dispatches = data,
  error: (err) => console.error(err)
});
```

---

### State management — BehaviorSubject pattern

No NgRx. Shared state uses `BehaviorSubject` in services:

```typescript
// In a service
private dispatches$ = new BehaviorSubject<Dispatch[]>([]);
readonly dispatches = this.dispatches$.asObservable();

updateDispatches(list: Dispatch[]) {
  this.dispatches$.next(list);
}
```

```typescript
// In a component
this.dispatchService.dispatches.subscribe(list => this.list = list);
```

---

### Forms — always use ReactiveFormsModule

```typescript
// In component class
form = this.fb.group({
  driverName: ['', Validators.required],
  vehicleId:  [null, Validators.required],
});

submit() {
  if (this.form.valid) {
    this.service.save(this.form.value);
  }
}
```

```html
<!-- In template -->
<form [formGroup]="form" (ngSubmit)="submit()">
  <mat-form-field>
    <input matInput formControlName="driverName" />
    <mat-error *ngIf="form.get('driverName')?.hasError('required')">
      {{ 'field.required' | translate }}
    </mat-error>
  </mat-form-field>
</form>
```

> All user-visible strings must use `| translate`. Never hardcode English text in templates.

---

### i18n — translation rules

Translation keys live in:

```
tms-admin-web-ui/src/assets/i18n/
├── en.json   ← English
└── km.json   ← Khmer
```

Usage in templates:

```html
{{ 'dispatch.title' | translate }}
{{ 'common.save' | translate }}
```

When you add new text, add the key to **both** `en.json` and `km.json`.

---

### Starting Angular

```bash
cd tms-admin-web-ui
npm ci --legacy-peer-deps   # First time only
npm start                   # http://localhost:4200
```

> Always `npm start` — not `ng serve`. Only `npm start` loads the proxy config.

---

### Running Angular tests

```bash
# Watch mode (development)
npm run test

# Headless with coverage report (CI / before committing)
npm run test:ci
```

---

### Building for production

```bash
npm run build
# Output → dist/tms-admin-web-ui/
```

In production, nginx serves the built files and handles SPA routing:

```nginx
location / {
    try_files $uri $uri/ /index.html;  # Always fall back to index.html
}
```

This means all Angular routes (`/dispatch`, `/drivers`, etc.) work when refreshed in the browser.

---

## How all 3 layers connect — end to end

```
[MySQL / Redis / Mongo / Kafka]
          ↑
   tms-core-api :8080
   tms-auth-api :8083
   tms-driver-app-api :8084
          ↑
     api-gateway :8086
          ↑
   proxy.conf.cjs (:4200)
          ↑
   Angular Component
   → calls service method
   → HttpClient + AuthInterceptor
   → relative /api/... path
          ↑
       Admin Browser
```

Every layer has one job. Keep them separated — don't put business logic in Angular, don't put presentation logic in Java controllers.

---

## Common Mistakes Cheat Sheet

| Layer | Mistake | Correct |
|---|---|---|
| Database | Edit an applied migration | Create a new migration file |
| Database | No `IF NOT EXISTS` guard | Always add it |
| Backend | Use bare `mvn` | Always `./mvnw` |
| Backend | Call another service's private API | Use shared DTO from `tms-backend-shared` |
| Backend | Mock DB in integration tests | Use real MySQL via Docker |
| Angular | `../../services/foo.service` import | Use `@services/foo.service` alias |
| Angular | Hardcode `localhost:8080` | Use relative `/api/...` path |
| Angular | Add Bootstrap to new component | Use Angular Material + Tailwind |
| Angular | Add text without translate pipe | Always `{{ 'key' | translate }}` |
| Angular | `ng serve` | `npm start` |
