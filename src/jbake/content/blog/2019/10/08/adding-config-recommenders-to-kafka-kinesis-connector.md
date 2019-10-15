title=Adding Configuration Recommendations to the Kafka Kinesis Connector
date=2019-10-08
type=post
tags=kafka,kinesis,kafka connect,java
status=published
~~~~~~

So, we've strengthened up our configuration validation logic for the Kafka Kinesis Connector but there's still more we can do to help those that want to use this plugin. Of course, the principles used in these articles should generally apply to most any Kafka Connector you create. The next step is to help recommend configuration values to our users. For example, we can validate that a user has given us a valid AWS region, e.g. `us-east-1`, `us-west-1`, etc. but the user may not know all the valid regions available. For this purpose, we can provide a recommender to help recommend values to the user by implementing the `ConfigDef.Recommender` interface.

<!--more-->

Here is a simple region recommender implementation (`VALID_REGIONS` is an array of region names pulled in via `RegionUtils`):

<?prettify?>

    private static final Recommender REGION_RECOMMENDER = regionRecommender();

    // ...
    
    private static Recommender regionRecommender() {
        return new Recommender() {
            @Override
            public List<Object> validValues(String name, Map<String, Object> parsedConfig) {
                return Arrays.asList(VALID_REGIONS);
            }

            @Override
            public boolean visible(String name, Map<String, Object> parsedConfig) {
                return true;
            }
        };
    }

We need to provide an implementation of the `validValues` and `visible` methods. Thankfully, in this case, the AWS libraries provide us with an easy way to get the information we need for the valid value recommendations.

It should be noted, however, that the [recommenders are not used by the default implementation of `validate()`](http://kafka.apache.org/documentation/#connect_configs) and you'll need to override it if you wish to use the recommender values when validating. For now, I have left the `validate()` method alone since my validator for the region is a one liner:

<?prettify?>

    private static final Validator REGION_VALIDATOR = ValidString.in(VALID_REGIONS)

You can take a look at the [full class](https://github.com/joelforjava/multi-destination-kinesis-kafka-connector/blob/v10/src/main/java/com/amazon/kinesis/kafka/config/FirehoseSinkConnectorConfig.java), if you'd like.

In the future, I hope to go a bit more in depth and use the recommended values during validation, just for the sake of completeness.

