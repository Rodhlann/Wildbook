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

// pg_dump -Ft sharks > sharks.out

//pg_restore -d sharks2 /home/webadmin/sharks.out


%>

<html>
<head>
<title>Fix Some Fields</title>

</head>


<body>
<p>Photo paths to fix.</p>
<ul>
<%

myShepherd.beginDBTransaction();

//build queries

Extent encClass=myShepherd.getPM().getExtent(Encounter.class, true);
Query encQuery=myShepherd.getPM().newQuery(encClass);
Iterator allEncs;





Extent sharkClass=myShepherd.getPM().getExtent(MarkedIndividual.class, true);
Query sharkQuery=myShepherd.getPM().newQuery(sharkClass);
Iterator allSharks;



try{


	String rootDir = getServletContext().getRealPath("/");
	String baseDir = ServletUtilities.dataDir(context, rootDir).replaceAll("dev_data_dir", "caribwhale_data_dir");
	
allEncs=myShepherd.getAllEncountersForSpecies("Megaptera", "novaeangliae").iterator();
allSharks=myShepherd.getAllMarkedIndividuals(sharkQuery);

while(allEncs.hasNext()){
	Encounter enc=(Encounter)allEncs.next();
	File encDir = new File(enc.dir(baseDir));
	
	String encDirPath=encDir.getAbsolutePath();
	ArrayList<SinglePhotoVideo> allP=myShepherd.getAllSinglePhotoVideosForEncounter(enc.getCatalogNumber());
	for(int i=0;i<allP.size();i++){
		SinglePhotoVideo spv=allP.get(i);
		String filePath=encDirPath+"/"+spv.getFilename();
		if(!filePath.equals(spv.getFullFileSystemPath())){
			spv.setFullFileSystemPath(filePath);
			myShepherd.commitDBTransaction();
			myShepherd.beginDBTransaction();
		}
		
		
	}
}

%>




<%
} 
catch(Exception ex) {

	System.out.println("!!!An error occurred on page fixSomeFields.jsp. The error was:");
	ex.printStackTrace();
	//System.out.println("fixSomeFields.jsp page is attempting to rollback a transaction because of an exception...");
	encQuery.closeAll();
	encQuery=null;
	//sharkQuery.closeAll();
	//sharkQuery=null;


}
finally{
	myShepherd.rollbackDBTransaction();
	myShepherd.closeDBTransaction();
	myShepherd=null;
}
%>

</ul>
<p>Done successfully!</p>
</body>
</html>
