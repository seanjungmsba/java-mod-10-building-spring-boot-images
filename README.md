# Building Spring Boot Images

## Learning Goals

- Understanding Spring Boot native Maven container build process
- Understanding simple case Dockerfile construction
- Experiencing iterative development process with container construction

## Instructions

Throughout the previous labs, we've been using pre-built Docker images to setup all our environments. While Docker definitely
has been helping us in those cases, so far we have yet to create an image from scratch ourselves. Not only is this necessary
to do when creating images around custom applications, it is also necessary when needing to modify current
applications that may already have their own images provided.
As you may be able to recall from the previous labs, there were frequently environmental variables being passed along with the
container run to get the desired behavior. This may not be available at
all times to do, so customizing application images is frequently needed.

We will start approaching this task by using the built-in image build process available with Maven.
After working through that process, we'll dive into using Dockerfile to achieve the same end.

## Spring Boot Native Maven Image Build

Open up a terminal window in our previous single node Cassandra Spring Boot project and run the following:

``` shell
./mvnw spring-boot:build-image
...

[INFO] Successfully built image 'docker.io/library/rest-service-complete:0.0.1-SNAPSHOT'
[INFO] 
[INFO] ------------------------------------------------------------------------
[INFO] BUILD SUCCESS
[INFO] ------------------------------------------------------------------------
[INFO] Total time:  53.191 s
[INFO] Finished at: 2022-07-24T17:12:24-05:00
[INFO] ------------------------------------------------------------------------
```

> It's worth noting that the `spring-boot:build-image` phase does run through the testing phase by default. The `-DskipTests` flag
> can be used to disable this if needed.

This same process can be done directly in IntelliJ by enabling this plugin in the Maven pane to execute after build.


You can now take a look at the local Docker images on your workstation, and see that these are now ready for your use

``` shell
docker images
REPOSITORY                  TAG                    IMAGE ID       CREATED         SIZE
...
rest-service-complete       0.0.1-SNAPSHOT         ceae6ec762be   42 years ago    245MB
paketobuildpacks/builder    base                   303a611351e3   42 years ago    1.18GB
```

But, if you try to use them as is, they will fail due to Database connectivity errors. We haven't been considering the case of Dockerized
applications up until this point, and our workflow of using services on localhost(127.0.0.1) for development work will no longer work once
migrated to Docker.

Let's hardcode some new values for now in order to get this up and running quickly.

``` shell
docker inspect --format '{{ .Name }} {{ .NetworkSettings.Networks.bridge.IPAddress }}' cassandra-lab
/cassandra-lab 172.17.0.2
```

Update `application.properties`

``` text
spring.data.cassandra.contact-points=172.17.0.2:9042
```

Rebuild the application and image, and we can now see it running correctly from inside a container

``` shell
docker run --rm --name spring-boot-lab -d -p 8080:8080 rest-service-complete:0.0.1-SNAPSHOT

curl "http://localhost:8080/greeting"
{"id":1,"content":"Hello, World!"}%

curl "http://localhost:8080/persistent_greeting"
{"id":9,"content":"Hello, World!"}% 
```

Hardcoding environment values is a fairly bad practice though, so let us parameterize these to enable very easy reuse in any environment.
In the case of Spring Boot, this is an absolutely trivial process as Spring Boot supports overriding arbitrary properties with Environmental
Variables.
E.g. we can override spring.data.cassandra.contact-points by passing into the container the environmental variable
`SPRING_DATA_CASSANDRA_CONTACT_POINTS.` We can also expand variables in the properties files using the syntax `${ENV_VAR}` if anything more complex is needed.

Let's test this out by reverting the connection string to localhost(127.0.0.1) again, and then running a container with the correct environmental variables
specified.

``` shell
# update connection to localhost and rebuild
docker run --rm --name spring-boot-lab -p 8080:8080 rest-service-complete:0.0.1-SNAPSHOT
# see container crash with connection errors

docker run --rm --name spring-boot-lab -p 8080:8080 -e SPRING_DATA_CASSANDRA_CONTACT_POINTS="172.17.0.2:9042" rest-service-complete:0.0.1-SNAPSHOT
# see container persisting, and serving traffic correctly
curl "http://localhost:8080/persistent_greeting"
{"id":10,"content":"Hello, World!"}%
```

At this point, it is now easily possible to launch as many instances of the application as we want, all connecting to the same backend Database system.

