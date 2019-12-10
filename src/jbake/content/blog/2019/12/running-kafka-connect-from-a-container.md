title=Running a Kafka Connector Inside a Container
date=2019-12-22
type=post
tags=kafka,docker,kafka connect,java
status=published
~~~~~~
Everywhere you look these days in the software development world, you'll find containers in use in a variety of situations and by a vast number of developers and companies. `TODO - talk more about containers`

What I'm setting out to do with this post is walk through how to deploy the Kafka-Kinesis Connector in a container, using docker or postman for starters and then moving on to how we might be able to deploy it in a production environment, using Kubernetes. I am by no means an expert in any container technology, but I can mostly get around using containers in docker. So, this is a learning experience on multiple fronts for me.

For starters, we need a Kafka container! There are several to choose from, including [wurstmeister/kafka-docker](https://github.com/wurstmeister/kafka-docker), [Bitnami](https://hub.docker.com/r/bitnami/kafka/), and [Confluent](https://docs.confluent.io/current/quickstart/ce-docker-quickstart.html). I'm not very familiar with the Confluent Platform and the Control Center, but the steps to get a connector going are right there!

I'll start by seeing how far I can get with the Confluent version and move on to the others if I can find the time.