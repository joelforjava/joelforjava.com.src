title=Updating Legacy Code, Part II: NIO.2
date=2018-05-03
type=post
tags=java,java 7,nio.2,legacy,carmix-creator
status=published
~~~~~~

In a previous post, we updated legacy Java 5 code to use try-with-resources. In this post, we will be updating that same legacy code to use the new to Java 7 NIO.2 enhancements.

Java's NIO.2 is a set of new classes and methods that predominantly live in the `java.nio` package. It is intended to be a replacement of `java.io.File` as the abstraction when dealing with code that reads or writes from a filesystem.

The starting point for using NIO.2 is the `Path`. The `Path` class contains various methods for interacting with the path and extracting information about it. For the [carmix-creator](/blog/2018/04/19/introducing-carmix-collector-project.html) application, we will replace all uses of the `File` class and replace them with `Path` and other new classes and methods from the `java.nio.file` package.

Since carmix-creator copies files, it makes heavy use of several `File`-related classes. For starters, the `loadPlaylistFile` method can be refactored into a new method `loadPlaylistPath`.

<!--more-->

Here is the original. It simply creates a `File` object based on the strFilePath parameter.

<?prettify?>

    private File loadPlaylistFile(String strFilePath) {
        File playlistFile = null;
        if (strFilePath != null &amp;&amp; !strFilePath.equals("")) {
            playlistFile = new File(strFilePath);
        }

        return playlistFile;
    }

This is the updated version. Here we've replaced the direct `File` object creation with a call to `Paths.get` to obtain a reference to the file path and that result is loaded into a `java.nio.file.Path` object.

<?prettify?>

    private Path loadPlaylistPath(String strPathName) {
        Path playlistPath = null;
        if (strPathName != null &amp;&amp; !strPathName.equals("")) {
            playlistPath = Paths.get(strPathName);
        }

        return playlistPath;
    }

We next refactor `processPlaylistFile` into the new `processPlaylistPath` method. Here is how the method looked originally:

<?prettify?>

    private void processPlaylistFile(File filePlaylist) {

        BufferedReader input = null;
        try {
            input = new BufferedReader(new FileReader(filePlaylist));
            String firstLine = input.readLine();
            String nextLine = null;
            if (!M3U_HEADER.equals(firstLine)) {
                return;
            }
            LOG.log(Level.INFO, "Header Found");
            boolean keepReading = true;
            do {
                nextLine = input.readLine();
                if (nextLine == null) {
                    keepReading = false;
                } else if ("".equals(nextLine)) {
                    continue;
                } else if (nextLine.startsWith(M3U_INFO)) {
                    continue;
                } else { // This should be a File URL
                    processTrackURL(nextLine);
                }
            } while (keepReading);
        } catch (FileNotFoundException fnfe) {
            LOG.log(Level.SEVERE, null, fnfe);
        } catch (IOException ioe) {
            LOG.log(Level.SEVERE, null, ioe);
        } finally {
            try {
                input.close();
            } catch (IOException ex) {
                LOG.log(Level.SEVERE, null, ex);
            }
        }
    }

The refactored method:

<?prettify?>

    private Status processPlaylistPath(Path path) {
        try {
            List&lt;String&gt; lines = Files.readAllLines(path, StandardCharsets.ISO_8859_1);
            String firstLine = lines.remove(0);
            if (!M3U_HEADER.equals(firstLine)) {
                LOGGER.log(Level.WARNING, "M3U Header Not Found. for file: " + path.toString());
                return Status.INVALID_HEADER;
            }
            LOGGER.log(Level.INFO, "M3U Header Found");
            for (String s : lines) {
                if (StringUtils.isBlank(s)) {
                    continue;
                } else if (s.startsWith(M3U_INFO)) {
                    continue;
                } else {
                    processTrackURL(s);
                }
            }
        } catch (IOException e) {
            e.printStackTrace();
        }
        return Status.PROC_SUCCESSFULLY;

    }

We first replaced the `File` parameter with a `Path` parameter. Next, we read in the lines of the file represented by the `Path` using the new `Files.readAllLines` static method. This method also ensures the file is closed once the data is read or if there are any exceptions while the file is being read. We no longer have to read a file line by line using a `BufferedReader`!

