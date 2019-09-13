title=Updating from Grails Test Mixin Framework to Grails Testing Support Framework
date=2018-08-17
type=post
tags=groovy,grails,testing,grails testing support,ripplr
status=published
~~~~~~

In a [previous post](/blog/2018/07/16/updating-from-grails-3-1-9-to-grails-3-3-6.html), I upgraded my Ripplr application, which was using Grails 3.1.9 to version 3.3.6. One of the changes that have come with Grails 3.3 is the new Grails Testing Support framework, which makes heavy use of Groovy traits as opposed to the previous Test Mixin framework, which relied heavily on annotations and AST transformations.

Initially, I was not looking forward to updating test frameworks. However, during my first few refactorings, it has proven to be mostly worry free. For the most part, you're replacing Annotations with trait implementations. You may have to make some other small tweaks, but so far they have been quick to implement.

<!--more-->

For example, this is the `UserServiceSpec` test class using the test mixin framework:

<?prettify?>

    /* UserServiceSpec.groovy */

    @TestFor(UserService)
    @Mock([User, Profile])
    class UserServiceSpec extends Specification {
        // ... test methods
    }

This is the same test class after updating to the new testing support framework:

<?prettify?>

    /* UserServiceSpec.groovy */

    class UserServiceSpec extends Specification implements ServiceUnitTest<UserService>, DataTest {

        def setupSpec() {
            mockDomains(User, Profile)
        }
        // ... test methods
    }

You may notice that I implement another trait, `DataTest`. This <a href="https://testing.grails.org/latest/guide/index.html#unitTestingDomainClasses" rel="noopener" target="_blank">allows</a> the mocking of more than one domain class at a time. This trait comes with a method, mockDomains, which allows you to list the classes you wish to mock. For this test, I added the call to `mockDomains` from the `setupSpec` method. If you're only working with a single domain class, you could replace the `DataClass` trait with the `DomainUnitTest` trait instead.

One issue that has arisen for me is working with Command objects and validating them during unit tests. I'll get the following error any time I call validate() on a command object that both implements Validateable and has a constraints block:

    java.lang.IllegalArgumentException: Class [com.joelforjava.ripplr.UserRegisterCommand] is not a domain class

I suspect this is due, at least in part, to the omission of the <a href="https://docs.grails.org/3.2.x/api/grails/test/mixin/web/ControllerUnitTestMixin.html#mockCommandObject(java.lang.Class)">`mockCommandObject`</a> method from the Test Mixin framework. This method provided the command objects with the required validation behavior during unit testing. If I try to instantiate the class without the mockCommandObject method (e.g. calling new), I also get the error.

A test in the Grails guide <a href="http://guides.grails.org/grails-controller-testing/guide/index.html#unitTestSave" rel="noopener" target="_blank">here</a> shows the use of the params object instead of the command object, and I tried to make use of this style of testing, but I still see the error message with the following test:

<?prettify?>

    /* UserControllerSpec.groovy */
    def 'Calling update with an invalid command object results in being sent back to the update page'() {
        given: 'invalid params'
            params.username = 'obviously-real-username'

        and: 'we have the form token set'
            def tokenHolder = SynchronizerTokensHolder.store(session)
            params[SynchronizerTokensHolder.TOKEN_URI] = '/user/updateProfile'
            params[SynchronizerTokensHolder.TOKEN_KEY] =
            tokenHolder.generateToken(params[SynchronizerTokensHolder.TOKEN_URI])

        when: 'the new update action is invoked'
            controller.updateProfile()

        then: 'we are sent back to the update page'
            view == 'update'

        and: 'we get the command object sent back to us'
            model.user
    }

The trick that worked for me regarding the majority of the tests was moving the Command object-specific tests into their own spec class. These tests all passed with no problem. However, the other tests fail when I am verifying that a command object is valid/invalid for specific tests, such as the previous version of the test above. So, I did what any normal person does; I deleted the calls to validate()! Of course, this didn't work out very well. I ended up with various other errors. Most of these errors were regarding invalid command object scenarios. Since I was unable to call `validate()`, then the call to `hasErrors()` would never trigger, therefore causing other issues during tests.

I did have a few places where the call to validate() was unnecessary, such as testing form submissions without the token. However, there was one test where I needed to trigger `hasErrors()` to return true (e.g. the previously displayed test from UserControllerSpec). With the old test framework, I'd create a mock command object and leave it mostly empty, thus rendering it invalid. That doesn't work now nor does creating a new object. The error message stating that the class isn't a domain class rears its ugly head. So, my last resort, at least for now, is to make a `Spy` of the `UserUpdateCommand` object so that I can set the username value and also mock out the call to `hasErrors()` to return true.

This will turn the test into this:

<?prettify?>

    /* UserControllerSpec.groovy */
    def 'Calling update with an invalid command object results in being sent back to the update page'() {
        given: 'an invalid command object'
            def uuc = Spy(UserUpdateCommand) {
                1 * hasErrors() >> true
            }
            uuc.username = 'obviously-real-username'

        and: 'we have the form token set'
            def tokenHolder = SynchronizerTokensHolder.store(session)
            params[SynchronizerTokensHolder.TOKEN_URI] = '/user/updateProfile'
            params[SynchronizerTokensHolder.TOKEN_KEY] =
            tokenHolder.generateToken(params[SynchronizerTokensHolder.TOKEN_URI])

        when: 'the new update action is invoked'
            controller.updateProfile()

        then: 'we are sent back to the update page'
            view == 'update'

        and: 'we get the command object sent back to us'
            model.user
    }

Not my ideal solution, but it works. And I'm not proud of it.

For the remainder of the command object testing, I plan on writing tests that will verify that the objects created by `CommandObjectDataFactory` are indeed valid so that when they are used in other tests, we can be assured that they really are valid command objects!

Beyond these initial hurdles, I do not seem to be having any other issues with upgrading to Grails Testing Framework. Here's to hoping it will stay that way but I'll be sure to either update this post or write a new one if anything else goes horribly wrong!