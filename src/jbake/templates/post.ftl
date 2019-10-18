<#include "header.ftl">
	
			<!-- Post -->
				<article class="box post">
					<#if (content.title)??>
					<header>
						<!--
							Note: Titles and subtitles will wrap automatically when necessary, so don't worry
							if they get too long. You can also remove the <p> entirely if you don't
							need a subtitle.
						-->

						<h2><#escape x as x?xml>${content.title}</#escape></h2>
						<#if (content.last_updated??)>
							<p>Updated on: ${content.last_updated?date("yyyy-MM-dd")?string("dd MMMM yyyy")}</p>
						</#if>
					</header>
					<#else></#if>

					<div class="info">
						<!--
							Note: The date should be formatted exactly as it's shown below. In particular, the
							"least significant" characters of the month should be encapsulated in a <span>
							element to denote what gets dropped in 1200px mode (eg. the "uary" in "January").
							Oh, and if you don't need a date for a particular page or post you can simply delete
							the entire "date" element.

						-->
						<#assign pubDate>${content.date?date}</#assign>
						<#assign pubMonth = pubDate?date?string("MMMM")>
						<#assign pubDay = pubDate?date?string("dd")>
						<#assign pubYear = pubDate?date?string("yyyy")>
						<span class="date"><span class="month">${pubMonth[0..2]}<span>${pubMonth[3..]}</span></span> <span class="day">${pubDay}</span><span class="year">, ${pubYear}</span></span>
						<!--
							Note: You can change the number of list items in "stats" to whatever you want. TODO - put in template?
						-->
						<#if config.post_use_stats!false >
						<ul class="stats">
							<li><a href="#" class="icon fa-comment">16</a></li>
							<li><a href="#" class="icon fa-heart">32</a></li>
							<li><a href="#" class="icon brands fa-twitter">64</a></li>
							<li><a href="#" class="icon brands fa-facebook-f">128</a></li>
						</ul>
						</#if>
					</div>
					<#if (content.header_image??) >
						<#-- TODO - add header images to a few articles -->
						<a href="#" class="image featured"><img src="${content.header_image}" alt="" /></a>
					</#if>
					<p>${content.body}</p>
				</article>

	<hr />
	
				</div>
			</div>
		<#include "sidebar.ftl">

<#include "footer.ftl">