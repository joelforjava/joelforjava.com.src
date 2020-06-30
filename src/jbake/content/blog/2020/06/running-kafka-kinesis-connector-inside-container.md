title=Running the Kinesis Kafka Connector Inside a Container
date=2020-06-30
type=post
tags=kafka,docker,kafka connect,java
status=published
~~~~~~

In my previous [article](/blog/2020/06/running-kafka-connect-from-a-container.html), we walked through running a distributed Kafka Connect setup via Docker. In this article, I will be turning my attention to the Kinesis Kafka Connector and going through the steps to get it working in distributed mode and connecting to external services, e.g. an external Kafka cluster and The Kinesis Firehose service.

The overall intention of this is to go through how to connect a containerized application to external, non-containerized applications. We could just as easily replace the Kinesis Kafka Connector with something like the Elasticsearch Connector.

<!--more-->

### Creating the Dockerfile ###

We start with creating the Dockerfile that will be used to build the container in which we will run the Connector. While I plan on incorporating this build into the project, I started with the below:

<?prettify?>

    FROM wurstmeister/kafka:2.12-2.3.0

    ARG CLUSTER_NAME=cluster_1

    ARG ACCESS_KEY_ID
    ARG SECRET_ACCESS_KEY

    ENV AWS_ACCESS_KEY_ID=${ACCESS_KEY_ID}
    ENV AWS_SECRET_ACCESS_KEY=${SECRET_ACCESS_KEY}

    COPY config/${CLUSTER_NAME}/worker.properties /opt/kafka/config/

    COPY config/${CLUSTER_NAME}/kinesis-firehose-kafka-connector.* /opt/kafka/config/

    COPY config/${CLUSTER_NAME}/streamMapping.yaml /opt/kafka/config/

    COPY target/amazon-kinesis-kafka-connector-*.jar /opt/kafka/plugins/

    COPY start-kafka.sh /usr/bin/

    RUN chmod a+x /usr/bin/start-kafka.sh

This looks similar to the Dockerfile used in the last post, except now we're adding an argument so that we can build an image for a specific cluster, with the default being `cluster_1`. We're also adding environment variables for AWS, which will be required when sending data to Kinesis. There are several other ways to handle this, but this is the solution we will be going with for now. You definitely should NOT do this if you're going to check your image into a public repository.

From here, we can either do everything with docker via the command line, or we can wire up everything via Docker Compose.

### Overthinking Networking ###

Confession: I'm not the greatest with networking. It's not something I've had to work with a lot in the past, beyond making sure an application can reach another application, e.g. Bing, Google, or other external services via a URI. In other words, the networks have always been set up for me. With this, I wasted way too much time working on the networking, assuming a solution had to be complex, when the quickest solution was far simpler.

I went through a whole exercise of starting with a `host` network and then trying to do all this complicated work with creating different networks in an effort to have it the container talk to AWS and my local Kafka cluster.

So, rather than go through that rabbit hole of misery, I'll just post the final solution that works on my network and it should work on other basic LANs. I'm sure there would be more involved if we were doing this in a production or cloud environment where we would want to limit access to the outside world. Maybe I'll come back to that scenario if I can manage to find the time.

### Running via Docker CLI ###

We start with the standard `docker` commands:

<?prettify?>

    docker build -t kinesis_kafka_container_connect-distributed:latest --build-arg CLUSTER_NAME=cluster_1 --build-arg ACCESS_KEY_ID=fffffff --build-arg SECRET_ACCESS_KEY=ffffff .

    docker run -p '28083:8083' --add-host="kafka.joelforjava.local:192.168.55.57" --add-host="localstack.joelforjava.local:192.168.55.57" kinesis_kafka_container_connect-distributed:latest

The key part for me, was using the `--add-host` option. This will add a new entry into `/etc/hosts`. These two URLs, `kafka.joelforjava.local` and `localstack.joelforjava.local` are used in property files for the Kinesis Kafka Connector. 

*Side Note*: I've temporarily updated my version of the Connector to use [LocalStack](https://localstack.cloud) rather than actually connecting to AWS itself. For many reasons, I don't currently have a personal AWS account and I also can't easily do these kinds of things at my day job, so I had to find a way to test the connector out on my personal systems.

### Running via Docker Compose ###

Choosing the Compose route, I went with the following:

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
        network_mode: bridge
        extra_hosts:
          - "kafka.joelforjava.local:192.168.55.57"
          - "localstack.joelforjava.local:192.168.55.57"

In the Compose file, you use the `extra_hosts` configuration for adding additional hosts to `/etc/hosts`.

And, now I can dynamically scale up the connector, when needed by running `docker-compose up --scale connect-distributed=3`.

When deploying this in production, you may have to use a different network setup, but this should be a good starting point.

### Next Steps ###

For the next step in a future article, I hope to incorporate building docker images for various clusters into my regular build and deployment activities and I'm also hoping to dive into deploying this via Kubernetes. 

