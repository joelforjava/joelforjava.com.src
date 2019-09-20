		</div>
		<div id="push"></div>
    
    <div class="ui inverted vertical footer segment">
      <div class="ui center aligned container">
        <div class="ui stackable inverted divided grid">
          <div class="seven wide column">
            <h4 class="ui inverted header">Find Me Online</h4>
            <div class="ui inverted horizontal link list">
              <a href="https://github.com/joelforjava" target="_blank" class="item"><i class="icon github"></i></a>
              <a href="https://twitter.com/joelforjava" target="_blank" class="item"><i class="icon twitter"></i></a>
              <a href="https://joelforjava.tumblr.com/" target="_blank" class="item"><i class="icon tumblr"></i></a>
            </div>
          </div>
        </div>
        <div class="ui inverted section divider"></div>
        <div class="ui horizontal inverted small divided link list">
          <p class="item">&copy; 2019</p>
          <p class="item">Mixed with <a href="http://semantic-ui.com/">Semantic UI v2.4.1</a></p>
          <p class="item">Baked with <a href="http://jbake.org">JBake ${version}</a></p>
        </div>
      </div>
    </div>

    <!-- Le javascript
    ================================================== -->
    <!-- Placed at the end of the document so the pages load faster -->
    <script src="<#if (content.rootpath)??>${content.rootpath}<#else></#if>js/jquery-1.11.1.min.js"></script>
    <script src="<#if (content.rootpath)??>${content.rootpath}<#else></#if>js/semantic.min.js"></script>
    <script src="<#if (content.rootpath)??>${content.rootpath}<#else></#if>js/prettify.js"></script>
    <#-- This exists only for the home page. Try to keep this local to that page/template. -->
    <script>
      $(document)
          .ready(function() {

            // fix menu when passed
            $('.masthead')
              .visibility({
                once: false,
                onBottomPassed: function() {
                  $('.fixed.menu').transition('fade in');
                },
                onBottomPassedReverse: function() {
                  $('.fixed.menu').transition('fade out');
                }
              })
            ;
          })
        ;
      </script>
  </body>
</html>