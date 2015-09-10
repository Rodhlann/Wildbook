<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN"
        "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<%@ page contentType="text/html; charset=utf-8" language="java" import="org.joda.time.LocalDateTime,
org.joda.time.format.DateTimeFormatter,
org.joda.time.format.ISODateTimeFormat,
java.net.*,
org.ecocean.grid.*,
org.ecocean.neural.*,
	com.fastdtw.timeseries.TimeSeriesBase.*,
	com.fastdtw.dtw.*,
	com.fastdtw.util.Distances,
	com.fastdtw.timeseries.TimeSeriesBase.Builder,
	com.fastdtw.timeseries.*,
	org.apache.commons.math.stat.descriptive.SummaryStatistics,
java.io.*,java.util.*, java.io.FileInputStream, java.io.File, java.io.FileNotFoundException, org.ecocean.*,org.ecocean.servlet.*,javax.jdo.*, java.lang.StringBuffer, java.util.Vector, java.util.Iterator, java.lang.NumberFormatException"%>
<%!

public void populateNewHashtable(Hashtable<Integer,Integer> table, int upperlimit){
	
	
	for(int i=0;i<=upperlimit;i++){
		table.put(i, 0);
	}
	
}

%>
<%

String context="context0";
context=ServletUtilities.getContext(request);

	Shepherd myShepherd=new Shepherd(context);

ArrayList<String> suspectValues=new ArrayList<String>();

%>

<html>
<head>
<title>Matching Performance</title>

</head>


<body>
<%

//training metrics
double intersectionProportion=0.2;
if(request.getParameter("intersectionProportion")!=null){intersectionProportion=(new Double(request.getParameter("intersectionProportion"))).doubleValue();}

//double stdDev=0.05;

double intersectionStdDev=0.05;
if(request.getParameter("intersectionStdDev")!=null){intersectionStdDev=(new Double(request.getParameter("intersectionStdDev"))).doubleValue();}
double dtwStdDev=0.41;
if(request.getParameter("dtwStdDev")!=null){dtwStdDev=(new Double(request.getParameter("dtwStdDev"))).doubleValue();}
double i3sStdDev=0.01;
if(request.getParameter("i3sStdDev")!=null){i3sStdDev=(new Double(request.getParameter("i3sStdDev"))).doubleValue();}
double proportionStdDev=0.01;
if(request.getParameter("proportionStdDev")!=null){proportionStdDev=(new Double(request.getParameter("proportionStdDev"))).doubleValue();}
double intersectHandicap=0;
if(request.getParameter("intersectHandicap")!=null){intersectHandicap=(new Double(request.getParameter("intersectHandicap"))).doubleValue();}
double dtwHandicap=0;
if(request.getParameter("dtwHandicap")!=null){dtwHandicap=(new Double(request.getParameter("dtwHandicap"))).doubleValue();}
double i3sHandicap=0;
if(request.getParameter("i3sHandicap")!=null){i3sHandicap=(new Double(request.getParameter("i3sHandicap"))).doubleValue();}
double proportionHandicap=0;
if(request.getParameter("proportionHandicap")!=null){proportionHandicap=(new Double(request.getParameter("proportionHandicap"))).doubleValue();}


int chartWidth=800;

myShepherd.beginDBTransaction();


ArrayList<String> matchLinks=new ArrayList<String>();
ArrayList<String> falseLinks=new ArrayList<String>();
ArrayList<String> mergedLinks=new ArrayList<String>();




