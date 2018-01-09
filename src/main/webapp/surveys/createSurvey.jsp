<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN"
        "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<%@ page contentType="text/html; charset=utf-8" language="java" import="org.joda.time.LocalDateTime,
org.joda.time.format.DateTimeFormatter,
org.joda.time.format.ISODateTimeFormat,java.net.*,
org.ecocean.grid.*,org.ecocean.movement.*,
java.io.*,java.util.*, java.io.FileInputStream, java.util.Date, java.text.SimpleDateFormat, java.io.File, java.io.FileNotFoundException, org.ecocean.*,org.ecocean.servlet.*,javax.jdo.*, java.lang.StringBuffer, java.util.Vector, java.util.Iterator, java.lang.NumberFormatException"%>

<%
String context="context0";
context=ServletUtilities.getContext(request);
String langCode=ServletUtilities.getLanguageCode(request);
Shepherd myShepherd=new Shepherd(context);

Properties props = new Properties();
Properties surveyProps = new Properties();
 
myShepherd.beginDBTransaction();

props = ShepherdProperties.getProperties("createSurvey.properties", langCode,context);
surveyProps = ShepherdProperties.getProperties("createSurvey.properties", langCode,context);


%>

<jsp:include page="../header.jsp" flush="true" />


<div class="container maincontent">
	<div class="row">
		<div class="col-md-12">
			<h3><%=props.getProperty("createSurvey") %></h3>
			<hr/>
			<div id="errorSpan"></div>
		
		</div>
		<div class="col-md-12">

		
		</div>

	</div>
</div>

<jsp:include page="../footer.jsp" flush="true" />


