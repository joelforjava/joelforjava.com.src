        <a class="item" href="<#if (content.rootpath)??>${content.rootpath}<#else></#if>index.html"><i class="icon home"></i> Home</a>
        <a class="item" href="<#if (content.rootpath)??>${content.rootpath}<#else></#if>about.html">About</a>
        <div class="ui simple dropdown item">
          <i class="icon rss"></i> Subscribe <i class="dropdown icon"></i>
          <div class="menu">
            <a class="item" href="<#if (content.rootpath)??>${content.rootpath}<#else></#if>${config.feed_file}">RSS</a>
          </div>
        </div>
