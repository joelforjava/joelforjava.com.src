title=Running a Kafka Connector Inside a Container (Docker)
date=2020-06-08
type=post
tags=kafka,docker,kafka connect,java
status=published
~~~~~~
Everywhere you look these days in the software development world, you'll find containers in use in a variety of situations and by a vast number of developers and companies. [This article](https://www.docker.com/resources/what-container) from Docker does a good job of explaining containers. However, containers go far beyond Docker, including [Kubernetes](https://kubernetes.io), [Podman](https://podman.io/), [Apache Mesos](http://mesos.apache.org), and [Red Hat OpenShift Container Platform](https://docs.openshift.com/container-platform/4.4/welcome/index.html) among others.

I'm planning on writing a series of articles that go through various stages of deploying Kafka Connect in a containerized environment. For this article, I plan on getting to the point of deploying a multi-node distributed connector using docker. I will use one source connector in standalone mode that will be used to populate a Kafka topic with data and I will deploy a sink connector in distributed mode to pull the data back out.

Later articles will explore deploying other sink connectors in distributed mode, including the Kafka-Kinesis Connector, via containers. For this article, I will be using [Docker](https://www.docker.com) via [Docker Compose](https://docs.docker.com/compose/). I am hoping to look more into Podman and attempt deployment via Kubernetes in future articles. I am by no means an expert in any container technology, but I can mostly get around using containers in Docker. So, this is a learning experience on multiple fronts for me.

<!--more-->

### Picking a Kafka Container ###

For starters, we need a Kafka container! There are several to choose from, including [wurstmeister/kafka-docker](https://github.com/wurstmeister/kafka-docker), [Bitnami](https://hub.docker.com/r/bitnami/kafka/), and [Confluent](https://docs.confluent.io/current/quickstart/ce-docker-quickstart.html). I considered giving the Confluent version a try, but I'm not very familiar with the Confluent Platform and the Control Center, so I wasn't sure if there were any 'gotchas' when using it versus something like wurstmeister. Maybe I'll find the time to come back and give Confluent a better look in future articles. I decided to go with wurstmeister for this article. 

While researching this, I found an excellent [dev.to article](https://dev.to/thegroo/kafka-connect-crash-course-1chd) that goes over how to deploy a connector in standalone mode. I used this as my starting point with the hopes that I would eventually end up with a container setup that would be usable to connect to virtually any Kafka broker and send data into Kinesis Firehose (for the Kafka-Kinesis Connector).


### Step 1: Getting data into Kafka ###

I started out by cloning the repo from the previously referenced dev.to article:

    git clone git@github.com:stockgeeks/docker-compose.git

I more or less ran the Docker Compose file as discussed in that article, by running `docker-compose up`. I then placed a file in the connect-input-file directory (in my case a codenarc Groovy config file). Running a console consumer showed the file being output back out.

    $ docker exec -it kafka /opt/kafka/bin/kafka-console-consumer.sh --bootstrap-server kafka:9092 --topic simple-connect --from-beginning

As I worked through the examples on this page, I decided to go back and create a [separate project](https://github.com/joelforjava/kafka-connect-container-examples) that used the stockgeeks repo as the starting point. I will add to this repo as I try out different things and container technologies. You can checkout this repo by running `git clone git@github.com:joelforjava/kafka-connect-container-examples.git`. From this point forward, this is the project I will be using.

### Step 2: Getting data back out of Kafka ###

Next, I wanted to run Kafka Connect in distributed mode, pulling that same data back out using the `FileStreamSinkConnector` sink connector. Rather than build on the existing docker setup, I decided to create a new `Dockerfile`, `docker-compose.yml`, and new configuration files for the sink connector inside of a new directory (`distributed-connector`) in an attempt to keep everything somewhat organized.

This setup is shown in my `kafka-connect-container-examples` repo under the branch `step/2`.

<?prettify?>

	version: '3.3'

	services:

	  connect-distributed:
	    build:
	      context: .
	      dockerfile: Dockerfile
	    container_name: connect-distributed
	    ports:
	      - 18083:8083
	    volumes:
	      - ./connect-input-file:/tmp


In order for this container to interact with the already running Kafka broker, I will need to add this container to the existing network on which the kafka broker container is running. To do this, you will need to run `docker network ls` to get a list of networks used by your various containers.

Your output will differ based on what containers you run and the networks you've previously created. Here's what my list looked like at the time:

	NETWORK ID          NAME                                 DRIVER              SCOPE
	938a3db19507        bridge                               bridge              local
	cff74b7d60e4        build-system_sonarnet                bridge              local
	b93a229f4eb2        host                                 host                local
	da76ab07af40        kafka-connect-crash-course_default   bridge              local

In this case, `kafka-connect-crash-course_default` is the network created by the original (project root) `docker-compose.yml` file.

Next, I had to bring up the `connect-distributed` service container, but not actually start it. Alternatively, I could've listed the network declaration in the Docker Compose file.

    docker-compose up --no-start

Once the container is created, I can then run the following:

    docker network connect kafka-connect-crash-course_default connect-distributed

Once you've connected the container with the sink connector (`connect-distributed`) to the network, you can start up the service by running the `docker-connect up` command. You should then be able to query the REST API by running `curl http://localhost:18083/connectors` to get a list of currently running connectors, which should be an empty list.

Next, I created a JSON file, which pulled properties from the `connect-file-sink.properties` file and used this to configure the connector instance:

	curl -XPUT -H "Content-Type: application/json"  --data "@distributed-connector/connect-file-sink.json" http://localhost:18083/connectors/file-sink-connector/config | jq

If all goes well with the configuration, you should see an output similar to the following:

<?prettify?>

	{
	  "name": "file-sink-connector",
	  "config": {
	    "name": "file-sink-connector",
	    "connector.class": "org.apache.kafka.connect.file.FileStreamSinkConnector",
	    "tasks.max": "1",
	    "topics": "simple-connect",
	    "file": "/tmp/my-output-file.txt",
	    "key.converter": "org.apache.kafka.connect.storage.StringConverter",
	    "value.converter": "org.apache.kafka.connect.storage.StringConverter"
	  },
	  "tasks": [
	    {
	      "connector": "file-sink-connector",
	      "task": 0
	    }
	  ],
	  "type": "sink"
	}

At this point, as long as data was already in the `simple-connect` topic, then you should see output in `distributed-connector/connect-output-file/my-output-file.txt`.

### Step 3: Scaling up connect-distributed instances ###

For this step, I did a little cleanup with the Docker Compose files and all of the various plugin config files. This can be seen in the `step/3` branch. Before going any further, I had to run `docker-compose down` to ensure the containers from the previous step are removed. Failure to do this will cause conflicts when you go to start up the instances listed in this step. Alternatively, you could rename the containers in this step, but I chose to keep the existing names.

I moved the 'standalone' config files into a new directory and renamed the directory used for the 'distributed' configuration files. I increased the `tasks.max` value to `3` in an effort to see the tasks distributed across the scaled-up instances. 

Now, we can finally take a look at the change required for the `connect-distributed` service.

<?prettify?>

    connect-distributed:
      build:
        context: ./distributed
        dockerfile: Dockerfile
      # container_name: connect-distributed
      ports:
        - 8083
      depends_on:
        - kafka
      deploy:
        replicas: 4
      volumes:
        - ./distributed/connect-output-file:/tmp

In order to scale out a docker compose service, you can't provide a hard-coded `container_name` value, so that part is commented out and should ultimately be removed. You also can't do an explicit port mapping, e.g. `18083:8083`, but you can use a port range, such as `"18083-18093:8083"`. In the example above, I let Docker assign the ports. 

The example also lists 4 `replicas`, but this setting is only valid in Swarm mode and is otherwise ignored. In version 2 of the docker compose files, there was a `scale` parameter that could be used but it does not have a true equivalent in version 3 unless you count the Swarm setting.

For this step, I want to try running 3 instances of the connect-distributed service, so I enter the following command:

    docker-compose up --scale connect-distributed=3

Soon, you should see logging outputs for the various services, including the 3 instances of the connect-distributed service.

Whether or not you mapped a port range for the connect-distributed service, you should then check the containers to see what host ports were assigned to the instances.

    docker ps 

You should see output similar to below:

    CONTAINER ID        IMAGE                                COMMAND                  CREATED             STATUS              PORTS                                                NAMES
    cd7c061d9ef2        docker-compose_connect-distributed   "start-kafka.sh"         35 seconds ago      Up 34 seconds       0.0.0.0:32776->8083/tcp                              docker-compose_connect-distributed_3
    c4eb751169be        docker-compose_connect-distributed   "start-kafka.sh"         35 seconds ago      Up 34 seconds       0.0.0.0:32775->8083/tcp                              docker-compose_connect-distributed_1
    aa62908512ff        docker-compose_connect-standalone    "start-kafka.sh"         35 seconds ago      Up 34 seconds       0.0.0.0:8083->8083/tcp                               connect-standalone
    7722da0e7e48        docker-compose_connect-distributed   "start-kafka.sh"         35 seconds ago      Up 34 seconds       0.0.0.0:32774->8083/tcp                              docker-compose_connect-distributed_2

I've truncated the output to only show the connect containers. In this case, Docker assigned ports `32774` through `32776` to the scaled out connect-distributed services.

Now you should be able to perform the steps as done in Step 2 for querying the Connect REST API and for pushing a configuration by making use of one of the mapped ports.

Once the configuration is pushed, the `file-sink-connector` connector does its job and pulls the data from Kafka, saving the data to the `distributed/connect-output-file` directory. In addition, you can query Kafka using the Consumer Groups shell script to verify.

    docker exec -it kafka /opt/kafka/bin/kafka-consumer-groups.sh --bootstrap-server kafka:9092 --describe --all-groups

For the new version of the simple-connect topic, we created 3 partitions and then set `tasks.max` in the sink connector to 3, which resulted in one task per container and the summary below:

        GROUP                       TOPIC           PARTITION  CURRENT-OFFSET  LOG-END-OFFSET  LAG             CONSUMER-ID                                                                   HOST            CLIENT-ID
    connect-file-sink-connector simple-connect  1          4667            4667            0               connector-consumer-file-sink-connector-1-f009d64b-b2ad-42e9-be14-a77b9acfc6c0 /172.23.0.6     connector-consumer-file-sink-connector-1
    connect-file-sink-connector simple-connect  0          4666            4666            0               connector-consumer-file-sink-connector-0-e413eb56-30ec-4a3b-89fc-bf4b2aea01a9 /172.23.0.5     connector-consumer-file-sink-connector-0
    connect-file-sink-connector simple-connect  2          4667            4667            0               connector-consumer-file-sink-connector-2-c34e154b-8efb-4b41-aea0-a133a5f8556c /172.23.0.7     connector-consumer-file-sink-connector-2


This concludes, for now, my experiment to run a sink connector in distributed mode all via Docker. This should come in handy in helping to migrate some of our Kafka Connectors from Virtual Machines to containers. My next steps will most likely be either trying this with Kubernetes or trying to get another plugin working, such as the Kafka-Kinesis Connector or the Elasticsearch connector. I'm sure it'll be all of the above at some point. Thank you, if you've read this far. I hope this has been useful to someone.
