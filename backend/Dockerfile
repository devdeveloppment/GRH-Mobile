FROM eclipse-temurin:17-jre-alpine

WORKDIR /app

ARG JAR_FILE=target/grh-mobile-api-1.0.0.jar
COPY ${JAR_FILE} app.jar

EXPOSE 8080

ENTRYPOINT ["java", "-XX:+UseContainerSupport", "-XX:MaxRAMPercentage=75.0", "-jar", "/app/app.jar"]
