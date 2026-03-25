> [!WARNING]
> Legacy document notice: This file is kept for history and may be outdated.
> Use `/Users/sotheakh/Documents/develop/sv-tms/docs/README.md` for active documentation.

# ⚡ Quick Start - Local Dev (5 minutes)

## Terminal 1: Start MySQL
```bash
cd /Users/sotheakh/Documents/develop/sv-tms
docker compose -f docker-compose.local-dev.yml up -d
```

## Terminal 2: Start Spring Boot
```bash
cd /Users/sotheakh/Documents/develop/sv-tms/driver-app
./mvnw spring-boot:run
```

Wait for: `Started Application in X.XXX seconds`

## Terminal 3: Start Angular
```bash
cd /Users/sotheakh/Documents/develop/sv-tms/tms-frontend
npm ci --legacy-peer-deps  # (first time only)
npm run start -- --host 0.0.0.0 --port 4200
```

Wait for: `Application bundle generation complete`

## Open Browser
- **Frontend:** http://localhost:4200
- **Backend:** http://localhost:8080/actuator/health
- **Swagger UI:** http://localhost:8080/swagger-ui.html

## Stop Everything
```bash
# Terminal 1: Ctrl+C
# Terminal 2: Ctrl+C  
# Terminal 3: Ctrl+C

# Clean up MySQL
docker compose -f docker-compose.local-dev.yml down
```

---

See **LOCAL_DEV_SETUP.md** for detailed debugging guide!
