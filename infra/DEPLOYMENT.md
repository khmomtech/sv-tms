**Backend and Frontend Deployment Guide**

**Purpose:**
- **Summary:** Concise, reproducible steps to build and deploy the `tms-backend` and `tms-frontend` services for development and production.

**Prerequisites:**
- **Credentials:** Service account keys, database credentials, and any cloud secrets stored in secret manager or CI.
- **Tools:** `git`, `docker`, `docker-compose`, Java (matched to `pom.xml`), Maven (`./mvnw`), Node >=16, `npm`/`pnpm`, and Angular CLI for local dev.
- **Local services:** MySQL (or compatible), Redis, and optional Firebase Admin credentials for integrations.

**Quick environment variables (examples):**
- **Backend:** `SPRING_PROFILES_ACTIVE`, `DATABASE_URL`, `DATABASE_USERNAME`, `DATABASE_PASSWORD`, `JWT_SECRET`, `FIREBASE_CREDENTIALS_PATH`, `UPLOADS_DIR`
- **Frontend:** `API_BASE_URL`, `NG_ENV` (or environment-specific config files)

**Backend (tms-backend)**
- **Build (local):**
  - Use the Maven wrapper to ensure consistent environment:

    ```bash
    cd tms-backend
    ./mvnw clean package -DskipTests
    ```

- **Run locally:**
  - With Maven:

    ```bash
    ./mvnw spring-boot:run -Dspring-boot.run.profiles=dev
    ```

  - Or run the packaged jar:

    ```bash
    java -jar target/*.jar --spring.profiles.active=dev
    ```

- **Docker image (build & run):**
  - Build image (from repo root):

    ```bash
    cd tms-backend
    docker build -t sv-tms/backend:latest .
    ```

  - Run container (example):

    ```bash
    docker run --env-file ./env/backend.env -v /absolute/uploads:/app/uploads -p 8080:8080 sv-tms/backend:latest
    ```

- **Database migrations / schema:**
  - If using Flyway or Liquibase, run migrations during boot or as a pre-deploy job. For SQL-only projects, run SQL migration scripts against the DB before starting the app.
- **Uploads & persistent storage:**
  - Mount a host volume or network storage to the container path used by the backend for file uploads (e.g., `/app/uploads`).
- **Common production notes:**
  - Ensure Java runtime matches `pom.xml` `java.version`. If Dockerfile uses a different JDK, align or adjust images.
  - Externalize secrets via environment variables or a secret manager—do not commit credentials.

**Frontend (tms-frontend — Angular)**
- **Install deps:**

  ```bash
  cd tms-frontend
  npm ci
  ```

- **Build (production):**

  ```bash
  npm run build -- --configuration=production
  ```

  - Outputs go to `dist/` by default. Serve via static host (Nginx, CDN, or cloud storage + CDN).

- **Dev server:**

  ```bash
  npm run start
  ```

  - Use the provided `proxy.conf.json` in dev to forward `/api` to backend to avoid CORS.

- **Serving in production (Nginx example):**
  - Copy `dist/<app>` into your web root and configure `try_files $uri $uri/ /index.html;` for SPA routing.
  - Set `API_BASE_URL` at build time or use runtime configuration (small JS file loaded at app start) to avoid rebuilds when changing backend endpoints.

**Docker Compose (development)**
- **Use case:** Quickly bring up backend, DB, Redis and frontend dev or static server.
- **Example:** Use `docker-compose.dev.yml` (or create one) that:
  - Builds `tms-backend` image via `./mvnw` stage or uses prebuilt image.
  - Starts MySQL with a volume for persistence.
  - Starts Redis.
  - Optionally serves `tms-frontend` with `nginx` image or lets developers run `npm start` locally.

**Production Deployment Options (brief)**
- **Container Hosts:** Docker on VM, ECS, Kubernetes, or managed container platforms.
- **Kubernetes:** Deploy backend as Deployment + Service, mount a PVC for uploads, use Secrets for env. Add Liveness and Readiness probes.
- **App Service / Cloud Run:** Build container image, push to registry, and deploy using cloud managed services. Ensure environment vars and secrets are configured.

**CI/CD (outline)**
- **Build pipeline steps:**
  1. Checkout code.
  2. Run linters and unit tests.
  3. Build backend image: `./mvnw clean package` → Docker build → push to registry with tag (branch/commit).
  4. Build frontend: `npm ci` → `npm run build` → publish static artifacts or build frontend image.
  5. Run migration job against a staging DB (if applicable).
  6. Deploy to staging (K8s/Azure/ECS) and run smoke tests.
  7. Promote to production after approvals.

- **Rollback:** Keep previous image tags and a deployment strategy (blue/green or rolling) to revert quickly.

**Health checks & monitoring**
- **Backend:** Expose `/actuator/health` or equivalent. Configure readiness & liveness in orchestration.
- **Logging:** Centralize logs (ELK, Cloud Logging). Ensure structured logs and error levels.
- **Metrics:** Expose Prometheus metrics if using Prometheus/Grafana.

**Security & secrets**
- Use environment-based secrets or secret manager (Vault, AWS Secrets Manager, Azure Key Vault).
- Avoid embedding credentials in Docker images.
- Use HTTPS/TLS termination at edge (load balancer or CDN).

**Troubleshooting & common pitfalls**
- **Java version mismatch:** If `pom.xml` targets Java 21 but Dockerfile uses Java 17, builds or runtime may fail — align both.
- **CORS errors:** Use proxy in dev; set CORS policy in backend for known origins in production.
- **File permissions on uploads:** When mounting host volumes, ensure container user has write permissions.

**Quick Commands (summary)**
- Build backend jar:

  ```bash
  cd tms-backend
  ./mvnw clean package -DskipTests
  ```

- Build frontend production:

  ```bash
  cd tms-frontend
  npm ci
  npm run build -- --configuration=production
  ```

- Docker compose bring up (dev):

  ```bash
  docker compose -f docker-compose.dev.yml up --build
  ```

**Next steps / Optional additions**
- Kubernetes manifests for backend and frontend.
- A sample `docker-compose.dev.yml` and a production `docker-compose.yml`.
- CI pipeline YAML (GitHub Actions / GitLab CI) with image tags, scanning, and deployment steps.

---
*Created: infra/DEPLOYMENT.md*

**Docker Compose (dev) — example**
- Place `infra/docker-compose.dev.yml` next to this file for quick local brings-up. Example file includes `mysql`, `redis`, `backend` (built from `tms-backend`) and a `frontend` dev service that runs `npm start`.

Use:

```bash
docker compose -f infra/docker-compose.dev.yml up --build
```

**Example env file**
- Copy `infra/backend.env.example` → `infra/backend.env` and fill secrets before using compose or running containers locally.

**CI/CD example (GitHub Actions)**
- A sample workflow is included at `.github/workflows/ci-cd.yml` — it:
  - builds the backend jar with `./mvnw`;
  - builds the frontend production bundle;
  - optionally builds and pushes Docker images when registry secrets are set.

Customize the workflow to add staging promotion, migrations, and deployment steps (kubectl/helm/az/ecs/terraform).

**Final notes**
- If you want, I can now:
  - Add `infra/docker-compose.prod.yml` tuned for production volumes and networks.
  - Add a GitHub Actions `deploy` job that runs `kubectl`/`helm` using a `KUBE_CONFIG` secret.
  - Generate Kubernetes manifests and a sample Helm chart.

---
*Updated: infra/DEPLOYMENT.md*