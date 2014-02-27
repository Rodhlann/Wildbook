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
<%@page import="org.ecocean.servlet.ServletUtilities"%>
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN"
    "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<%@page contentType="text/html; charset=iso-8859-1" language="java"
				 import="org.ecocean.CommonConfiguration"
				 import="org.ecocean.Shepherd"
				 import="org.ecocean.batch.BatchProcessor"
				 import="org.ecocean.servlet.BatchUpload"
				 import="java.io.File"
				 import="java.io.PrintWriter"
				 import="java.text.MessageFormat"
         import="java.util.Enumeration"
         import="java.util.List"
         import="java.util.Locale"
         import="java.util.Properties"
         import="java.util.ResourceBundle"
%>
<%@taglib uri="http://java.sun.com/jsp/jstl/core" prefix="c" %>
<%@taglib uri="http://java.sun.com/jstl/fmt" prefix="fmt" %>
<%
  // Page internationalization.
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

  BatchProcessor proc = (BatchProcessor)session.getAttribute(BatchUpload.SESSION_KEY_TASK);
  if (proc == null) {
    BatchUpload.flushSessionInfo(request);
    response.sendRedirect(BatchUpload.JSP_MAIN);
  }

  response.setHeader("Cache-Control", "no-cache"); //Forces caches to obtain a new copy of the page from the origin server
	response.setHeader("Cache-Control", "no-store"); //Directs caches not to store the page under any circumstance
	response.setDateHeader("Expires", 0); //Causes the proxy cache to see the page as "stale"
	response.setHeader("Pragma", "no-cache"); //HTTP 1.0 backward compatibility


  List<String> errors = proc.getErrors();
  List<String> warnings = proc.getWarnings();
  boolean isFinished = proc.getStatus() == BatchProcessor.Status.FINISHED;
  boolean hasErrors = errors != null && !errors.isEmpty() || proc.getStatus() == BatchProcessor.Status.ERROR;
  boolean hasWarnings = warnings != null && !warnings.isEmpty();
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
	<link href="../css/gui-meter.css" rel="stylesheet" type="text/css"/>
  <script type="text/javascript" src="http://ajax.googleapis.com/ajax/libs/jquery/1.10.1/jquery.min.js"></script>
<%  if (!isFinished && !hasErrors) { %>
  <script language="javascript" type="text/javascript">
    var INTERVAL = 1000 * <%=CommonConfiguration.getBatchUploadProgressRefresh()%>;
    var PHASE_NONE = "<%=bundle.getProperty("gui.progress.status.phase.NONE")%>";
    var PHASE_MEDIA_DOWNLOAD = "<%=bundle.getProperty("gui.progress.status.phase.MEDIA_DOWNLOAD")%>";
    var PHASE_PERSISTENCE = "<%=bundle.getProperty("gui.progress.status.phase.PERSISTENCE")%>";
    var PHASE_THUMBNAILS = "<%=bundle.getProperty("gui.progress.status.phase.THUMBNAILS")%>";
    var PHASE_PLUGIN = "<%=proc.getPluginPhaseMessage()%>";
    var PHASE_DONE = "<%=bundle.getProperty("gui.progress.status.phase.DONE")%>";

    function refreshProgress() {
      $.ajax({
        url:'../BatchUpload/getBatchProgress',
        cache:false,
        dataType:'json',
        success:function(data) {
          if (data.error == undefined) {
            if (data.status == 'FINISHED' || data.status == 'ERROR') {
              window.location.href = window.location.href;
              return;
            }
            if (!$('#ajaxProblem').hasClass('hidden'))
              $('#ajaxProblem').addClass('hidden');
            // Update progress display & phase text.
            $('#progressMeter').width(data.progress + '%');
            $('#percent').text(data.progress + '%');
            $('#phase').text(eval('PHASE_' + data.phase));
            // Ensure progress displays are visible.
            $('#progress, #progressMeter, #phase').css('visibility', 'visible');
            setTimeout(refreshProgress, INTERVAL);
          } else {
            window.location.href = window.location.href;
            return;
          }
        },
        error:function(jqXHR, status, err) {
          console.log("AJAX response: " + jqXHR.responseText);
          console.log("AJAX error   : " + status + " / " + err);
          $("#ajaxProblem").removeClass('hidden');
          setTimeout(refreshProgress, INTERVAL);
        }
      });
    }

    $(document).ready(function() {
      window.setTimeout(refreshProgress, INTERVAL);
    });
  </script>
  <noscript>
    <meta http-equiv="refresh" content="<%=CommonConfiguration.getBatchUploadProgressRefresh() * 2%>"/>
  </noscript>
<%  } else { %>
  <script language="javascript" type="text/javascript">
    $(document).ready(function() {
      $('#ajaxProblem, #progress, #meter, #phase').css('visibility', 'hidden');
    });
  </script>
<%  } %>
  <style type="text/css">
    .progressMeter {
      width: <%=Integer.toString((int)proc.getProgress())%>%;
    }
  </style>
