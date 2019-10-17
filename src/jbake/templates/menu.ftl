				<!-- Nav -->
					<nav id="nav">
						<ul>
							<li><a href="<#if (content.rootpath)??>${content.rootpath}<#else></#if>index.html">Home</a></li>
							<li><a href="<#if (content.rootpath)??>${content.rootpath}<#else></#if>${config.archive_file}">Archives</a></li>
							<li><a href="<#if (content.rootpath)??>${content.rootpath}<#else></#if>about.html">About</a></li>
							<li><a href="<#if (content.rootpath)??>${content.rootpath}<#else></#if>feed.xml">Subscribe (RSS)</a></li>
							<li><a href="<#if (content.rootpath)??>${content.rootpath}<#else></#if>feed.json">Subscribe (JSON Feed)</a></li>
						</ul>
					</nav>
