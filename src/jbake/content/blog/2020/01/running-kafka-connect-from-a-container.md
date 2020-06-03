title=Running a Kafka Connector Inside a Container (Docker)
date=2020-06-08
type=post
tags=kafka,docker,kafka connect,java
status=published
~~~~~~
Everywhere you look these days in the software development world, you'll find containers in use in a variety of situations and by a vast number of developers and companies. `TODO - talk more about containers`

I'm planning on writing a series of articles that go through various stages of deploying Kafka Connect in a containerized environment. For this article, I plan on getting to the point of deploying a multi-node distributed connector using docker. I will use one source connector in standalone mode that will be used to populate a Kafka topic with data and I will deploy a sink connector in distributed mode to pull the data back out.

Later articles will explore deploying other sink connectors in distributed mode, including the Kafka-Kinesis Connector, via containers. For this article, I will be using docker and postman and will attempt deployment via Kubernetes in a future article. I am by no means an expert in any container technology, but I can mostly get around using containers in docker. So, this is a learning experience on multiple fronts for me.

### Picking a Kafka Container ###

For starters, we need a Kafka container! There are several to choose from, including [wurstmeister/kafka-docker](https://github.com/wurstmeister/kafka-docker), [Bitnami](https://hub.docker.com/r/bitnami/kafka/), and [Confluent](https://docs.confluent.io/current/quickstart/ce-docker-quickstart.html). I considered giving the Confluent version a try, but I'm not very familiar with the Confluent Platform and the Control Center, so I wasn't sure if there were any 'gotchas' when using it versus something like wurstmeister. Maybe if time permits at some point in the future, I can come back and give Confluent a better look so that I can get a better idea of what it offers on top of standard Apache Kafka. I decided to go with wurstmeister for this article. 

While researching this, I found an excellent [dev.to article](https://dev.to/thegroo/kafka-connect-crash-course-1chd) that goes over how to deploy a connector in standalone mode. I used this as my starting point with the expectation that I would eventually end up with a container setup that would be usable to connect to virtually any Kafka broker and send data into Kinesis Firehose (for the Kafka-Kinesis Connector).


### Step 1: Getting data into Kafka ###

I went ahead and cloned the repo from the dev.to article:

    git clone git@github.com:stockgeeks/docker-compose.git

I more or less ran the Docker Compose file as discussed in that article, by running `docker-compose up`. I then placed a file in the connect-input-file directory (in my case a codenarc Groovy config file). Running a console consumer showed the file being output back out.

    $ docker exec -it kafka /opt/kafka/bin/kafka-console-consumer.sh --bootstrap-server kafka:9092 --topic simple-connect --from-beginning

As I worked through the examples on this page, I decided to go back and create a [separate project](https://github.com/joelforjava/kafka-connect-container-examples) that used the stockgeeks repo as the starting point. I will add to this repo as I try out different things and container technologies.

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

Once you've connected the distributed container to the network, you can start up the connect-distributed service by running the usual `docker-connect up` command. You should then be able to query the REST API by running `curl http://localhost:18083/connectors` to get a list of currently running connectors, which should be an empty list.

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

### Step 3: Running multiple connect-distributed instances ###

For this step, I did a little cleanup with the docker-compose files and all of the various plugin config files. Granted, when I go to finally try this with the Kafka-Kinesis Connector, or with any setup that requires connecting to external services, I'll probably have to stick with a setup closer to that which was used in Step 2. However, I wanted to at least try to clean things up a little and put everything into a single `docker-compose.yml` file. This can be seen in the `step/3` branch.

I moved the 'standalone' config files into a new directory and renamed the directory used for the 'distributed' configuration files. Beyond dealing with the moving around of the files, nothing else really changed. Also, prior to running this new setup, I had to remove the old containers due to naming conflicts. You could rename the containers used in the new file instead, but I decided to keep the names the same.

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

In order to create multiple instances of a service, you can't give a container name, so that part is commented out. You also can't do an explicit port mapping, e.g. 18083 on the host to 8083 on the container.



`TODO list rest`

However, I'd like to try and go the next step and deploy a connector in distributed mode, since this is how we tend to use it in production at my day job. This would, hopefully, allow us to scale up or down, when needed.