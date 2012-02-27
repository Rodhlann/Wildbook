<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN"
        "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<%@ page contentType="text/html; charset=utf-8" language="java" import="java.net.*,java.io.*,java.util.*, java.io.FileInputStream, java.io.File, java.io.FileNotFoundException, org.ecocean.*,org.ecocean.servlet.*,javax.jdo.*, java.lang.StringBuffer, java.util.Vector, java.util.Iterator, java.lang.NumberFormatException"%>

<%


	Shepherd myShepherd=new Shepherd();

// pg_dump -Ft sharks > sharks.out

//pg_restore -d sharks2 /home/webadmin/sharks.out


%>

<html>
<head>
<title><%=CommonConfiguration.getHTMLTitle() %></title>
<meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
<meta name="Description"
	content="<%=CommonConfiguration.getHTMLDescription() %>" />
<meta name="Keywords"
	content="<%=CommonConfiguration.getHTMLKeywords() %>" />
<meta name="Author" content="<%=CommonConfiguration.getHTMLAuthor() %>" />

<link rel="shortcut icon"
	href="<%=CommonConfiguration.getHTMLShortcutIcon() %>" />
</head>


<body>
<%

myShepherd.beginDBTransaction();

//build queries

Extent encClass=myShepherd.getPM().getExtent(Encounter.class, true);
Query encQuery=myShepherd.getPM().newQuery(encClass);
Iterator allEncs;



Extent sharkClass=myShepherd.getPM().getExtent(MarkedIndividual.class, true);
Query sharkQuery=myShepherd.getPM().newQuery(sharkClass);
Iterator allSharks;

//empty comment



try{


allEncs=myShepherd.getAllEncounters(encQuery);
allSharks=myShepherd.getAllMarkedIndividuals(sharkQuery);

int numLogEncounters=0;

while(allEncs.hasNext()){
	
	//change state
	Encounter sharky=(Encounter)allEncs.next();
	//if(sharky.getApproved()){sharky.setState("approved");}
	//else if(sharky.getUnidentifiable()){sharky.setState("unidentifiable");}
	//else{sharky.setState("unapproved");}
	
	//change to SinglePhotoVideo
	//int numPhotos=sharky.getImages().size();
	//List<SinglePhotoVideo> images=sharky.getImages();
	

	
	
	/*
	if(sharky.getSizeAsDouble()!=null){
		Measurement measurement = new Measurement(sharky.getEncounterNumber(), "length", sharky.getSizeAsDouble(), "meters", sharky.getSizeGuess());
        sharky.addMeasurement(measurement);
	}
	*/
	
	/*
	
	for(int i=0;i<numPhotos;i++){
		

		try{
			File file=new File("/opt/tomcat6/webapps/ROOT/encounters/"+sharky.getCatalogNumber()+"/"+sharky.getImages().get(i).getDataCollectionEventID()+".jpg");
			if(!file.exists()){
				URL url = new URL("http://www.whaleshark.org/encounters/encounter.jsp?number="+sharky.getCatalogNumber());
				BufferedReader in=new BufferedReader(new InputStreamReader(url.openStream()));
				in.close();
				in=null;
				url=null;
			}
		}
		catch(Exception e){}
	
		
		//SinglePhotoVideo single=new SinglePhotoVideo(sharky.getCatalogNumber(), ((String)sharky.additionalImageNames.get(i)), ("/opt/tomcat6/webapps/ROOT/encounters/"+sharky.getCatalogNumber()+((String)sharky.additionalImageNames.get(i))));
		//SinglePhotoVideo single=images.get(i);
		//single.
		//set keywords
		//String checkString=sharky.getEncounterNumber() + "/" + (String)sharky.additionalImageNames.get(i);
		//Iterator keywords=myShepherd.getAllKeywords();
	//	while(keywords.hasNext()){
		//	Keyword word=(Keyword)keywords.next();
			//if(word.isMemberOf(checkString)){single.addKeyword(word);}
		//}
		//sharky.addSinglePhotoVideo(single);
	
	}
	*/

}


while(allSharks.hasNext()){

	MarkedIndividual sharky=(MarkedIndividual)allSharks.next();
	
	//populate max years between resightings
	/*
	if(sharky.totalLogEncounters()>0){
		//int numLogEncounters=);
		for(int i=0;i<sharky.totalLogEncounters();i++){
			Encounter enc=sharky.getLogEncounter(i);
			sharky.removeLogEncounter(enc);
			sharky.addEncounter(enc);
			i--;
			//check if log encounters still exist
			numLogEncounters++;
			
		}
	}*/
	sharky.resetMaxNumYearsBetweenSightings();
	
}


myShepherd.commitDBTransaction();
	myShepherd.closeDBTransaction();
	myShepherd=null;
%>


<p>Done successfully!</p>
<p>numLogEncounters: <%=numLogEncounters %></p>

<%
} 
catch(Exception ex) {

	System.out.println("!!!An error occurred on page allEncounters.jsp. The error was:");
	ex.printStackTrace();
	//System.out.println("fixSomeFields.jsp page is attempting to rollback a transaction because of an exception...");
	//encQuery.closeAll();
	//encQuery=null;
	sharkQuery.closeAll();
	sharkQuery=null;
	myShepherd.rollbackDBTransaction();
	myShepherd.closeDBTransaction();
	myShepherd=null;

}
%>


</body>
</html>