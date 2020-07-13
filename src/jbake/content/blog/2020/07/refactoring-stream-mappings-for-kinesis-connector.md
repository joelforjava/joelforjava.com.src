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

I'm going to attempt the second approach, as ugly as it may end up being it may be the best bet to untether the connector from the YAML file.

