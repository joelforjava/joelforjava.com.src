title=Testing: Using JUnit Rule(s) to Reduce the Usage of Mocking Frameworks
date=2018-08-10
type=post
tags=java,junit,junit4,junit47
status=published
~~~~~~

In a [previous post](/blog/2018/07/09/unit-testing-with-mockito-and-powermock.html), I wrote a unit test using JUnit 4.12 that unfortunately made use of what I believed to be unneeded uses of Mockito and PowerMockito. These tests were written with an earlier Junit 4 mindset, a mindset that was unaware of <a href="https://www.testwithspring.com/lesson/introduction-to-junit-4-rules/" rel="noopener" target="_blank">JUnit Rules</a>. Now that I've had some time to look around some, I'm going to rewrite the tests making use of the TemporaryFolder Rule.

The `TemporaryFolder` rule allows us to create folders and files that are deleted after a test is completed. I realize this is something that I could have likely done without the Rule and even prior to my mocking, but using the Rule makes it far easier to work with and performs the cleanup seamlessly.

All of the changes made are very similar and involve setting up a temporary file and writing to the file and then using it for the current test.

<!--more-->

<?prettify?>

    @Test
    public void testWithNoInfoEntries() throws Exception {
        // 1 - create temporary file using Rule
        File inFile = temporaryFolder.newFile("testIn.m3u");

        List<String> lines = new ArrayList<String>() {{
            add("#EXTM3U");
            add("M:\\Temp\\File.mp3");
            add("M:\\Temp\\File2.mp3");
            add("M:\\Temp\\File3.mp3");
        }};

        // 2 - write lines to the file
        try (BufferedWriter bw = new BufferedWriter(new FileWriter(inFile))) {
            for (String line : lines) {
                bw.write(line);
                bw.newLine();
            }
        }

        // 3 - convert file to Path and pass it to the service call
        Path p = inFile.toPath();

        M3UPlaylistProcessor processor = new M3UPlaylistProcessor();
        List<String> extracted = processor.extractURIs(p);

        Assert.assertEquals(3, extracted.size());
    }


The main differences are shown via comments in the previous code block. At the first point, we create the new temporary file using the TemporaryFolder Rule we've added to the test class. Secondly, we actually write the `lines` list to the file. Finally, we convert the file to a path object and send the path to the service. All Mockito and PowerMock references are removed! Making similar changes in each test that uses mocks will eliminate the need for them altogether.

There, of course, are perfectly good reasons to use mocks and even PowerMockito. However, at least for the tests written so far for this particular project, they were completely unnecessary.