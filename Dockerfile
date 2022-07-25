# Selecting image to use for build stage
FROM eclipse-temurin:11-jdk as builder
# Designating work directory
WORKDIR app

# Copying application into the build stage
COPY mvnw .
COPY .mvn .mvn
COPY pom.xml .
COPY src src

# Running a Maven build inside the container
RUN ./mvnw install -DskipTests

# Extracting the layers from the built Jar file
ARG JAR_FILE=target/*.jar
COPY ${JAR_FILE} application.jar
RUN java -Djarmode=layertools -jar application.jar extract


# Selecting image to use for the runtime stage
FROM eclipse-temurin:11-jre
WORKDIR app

# Copying the built application files from the build stage
COPY --from=builder /app/dependencies/ ./
COPY --from=builder /app/spring-boot-loader/ ./
COPY --from=builder /app/snapshot-dependencies/ ./
COPY --from=builder /app/application/ ./

# Triggering the Spring Boot launcher at container run
ENTRYPOINT ["java", "org.springframework.boot.loader.JarLauncher"]

