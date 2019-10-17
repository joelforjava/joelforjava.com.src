<#include "header.ftl">
	
	<article class="box post post-excerpt">
		<header>
			<h2>Blog Archive</h2>
		</header>
	<!--<ul>-->
		<#list published_posts as post>
		<#if (last_month)??>
			<#if post.date?string("MMMM yyyy") != last_month>
				</ul>
				<h4>${post.date?string("MMMM yyyy")}</h4>
				<ul>
			</#if>
		<#else>
			<h4>${post.date?string("MMMM yyyy")}</h4>
			<ul>
		</#if>
		
		<li>${post.date?string("dd")} - <a href="${content.rootpath}${post.uri}"><#escape x as x?xml>${post.title}</#escape></a></li>
		<#assign last_month = post.date?string("MMMM yyyy")>
		</#list>
		</ul>
	</article>
			</div> <!-- inner -->
		</div> <!-- content -->
	<#include "sidebar.ftl">
	
<#include "footer.ftl">