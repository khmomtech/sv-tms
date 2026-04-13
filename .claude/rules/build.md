---
description: Build conventions for Maven multi-module, Angular, and Flutter
---

# Build Conventions

## Maven (Backend)

- Always use `./mvnw`, never bare `mvn`.
- Multi-module services (build from **repo root**):
  `tms-core-api`, `tms-auth-api`, `tms-driver-app-api`, `tms-message-api`, `api-gateway`
  → depend on `tms-backend-shared`, root `pom.xml` is the reactor.
- Standalone services (build from **their own directory**):
  `tms-telematics-api`, `tms-safety-api`

```bash
# Build everything (skip tests)
./mvnw clean package -DskipTests

# Build single module with its dependencies
./mvnw -pl tms-core-api -am clean package -DskipTests

# Run locally
cd tms-core-api && ./mvnw spring-boot:run -Dspring-boot.run.profiles=local
```

- After any Lombok or MapStruct class change: run `./mvnw clean package` to regenerate annotation processors.
- Maven heap on VPS is capped at 1 GB (`MAVEN_OPTS=-Xmx1g`) — do not add `-T` parallel flag, it causes OOM.

## Angular

```bash
cd tms-admin-web-ui
npm ci --legacy-peer-deps   # Install deps
npm start                   # Dev server (uses proxy.conf.cjs → port 8086)
npm run build               # Production build
```

- Use `npm start` not `ng serve` — the proxy config only loads via `npm start`.

## Flutter

```bash
cd tms_driver_app
flutter pub get
flutter run                 # Debug on connected device
flutter build apk           # Release APK
```

- API base URL must be set at compile time: `--dart-define=API_BASE_URL=<url>`
- Android emulator: use `10.0.2.2` not `localhost`.
