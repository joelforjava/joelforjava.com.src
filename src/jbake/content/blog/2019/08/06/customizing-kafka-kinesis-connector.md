title=Customizing the Kafka Kinesis Connector
date=2019-08-06
type=post
tags=kafka,kinesis,aws,kafka connect,java
status=draft
~~~~~~

Prior to the work that eventually led me to write this article, and the other Kafka-related ones that will follow, I had very little exposure to Kafka and its ecosystem. I knew, more-or-less, what Kafka was and could do the basics to get a broker started and then run producers and consumers from the command line. That was the extent of my working with Kafka until I inherited the maintaining and deployment of Kafka Connect clusters at work.

These clusters all forward data to AWS Kinesis Firehoses, which is then further processed either with Athena, Splunk, Elasticsearch for Kibana dashbboards, or another Big Data tool. The connector used by all of these clusters is a variation of the one <a href="https://github.com/awslabs/kinesis-kafka-connector" title="Kinesis Kafka Connector by AWSLabs on Github">here</a>.

I say variation due to the fact that we had to modify it in order for it to take in multiple topics and then deliver to the related Kinesis Data Firehose. For each Kafka topic, there is at least one Kinesis Data Firehose. Due to time constraints, this ended up being a very painful process, and the evolution of that code is what will be explored here, at least as far as it can be.

<!--more-->

I did not write the initial modifications of the code, but I did write the updates, for better or worse, that came after the initial panic of “we need this yesterday”.  While we could have possibly run many instances of these connectors each configured with one topic and one deliveryStream, we soon learned that each topic had to go to multiple Firehoses. We then also wanted to run one connector to take data from *multiple* topics and send the data to the correlated Firehose(s).

If we were simply running a connector per topic, we could’ve just updated the handling of the deliveryStream property to handle multiple values. Also, maybe things could’ve been handled differently on the Firehose side of things. I had zero input or insight into how or why certain things were decided for Firehose Streams, nor did I really know enough about it o help make those decisions. I think the solution we ultimately came up with works well for the work we need performed.

<figure>
<pre class="prettyprint">
`
topics=GOLD.TOPIC
deliveryStreamNames=GOLD-STREAM,ES-GOLD-STREAM        
`
</pre>
<figcaption>Figure 1-1: A possible solution if all topics were going to multiple streams or only one topic to multiple streams</figcaption>
</figure>

I have forked the kinesis-kaka-connector from GitHub so that I can demonstrate the stages in which we found ourselves. Note that due to constraints with my job, this code is not exactly the same as that which was written originally, but it still conveys the same point.

Our unfortunate first version that was deployed to production <a href="https://github.com/joelforjava/kinesis-kafka-connector/tree/v1">here</a> used hard-coded values that mapped the Kafka Topic to the relevant Kinesis Topics. Needless to say, this code was very brittle and we had to do a different build per cluster. Calling it a pain to initially deploy and then update is being nice, which I’m sure you can imagine.  The hope was that it would be a deploy-once application, but of course it wasn’t. Seldom is a deployment ever truly a one-time thing. At some point you’ll need to make changes, and so I needed to make changes to help make that easier to do.

<?prettify?>

    package com.amazon.kinesis.kafka;

    import java.util.*;

    public class StreamMappings {

        static final Map<String, List<String>> CLUSTER_1;
        static {
            CLUSTER_1 = new LinkedHashMap<>();
            CLUSTER_1.put("IMPORTANT.TOPIC", Arrays.asList("IMPORTANT-STREAM", "S3-IMPORTANT-STREAM"));
            CLUSTER_1.put("FASCINATING.TOPIC", Arrays.asList("FASCINATING-STREAM", "S3-FASCINATING-STREAM"));
            CLUSTER_1.put("METRICBEAT.TOPIC", Arrays.asList("METRICBEAT-STREAM", "S3-METRICBEAT-STREAM"));
            CLUSTER_1.put("LOGSTASH.TOPIC", Arrays.asList("LOGSTASH-STREAM", "S3-LOGSTASH-STREAM"));
            CLUSTER_1.put("RABBITMQ.TOPIC", Arrays.asList("RABBITMQ-STREAM", "S3-RABBITMQ-STREAM"));
        }

        // .. more ..
    }

So, when I ended up being put in charge of this code, I did what I could to improve it while adding new mappings required by the client. Unfortunately, I wasn’t given many hours to work on it, so I managed to get the second version up and going in 2 of the 3 current environments at the time. This time, we added a new property to the properties file that designated what cluster it was (CLUSTER1, CLUSTER2, etc.) and then used a look up method to load the mappings. It’s still hardcoded, but at least the same code can be deployed everywhere.