The `processTrackURL` method can replace the call to the private method copy to the new `Files.copy` method. We can also replace the `checkFileOrDirectoryExists` call with `Files.exists`.

Original:

<?prettify?>

    private void processTrackURL(String strLine) {
        if (checkFileOrDirectoryExists(strLine)) {
            File inFile = new File(strLine);
            String fileName = inFile.getName();
            String newFileName = strMixDirectoryPath + fileName;
            try {
                if (usingArtistName) {
                    MP3File mp3File = new MP3File(source.toFile(), false);
                    ID3v1 tag = mp3File.getID3v1Tag();
                    artistName = tag.getArtist();

                    newFileName = this.getStrDestDirectoryName() + artistName + "\\" + fileName;
                } else {
                    newFileName = this.getStrDestDirectoryName() + fileName;
                }
                File outFile = new File(newFileName);
                copy(inFile, outFile);
            } catch (IOException ex) {
                LOG.log(Level.SEVERE, null, ex);
            }
            LOG.log(Level.INFO, "File {0} located!", strLine);
        } else {
            LOG.log(Level.SEVERE, "File {0} not found!", strLine);
        }
    }

New:

<?prettify?>

    private void processTrackURL(String strLine) {
        Path source = Paths.get(strLine);
        if (Files.exists(source)) {
            String artistName = "";
            String fileName = source.getFileName().toString();
            String newFileName = strMixDirectoryPath + fileName;
            try {
                if (usingArtistName) {
                    MP3File mp3File = new MP3File(source.toFile(), false);
                    ID3v1 tag = mp3File.getID3v1Tag();
                    artistName = tag.getArtist();

                    newFileName = this.getStrDestDirectoryName() + artistName + "\\" + fileName;
                }
                Path target = Paths.get(newFileName);
                Files.copy(source, target, COPY_ATTRIBUTES, REPLACE_EXISTING);
            } catch (IOException ex) {
                LOG.log(Level.SEVERE, null, ex);
            }
            LOG.log(Level.INFO, "File {0} located!", strLine);
        } else {
            LOG.log(Level.SEVERE, "File {0} not found!", strLine);
        }
    }

At a glance, it seems like we no longer need the private `copy` method. If you run the application and try copying without using the artist names, it will copy fine. However, when you select to have the files copied into folders by artist, then the copy fails due to a `java.nio.file.NoSuchFileException` on the target. Turns out, for the moment at least, we need the `copy` method after all since it took care of creating the artist folders. We can still make improvements to this private `copy` method, though.

So, we revert the call to `Files.copy` back to the private method call, updated to take `Path`s instead of `File`s. Within this method, we will call `Files.copy`. We also make a few updates to make use of additional methods in the `Files` class.

Before:

<?prettify?>

    public static void copy(File inFile, File outFile) throws IOException {

        if (inFile.getCanonicalPath().equals(outFile.getCanonicalPath())) {
            // inFile and outFile are the same;
            // hence no copying is required.
            LOGGER.log(Level.INFO, "Files are the same, no copy performed");
            return;
        }

        verifyFile(inFile, FILE_TYPE, READ_FILE);

        if (outFile.isDirectory()) {
            outFile = new File(outFile, inFile.getName());
        }

        if (outFile.exists()) {
            if (!outFile.canWrite()) {
                throw new IOException("Cannot write to: " + outFile);
            }
            // This should become a prompt for the GUI
            System.out.print("Overwrite existing file " + outFile.getName() + "? (Y/N): ");
            System.out.flush();
            BufferedReader promptIn = new BufferedReader(new InputStreamReader(System.in));
            String response = promptIn.readLine();
            if (!response.toUpperCase().equals("Y")) {
                throw new IOException("FileCopy: " + "existing file was not overwritten.");
            }
        } else {
            File dirFile = outFile.getParentFile();

            if (dirFile != null &amp;&amp; (!dirFile.exists())) {
                if (!dirFile.mkdirs()) {
                    if(!dirFile.exists()) {
                        throw new IOException("Cannot create directory: " + dirFile);
                    }
                }
            }

            // check for exists, isFile, canWrite
            verifyFile(inFile, FILE_TYPE, WRITE_FILE);
        }

        try(FileInputStream fis = new FileInputStream(inFile);
            FileOutputStream fos = new FileOutputStream(outFile);
            InputStream in = new BufferedInputStream(fis);
            OutputStream out = new BufferedOutputStream(fos)) {
            byte[] buffer = new byte[4096];
            int bytesRead;
            while ((bytesRead = in.read(buffer)) != -1){
                out.write(buffer, 0, bytesRead);
            } // write
        }
    }

