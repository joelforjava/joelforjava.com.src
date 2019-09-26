<#include "header.ftl">
	
	<#include "menu.ftl">

	<#if (content.title)??>
	<h1 class="ui header">
		<#escape x as x?xml>${content.title}</#escape>
		<div class="sub header">
		${content.date?string("dd MMMM yyyy")}
		<#if (content.last_updated)?has_content>
			<span class="right">Last Updated: <em>${content.last_updated?date('yyyy-MM-dd')?string('dd MMMM yyyy')}</em></span>
		</#if>

		</div>
	</h1>
	<#else></#if>


	<p>${content.body}</p>

	<hr />
	
<#include "footer.ftl">