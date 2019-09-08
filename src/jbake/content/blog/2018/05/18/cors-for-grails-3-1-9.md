title=CORS for Grails 3.1.9
date=2018-05-18
type=post
tags=groovy,grails,cors,ripplr
status=published
~~~~~~

At my (now former) day job, I work on a monolithic java web application. CORS, cross-origin resource sharing, is not something that is a big concern for that application since, by default, a script can make a request to the same server from which it originates. However, modern web applications tend to have incoming connections from a variety of other applications, including mobile applications or a single page application running on a separate server. When working with these applications or with your own applications that need to connect to different servers, CORS is something that developers definitely need to keep in mind.

<!--more-->

In my [Ripplr](/blog/2018/05/08/introducing-ripplr.html) application, I have created a set of services that can be used by a mobile app, or maybe even a future third party application. For this demonstration, I will showcase how to set up CORS to allow incoming connections from an external Angular application.

Here are the systems that will be used:

- [Ripplr](https://github.com/joelforjava/ripplr-grails3) (back end, built using Grails 3.1.9)
- [Ripplr Angular UI](https://github.com/joelforjava/ripplr-angular-ui) (Timeline Only - single page built using Angular 2)

The Ripplr back end code is more or less your standard Grails application. I've based it heavily on the Hubub application that is a part of the [Grails in Action](https://www.manning.com/books/grails-in-action-second-edition) book as Ripplr is the code I created as I followed along. This application has Spring Security enabled but I have opened up an endpoint to the global timeline for use in the Angular demo.

While I have seen [several](https://github.com/appcela/grails3-cors-interceptor-spring-security-rest-sample-app) [links](https://stackoverflow.com/questions/29584164/how-to-enable-cors-in-grails-3-0-1) talking about how to get CORS working with Grails 3 and the Spring Security Plugin, I couldn't quite get them working right for myself. I decided to look for a different way to get CORS working with Grails 3, preferably without a Grails plugin.

By default, CORS will deny everything that does not have the same Origin. Since the Ripplr backend is running on port `8080` and the Angular timeline UI is running on port `4200`, this means we have different origins. It isn't enough for them to both be on `localhost` (or any other host, for that matter). So, we will need to tell the Grails application that the Angular application is a trusted application.

So, in order to enable this, I started my research at the top: [The Grails 3.1.9 Guide](http://docs.grails.org/3.1.9/guide/introduction.html#whatsNew31). There, it mentions that Grails 3.1 has been updated to Spring 4.2. I wasn't too familiar with all that came with Spring 4.2 consdiering my day job still dealt with Spring 2.5. I dove into the Spring Framework documentation and found [this](https://docs.spring.io/spring/docs/4.2.9.RELEASE/spring-framework-reference/htmlsingle/#cors). It states that as of Spring Framework 4.2, CORS is supported out of the box!

So, it sounds like what I really need to try is leverage this new CORS support in the Spring Framework. I came across the [CorsFilter](https://docs.spring.io/spring-framework/docs/4.2.9.RELEASE/javadoc-api/org/springframework/web/filter/CorsFilter.html) filter class and thought that would be something I could easily implement.

This is the class I came up with:

<?prettify?>

    @CompileStatic
    class CustomCorsFilter extends org.springframework.web.filter.CorsFilter {

        CustomCorsFilter() {
            super(configurationSource())
        }

        private static UrlBasedCorsConfigurationSource configurationSource() {
            CorsConfiguration config = new CorsConfiguration();
            config.setAllowCredentials(true)
            config.addAllowedOrigin('http://localhost:4200')
            ['origin', 'authorization', 'accept', 'content-type', 'x-requested-with'].each { header -&gt;
                config.addAllowedHeader(header)
            }
            ['GET', 'HEAD', 'POST', 'PUT', 'DELETE', 'OPTIONS'].each { method -&gt;
                config.addAllowedMethod(method)
            }
            UrlBasedCorsConfigurationSource source = new UrlBasedCorsConfigurationSource();
            source.registerCorsConfiguration('/**', config)
            return source
        }

    }

Notice the call to `config.addAllowedOrigin`. I've set it to allow only `localhost:4200`. You could add as many origins as you'd like, or even be bold and allow `'*'`, but I don't recommend it since you'll open up your system to the entire internet. Also notice how we added the major HTTP verbs to the allowed methods. You could narrow this down further, if desired. We can also dig deeper into the configuration, including setting the max-age of how long the response from a pre-flight request can be cached by clients, and even combine separate configurations into one. The `UrlBasedCorsConfigurationSource` class allows you to register several CORS configurations, if necessary, Here, we're just using a single `CorsConfiguration` object for the entire application.

Once you do this, you will need to register the bean in your `resources.groovy`

<?prettify?>

    beans = {

        customCorsFilter(CustomCorsFilter)

        corsFilter(FilterRegistrationBean) {
            filter = customCorsFilter
            order = 0
        }

    }

Of course, by the time Grails 3.2.1 came around, it natively supported CORS via configuration in `application.yml`. I may come back around to this at some point in the future to make sure it's as easy as it seems once I update Ripplr to the latest Grails version. I hope reading this article has been as useful to you as writing it has been useful to me.
