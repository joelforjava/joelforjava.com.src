title=Testing: Unit Testing with Mockito and Powermock
date=2018-07-09
type=post
tags=java,testing,junit,unit testing,powermock,mockito,carmix-collector
status=published
~~~~~~

Testing your code is an important step in the software development lifecycle and should be done as early as possible. Testing, in general, helps us catch mistakes and bugs in our code. I once worked on a project that had very little tests in place and the majority of those tests failed because your database is different from the test database. But, it also had some very important tests that would check Spring configurations and ensure everything was wired up correctly. These integration tests helped catch a lot of wiring issues quickly and helped us be more aware of how we updated the configurations as we updated the code. Tests, no matter if we're talking about unit, integration, functional, stress, or any other form of testing, help us find problems with the systems we write and gives us confidence that the code we write will work as expected.

<!--more-->

Now that `carmix-creator` has been [refactored](/blog/2018/06/05/refactoring-extract-class-part-2/) a bit, it's time to finally start adding some tests to make sure it all works the way it is expected to work.

There are at least three main types of tests that should be performed before a project or release goes live: unit tests, integration tests, and functional tests.<span id="read-more-1"></span> For now, we will focus on unit testing and work toward integration tests in a future post.

Unit testing is the practice of testing a single piece of code, usually a single class (in object-oriented programming) or a single function (in the case of functional programming), in isolation from external dependencies, including databases and external services. These external dependencies are mocked or stubbed to return expected outputs.

Unit tests are the first tests one should write when developing code and they should run quickly and produce repeatable results.

For the current iteration of the `carmix-creator` project, the classes that should be unit tested are `M3UPlaylistProcessor` and `CopyFileService`. Unfortunately, in the case of these classes, we have to go a bit further with mocking and mock some static methods.

There are many frameworks which be used when testing Java applications, including [JUnit](https://junit.org/), [TestNG](https://testng.org), [Spock](http://spockframework.org/), and [ScalaTest](http://www.scalatest.org/). We can go further and include mocking frameworks, such as [Mockito](http://site.mockito.org/), [EasyMock](http://easymock.org/), and [jMock](http://jmock.org/). For purposes of this post, I will be going with JUnit 4.12 for the simple reason that it was automatically added when I set up the Maven POM file. In addition, I will use Mockito and [PowerMock](http://powermock.github.io/) to aid in mocking. PowerMock adds additional functionality to existing mocking frameworks, such as Mockito and EasyMock, including the ability to mock static methods.

I usually don't like having to depend on Powermock, but sometimes it's a necessary evil such as the case with the playlist processor, since we want to mock `Files.readAllLines`. I would rather mock the `Path` class to return the expected lines when read, but `Path` is used to locate a file on the system and doesn't represent data within the referenced file. So, we'll need to mock `Files.readAllLines` to return the expected output in the form of different `List<string></string>`s based on what we want to test. In this case, we want to test that the File URIs are extracted from the returned list.

We can start with a simple test, one that does not require any mocks to be set up. We'll see what happens when we pass a `null Path` to the extractURIs method.

<?prettify?>

    @Test(expected = NullPointerException.class)
    public void testWithNullPath() {
        M3UPlaylistProcessor processor = new M3UPlaylistProcessor();
        processor.extractURIs(null);
    }

Since `extractURIs` does no checking on the `Path` parameter it receives, we end up with a `NullPointerException` thrown from the `Files.readAllLines` method call. Even though we 'know' how this method is called from the context of the GUI and that checks are performed before the call being made, we should still probably do a check on the parameter and act accordingly when the parameter is `null`. If I were practicing TDD at this moment, I'd update the code to handle this scenario, but for now I'll leave it alone.

There are a couple different ways we could handle the expected `NullPointerException`. The way you see above is the form I have used in the past with earlier versions of JUnit 4. However, in JUnit 4.7, they introduced the concept of Rules. Using Rules, we can rewrite the test the following way:

<?prettify?>

    // ... top of class
    @Rule
    public final ExpectedException expectedException = ExpectedException.none();

    // ... Other code

    @Test
    public void testWithNullPath() {
        M3UPlaylistProcessor processor = new M3UPlaylistProcessor();
        expectedException.expect(NullPointerException.class);
        processor.extractURIs(null);
    }

A JUnit rule intercepts method calls and allows us to handle a scenario both before a test method is run and after a test method has run. In this case, the `ExpectedException` rule will help us handle expectations for the thrown `NullPointerException`. I honestly just learned about rules while writing this post, so I'm looking forward into digging deeper.

A typical unit test method makes assertions about return values, however, since the previous test method was simply testing for the expected `NullPointerException`, there were no need for assertions.

So, we've tested with a null path, let's now try testing a file that has a single valid entry. For this test, we need to mock what `Files.readAllLines` returns since the `List` returned from this method is the list that will be processed for URI values. As I stated previously, I don't particularly like having to mock static methods, but in this case it's a necessary evil for the way the code is currently structured.

<?prettify?>

    @Test
    public void testWithSingleEntry() throws Exception {
        Path p = Paths.get("Test");

        List<String> lines = new ArrayList<String>() {{
            add("#EXTM3U");
            add("#EXTINF A Great Band - That Song You Remember");
            add("M:\\Temp\\File.mp3");
        }};
        PowerMockito.mockStatic(Files.class);
        Mockito.when(Files.readAllLines(p, StandardCharsets.ISO_8859_1)).thenReturn(lines);

        M3UPlaylistProcessor processor = new M3UPlaylistProcessor();
        List<String> extracted = processor.extractURIs(p);

        Assert.assertEquals(extracted.size(), 1);
    }

You should notice that we didn't need to mock the `Path` variable, although we could have done so. A path is just a locator to a file and since we're mocking the method that would make use of it, then there are no benefits to mocking it. The only mocking required is concerning the static method call. This method call was mocked to return an expected list, which contains the M3U Header, M3U File Information, and the File URI.

In order to run this test, we will need to annotate the class with the following annotations: `@PrepareForTest(M3UPlaylistProcessor.class)` and `@RunWith(PowerMockRunner.class)`. This allows Powermock to perform the extra work involved in order to mock the static method(s) we use.

Now, I can just add some variations of the previous test to see how the class under test handles the different data. For example, I can see what happens if I leave out the `#EXTINF` lines or if I have a file without an expected M3U header.

<?prettify?>

    @Test
    public void testWithNoInfoEntries() throws Exception {
        Path p = Mockito.mock(Path.class);

        List<String> lines = new ArrayList<>() {{
            add("#EXTM3U");
            add("M:\\Temp\\File.mp3");
            add("M:\\Temp\\File2.mp3");
            add("M:\\Temp\\File3.mp3");
        }};

        PowerMockito.mockStatic(Files.class);
        Mockito.when(Files.readAllLines(p, StandardCharsets.ISO_8859_1)).thenReturn(lines);

        M3UPlaylistProcessor processor = new M3UPlaylistProcessor();
        List<String> extracted = processor.extractURIs(p);

        Assert.assertEquals(3, extracted.size());
    }

You should notice that this test looks a lot like the previous one, except we've changed the mocked return list and we're expecting 3 URIs extracted from this list.

This has been a fairly brief overview of how to write JUnit tests with Mockito and Powermock. I'm hoping to go back over them in the near future and update them where possible, hopefully refactoring out my dependence on Powermock. For now, I'm content with having some tests in place and will see where I can make more improvements throughout the codebase.