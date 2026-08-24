# syntax=docker/dockerfile:1.7
FROM maven:3.9-eclipse-temurin-21 AS dependencies
WORKDIR /workspace
COPY pom.xml .
RUN --mount=type=cache,target=/root/.m2 \
    mvn --batch-mode -DskipTests dependency:go-offline

FROM dependencies AS build
COPY src src
RUN --mount=type=cache,target=/root/.m2 \
    mvn --batch-mode -DskipTests package

FROM eclipse-temurin:21-jre AS runtime
ENV SPRING_PROFILES_ACTIVE=prod
WORKDIR /app
RUN useradd --system --uid 10001 --no-create-home appuser
COPY --from=build --chown=10001:10001 /workspace/target/*.jar /app/app.jar
USER 10001
EXPOSE 8080
ENTRYPOINT ["java", "-XX:MaxRAMPercentage=75", "-XX:+ExitOnOutOfMemoryError", "-jar", "/app/app.jar"]
