# syntax=docker/dockerfile:1.7
# ----------------------------------------------
# Stage 1: Build
# ----------------------------------------------
FROM maven:3.9.5-eclipse-temurin-21 AS builder
WORKDIR /app

# Copy root pom and module poms so Maven can resolve multi-module dependencies.
COPY pom.xml .
COPY tms-core-api/pom.xml tms-core-api/pom.xml
COPY tms-backend-shared/pom.xml tms-backend-shared/pom.xml
COPY tms-auth-api/pom.xml tms-auth-api/pom.xml
COPY tms-driver-app-api/pom.xml tms-driver-app-api/pom.xml
COPY tms-telematics-api/pom.xml tms-telematics-api/pom.xml
COPY tms-safety-api/pom.xml tms-safety-api/pom.xml
COPY api-gateway/pom.xml api-gateway/pom.xml
COPY tms-message-api/pom.xml tms-message-api/pom.xml
COPY device-gateway/pom.xml device-gateway/pom.xml

# Ensure expected module directories exist for the root reactor.
COPY tms-core-api tms-core-api
COPY tms-telematics-api tms-telematics-api
COPY tms-safety-api tms-safety-api
COPY api-gateway api-gateway
COPY tms-message-api tms-message-api
COPY tms-auth-api tms-auth-api
COPY tms-driver-app-api tms-driver-app-api
COPY device-gateway device-gateway

# Copy source for both backend and shared modules.
COPY tms-core-api/src ./tms-core-api/src
COPY tms-backend-shared/src ./tms-backend-shared/src

# Copy additional modules required by the root reactor POM
COPY device-gateway device-gateway

# Build the backend module.
# Skip tests compilation/run to avoid CI-only test dependencies and speed up local builds.
RUN --mount=type=cache,target=/root/.m2 \
    mvn -pl tms-core-api -am clean package -Dmaven.test.skip=true

# ----------------------------------------------
# Stage 2: Runtime
# ----------------------------------------------
FROM eclipse-temurin:21-jdk-jammy

RUN apt-get update \
 && apt-get install -y --no-install-recommends curl \
 && rm -rf /var/lib/apt/lists/* \
 && addgroup --system appuser \
 && adduser --system --ingroup appuser --no-create-home appuser

WORKDIR /app

# The backend module builds an executable Spring Boot jar with classifier 'exec'.
# Copy that jar into the runtime image.
COPY --from=builder /app/tms-core-api/target/*-exec.jar app.jar
COPY tms-core-api/init-uploads.sh .

RUN chmod +x init-uploads.sh \
 && mkdir -p /app/uploads \
 && chown -R appuser:appuser /app

USER appuser

# Container-aware JVM
ENV JAVA_OPTS="\
-XX:+UseContainerSupport \
-XX:MaxRAMPercentage=75.0 \
-XX:+HeapDumpOnOutOfMemoryError \
-XX:HeapDumpPath=/tmp/oom.hprof \
-Xlog:gc*:file=/tmp/gc.log:tags,time,level:filecount=5,filesize=10m"

VOLUME ["/app/uploads"]

HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=10 \
 CMD curl -f http://localhost:8080/actuator/health || exit 1

EXPOSE 8080

ENTRYPOINT ["sh", "-c", "./init-uploads.sh && exec java $JAVA_OPTS -jar /app/app.jar"]
