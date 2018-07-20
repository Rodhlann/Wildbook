<%@ page
		contentType="text/html; charset=utf-8"
		language="java"
     	import="org.ecocean.CommonConfiguration,org.ecocean.ContextConfiguration"
%>
        <%

System.out.println("Beginning footer");

String context="context0";
context=ServletUtilities.getContext(request);
String langCode=ServletUtilities.getLanguageCode(request);
Properties props = new Properties();
props = ShepherdProperties.getProperties("header.properties", langCode, context);
Shepherd myShepherd = new Shepherd(context);

// 'sets serverInfo if necessary
CommonConfiguration.ensureServerInfo(myShepherd, request);

String urlLoc = "//" + CommonConfiguration.getURLLocation(request);

myShepherd.setAction("header.jsp");
myShepherd.beginDBTransaction();

String username = null;
User user = null;
boolean indocetUser = false;
System.out.println("Footer1");

if(request.getUserPrincipal()!=null){

  user = myShepherd.getUser(request);
  username = (user!=null) ? user.getUsername() : null;
  indocetUser = (user!=null && user.hasAffiliation("indocet"));

  //finally{
    myShepherd.rollbackDBTransaction();
    myShepherd.closeDBTransaction();
  //}
}

System.out.println("Footer2: isIndocetUser = "+indocetUser);

%>
        <!-- footer -->
        <footer class="page-footer">

            <div class="container-fluid">
              <div class="container main-section">

                <div class="row">
                  <p class="col-sm-8" style="margin-top:40px;">
                    <small>This software is distributed under the GPL v2 license and is intended to support mark-recapture field studies.
                  <br> <a href="http://www.wildme.org/wildbook" target="_blank">Wildbook v.<%=ContextConfiguration.getVersion() %></a> </small>
                  </p>
                  <!-- IndoCet funder logos -->
                  <%if (indocetUser) {%>
                    <a href="https://www.ffem.fr" class="col-sm-4" title="Funded in part by FFEM">
                      <img src="<%=urlLoc %>/cust/indocet/logo_FFEM.png" alt=" logo" class="pull-right" style="
                        height: 150px;
                      "/>
                    </a>
                    <a href="commissionoceanindien.org" class="col-sm-4" title="Funded in part by COI">
                      <img src="<%=urlLoc %>/cust/indocet/logo_COI.png" alt=" logo" class="pull-right" style="
                        height: 150px;
                      "/>
                    </a>

                  <%}%>
                  <a href="http://www.wildbook.org" class="col-sm-4" title="This site is Powered by Wildbook">
                    <img src="<%=urlLoc %>/images/WildBook_logo_72dpi-01.png" alt=" logo" class="pull-right" style="
											height: 150px;
										"/>
                  </a>
                </div>
              </div>
            </div>

            <script>
				  (function(i,s,o,g,r,a,m){i['GoogleAnalyticsObject']=r;i[r]=i[r]||function(){
				  (i[r].q=i[r].q||[]).push(arguments)},i[r].l=1*new Date();a=s.createElement(o),
				  m=s.getElementsByTagName(o)[0];a.async=1;a.src=g;m.parentNode.insertBefore(a,m)
				  })(window,document,'script','//www.google-analytics.com/analytics.js','ga');

				  ga('create', 'UA-30944767-5', 'auto');
				  ga('send', 'pageview');

			</script>

        </footer>
        <!-- /footer -->
    </body>
</html>
