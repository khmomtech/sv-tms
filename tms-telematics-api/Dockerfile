# syntax=docker/dockerfile:1.7
# ── Stage 1: Build ─────────────────────────────────────────────────────────────
FROM maven:3.9.5-eclipse-temurin-21 AS builder
WORKDIR /app

# Resolve dependencies first (better layer caching)
COPY pom.xml .
RUN --mount=type=cache,target=/root/.m2 \
    mvn dependency:go-offline -q

COPY src ./src
RUN --mount=type=cache,target=/root/.m2 \
    mvn clean package -DskipTests -q

# ── Stage 2: Runtime ────────────────────────────────────────────────────────────
FROM eclipse-temurin:21-jre-jammy

RUN apt-get update && apt-get install -y --no-install-recommends curl \
  && rm -rf /var/lib/apt/lists/* \
  && groupadd --system appuser && useradd --system --gid appuser --no-create-home appuser

WORKDIR /app

COPY --from=builder /app/target/tms-telematics-api-*.jar app.jar

# Spool directory for offline location history buffering
RUN mkdir -p /app/spool && chown -R appuser:appuser /app

USER appuser

VOLUME ["/app/spool"]

EXPOSE 8082

HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=10 \
  CMD curl -f http://localhost:8082/actuator/health || exit 1

ENTRYPOINT ["sh", "-c", "exec java -XX:+UseContainerSupport -XX:MaxRAMPercentage=75.0 -jar /app/app.jar"]
