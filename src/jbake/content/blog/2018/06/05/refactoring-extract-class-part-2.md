title=Refactoring: Extract Class (Part 2)
date=2018-06-05
type=post
tags=java,refactoring,carmix-collector
status=published
~~~~~~

In a previous [post](/blog/2018/05/29/refactoring-extract-class-part-1.html), I began refactoring the [carmix-collector](/blog/2018/04/19/introducing-carmix-collector-project.html) project. While its function is fairly simple, it had one class trying to do all the work which, among other things, makes the code terribly hard to test. In this post, I will be doing another refactoring that might take a minute to work out, but we will back up and try something new, if needed.

I start by creating a new playlist processor class, `M3UPlaylistProcessor`. Its purpose will be to process the selected playlist file. Inside the new class, I create a new method, `process` that will contain the body of the existing `processPlaylistPath` method from the GUI class. I think naming the method `process` is a bit better than `processPlaylistPath` since the class name makes 'Playlist' redundant and the `Path` method parameter makes it clear we are processing a Path.

If you try and compile this code (or are using an IDE), you'll notice an error: `Cannot resolve method 'processTrackURL'`. You'll probably also notice it doesn't recognize the Status enum either or the Strings used to denote the M3U header and info sections. Seems simple enough to just copy the processTrackURL method and other missing items from the GUI class and keep going.

<!--more-->

<?prettify?>

    public class M3UPlaylistProcessor {

        public Status process(Path path) {
            List<String> lines;
            try {
                lines = Files.readAllLines(path, StandardCharsets.ISO_8859_1);
                String firstLine = lines.remove(0);
                if (!M3U_HEADER.equals(firstLine)) {
                    LOGGER.log(Level.WARNING, "M3U Header Not Found. for file: " + path.toString());
                    return Status.INVALID_HEADER; // preferably, throw error
                }
                LOGGER.log(Level.INFO, "M3U Header Found");
                for (String s : lines) {
                    if (StringUtils.isBlank(s)) {
                        continue;
                    } else if (s.startsWith(M3U_INFO)) {
                        continue;
                        // processExtraInfo(s);
                    } else {
                        processTrackURL(s);
                    }
                }
            } catch (IOException e) {
                e.printStackTrace();
            }
            return Status.PROC_SUCCESSFULLY;

        }

        private void processTrackURL(String strLine) {
            Path source = Paths.get(strLine);
            if (Files.exists(source)) {
                // do stuff
                String albumName = "";
                String artistName = "";
                String fileName = source.getFileName().toString();
                String newFileName = this.getStrDestDirectoryName() + fileName;
                try {
                    if (usingArtistName) {
                        MP3File mp3File = new MP3File(source.toFile(), false);
                        ID3v1 tag = mp3File.getID3v1Tag();
                        artistName = tag.getArtist();

                        newFileName = this.getStrDestDirectoryName() + artistName + "\\" + fileName;
                    }
                    Path target = Paths.get(newFileName);
                    copyService.copy(source, target);
                    String strLogInfo = "Copied: " + strLine + "\n to " + newFileName;
                    setProgressInfoText(strLogInfo);
                    LOGGER.log(Level.INFO, strLogInfo);
                } catch (TagException | IOException ex) {
                    // Display new error message
                    ex.getMessage();
                    LOGGER.log(Level.SEVERE, null, ex);
                }
            } else {
                String strLogWarning = "File not found! - " + strLine;
                LOGGER.log(Level.WARNING, strLogWarning);
            }
        }

        private static final String M3U_HEADER = "#EXTM3U";
        private static final String M3U_INFO = "#EXTINF";

        private static final Logger LOGGER = Logger.getLogger(M3UPlaylistProcessor.class.getName());

        public enum Status {
            INVALID_HEADER,
            PROC_SUCCESSFULLY
        }

    }

However, I think I made things worse. While not immediately obvious above, I've inadvertently brought over other method calls and used fields specific to the GUI class, including that newly created copy service code. So, I remove the processTrackURL methods and leave the Strings and Status enum. What do I do next? I want to keep as much of this processing out of the main GUI class as possible, but it doesn't seem like I can do that without adding more parameters to the main process method, which doesn't seem right. And we don't want the copying to take place in this new class, it should let the GUI class control that service. And, the more I look at it, I realize it's trying to make calls to the GUI itself that handle the progress bar text. This approach won't work.

Maybe instead of 'processing' the M3U file, I could extract the File URIs and send them back to the GUI class? At that point, each String could be sent to the `processTrackURL` method in the GUI class and it should all work again. So, I'll create a new `extractURIs` method that will collect all of the URIs as Strings and send them back. This is what we end up with:

<?prettify?>

    public List<String> extractURIs(Path path) {
        List<String> extractedUris = new ArrayList<>();
        try {
            List<String> lines = Files.readAllLines(path, StandardCharsets.ISO_8859_1);
            String firstLine = lines.remove(0);
            if (!M3U_HEADER.equals(firstLine)) {
                LOGGER.log(Level.WARNING, "M3U Header Not Found. for file: " + path.toString());
                return Collections.emptyList();
            }
            LOGGER.log(Level.INFO, "M3U Header Found");
            for (String s : lines) {
                if (StringUtils.isBlank(s)) {
                    continue;
                } else if (s.startsWith(M3U_INFO)) {
                    continue;
                    // processExtraInfo(s);
                } else {
                    extractedUris.add(s);
                }
            }
        } catch (IOException e) {
            e.printStackTrace();
        }
        return extractedUris;
    }

The main changes are we no longer send back a `Status`, but a List of `String`s that represent the file locations we wish to copy. The call to `processTrackURL` now adds a line to the list that will be returned.

In the `CarMixCreatorGUI` class, I add the new `M3UPlaylistProcessor` class and make sure to initialize it in the constructor. The old `processPlaylistPath` then is changed to this:

<?prettify?>

    private Status processPlaylistPath(Path path) {
        List<String> lines = playlistProcessor.extractURIs(path);
        for (String line : lines) {
            processTrackURL(line);
        }
        return Status.PROC_SUCCESSFULLY;
    }

We now have a new processing class that takes care of extracting the relevant data from a selected M3U playlist. Things ended up a bit differently than I initially expected they would, but I think the direction the code is headed is in the right one. There's still other areas I want to consider for refactoring, but for now, I'll leave it alone. As always, these changes are in the GitHub [repo](https://github.com/joelforjava/carmix-collector/tree/7e6abebd6f6ee61ffd0932852e669976a092c019).

It appears the app still runs as expected, but it's hard to know for certain without tests to back it all up? Maybe I should get started on writing some tests. Until next time!