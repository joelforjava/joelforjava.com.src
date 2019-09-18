<#include "header.ftl">
	
	<#include "menu_hidden.ftl">

	<#--  <div id="push"></div>  -->

	<div class="pusher">
		<div class="ui inverted vertical masthead center aligned segment">
			<div class="ui container">
				<div class="ui large secondary inverted pointing menu">
				    <#include "menu_common.ftl">
				</div>
			</div>
			<div class="ui container">
				<img class="ui medium centered image" src="/images/joelforjava-icon.jpeg">
			</div>
			<div class="ui text container">
				<h1 class="ui inverted header">Joel for Java</h1>
			</div>
		</div>
	<div class="ui main container">
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
	  </div>
	</div>
	
	<hr />
	
	<p>Older posts are available in the <a href="${content.rootpath}${config.archive_file}">archive</a>.</p>

<#include "footer.ftl">