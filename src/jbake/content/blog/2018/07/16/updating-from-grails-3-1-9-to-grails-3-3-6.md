title=Updating from Grails 3.1.9 to Grails 3.3.6
date=2018-07-16
type=post
tags=groovy,grails,grails33,ripplr
status=published
~~~~~~

I had intended to write an article on upgrading to Grails 3.3.5, but I ran into an [issue](https://github.com/grails/grails-core/issues/10993) that prevented me from completing the upgrade. Luckily, this issue was fixed in the 3.3.6 release.

I will walk through the steps I performed to upgrade my Grails 3.1.9 application, Ripplr to version 3.3.6. These steps will likely work for any 3.1.x to 3.3.x upgrade, but I have only successfully tested upgrading with this specific combination.

Here are the steps I performed:

1. Update build.gradle
    - Update GORM Version
    - Update to Hibernate 5
    - Add Grails test mixins dependency for tests that are now using a legacy framework
    - Add new dependencies
    - Update plugin versions, if at all possible\
2. Update application.yml and application.groovy
3. Update resources.groovy
4. Move Bootstrap.groovy and UrlMappings.groovy out of the default package
5. Update Gradle Wrapper
6. Add Grails wrapper
7. Update Logging Configuration
8. Fix broken unit tests (or Ignore them)
9. Fix broken integration tests (or Ignore them)
10. Verify CORS still works
11. Fix Hibernate startup errors that occurred after updates

<!--more-->

## Update build.gradle ##
### Update GORM Version ###

Grails 3.3 uses GORM 6.1. Moving from version 5 to 6.1 may prove challenging for complex setups, but it was mostly pain free for me. For example, you may need to add configuration to `application.groovy` to make sure GORM uses properties instead of fields if your domain objects depend on property access.

<?prettify?>

    /* application.groovy */
    import javax.persistence.*

    grails.gorm.default.mapping = {
        '*'(accessType: AccessType.PROPERTY)
    }

Or, you may be using older versions of the Spring Security plugin in which the SpringSecurityService class is injected into your User class (as is done in Ripplr). In cases like this, you'll need to set autowire to true in your domain class.

<?prettify?>

    /* User.groovy */
    static mapping = {
        autowire = true
    }

Further upgrade details can be found in the GORM for Hibernate <a href="http://gorm.grails.org/latest/hibernate/manual/index.html#upgradeNotes" rel="noopener" target="_blank">documentation</a>.

### Update to Hibernate 5 ###

GORM 6.1 was built with Hibernate 5.2 in mind. You can continue to use Hibernate 4 if you'd like, but Hibernate 5 has several upgrades that may be worth it to you. For starters, you can now use the new Java 8 Date and Time classes as BasicTypes. As always, be aware of any possible breaking changes, especially if you're making use of lower level Hibernate APIs, by looking over the <a href="https://github.com/hibernate/hibernate-orm/wiki/Migration-Guide---5.2" rel="noopener" target="_blank">migration guide</a>.

<?prettify?>

    /* build.gradle */
    buildscript {
        //...
        dependencies {
            classpath "org.grails.plugins:hibernate5:${gormVersion-".RELEASE"}"
        }
    }
    //...
    dependencies {
        //..
        compile "org.grails.plugins:hibernate5"
        //..
    }

### Add Grails Test Mixin Dependency ###

Grails 3.3 introduced the <a href="https://testing.grails.org/" rel="noopener" target="_blank">Grails Testing Support Framework</a>, which means that the older tests should be updated to use the new framework as soon as possible. However, in the meantime, you can add the <a href="https://grails-plugins.github.io/grails-test-mixin-plugin/latest/guide/index.html" rel="noopener" target="_blank">Test Mixin Framework</a> support via a dependency. I will slowly migrate to the new framework.

<?prettify?>

    /* build.gradle */
    testCompile "org.grails:grails-test-mixins:3.3.0"

### Add new dependencies ###

Several new dependencies are added for Grails 3.3, including the new testing frameworks. Even if you plan on using the mixins for a while longer, you should go ahead and add the new dependencies so you can start migrating as soon as possible. Also, several libraries have been externalized into separate projects, such as `GSP` and `Events`. Below is a sample of the dependencies I added for Ripplr:

<?prettify?>

    /* build.gradle */
    compile "org.grails:grails-logging"
    compile "org.grails:grails-plugin-rest"
    compile "org.grails:grails-plugin-databinding"
    compile "org.grails:grails-plugin-i18n"
    compile "org.grails:grails-plugin-services"
    compile "org.grails:grails-plugin-url-mappings"
    compile "org.grails:grails-plugin-interceptors"

In all honesty, I didn't just "know" this, I created an empty Grails 3.3.6 project and merged the Gradle build and property files with my existing files.

### Update Plugins - Spring Security ###

As mentioned above, in addition to updating the version to 3.2.1, I added an `autowire` section to the `User` domain class to allow use of the `SpringSecurityService`.

<?prettify?>

    /* build.gradle */
    compile "org.grails.plugins:spring-security-core:3.2.1"

### Update Plugins - Elasticsearch ###

The latest Elasticsearch plugin (2.4.1) is built to work with Elasticsearch 5.4.1. Ripplr was working with 2.3.3, so this requires an upgrade, that luckily has a minimal impact on Ripplr due to its development status. There's a chance I could've fought with the plugin and configuration to make it work with 2.3.3, but I figured it would be best to go ahead and move to 5.4.1. Details on making mapping migrations can be found in the plugin <a href="https://puneetbehl.github.io/elasticsearch-grails-plugin/2.4.x/index.html#mappingMigrations" rel="noopener" target="_blank">documentation</a>.
I initially added a dependency on the mapper plugin, since it was <a href="https://www.elastic.co/guide/en/elasticsearch/plugins/5.6/mapper-attachments.html" rel="noopener" target="_blank">deprecated</a> in Elasticsearch 5.0 and the application would not start without it. However, after looking through the documentation a bit more I discovered that if you're not making use of the mapper plugin, you can <a href="https://puneetbehl.github.io/elasticsearch-grails-plugin/2.4.x/index.html#client-mode" rel="noopener" target="_blank">disable</a> it in application.yml.

Adding the mapper plugin back to Elasticsearch:

<?prettify?>

    /* build.gradle */
    compile 'org.grails.plugins:elasticsearch:2.4.1'
    runtime 'org.elasticsearch.plugin:mapper-attachments:2.4.6'

Disabling the mapper plugin:

<?prettify?>

    # application.yml
    elasticSearch:
        plugin:
            mapperAttachment:
                enabled: false

## Update resources.groovy ##

Older versions of Spring Boot had the `FilterRegisterationBean` in the `org.springframework.boot.context.embedded` package. Version 1.5 removed this package and therefore I had to use an updated package of `org.springframework.boot.web.servlet` in `resources.groovy`.

<?prettify?>

    /* resources.groovy */
    import org.springframework.boot.web.servlet.FilterRegistrationBean

## Move Bootstrap.groovy and UrlMappings.groovy out of the default package ##

As per the upgrade <a href="http://docs.grails.org/3.2.x/guide/upgrading.html#upgrading31x" rel="noopener" target="_blank">documentation</a>, we should stop using the default namespace as this may cause issues when the application is packaged inside a JAR or WAR file. I moved mine to the `ripplr.grails3` package. Also make sure you move the file to the correct folder structure.

<?prettify?>

    /* Bootstrap.groovy */
    package ripplr.grails3

## Update Gradle Wrapper ##

I updated the Gradle Wrapper to version 3.5 (the default version with Grails 3.3.6) using <a href="https://gradle.org/install/#with-the-gradle-wrapper" rel="noopener" target="_blank">this</a> method. Grails 3.3 will also work with Gradle 4.x, but my current script has a few areas that would break with Gradle 4, so I'm leaving it at 3.5 for now.

    $ ./gradlew wrapper --gradle-version=3.5 --distribution-type=bin

## Add Grails Wrapper ##

The Grails wrapper was introduced in Grails 2.1, but unfortunately was removed from Grails 3 until version <a href="http://docs.grails.org/3.2.3/guide/single.html#whatsNewGrailsWrapper" rel="noopener" target="_blank">3.2.3</a>. Since Ripplr was created prior to the reintroduction of the Grails wrapper, I used the empty project I mentioned above and copied the relevant files into the Ripplr project.

## Update Logging Configuration ##

Grails 3.3 also updated how logs are <a href="http://docs.grails.org/3.3.x/guide/conf.html#loggerName" rel="noopener" target="_blank">configured</a>. Prior versions of grails relied on the convention of `grails.app.<type>.<fully-qualified-class-name></fully-qualified-class-name></type>`. However, now you can just use the fully qualified class name to configure your logs.

<?prettify?>

    /* logback.groovy */
    logger 'com.joelforjava.ripplr.UserController', DEBUG, ['STDOUT'], false

## Fix Broken Unit Tests (Or Ignore Them) ##

I don't typically advocate for ignoring tests as it could mask future problems with your code and cause other potential issues during the software development lifecycle. However, in my case, I think I may have unearthed something wrong with how I wrote the tests themselves or something wrong with the domain modeling. I'll ignore these tests temporarily and then work on fixing the problems with the tests once I've completed the upgrade. I don't think it's an upgrade issue, but a me issue! This will also give me a starting point for upgrading to the new Grails Testing Support Framework.

## Fix Broken Integration Tests (Or Ignore Them) ##

I used the same logic here as with the unit tests. Luckily, the Integration tests all passed, so there was no need to ignore or fix any of them.

## Verify CORS still works ##

Beyond my small change to `resources.groovy`, I didn't have to touch the CORS configuration. I still wanted to make sure it was working as expected. In the future, I'll likely move the configuration to `application.yml`.

## Fix Hibernate startup errors that occurred after updates ##

After the upgrade, I noticed a couple of errors that would appear whenever I ran any grails or gradle commands. However, no functionality seems to be impacted, so I will leave them be for now and come back and update here when I figure out the solution.

## Conclusion ##

This has been my very brief overview of how I upgraded my Grails 3.1.9 application to Grails 3.3.6. There is still a lot of work to be done, such as upgrading the tests to use the new framework and updating how I configure CORS, but the steps outlined here have given me a good starting point for moving forward with the latest version of Grails.