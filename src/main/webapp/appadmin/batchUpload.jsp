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
	~ MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.	See the
	~ GNU General Public License for more details.
	~
	~ You should have received a copy of the GNU General Public License
	~ along with this program; if not, write to the Free Software
	~ Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA	02110-1301, USA.
--%>
<%@page import="java.text.MessageFormat"%>
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN"
    "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<%@page contentType="text/html; charset=iso-8859-1" language="java"
				 import="org.ecocean.CommonConfiguration"
				 import="org.ecocean.Shepherd"
				 import="org.ecocean.Keyword"
				 import="java.io.File"
				 import="java.io.IOException"
         import="java.util.Enumeration"
         import="java.util.Iterator"
         import="java.util.List"
         import="java.util.ArrayList"
         import="java.util.Locale"
         import="java.util.Properties"
         import="java.util.ResourceBundle"
         import="java.util.TreeSet"
         import="org.slf4j.Logger"
         import="org.slf4j.LoggerFactory"
%>
<%@taglib uri="http://java.sun.com/jsp/jstl/core" prefix="c" %>
<%
	Shepherd myShepherd = new Shepherd();
	response.setHeader("Cache-Control", "no-cache"); //Forces caches to obtain a new copy of the page from the origin server
	response.setHeader("Cache-Control", "no-store"); //Directs caches not to store the page under any circumstance
	response.setDateHeader("Expires", 0); //Causes the proxy cache to see the page as "stale"
	response.setHeader("Pragma", "no-cache"); //HTTP 1.0 backward compatibility

  // --------------------------------------------------------------------------
  // Page internationalization.
  // Code is use below is a compromise to fit in with the current i18n mechanism.
  // Ideally it should use the proper ResourceBundle lookup mechanism, and when
  // not explicitly chosen by the user, find supported languages/variants from
  // the browser configuration.
  String langCode = "en";
  if (session.getAttribute("langCode") != null) {
    langCode = (String)session.getAttribute("langCode");
  } else {
    Locale loc = request.getLocale();
    langCode = loc.getLanguage();
  }
//  Locale locale = new Locale(langCode);
//  ResourceBundle bundle = ResourceBundle.getBundle("/bundles/batchUpload", locale);
  Properties bundle = new Properties();
  bundle.load(getClass().getResourceAsStream("/bundles/batchUpload_" + langCode + ".properties"));
  // --------------------------------------------------------------------------

  List<String> errors = (List<String>)session.getAttribute("batchErrors");
  boolean hasErrors = errors != null && !errors.isEmpty();

  // If landed directly on page without forwarding, reset ready for use.
  String uri = (String)request.getAttribute("javax.servlet.forward.request_uri");
  if (uri == null || "".equals(uri)) {
    for (Enumeration e = session.getAttributeNames(); e.hasMoreElements();) {
      String s = (String)e.nextElement();
      if (s.toLowerCase().startsWith("batch"))
        session.removeAttribute(s);
    }
  }
  // Define template/data types.
  final String[] TYPES = {"Ind", "Enc", "Mea", "Med", "Sam"};
%>
<%!
  private static Logger log = LoggerFactory.getLogger(org.ecocean.batch.BatchParser.class);

  private final String createOptionsList(int i, String langCode) throws IOException {
    List<String> list = new ArrayList<String>();
    List<String> temp = new ArrayList<String>();
    TreeSet<String> set = null;
    switch (i) {
      case 0:
      case 1:
        list = CommonConfiguration.getSequentialPropertyValues("sex");
        break;
      case 2:
        temp = CommonConfiguration.getSequentialPropertyValues("genusSpecies");
        set = new TreeSet<String>();
        for (String s : temp)
          set.add(s.substring(0, s.indexOf(" ")));
        list.addAll(set);
        break;
      case 3:
        temp = CommonConfiguration.getSequentialPropertyValues("genusSpecies");
        set = new TreeSet<String>();
        for (String s : temp)
          set.add(s.substring(s.indexOf(" ") + 1));
        list.addAll(set);
        break;
      case 4:
        list = CommonConfiguration.getSequentialPropertyValues("locationID");
        break;
      case 5:
        list = CommonConfiguration.getSequentialPropertyValues("livingStatus");
        break;
      case 6:
        list = CommonConfiguration.getSequentialPropertyValues("lifeStage");
        break;
      case 7:
        Properties props = new Properties();
        props.load(getClass().getResourceAsStream("/bundles/" + langCode + "/encounter.properties"));
        list.add(props.getProperty("unmatchedFirstEncounter"));
        list.add(props.getProperty("visualInspection"));
        list.add(props.getProperty("automatedMatching"));
        break;
      case 8:
        list = CommonConfiguration.getSequentialPropertyValues("measurement");
        break;
      case 9:
        list = CommonConfiguration.getSequentialPropertyValues("measurementUnits");
        break;
      case 10:
        list = CommonConfiguration.getSequentialPropertyValues("samplingProtocol");
        break;
      case 11:
        Shepherd shep = new Shepherd();
        for (Iterator iter = shep.getAllKeywords(); iter.hasNext();)
          list.add(((Keyword)iter.next()).getReadableName());
        shep.closeDBTransaction();
        shep = null;
        break;
      case 12:
        list = CommonConfiguration.getSequentialPropertyValues("tissueType");
        break;
      case 13: // FIXME
        list = CommonConfiguration.getSequentialPropertyValues("preservationMethod");
        break;
      default:
    }
//    log.trace(String.format("EnumList has %d items: %s", list.size(), list));
    StringBuilder sb = new StringBuilder();
    sb.append("<br />{");
    for (String s : list)
      sb.append("<span class=\"example\">&quot;").append(s).append("&quot;</span>, ");
    sb.setLength(sb.length() - 2);
    sb.append("}");
//    log.trace(String.format("EnumList: %s", sb.toString()));
    return sb.toString();
  }
