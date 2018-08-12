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
<title>Fix Some Fields</title>

</head>


<body>
<<<<<<< HEAD
<p>Removing all workspaces.</p>
=======

>>>>>>> origin/crc
<ul>
<%

myShepherd.beginDBTransaction();
try{
	
    List<String> encs=null;
    String filter="SELECT DISTINCT catalogNumber FROM org.ecocean.Encounter";  
    Query query=myShepherd.getPM().newQuery(filter);
    Collection c = (Collection) (query.execute());
    encs=new ArrayList<String>(c);
    query.closeAll();
    %>
    <li><%=encs.toString() %></li>
	<%

	Iterator allEncs=myShepherd.getAllMarkedIndividuals();
	


	while(allEncs.hasNext()){
		
		MarkedIndividual enc=(MarkedIndividual)allEncs.next();
		enc.refreshDependentProperties(context);
		myShepherd.commitDBTransaction();
		myShepherd.beginDBTransaction();

	}
	myShepherd.rollbackDBTransaction();
	
>>>>>>> origin/crc
}
catch(Exception e){
	myShepherd.rollbackDBTransaction();
}
finally{
	myShepherd.closeDBTransaction();

}

%>

</ul>
<<<<<<< HEAD
<p>Done successfully: <%=numFixes %> workspaces deleted.</p>
=======
<p>Done successfully: <%=numFixes %></p>

>>>>>>> origin/crc
</body>
</html>
