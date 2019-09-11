<#include "header.ftl">
	
	<#include "menu.ftl">

	<h1 class="ui header">Blog</h1>

	<#list posts as post>
  		<#if (post.status == "published")>
  			<a href="${post.uri}"><h1><#escape x as x?xml>${post.title}</#escape></h1></a>
  			<p>${post.date?string("dd MMMM yyyy")}</p>
  			<p>${post.body?keep_before_last('<!--more-->')}</p>
			<p><a href="${post.uri}">Read more...</a></p>
  		</#if>
  	</#list>
	
	<hr />
	
	<p>Older posts are available in the <a href="${content.rootpath}${config.archive_file}">archive</a>.</p>

<#include "footer.ftl">