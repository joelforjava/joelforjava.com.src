<#include "header.ftl">
	
	<#list published_posts as post>
			<!-- Post -->
				<article class="box post post-excerpt">
					<header>
						<!--
							Note: Titles and subtitles will wrap automatically when necessary, so don't worry
							if they get too long. You can also remove the <p> entirely if you don't
							need a subtitle.
						-->
						<h2><a href="${post.uri}"><#escape x as x?xml>${post.title}</#escape></a></h2>
						<#-- <p>${post.date?string("dd MMMM yyyy")}</p> TODO - this date moves to the 'tab' (the date span below) -->
					</header>
					<div class="info">
						<!--
							Note: The date should be formatted exactly as it's shown below. In particular, the
							"least significant" characters of the month should be encapsulated in a <span>
							element to denote what gets dropped in 1200px mode (eg. the "uary" in "January").
							Oh, and if you don't need a date for a particular page or post you can simply delete
							the entire "date" element.

						-->
						<#assign pubDate>${post.date?date}</#assign>
						<#assign pubMonth = pubDate?date?string("MMMM")>
						<#assign pubDay = pubDate?date?string("dd")>
						<#assign pubYear = pubDate?date?string("yyyy")>
						<span class="date"><span class="month">${pubMonth[0..2]}<span>${pubMonth[3..]}</span></span> <span class="day">${pubDay}</span><span class="year">, ${pubYear}</span></span>
						<!--
							Note: You can change the number of list items in "stats" to whatever you want. TODO - put in template?
						-->
						<#-- WTF do you do when this config value isn't in the properties file?! -->
						<#if config.post_use_stats!false >
						<ul class="stats">
							<li><a href="#" class="icon fa-comment">16</a></li>
							<li><a href="#" class="icon fa-heart">32</a></li>
							<li><a href="#" class="icon brands fa-twitter">64</a></li>
							<li><a href="#" class="icon brands fa-facebook-f">128</a></li>
						</ul>
						</#if>
					</div>

					<#if (post.header_image??) >
						<#-- TODO - add header images to a few articles -->
						<a href="#" class="image featured"><img src="${post.header_image}" alt="" /></a>
					</#if>
					<p>${post.body?keep_before_last('<!--more-->')}</p>
					<p><a href="${post.uri}">Read more...</a></p>
				</article>
  	</#list>
	
	<hr />
	<#-- TODO fix this! -->
	<#if (config.index_paginate && numberOfPages > 1)>

		<!-- Pagination -->
			<div class="pagination">
				<#if (currentPageNumber > 1)>
					<a href="${content.rootpath}${previousFileName!'#'}" class="button previous">Previous Page</a>
				</#if>
				<div class="pages">
					<a href="#" class="<#if (currentPageNumber == 1)>active</#if>">1</a>
					<#assign startingPage = 2>
					<#--  <#assign maxPagesShown = startingPage + 5>  -->
					<#-- TODO - make this a configuration value? -->
					<#-- TODO: come up with a better name for this variable!! -->
					<#assign origMaxPagesShown = 4>
					<#assign maxPagesShown = origMaxPagesShown>
					<#if (currentPageNumber > maxPagesShown)>
						<span>&hellip;</span>
						<#assign val = currentPageNumber - maxPagesShown>
						<#--  <#assign val = currentPageNumber>  -->
						<#assign startingPage += val>
						<#assign maxPagesShown += val>
					</#if>
					<#list startingPage..maxPagesShown as pageNumber>
						<#if (pageNumber != numberOfPages)>
							<a href="#" class="<#if (currentPageNumber == pageNumber)>active</#if>">${pageNumber}</a>
						</#if>
					</#list>
					<#--  <#if (numberOfPages > maxPagesShown && currentPageNumber <= origMaxPagesShown)>  -->
					<#if (numberOfPages > maxPagesShown)>
						<span>&hellip;</span>
					</#if>
					<a href="#" class="<#if (currentPageNumber == numberOfPages)>active</#if>">${numberOfPages}</a>
				</div>
				<#if (currentPageNumber < numberOfPages)>
					<a href="${content.rootpath}${nextFileName!'#'}" class="button next">Next Page</a>
				</#if>
			</div>

	<#else>
		<p>Older posts are available in the <a href="${content.rootpath}${config.archive_file}">archive</a>.</p>
	</#if>
				</div>
			</div>

		<#include "sidebar.ftl">

<#include "footer.ftl">