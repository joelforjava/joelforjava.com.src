title=Adding Filtering to the Kafka Kinesis Connector
date=2019-09-26
type=post
tags=kafka,kinesis,aws,kafka connect,java
status=published
~~~~~~

In a [previous post](/blog/2019/09/22/customizing-kafka-kinesis-connector.html), we made modifications to the Kafka-Kinesis Connector that allowed us to use multiple topics and multiple destinations with a single connector task. This time, we’ll go a bit further and add more functionality to the connector. What if we later ended up with a requirement that some of the data going through a topic had to be filtered out into additional destination firehoses?

<!--more-->

This scenario should be fairly easy to get set up in the YAML configuration. We’ll call the new section `filters` and then list the traits of these filters, such as listing the criteria that will cause a message to be filtered into the additional firehose destinations. The message can either start with certain phrases or contain specific keywords anywhere in the message. Matching either of these criteria will cause the message to be sent to the additional destination(s).

<pre class="prettyprint">
    <code>
- name: BIOMETRICS.TOPIC
  destinations:
    - BIOMETRICS-STREAM
    - S3-BIOMETRICS-STREAM
  filters:
    - sourceTopic: BIOMETRICS.TOPIC
      destinationStreamNames:
        - BLOODPRESSURE-STREAM
      keywords:
        - Blood pressure
        - Bloodpressure
        - blood pressure
    - sourceTopic: BIOMETRICS.TOPIC
      destinationStreamNames:
        - HEARTRATE-STREAM
      startingPhrases:
        - Heart rate
    </code>
</pre>

We’ll create an additional object to hold the Filter data and add logic that will  check to see if a message contains either a starting phrase or keywords as set in the configuration. We will also need to add additional logic to check for these keywords and starting phrases. If none of the values are found in a given message, then they do not go to the additional streams.

<?prettify?>

    data class StreamFilterMapping(var sourceTopic: String? = null,
                                var destinationStreamNames: List<String>? = null,
                                var keywords: List<String>? = null,
                                var startingPhrases: List<String>? = null)

The updated logic will want to ensure it does not interfere with the existing logic and should only add new streams for filtered messages to the existing list of streams. If the topic doesn’t have filters configured or if the message does not meet filtering criteria, then the list should remain untouched.

<?prettify?>

    List<StreamFilterMapping> filterMappings = filters.get(topic);
    if (filterMappings != null && !filterMappings.isEmpty()) {
        boolean found = false;
        final String val = new String((byte[])sinkRecord.value());
        for (StreamFilterMapping filter : filterMappings) {
            List<String> keywords = Optional.ofNullable(filter.getKeywords())
                                            .orElse(Collections.emptyList());
            List<String> phrases = Optional.ofNullable(filter.getStartingPhrases())
                                            .orElse(Collections.emptyList());

            if (keywords.stream().anyMatch(val::contains)
                    || phrases.stream().anyMatch(s -> val.startsWith("{\"message\":\""+s))) {
                if (filter.getDestinationStreamNames() != null) {
                    streams.addAll(filter.getDestinationStreamNames());
                    found = true;
                }
            }

            if (!found) {
                log.debug("No additional streams found via filter for Topic '{}' with Message: {}.", topic, val);
            }
        }
    }

Here, we make use of `Optional`s to return an empty list in the event that either the keywords or starting phrases collections are `null`. This helps the logic for verifying the message fairly small. We also make use of the Streams API to search the lists for any configured keywords or phrases. If found, we add the related destination streams to the existing stream list and continue as before.

This brings us to the end of the article. We walked through how to add additional functionality to the Kafka Kinesis Connector in the form of filtering messages to send them to additional Firehoses. Next, I plan on cleaning the code up a bit, such as renaming the confusingly similar putRecordBatch, putBatch, etc. Hopefully we will also walk through various ways to test it, including unit tests and possibly integration & functional tests.
