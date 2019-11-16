title=Parsing YAML Using Kotlin Objects
date=2019-11-19
type=post
tags=kotlin,yaml
status=draft
~~~~~~

A.K.A. Getting Kotlin and SnakeYAML to Play Nicely Together

When I set out to customize the Kafka-Kinesis Connector to read in a [YAML configuration](/blog/2019/09/22/customizing-kafka-kinesis-connector.html) for use by the connector, I decided to go with Kotlin data classes to hold that configuration. The initial versions of these classes aren’t as good as I think they could be, though. For example, all of these data classes make use of vars rather than vals. I’d much rather stick to vals whenever possible due to the fact that they're read-only and cannot be changed once set. 

The initial data classes also all use optional (nullable) types for every field. I’d prefer using non-optionals when I can and when I know that certain values should always be non-null, such as the topic or destination stream names. Even for the 'optional' items, like `filters`, I'd still prefer to return an empty list rather than `null`. These data classes were all created this way because it was the quickest way I could get it all to work together and, at the time, all I wanted was something that worked. So this is me coming back to see what I can do to make these classes better, if anything.

This is the first version of the `DestinationStreamMapping` class:

<?prettify?>

    data class DestinationStreamMapping(var name: String? = null, 
    	                            var destinations: List<String>? = null, 
    	                            var fiters: List<StreamFilterMapping>? = null)

What I would like to end up with is something like this:

<?prettify?>

    data class DestinationStreamMapping(val name: String, 
    	                            val destinations: List<String>, 
    	                            val fiters: List<StreamFilterMapping>)

You may be thinking there isn't much of a difference between the two, and on the surface you'd be right. However, `val`s can only be assigned once and are therefore read-only. I tend to err on the side of read-only and immutability wherever possible. 

Is this attainable using SnakeYAML to parse my YAML files? Let's find out! While working on this, I came across an [article](https://www.mkammerer.de/blog/snakeyaml-and-kotlin) that tried to attain this and failed. That article ultimately suggested going with Jackson, and maybe that's the way to go. However, I want to see if it is at all possible to use the desired data classes with YAML. Will it even be YAML we want to use?

For these tests, I'll be using a project that contains a different set of Kotlin and YAML files, which reference Bands, their albums, and their songs. This project is available on GitHub. It has 4 kotlin files, try_1.kt up to try_4.kt that contain the different data class implementations.

Here is an example of a YAML file we will be attempting to parse:

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

And here's our beginning Band data classes as they exist in `try_1.kt`:

<?prettify?>

    data class Band(var name: String? = null, var albums: List<Album>? = null)

    data class Album(var name: String? = null,
                 var releaseYear: Int? = null,
                 var label: String? = null,
                 var tracks: List<Song>? = null)

    data class Song(var name: String? = null)

These classes all use vars and have null defaults. This causes a default constructor to be created and therefore SnakeYAML will be able to parse the YAML into these data classes.

The first step I took in refining these classes was to replace `var`s with `val`s in one of the data classes. Doing this causes the tests all fail due to the now lack of setters for that class. There is a way around this, though, if you change the bean access to `BeanAccess.FIELD` instead of `BeanAccess.DEFAULT`, which uses JavaBean properties and public fields. If you run the tests `TODO list tests!` after making this change in the `parseYamlAs` function, then all the tests will pass again. These class definitions are present in `try_2.kt`.

As for the non-null fields, as long as you use something like an empty string for the initializer, you can switch from `String?` to `String`.

So, now we have the following data classes from `try_3.kt`:

<?prettify?>

	data class Band3(val name: String = "", val albums: List<Album3> = emptyList())

	data class Album3(val name: String = "",
	                  val releaseYear: Int = 0,
	                  val label: String = "",
	                  val tracks: List<Song3> = emptyList())

	data class Song3(val name: String = "")

And this is the function used to parse the YAML:

<?prettify?>

	fun <T> parseYamlAsUsingFieldAccess(fileUrl: String, clazz: Class<T>): T? {
	    var mapping: T? = null
	    val inputStream = loadResourceAsStream(fileUrl) ?: return mapping
	    BufferedInputStream(inputStream).use { bis ->
	        val yaml = Yaml()
	        yaml.setBeanAccess(BeanAccess.FIELD)
	        mapping = yaml.loadAs(bis, clazz)
	    }
	    return mapping
	}

My next step was to eliminate the default values. This took a bit of work to find a YAML format that would parse correctly into these classes. And while I did manage to make it work with the above parse function, you'll soon see that the `clazz` parameter is redundant when presented with the final YAML, so I wrote a new, very similar method to handle the parsing.

<?prettify?>

	data class Band4(val name: String, val albums: List<Album4>)

	data class Album4(val name: String,
	                  val releaseYear: Int,
	                  val label: String,
	                  val tracks: List<Song4>)

	data class Song4(val name: String)

Prior to this, I did not realize that you can add type information to your YAML definitions. This is the approach I found myself taking with these last data classes. There seemed to be no other way to get SnakeYAML to parse data into these classes.

Before I set out to write this article and while I was working with the Kafka-Kinesis Connector, I found another article that also showed some frustrations with working with Kotlin and SnakeYAML. `(TODO - LINK!!)`. Ultimately, the author decided to go with Jackson for YAML parsing, so I knew using the final data classes would not work with the existing YAMIL as-is. Still, I thought it would be interesting to look more into what it would take to get SnakeYAML to parse *something* using those classes.  The results, in my opinion, are not very pretty. I'm sure there are valid uses for adding type details to a YAML definition, but for the vast majority of my uses I want to avoid adding this type of information.

From this point, TBD......

#### How do I incorporate the below into the article?


So, I’ll be working with a similar structure as to those files used with my version of the Kafka-Kinesis Connector and I’ll begin with data classes that resemble those initial data classes and progressively work toward data classes that are more restrictive (e.g. as many vals as possible and non-null types). Hopefully the final result will be data classes that don’t require default values for everything and just be simplistic-looking data classes.