%>
<html>
<head>
	<title><%=CommonConfiguration.getHTMLTitle() %></title>
	<meta http-equiv="Content-Type" content="text/html; charset=utf-8"/>
	<meta name="Description" content="<%=CommonConfiguration.getHTMLDescription() %>"/>
	<meta name="Keywords" content="<%=CommonConfiguration.getHTMLKeywords() %>"/>
	<meta name="Author" content="<%=CommonConfiguration.getHTMLAuthor() %>"/>
	<link href="<%=CommonConfiguration.getCSSURLLocation(request) %>" rel="stylesheet" type="text/css"/>
	<link rel="shortcut icon" href="<%=CommonConfiguration.getHTMLShortcutIcon() %>"/>
	<link href="../css/batchUpload.css" rel="stylesheet" type="text/css"/>
</head>

<body>
<div id="wrapper">
	<div id="page">
		<jsp:include page="../header.jsp" flush="true">
			<jsp:param name="isAdmin" value="<%=request.isUserInRole(\"admin\")%>"/>
		</jsp:include>
		<div id="main">

      <h1><%=bundle.getProperty("gui.title")%></h1>
			<p><%=bundle.getProperty("gui.overview")%></p>

      <% if (hasErrors) { %>
      <div id="errors">
        <hr />
  			<h2><%=bundle.getProperty("gui.errors.title")%></h2>
        <ul id="errorList">
        <c:forEach var="err" items="${batchErrors}">
          <li>${err}</li>
        </c:forEach>
        </ul>
        <hr />
      </div>
      <% } %>

			<h2><%=bundle.getProperty("gui.step1.title")%></h2>
			<p><%=bundle.getProperty("gui.step1.text")%></p>

      <ul id="templateList">
        <% for (String type : TYPES) { %>
          <% if (type.equals("Ind") || type.equals("Enc")) { %>
        <li class="required"><a href="../BatchUpload/template<%=type%>"><%=bundle.getProperty("gui.step1.template." + type.toLowerCase(Locale.US))%></a></li>
          <% } else { %>
        <li><a href="../BatchUpload/template<%=type%>"><%=bundle.getProperty("gui.step1.template." + type.toLowerCase(Locale.US))%></a></li>
          <% } %>
        <% } %>
      </ul>

			<h2><%=bundle.getProperty("gui.step2.title")%></h2>
			<p><%=bundle.getProperty("gui.step2.text")%></p>
      <ul id="rules">
      <% for (int i = 0; i <= 14; i++) { %>
        <li><%=bundle.getProperty("gui.step2.list" + i)%></li>
      <% } %>
      <% for (int i = 0; i <= 13; i++) { %>
      <li><%=MessageFormat.format(bundle.getProperty("gui.step2.enums.list" + i), createOptionsList(i, langCode))%></li>
      <% } %>
      </ul>
			<p><%=bundle.getProperty("gui.step2.text2")%></p>

<%
  String batchPlugin = CommonConfiguration.getBatchUploadPlugin();
  if (batchPlugin != null) {
%>
      <p class="pluginText"><%=bundle.getProperty("gui.step2.pluginText")%></p>
<%
  }
%>

			<h2><%=bundle.getProperty("gui.step3.title")%></h2>
			<p><%=bundle.getProperty("gui.step3.text")%></p>
			<!--<h3><%=bundle.getProperty("gui.titleForm")%></h3>-->
      <form name="batchUpload" method="post" enctype="multipart/form-data" accept-charset="utf-8" action="../BatchUpload/uploadBatchData">
			<table id="batchTable">
        <% for (String type : TYPES) { %>
				<tr>
					<td class="required"><%=bundle.getProperty("gui.step3.form.text." + type.toLowerCase(Locale.US))%></td>
					<td><input name="csv<%=type%>" type="file" id="csv<%=type%>" size="20" maxlength="255"></td>
				</tr>
        <% } %>
				<tr>
					<td colspan="3">
            <input type="submit" id="upload" value="<%=bundle.getProperty("gui.step3.form.submit")%>">
            <input type="reset" id="reset" value="<%=bundle.getProperty("gui.step3.form.reset")%>">
          </td>
				</tr>
			</table>
			</form>
			<p class="notice"><%=bundle.getProperty("gui.step3.text2")%></p>

			<h2><%=bundle.getProperty("gui.step4.title")%></h2>
			<p><%=bundle.getProperty("gui.step4.text")%></p>

			<h2><%=bundle.getProperty("gui.step5.title")%></h2>
			<p><%=bundle.getProperty("gui.step5.text")%></p>

<%
  // Clean up page resources.
  myShepherd.rollbackDBTransaction();
  myShepherd.closeDBTransaction();
%>
			<jsp:include page="../footer.jsp" flush="true"/>
		</div>
	</div>
	<!-- end page --></div>
<!--end wrapper -->
</body>
</html>


