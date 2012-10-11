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

<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">

<%@ page contentType="text/html; charset=utf-8" language="java"
         import="java.text.DecimalFormat,org.ecocean.Util.MeasurementDesc,org.apache.commons.math.stat.descriptive.SummaryStatistics,java.util.Vector,java.util.Properties,org.ecocean.genetics.*,java.util.*,java.net.URI, org.ecocean.*" %>



<html>
<head>



  <%

  DecimalFormat df = new DecimalFormat("#.##");

    //let's load encounterSearch.properties
    String langCode = "en";
    if (session.getAttribute("langCode") != null) {
      langCode = (String) session.getAttribute("langCode");
    }
    Properties encprops = new Properties();
    encprops.load(getClass().getResourceAsStream("/bundles/" + langCode + "/searchResultsAnalysis.properties"));

    Properties haploprops = new Properties();
    haploprops.load(getClass().getResourceAsStream("/bundles/haplotypeColorCodes.properties"));

    
    //get our Shepherd
    Shepherd myShepherd = new Shepherd();


    
 	//prep for measurements summary
 	List<MeasurementDesc> measurementTypes=Util.findMeasurementDescs("en");
 	int numMeasurementTypes=measurementTypes.size();
 	SummaryStatistics[] measurementValues=new SummaryStatistics[numMeasurementTypes];
 	SummaryStatistics[] measurementValuesMales=new SummaryStatistics[numMeasurementTypes];
 	SummaryStatistics[] measurementValuesFemales=new SummaryStatistics[numMeasurementTypes];
 	for(int b=0;b<measurementValues.length;b++){
 		measurementValues[b]=new SummaryStatistics();
 		measurementValuesMales[b]=new SummaryStatistics();
 		measurementValuesFemales[b]=new SummaryStatistics();

 	}

 	
 	//prep for biomeasurements summary
 	List<MeasurementDesc> bioMeasurementTypes=Util.findBiologicalMeasurementDescs("en");
 	int numBioMeasurementTypes=bioMeasurementTypes.size();
 	SummaryStatistics[] bioMeasurementValues=new SummaryStatistics[numBioMeasurementTypes];
 	SummaryStatistics[] bioMeasurementValuesMales=new SummaryStatistics[numBioMeasurementTypes];
 	SummaryStatistics[] bioMeasurementValuesFemales=new SummaryStatistics[numBioMeasurementTypes];
 	for(int b=0;b<bioMeasurementValues.length;b++){
 		bioMeasurementValues[b]=new SummaryStatistics();
 		bioMeasurementValuesMales[b]=new SummaryStatistics();
 		bioMeasurementValuesFemales[b]=new SummaryStatistics();
 	}



    int numResults = 0;

    //set up the vector for matching encounters
    Vector rEncounters = new Vector();

    //kick off the transaction
    myShepherd.beginDBTransaction();

    //start the query and get the results
    String order = "";
    EncounterQueryResult queryResult = EncounterQueryProcessor.processQuery(myShepherd, request, order);
    rEncounters = queryResult.getResult();
    
    //let's prep the HashTable for the haplo pie chart
    ArrayList<String> allHaplos2=myShepherd.getAllHaplotypes(); 
    int numHaplos2 = allHaplos2.size();
    Hashtable<String,Integer> pieHashtable = new Hashtable<String,Integer>();
 	for(int gg=0;gg<numHaplos2;gg++){
 		String thisHaplo=allHaplos2.get(gg);
 		pieHashtable.put(thisHaplo, new Integer(0));
 	}
    
 	//let's prep the HashTable for the sex pie chart
 	Hashtable<String,Integer> sexHashtable = new Hashtable<String,Integer>();
 	sexHashtable.put("male", new Integer(0));
 	sexHashtable.put("female", new Integer(0));
 	sexHashtable.put("unknown", new Integer(0));
 	
 	
 	int resultSize=rEncounters.size();
 	ArrayList<String> markedIndividuals=new ArrayList<String>();
 	 for(int y=0;y<resultSize;y++){
 		 
 		 
 		 Encounter thisEnc=(Encounter)rEncounters.get(y);
 		 if((!thisEnc.equals("Unassigned"))&&(!markedIndividuals.contains(thisEnc.getIndividualID().trim()))){markedIndividuals.add(thisEnc.getIndividualID().trim());}
 		 //haplotype ie chart prep
 		 if(thisEnc.getHaplotype()!=null){
      	   if(pieHashtable.containsKey(thisEnc.getHaplotype().trim())){
      		   Integer thisInt = pieHashtable.get(thisEnc.getHaplotype().trim())+1;
      		   pieHashtable.put(thisEnc.getHaplotype().trim(), thisInt);
      	   }
 	 	}
 		 
 	    //sex pie chart 	 
 		if(thisEnc.getSex().equals("male")){
 		   Integer thisInt = sexHashtable.get("male")+1;
  		   sexHashtable.put("male", thisInt);
 		}
 		else if(thisEnc.getSex().equals("female")){
  		   Integer thisInt = sexHashtable.get("female")+1;
  		   sexHashtable.put("female", thisInt);
 		}
 	    else{
 	    	Integer thisInt = sexHashtable.get("unknown")+1;
   		    sexHashtable.put("unknown", thisInt);
 	    }
 	    
 		//measurement
		for(int b=0;b<numMeasurementTypes;b++){
			if(thisEnc.getMeasurement(measurementTypes.get(b).getType())!=null){
				
					measurementValues[b].addValue(thisEnc.getMeasurement(measurementTypes.get(b).getType()).getValue().doubleValue());

					//males versus females analysis
					if((thisEnc.getSex()!=null)&&(thisEnc.getSex().equals("male"))){
						measurementValuesMales[b].addValue(thisEnc.getMeasurement(measurementTypes.get(b).getType()).getValue().doubleValue());
					}
					else if((thisEnc.getSex()!=null)&&(thisEnc.getSex().equals("female"))){
						measurementValuesFemales[b].addValue(thisEnc.getMeasurement(measurementTypes.get(b).getType()).getValue().doubleValue());
					}

			}
		}
		
 		//biomeasurement tabulation
		for(int b=0;b<numBioMeasurementTypes;b++){
			if(thisEnc.getBiologicalMeasurement(bioMeasurementTypes.get(b).getType())!=null){
				
					bioMeasurementValues[b].addValue(thisEnc.getBiologicalMeasurement(bioMeasurementTypes.get(b).getType()).getValue().doubleValue());

					
					//males versus females analysis
					if((thisEnc.getSex()!=null)&&(thisEnc.getSex().equals("male"))){
						bioMeasurementValuesMales[b].addValue(thisEnc.getBiologicalMeasurement(bioMeasurementTypes.get(b).getType()).getValue().doubleValue());
					}
					else if((thisEnc.getSex()!=null)&&(thisEnc.getSex().equals("female"))){
						bioMeasurementValuesFemales[b].addValue(thisEnc.getBiologicalMeasurement(bioMeasurementTypes.get(b).getType()).getValue().doubleValue());
					}
					

					
			}
		}
 	    
 	    
 		 
 	 }	
 	 
 	 
 	 
 	 
  %>

  <title><%=CommonConfiguration.getHTMLTitle()%>
  </title>
  <meta http-equiv="Content-Type" content="text/html; charset=utf-8"/>
  <meta name="Description" content="<%=CommonConfiguration.getHTMLDescription()%>"/>
  <meta name="Keywords" content="<%=CommonConfiguration.getHTMLKeywords()%>"/>
  <meta name="Author" content="<%=CommonConfiguration.getHTMLAuthor()%>"/>
  <link href="<%=CommonConfiguration.getCSSURLLocation(request)%>" rel="stylesheet" type="text/css"/>
  <link rel="shortcut icon" href="<%=CommonConfiguration.getHTMLShortcutIcon()%>"/>


    <style type="text/css">
      body {
        margin: 0;
        padding: 10px 20px 20px;
        font-family: Arial;
        font-size: 16px;
      }



      #map {
        width: 600px;
        height: 400px;
      }

    </style>
  

