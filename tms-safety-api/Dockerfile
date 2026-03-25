# syntax=docker/dockerfile:1.7
# ----------------------------------------------
# Stage 1: Build
# ----------------------------------------------
FROM maven:3.9.5-eclipse-temurin-21 AS builder
WORKDIR /app

COPY pom.xml .
COPY src ./src
RUN --mount=type=cache,target=/root/.m2 \
    mvn clean package -DskipTests

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

COPY --from=builder /app/target/*.jar app.jar
COPY init-uploads.sh .

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
 CMD sh -c 'curl -f "http://localhost:${SERVER_PORT:-8080}/actuator/health" || exit 1'

EXPOSE 8080

ENTRYPOINT ["sh", "-c", "./init-uploads.sh && exec java $JAVA_OPTS -jar /app/app.jar"]
