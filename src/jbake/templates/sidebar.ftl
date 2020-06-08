		<!-- Sidebar -->
			<div id="sidebar">

				<!-- Logo -->
					<h1 id="logo">
						<a href="<#if (content.rootpath)??>${content.rootpath}<#else></#if>index.html">Joel for Java</a>
					</h1>

                <#include "menu.ftl"/>

				<!-- Text -->
					<section class="box text-style1">
						<div class="inner">
							<p>
								<a href="https://twitter.com/search?q=%23blacklivesmatter" target="_blank">#BlackLivesMatter</a>
							</p>
						</div>
					</section>

				<!-- Recent Posts -->
					<section class="box recent-posts">
						<header>
							<h2>Recent Posts</h2>
						</header>
                        <#list published_posts>
						<ul>
                            <#items as recentPost>
                                <#if (recentPost?counter > 4)><#break></#if> <#-- TODO make this configurable.-->
                                <li><a href="${content.rootpath}${recentPost.uri}"><#escape x as x?xml>${recentPost.title}</#escape></a></li>
                            </#items>
						</ul>
                        </#list>
					</section>

				<!-- Copyright -->
					<ul id="copyright">
						<li>&copy; 2016 - 2020</li>
                        <li>Design: <a href="http://html5up.net">HTML5 UP</a></li>
                        <li>Baked with <a href="http://jbake.org">JBake ${version}</a></li>
					</ul>

			</div>

