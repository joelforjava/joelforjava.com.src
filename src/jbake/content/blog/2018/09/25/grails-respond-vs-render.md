title=Grails: Respond vs. Render
date=2018-09-25
type=post
tags=groovy,grails
status=draft
~~~~~~

When I was first getting familiar Grails, either through books or through my own attempts to make apps, I always seemed to make use of render. For whatever reason, respond always intimidated me. Looking back over Ripplr, I've noticed that I either make calls to render, redirect, or simply return the model I use in the view. However, as I started to read the documentation more thoroughly and then try to make use of it in my own code and other projects, it started to become more clear to me how it should be used.
Respond makes use of the Accept header or file extension in the URL to determine the most appropriate representation of the response via the process of <a href="http://docs.grails.org/latest/guide/theWebLayer.html#contentNegotiation" rel="noopener" target="_blank">content negotiation</a>.
Respond also <a href="http://docs.grails.org/latest/ref/Controllers/respond.html" rel="noopener" target="_blank">calculates</a> a model name for the returned object, based on the content of the object.

TODO - respond, as in respond user, yadda, yadda, more-or-less is a call to 'show(user)'

NOTE: This is a private post. It stands mostly as a refresher/reminder of how it works, if I ever forget.