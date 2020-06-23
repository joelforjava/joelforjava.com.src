title=Running the Kafka Kinesis Connector Inside a Container
date=2020-06-30
type=post
tags=kafka,docker,kafka connect,java
status=draft
~~~~~~

In my previous [article](/blog/2020/06/running-kafka-connect-from-a-container.html), we walked through running a distributed Kafka Connect setup via Docker. In this article, I will be turning my attention to the Kinesis Kafka Connector and going through the steps to get it working in distributed mode and connecting to external services, e.g. an external Kafka cluster and The Kinesis Firehose service.

The overall intention of this is to go through how to connect a containerized application to external, non-containerized applications. We could just as easily replace the Kinesis Kafka Connector with something like the Elasticsearch Connector.

<!--more-->

### Creating the Dockerfile ###

We start with creating the Dockerfile that will be used to build the container in which we will run the Connector. While I plan on incorporating this build into the project, I started with the below:

<?prettify?>

    FROM wurstmeister/kafka:2.12-2.3.0

    ARG CLUSTER_NAME=cluster_1

    ENV AWS_ACCESS_KEY_ID=fffffffff
    ENV AWS_SECRET_ACCESS_KEY=ffffffff

    COPY config/${CLUSTER_NAME}/worker.properties /opt/kafka/config/

    COPY config/${CLUSTER_NAME}/kinesis-firehose-kafka-connector.* /opt/kafka/config/

    COPY config/${CLUSTER_NAME}/streamMapping.yaml /opt/kafka/config/

    COPY target/amazon-kinesis-kafka-connector-*.jar /opt/kafka/plugins/

    COPY start-kafka.sh /usr/bin/

    RUN chmod a+x /usr/bin/start-kafka.sh

This looks similar to the Dockerfile used in the last post, except now we're adding an argument so that we can build an image for a specific cluster, with the default being `cluster_1`. We're also adding environment variables for AWS, which will be required when sending data to Kinesis. There are several other ways to handle this, but this is the solution we will be going with for now.

From here, we can either do everything with docker via the command line, or we can wire up everything via Docker Compose.

Confession: I'm not the greatest with networking. It's not something I've had to work with a lot in the past, beyond making sure an application can reach another application, e.g. Bing, Google, or other external services. I wasted way too much time working on the networking, when the solution was rather simple.

I went through a whole exercise of starting with a `host` network and then trying to do all this complicated work with creating different networks in an effort to have it the container talk to AWS and my local Kafka cluster.

So, rather than go through all that, I'll just post the final solution that works on my network. I'm sure there would be more involved if we were doing this in a production environment where we would want to limit access to the outside world. Maybe I'll come back to that scenario if I ever go that far with my work.

So, we start with the standard `docker` command:

`TODO put command line stuff here`

Choosing the Compose route, we can use the following:

<?prettify?>

    version: '3.3'

    services:

      connect-distributed:
        build:
          context: .
          dockerfile: Dockerfile
        ports:
          - 8083
        depends_on:
          - kafka
        deploy:
          replicas: 4
        volumes:
          - ./tmp_out:/tmp
        networks:
          - connectnet

    networks:
      connectnet:
        driver: bridge

My second attempt:

<?prettify?>

    version: '3.3'

    services:

      connect-distributed:
        build:
          context: .
          dockerfile: Dockerfile
        ports:
          - 8083
        volumes:
          - ./tmp_out:/tmp
        network_mode: host  # This disables port forwarding

Using this version, I'm able to get it up and running. However, using `network_mode: host` on a Mac [essentially](https://github.com/docker/for-mac/issues/1031) disables port forwarding due to how Docker runs on the Mac. I can make this work, however, by logging into the container and running the relevant commands there. We also can't scale this version, I assume for similar reasons. This isn't acceptable for something more production-ready, but it's a good first try just to get it going.

So, back to the drawing board. I have a feeling it won't be possible to run Docker on a Mac, so I'll try running on Linux and see how it goes.

