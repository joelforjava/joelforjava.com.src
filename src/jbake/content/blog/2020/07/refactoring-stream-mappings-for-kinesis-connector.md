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


