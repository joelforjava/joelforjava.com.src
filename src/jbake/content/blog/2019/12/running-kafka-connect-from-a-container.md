title=Running a Kafka Connector Inside a Container (Docker)
date=2020-01-22
type=post
tags=kafka,docker,kafka connect,java
status=published
~~~~~~
Everywhere you look these days in the software development world, you'll find containers in use in a variety of situations and by a vast number of developers and companies. `TODO - talk more about containers`

What I'm setting out to do with this post is walk through how to deploy the Kafka-Kinesis Connector in a container, using docker or postman for starters and then moving on to how we might be able to deploy it in a production environment, using Kubernetes. I am by no means an expert in any container technology, but I can mostly get around using containers in docker. So, this is a learning experience on multiple fronts for me.

For starters, we need a Kafka container! There are several to choose from, including [wurstmeister/kafka-docker](https://github.com/wurstmeister/kafka-docker), [Bitnami](https://hub.docker.com/r/bitnami/kafka/), and [Confluent](https://docs.confluent.io/current/quickstart/ce-docker-quickstart.html). I considered giving the Confluent version a try, but I'm not very familiar with the Confluent Platform and the Control Center, so I wasn't sure if there were any 'gotchas' when using it versus something like wurstmeister. Maybe if time permits at some point in the future, I can come back and give Confluent a better look. I decided to go with wurstmeister for this article. 

While researching this, I found an excellent [dev.to article](https://dev.to/thegroo/kafka-connect-crash-course-1chd) that goes over how to deploy a connector in standalone mode. I used this as my starting point with the expectation that I would eventually end up with a container setup that would be usable to connect to virtually any Kafka broker and send data into Kinesis Firehose (for the Kafka-Kinesis Connector).

I went ahead and cloned the repo from the dev.to article:

    git clone git@github.com:stockgeeks/docker-compose.git

I more or less ran the Docker Compose file as discussed in that article, by running `docker-compose up`. I then placed a file in the connect-input-file directory (in my case a codenarc Groovy config file). Running a consumer showed the file being output back out.

Next, I wanted to run Kafka Connect in distributed mode, pulling that same data back out using the `FileSourceSinkConnector`. Rather than build on the existing docker setup, I decided to create a new docker compose file inside of a new directory in an attempt to make the differences more apparent to myself.

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


In order for this container to interact with the already running Kafka broker, I had to add this container to the existing network by running the following:

    docker network connect kafka-connect-crash-course_default connect-distributed

where kafka-connect-crash-course_default is the network created by the original `docker-compose` file. You can get the network name by running:

    $ docker network ls

	NETWORK ID          NAME                                 DRIVER              SCOPE
	938a3db19507        bridge                               bridge              local
	cff74b7d60e4        build-system_sonarnet                bridge              local
	b93a229f4eb2        host                                 host                local
	da76ab07af40        kafka-connect-crash-course_default   bridge              local

Once you've completed this step, you can bring up the newly created docker-compose file for the connect-distributed service by running the usual `docker-connect up` command. You should then be able to query the REST API by running `curl http://localhost:18083/connectors` to get a list of currently running connectors, which should be an empty list.

Next, I created a JSON file, which pulled properties from the `connect-file-sink.properties` file and used this to configure the connector instance:

	curl -XPUT -H "Content-Type: application/json"  --data "@kafka-connect-distributed/config.json" http://localhost:18083/connectors/file-sink-connector/config | jq

If all goes well with the configuration, you should see an output similar to the following:

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


`TODO list rest`

However, I'd like to try and go the next step and deploy a connector in distributed mode, since this is how we tend to use it in production at my day job. This would, hopefully, allow us to scale up or down, when needed.