<style type="text/css">
  #tabmenu {
    color: #000;
    border-bottom: 2px solid black;
    margin: 12px 0px 0px 0px;
    padding: 0px;
    z-index: 1;
    padding-left: 10px
  }

  #tabmenu li {
    display: inline;
    overflow: hidden;
    list-style-type: none;
  }

  #tabmenu a, a.active {
    color: #DEDECF;
    background: #000;
    font: bold 1em "Trebuchet MS", Arial, sans-serif;
    border: 2px solid black;
    padding: 2px 5px 0px 5px;
    margin: 0;
    text-decoration: none;
    border-bottom: 0px solid #FFFFFF;
  }

  #tabmenu a.active {
    background: #FFFFFF;
    color: #000000;
    border-bottom: 2px solid #FFFFFF;
  }

  #tabmenu a:hover {
    color: #ffffff;
    background: #7484ad;
  }

  #tabmenu a:visited {
    color: #E8E9BE;
  }

  #tabmenu a.active:hover {
    background: #7484ad;
    color: #DEDECF;
    border-bottom: 2px solid #000000;
  }
  
  
</style>
  
      <script>
        function getQueryParameter(name) {
          name = name.replace(/[\[]/, "\\\[").replace(/[\]]/, "\\\]");
          var regexS = "[\\?&]" + name + "=([^&#]*)";
          var regex = new RegExp(regexS);
          var results = regex.exec(window.location.href);
          if (results == null)
            return "";
          else
            return results[1];
        }
  </script>
  



    
