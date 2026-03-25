# syntax=docker/dockerfile:1.7
FROM maven:3.9.5-eclipse-temurin-21 AS builder
WORKDIR /app

COPY pom.xml .
COPY tms-backend-shared/pom.xml tms-backend-shared/pom.xml
COPY tms-message-api/pom.xml tms-message-api/pom.xml
COPY tms-core-api/pom.xml tms-core-api/pom.xml
COPY tms-auth-api/pom.xml tms-auth-api/pom.xml
COPY tms-driver-app-api/pom.xml tms-driver-app-api/pom.xml
COPY tms-telematics-api/pom.xml tms-telematics-api/pom.xml
COPY tms-safety-api/pom.xml tms-safety-api/pom.xml
COPY api-gateway/pom.xml api-gateway/pom.xml
COPY device-gateway/pom.xml device-gateway/pom.xml

RUN --mount=type=cache,target=/root/.m2 \
    mvn -pl tms-message-api -am dependency:go-offline

COPY tms-backend-shared/src tms-backend-shared/src
COPY tms-message-api/src tms-message-api/src

RUN --mount=type=cache,target=/root/.m2 \
    mvn -pl tms-message-api -am clean package -Dmaven.test.skip=true

FROM eclipse-temurin:21-jre-jammy
RUN apt-get update \
 && apt-get install -y --no-install-recommends curl \
 && rm -rf /var/lib/apt/lists/*
WORKDIR /app
COPY --from=builder /app/tms-message-api/target/*.jar app.jar
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=10 \
 CMD curl -f http://localhost:8088/actuator/health || exit 1
EXPOSE 8088
ENTRYPOINT ["java", "-jar", "/app/app.jar"]
