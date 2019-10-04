title=My Kafka Connect Woes When Updating the Kafka Kinesis Plugin
date=2019-09-28
type=post
tags=kafka,kinesis,kafka connect,java
status=published
~~~~~~

We have several 3-node Kafka connect clusters that each process different topics. If you’ve read my [first article](/blog/2019/09/22/customizing-kafka-kinesis-connector.html) regarding my project's customized version of the AWS Labs Kafka-Kinesis Connector, you’ve already read about the corner we backed ourselves into with our first deployments of the modified code. We’ve been working, when possible, to fix those mistakes and to make updates to the clusters and their configurations easy. Well, at least easier than the abomination with which we started.

During one of the updates to the code, updates that added additional properties and an additional configuration file, we ran into an issue with one of the clusters. We were attempting a rolling update of the Kafka-Kinesis Connector plugin and while it went smoothly for the first two clusters, it was a huge pain to get this particular cluster to update appropriately.

<!--more-->

I had updated the config via the REST API with 2 new properties (`clusterName` and `mappingFile`) that were used by the new code. Calling `GET /<CONNECTOR_ID/config` on each of the servers would return the updated configuration. These properties were also a part of the properties file that was stored in the `config` directory. These properties both dealt with how we were using one running connect cluster to handle data from multiple topics going into separate, sometimes multiple, Kinesis data streams.

<?prettify?>

    {
        "name" : "cluster_1",
        "connector.class" : "com.amazon.kinesis.kafka.FirehoseSinkConnector",
        "tasks.max" : 25,
        "topics" : "IMPORTANT.TOPIC,FASCINATING.TOPIC,METRICBEAT.TOPIC,LOGSTASH.TOPIC,RABBITMQ.TOPIC",
        "region" : "us-west-1",
        "batch" : "true",
        "batchSize" : 500,
        "batchSizeInBytes" : 3670016,
        "deliveryStream" : "not_used",
        "clusterName": "DEV_CLUSTER_1",
        "mappingFile": "/opt/kafka/config/streamMappings.yaml"
    }

Earlier in the day, this same setup was successfully deployed to another Kafka Connect cluster, done as a rolling update. Each of these clusters connect to a different Kafka cluster, streaming data into separate Kinesis data streams. There were no issues deploying the update here. However, this particular cluster was running a version that was ‘between’ that which was [originally running](https://github.com/joelforjava/multi-destination-kinesis-kafka-connector/tree/v1) on the problematic cluster and the [new code](https://github.com/joelforjava/multi-destination-kinesis-kafka-connector/tree/v3) that is being deployed. Does that matter? I would hope not. But, it’s one of the few differences I can think of code-wise.

The new code explicitly checks for each of these 2 new properties and throws a `ConfigException` if it cannot load a valid value for either of them since the code will not work correctly without one of them being set. When I started the new deployment on one of the servers of this cluster, I shut down the service and updated the JAR and config files. When I started it back up, I would soon see the `ConfigException` thrown due to its not finding these properties. So, I reverted everything back and it was all back to normal. I decided to attempt the update on another server and then finally the 3rd server, seeing the same result each time I attempted to update the JAR and configuration files. However, due to how distributed mode works, it didn’t really matter that I was updating the configuration files. But, as I mentioned, the REST API showed the newly updated properties when calling GET on the `/config` endpoint.

<?prettify lang=java?>

    String mappingFileUrl = props.get(FirehoseSinkConnector.MAPPING_FILE);
    String clusterName = props.get(FirehoseSinkConnector.CLUSTER_NAME);
    if (mappingFileUrl != null) {
        log.info("Property for {} found. Attempting to load this configuration file.", FirehoseSinkConnector.MAPPING_FILE);
        Optional<ClusterMapping> optionalMapping = ConfigParser.parse(mappingFileUrl);
        if (optionalMapping.isPresent()) {
            ClusterMapping clusterMapping = optionalMapping.get();
            String cName = clusterMapping.getClusterName();
            log.info("Using cluster name: {}", cName);
            lookup = clusterMapping.getStreamsAsMap();
        } else {
            log.error("Parser could not correctly parse the mapping file at {}. Please verify the configuration.", mappingFileUrl);
            throw new ConfigException("Parser could not correctly parse the mapping file");
        }
    } else if (clusterName != null) {
        log.warn("Using cluster name: {}", clusterName);
        log.warn("Attempting to use hard-coded mappings. Please provide a YAML mapping file in the future");
        lookup = StreamMappings.lookup(clusterName);
    } else {
        throw new ConfigException("Connector cannot start without required property value for either 'mappingFile' or 'clusterName'.");
    }

The ‘between’ version that I mentioned earlier makes use of one of the two new properties (`clusterName`) that were being introduced to the problematic cluster. I decided to attempt to deploy [this version](https://github.com/joelforjava/multi-destination-kinesis-kafka-connector/tree/v2) to one node of the problematic cluster, just to see what would happen. Same result. It couldn’t find the new property that was introduced in that version of the plugin.

After wasting the majority of the day of two coworkers to go over everything I had already done, it was finally decided that we would shut everything down early the next day, upgrade one of the servers and start it up first. 

So, that’s what happened. And everything started fine with the updated node as the only node running. Updating the other servers and starting them one at a time proved to be no issue. The big question I have is: WHY?!? Why was this such a pain in the ass to update? Why wasn’t the complete configuration being fed into the new code?

I could see a case being made if the was Connect works with properties is that it ONLY uses the configuration located at `/<CONNECTOR_ID>/config` after first start and then if those new properties weren’t there. However, the properties WERE THERE! They were coming through in the REST API call no matter which node we made the call on. I have also since updated other properties on this same cluster and the changes were picked up instantly after calling the `/restart` endpoint. 

So, that's it. We shut down the cluster completely and did the update. Something I didn't want to do, but looking back on it, it was definitely quicker that the mess that ensued from trying to do a rolling update.