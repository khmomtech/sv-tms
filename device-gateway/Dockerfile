# ── Stage 1: Build ─────────────────────────────────────────────────────────────
FROM maven:3.9.5-eclipse-temurin-21 AS builder
WORKDIR /app

# Resolve dependencies first (better layer caching)
COPY pom.xml .
RUN mvn dependency:go-offline -q

COPY src ./src
RUN mvn clean package -DskipTests -q

# ── Stage 2: Runtime ────────────────────────────────────────────────────────────
FROM eclipse-temurin:21-jre-jammy

RUN apt-get update && apt-get install -y --no-install-recommends curl \
  && rm -rf /var/lib/apt/lists/* \
  && groupadd --system appuser && useradd --system --gid appuser --no-create-home appuser

WORKDIR /app

COPY --from=builder /app/target/device-gateway-*.jar app.jar

USER appuser

EXPOSE 8085

HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=10 \
  CMD curl -f http://localhost:8085/actuator/health || exit 1

ENTRYPOINT ["sh", "-c", "exec java -XX:+UseContainerSupport -XX:MaxRAMPercentage=75.0 -jar /app/app.jar"]
