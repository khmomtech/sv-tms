# Local Startup Order (VSCode + Vite)

## 1) Start dependencies

1. Start MySQL on `localhost:3307`.
2. Start Redis on `localhost:6379` (optional but recommended).

You can run:

```bash
cd tms-backend
./scripts/local-preflight.sh
```

## 2) Start backend on `8080`

Preferred (VSCode):

1. Open `.vscode/launch.json`.
2. Run launch profile: `🌟 Backend - Spring Boot (Local Dev)`.

Terminal fallback:

```bash
cd tms-backend
./run-with-env.sh
```

or:

```bash
cd tms-backend
./mvnw spring-boot:run -Dspring-boot.run.main-class=com.svtrucking.logistics.Application
```

## 3) Verify backend health

```bash
curl -sS http://localhost:8080/actuator/health
```

Expected: HTTP 200 with `"status":"UP"` (or healthy payload for your profile).

## 4) Start frontend

```bash
cd tms-frontend
npm start
```

Frontend dev server listens on `http://localhost:4200`, proxying `/api` and `/ws-sockjs` to `http://localhost:8080`.

## Troubleshooting

- `ECONNREFUSED /ws-sockjs` in Vite logs:
  - Network-level issue. Backend is not reachable on `localhost:8080`.
  - Fix by starting backend first and confirming port `8080` is listening.

- `401/403` on `/ws-sockjs/...`:
  - Auth-level issue. Token missing/expired/invalid or user not found.
  - Re-login and check backend logs for websocket auth reason categories:
    - `missing_token`
    - `expired_token`
    - `invalid_signature`
    - `user_not_found`

- `ClassFormatError` (for example: `Extra bytes at the end of class file ...CustomerContactDto`):
  - Usually stale/corrupted local build artifacts, not source code.
  - Recovery sequence:
    1. Stop backend process.
    2. Remove compiled output: `rm -rf target`.
    3. Rebuild cleanly: `./mvnw -DskipTests clean compile`.
    4. Validate class bytecode: `javap -classpath target/classes com.svtrucking.logistics.dto.CustomerContactDto`.
    5. Start backend again with explicit main class:
       - `./mvnw spring-boot:run -Dspring-boot.run.main-class=com.svtrucking.logistics.Application`
