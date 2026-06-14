# Slim runtime image — no Maven, no JDK, just a JRE + the app jar
FROM eclipse-temurin:17-jre
WORKDIR /app
ARG SERVICE
COPY ${SERVICE}/target/*.jar app.jar
EXPOSE 8080
ENTRYPOINT ["java","-jar","app.jar"]
