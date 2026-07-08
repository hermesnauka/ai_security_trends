FROM maven:3.9-eclipse-temurin-21 AS build
WORKDIR /build
COPY pom.xml .
RUN mvn -B dependency:go-offline
COPY src ./src
RUN mvn -B package -DskipTests

FROM eclipse-temurin:21-jre-alpine
WORKDIR /app
RUN addgroup -S securevision && adduser -S securevision -G securevision
COPY --from=build /build/target/securevision-backend.jar ./app.jar
USER securevision
EXPOSE 8080
ENTRYPOINT ["java", "-jar", "app.jar"]
