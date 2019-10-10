title=Updating Legacy Code: Lambdas I
date=2018-09-28
type=post
tags=java,java8,legacy,carmix-creator
status=published
~~~~~~

Now that we've gone through and updated `carmix-creator` with all of the possible Java 7 updates, we can finally start looking at Java 8 and how we can make use of some of the constructs and other updates that Java 8 has to offer. For starters, we will see where we can make use of the biggest advancement to come to the language with the Java 8 release--lambda expressions.

## What is a Lambda Expression ##

A lambda expression is a representation of an anonymous function comprised of a set of parameters, the lambda operator (->) and a function body, which is optionally surrounded by curly braces. Prior to Java 8, you might have used an anonymous class to handle this work, but lambda expressions help make your code less verbose and they can help make your intent more clear.

<!--more-->

Lambda expressions are converted into functional interfaces, an interface that contains only one abstract method among one or more default or static methods.

While `carmix-creator` does not seem to make much use of code that would benefit from the use of lambdas, we can find a few places to update. For example:

<?prettify?>

    m3uFileSelectButton.setText("Select");
    m3uFileSelectButton.addActionListener(new java.awt.event.ActionListener() {
        public void actionPerformed(java.awt.event.ActionEvent evt) {
            m3uFileSelectButtonActionPerformed(evt);
        }
    });

Here, we are adding an `ActionListener` by creating an anonymous class. There are a couple of ways we could update this. But for the purpose of this post, we'll make use of lambda expressions since `ActionListener` is a functional interface.

<?prettify?>

    m3uFileSelectButton.setText("Select");
    m3uFileSelectButton.addActionListener(evt -> m3uFileSelectButtonActionPerformed(evt));

Considering all that the `m3uFileSelectButtonActionPerformed` method does is call another method, we could further update the lambda in the following way:

<?prettify?>

    m3uFileSelectButton.setText("Select");
    m3uFileSelectButton.addActionListener(evt -> selectPlaylistFile());

Now, if the `m3uFileSelectButtonActionPerformed` performed other work, we could still inline the method like so:

<?prettify?>

    m3uFileSelectButton.setText("Select");
    m3uFileSelectButton.addActionListener(evt -> {
        selectPlaylistFile();
        //someOtherMethodCall();
    });

However, if the `m3uFileSelectButtonActionPerformed` method was doing a lot of work, I'd probably just leave it alone. Since it's currently only calling `selectPlaylistFile()`, I'll use that version and get rid of the extra method.

We can make similar changes to all of the `addActionListener` calls.

Since the other button action listeners are all calling a methods that in turn call another method, we'll remove the 'wrapper' methods from these listeners and put the method call directly in the lambda expression. Of course, we may need to do more with button presses in the future, but I'm trying to be better about not writing any extra code until <a href="https://blog.codinghorror.com/the-best-code-is-no-code-at-all/" rel="noopener" target="_blank">it's absolutely needed</a>.

There is one other place we can make a change: in the `main` method.

<?prettify?>

    public static void main(String args[]) {
        java.awt.EventQueue.invokeLater(new Runnable() {
            public void run() {
                new CarMixCreatorGUI().setVisible(true);
            }
        });
    }

We can replace the `Runnable` anonymous class with a lambda in the following manner:

<?prettify?>

    public static void main(String args[]) {
        java.awt.EventQueue.invokeLater(() -> new CarMixCreatorGUI().setVisible(true));
    }

This has been a very brief overview of Lambda expressions as I've only begun to scratch the surface with how they can help make your code less verbose. I'm hoping to have something a bit more in depth in the future. In the meantime, I recommend checking out <a href="https://docs.oracle.com/javase/tutorial/java/javaOO/lambdaexpressions.html" rel="noopener" target="_blank">this tutorial</a> from Oracle, which shows how one can work toward making use of Lambda expressions.