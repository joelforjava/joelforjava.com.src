title=Introducing the 'carmix-collector' Project
date=2018-04-19
type=post
tags=java,legacy,project,carmix-creator
status=published
~~~~~~

I will be using several projects of various sizes throughout my posts here. The first project I would like to introduce is one I've dubbed the 'carmix-collector'. It's a Java Swing application that was created using Netbeans and I wrote the original version of this code around 2006. The purpose of this application was to quickly copy songs from an MP3 Playlist (*.m3u) file so that they could be burned to a CD for use in my MP3-enabled car stereo. Needless to say, I haven't paid much attention to this code in years.

<!--more-->

<img src="/images/CarmixCollector-Win10.png" alt="Carmix-Collector Screenshot as seen on Windows 10" width="300" height="243" class="alignnone size-medium wp-image-47">

The version of the code I am starting with was updated in 2010, although I couldn't really tell you what changed between the original version and this one. It was written originally in Java 5, but it will progressively move toward Java 7, 8, 9+. I have updated the project to use Maven, rather than the custom NetBeans Ant build. Other than this, the code is mostly untouched except for the changes we will be going through in various posts. Personally, I see several ways this application can be improved both from a usability standpoint and a coding standpoint. We'll see how many ways we can change, and hopefully improve, this project as time progresses.

If you are interested, I have checked the code into git <a href="https://github.com/joelforjava/carmix-collector" rel="noopener" target="_blank">here</a>.