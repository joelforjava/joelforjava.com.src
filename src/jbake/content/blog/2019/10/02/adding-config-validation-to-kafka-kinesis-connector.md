title=Adding Configuration Validation to the Kafka Kinesis Connector
date=2019-10-02
type=post
tags=kafka,kinesis,kafka connect,java
status=published
~~~~~~

As it currently stands, you can easily feed invalid property values to the Kafka Kinesis Firehose Connector, such as a batch size of 1000, when the maximum batch size allowed by Firehose is only 500. Thankfully, Kafka Connect provides a mechanism to help with validating properties. The REST API provides a validate endpoint at `/connector-plugins/<CONNECTOR_CLASS_NAME>/config/validate`.

<!--more-->

If you try running the following command:

<?prettify?>

    curl -XPUT -H "Content-type: application/json" http://localhost:8083/connector-plugins/FirehoseSinkConnector/config/validate --data '{"connector.class": "com.amazon.kinesis.kafka.FirehoseSinkConnector", "topics": "Hello-World-Topic"}'

You will get a response similar to the truncated one below:

<?prettify?>

    {
        "name": "com.amazon.kinesis.kafka.FirehoseSinkConnector",
        "error_count": 0,
        "groups": [
            "Common",
            "Transforms",
            "Error Handling"
        ],
        "configs": [
            {
                "definition": {
                    "name": "name",
                    "type": "STRING",
                    "required": true,
                    "default_value": null,
                    "importance": "HIGH",
                    "documentation": "Globally unique name to use for this connector.",
                    "group": "Common",
                    "width": "MEDIUM",
                    "display_name": "Connector name",
                    "dependents": [],
                    "order": 1
                },
                "value": {
                    "name": "name",
                    "value": "dev_cluster_1",
                    "recommended_values": [],
                    "errors": [],
                    "visible": true
                }
            },
            {
                "definition": {
                    "name": "connector.class",
                    "type": "STRING",
                    "required": true,
                    "default_value": null,
                    "importance": "HIGH",
                    "documentation": "Name or alias of the class for this connector. Must be a subclass of org.apache.kafka.connect.connector.Connector. If the connector is org.apache.kafka.connect.file.FileStreamSinkConnector, you can either specify this full name,  or use \"FileStreamSink\" or \"FileStreamSinkConnector\" to make the configuration a bit shorter",
                    "group": "Common",
                    "width": "LONG",
                    "display_name": "Connector class",
                    "dependents": [],
                    "order": 2
                },
                "value": {
                    "name": "connector.class",
                    "value": "com.amazon.kinesis.kafka.FirehoseSinkConnector",
                    "recommended_values": [],
                    "errors": [],
                    "visible": true
                }
            }
        ]
    }

You should see definitions for properties such as `topics`, `topics.regex`, `errors.retry.timeout`, and the other properties provided by Kafka Connect out of the box. You will also see any errors caused by any of the values we provide for those properties. However, there are no entries for our properties, such as `region` or `batchSizeInBytes`. How do we get those entries?

At the most basic level, we need to provide a custom implementation of the `config()` method in `FirehoseSinkConnector`. We do this by providing our own `ConfigDef` rather than the default `new ConfigDef()` that is currently returned.

### Implementing a Custom ConfigDef ###