``` shell
docker run --rm --name spring-boot-lab-2 -d -p 8081:8080 -e SPRING_DATA_CASSANDRA_CONTACT_POINTS="172.17.0.2:9042" rest-service-complete:0.0.1-SNAPSHOT
docker run --rm --name spring-boot-lab-3 -d -p 8082:8080 -e SPRING_DATA_CASSANDRA_CONTACT_POINTS="172.17.0.2:9042" rest-service-complete:0.0.1-SNAPSHOT
docker run --rm --name spring-boot-lab-4 -d -p 8083:8080 -e SPRING_DATA_CASSANDRA_CONTACT_POINTS="172.17.0.2:9042" rest-service-complete:0.0.1-SNAPSHOT
docker run --rm --name spring-boot-lab-5 -d -p 8084:8080 -e SPRING_DATA_CASSANDRA_CONTACT_POINTS="172.17.0.2:9042" rest-service-complete:0.0.1-SNAPSHOT
docker ps
CONTAINER ID   IMAGE                                  COMMAND                  CREATED          STATUS          PORTS                                                                          NAMES
8591e3c8662d   rest-service-complete:0.0.1-SNAPSHOT   "/cnb/process/web"       3 seconds ago    Up 2 seconds    0.0.0.0:8084->8080/tcp, :::8084->8080/tcp                                      spring-boot-lab-5
a765a276e7ed   rest-service-complete:0.0.1-SNAPSHOT   "/cnb/process/web"       13 seconds ago   Up 13 seconds   0.0.0.0:8083->8080/tcp, :::8083->8080/tcp                                      spring-boot-lab-4
742629b00477   rest-service-complete:0.0.1-SNAPSHOT   "/cnb/process/web"       22 seconds ago   Up 21 seconds   0.0.0.0:8082->8080/tcp, :::8082->8080/tcp                                      spring-boot-lab-3
f8fb16fdc9c6   rest-service-complete:0.0.1-SNAPSHOT   "/cnb/process/web"       29 seconds ago   Up 29 seconds   0.0.0.0:8081->8080/tcp, :::8081->8080/tcp                                      spring-boot-lab-2
33b63f4e4c5d   rest-service-complete:0.0.1-SNAPSHOT   "/cnb/process/web"       37 minutes ago   Up 37 minutes   0.0.0.0:8080->8080/tcp, :::8080->8080/tcp                                      spring-boot-lab
a03e783ff4fe   cassandra:4.0.4                        "docker-entrypoint.s…"   2 days ago       Up 7 hours      7000-7001/tcp, 7199/tcp, 9160/tcp, 0.0.0.0:9042->9042/tcp, :::9042->9042/tcp   cassandra-lab
curl "http://localhost:8080/greeting"
{"id":1,"content":"Hello, World!"}%

curl "http://localhost:8081/greeting"
{"id":1,"content":"Hello, World!"}%

curl "http://localhost:8082/greeting"
{"id":1,"content":"Hello, World!"}%

curl "http://localhost:8083/greeting"
{"id":1,"content":"Hello, World!"}%

curl "http://localhost:8084/greeting"
{"id":1,"content":"Hello, World!"}%

curl "http://localhost:8080/persistent_greeting"
{"id":11,"content":"Hello, World!"}%

curl "http://localhost:8081/persistent_greeting"
{"id":12,"content":"Hello, World!"}%

curl "http://localhost:8082/persistent_greeting"
{"id":13,"content":"Hello, World!"}%

curl "http://localhost:8083/persistent_greeting"
{"id":14,"content":"Hello, World!"}%

curl "http://localhost:8084/persistent_greeting"
{"id":15,"content":"Hello, World!"}%
```

## Simple Case Dockerfile

> Dockerfile can be considered its own configuration management language, and can get quite complex. So for the sake of this lab, we will be approaching
> this using a pre-written Dockerfile that follows best practices for Spring Boot images.

While what we have accomplished with generating images directly in Maven is the most simple way to get started, the functionality provided there is
only going to cover a specific predefined subset of what Dockfiles are capable of building. If you utilize the full extent of a Dockerfile,
you can essentially build an entire self-contained OS image configured specifically for your needs, whatever they may be. It does require
a much larger Sysadmin knowledge base though to make the full use of this. Some basic Linux knowledge and Googling abilities should get you
to resolving most common problems though.

Take a look at the included Dockerfile, and try to understand what all the steps are accomplishing. The Docker primer lesson should have covered all
these items from the Dockerfile command side. And, there is a good overview on the best-practices approach of [layered Spring Boot containers](https://spring.io/guides/topicals/spring-boot-docker/#a-better-dockerfile)
being used here.


Once you've reviewed those, copy the Dockerfile into the project directory, to the same level as the `pom.xml` file.
Then, run the following command from a terminal at that location:

``` shell
docker build -t spring-boot-lab-build .
Sending build context to Docker daemon  33.43MB
Step 1/19 : FROM eclipse-temurin:11-jdk as builder
...
Successfully built 4e75576a93d4
Successfully tagged spring-boot-lab-build:latest
```

If everything builds successfully, you should now see this image available for use on your workstation

``` shell
docker images
REPOSITORY                  TAG                    IMAGE ID       CREATED              SIZE
spring-boot-lab-build       latest                 4e75576a93d4   45 seconds ago       273MB
...

```

You can launch an instance using this image, and see that it runs identically to what was built via the Maven plugin

``` shell
docker run --rm --name spring-boot-lab-6 -d -p 8085:8080 -e SPRING_DATA_CASSANDRA_CONTACT_POINTS="172.17.0.2:9042" spring-boot-lab-build

curl "http://localhost:8085/greeting"
{"id":1,"content":"Hello, World!"}%

curl "http://localhost:8085/persistent_greeting"
{"id":16,"content":"Hello, World!"}%
```

## Advanced Lab

Take a look at all the containers we have used so far in this class. Their docker images are available from [hub.docker.com](https://hub.docker.com),
and you should be able to look up the associated Github repositories to browse to the Dockerfiles. Look through these Dockerfiles, and see just how
complex these environments can get. The Bitnami containers have a complex nest of shell scripts that may be worth looking through.
Always try to keep your own Dockerfiles/images as simple as possible when you can, but sometimes there is no getting around this complexity.
