<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN"
        "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<%@ page contentType="text/html; charset=utf-8" language="java" import="org.joda.time.LocalDateTime,
org.joda.time.format.DateTimeFormatter,
org.joda.time.format.ISODateTimeFormat,java.net.*,
org.ecocean.grid.*,
java.io.*,java.util.*, java.io.FileInputStream, java.io.File, java.io.FileNotFoundException, org.ecocean.*,org.ecocean.servlet.*,javax.jdo.*, java.lang.StringBuffer, java.util.Vector, java.util.Iterator, java.lang.NumberFormatException"%>

<%

String context="context0";
context=ServletUtilities.getContext(request);

Shepherd myShepherd=new Shepherd(context);



%>

<html>
<head>
<title>Location ID Tester</title>

</head>


<body>
<h2>Default tests</h2>
<p><pre><%=LocationID.getLocationIDStructure().toString() %></pre></p>

<p>The name for locationID 1 is: <pre><%=LocationID.getNameForLocationID("1",null) %></pre></p>

<p>The name for locationID 6 is: <pre><%=LocationID.getNameForLocationID("6",null) %></pre></p>

<p>The parent and child IDs for locationID 1 are: <pre><%=LocationID.getIDForParentAndChildren("1",null).toString() %></pre></p>

<p>
<form>
<%=LocationID.getHTMLSelector(true,null,null)%>
</form>
</p>

<p>Single select and selected: 
<form>
<%=LocationID.getHTMLSelector(false, "1",null)%>
</form>
</p>

<h2>Override tests</h2>
<p><pre><%=LocationID.getLocationIDStructure("test").toString() %></pre></p>

<p>The name for locationID 1 is: <pre><%=LocationID.getNameForLocationID("1","test") %></pre></p>

<p>The name for locationID 6 is: <pre><%=LocationID.getNameForLocationID("6","test") %></pre></p>
</body>
</html>
