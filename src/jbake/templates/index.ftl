<#include "header.ftl">
	
	<#include "menu.ftl">

	<img class="ui fluid image" src="/images/computer-1873831.png">

	<div id="push"></div>

	<#list posts as post>
  		<#if (post.status == "published")>
		  <div class="ui segments">
		  	<div class="ui black inverted segment">
				<a href="${post.uri}"><h1 class="ui grey inverted header"><#escape x as x?xml>${post.title}</#escape></h1></a>
				<p>${post.date?string("dd MMMM yyyy")}</p>
			</div>
			<div class="ui segment">
				<p>${post.body?keep_before_last('<!--more-->')}</p>
				<p><a href="${post.uri}">Read more...</a></p>
			</div>
		  </div>
  		</#if>
  	</#list>
	
	<hr />
	
	<p>Older posts are available in the <a href="${content.rootpath}${config.archive_file}">archive</a>.</p>

<#include "footer.ftl">