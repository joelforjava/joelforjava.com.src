title=Migrating joelforjava.co(m) from WordPress to JBake
date=2019-09-15
type=post
tags=general,wordpress,static site generators,jbake,freemarker,groovy,thymeleaf,jade,blogging
status=published
~~~~~~

When I started this site back in 2016, I went with [WordPress](http://wordpress.org) because it was the quickest solution I could find to get things off the ground. However, as time has progressed, it has become clear that it's a bit overkill for my needs. I don't plan on ever having users sign up for accounts, for example. It's just me and the stuff I write. Could that change? Possibly, but not likely. Meanwhile, static site generators, such as [Gatsby](http://gatsbyjs.org/), [Sphinx](http://www.sphinx-doc.org/), [Jekyll](http://jekyllrb.com/), [VuePress](https://vuepress.vuejs.org/), and a trove of others have been gaining in popularity. That's when it hit me, all I really need is a basic static-type site. 

While I really wanted to go with something like VuePress or Gatsby so that I could sharpen my now archaic JavaScript skills, I decided to go with [JBake](http://jbake.org/). JBake has features that were more familiar to me, including [Freemarker](http://freemarker.org/) and [Groovy](http://groovy-lang.org/) based templates and even has a [Gradle](http://gradle.org/) [plugin](https://plugins.gradle.org/plugin/org.jbake.site) so that I could create a build script to help maintain the new version of the blog. Other offerings have similar features, but I've really missed working with Groovy and Gradle. These days, for better or worse, I'm mostly working with Python.

Since I didn't really have that many articles written over the years, it wasn't that much effort to copy everything over into new [Markdown](https://daringfireball.net/projects/markdown/) files, which is what I plan on using for most of my articles. I could've probably written something to copy the data from WordPress, but I copied them manually since it might've taken me longer to write a script.

So, here I am now. Everything copied over and I even have some new articles coming down the pipeline. Hopefully by the time you see this, I'll already have a new and improved layout.

To help me keep tabs on the site, I've added a couple of Gradle tasks, including one to check for articles still in draft and another that validates all of the links to make sure we don't have any that are broken. They're a bit messy, but I'm hoping to improve them over time. I'm also hoping to add a spellchecker task to help keep misspellings to a minimum. You can check out everything [here](https://github.com/joelforjava/joelforjava.com.src).

I used the jbake command to initialize my site using `jbake -i`. The site was set up using Freemarker templates, which was fine with me. You can change the templating engine used by running `jbake -i -t <ENGINE>`, where ENGINE is one of `freemarker`, `groovy`, `groovy-mte`, `thymeleaf`, or `jade`. If you've already set up a Gradle build script, you can update the `template` property of the `jbake` as follows:

<?prettify?>

    jbake {
        template = 'ENGINE'
    }

Here, ENGINE is the same as for the jbake command. Also, if you initialize a JBake site with Gradle and don't supply a template engine name, it will default to `groovy` instead of `freemarker`. When using Gradle, you can run the `bake` task to re-build your site and the `bakePreview` task to run in preview mode, similar to how `jbake -s` works. However, you'll need to run `gradle bake` each time you wish to update the deployed site. More information on the plugin and itse setup can be found on its GitHub [page](https://github.com/jbake-org/jbake-gradle-plugin).

Thank you for reading and I hope to somehow keep articles coming even when I'm not able to work with Java as much. Strangely, it seems like the more I'm pushed away from the Java ecosystem, the more I want to work in it. I might post some Python and other language stuff here, too, but that kind of gets away from the whole 'Joel for Java' thing, doesn't it?