title=Creating a Builder for the Kafka Connect ConfigKey Class
date=2019-10-12
type=post
tags=kafka,kinesis,kafka connect,java,design patterns, builder
status=published
~~~~~~

One of the issues I have with creating a custom ConfigDef for the Kafka Kinesis Connector is having to deal with multiple, very long, method signatures for `ConfigDef.define`. `ConfigDef` provides an astonishing 16 `define` methods as of version `0.11.0.2` (the version that's used by the project), with one that takes in a `ConfigKey` that actually performs the work. All of the other methods eventually call this method, passing in a new `ConfigKey`, which means the constructor for this class is also a monster. 

<!--more-->

I'm not questioning the design decisions that went into this. I actually like how they all chain up to calling one define method. However, calls to `define` all look something like this:

<?prettify?>

    configDef.define(
        REGION_CONFIG,
        Type.STRING,
        "us-east-1",
        REGION_VALIDATOR,
        Importance.HIGH,
        "Specify the region of your Kinesis Firehose",
        group,
        ++offset,
        Width.SHORT,
        "AWS Region",
        REGION_RECOMMENDER)
        .define(
            MAPPING_FILE_CONFIG,
            Type.STRING,
            ConfigDef.NO_DEFAULT_VALUE,
            MAPPING_FILE_VALIDATOR,
            Importance.HIGH,
            "Location of the YAML Mapping file that defines the mapping from topics to destinations",
            group,
            ++offset,
            Width.MEDIUM,
            "Mapping Configuration Location")

    // additional calls to define

And, while you might be able to tell that the first parameter is the config name, with the type as the second parameter, it quickly becomes problematic when you deal with definitions that might not have a Validator or that might not have a need to pass in a default value. It's just hard to look at, even with the help of an IDE such as Intellij or Eclipse. However, using a builder would help make this more readable. 

## What is the Builder Pattern? ##

The builder pattern provides an alternate way of creating and instantiating a new object. As [Wikipedia](https://en.wikipedia.org/wiki/Builder_pattern) puts it, the builder is designed to provide a flexible solution to various object creation problems in object-oriented programming. With this pattern, you create an additional class, the Builder, that contains the same fields that you're wanting to use to create a class. For example, for a `ConfigKey` Builder, we'd want to contain the fields below:


<?prettify?>

    String name;
    Type type;
    String documentation;
    Object defaultValue;
    Validator validator;
    Importance importance;
    String group;
    int orderInGroup;
    Width width;
    String displayName;
    List<String> dependents;
    Recommender recommender;
    boolean internalConfig;

Each of these fields would contain a corresponding setter, such as `setType`, `setDocumentation`, etc. For builders, I tend to not use the `set` prefix and just name the setters the same as the field name. Alternatively, I might find myself using a `with` prefix. After you set all of the fields you wish to set, you then call the `build()` method that takes care of creating the new class. Also, rather than having a `setName`, I pass the name into the builder constructor, since all `ConfigKey`s really should have a name associated with them.

So, I created a builder that makes it more apparent which values are being set. The code from above becomes the following:

<?prettify?>

    configDef.define(new ConfigKeyBuilder(REGION_CONFIG)
            .type(Type.STRING)
            .defaultValue("us-east-1")
            .validator(REGION_VALIDATOR)
            .importance(Importance.HIGH)
            .documentation("Specify the region of your Kinesis Firehose")
            .group(group)
            .orderInGroup(++offset)
            .width(Width.SHORT)
            .displayName("AWS Region")
            .recommender(REGION_RECOMMENDER).build())
        .define(new ConfigKeyBuilder(MAPPING_FILE_CONFIG)
                .type(Type.STRING)
                .defaultValue(ConfigDef.NO_DEFAULT_VALUE)
                .validator(MAPPING_FILE_VALIDATOR)
                .importance(Importance.HIGH)
                .documentation("Location of the YAML Mapping file that defines the mapping from topics to destinations")
                .group(group)
                .orderInGroup(++offset)
                .width(Width.MEDIUM)
                .displayName("Mapping Configuration Location").build())

In my opinion, this is far better than having to guess and remember the order of the parameters to the other `define` methods. Using the `ConfigKeyBuilder` makes the values which you're setting more apparent, such as the recommender or the default value for a configuration. The builder pattern can make code more verbose, but in this case, I will happily accept the verbosity over the confusion of all the `define` methods. Also, the builder pattern could potentially lead to incompletely instantiated objects, but again, it's worth the risk since it helps lessen my mental load for creating new objects. If you wanted to take things one step further, you could run validators prior to creating the objects to ensure you have all the required values set.

The complete class can be viewed in my [GitHub repo](https://github.com/joelforjava/multi-destination-kinesis-kafka-connector/blob/v10/src/main/java/com/amazon/kinesis/kafka/config/ConfigKeyBuilder.java).