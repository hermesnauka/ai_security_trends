FROM sbtscala/scala-sbt:eclipse-temurin-21.0.11_10_1.12.13_3.3.8 AS build
WORKDIR /build
COPY project ./project
COPY build.sbt ./
RUN sbt update
COPY src ./src
RUN sbt assembly

FROM eclipse-temurin:21-jre-alpine
WORKDIR /app
RUN addgroup -S scalashield && adduser -S scalashield -G scalashield
COPY --from=build /build/target/scala-3.3.8/scalashield-backend-assembly-*.jar ./app.jar
USER scalashield
EXPOSE 8080
ENTRYPOINT ["java", "-jar", "app.jar"]