<?prettify?>

    static Map<String, List<String>> lookup(String clusterName) {
        switch (clusterName.toUpperCase()) {
            case "CLUSTER_1":
                return CLUSTER_1;
            case "CLUSTER_2":
                return CLUSTER_2;
            case "CLUSTER_3":
                return CLUSTER_3;
            default:
                return Collections.emptyMap();
        }
    }        

We still needed to make this code dynamically handle mappings, though. Initially I wanted to keep everything in one connector property file, and briefly considered creating a mapping, say destinationStreamMappings, in the properties file along the lines of [TOPIC1]:[STREAM1]:[STREAM2],[TOPIC2]:[STREAM2], etc. However, this was problematic and potentially messy and error prone. It ended up looking pretty ugly once you had over four or five topics and I found myself putting colons where commas should be and vice versa. If I was making this mistake, then surely anyone that had to maintain this code after me would have issues.

I also considered using properties similar to the following:

<?prettify?>

    stream.mapping.one.sourceTopic=SOURCE_TOPIC
    stream.mapping.one.destinationStreamName.1=DESTINATION_1
    stream.mapping.one.destinationStreamName.2=DESTINATION_2           

However, this seemed a bit verbose, especially in the case of one of the connectors pulling from at least 15 topics, most of them with multiple destinations. So, we looked into other options but ultimately chose a using a separate YAML file. This file would also allow for extensibility, which actually ends up relevant soon after the YAML update was completed. While I could’ve also just let SnakeYAML parse the YAML into a Map of Strings to Lists of Strings (which is how the lookup map was set up anyway), I opted for creating separate objects to hold this data, which would also help when it came to extensibility.

<?prettify?>

    class ClusterMapping {

        var clusterName: String? = ""
        var streams: List<DestinationStreamMapping>? = null
    
        val streamsAsMap: Map<String, List<String>?>
            get() = if (streams == null) {
                emptyMap()
            } else {
                streams!!.associateBy( {it.name!!}, {it.destinations} )
            }
    }

    class DestinationStreamMapping {
        var name: String? = null
        var destinations: List<String>? = null
    }

You might notice the property `streamsAsMap` on the `ClusterMapping` class. This was created in order to make sure the existing logic in `FirehoseSinkTask.putRecordsInBatch` remained the same. We just set the lookup map to the result of this property. I’m hoping to explore changing it at some point in the future.

However, when it came time to deploy the new version of the code that used YAML mappings, it was very problematic to get pushed to one of the clusters, which will be discussed in a separate post. The other servers updated smoothly, which is what made this one server issue puzzling. Now, if you need to add a mapping, all you need to do is update the YAML and restart the connector. Once restarted, push the new topic(s) to the REST API and the connector should start processing the new mappings. This ended up being magnitudes better than the old setup.

This set up has a fairly major issue, though. The mapping file will have to be present on every node in the Connect cluster. So, if you have a 20-node cluster, then all 20 nodes will need that file in the SAME location. This shouldn’t be an issue if your nodes are just copies of a templated virtual machine, but if you use different box set ups for some of the nodes, they’ll have to be updated. Thankfully, we have all of our nodes set up in the exact same way per cluster. At some point in the future, I hope to explore a way we can bring it all back to a single configuration file and something that can be pushed directly to the REST API, but going with YAML was the quickest way to go at this point and we have the automation in place to update the files on the server.

<em>Side Note:</em> The domain objects were originally written in Groovy, but I’ve opted to go with Kotlin here. I like trying to mix in alternate JVM classes if it’ll help the code look cleaner. And, Plain Old Groovy (or Kotlin) Objects are definitely easier on the eyes than the equivalent Java. This change to Kotlin for this version of the connector also gave me a chance to work with a language I wanted to work with more.

In addition, since I switched to Kotlin for this version of the connector, I’m hitting a few bumps with using Kotlin objects in the place of the equivalent Groovy or Java classes. SnakeYAML requires a default no-arg constructor and trying to get Kotlin to play nicely with this requirement was a bit tricky at first. When using a Kotlin data class, you have to set default values for all properties in order to create a parameterless constructor. I found <a href="https://www.mkammerer.de/blog/snakeyaml-and-kotlin/">SnakeYAML and Kotlin</a>, which explores using Jackson for YAML and Kotlin, so maybe that is the route I will go. I may try to explore SnakeYAML a bit more before doing so, though.

So, this brings us to the end of this article. We looked at ways to extend the Kafka Kinesis Connector to work with multiple Firehose destinations. Also bear in mind, this only covers updating the `FirehoseSinkConnector` and `FirehoseSinkTask`. We didn’t make use of the `KinesisStreamSinkConnector`.

In future articles I will go over the upgrade issue that was experienced when deploying the newly updated code to one of the clusters and I will also go over some additional changes that we ended up having to make to the code that made me thankful we had separated out the mapping configurations into YAML files.