title=Parsing YAML Using Kotlin Objects
date=2019-11-19
type=post
tags=kotlin,yaml
status=published
~~~~~~

A.K.A. Getting Kotlin and SnakeYAML to Play Nicely Together

#### TODO - start Come back to this? ####

In my posts for a custom Kafka-Kinesis Connector, I decided to make use of a few Kotlin data classes to represent YAML configuration objects. The initial versions of these classes aren’t as good as I think they could be, though. For example, all of the data classes make use of vars rather than vals. I’d much rather stick to vals whenever possible. 

They also all use optional (nullable) types for every field. I’d much rather use non-optionals when I can and when I know that certain values should always be non-null, such as the topic or destination stream names. They were all set up this way because it was the only way I could get it all to work together and at the time, all I wanted was something that worked.

#### Come back to this? ####

For example, I started out with this class for the `DestinationStreamMapping`:

<?prettify?>

    data class DestinationStreamMapping(var name: String? = null, 
    	                            var destinations: List<String>? = null, 
    	                            var fiters: List<StreamFilterMapping>? = null)

What I would like to end up with is something like this:

<?prettify?>

    data class DestinationStreamMapping(val name: String, 
    	                            val destinations: List<String>, 
    	                            val fiters: List<StreamFilterMapping>)

Is this attainable using SnakeYAML to parse my YAML files? Let's find out! While working on this, I came across an [article](https://www.mkammerer.de/blog/snakeyaml-and-kotlin) that tried to attain this and failed. That article ultimately suggested going with Jackson, and maybe that's the way to go. However, I want to see if it is at all possible to use the desired data classes with YAML. Will it even be YAML we want to use?

For these tests, I'll be using a different set of Kotlin and YAML files, which reference Bands, their albums, and their songs. For starters, we will go with using vars and null defaults just to force Kotlin to generate a parameterless constructor.

Here is a sample of the YAML we will be attempting to parse:

<?prettify?>

	name: Fleetwood Mac
	albums:
	  - name: Rumours
	    releaseYear: 1977
	    label: Warner Bros.
	    tracks:
	      - Second Hand News
	      - Dreams
	  - name: Fleetwood Mac
	    releaseYear: 1975
	    label: Reprise
	    tracks:
	      - Monday Morning
	      - Warm Ways

And here's our beginning Band data classes:

<?prettify?>

    data class Band(var name: String? = null, var albums: List<Album>? = null)

    data class Album(var name: String? = null,
                 var releaseYear: Int? = null,
                 var label: String? = null,
                 var tracks: List<Song>? = null)

    data class Song(var name: String? = null)

These classes all use vars and have null defaults. This causes a default constructor to be created and therefore SnakeYAML will be able to parse the YAML into these data classes.

As soon as you replace vars with vals in one of the data classes, the tests all fail due to the now lack of setters for that class. There is a way around this, though, if you change the bean access to BeanAccess.FIELD instead of BeanAccess.DEFAULT, which uses JavaBean properties and public fields. If you run the tests after making this change in the ConfigParser class, then all the tests will pass again.

As for the non-null fields, as long as you use something like an empty string for the initializer, you can switch the type to String.

##      ##

I found an article that also showed some frustrations with working with Kotlin and SnakeYAML. (TODO - LINK!!). Ultimately, he decided to go with Jackson for YAML parsing but I wanted to look more into using SnakeYAML with Kotlin since it’s a smaller library and I really just want to see what’s possible with it.  I thought maybe this could prove as a good way for me to get more familiar with Kotlin and also see if I can get the desired results with SnakeYAML.

So, I’ll be working with a similar structure as to those files used with my version of the Kafka-Kinesis Connector and I’ll begin with data classes that resemble those initial data classes and progressively work toward data classes that are more restrictive (e.g. as many vals as possible and non-null types). Hopefully the final result will be data classes that don’t require default values for everything and just be simplistic-looking data classes.