<%--
  ~ Wildbook - A Mark-Recapture Framework
  ~ Copyright (C) 2008-2015 Jason Holmberg
  ~
  ~ This program is free software; you can redistribute it and/or
  ~ modify it under the terms of the GNU General Public License
  ~ as published by the Free Software Foundation; either version 2
  ~ of the License, or (at your option) any later version.
  ~
  ~ This program is distributed in the hope that it will be useful,
  ~ but WITHOUT ANY WARRANTY; without even the implied warranty of
  ~ MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
  ~ GNU General Public License for more details.
  ~
  ~ You should have received a copy of the GNU General Public License
  ~ along with this program; if not, write to the Free Software
  ~ Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
  --%>
<!DOCTYPE html>
<html>
<%@ page contentType="text/html; charset=utf-8" language="java"
     import="org.ecocean.ShepherdProperties,
             org.ecocean.servlet.ServletUtilities,
             org.ecocean.CommonConfiguration,
             org.ecocean.Shepherd,
             org.ecocean.Util,
             org.ecocean.Organization,
             org.ecocean.User,
             java.util.ArrayList,
             java.util.List,
             java.util.Properties,
             org.apache.commons.text.WordUtils,
             org.ecocean.security.Collaboration,
             org.ecocean.ContextConfiguration
              "
%>

<%
String context="context0";
context=ServletUtilities.getContext(request);
String langCode=ServletUtilities.getLanguageCode(request);
Properties props = new Properties();
props = ShepherdProperties.getProperties("header.properties", langCode, context);
Shepherd myShepherd = new Shepherd(context);
myShepherd.setAction("header.jsp");
String urlLoc = "//" + CommonConfiguration.getURLLocation(request);

if (org.ecocean.MarkedIndividual.initNamesCache(myShepherd)) System.out.println("INFO: MarkedIndividual.NAMES_CACHE initialized");

String pageTitle = (String)request.getAttribute("pageTitle");  //allows custom override from calling jsp (must set BEFORE include:header)
if (pageTitle == null) {
    pageTitle = CommonConfiguration.getHTMLTitle(context);
} else {
    pageTitle = CommonConfiguration.getHTMLTitle(context) + " | " + pageTitle;
}

String username = null;
User user = null;
String profilePhotoURL=urlLoc+"/images/empty_profile.jpg";
// we use this arg bc we can only log out *after* including the header on logout.jsp. this way we can still show the logged-out view in the header
boolean loggingOut = Util.requestHasVal(request, "loggedOut");

boolean indocetUser = false;
String organization = request.getParameter("organization");
if (organization!=null && organization.toLowerCase().equals("indocet"))  {
  indocetUser = true;
}
myShepherd.beginDBTransaction();
try {
  if(!indocetUser && request.getUserPrincipal()!=null && !loggingOut){
    user = myShepherd.getUser(request);
    username = (user!=null) ? user.getUsername() : null;
    String orgName = "indocet";
    Organization indocetOrg = myShepherd.getOrganizationByName(orgName);
    indocetUser = ((user!=null && user.hasAffiliation(orgName)) || (indocetOrg!=null && indocetOrg.hasMember(user)));
  	if(user.getUserImage()!=null){
  	  profilePhotoURL="/"+CommonConfiguration.getDataDirectoryName(context)+"/users/"+user.getUsername()+"/"+user.getUserImage().getFilename();
  	}
  }
}
catch(Exception e){
  System.out.println("Exception on indocetCheck in header.jsp:");
  e.printStackTrace();
  myShepherd.closeDBTransaction();
}
finally{
  myShepherd.rollbackDBTransaction();
  myShepherd.closeDBTransaction();
}


%>