</head>

<body>
<div id="wrapper">
	<div id="page">
		<jsp:include page="../header.jsp" flush="true">
			<jsp:param name="isAdmin" value="<%=request.isUserInRole(\"admin\")%>"/>
		</jsp:include>
		<div id="main">

      <h1><%=bundle.getProperty("gui.progress.title")%></h1>

<%  if (hasErrors) { %>
      <p><%=bundle.getProperty("gui.progress.text.error")%></p>
<%    switch (proc.getPhase()) {
        case MEDIA_DOWNLOAD:
%>
      <p><%=bundle.getProperty("gui.progress.text.errorIntegrityMediaDownload")%></p>
<%          break;
        case PERSISTENCE:
%>
      <p><%=bundle.getProperty("gui.progress.text.errorIntegrityPersistence")%></p>
<%          break;
        case THUMBNAILS:
%>
      <p><%=bundle.getProperty("gui.progress.text.errorIntegrityThumbnails")%></p>
<%          break;
        case PLUGIN:
%>
      <p><%=bundle.getProperty("gui.progress.text.errorIntegrityPlugin")%></p>
<%          break;
        default:
%>
      <p><%=bundle.getProperty("gui.progress.text.errorIntegrityOk")%></p>
<%          break;
      }
%>
<%  } else { %>
<%
      switch(proc.getStatus()) {
        case FINISHED: %>
      <p><%=bundle.getProperty("gui.progress.text.finished")%></p>
<%        break;
        case ERROR: %>
      <p><%=bundle.getProperty("gui.progress.text.error")%></p>
<%        break;
        default: %>
      <p><%=bundle.getProperty("gui.progress.text.running")%></p>
      <p id="progress"><%=MessageFormat.format(bundle.getProperty("gui.progress.text.tracker"), proc.getProgress())%></p>
      <!-- Progress meter (maybe replaced with HTML5 tag, eventually). -->
      <div class="meter nostripes">
        <span id="progressMeter" class="hidden"></span>
      </div>
<%    } %>
      <p id="phase" class="hidden"><%=bundle.getProperty("gui.progress.status.phase.NONE")%></p>
      <p id="ajaxProblem" class="hidden"><%=bundle.getProperty("gui.progress.problem")%></p>
<%  } %>

<%  if (hasErrors) { %>
      <div id="errors">
  			<h2><%=bundle.getProperty("gui.errors.title")%></h2>
        <ul id="errorList">
<%    for (String msg : errors) { %>
          <li><%=ServletUtilities.preventCrossSiteScriptingAttacks(msg)%></li>
<%    } %>
        </ul>
<%    if (proc.getThrown() != null) { %>
          <p><%=bundle.getProperty("gui.errors.thrown")%></p>
          <pre><%proc.getThrown().printStackTrace(new PrintWriter(out));%><pre>
<%    } %>
      </div>
<%  } %>
<%  if (hasWarnings) { %>
      <div id="warnings">
  			<h2><%=bundle.getProperty("gui.warnings.title")%></h2>
        <ul id="warningList">
<%    for (String msg : warnings) { %>
          <li><%=ServletUtilities.preventCrossSiteScriptingAttacks(msg)%></li>
<%    } %>
        </ul>
      </div>
<%  } %>

      <jsp:include page="../footer.jsp" flush="true"/>
		</div>
	</div>
	<!-- end page --></div>
<!--end wrapper -->
</body>
</html>