<script type="text/javascript" src="https://www.google.com/jsapi"></script>

<script type="text/javascript">
      google.load("visualization", "1", {packages:["corechart"]});
      google.setOnLoadCallback(drawHaploChart);
      function drawHaploChart() {
        var data = new google.visualization.DataTable();
        data.addColumn('string', 'Haplotype');
        data.addColumn('number', 'No. Recorded');
        data.addRows([
          <%
          ArrayList<String> allHaplos=myShepherd.getAllHaplotypes(); 
          int numHaplos = allHaplos.size();
          

          
          for(int hh=0;hh<numHaplos;hh++){
          %>
          ['<%=allHaplos.get(hh)%>',    <%=pieHashtable.get(allHaplos.get(hh))%>]
		  <%
		  if(hh<(numHaplos-1)){
		  %>
		  ,
		  <%
		  }
          }
		  %>
          
        ]);

        var options = {
          width: 450, height: 300,
          title: 'Haplotypes in Matched Encounters',
          colors: [
                   <%
                   String haploColor="CC0000";
                   if((encprops.getProperty("defaultMarkerColor")!=null)&&(!encprops.getProperty("defaultMarkerColor").trim().equals(""))){
                	   haploColor=encprops.getProperty("defaultMarkerColor");
                   }   

                   
                   for(int yy=0;yy<numHaplos;yy++){
                       String haplo=allHaplos.get(yy);
                       if((haploprops.getProperty(haplo)!=null)&&(!haploprops.getProperty(haplo).trim().equals(""))){
                     	  haploColor = haploprops.getProperty(haplo);
                        }
					%>
					'#<%=haploColor%>',
					<%
                   }
                   %>
                   
                   
          ]
        };

        var chart = new google.visualization.PieChart(document.getElementById('chart_div'));
        chart.draw(data, options);
      }
      
      google.setOnLoadCallback(drawSexChart);
      function drawSexChart() {
        var data = new google.visualization.DataTable();
        data.addColumn('string', 'Sex');
        data.addColumn('number', 'No. Recorded');
        data.addRows([

          ['male',    <%=sexHashtable.get("male")%>],
           ['female',    <%=sexHashtable.get("female")%>],
           ['unknown',    <%=sexHashtable.get("unknown")%>]
          
        ]);

        <%
        haploColor="CC0000";
        if((encprops.getProperty("defaultMarkerColor")!=null)&&(!encprops.getProperty("defaultMarkerColor").trim().equals(""))){
     	   haploColor=encprops.getProperty("defaultMarkerColor");
        }
        
        %>
        var options = {
          width: 450, height: 300,
          title: 'Sex Distribution in Matched Encounters',
          colors: ['#0000FF','#FF00FF','<%=haploColor%>']
        };

        var chart = new google.visualization.PieChart(document.getElementById('sexchart_div'));
        chart.draw(data, options);
      }
      
      
</script>

    
  </head>
 <body onunload="GUnload()">
 <div id="wrapper">
 <div id="page">
<jsp:include page="../header.jsp" flush="true">

  <jsp:param name="isAdmin" value="<%=request.isUserInRole(\"admin\")%>" />
</jsp:include>
 <div id="main">
 
 <ul id="tabmenu">
 
   <li><a href="searchResults.jsp?<%=request.getQueryString() %>"><%=encprops.getProperty("table")%>
   </a></li>
   <li><a
     href="thumbnailSearchResults.jsp?<%=request.getQueryString() %>"><%=encprops.getProperty("matchingImages")%>
   </a></li>
   <li><a
     href="mappedSearchResults.jsp?<%=request.getQueryString() %>"><%=encprops.getProperty("mappedResults") %>
   </a></li>
   <li><a
     href="../xcalendar/calendar2.jsp?<%=request.getQueryString() %>"><%=encprops.getProperty("resultsCalendar")%>
   </a></li>
   <li><a class="active"><%=encprops.getProperty("analysis")%>
   </a></li>
      <li><a
     href="exportSearchResults.jsp?<%=request.getQueryString() %>"><%=encprops.getProperty("export")%>
   </a></li>
 
 </ul>
 <table width="810px" border="0" cellspacing="0" cellpadding="0">
   <tr>
     <td>
       <br/>
 
       <h1 class="intro"><%=encprops.getProperty("title")%>
       </h1>
     </td>
   </tr>
</table>
 
 <p>
 Number matching encounters: <%=resultSize %>
 </p>