<html>
    <head>

      <!-- Global site tag (gtag.js) - Google Analytics -->
      <script async src="https://www.googletagmanager.com/gtag/js?id=UA-30944767-12"></script>

      <script>
        window.dataLayer = window.dataLayer || [];
        function gtag(){dataLayer.push(arguments);}
        gtag('js', new Date());

        gtag('config', 'UA-30944767-12');
      </script>

      <title><%=pageTitle%></title>
      <meta name="viewport" content="width=device-width, initial-scale=1, user-scalable=no">
      <meta http-equiv="Content-Type" content="text/html; charset=utf-8"/>
      <meta charset="UTF-8">
      <meta name="Description"
            content="<%=CommonConfiguration.getHTMLDescription(context) %>"/>
      <meta name="Keywords"
            content="<%=CommonConfiguration.getHTMLKeywords(context) %>"/>
      <meta name="Author" content="<%=CommonConfiguration.getHTMLAuthor(context) %>"/>
      <link rel="shortcut icon"
            href="<%=CommonConfiguration.getHTMLShortcutIcon(context) %>"/>
      <link href='//fonts.googleapis.com/css?family=Oswald:400,300,700' rel='stylesheet' type='text/css'/>
      <link rel="stylesheet" href="<%=urlLoc %>/cust/mantamatcher/css/manta.css" />

      <%
      if (indocetUser) {
        %><link rel="stylesheet" href="<%=urlLoc %>/cust/indocet/overwrite.css" /><%
      }
      %>
      <!-- Icon font necessary for indocet style, but for consistency will be applied everywhere -->
      <link rel="stylesheet" href="<%=urlLoc %>/fonts/elusive-icons-2.0.0/css/elusive-icons.min.css">
      <link rel="stylesheet" href="<%=urlLoc %>/fonts/elusive-icons-2.0.0/css/icon-style-overwrite.css">

      <link href="<%=urlLoc %>/tools/jquery-ui/css/jquery-ui.css" rel="stylesheet" type="text/css"/>
     
     <%
     if((CommonConfiguration.getProperty("allowSocialMediaLogin", context)!=null)&&(CommonConfiguration.getProperty("allowSocialMediaLogin", context).equals("true"))){
     %> 	
    	 <link href="<%=urlLoc %>/tools/hello/css/zocial.css" rel="stylesheet" type="text/css"/>
     <%
     }
     %>
     
     
      <!-- <link href="<%=urlLoc %>/tools/timePicker/jquery.ptTimeSelect.css" rel="stylesheet" type="text/css"/> -->
	    <link rel="stylesheet" href="<%=urlLoc %>/tools/jquery-ui/css/themes/smoothness/jquery-ui.css" type="text/css" />


      <script src="<%=urlLoc %>/tools/jquery/js/jquery.min.js"></script>
      <script src="<%=urlLoc %>/tools/bootstrap/js/bootstrap.min.js"></script>
      <script type="text/javascript" src="<%=urlLoc %>/javascript/core.js"></script>
      <script type="text/javascript" src="<%=urlLoc %>/tools/jquery-ui/javascript/jquery-ui.min.js"></script>

        <script type="text/javascript" src="<%=urlLoc %>/javascript/ia.js"></script>
        <script type="text/javascript" src="<%=urlLoc %>/javascript/ia.IBEIS.js"></script>  <!-- TODO plugin-ier -->

     <script type="text/javascript" src="<%=urlLoc %>/javascript/jquery.blockUI.js"></script>
	   <script type="text/javascript" src="<%=urlLoc %>/javascript/jquery.cookie.js"></script>

	 <%
     if((CommonConfiguration.getProperty("allowSocialMediaLogin", context)!=null)&&(CommonConfiguration.getProperty("allowSocialMediaLogin", context).equals("true"))){
     %> 
      <script type="text/javascript" src="<%=urlLoc %>/tools/hello/javascript/hello.all.js"></script>
      <%
      }
      %>
      
      <script type="text/javascript"  src="<%=urlLoc %>/JavascriptGlobals.js"></script>
      <script type="text/javascript"  src="<%=urlLoc %>/javascript/collaboration.js"></script>

      <script type="text/javascript" src="<%=urlLoc %>/javascript/notifications.js"></script>

      <script type="text/javascript"  src="<%=urlLoc %>/javascript/imageEnhancer.js"></script>
      <link type="text/css" href="<%=urlLoc %>/css/imageEnhancer.css" rel="stylesheet" />    

      <script src="<%=urlLoc %>/javascript/lazysizes.min.js"></script>

 	<!-- Start Open Graph Tags -->
 	<meta property="og:url" content="<%=request.getRequestURI() %>?<%=request.getQueryString() %>" />
  	<meta property="og:site_name" content="<%=CommonConfiguration.getHTMLTitle(context) %>"/>
  	<!-- End Open Graph Tags -->    


	<!-- Clockpicker on creatSurvey jsp -->
    <script type="text/javascript" src="<%=urlLoc %>/tools/clockpicker/jquery-clockpicker.min.js"></script>
    <link type="text/css" href="<%=urlLoc %>/tools/clockpicker/jquery-clockpicker.min.css" rel="stylesheet" /> 
   
    <style>
      ul.nav.navbar-nav {
        width: 100%;
      }

    </style>

    </head>

    <body role="document">

        <!-- ****header**** -->
        <header class="page-header clearfix" style="padding-top: 0px;padding-bottom:0px;">
            <nav class="navbar navbar-default navbar-fixed-top">
              <div class="header-top-wrapper">
                <div class="container">
                <div class="search-and-secondary-wrapper">
                    <ul class="secondary-nav hor-ul no-bullets">


                      <%
	                      if(user != null && !loggingOut){
	                          try {
  		                    	  String fullname=request.getUserPrincipal().toString();
                              if (user.getFullName()!=null) fullname=user.getFullName();


		                  %>

		                      		<li><a href="<%=urlLoc %>/myAccount.jsp" title=""><img align="left" title="<%=props.getProperty("yourAccount") %>" style="border-radius: 3px;border:1px solid #ffffff;margin-top: -7px;" width="*" height="32px" src="<%=profilePhotoURL %>" /></a></li>
		             				      <li><a href="<%=urlLoc %>/logout.jsp" ><%=props.getProperty("logout") %></a></li>

		                      		<%
	                          }
	                          catch(Exception e){e.printStackTrace();}
	                      }
	                      else{
	                      %>

	                      	<li><a href="<%=urlLoc %>/welcome.jsp" title=""><%=props.getProperty("login") %></a></li>

	                      <%
	                      }

                      %>





                      <%
                      if (CommonConfiguration.getWikiLocation(context)!=null) {
                      %>
                        <li><a target="_blank" href="<%=CommonConfiguration.getWikiLocation(context) %>"><%=props.getProperty("userWiki")%></a></li>
                      <%
                      }



                      List<String> contextNames=ContextConfiguration.getContextNames();
                		int numContexts=contextNames.size();
                		if(numContexts>1){
                		%>

                		<li>
                						<form>
                						<%=props.getProperty("switchContext") %>&nbsp;
                							<select style="color: black;" id="context" name="context">
			                					<%
			                					for(int h=0;h<numContexts;h++){
			                						String selected="";
			                						if(ServletUtilities.getContext(request).equals(("context"+h))){selected="selected=\"selected\"";}
			                					%>

			                						<option value="context<%=h%>" <%=selected %>><%=contextNames.get(h) %></option>
			                					<%
			                					}
			                					%>
                							</select>
                						</form>
                			</li>
                			<script type="text/javascript">

	                			$( "#context" ).change(function() {

		                  			//alert( "Handler for .change() called with new value: "+$( "#context option:selected" ).text() +" with value "+ $( "#context option:selected").val());
		                  			$.cookie("wildbookContext", $( "#context option:selected").val(), {
		                  			   path    : '/',          //The value of the path attribute of the cookie
		                  			                           //(default: path of page that created the cookie).

		                  			   secure  : false          //If set to true the secure attribute of the cookie
		                  			                           //will be set and the cookie transmission will
		                  			                           //require a secure protocol (defaults to false).
		                  			});

		                  			//alert("I have set the wildbookContext cookie to value: "+$.cookie("wildbookContext"));
		                  			location.reload(true);

	                			});

                			</script>
                			<%
                		}
                		%>
                		   <!-- Can we inject language functionality here? -->
                    <%

            		List<String> supportedLanguages=CommonConfiguration.getIndexedPropertyValues("language", context);
            		int numSupportedLanguages=supportedLanguages.size();

            		if(numSupportedLanguages>1){
            		%>
            			<li>


            					<%
            					for(int h=0;h<numSupportedLanguages;h++){
            						String selected="";
            						if(ServletUtilities.getLanguageCode(request).equals(supportedLanguages.get(h))){selected="selected=\"selected\"";}
            						String myLang=supportedLanguages.get(h);
            					%>
            						<img style="cursor: pointer" id="flag_<%=myLang %>" title="<%=CommonConfiguration.getProperty(myLang, context) %>" src="//<%=CommonConfiguration.getURLLocation(request) %>/images/flag_<%=myLang %>.gif" />
            						<script type="text/javascript">

            							$( "#flag_<%=myLang%>" ).click(function() {

            								//alert( "Handler for .change() called with new value: "+$( "#langCode option:selected" ).text() +" with value "+ $( "#langCode option:selected").val());
            								$.cookie("wildbookLangCode", "<%=myLang%>", {
            			   						path    : '/',          //The value of the path attribute of the cookie
            			                           //(default: path of page that created the cookie).

            			   						secure  : false          //If set to true the secure attribute of the cookie
            			                           //will be set and the cookie transmission will
            			                           //require a secure protocol (defaults to false).
            								});

            								//alert("I have set the wildbookContext cookie to value: "+$.cookie("wildbookContext"));
            								location.reload(true);

            							});

            						</script>
            					<%
            					}
            					%>

            		</li>
            		<%
            		}
            		%>
            		<!-- end language functionality injection -->




                    </ul>


                    <style type="text/css">
                      #header-search-button, #header-search-button:hover {
                        color: inherit;
                        background-color: inherit;
                        padding: 0px;
                        margin: 0px;
                      }
                    </style>
                    <script>
                      $('#header-search-button').click(function() {
                        document.forms['header-search'].submit();
                      })
                    </script>


                    <div class="search-wrapper">
                      <label class="search-field-header">
                            <form name="form2" id="header-search" method="get" action="<%=urlLoc %>/individuals.jsp">
                              <input type="text" id="search-site" placeholder="<%=props.getProperty("siteSearchDefault")%>" class="search-query form-control navbar-search ui-autocomplete-input" autocomplete="off" name="number" />
                              <input type="hidden" name="langCode" value="<%=langCode%>"/>
                              <span class="el el-lg el-search"></span>
                          </form>
                      </label>
                    </div>
                  </div>
                  <a class="navbar-brand wildbook" target="_blank" href="<%=urlLoc %>">Wildbook for Mark-Recapture Studies</a>
                  <a class="navbar-brand indocet" target="_blank" href="<%=urlLoc %>" style="display: none">Wildbook for Mark-Recapture Studies</a>

                </div>
              </div>

              <div class="nav-bar-wrapper">
                <div class="container">
                  <div class="navbar-header clearfix">
                    <button type="button" class="navbar-toggle collapsed" data-toggle="collapse" data-target="#navbar" aria-expanded="false" aria-controls="navbar">
                      <span class="sr-only">Toggle navigation</span>
                      <span class="icon-bar"></span>
                      <span class="icon-bar"></span>
                      <span class="icon-bar"></span>
                    </button>
                  </div>

                  <div id="navbar" class="navbar-collapse collapse">
                  <div id="notifications"><%= Collaboration.getNotificationsWidgetHtml(request) %></div>
                    <ul class="nav navbar-nav">

                      <li><!-- the &nbsp on either side of the icon aligns it with the text in the other navbar items, because by default them being different fonts makes that hard. Added two for horizontal symmetry -->
                        
                        <a href="<%=urlLoc %>">&nbsp<span class="el el-home"></span>&nbsp</a>
                      </li>

                      <li class="dropdown">
                        <a href="#" class="dropdown-toggle" data-toggle="dropdown" role="button" aria-expanded="false"><%=props.getProperty("submit")%> <span class="caret"></span></a>
                        <ul class="dropdown-menu" role="menu">
                            
                            <li><a href="<%=urlLoc %>/submit.jsp"><%=props.getProperty("report")%></a></li>
                            
                            <!--
                            <li class="dropdown"><a href="<%=urlLoc %>/surveys/createSurvey.jsp"><%=props.getProperty("createSurvey")%></a></li>
                            -->
                            
                            <li class="dropdown"><a href="<%=urlLoc %>/import/instructions.jsp"><%=props.getProperty("bulkImport")%></a></li>
                        </ul>
                      </li>                      
                      <li class="dropdown">
                        <a href="#" class="dropdown-toggle" data-toggle="dropdown" role="button" aria-expanded="false"><%=props.getProperty("learn")%> <span class="caret"></span></a>
                        <ul class="dropdown-menu" role="menu">

                        	<li class="dropdown"><a href="<%=urlLoc %>/overview.jsp"><%=props.getProperty("aboutYourProject")%></a></li>

                          	<li><a href="<%=urlLoc %>/citing.jsp"><%=props.getProperty("citing")%></a></li>

                          	<li><a href="<%=urlLoc %>/photographing.jsp"><%=props.getProperty("howToPhotograph")%></a></li>
                          	<li><a target="_blank" href="https://www.wildbook.org"><%=props.getProperty("learnAboutShepherd")%></a></li>
                        	<li class="divider"></li>
                        </ul>
                      </li>
                      <li class="dropdown">
                        <a href="#" class="dropdown-toggle" data-toggle="dropdown" role="button" aria-expanded="false"><%=props.getProperty("individuals")%> <span class="caret"></span></a>
                        <ul class="dropdown-menu" role="menu">
                          <li><a href="<%=urlLoc %>/gallery.jsp"><%=props.getProperty("gallery")%></a></li>

                          <li><a href="<%=urlLoc %>/individualSearchResults.jsp"><%=props.getProperty("viewAll")%></a></li>
                        </ul>
                      </li>
                      <li class="dropdown">
                        <a href="#" class="dropdown-toggle" data-toggle="dropdown" role="button" aria-expanded="false"><%=props.getProperty("occurrences")%> <span class="caret"></span></a>
                        <ul class="dropdown-menu" role="menu">
                          <li><a href="<%=urlLoc %>/occurrenceSearch.jsp"><%=props.getProperty("search")%></a></li>

                          <li><a href="<%=urlLoc %>/occurrenceSearchResults.jsp"><%=props.getProperty("viewAll")%></a></li>
                        </ul>
                      </li>
                      <li class="dropdown">
                        <a href="#" class="dropdown-toggle" data-toggle="dropdown" role="button" aria-expanded="false"><%=props.getProperty("encounters")%> <span class="caret"></span></a>
                        <ul class="dropdown-menu" role="menu">
                          <li class="dropdown-header"><%=props.getProperty("states")%></li>

                        <!-- list encounters by state -->
                          <% boolean moreStates=true;
                             int cNum=0;
                             while(moreStates) {
                                 String currentLifeState = "encounterState"+cNum;
                                 if (CommonConfiguration.getProperty(currentLifeState,context)!=null) { %>
                                   <li><a href="<%=urlLoc %>/encounters/searchResults.jsp?state=<%=CommonConfiguration.getProperty(currentLifeState,context) %>"><%=props.getProperty("viewEncounters").trim().replaceAll(" ",(" "+WordUtils.capitalize(CommonConfiguration.getProperty(currentLifeState,context))+" "))%></a></li>
                                 <% cNum++;
                                 } else {
                                     moreStates=false;
                                 }
                            } //end while %>
                          <li class="divider"></li>
                          <li><a href="<%=urlLoc %>/encounters/thumbnailSearchResults.jsp?noQuery=true"><%=props.getProperty("viewImages")%></a></li>
                          <li><a href="<%=urlLoc %>/xcalendar/calendar.jsp"><%=props.getProperty("encounterCalendar")%></a></li>
                          <% if(request.getUserPrincipal()!=null) { %>
                            <li><a href="<%=urlLoc %>/encounters/searchResults.jsp?username=<%=request.getRemoteUser()%>"><%=props.getProperty("viewMySubmissions")%></a></li>
                          <% } %>
                        </ul>
                      </li>


                      <li class="dropdown">
                        <a href="#" class="dropdown-toggle" data-toggle="dropdown" role="button" aria-expanded="false" id="search-dropdown"><%=props.getProperty("search")%> <span class="caret"></span></a>
                        <ul class="dropdown-menu" role="menu">
                              <li><a href="<%=urlLoc %>/encounters/encounterSearch.jsp" id="encounter-search-link"><%=props.getProperty("encounterSearch")%></a></li>
                              <li><a href="<%=urlLoc %>/individualSearch.jsp" id="individual-search-link"><%=props.getProperty("individualSearch")%></a></li>
                              <li><a href="<%=urlLoc %>/occurrenceSearch.jsp" id="occurrence-search-link"><%=props.getProperty("occurrenceSearch")%></a></li>
                              <!--
                              <li><a href="<%=urlLoc %>/surveys/surveySearch.jsp" id="survey-search-link"><%=props.getProperty("surveySearch")%></a></li>
                              <li><a href="<%=urlLoc %>/encounters/searchComparison.jsp" id="search-comparison-link"><%=props.getProperty("locationSearch")%></a></li>
                           	  -->
                           </ul>
                      </li>


                      <li class="dropdown">
                        <a href="#" class="dropdown-toggle" data-toggle="dropdown" role="button" aria-expanded="false"><%=props.getProperty("administer")%> <span class="caret"></span></a>
                        <ul class="dropdown-menu" role="menu">
                            <% if (CommonConfiguration.getWikiLocation(context)!=null) { %>
                              <li><a target="_blank" href="<%=CommonConfiguration.getWikiLocation(context) %>/photographing.jsp"><%=props.getProperty("userWiki")%></a></li>
                            <% }
                            if(request.getUserPrincipal()!=null) {
                            %>
                              <li><a href="<%=urlLoc %>/myAccount.jsp"><%=props.getProperty("myAccount")%></a></li>
                            <% }
                            if(CommonConfiguration.allowBatchUpload(context) && (request.isUserInRole("admin"))) { %>
                              <li><a href="<%=urlLoc %>/BatchUpload/start"><%=props.getProperty("batchUpload")%></a></li>
                            <% }
                            if(request.isUserInRole("admin")) { %>
                              <li><a href="<%=urlLoc %>/appadmin/admin.jsp"><%=props.getProperty("general")%></a></li>
                              <li><a href="<%=urlLoc %>/appadmin/logs.jsp"><%=props.getProperty("logs")%></a></li>
                                
                                <li><a href="<%=urlLoc %>/appadmin/users.jsp?context=context0"><%=props.getProperty("userManagement")%></a></li>
								<li><a href="<%=urlLoc %>/appadmin/intelligentAgentReview.jsp?context=context0"><%=props.getProperty("intelligentAgentReview")%></a></li>
								
                                <% 
                                if (CommonConfiguration.getIPTURL(context) != null) { %>
                                  <li><a href="<%=CommonConfiguration.getIPTURL(context) %>"><%=props.getProperty("iptLink")%></a></li>
                                <% } %>
                                <li><a href="<%=urlLoc %>/appadmin/kwAdmin.jsp"><%=props.getProperty("photoKeywords")%></a></li>
                                <% if (CommonConfiguration.allowAdoptions(context)) { %>
                                  <li class="divider"></li>
                                  <li class="dropdown-header"><%=props.getProperty("adoptions")%></li>
                                  <li><a href="<%=urlLoc %>/adoptions/adoption.jsp"><%=props.getProperty("createEditAdoption")%></a></li>
                                  <li><a href="<%=urlLoc %>/adoptions/allAdoptions.jsp"><%=props.getProperty("viewAllAdoptions")%></a></li>
                                  <li class="divider"></li>
                                <% } %>
                                <li><a target="_blank" href="http://www.wildbook.org"><%=props.getProperty("shepherdDoc")%></a></li>
                                <% 

                            } //end if admin
                            if(CommonConfiguration.isCatalogEditable(context) && request.getRemoteUser()!=null) { %>
                            	<li class="divider"></li>
                            	<li><a href="<%=urlLoc %>/import/instructions.jsp"><%=props.getProperty("bulkImport")%></a></li>
                            	<li><a href="<%=urlLoc %>/imports.jsp"><%=props.getProperty("standardImportListing")%></a></li>
                           	<%
                           
                           
                          	}
                            %>
                            <li class="dropdown">
                              <ul class="dropdown-menu" role="menu">
                              <%
                              if(CommonConfiguration.getProperty("allowAdoptions", context).equals("true")){
                              %>
                                <li><a href="<%=urlLoc %>/adoptananimal.jsp"><%=props.getProperty("adoptions")%></a></li>
                              <%
                              }
                              %>
                                <li><a href="<%=urlLoc %>/userAgreement.jsp"><%=props.getProperty("userAgreement")%></a></li>



                              </ul>
                            </li>



                            <%
                            if(CommonConfiguration.useSpotPatternRecognition(context)){
                            %>
                            	<li class="divider"></li>
                            	<li class="dropdown-header"><%=props.getProperty("grid")%></li>
                            	<li><a href="<%=urlLoc %>/appadmin/scanTaskAdmin.jsp?context=context0"><%=props.getProperty("gridAdministration")%></a></li>
                            	<li><a href="<%=urlLoc %>/software/software.jsp"><%=props.getProperty("gridSoftware")%></a></li>
                            <%
                            }
                            %>
                          </ul>
                        </li>
                      </ul>




                  </div>

                </div>
              </div>
            </nav>
        </header>

        <script>
        $('#search-site').autocomplete({
            // sortResults: true, // they're already sorted
            appendTo: $('#navbar-top'),
            response: function(ev, ui) {
                if (ui.content.length < 1) {
                    $('#search-help').show();
                } else {
                    $('#search-help').hide();
                }
            },
            select: function(ev, ui) {
                if (ui.item.type == "individual") {
                    window.location.replace("<%=("//" + CommonConfiguration.getURLLocation(request)+"/individuals.jsp?id=") %>" + ui.item.value);
                }
                else if (ui.item.type == "encounter") {
                	window.location.replace("<%=("//" + CommonConfiguration.getURLLocation(request)+"/encounters/encounter.jsp?number=") %>" + ui.item.value);
                }
                else if (ui.item.type == "locationID") {
                	window.location.replace("<%=("//" + CommonConfiguration.getURLLocation(request)+"/encounters/searchResultsAnalysis.jsp?locationCodeField=") %>" + ui.item.value);
                }
                /*
                //restore user later
                else if (ui.item.type == "user") {
                    window.location.replace("/user/" + ui.item.value);
                }
                else {
                    alertplus.alert("Unknown result [" + ui.item.value + "] of type [" + ui.item.type + "]");
                }
                */
                return false;
            },
            //source: app.config.wildbook.proxyUrl + "/search"
            source: function( request, response ) {
                $.ajax({
                    url: '<%=("//" + CommonConfiguration.getURLLocation(request)) %>/SiteSearch',
                    dataType: "json",
                    data: {
                        term: request.term
                    },
                    success: function( data ) {
                        var res = $.map(data, function(item) {
                            var label="";
                            var nickname="";
                            if ((item.type == "individual")&&(item.species!=null)) {
//                                label = item.species + ": ";
                            }
                            else if (item.type == "user") {
                                label = "User: ";
                            } else {
                                label = "";
                            }
                            
                            if(item.nickname != null){
                            	nickname = " ("+item.nickname+")";
                            }
                            
                            return {label: label + item.label+nickname,
                                    value: item.value,
                                    type: item.type,
                                    nickname: nickname};
                            });

                        response(res);
                    }
                });
            }
        });
        //prevent enter key on tyeahead
        $('#search-site').keydown(function (e) {
                	    if (e.keyCode == 13) {
                	        e.preventDefault();
                	        return false;
                	    }
        });


        // if there is an organization param, set it as a cookie so you can get yer stylez without appending to all locations
        let urlParams = new URLSearchParams(window.location.search);
        if (urlParams.has("organization")) {
          let orgParam = urlParams.get("organization");
          $.cookie("wildbookOrganization", orgParam, {
              path    : '/',     
              secure  : false, 
              expires : 1
          });
        }


        </script>

        <!-- ****/header**** -->
