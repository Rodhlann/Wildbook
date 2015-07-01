<%--
  ~ The Shepherd Project - A Mark-Recapture Framework
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

<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN"
"http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<%@ page contentType="text/html; charset=utf-8" language="java"
     import="org.ecocean.ShepherdProperties,
             org.ecocean.servlet.ServletUtilities,
             org.ecocean.CommonConfiguration,
             java.util.ArrayList,
             java.util.Properties,
             org.apache.commons.lang.WordUtils
   	       "
%>

<%
String context="context0";
context=ServletUtilities.getContext(request);
String langCode=ServletUtilities.getLanguageCode(request);
Properties props = new Properties();
props = ShepherdProperties.getProperties("header.properties", langCode, context);
%>

<html xmlns="http://www.w3.org/1999/xhtml">
    <head>
      <title><%=CommonConfiguration.getHTMLTitle(context)%>
      </title>
      <meta http-equiv="Content-Type" content="text/html; charset=utf-8"/>
      <meta name="Description"
            content="<%=CommonConfiguration.getHTMLDescription(context) %>"/>
      <meta name="Keywords"
            content="<%=CommonConfiguration.getHTMLKeywords(context) %>"/>
      <meta name="Author" content="<%=CommonConfiguration.getHTMLAuthor(context) %>"/>
      <link href="<%=CommonConfiguration.getCSSURLLocation(request, context) %>"
            rel="stylesheet" type="text/css"/>
      <link rel="shortcut icon"
            href="<%=CommonConfiguration.getHTMLShortcutIcon(context) %>"/>
      <link href='http://fonts.googleapis.com/css?family=Oswald:400,300,700' rel='stylesheet' type='text/css'>
      <link rel="stylesheet" href="cust/mantamatcher/css/manta.css" />

      <script src="tools/jquery/js/jquery.min.js"></script>
      <script src="tools/bootstrap/js/bootstrap.min.js"></script>
      <script type="text/javascript" src="javascript/core.js"></script>
	  <script type="text/javascript" src="tools/jquery-ui/javascript/jquery-ui.min.js"></script>
 	  <script type="text/javascript" src="tools/hello/javascript/hello.all.js"></script>

    </head>
    <body role="document">
        <!-- ****header**** -->
        <header class="page-header clearfix">
            <nav class="navbar navbar-default navbar-fixed-top">
              <div class="header-top-wrapper">
                <div class="container">
                  <div class="search-and-secondary-wrapper">
                    <ul class="secondary-nav hor-ul no-bullets">
                      <li><a href="#" title="">English</a></li><li><a href="http://<%=CommonConfiguration.getURLLocation(request) %>/welcome.jsp" title="">Login</a></li>
                      <%
          					if (CommonConfiguration.getWikiLocation(context)!=null) {
        					%>
						        <li><a target="_blank" href="<%=CommonConfiguration.getWikiLocation(context) %>"><%=props.getProperty("userWiki")%></a></li>
						        <% 
						    } 
                      %>
                    </ul>
                    <div class="search-wrapper">
                      <label class="search-field-header">
                      	<form name="form2" method="get" action="http://<%=CommonConfiguration.getURLLocation(request) %>/individuals.jsp">
                        	<input placeholder="record nr., encounter nr., nickname or id" name="number" />
                        	<input type="hidden" name="langCode" value="<%=langCode%>"/>
                        	<input type="submit" value="search" />
                        </form>

                      </label>
                    </div>
                  </div>
                  <a class="navbar-brand" href="/">MantaMatcher the Wildbook for Manta Rays</a>
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
                    <ul class="nav navbar-nav">
                                  <!--                -->
                      <li class="active home text-hide"><a href="http://<%=CommonConfiguration.getURLLocation(request) %>"><%=props.getProperty("home")%></a></li>
                      <li><a href="http://<%=CommonConfiguration.getURLLocation(request) %>/submit.jsp"><%=props.getProperty("report")%></a></li>
                   
                      <li class="dropdown">
                        <a href="#" class="dropdown-toggle" data-toggle="dropdown" role="button" aria-expanded="false">Learn <span class="caret"></span></a>
                        <ul class="dropdown-menu" role="menu">
                        
                          <li><a href="http://<%=CommonConfiguration.getURLLocation(request) %>/photographing.jsp">How to Photograph</a></li>
                          <li><a target="_blank" href="http://www.wildme.org/wildbook">Learn about Wildbook</a></li>
                        </ul>
                      </li>
                      
                      
                      <li class="dropdown">
                        <a href="#" class="dropdown-toggle" data-toggle="dropdown" role="button" aria-expanded="false"><%=props.getProperty("participate")%> <span class="caret"></span></a>
                        <ul class="dropdown-menu" role="menu">
                          <li><a href="http://<%=CommonConfiguration.getURLLocation(request) %>/adoptamanta.jsp">Adopt a Manta</a></li>
                             
                          
                          
                          <li><a href="<%=CommonConfiguration.getWikiLocation(context) %>mantamatcher_library_access_policy"><%=props.getProperty("accessPolicy")%></a></li>
                          <li><a href="http://<%=CommonConfiguration.getURLLocation(request) %>/userAgreement.jsp"><%=props.getProperty("userAgreement")%></a></li>
                          
                          
                          <!--  examples of navigation dividers
                          <li class="divider"></li>
                          <li class="dropdown-header">Nav header</li>
                           -->
                          
                        </ul>
                      </li>
                      <li class="dropdown">
                        <a href="#" class="dropdown-toggle" data-toggle="dropdown" role="button" aria-expanded="false">Individuals <span class="caret"></span></a>
                        <ul class="dropdown-menu" role="menu">
                        
                          <li><a href="http://<%=CommonConfiguration.getURLLocation(request) %>/individualSearchResults.jsp"><%=props.getProperty("viewAll")%></a></li>

                        </ul>
                      </li>
                      <li class="dropdown">
                        <a href="#" class="dropdown-toggle" data-toggle="dropdown" role="button" aria-expanded="false">Encounters <span class="caret"></span></a>
                        <ul class="dropdown-menu" role="menu">
                        
                          
                          <li class="dropdown-header">By State</li>
                        
                        <!-- list encounters by state -->
      						<%
      						boolean moreStates=true;
      						int cNum=0;
							while(moreStates){
	  								String currentLifeState = "encounterState"+cNum;
	  								if(CommonConfiguration.getProperty(currentLifeState,context)!=null){
	  									%>
	  									<li><a href="http://<%=CommonConfiguration.getURLLocation(request) %>/encounters/searchResults.jsp?state=<%=CommonConfiguration.getProperty(currentLifeState,context) %>"><%=props.getProperty("viewEncounters").trim().replaceAll(" ",(" "+WordUtils.capitalize(CommonConfiguration.getProperty(currentLifeState,context))+" "))%></a></li>
										
										<%
										cNum++;
	  									
  									}
  									else{
     									moreStates=false;
  									}
  
							} //end while
      						%>
      						
      						<li class="divider"></li>
      						
      						<li><a href="http://<%=CommonConfiguration.getURLLocation(request) %>/encounters/thumbnailSearchResults.jsp?noQuery=true"><%=props.getProperty("viewImages")%></a></li>
      						
      						<li><a href="http://<%=CommonConfiguration.getURLLocation(request) %>/xcalendar/calendar.jsp"><%=props.getProperty("encounterCalendar")%></a></li>



      						<%
						     if(request.getUserPrincipal()!=null){
						     %>
						       
						       <li><a href="http://<%=CommonConfiguration.getURLLocation(request) %>/encounters/searchResults.jsp?username=<%=request.getRemoteUser()%>"><%=props.getProperty("viewMySubmissions")%></a></li>
						       
						    <%
						    }
						    %>
                          
                        
                        </ul>
                      </li>
                      
                      
                      
                     
                      <li class="dropdown">
                        <a href="#" class="dropdown-toggle" data-toggle="dropdown" role="button" aria-expanded="false"><%=props.getProperty("search")%> <span class="caret"></span></a>
                        <ul class="dropdown-menu" role="menu">
							  <li><a href="http://<%=CommonConfiguration.getURLLocation(request) %>/encounters/encounterSearch.jsp"><%=props.getProperty("encounterSearch")%></a></li>
						      <li><a href="http://<%=CommonConfiguration.getURLLocation(request) %>/individualSearch.jsp"><%=props.getProperty("individualSearch")%></a></li>
						      <li><a href="http://<%=CommonConfiguration.getURLLocation(request) %>/encounters/searchComparison.jsp"><%=props.getProperty("locationSearch")%></a></li>
						       <li><a href="http://<%=CommonConfiguration.getURLLocation(request) %>/googleSearch.jsp"><%=props.getProperty("googleSearch")%></a></li>
						</ul>
                      </li>
                      
                      
             
                      <li class="dropdown">
                        <a href="http://<%=CommonConfiguration.getURLLocation(request) %>/overview.jsp">About</a>
                      </li>
                      
     
                      
                      <li>
                        <a href="http://<%=CommonConfiguration.getURLLocation(request) %>/contactus.jsp"><%=props.getProperty("contactUs")%> </a>
                      </li>
                      
                      
                      <li class="dropdown">
                        <a href="#" class="dropdown-toggle" data-toggle="dropdown" role="button" aria-expanded="false"><%=props.getProperty("administer")%> <span class="caret"></span></a>
                        <ul class="dropdown-menu" role="menu">
                        
                        	<%
          					if (CommonConfiguration.getWikiLocation(context)!=null) {
        					%>
						        <li><a target="_blank" href="<%=CommonConfiguration.getWikiLocation(context) %>/photographing.jsp"><%=props.getProperty("userWiki")%></a></li>
                          
						        <% 
						    } 	      
                        	if(request.getUserPrincipal()!=null){
						    %>
						  	    <li><a href="http://<%=CommonConfiguration.getURLLocation(request) %>/myAccount.jsp"><%=props.getProperty("myAccount")%></a></li>

						  	<%
						  	     
						  	}
                        	
                        	
                        	if(request.isUserInRole("admin")){
							%>
	
						    	<li><a href="http://<%=CommonConfiguration.getURLLocation(request) %>/appadmin/admin.jsp"><%=props.getProperty("general")%></a></li>
<%
						        if(CommonConfiguration.allowBatchUpload(context)){
						        %>
						        	<li><a href="http://<%=CommonConfiguration.getURLLocation(request) %>/BatchUpload/start"><%=props.getProperty("batchUpload")%></a></li>
								<%
						        }
								%>
								
								<li><a href="http://<%=CommonConfiguration.getURLLocation(request) %>/appadmin/logs.jsp"><%=props.getProperty("logs")%></a></li>
								
	                			<%
						        if(CommonConfiguration.useSpotPatternRecognition(context)){
						        %>
						         <li><a href="http://<%=CommonConfiguration.getURLLocation(request) %>/software/software.jsp"><%=props.getProperty("gridSoftware")%></a></li>
								
						        <%
						        }
						        %>

								<li><a href="http://<%=CommonConfiguration.getURLLocation(request) %>/appadmin/users.jsp?context=context0"><%=props.getProperty("userManagement")%></a></li>
								
						        <%
						          if (CommonConfiguration.getTapirLinkURL(context) != null) {
						        %>
						        	<li><a href="<%=CommonConfiguration.getTapirLinkURL(context) %>"><%=props.getProperty("tapirLink")%></a></li>
								
						        <% 
						        } 
						        
						        if (CommonConfiguration.getIPTURL(context) != null) {
						        %>
						        	<li><a href="<%=CommonConfiguration.getIPTURL(context) %>"><%=props.getProperty("iptLink")%></a></li>
								<% 
					        	} 
					        	%>
        
	        					<li><a href="http://<%=CommonConfiguration.getURLLocation(request) %>/appadmin/kwAdmin.jsp"><%=props.getProperty("photoKeywords")%></a></li>
								
	        					<%
								if (CommonConfiguration.allowAdoptions(context)) {
						        %>
						        
							        <li class="divider"></li>
						            <li class="dropdown-header"><%=props.getProperty("adoptions")%></li>
		        					<li><a href="http://<%=CommonConfiguration.getURLLocation(request) %>/adoptions/adoption.jsp"><%=props.getProperty("createEditAdoption")%></a></li>
									<li><a href="http://<%=CommonConfiguration.getURLLocation(request) %>/adoptions/allAdoptions.jsp"><%=props.getProperty("viewAllAdoptions")%></a></li>
									<li class="divider"></li>
	        					<%
	        					}
	          					%>

		     					<li><a target="_blank" href="http://www.wildme.org/wildbook"><%=props.getProperty("shepherdDoc")%></a></li>
								<li><a href="http://<%=CommonConfiguration.getURLLocation(request) %>/javadoc/index.html">Javadoc</a></li>
								
			
								<%
								if(CommonConfiguration.isCatalogEditable(context)){
								%>			
									<li class="divider"></li>			
									<li><a href="http://<%=CommonConfiguration.getURLLocation(request) %>/appadmin/import.jsp">Data Import</a></li>
								
								<%
								}
			
			
			
							} //end if admin
	
							%>	
                        
                        
                          
                          
                        </ul>
                      </li>
                      
                      
                    </ul>
                  </div>
                </div>
              </div>
            </nav>
        </header>
        <!-- ****/header**** -->
