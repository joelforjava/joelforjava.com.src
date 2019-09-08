title=Refactoring: Replace Parameter With Explicit Methods
date=2018-09-21
type=post
tags=java,refactoring,carmix-creator
status=published
~~~~~~

As I continue to refactor and refine my <a href="/blog/2018/04/19/introducing-the-carmix-collector-project.html">carmix-collector</a> project, I've come across a method that I really don't like. It looks too busy and depends on two separate parameters to determine what work should be done inside the method. Here's the method as it currently exists:

<?prettify?>

    private static boolean verifyFile(Path aPath, String indFileDir, String indReadWrite) throws IOException {
        if (!Files.exists(aPath)) {
            throw new IOException("File Verification: " + aPath.getFileName() + " does not exist");
        }

        switch (indFileDir) {
            case FILE_TYPE:
                if (!Files.isRegularFile(aPath)) {
                    throw new IOException("File Verification: " + aPath.getFileName() + " does not exist");
                }
                break;
            case DIR_TYPE:
                if (!Files.isDirectory(aPath)) {
                    throw new IOException("Directory Verification: " + aPath.getFileName() + " does not exist");
                }
                break;
        }

        switch (indReadWrite) {
            case READ_FILE:
                if (!Files.isReadable(aPath)) {
                    throw new IOException("File Verification: Cannot read file " + aPath.getFileName());
                }
                break;
            case WRITE_FILE:
                if (!Files.isWritable(aPath)) {
                    throw new IOException("File Verification: Cannot write to file " + aPath.getFileName());
                }
                break;
            }
        return true;
    }

What we should do is create a new method for each possible parameter value. We should use the <a href="https://refactoring.com/catalog/replaceParameterWithExplicitMethods.html" rel="noopener" target="_blank">Replace Parameter With Explicit Methods</a> refactoring.

<!--more-->

In the case of this method, we have two parameters that each have two possible values, so we will introduce four methods, two that handle the possible values of `indFileDir` and two that handle the cases of `indReadWrite`. We will refactor this method by removing one parameter at a time, starting with `indReadWrite`. For `verifyFile`, `indReadWrite` is an indicator that states whether we should check if a path is readable or if it is writable. So, we should create two methods, `canRead` and `canWrite`. Their implementation follows.

<?prettify?>

    private static boolean canRead(Path path) throws IOException {
        if (!Files.isReadable(path)) {
            throw new IOException("File Verification: Cannot read file " + aPath.getFileName());
        }
        return true;
    }

    private static boolean canWrite(Path path) throws IOException {
        if (!Files.isWritable(path)) {
            throw new IOException("File Verification: Cannot write to file " + aPath.getFileName());
        }
        return true;
    }

At this point, we should add their usages to where `verifyFile` is called:

<?prettify?>

    public void copy(Path inPath, Path outPath) throws IOException {
        // ...
        verifyFile(inPath FILE_TYPE, READ_FILE);
        canRead(inPath);

        if (Files.exists(outPath)) {
            // ...
        } else {
            // ...
            verifyFile(inPath, FILE_TYPE, WRITE_FILE);
            canWrite(outPath);
        }
    }

Now we need to take care of the other indicator parameter, `indFileDir`. In this case we're using the parameter to indicate if the path refers to a file or a directory. In this case, we should create new methods reflecting this usage, such as isFile or isDirectory.

<?prettify?>

    public static boolean isFile(Path path) throws IOException {
        if (!Files.isRegularFile(path)) {
            throw new IOException("File Verification: " + aPath.getFileName() + " does not exist");
        }
        return true;
    }

    public static boolean isDirectory(Path path) throws IOException {
        if (!Files.isDirectory(path)) {
            throw new IOException("Directory Verification: " + aPath.getFileName() + " does not exist");
        }
        return true;
    }

Now, we can just replace the remaining calls to `verifyFile` to the corresponding calls to `isFile` or `isDirectory` and then get rid of the `verifyFile` method. We really only need to use `isFile` as we were never actually checking directories anyway, so it's gone too. Also, you may notice we didn't replace the 'exists' functionality that was present at the top of `verifyFile`. The check was redundant as several calls within the Files class check for existence, including `isReadable` and `isWritable`.

And, there we have it, a basic exercise in implementing the 'Replace parameter with explicit method' refactoring. The smaller methods are more explicit and help get across what we're trying to accomplish with calling each of them and it removes the need for a couple of confusing indicator Strings to dictate method flow.

<aside>
After thought: In the updated code, there's a problem with the call to `canWrite`. If you notice the accompanying call to `verifyFile` it uses `inPath`, where it should be calling `outPath`. However, using `outPath` causes no files to be copied. It's a bug I'll need to come back and figure out at a later time and is likely related to what I just mentioned about checking for existence in the call to `isWritable`. For the time being, I'll leave the call to `canWrite` commented out and will likely remove it in the future since it really doesn't make much sense to check if a non-existing file can be written to.
</aside>