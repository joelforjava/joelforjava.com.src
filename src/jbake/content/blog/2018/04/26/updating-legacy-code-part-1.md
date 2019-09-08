title=Updating Legacy Code, Part I: Try with Resources
date=2018-04-26
type=post
tags=java,java 7,try with resources,legacy,carmix-creator
status=published
~~~~~~

So, Java 7 has been out for a quite a while now, but my corporate career had yet to expose me to anything newer than Java 6 at the time I originally wrote this. Even now, as of April 2018, I have yet to work with Java 8 in an enterprise setting. So, I took it upon myself at the time to learn some of the updates to the Java language in this version before starting to look at the changes in Java 8 (and now Java 9 and 10!).

Java 7 brought several key improvements to the language. Some of these improvements I will be covering include:

 - Try-with-resources
 - New File IO (NIO.2)
 - The ability to use strings in a switch statement
 - The ability to handle multiple exceptions in one catch block

 For this article, we are highlighting try-with resources and how this change can be applied to pre-Java 7 code. To showcase these improvements, I will be using the [carmix-creator](/blog/2018/04/19/introducing-carmix-collector-project.html). It has several areas that are in dire need of the Java 7 improvements.

 <!--more-->

 ## First of all, what is "try-with-resources"? ##

 Try-with-resources (TWR) is a mechanism that allows for the automatic closing of resources used within a typical `try/catch/finally` block. Rather than initializing a variable in the following manner:

<?prettify?>

    // ...
    BufferedReader br = null;
    try {
        br = new BufferedReader(new FileReader(file));
        // ...
    } finally {
        br.close();
    }
    // ...

You initialize the variable beside the declaration of the `try` block similar to below:

<?prettify?>

    // ...
    try(BufferedReader br = new BufferedReader(new FileReader(file))) {
        // ...
    }

### Example 1 - processPlaylistFile ###

For carmix-creator, there are a couple of places we can apply this. First, let's look at the `processPlaylistFile` method. It has a `try/catch/finally` block similar to the one above:

<?prettify?>

    private Status processPlaylistFile(File file) {
        try {
            BufferedReader input = new BufferedReader(new FileReader(file));
            String strLogInfo = "";

            try {
                String firstLine = input.readLine();
                String nextLine = null;

                // ... elided ...

                boolean keepReading = true;
                do {
                    nextLine = input.readLine();
                    if (nextLine == null) {
                        keepReading = false;
                    } else if ("".equals(nextLine)) {
                        continue;
                    } else if (nextLine.startsWith(M3U_INFO)) {
                        //processExtraInfo(nextLine);
                    } else { // This should be a File URL
                        processTrackURL(nextLine);
                    }
                } while (keepReading);
            } finally {
                input.close();
            }
        } catch (FileNotFoundException fnfe) {
            fnfe.printStackTrace();
        } catch (IOException ioe) {
            ioe.printStackTrace();
        }

        return Status.PROC_SUCCESSFULLY;
    }

The inner `try/finally` in this code is exactly the thing TWR is meant to replace. While we're at it, let's refactor this to be a single `try/catch` block.

Here is the updated version:

<?prettify?>

    private Status processPlaylistFile(File file) {
        try(BufferedReader input = new BufferedReader(new FileReader(file))) {

            String strLogInfo = "";

            String firstLine = input.readLine();
            String nextLine = null;

            // ... elided ...

            boolean keepReading = true;
            do {
                nextLine = input.readLine();
                if (nextLine == null) {
                    keepReading = false;
                } else if ("".equals(nextLine)) {
                    continue;
                } else if (nextLine.startsWith(M3U_INFO)) {
                    //processExtraInfo(nextLine);
                } else { // This should be a File URL
                    processTrackURL(nextLine);
                }
            } while (keepReading);

        } catch (FileNotFoundException fnfe) {
            fnfe.printStackTrace();
        } catch (IOException ioe) {
            ioe.printStackTrace();
        }

        return Status.PROC_SUCCESSFULLY;
    }

