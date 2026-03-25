# device-gateway

Device gateway microservice for ingesting driver telemetry (GPS points) and storing them reliably.

## Run

From the repository root:

```bash
cd device-gateway
./mvnw spring-boot:run
```

## Test

```bash
cd device-gateway
./mvnw test
```

## Configuration

- `application.yml` contains default MySQL datasource configuration.
- `application-test.yml` uses an in-memory H2 database for unit/integration tests.
