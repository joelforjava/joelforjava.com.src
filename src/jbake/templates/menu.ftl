	<!-- Fixed navbar -->
    <div class="ui fixed inverted menu">
      <div class="ui container">
        <a class="header item" href="<#if (content.rootpath)??>${content.rootpath}<#else></#if>"><img class="logo" src="/images/joelforjava-icon.jpeg"> Joel for Java</a>
        <a class="item" href="<#if (content.rootpath)??>${content.rootpath}<#else></#if>index.html">Home</a>
        <a class="item" href="<#if (content.rootpath)??>${content.rootpath}<#else></#if>about.html">About</a>
        <a class="item" href="<#if (content.rootpath)??>${content.rootpath}<#else></#if>${config.feed_file}">Subscribe</a>
        <div class="ui simple dropdown item">
          Dropdown <i class="dropdown icon"></i>
          <div class="menu">
            <a class="item" href="#">Action</a>
            <a class="item" href="#">Another action</a>
            <a class="item" href="#">Something else here</a>
            <div class="divider"></div>
            <div class="header">Nav header</div>
            <div class="item">
              <i class="dropdown icon"></i>
              Sub Menu
              <div class="menu">
                <a class="item" href="#">Link Item</a>
                <a class="item" href="#">Link Item</a>
              </div>
            </div>
            <a class="item" href="#">Link Item</a>
          </div>
        </div>
      </div>
    </div>
    <div class="ui main container">