After:

<?prettify?>

    public static void copy(Path inPath, Path outPath) throws IOException {

        if (Files.exists(outPath) &amp;&amp; Files.isSameFile(inPath, outPath)) {
            LOGGER.log(Level.INFO, "Files are the same, no copy performed");
            return;
        }

        verifyFile(inPath, FILE_TYPE, READ_FILE);

        if (Files.exists(outPath)) {
            if (!Files.isWritable(outPath)) {
                throw new IOException("Cannot write to: " + outPath);
            }
        } else {
            Path parentDirectory = outPath.getParent();
            if (!Files.exists(parentDirectory)) {
                Files.createDirectories(parentDirectory);
            if (!Files.exists(parentDirectory)) {
                throw new IOException("Cannot create directory: " + parentDirectory);
            }
        }

        // check for exists, isRegularFile, canWrite
        verifyFile(inPath, FILE_TYPE, WRITE_FILE);
        }
        Files.copy(inPath, outPath, COPY_ATTRIBUTES, REPLACE_EXISTING);
    }

There is more work that could be done to this method, but I will leave that to future post(s) that discuss refactoring.

Since we're making use of the copy method, we'll have to update the `verifyFile` method to take `Path`s instead of `File`s.

Here's the method pre-`Path`:

<?prettify?>

    private static boolean verifyFile(File aFile, String indFileDir, String indReadWrite) throws IOException {
        if (!aFile.exists()) {
            throw new IOException("File Verification: " + aFile.getPath() + " does not exist");
        }
        if (FILE_TYPE.equals(indFileDir)) {
            if (!aFile.isFile()) {
                throw new IOException("File Verification: " + aFile.getPath() + " does not exist");
            }
        } else if (DIR_TYPE.equals(indFileDir)) {
            if (!aFile.isDirectory()) {
                throw new IOException("Directory Verification: " + aFile.getPath() + " does not exist");
            }
        }
        if (READ_FILE.equals(indReadWrite)) {
            if (!aFile.canRead()) {
                throw new IOException("File Verification: Cannot read file " + aFile.getPath());
            }
        } else if (WRITE_FILE.equals(indReadWrite)){
            if (!aFile.canWrite()) {
                throw new IOException("File Verification: Cannot write to file " + aFile.getPath());
            }
        }
        return false;
    }

And here it is refactored to use the Path and Files classes:

<?prettify?>

    private static boolean verifyFile(Path aPath, String indFileDir, String indReadWrite) throws IOException {
        if (!Files.exists(aPath)) {
            throw new IOException("File Verification: " + aPath.getFileName() + " does not exist");
        }
        if (FILE_TYPE.equals(indFileDir)) {
            if (!Files.isRegularFile(aPath)) {
                throw new IOException("File Verification: " + aPath.getFileName() + " does not exist");
            }
        } else if (DIR_TYPE.equals(indFileDir)) {
            if (!Files.isDirectory(aPath)) {
                throw new IOException("Directory Verification: " + aPath.getFileName() + " does not exist");
            }
        }
        if (READ_FILE.equals(indReadWrite)) {
            if (!Files.isReadable(aPath)) {
                throw new IOException("File Verification: Cannot read file " + aPath.getFileName());
            }
        } else if (WRITE_FILE.equals(indReadWrite)){
            if (!Files.isWritable()) {
                throw new IOException("File Verification: Cannot write to file " + aPath.getFileName());
            }
        }
        return true;
    }

The updated verifyFile method helps to show how you check file properties when working with `Path`s. The `Files` class has many static methods that can be used, including checking for the existence of a file or checking whether or not a file can be read or written to. Many more methods live in this class to help you work with files.

And this should wrap up updating the carmix-creator to use Java 7 NIO.2, where applicable to the application. There is far more to NIO.2 than has been shown here and I urge you to all go give it a try if you haven't already. NIO.2 changes don't stop here. Thanks to the Streams API in Java 8, there will be new things to try with that as well.