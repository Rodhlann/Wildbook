<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN"
        "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<%@ page contentType="text/html; charset=utf-8" language="java" import="org.joda.time.LocalDateTime,
org.joda.time.format.DateTimeFormatter,
org.joda.time.format.ISODateTimeFormat,java.net.*,
org.ecocean.grid.*, org.ecocean.media.*,
java.io.*,java.util.*, java.io.FileInputStream, java.io.File, java.io.FileNotFoundException, org.ecocean.*,org.ecocean.servlet.*,javax.jdo.*, java.lang.StringBuffer, java.util.Vector, java.util.Iterator, java.lang.NumberFormatException"%>

<%

boolean committing = false;
%>

<html>
<head>
<title>Fix Some Fields</title>

</head>


<body>
<h1>Fixing some fields</h1>
<h2>Committing? <%=committing%>!</h2>
<ul>
<%

Integer[] contextNums = new Integer[] {0,1};

for (Integer contextNum : contextNums) {

String context="context"+contextNum.toString();




Shepherd myShepherd=new Shepherd(context);


%><p><em>in context <code><%=context%>:</code></em>
<%

myShepherd.beginDBTransaction();

int numFixes=0;

try {

	String rootDir = getServletContext().getRealPath("/");
	String baseDir = ServletUtilities.dataDir(context, rootDir).replaceAll("dev_data_dir", "caribwhale_data_dir");

  Iterator allOccurrences=myShepherd.getAllOccurrencesNoQuery();


  %>
  <ul>
  <%



  while(allOccurrences.hasNext()/* && numFixes < 20*/){

    Occurrence occ=(Occurrence)allOccurrences.next();
    if (occ.getIndividualCount()==null) {
      occ.setIndividualCount();
      occ.setLatLonFromEncs();
      numFixes++;
    }

    if (committing) {
      myShepherd.commitDBTransaction();
      myShepherd.beginDBTransaction();
    }

    %><li>
      <ul>occ <%=occ.getOccurrenceID()%>
        <li>individualCount <%=occ.getIndividualCount()%></li>
        <li>num encounters <%=occ.getEncounters().size()%></li>
        <li>latlong <%=occ.getLatLonString()%></li>
      </ul>
    </li><%
  }
}
catch(Exception e){
	myShepherd.rollbackDBTransaction();
}
finally{
	myShepherd.closeDBTransaction();

}
%>
</ul>
Done successfully: <%=numFixes %></p>

<%
// end of context loop
}
%>



</body>
</html>