This is where I take a bit of inspiration from the [Confluent Elasticsearch Connector](https://github.com/confluentinc/kafka-connect-elasticsearch) and create a new class, `FirehoseSinkConnectorConfig`, that handles the creation of this new `ConfigDef`. For example, if we want to add a definition for the `region` property, we could create the following:

<?prettify?>

    private static void addConfig(ConfigDef configDef) {
        int offset = 0;
        final String group = "AWS Configuration";
        configDef.define(
                REGION_CONFIG,
                ConfigDef.Type.STRING,
                "us-east-1",
                ConfigDef.Importance.HIGH,
                "Specify the region of your Kinesis Firehose",
                group,
                ++offset,
                ConfigDef.Width.SHORT,
                "AWS Region");
        // Add others
    }

We can then change the `FirehoseSinkConnector.config` method to return `FirehoseSinkConnectorConfig.CONFIG`, which contains the custom-built `ConfigDef` definition, and this updated config will be displayed when you try to validate your configuration against the REST API.

<?prettify?>

    curl -XPUT -H "Content-type: application/json" http://localhost:8083/connector-plugins/FirehoseSinkConnector/config/validate --data '{"connector.class": "com.amazon.kinesis.kafka.FirehoseSinkConnector", "topics": "Hello-World-Topic", "batchSize": 600}'

Will result in:

<?prettify?>

    {
        "name": "com.amazon.kinesis.kafka.FirehoseSinkConnector",
        "error_count": 0,
        "groups": [
            "Common",
            "Transforms",
            "Error Handling",
            "AWS Configuration"
        ],
        "configs": [
            {
                "definition": {
                    "name": "region",
                    "type": "STRING",
                    "required": false,
                    "default_value": "us-east-1",
                    "importance": "HIGH",
                    "documentation": "Specify the region of your Kinesis Firehose",
                    "group": "AWS Configuration",
                    "width": "SHORT",
                    "display_name": "AWS Region",
                    "dependents": [],
                    "order": 1
                },
                "value": {
                    "name": "region",
                    "value": "us-east-1",
                    "recommended_values": [],
                    "errors": [],
                    "visible": true
                }
            },
            {
                "definition": {
                    "name": "batchSize",
                    "type": "INT",
                    "required": false,
                    "default_value": "500",
                    "importance": "HIGH",
                    "documentation": "Number of messages to be batched together. Firehose accepts at max 500 messages in one batch.",
                    "group": "AWS Configuration",
                    "width": "SHORT",
                    "display_name": "Maximum Number of Messages to Batch",
                    "dependents": [],
                    "order": 4
                },
                "value": {
                    "name": "batchSize",
                    "value": "600",
                    "recommended_values": [],
                    "errors": [],
                    "visible": true
                }
            }
        ]
    }

When calling the REST API after the updated code has been deployed, you should see an entry for the `region` property and any additional properties you've defined in your custom `ConfigDef`. Also notice we passed an invalid value for `batchSize`, however it doesn't show an error. We still need to do a little bit more work to handle the validation.

### Adding Configuration Validation ###

We do this with the help of `ConfigDef.Validator`s. The `Validator` class allows us to provide any kind of special validation logic for our configurations, such as ensuring we use a valid `region` value.

We can provide an implementation for a `Validator` using a Lambda and add the following the the `FirehoseSinkConnectorConfig` class:

<?prettify?>

    private static final ConfigDef.Validator batchSizeValidator = (name,  value) -> {
        Integer intValue = (Integer) value;
        if (intValue <= 0 || intValue > MAX_BATCH_SIZE) {
            throw new ConfigException(name, intValue, "Batch size must be greater than zero or no greater than 500");
        }
    };

Even better than this, for our current use case, Connect provides some sample implementations of `Validator`, including `Range` and `ValidList`. So we can make our `batchSizeValidator` even simpler:

<?prettify?>

    private static final ConfigDef.Range batchSizeValidator = ConfigDef.Range.between(0, MAX_BATCH_SIZE);

We can add this validator implementation to our configuration definition and now it'll reject any invalid values, which can be shown in the following unit test:

<?prettify?>

    @Test(expectedExceptions = ConfigException.class, expectedExceptionsMessageRegExp = "Invalid value.*")
    public void testPropertyWithInvalidMaxValueWillBeRejected() {
        Map<String, String> props = new HashMap<>();
        String batchSize = "5000";
        props.put(FirehoseSinkConnectorConfig.MAPPING_FILE_CONFIG, "sample_cluster_2_w_filters.yaml");
        props.put(FirehoseSinkConnectorConfig.BATCH_SIZE_CONFIG, batchSize);
        FirehoseSinkConnectorConfig config = new FirehoseSinkConnectorConfig(props);
    }

After deploying this latest update, if we repeat the curl request from above, we will see an error flagged for the `batchSize` value:

<?prettify?>

    {
      "definition": {
        "name": "batchSize",
        "type": "INT",
        "required": false,
        "default_value": "500",
        "importance": "HIGH",
        "documentation": "Number of messages to be batched together. Firehose accepts at max 500 messages in one batch.",
        "group": "AWS Configuration",
        "width": "SHORT",
        "display_name": "Maximum Number of Messages to Batch",
        "dependents": [],
        "order": 4
      },
      "value": {
        "name": "batchSize",
        "value": "600",
        "recommended_values": [],
        "errors": [
          "Invalid value 600 for configuration batchSize: Value must be no more than 500"
        ],
        "visible": true
      }
    }

### Configuration Validation in Standalone Mode ###

If you would rather try run Connect in standalone mode, you will still get error messages when you try to start with an invalid property file for your connector instance:

<?prettify?>

    ./connect-standalone.sh ~/dev/kafka-connect/config/cluster_3/worker.properties ~/dev/kafka-connect/config/cluster_3/kinesis-firehose-kafka-connector.properties

Results in:

<?prettify?>

    [2019-08-25 12:01:55,483] ERROR Stopping after connector error (org.apache.kafka.connect.cli.ConnectStandalone:121)
    java.util.concurrent.ExecutionException: org.apache.kafka.connect.runtime.rest.errors.BadRequestException: Connector configuration is invalid and contains the following 1 error(s):
    Missing required configuration "mappingFile" which has no default value.
    You can also find the above list of errors at the endpoint `/{connectorType}/config/validate`
        at org.apache.kafka.connect.util.ConvertingFutureCallback.result(ConvertingFutureCallback.java:79)
 
This is just scratching the surface of what can be done with Kafka Connect configurations and I'm hoping to explore it a bit more in the future, including the use of custom `Recommender` implementations.