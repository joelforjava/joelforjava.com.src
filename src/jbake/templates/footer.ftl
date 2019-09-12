		</div>
		<div id="push"></div>
    
    <div class="ui inverted vertical footer segment">
      <div class="ui center aligned container">
        <div class="ui inverted section divider"></div>
        <div class="ui horizontal inverted small divided link list">
          <#--  <a class="item" href="http://semantic-ui.com/">Semantic UI v2.4.1</a>
          <a class="item" href="http://jbake.org">JBake ${version}</a>  -->
          <p class="items">&copy; 2019 | Mixed with <a href="http://semantic-ui.com/">Semantic UI v2.4.1</a> | Baked with <a href="http://jbake.org">JBake ${version}</a></p>
        </div>
      </div>
    </div>

    <!-- Le javascript
    ================================================== -->
    <!-- Placed at the end of the document so the pages load faster -->
    <script src="<#if (content.rootpath)??>${content.rootpath}<#else></#if>js/jquery-1.11.1.min.js"></script>
    <script src="<#if (content.rootpath)??>${content.rootpath}<#else></#if>js/semantic.min.js"></script>
    <script src="<#if (content.rootpath)??>${content.rootpath}<#else></#if>js/prettify.js"></script>
    
  </body>
</html>