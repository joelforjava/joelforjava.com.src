title=Updating Legacy Code, Part III: Switch with Strings
date=2018-05-10
type=post
tags=java,java 7,nio.2,legacy,carmix-creator
status=published
~~~~~~

The past few posts have been going over some of the improvements that came with updating to Java 7. This article will showcase how to use strings in a switch statement using the [carmix-creator](/blog/2018/04/19/introducing-carmix-collector-project.html) project.

Prior to Java 7, you had to use constants of type `Byte`, `Character`, `Short`, `Integer` constants (or their primitive equivalents) or `enum`s as values for the cases in a `switch` statement. Personally, I think this is the way to go, but it isn't always possible and I'm glad they made the change. The majority of my past projects made minimal use of `enum` or `Integer`/`int` constants. They relied heavily on Strings, so this change would help make an endless sea of if statements look a little bit better. Even in my own code, I've only started to embrace enums, but it'll be a while before I get to writing about all that.

<!--more-->

The carmix-creator project has a method called `verifyFile`. It makes use of several `if` statements. It can be cleaned up some by switching some of the `if` statements with `switch` statements. Prior to Java 7, you could only use a switch statement with an integer or enumerated type. But now, we can use strings.

As an example of a method that could make use of this construct, here is the old version of the verifyFile method:

<?prettify?>

    private boolean verifyFile(File aFile, String indFileDir, String indReadWrite) throws IOException {
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
        } else if (WRITE_FILE.equals(indReadWrite)) {
            if (!aFile.canWrite()) {
                throw new IOException("File Verification: Cannot write to file " + aFile.getPath());
            }
        }
        return true;
    }

Updated:

<?prettify?>

    private boolean verifyFile(File aFile, String indFileDir, String indReadWrite) throws IOException {
        if (!aFile.exists()) {
            throw new IOException("File Verification: " + aFile.getPath() + " does not exist");
        }
        switch (indFileDir) {
        case FILE_TYPE:
            if (!aFile.isFile()) {
                throw new IOException("File Verification: " + aFile.getPath() + " does not exist");
            }
            break;
        case DIR_TYPE:
            if (!aFile.isDirectory()) {
                throw new IOException("Directory Verification: " + aFile.getPath() + " does not exist");
            }
            break;
        default :
            break;
        }
        switch (indReadWrite) {
        case READ_FILE:
            if (!aFile.canRead()) {
                throw new IOException("File Verification: Cannot read file " + aFile.getPath());
            }
            break;
        case WRITE_FILE:
            if (!aFile.canWrite()) {
                throw new IOException("File Verification: Cannot write to file " + aFile.getPath());
            }
            break;
        default :
            break;
        }
        return true;
    }

If you're interested, I did manage to make some other changes to this method by using the NIO.2 classes. These updates can be seen in [GitHub](https://github.com/joelforjava/carmix-collector/blob/97db0b9cc7eb0b70491b221a7c219d71d711b22a/src/main/java/com/joelforjava/CarMixCreatorGUI.java).

Switch with strings may seem like a small change, but I can think of at least a dozen places it might be useful in some of the legacy code with which I have worked and I imagine most everyone could think of at least one area in which it would improve the code to some degree.
