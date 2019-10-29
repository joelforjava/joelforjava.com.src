title=Adding SSL Encryption Configuration to Kafka Connectors
date=2019-10-27
type=post
tags=kafka,kafka connect,java,ssl,encryption
status=published
~~~~~~

One thing you should always strive to do is to enable encryption, wherever possible, even if your systems are locked away behind layers and layers of firewalls and other security protocols. Even if your systems are not public facing and don't have a public IP address, you should at the very least encrypt your communications. For this article, we will explore how we enable a Kafka connector to communicate with an SSL-encrypted Kafka cluster.

<!--more-->

I'm by no means an encryption expert, but I'm doing my best to pick things up along the way. Recently, we finally enabled SSL encryption on the Kafka clusters we use at my day job. While there were pages and articles that send me in the right direction, ultimately they only got me half way there. [The Apache Kafka documentation](http://kafka.apache.org/documentation/#security_ssl) does a good job of explaining how to set up SSL and it does a good job of showing how to get a producer or consumer communicating with an SSL-enabled broker. However, if you try to use the same properties to work with Kafka Connect, you'll be disappointed. All I ended up seeing whenever I'd start the connector are a series of OutOfMemory errors and we'd have to shut it back down.

What I was unaware of at the time, is we needed to add properties that specifically targeted the connector. If you're using a `Sink` connector, you'll need to add the same `ssl.*` properties prefixed with `consumer.`, while `Source` connectors will need to use the `producer.` prefix. You'll need to make sure these properties exist alongside the existing `ssl.*` properties. If you have only the `consumer.` or `producer.` prefixed properties, they'll be ignored!

Here's a sample Sink connector property file (`connect-distributed.properties`)

    # SSL Configuration
    security.protocol=SSL
    ssl.truststore.location=/opt/kafka/truststore/kafka.connect.truststore.jks

    ssl.enabled.protocols=TLSv1.2,TLSv1.1
    ssl.truststore.type=JKS

    # Connector properties
    consumer.security.protocol=SSL
    consumer.ssl.truststore.location=/opt/kafka/truststore/kafka.connect.truststore.jks

    consumer.ssl.enabled.protocols=TLSv1.2,TLSv1.1
    consumer.ssl.truststore.type=JKS

As my luck would have it, I didn't find the Confluent page that [discussed this very thing](https://docs.confluent.io/current/connect/security.html) until after my figuring out the problem. Maybe I was having a bad Google day? Well, just in case you're having a bad Google day too, I hope this article has been some help to you.