Notice that the <code>BufferedReader</code> resource is now declared inside parentheses beside the try keyword. I also removed the `finally` block since TWR will automatically close anything that is initialized in the `try`. This call to close will propagate to the inner `FileReader` and close it as well. Resources will be closed from the inside out.

There is a minor issue with this solution, however. If the `BufferedReader` constructor throws an exception then the `FileReader` will not be closed. There are several [solutions](https://stackoverflow.com/questions/12552863/correct-idiom-for-managing-multiple-chained-resources-in-try-with-resources-bloc) we could go with. However, I prefer to break out the `FileReader` into a separate variable in order to make try-with-resources aware of it. TWR will close the `FileReader` properly if there are any issues while calling the `BufferedReader` constructor. Resources will be closed in the opposite order in which they are listed.

<?prettify?>

    private Status processPlaylistFile(File file) {
        try(FileReader fileReader = new FileReader(file);
            BufferedReader input = new BufferedReader(fileReader)) {

            // .. same as before ..

        } catch (FileNotFoundException fnfe) {
            fnfe.printStackTrace();
        } catch (IOException ioe) {
            ioe.printStackTrace();
        }

        return Status.PROC_SUCCESSFULLY;
    }

Whether or not this is actually an issue depends on the code itself and whether or not you expect the code to keep going when an exception is thrown. As the code currently is, all that is being done is printing the stack trace to the console and then we keep going. In this case, we will be better off with the separate `FileReader` variable.

### Example 2 - copy ###

The copy method is another that could use a refresh to use TWR. Since we're copying, this time we are working with both an `InputStream` and an `OutputStream`:

<?prettify?>

    public static void copy(File inFile, File outFile) throws IOException {

        // ... elided ...

        InputStream in = null;
        OutputStream out = null;

        // ... elided ...

        try {
            in = new BufferedInputStream(new FileInputStream(inFile));
            out = new BufferedOutputStream(new FileOutputStream(outFile));
            byte[] buffer = new byte[4096];
            int bytesRead;
            while ((bytesRead = in.read(buffer)) != -1){
                out.write(buffer, 0, bytesRead);
            } // write
        } catch (IOException e) {
            e.printStackTrace();
        } finally {
            if (in != null) {
                try {
                    in.close();
                } catch (Exception e) {
                }
            }
            if (out != null) {
                try {
                    out.close();
                } catch (Exception e) {
                }
            }
        }
    }

And here is the the updated version:

<?prettify?>

    public static void copy(File inFile, File outFile) throws IOException {

        // ... elided ...

        try(FileInputStream fis = new FileInputStream(inFile);
            FileOutputStream fos = new FileOutputStream(outFile);
            InputStream in = new BufferedInputStream(fis);
            OutputStream out = new BufferedOutputStream(fos)) {
            byte[] buffer = new byte[4096];
            int bytesRead;
            while ((bytesRead = in.read(buffer)) != -1){
                out.write(buffer, 0, bytesRead);
            } // write
        } catch (IOException e) {
        e.printStackTrace();
        }
    }

I chose to break out the creation of each inner stream into a separate variable so that TWR will close them all correctly. As mentioned above, this isn't required but could be beneficial if any of the outer streams' constructors throw an exception.

There is more to Try-with-resources than what we have seen here. We also have the presence of enhanced stack traces and suppressed exceptions. Prior to Java 7, exceptions may end up swallowed when handling resources. This is still possible with TWR, but now the stack traces have been enhanced to allow you to see these exceptions that would otherwise be lost.

Java 7 also introduced the [AutoClosable](https://docs.oracle.com/javase/7/docs/api/java/lang/AutoCloseable.html) interface, which is now used by many Java built-in classes, including many listed here, to allow a class to be automatically closed by the try-with-resources construct. If you want to use your resource with try-with-resources, you'll need to implement this interface.

I am a big fan of TWR and try to make use of it whenever it's needed. If at all possible, I think it's best to use it and avoid handling the closing resources manually.