<p><strong>Measurements</strong></p>
<%
 		//measurement
		
		if(measurementTypes.size()>0){
			for(int b=0;b<numMeasurementTypes;b++){
			%>
				<p>Mean <%= measurementTypes.get(b).getType()%>: 
				<% 
				
				//now report averages
				if(measurementValues[b].getN()>0){
				%>
				&nbsp;<%=df.format(measurementValues[b].getMean()) %>&nbsp;<%=measurementTypes.get(b).getUnits() %> (Std. Dev. <%=df.format(measurementValues[b].getStandardDeviation()) %>) N=<%=measurementValues[b].getN() %><br />
				<ul>
					<li>Mean for males: <%=df.format(measurementValuesMales[b].getMean()) %>&nbsp;<%=measurementTypes.get(b).getUnits() %> (Std. Dev. <%=df.format(measurementValuesMales[b].getStandardDeviation()) %>) N=<%=measurementValuesMales[b].getN() %></li>
					<li>Mean for females: <%=df.format(measurementValuesFemales[b].getMean()) %>&nbsp;<%=measurementTypes.get(b).getUnits() %> (Std. Dev. <%=df.format(measurementValuesFemales[b].getStandardDeviation()) %>) N=<%=measurementValuesFemales[b].getN() %></li>
				</ul>
				<%
				}
				else{
					%>
					&nbsp;No measurement values available.
					<%
				}
				
				%>
				</p>
			<%
			}
		}
		else{
			%>
			<p>No measurement types defined.</p>
			<% 
		}
%>
<p><strong>Biological/Chemical Measurements</strong></p>
<%
 		//measurement
		
		if(bioMeasurementTypes.size()>0){
			for(int b=0;b<numBioMeasurementTypes;b++){
			%>
				<p>Mean <%= bioMeasurementTypes.get(b).getType()%>: 
				<% 
				
				//now report averages
				if(bioMeasurementValues[b].getN()>0){
				%>
				&nbsp;<%=df.format(bioMeasurementValues[b].getMean()) %>&nbsp;<%=bioMeasurementTypes.get(b).getUnits() %> (Std. Dev. <%=df.format(bioMeasurementValues[b].getStandardDeviation()) %>) N=<%=bioMeasurementValues[b].getN() %><br />
				<ul>
					<li>Mean for males: <%=df.format(bioMeasurementValuesMales[b].getMean()) %>&nbsp;<%=bioMeasurementTypes.get(b).getUnits() %> (Std. Dev. <%=df.format(bioMeasurementValuesMales[b].getStandardDeviation()) %>) N=<%=bioMeasurementValuesMales[b].getN() %></li>
					<li>Mean for females: <%=df.format(bioMeasurementValuesFemales[b].getMean()) %>&nbsp;<%=bioMeasurementTypes.get(b).getUnits() %> (Std. Dev. <%=df.format(bioMeasurementValuesFemales[b].getStandardDeviation()) %>) N=<%=bioMeasurementValuesFemales[b].getN() %></li>
					</ul>
				<%
				}
				else{
					%>
					&nbsp;No measurement values available.
					<%
				}
				
				%>
				</p>
			<%
			}
		}
		else{
			%>
			<p>No measurement types defined.</p>
			<% 
		}


     try {
 %>
 


 <div id="chart_div"></div>

<div id="sexchart_div"></div>
 
 <%
 
     } 
     catch (Exception e) {
       e.printStackTrace();
     }
 



 
 
   myShepherd.rollbackDBTransaction();
   myShepherd.closeDBTransaction();
   rEncounters = null;
 
%>
 <table>
  <tr>
    <td align="left">

      <p><strong><%=encprops.getProperty("queryDetails")%>
      </strong></p>

      <p class="caption"><strong><%=encprops.getProperty("prettyPrintResults") %>
      </strong><br/>
        <%=queryResult.getQueryPrettyPrint().replaceAll("locationField", encprops.getProperty("location")).replaceAll("locationCodeField", encprops.getProperty("locationID")).replaceAll("verbatimEventDateField", encprops.getProperty("verbatimEventDate")).replaceAll("alternateIDField", encprops.getProperty("alternateID")).replaceAll("behaviorField", encprops.getProperty("behavior")).replaceAll("Sex", encprops.getProperty("sex")).replaceAll("nameField", encprops.getProperty("nameField")).replaceAll("selectLength", encprops.getProperty("selectLength")).replaceAll("numResights", encprops.getProperty("numResights")).replaceAll("vesselField", encprops.getProperty("vesselField"))%>
      </p>

      <p class="caption"><strong><%=encprops.getProperty("jdoql")%>
      </strong><br/>
        <%=queryResult.getJDOQLRepresentation()%>
      </p>

    </td>
  </tr>
</table>
 
 <jsp:include page="../footer.jsp" flush="true"/>
</div>
</div>
<!-- end page --></div>
<!--end wrapper -->

</body>
</html>
