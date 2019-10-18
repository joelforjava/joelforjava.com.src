				<!-- Nav -->
					<nav id="nav">
						<ul>
							<li <#if (content.type?? && content.type?ends_with("masterindex")) > class="current"</#if>><a href="<#if (content.rootpath)??>${content.rootpath}<#else></#if>index.html">Home</a></li>
							<li <#if (content.type?? && content.type?ends_with("archive")) > class="current"</#if>><a href="<#if (content.rootpath)??>${content.rootpath}<#else></#if>${config.archive_file}">Archives</a></li>
							<li <#if (content.uri?? && content.uri?ends_with("about.html")) > class="current"</#if>><a href="<#if (content.rootpath)??>${content.rootpath}<#else></#if>about.html">About</a></li>
							<li><a href="<#if (content.rootpath)??>${content.rootpath}<#else></#if>feed.xml">Subscribe (RSS)</a></li>
							<li><a href="<#if (content.rootpath)??>${content.rootpath}<#else></#if>feed.json">Subscribe (JSON Feed)</a></li>
						</ul>
					</nav>
