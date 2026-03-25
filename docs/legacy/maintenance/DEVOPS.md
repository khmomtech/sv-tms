> [!WARNING]
> Legacy document notice: This file is kept for history and may be outdated.
> Use `/Users/sotheakh/Documents/develop/sv-tms/docs/README.md` for active documentation.

# SV-TMS — Development & Operations (DEVOPS)

Purpose
This document collects practical, repo-specific developer and operational instructions for running, building, and deploying the SV-TMS stack (backend, angular frontend, flutter mobile). Use this as the single place for reproducible dev setup, CI guidance, secrets handling and common troubleshooting.

Projects
- `driver-app/` — Spring Boot backend (API, WebSocket, MySQL, Firebase Admin).
- `tms-frontend/` — Angular dispatcher/admin UI (ng serve in dev, build for prod).
- `tms_driver_app/` — Flutter driver mobile app.

Quick start (full stack local)
1. Copy env examples to real env files or set necessary env vars.

```bash
cp driver-app/.env.example driver-app/.env
cp tms-frontend/.env.example tms-frontend/.env
cp tms_driver_app/.env.example tms_driver_app/.env
```

2. Start the full dev stack (MySQL + backend + angular dev server):

```bash
docker compose -f docker-compose.dev.yml up --build
```

3. Open:
- Backend: http://localhost:8080 (Actuator at /actuator/health)
- Angular: http://localhost:4200 (dev server)

Important local commands
- Backend
  - Build (skip tests): ./mvnw clean package -DskipTests
  - Run dev: ./mvnw spring-boot:run
  - Tests: ./mvnw test
- Angular
  - Install: npm ci
  - Dev: npm run start
  - Build: npm run build
- Flutter
  - Get packages: flutter pub get
  - Run: flutter run
  - Build apk: flutter build apk

Environment & secrets
- Do NOT commit secrets. Use `.env` files locally and CI secret store in GitHub Actions.
- Key variables (examples):
  - Backend: SPRING_DATASOURCE_URL, SPRING_DATASOURCE_USERNAME, SPRING_DATASOURCE_PASSWORD, JWT_SECRET, FIREBASE_CREDENTIALS (path)
  - Angular: VITE_API_URL or API_URL (depends on build), MAP_API_KEY
  - Flutter: API_BASE_URL, FIREBASE_API_KEY, MAP_API_KEY
- See the provided `.env.example` files in each project for exact names.

OpenAPI & client generation
- Backend exposes OpenAPI via springdoc at `/v3/api-docs` and Swagger UI (if enabled). To export and freeze the contract:

```bash
# with backend running locally
curl -s http://localhost:8080/v3/api-docs > api/driver-app-openapi.json
```

- Use the OpenAPI file to generate clients:
  - TypeScript (Angular): openapi-generator or `@openapitools/openapi-generator-cli` to produce typed services
  - Dart (Flutter): `openapi-generator` with `dart-dio` or `dart` generator

CI/CD guidance
- Backend job
  - Run: `./mvnw -B -DskipTests=false test package`
  - Build Docker image and push to registry
- Angular job
  - Run: `npm ci && npm run build`
- Flutter job
  - Run: `flutter pub get && flutter test && flutter build apk` (for release artifact)
- Integration tests
  - Use docker-compose in the job to bring up mysql + backend + angular (or mocked frontend) and run smoke tests against HTTP endpoints.

Backups & restores
- Repo includes scripts: `backup_docker_mysql.sh`, `restore_mysql.sh`, `backup_docker_uploads.sh`, `restore_uploads.sh`. Use these for local/ops backup of MySQL and `uploads/` directory.

Health & monitoring
- Backend: Spring Boot Actuator is included. Ensure `/actuator/health` is reachable for healthchecks and Docker.
- Consider adding Prometheus exporter and JSON logging for production observability.

Java runtime alignment
- Current repo note: `pom.xml` sets Java 21 but Dockerfile uses Temurin 17. Choose one:
  1) Upgrade Dockerfile base images to Temurin 21 (recommended), or
  2) Downgrade `pom.xml` `<java.version>` to 17 if you must remain on JDK 17.

Troubleshooting tips
- MapStruct/Lombok compilation errors: run a full `./mvnw clean package` locally. Ensure IDE has annotation processing enabled.
- DB connection errors: check `docker compose ps` and `docker logs svtms-mysql` for init failures (bad SQL or permission issues).

Security notes
- Do not commit Firebase service account files — mount them into the backend container via docker-compose or provide a mock sender in local dev.
- Use CI secrets for JWT signing keys, DB passwords, and Firebase credentials.

Next steps (recommended immediate tasks)
1. Align Java runtime version across `pom.xml` and `Dockerfile`.
2. Create GitHub Actions CI for all three projects.
3. Export OpenAPI and add generated clients for Angular and Flutter.

If you want, I can implement any of the above steps (CI, Java alignment, client generation).
