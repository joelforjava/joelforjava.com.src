title=Refactoring the Stream Mappings Configuration Setup
date=2020-07-31
type=post
tags=kafka,kafka connect,java
status=draft
~~~~~~

A little over a year ago, I walked through a refactoring of the Kinesis Kafka Connector that allowed me to map out mappings from source topics into Kinesis Firehose destinations. With this mapping, I could configure messages from one topic to be sent to one or more firehoses outright or based on the message data. This solution has one weak point, especially when taking distributed mode into consideration: It requires an external file to be updated and then the service to be restarted. Wouldn't it be great if we could just push the mappings as JSON into the REST API, with a structure similar to below?

    {
        "clusterName": "cluster_1",
        "streams": [
            {
                "name": "TEMPERATURES.TOPIC",
                "destinations": [ "TEMPERATURES-STREAM", "S3-TEMPERATURES-STREAM", "WEATHER-STREAM" ]
            },
            {
                "name": "BIOMETRICS.TOPIC",
                "destinations": [ "BIOMETRICS-STREAM", "S3-BIOMETRICS-STREAM" ],
                "filters": [
                    {
                        "sourceTopic": "BIOMETRICS.TOPIC",
                        "destinationStreamNames": [ "BLOODPRESSURE-STREAM" ],
                        "keywords": [ "Blood pressure", "Bloodpressure", "blood pressure" ]
                    },
                    {
                        "sourceTopic": "BIOMETRICS.TOPIC",
                        "destinationStreamNames": [ "HEARTRATE-STREAM" ],
                        "startingPhrases": [ "Heart rate" ]
                    }
                ]
            }
        ]
    }

However, can we make this work? Furthermore, can we make this work in both distributed and standalone modes?

The quick answer appears to be no. 

If we adhere strictly to the `ConfigDef.Type` `enum`, we have to use one of the following: `BOOLEAN`, `STRING`, `INT`, `SHORT`, `LONG`, `DOUBLE`, `LIST`, `CLASS`, or `PASSWORD`. Sticking with the `ConfigDef` seems to also rule out "dynamic" properties, like `streams.0.name`, `streams.0.destinations`, etc. since you have to explicitly list out the property names in your `ConfigDef` implementation.

There are several options to choose from at this point, each with varying degrees of difficulty. 

You could try creating a custom subclass of `ConfigDef`. However, things get problematic when it comes to `ConfigDef.Type`, which is an `enum` and cannot be subclassed.

You could use the `Type.STRING` type and pass the stringified JSON object that way. However, this could get ugly if you're mapping a lot of different topics. You would be able to validate it via a `Validator`, though, prior to pushing the configuration. Still, you'd need to take extra care around this solution to ensure you don't attempt to push an invalid configuration.

If you don't need to worry about filtering data into multiple firehoses based on keywords or phrases, you could create a new property, say `deliveryStreamNames` that accepts more than one Firehose Delivery Stream name, if all you need to do is send to multiple Firehoses. You could then push a configuration per topic or topics. However, if you're consuming from a lot of topics, this will get unwieldly fast. This situation is one of the primary reasons we went with the one config for all topics approach.

For the moment, let's attempt the second approach, as ugly as it may end up being. It may be the quickest way to untether the connector from the YAML file but is it the best? That remains to be seen.

### Adding a parseJSON method ###

Thanks to Kafka's dependency on Jackson, the Connector project has it as a transitive dependency. We can add a method to `MappingConfigParser`, like so:

    public static Optional<ClusterMapping> parseJson(String jsonData) {
        ClusterMapping mapping = null;

        ObjectMapper mapper = new ObjectMapper();
        try {
            mapping = mapper.readValue(jsonData, ClusterMapping.class);
        } catch (IOException e) {
            log.error("There was an error trying to read the mapping data from the provided string.");
        }
        return Optional.ofNullable(mapping);
    }

As long as we pass valid JSON, we can convert it to a `ConfigMapping`! We can exercise this functionality with a unit test:

    @Test
    void testParseJsonCanParseStringWithNewlinesIntoClusterMapping() {
        String jsonData = "    {\n" +
                "        \"clusterName\": \"cluster_1\",\n" +
                "        \"streams\": [\n" +
                "            {\n" +
                "                \"name\": \"TEMPERATURES.TOPIC\",\n" +
                "                \"destinations\": [ \"TEMPERATURES-STREAM\", \"S3-TEMPERATURES-STREAM\", \"WEATHER-STREAM\" ]\n" +
                "            },\n" +
                "            {\n" +
                "                \"name\": \"BIOMETRICS.TOPIC\",\n" +
                "                \"destinations\": [ \"BIOMETRICS-STREAM\", \"S3-BIOMETRICS-STREAM\" ],\n" +
                "                \"filters\": [\n" +
                "                    {\n" +
                "                        \"sourceTopic\": \"BIOMETRICS.TOPIC\",\n" +
                "                        \"destinationStreamNames\": [ \"BLOODPRESSURE-STREAM\" ],\n" +
                "                        \"keywords\": [ \"Blood pressure\", \"Bloodpressure\", \"blood pressure\" ]\n" +
                "                    },\n" +
                "                    {\n" +
                "                        \"sourceTopic\": \"BIOMETRICS.TOPIC\",\n" +
                "                        \"destinationStreamNames\": [ \"HEARTRATE-STREAM\" ],\n" +
                "                        \"startingPhrases\": [ \"Heart rate\" ]\n" +
                "                    }\n" +
                "                ]\n" +
                "            }\n" +
                "        ]\n" +
                "    }";

        Optional<ClusterMapping> mapping = MappingConfigParser.parseJson(jsonData);
        Assert.assertTrue(mapping.isPresent());

        ClusterMapping clusterMapping = mapping.get();
        Assert.assertEquals(clusterMapping.getClusterName(), "cluster_1");
        Assert.assertEquals(clusterMapping.getStreams().size(), 2);
    }

Everything seems to work fine! However, adding this mapping as a property in the property file is ... less than ideal. Below are the contents of an example property file, with the `streamMappings` property being a mini-fied version of the JSON at the top of the page.

    name=cluster_3
    connector.class=com.amazon.kinesis.kafka.FirehoseSinkConnector
    tasks.max=25
    topics=TEMPERATURES.TOPIC,BIOMETRICS.TOPIC
    region=us-east-1
    batch=true
    batchSize=500
    batchSizeInBytes=3670016
    streamMappings={"clusterName": "cluster_3","streams": [{"name": "TEMPERATURES.TOPIC","destinations": [ "TEMPERATURES-STREAM", "S3-TEMPERATURES-STREAM", "WEATHER-STREAM" ]},{"name": "BIOMETRICS.TOPIC","destinations": [ "BIOMETRICS-STREAM", "S3-BIOMETRICS-STREAM" ],"filters": [{"sourceTopic": "BIOMETRICS.TOPIC","destinationStreamNames": [ "BLOODPRESSURE-STREAM" ],"keywords": [ "Blood pressure", "Bloodpressure", "blood pressure" ]},{"sourceTopic": "BIOMETRICS.TOPIC","destinationStreamNames": [ "HEARTRATE-STREAM" ],"startingPhrases": [ "Heart rate" ]}]}]}

This mapping is fairly small considering it contains only two topics. What if we had to work with 10, 20, or more?

`TODO` - how would this look if we checked the plugin's config?

