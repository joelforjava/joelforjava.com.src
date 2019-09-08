title=Refactoring: Extract Class (Part 1)
date=2018-05-29
type=post
tags=java,refactoring,carmix-collector
status=published
~~~~~~

Refactoring is an important step in the software development process. It should be practiced early and often to help maintain and improve code quality over time. Of course, we're all guilty of putting this off when deadlines and management expectations force us to choose between just having something working on time or improving upon your existing code while writing new functionality. If we're lucky, we're able to go back and refactor the code before the project is over, but it must be done with great care to ensure that we do not break any of the existing functionality. This is where it would be important to have an existing test suite to verify everything runs as expected before and after refactoring.

<!--more-->

In my case, if you look at the [carmix-creator](https://github.com/joelforjava/carmix-collector/tree/b83078b18e6040f6b07b970c2662f312f6070906) project, I have a monolithic class that extends `JFrame`, which does not make it easy to test all of the moving parts separately. I want to get this project to that point, so in order to do that I need to carefully refactor some of the functionality out into a separate class. A class should not take on more responsibilities than required. There are several areas of this class we could look at for refactoring purposes, including the parsing of the M3U files and copying files. The GUI class should focus on displaying the form and leave the rest of the work to other classes. For starters, I'll be refactoring out the copy functionality into a new class whose sole purpose is to handle copying files.

Once the copy functionality is in its own class, it should be easier to test. There are several options on how we could refactor the copy functionality. We could create a utility-type class and give it a static copy function, however, I try to refrain from creating utility/helper-type classes as much as possible. For now, I'll create a new class `CopyFileService.java` and move the whole copy method over to this class. If you're using an IDE like Eclipse or Intellij, you'll probably notice that this method depends on another method, `verifyFile`. We should go ahead and move this method over as well.

Here's a brief view of how the new class looks:

<?prettify?>

    public class CopyFileService {
        public void copy(Path inPath, Path outPath) throws IOException {
            // ... original method body goes here ...
        }

        private static boolean verifyFile(Path aPath, String indFileDir, String indReadWrite) throws IOException {
            // ... original method body goes here ...
        }
    }

Now, we'll need to create an instance of the `CopyFileService` inside the GUI class and replace the call to the copy method within processTrackURL with a call to the CopyFileService method.

Before:

<?prettify?>

    copy(source, target);

After:

<?prettify?>

    private CopyFileService copyService = new CopyFileService();

<?prettify?>

    copyService.copy(source.target);

We could take this first refactoring a bit further and create an interface for the newly created `CopyFileService` to implement, but for now, I'll leave it be.

The next thing to be refactored will be the playlist processing methods, but that will come in a later article because this refactoring will have the potential to change how the program processes the data and is deserving of an article all its own. We'll also start looking into writing some tests to help make sure everything is working the way it is expected to. Keep an eye out for those in the coming days and weeks. These changes are located in the GitHub [repo](https://github.com/joelforjava/carmix-collector/tree/8431630ab64bb60542b37240267cdb52eb1e70f6).

So, this has been a first attempt at refactoring, more specifically the technique called [Extract Class](https://refactoring.com/catalog/extractClass.html). I hope it has proved useful if you're new to refactoring or just needed a quick refresher for this particular technique.