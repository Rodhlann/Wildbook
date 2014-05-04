<%--
  ~ The Shepherd Project - A Mark-Recapture Framework
  ~ Copyright (C) 2011 Jason Holmberg
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
<%@ page contentType="text/html; charset=iso-8859-1" language="java"
         import="org.ecocean.servlet.ServletUtilities,org.ecocean.CommonConfiguration, org.ecocean.Keyword, org.ecocean.Shepherd" %>
<%@ page import="javax.jdo.Extent" %>
<%@ page import="javax.jdo.Query" %>
<%@ page import="java.util.Iterator" %>
<%

String context="context0";
context=ServletUtilities.getContext(request);
  Shepherd myShepherd = new Shepherd(context);
  Extent allKeywords = myShepherd.getPM().getExtent(Keyword.class, true);
  Query kwQuery = myShepherd.getPM().newQuery(allKeywords);

//handle some cache-related security
  response.setHeader("Cache-Control", "no-cache"); //Forces caches to obtain a new copy of the page from the origin server
  response.setHeader("Cache-Control", "no-store"); //Directs caches not to store the page under any circumstance
  response.setDateHeader("Expires", 0); //Causes the proxy cache to see the page as "stale"
  response.setHeader("Pragma", "no-cache"); //HTTP 1.0 backward compatibility
%>

<html>
<head>
  <title><%=CommonConfiguration.getHTMLTitle(context) %>
  </title>
  <meta http-equiv="Content-Type" content="text/html; charset=utf-8"/>
  <meta name="Description"
        content="<%=CommonConfiguration.getHTMLDescription(context) %>"/>
  <meta name="Keywords"
        content="<%=CommonConfiguration.getHTMLKeywords(context) %>"/>
  <meta name="Author" content="<%=CommonConfiguration.getHTMLAuthor(context) %>"/>
  <link href="<%=CommonConfiguration.getCSSURLLocation(request,context) %>"
        rel="stylesheet" type="text/css"/>
  <link rel="shortcut icon"
        href="<%=CommonConfiguration.getHTMLShortcutIcon(context) %>"/>

</head>

<body>
<div id="wrapper">
  <div id="page">
    <jsp:include page="../header.jsp" flush="true">
      <jsp:param name="isAdmin" value="<%=request.isUserInRole(\"admin\")%>" />
    </jsp:include>
    <div id="main">
      <%
        myShepherd.beginDBTransaction();
      %>
      <p>

      <h1 class="intro">
        <table>
          <tr>
            <td><img src="../images/keyword_icon_large.gif" width="50" height="50"
                     hspace="3" vspace="3" align="absmiddle"/> Image Keyword
              Administration
            </td>
          </tr>
        </table>
      </h1>
      </p>
      <p>There are currently <%=myShepherd.getNumKeywords()%> keywords
        defined in the database.</p>
      <table width="720" border="1" cellpadding="3" bordercolor="#000000"
             bgcolor="#CCCCCC">
        <tr>
          <td>
            <p><strong>Add a new keyword</strong></p>

            <form action="../KeywordHandler" method="post" name="addNew" id="addNew">

              <p>New keyword description (visible to users): 
              <input name="readableName" type="text" id="readableName" size="40" maxlength="40"> 
              <br />
              Example: <font face="Courier New, Courier, mono">scar, fin, 1st dorsal</font></p>
				<input name="action" type="hidden" id="action" value="addNewWord" />
              <p><input type="submit" name="Submit" value="Add"></p>
            </form>
          </td>
        </tr>
      </table>
      <p>&nbsp;</p>
      <table width="720" border="1" cellpadding="3" bordercolor="#000000"
             bgcolor="#CCCCCC">
        <tr>
          <td>
            <p><strong>Remove a keyword</strong></p>

            <form action="../KeywordHandler" method="post" name="removeWord"
                  id="removeWord">
              <p>Keyword to remove: <select name="keyword" id="keyword">

                <%
                  int totalKeywords = myShepherd.getNumKeywords();
                  Iterator keys = myShepherd.getAllKeywords(kwQuery);
                  for (int n = 0; n < totalKeywords; n++) {
                    Keyword word = (Keyword) keys.next();
                %>

                <option value="<%=word.getReadableName()%>"><%=word.getReadableName()%>
                </option>
                <%}%>

              </select> <input name="action" type="hidden" id="action" value="removeWord"></p>
              <p><input name="Submit2" type="submit" id="Submit2" value="Remove"></p>
            </form>
          </td>
        </tr>
      </table>
      <p>&nbsp;</p>
      <table width="720" border="1" cellpadding="3" bordercolor="#000000"
             bgcolor="#CCCCCC">
        <tr>
          <td>
            <p><strong>Rename a keyword</strong></p>

            <form action="../KeywordHandler" method="post" name="renameWord"
                  id="remnameWord">
              <p>Keyword to rename: <select name="keyword" id="keyword">

                <%

                  keys = myShepherd.getAllKeywords(kwQuery);
                  for (int w = 0; w < totalKeywords; w++) {
                    Keyword word = (Keyword) keys.next();
                %>

                <option value="<%=word.getReadableName()%>"><%=word.getReadableName()%>
                </option>
                <%}%>

              </select>
              <p>New keyword description (visible to users): <input
                name="newName" type="text" id="newName" size="40" maxlength="40"></p>
              <input name="action" type="hidden" id="action" value="rename"></p>
              <p><input name="Submit2" type="submit" id="Submit2" value="Rename"></p>
            </form>
          </td>
        </tr>
      </table>

      <%
        kwQuery.closeAll();
        myShepherd.rollbackDBTransaction();
        myShepherd.closeDBTransaction();
        kwQuery = null;
        myShepherd = null;
      %>
      <jsp:include page="../footer.jsp" flush="true"/>
    </div>
  </div>
  <!-- end page --></div>
<!--end wrapper -->
</body>
</html>