try{

Vector encounters=myShepherd.getAllEncountersNoFilterAsVector();
int numEncs=encounters.size();
for(int i=0;i<(numEncs-1);i++){
  for(int j=(i+1);j<numEncs;j++){
    
    Encounter enc1=(Encounter)encounters.get(i);
    Encounter enc2=(Encounter)encounters.get(j);
    
    if(((enc1.getSpots()!=null)&&(enc1.getSpots().size()>0)&&(enc1.getRightSpots()!=null))&&((enc1.getRightSpots().size()>0))&&((enc2.getSpots()!=null)&&(enc2.getSpots().size()>0)&&(enc2.getRightSpots()!=null)&&((enc2.getRightSpots().size()>0)))){
        try{
          //System.out.println("Learning: "+enc1.getCatalogNumber()+" and "+enc2.getCatalogNumber());
          
          //if both have spots, then we need to compare them
       
          //first, are they the same animal?
          //default is 1==no
          double output=1;
          if((enc1.getIndividualID()!=null)&&(!enc1.getIndividualID().toLowerCase().equals("unassigned"))){
            if((enc2.getIndividualID()!=null)&&(!enc2.getIndividualID().toLowerCase().equals("unassigned"))){
              //train a match
              if(enc1.getIndividualID().equals(enc2.getIndividualID())){output=0;}
            }
            
          }
          
          
          //http://localhost:8080/wildbook-5.4.0-DEVELOPMENT/encounters/intersectVisualization.jsp?enc1=8280807b-5dff-4b4c-a2a8-bfe2ec9ec054&enc2=ea5d275f-814e-4775-8fa9-fcfa3efb5d10
          
        if(output==1){
        	falseLinks.add(enc1.getCatalogNumber()+":"+enc2.getCatalogNumber());
              
        }
        else{
        	matchLinks.add(enc1.getCatalogNumber()+":"+enc2.getCatalogNumber());
        }
          
        }
        catch(Exception e){
        	e.printStackTrace();
        }
    }

  }
}


//create our hashmaps of incorrect match scores
//Hashtable<Double,Integer> intersectionHashtable = new Hashtable<Double,Integer>();
//populateNewHashtable(intersectionHashtable,3);
//Hashtable<Integer,Integer> dtwHashtable = new Hashtable<Integer,Integer>();
//populateNewHashtable(dtwHashtable,3);
//Hashtable<Integer,Integer> i3sHashtable = new Hashtable<Integer,Integer>();
//populateNewHashtable(i3sHashtable,3);
//Hashtable<Integer,Integer> proportionHashtable = new Hashtable<Integer,Integer>();
//populateNewHashtable(proportionHashtable,3);
Hashtable<Integer,Integer> overallHashtable = new Hashtable<Integer,Integer>();
populateNewHashtable(overallHashtable,12);	
ArrayList<Double> intersectionValues=new ArrayList<Double>();
ArrayList<Double> dtwValues=new ArrayList<Double>();
ArrayList<Double> i3sValues=new ArrayList<Double>();
ArrayList<Double> proportionValues=new ArrayList<Double>();

//create hastables of coreect
//Hashtable<Double,Integer> intersectionCorrectHashtable = new Hashtable<Double,Integer>();
//populateNewHashtable(intersectionCorrectHashtable,3);	
//Hashtable<Integer,Integer> dtwCorrectHashtable = new Hashtable<Integer,Integer>();
//populateNewHashtable(dtwCorrectHashtable,3);	
//Hashtable<Integer,Integer> i3sCorrectHashtable = new Hashtable<Integer,Integer>();
//populateNewHashtable(i3sCorrectHashtable,3);	
//Hashtable<Integer,Integer> proportionCorrectHashtable = new Hashtable<Integer,Integer>();
//populateNewHashtable(proportionCorrectHashtable,3);	
Hashtable<Integer,Integer> overallCorrectHashtable = new Hashtable<Integer,Integer>();
populateNewHashtable(overallCorrectHashtable,12);	
ArrayList<Double> intersectionCorrectValues=new ArrayList<Double>();
ArrayList<Double> dtwCorrectValues=new ArrayList<Double>();
ArrayList<Double> i3sCorrectValues=new ArrayList<Double>();
ArrayList<Double> proportionCorrectValues=new ArrayList<Double>();



SummaryStatistics intersectionStats=TrainNetwork.getIntersectionStats(request);
SummaryStatistics dtwStats=TrainNetwork.getDTWStats(request);
SummaryStatistics proportionStats=TrainNetwork.getProportionStats(request);
SummaryStatistics i3sStats=TrainNetwork.getI3SStats(request);

double correctScoreTotal=0;
int numCorrectScores=0;

double incorrectScoreTotal=0;
int numIncorrectScores=0;


//render data for matches and nonmatches
mergedLinks.addAll(matchLinks);
mergedLinks.addAll(falseLinks);

for(int i=0;i<mergedLinks.size();i++){
	int colonNum=mergedLinks.get(i).indexOf(":");
	String enc1Number=mergedLinks.get(i).substring(0, (colonNum));
	String enc2Number=mergedLinks.get(i).substring(colonNum+1, (mergedLinks.get(i).length()));
	Encounter enc1=myShepherd.getEncounter(enc1Number);
	Encounter enc2=myShepherd.getEncounter(enc2Number);
	
	if(((enc1.getSpots()!=null)&&(enc1.getSpots().size()>0)&&(enc1.getRightSpots()!=null))&&((enc1.getRightSpots().size()>0))&&((enc2.getSpots()!=null)&&(enc2.getSpots().size()>0)&&(enc2.getRightSpots()!=null)&&((enc2.getRightSpots().size()>0)))){
        try{
          
          //if both have spots, then we need to compare them
       
          //first, are they the same animal?
          //default is 1==no
          double output=1;
          if((enc1.getIndividualID()!=null)&&(!enc1.getIndividualID().toLowerCase().equals("unassigned"))){
            if((enc2.getIndividualID()!=null)&&(!enc2.getIndividualID().toLowerCase().equals("unassigned"))){
              //train a match
              if(enc1.getIndividualID().equals(enc2.getIndividualID())){output=0;}
            }
            
          }
          
          
          EncounterLite el1=new EncounterLite(enc1);
          EncounterLite el2=new EncounterLite(enc2);
          
          //HolmbergIntersection
          Double numIntersections=EncounterLite.getHolmbergIntersectionScore(el1, el2,intersectionProportion);
          if((numIntersections>0.7)&&(output==1)){suspectValues.add(mergedLinks.get(i));}
          
          //FastDTW
          TimeWarpInfo twi=EncounterLite.fastDTW(el1, el2, 30);
          
          java.lang.Double distance = new java.lang.Double(-1);
          if(twi!=null){
            WarpPath wp=twi.getPath();
              String myPath=wp.toString();
            distance=new java.lang.Double(twi.getDistance());
          }   
          
          //I3S
          I3SMatchObject newDScore=EncounterLite.improvedI3SScan(el1, el2);
          double i3sScore=-1;
          if(newDScore!=null){i3sScore=newDScore.getI3SMatchValue();}
          
          //Proportion metric
          Double proportion=EncounterLite.getFlukeProportion(el1,el2);
          
          double thisScore=TrainNetwork.getOverallFlukeMatchScore(request, numIntersections, distance.doubleValue(), i3sScore, new Double(proportion),intersectionStats,dtwStats,i3sStats, proportionStats, intersectionStdDev,dtwStdDev,i3sStdDev,proportionStdDev,intersectHandicap, dtwHandicap,i3sHandicap,proportionHandicap);
            //getOverallFlukeMatchScore(HttpServletRequest request, double intersectionsValue, double dtwValue, double i3sValue, double proportionsValue, double numStandardDevs, SummaryStatistics intersectionStats, SummaryStatistics dtwStats,SummaryStatistics i3sStats, SummaryStatistics proportionStats)
            if(output==0){
            	
            	
            	
            	//overall
            	int score=(new Double(thisScore)).intValue(); 
            	Integer numValue=overallCorrectHashtable.get(score).intValue()+1;
            	overallCorrectHashtable.put(score, numValue);
            	correctScoreTotal+=score;
            	numCorrectScores++;
            	
            	//intersection
            	intersectionCorrectValues.add(numIntersections);
            	
            	//FastDTW
            	dtwCorrectValues.add(distance);
            	
            	//I3S
            	i3sCorrectValues.add(i3sScore);
            	
            	//Proportion
            	proportionCorrectValues.add(proportion);
            	
            }
            else{
            	
            	//overall
            	int score=(new Double(thisScore)).intValue(); 
            	Integer numValue=overallHashtable.get(score).intValue()+1;
            	overallHashtable.put(score, numValue);
            	incorrectScoreTotal+=score;
            	numIncorrectScores++;
            	
            	//intersection
            	intersectionValues.add(numIntersections);
            	
            	//FastDTW
            	dtwValues.add(distance);
            	
            	//I3S
            	i3sValues.add(i3sScore);
            	
            	//Proportion
            	proportionValues.add(proportion);
            }
            
          
          
        
      }
      catch(Exception e){
        e.printStackTrace();
      }

        
        
      }
	
}	



myShepherd.rollbackDBTransaction();
	myShepherd.closeDBTransaction();
	myShepherd=null;
%>

<script type="text/javascript" src="https://www.google.com/jsapi"></script>
    <script type="text/javascript">
    
    var chartWidth=<%=chartWidth %>;
    var chartHeight=500;
    

    google.load('visualization', '1.1', {packages: ['line', 'corechart']});
    google.setOnLoadCallback(drawChart);

      // Callback that creates and populates a data table,
      // instantiates the pie chart, passes in the data and
      // draws it.
      function drawChart() {

        // Create the data table.
        var overallCorrectData = new google.visualization.DataTable();
        overallCorrectData.addColumn('number', 'score');
        overallCorrectData.addColumn('number', 'matching');
        
        overallCorrectData.addRows([
      	<%
      	  for(int i=1;i<overallCorrectHashtable.size();i++){
      		  %>
      		  [<%=i %>,<%=(overallCorrectHashtable.get(i).doubleValue()/matchLinks.size()) %>],
      		  <%
      	  }           
      	%>              
		]);
      	
      	
      	
     	 // Create the data table.
       var overallIncorrectData = new google.visualization.DataTable();
       overallIncorrectData.addColumn('number', 'score');
       overallIncorrectData.addColumn('number', 'nonmatching');
     	
       
     	overallIncorrectData.addRows([
		<%
		  for(int i=1;i<overallHashtable.size();i++){
			  %>
			  [<%=i %>,<%=(overallHashtable.get(i).doubleValue()/falseLinks.size()) %>],
			  <%
		  }           
		%>           
     	               
     	               
		]);
      	
      	
      	
      	var joinedData = google.visualization.data.join(overallIncorrectData, overallCorrectData, 'full', [[0, 0]], [1], [1]);
      	
      	

	        
	        var options = {'title':'Overall Scoring Performance: Matches vs Non-matches',
                    'width':chartWidth,
                    'height':chartHeight,
                    'pointSize': 5,
                    'color': 'yellow',
                    series: {
                        0: { color: 'red' },
                     	1: {color: 'green'},

                       
                      },
                      vAxis: {title: "% of type (match or non-match) total"},
                      hAxis: {title: "Overall Score"},
                    };

	        // Instantiate and draw our chart, passing in some options.
	        var chart = new google.visualization.LineChart(document.getElementById('overallchart_div'));
	        chart.draw(joinedData, options);
	        
	      }
      	              
      	              
</script>


<script type="text/javascript" src="https://www.google.com/jsapi"></script>
    <script type="text/javascript">
		google.setOnLoadCallback(drawInterChart);

      // Callback that creates and populates a data table,
      // instantiates the pie chart, passes in the data and
      // draws it.
      function drawInterChart() {

        // Create the data table.
        var interCorrectData = new google.visualization.DataTable();
        interCorrectData.addColumn('number', 'score');
        interCorrectData.addColumn('number', 'matching');
        
        interCorrectData.addRows([
                                  
         <%
         Collections.sort(intersectionCorrectValues);
        
      	  for(int y=0;y<intersectionCorrectValues.size();y++){
      		double position=(double)y/intersectionCorrectValues.size();
    		  
      		  %>
      		  [<%=position %>,<%=intersectionCorrectValues.get(y) %>],
      		  <%
      	  }           
      	%>              
		]);
      	
      	
      	
     	 // Create the data table.
       var interIncorrectData = new google.visualization.DataTable();
       interIncorrectData.addColumn('number', 'score');
       interIncorrectData.addColumn('number', 'nonmatching');
     	
       
       interIncorrectData.addRows([
		<%
         Collections.sort(intersectionValues);
        
      	  for(int y=0;y<intersectionValues.size();y++){
      		  double position=(double)y/intersectionValues.size();
      		  %>
      		  [<%=position %>,<%=intersectionValues.get(y) %>],
      		  <%
      	  }           
      	%>           
     	               
     	               
		]);
      	
      	
      	
      	var joinedData = google.visualization.data.join(interIncorrectData, interCorrectData, 'full', [[0, 0]], [1], [1]);
      	
      	

	        
	        var options = {'title':'Overall Scoring Distribution: Holmberg Intersection',
                    'width':chartWidth,
                    'height':chartHeight,
                    'pointSize': 5,
                    'color': 'yellow',
                    series: {
                        0: { color: 'red' },
                     	1: {color: 'green'},

                       
                      },
                      vAxis: {title: "Score (higher is better)"},
                      hAxis: {title: "fraction matches"},
                    };

	        // Instantiate and draw our chart, passing in some options.
	        var chart = new google.visualization.LineChart(document.getElementById('intersectchart_div'));
	        chart.draw(joinedData, options);
	        
	      }
      	              
      	              
</script>

<script type="text/javascript" src="https://www.google.com/jsapi"></script>
    <script type="text/javascript">
		google.setOnLoadCallback(drawDTWChart);

      // Callback that creates and populates a data table,
      // instantiates the pie chart, passes in the data and
      // draws it.
      function drawDTWChart() {

        // Create the data table.
        var dtwCorrectData = new google.visualization.DataTable();
        dtwCorrectData.addColumn('number', 'score');
        dtwCorrectData.addColumn('number', 'matching');
        
        dtwCorrectData.addRows([
                                  
         <%
         Collections.sort(dtwCorrectValues);
        
      	  for(int y=0;y<dtwCorrectValues.size();y++){
      		double position=(double)y/dtwCorrectValues.size();
    		  
      		  %>
      		  [<%=position %>,<%=dtwCorrectValues.get(y) %>],
      		  <%
      	  }           
      	%>              
		]);
      	
      	
      	
     	 // Create the data table.
       var dtwIncorrectData = new google.visualization.DataTable();
       dtwIncorrectData.addColumn('number', 'score');
       dtwIncorrectData.addColumn('number', 'nonmatching');
     	
       
       dtwIncorrectData.addRows([
		<%
         Collections.sort(dtwValues);
        
      	  for(int y=0;y<dtwValues.size();y++){
      		  double position=(double)y/dtwValues.size();
      		  %>
      		  [<%=position %>,<%=dtwValues.get(y) %>],
      		  <%
      	  }           
      	%>           
     	               
     	               
		]);
      	
      	
      	
      	var joinedData = google.visualization.data.join(dtwIncorrectData, dtwCorrectData, 'full', [[0, 0]], [1], [1]);
      	
      	

	        
	        var options = {'title':'Overall Scoring Distribution: FastDTW',
                    'width':chartWidth,
                    'height':chartHeight,
                    'pointSize': 5,
                    'color': 'yellow',
                    series: {
                        0: { color: 'red' },
                     	1: {color: 'green'},

                       
                      },
                      vAxis: {title: "Score (lower is better)"},
                      hAxis: {title: "fraction matches"},
                    };

	        // Instantiate and draw our chart, passing in some options.
	        var chart = new google.visualization.LineChart(document.getElementById('dtwchart_div'));
	        chart.draw(joinedData, options);
	        
	      }
      	              
      	              
</script>

<script type="text/javascript" src="https://www.google.com/jsapi"></script>
    <script type="text/javascript">
		google.setOnLoadCallback(drawI3SChart);

      // Callback that creates and populates a data table,
      // instantiates the pie chart, passes in the data and
      // draws it.
      function drawI3SChart() {

        // Create the data table.
        var i3sCorrectData = new google.visualization.DataTable();
        i3sCorrectData.addColumn('number', 'score');
        i3sCorrectData.addColumn('number', 'matching');
        
        i3sCorrectData.addRows([
                                  
         <%
         Collections.sort(i3sCorrectValues);
        
      	  for(int y=0;y<i3sCorrectValues.size();y++){
      		double position=(double)y/i3sCorrectValues.size();
    		  
      		  %>
      		  [<%=position %>,<%=i3sCorrectValues.get(y) %>],
      		  <%
      	  }           
      	%>              
		]);
      	
      	
      	
     	 // Create the data table.
       var i3sIncorrectData = new google.visualization.DataTable();
       i3sIncorrectData.addColumn('number', 'score');
       i3sIncorrectData.addColumn('number', 'nonmatching');
     	
       
       i3sIncorrectData.addRows([
		<%
         Collections.sort(i3sValues);
        
      	  for(int y=0;y<i3sValues.size();y++){
      		  double position=(double)y/i3sValues.size();
      		  %>
      		  [<%=position %>,<%=i3sValues.get(y) %>],
      		  <%
      	  }           
      	%>           
     	               
     	               
		]);
      	
      	
      	
      	var joinedData = google.visualization.data.join(i3sIncorrectData, i3sCorrectData, 'full', [[0, 0]], [1], [1]);
      	
      	

	        
	        var options = {'title':'Overall Scoring Distribution: Modified I3S with Improved Affine Transform',
                    'width':chartWidth,
                    'height':chartHeight,
                    'pointSize': 5,
                    'color': 'yellow',
                    series: {
                        0: { color: 'red' },
                     	1: {color: 'green'},

                       
                      },
                      vAxis: {title: "Score (lower is better)"},
                      hAxis: {title: "fraction matches"},
                    };

	        // Instantiate and draw our chart, passing in some options.
	        var chart = new google.visualization.LineChart(document.getElementById('i3schart_div'));
	        chart.draw(joinedData, options);
	        
	      }
      	              
      	              
</script>

<script type="text/javascript" src="https://www.google.com/jsapi"></script>
    <script type="text/javascript">
		google.setOnLoadCallback(drawProportionsChart);

      // Callback that creates and populates a data table,
      // instantiates the pie chart, passes in the data and
      // draws it.
      function drawProportionsChart() {

        // Create the data table.
        var proportionCorrectData = new google.visualization.DataTable();
        proportionCorrectData.addColumn('number', 'score');
        proportionCorrectData.addColumn('number', 'matching');
        
        proportionCorrectData.addRows([
                                  
         <%
         Collections.sort(proportionCorrectValues);
        
      	  for(int y=0;y<proportionCorrectValues.size();y++){
      		double position=(double)y/proportionCorrectValues.size();
    		  
      		  %>
      		  [<%=position %>,<%=proportionCorrectValues.get(y) %>],
      		  <%
      	  }           
      	%>              
		]);
      	
      	
      	
     	 // Create the data table.
       var proportionIncorrectData = new google.visualization.DataTable();
       proportionIncorrectData.addColumn('number', 'score');
       proportionIncorrectData.addColumn('number', 'nonmatching');
     	
       
       proportionIncorrectData.addRows([
		<%
         Collections.sort(proportionValues);
        
      	  for(int y=0;y<proportionValues.size();y++){
      		  double position=(double)y/proportionValues.size();
      		  %>
      		  [<%=position %>,<%=proportionValues.get(y) %>],
      		  <%
      	  }           
      	%>           
     	               
     	               
		]);
      	
      	
      	
      	var joinedData = google.visualization.data.join(proportionIncorrectData, proportionCorrectData, 'full', [[0, 0]], [1], [1]);
      	
      	

	        
	        var options = {'title':'Overall Scoring Distribution: Fluke Proportions (height-width)',
                    'width':chartWidth,
                    'height':chartHeight,
                    'pointSize': 5,
                    'color': 'yellow',
                    series: {
                        0: { color: 'red' },
                     	1: {color: 'green'},

                       
                      },
                      vAxis: {title: "Score (lower is better)"},
                      hAxis: {title: "fraction matches"},
                    };

	        // Instantiate and draw our chart, passing in some options.
	        var chart = new google.visualization.LineChart(document.getElementById('proportionchart_div'));
	        chart.draw(joinedData, options);
	        
	      }
      	              
      	              
</script>


<h1>Algorithm Analysis</h1>

<h2>Overall Scoring</h2>

<div id="overallchart_div"></div>
<p>Average match vs non-match score diff per encounter: <%=(correctScoreTotal/numCorrectScores-incorrectScoreTotal/numIncorrectScores) %></p>

<h2>Individual Algorithm Behavior</h2>

<div id="intersectchart_div"></div>

<div id="dtwchart_div"></div>

<div id="i3schart_div"></div>

<div id="dtwchart_div"></div>

<div id="proportionchart_div"></div>

<h2>Match Links (<%=matchLinks.size() %>)</h2>
<%
for(int i=0;i<matchLinks.size();i++){
	int colonNum=matchLinks.get(i).indexOf(":");
	String enc1Number=matchLinks.get(i).substring(0, (colonNum));
	String enc2Number=matchLinks.get(i).substring(colonNum+1, (matchLinks.get(i).length()));
%>
	<a href="http://<%=CommonConfiguration.getURLLocation(request) %>/encounters/intersectVisualization.jsp?enc1=<%=enc1Number %>&enc2=<%=enc2Number %>">Link</a><br />
<%
}
%>

<h2>Nonmatches (<%=falseLinks.size() %>)</h2>
<%
for(int i=0;i<falseLinks.size();i++){
	int colonNum=falseLinks.get(i).indexOf(":");
	String enc1Number=falseLinks.get(i).substring(0, (colonNum));
	String enc2Number=falseLinks.get(i).substring(colonNum+1, (falseLinks.get(i).length()));
%>
	<a href="http://<%=CommonConfiguration.getURLLocation(request) %>/encounters/intersectVisualization.jsp?enc1=<%=enc1Number %>&enc2=<%=enc2Number %>&intersectionStdDev=<%=intersectionStdDev %>&dtwStdDev=<%=dtwStdDev %>&i3sStdDev=<%=i3sStdDev %>&proportionStdDev=<%=proportionStdDev %>&intersectHandicap=<%=intersectHandicap %>&dtwHandicap=<%=dtwHandicap %>&i3sHandicap=<%=i3sHandicap %>&proportionHandicap=<%=proportionHandicap %>">Link</a><br />
<%
}
%>

<h2>High False Matches (<%=suspectValues.size() %>)</h2>
<%
for(int i=0;i<suspectValues.size();i++){
	int colonNum=suspectValues.get(i).indexOf(":");
	String enc1Number=suspectValues.get(i).substring(0, (colonNum));
	String enc2Number=suspectValues.get(i).substring(colonNum+1, (suspectValues.get(i).length()));
%>
	<a href="http://<%=CommonConfiguration.getURLLocation(request) %>/encounters/intersectVisualization.jsp?enc1=<%=enc1Number %>&enc2=<%=enc2Number %>&intersectionStdDev=<%=intersectionStdDev %>&dtwStdDev=<%=dtwStdDev %>&i3sStdDev=<%=i3sStdDev %>&proportionStdDev=<%=proportionStdDev %>&intersectHandicap=<%=intersectHandicap %>&dtwHandicap=<%=dtwHandicap %>&i3sHandicap=<%=i3sHandicap %>&proportionHandicap=<%=proportionHandicap %>">Link</a><br />
<%
}






} 
catch(Exception ex) {

	ex.printStackTrace();
}
%>


</body>
</html>
