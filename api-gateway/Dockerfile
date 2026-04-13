# syntax=docker/dockerfile:1.7
FROM maven:3.9.5-eclipse-temurin-21 AS builder
WORKDIR /app

COPY pom.xml .
COPY tms-backend-shared/pom.xml tms-backend-shared/pom.xml
COPY api-gateway/pom.xml api-gateway/pom.xml
COPY tms-core-api/pom.xml tms-core-api/pom.xml
COPY tms-auth-api/pom.xml tms-auth-api/pom.xml
COPY tms-driver-app-api/pom.xml tms-driver-app-api/pom.xml
COPY tms-telematics-api/pom.xml tms-telematics-api/pom.xml
COPY tms-safety-api/pom.xml tms-safety-api/pom.xml
COPY tms-message-api/pom.xml tms-message-api/pom.xml
COPY device-gateway/pom.xml device-gateway/pom.xml

COPY tms-backend-shared/src tms-backend-shared/src
COPY api-gateway/src api-gateway/src

RUN --mount=type=cache,target=/root/.m2 \
    mvn -pl api-gateway -am clean package -Dmaven.test.skip=true

RUN mkdir -p /layers/api-gateway \
 && cd /layers/api-gateway \
 && jar -xf /app/api-gateway/target/*.jar

FROM eclipse-temurin:21-jre-jammy
RUN apt-get update \
 && apt-get install -y --no-install-recommends curl \
 && rm -rf /var/lib/apt/lists/* \
 && groupadd -r appgroup && useradd -r -g appgroup -s /bin/false appuser
WORKDIR /app
COPY --from=builder /layers/api-gateway/ /app/
RUN chown -R appuser:appgroup /app
USER appuser
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=10 \
 CMD curl -f http://localhost:8086/actuator/health || exit 1
EXPOSE 8086
ENTRYPOINT ["java", "org.springframework.boot.loader.launch.JarLauncher"]
