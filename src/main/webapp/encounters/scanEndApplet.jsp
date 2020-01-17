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

<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN"
"http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<%@ page contentType="text/html; charset=iso-8859-1" language="java"
         import="org.ecocean.servlet.ServletUtilities,org.dom4j.Document, org.dom4j.Element,org.dom4j.io.SAXReader, org.ecocean.*, org.ecocean.grid.MatchComparator, org.ecocean.grid.MatchObject, java.io.File, java.util.Arrays, java.util.Iterator, java.util.List, java.util.Vector" %>

<%

String context="context0";
context=ServletUtilities.getContext(request);

//let's set up references to our file system components
String rootWebappPath = getServletContext().getRealPath("/");
File webappsDir = new File(rootWebappPath).getParentFile();
File shepherdDataDir = new File(webappsDir, CommonConfiguration.getDataDirectoryName(context));
File encountersDir=new File(shepherdDataDir.getAbsolutePath()+"/encounters");



  //session.setMaxInactiveInterval(6000);
  String num="";
  if(request.getParameter("number")!=null){
	Shepherd myShepherd=new Shepherd(context);
	myShepherd.setAction("scanEndApplet.jsp");
	myShepherd.beginDBTransaction();
	if(myShepherd.isEncounter(ServletUtilities.preventCrossSiteScriptingAttacks(request.getParameter("number")))){
  		num = ServletUtilities.preventCrossSiteScriptingAttacks(request.getParameter("number"));
	}
	myShepherd.rollbackDBTransaction();
	myShepherd.closeDBTransaction();
  }	
  String encSubdir = Encounter.subdir(num);

	/*
  Shepherd myShepherd = new Shepherd(context);
  myShepherd.setAction("scanEndApplet.jsp");
  if (request.getParameter("writeThis") == null) {
    myShepherd = (Shepherd) session.getAttribute(request.getParameter("number"));
  }
  */
  //Shepherd altShepherd = new Shepherd(context);
  String sessionId = session.getId();
  boolean xmlOK = false;
  SAXReader xmlReader = new SAXReader();
  File file = new File("foo");
  String scanDate = "";
  String C = "";
  String R = "";
  String epsilon = "";
  String Sizelim = "";
  String maxTriangleRotation = "";
  String side2 = "";
%>
<jsp:include page="../header.jsp" flush="true"/>

<style type="text/css">
 
  #tabmenu {
    color: #000;
    border-bottom: 1px solid #CDCDCD;
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
    color: #000;
    background: #E6EEEE;

    border: 1px solid #CDCDCD;
    padding: 2px 5px 0px 5px;
    margin: 0;
    text-decoration: none;
    border-bottom: 0px solid #FFFFFF;
  }

  #tabmenu a.active {
    background: #8DBDD8;
    color: #000000;
    border-bottom: 1px solid #8DBDD8;
  }

  #tabmenu a:hover {
    color: #000;
    background: #8DBDD8;
  }

  #tabmenu a:visited {
    
  }

  #tabmenu a.active:hover {
    color: #000;
    border-bottom: 1px solid #8DBDD8;
  }
  
  td, th {
    border: 1px solid black;
    padding: 5px;
}

#spot-display {}
.match-side {
    text-align: center;
    display: inline-block;
    position: relative;
    width: 49%;
}
.match-side img {
    height: 400px;
}
.match-side-info {
    height: 9.1em;
    background-color: #DDD;
}

#match-controls {
    height: 5em;
}
#match-info {
    width: 70%;
    display: inline-block;
}
#match-controls input {
    position: absolute;
    display: none;
}
#match-button-next {
    right: 0px;
}
#match-button-prev {
    left: 0px;
}

.match-side-attribute-label,
.match-side-attribute-value {
    line-height: 1.3em;
    display: inline-block;
    vertical-align: middle;
}
.match-side-attribute-value {
    text-align: left;
    white-space: nowrap;
    overflow: hidden;
    width: 60%;
}
.match-side-attribute-label {
    width: 39%;
    font-weight: bold;
    font-size: 0.8em;
    text-align: right;
    padding-right: 10px;
}


</style>


<div class="container maincontent">

<ul id="tabmenu">
  <li><a
    href="encounter.jsp?number=<%=num%>">Encounter
    <%=num%>
  </a></li>
  

  <%
    String fileSider = "";
    File finalXMLFile;
    File locationIDXMLFile;
    if ((request.getParameter("rightSide") != null) && (request.getParameter("rightSide").equals("true"))) {
      //finalXMLFile=new File((new File(".")).getCanonicalPath()+File.separator+"webapps"+File.separator+"ROOT"+File.separator+"encounters"+File.separator+num+File.separator+"lastFullRightI3SScan.xml");
      finalXMLFile = new File(encountersDir.getAbsolutePath()+"/"+ encSubdir + "/lastFullRightI3SScan.xml");
      locationIDXMLFile = new File(encountersDir.getAbsolutePath()+"/"+ encSubdir + "/lastFullRightLocationIDScan.xml");


      side2 = "right";
      fileSider = "&rightSide=true";
    } else {
      //finalXMLFile=new File((new File(".")).getCanonicalPath()+File.separator+"webapps"+File.separator+"ROOT"+File.separator+"encounters"+File.separator+num+File.separator+"lastFullI3SScan.xml");
      finalXMLFile = new File(encountersDir.getAbsolutePath()+"/" + encSubdir + "/lastFullI3SScan.xml");
      locationIDXMLFile = new File(encountersDir.getAbsolutePath()+"/" + encSubdir + "/lastFullLocationIDScan.xml");
    }
    
    
    if (locationIDXMLFile.exists()) {
  %>

  <li><a
    href="scanEndAppletLocationID.jsp?writeThis=true&number=<%=num%>&I3S=true<%=fileSider%>">Locally Filtered Results (Modified Groth)</a>
  </li>
  <%
    }
    %>
    
    <li><a class="active">Modified Groth (Full)</a></li>
    <%
    
    if (finalXMLFile.exists()) {
  %>

  <li><a
    href="i3sScanEndApplet.jsp?writeThis=true&number=<%=num%>&I3S=true<%=fileSider%>">I3S</a>
  </li>
  <%
    }
    


  %>


</ul>

<%
  Vector initresults = new Vector();
  Document doc;
  Element root;
  String side = "left";

  /*
  if (request.getParameter("writeThis") == null) {
    initresults = myShepherd.matches;
    if ((request.getParameter("rightSide") != null) && (request.getParameter("rightSide").equals("true"))) {
      side = "right";
    }
  }
  */
  //else {

//read from the written XML here if flagged
    try {
      if ((request.getParameter("rightSide") != null) && (request.getParameter("rightSide").equals("true"))) {
        //file=new File((new File(".")).getCanonicalPath()+File.separator+"webapps"+File.separator+"ROOT"+File.separator+"encounters"+File.separator+num+File.separator+"lastFullRightScan.xml");
        file = new File(encountersDir.getAbsolutePath()+"/" + encSubdir + "/lastFullRightScan.xml");


        side = "right";
      } else {
        //file=new File((new File(".")).getCanonicalPath()+File.separator+"webapps"+File.separator+"ROOT"+File.separator+"encounters"+File.separator+num+File.separator+"lastFullScan.xml");
        file = new File(encountersDir.getAbsolutePath()+"/" + encSubdir + "/lastFullScan.xml");

      }
      doc = xmlReader.read(file);
      root = doc.getRootElement();
      scanDate = root.attributeValue("scanDate");
      xmlOK = true;
      R = root.attributeValue("R");
      C = root.attributeValue("C");
      maxTriangleRotation = root.attributeValue("maxTriangleRotation");
      Sizelim = root.attributeValue("Sizelim");
      epsilon = root.attributeValue("epsilon");
    } catch (Exception ioe) {
      System.out.println("Error accessing the stored scan XML data for encounter: " + num);
      ioe.printStackTrace();
      //initresults = myShepherd.matches;
      xmlOK = false;
    }

  //}
  MatchObject[] matches = new MatchObject[0];
  if (!xmlOK) {
    int resultsSize = initresults.size();
    System.out.println(resultsSize);
    matches = new MatchObject[resultsSize];
    for (int a = 0; a < resultsSize; a++) {
      matches[a] = (MatchObject) initresults.get(a);
    }
    R = request.getParameter("R");
    C = request.getParameter("C");
    maxTriangleRotation = request.getParameter("maxTriangleRotation");
    Sizelim = request.getParameter("Sizelim");
    epsilon = request.getParameter("epsilon");
  }
%>

<p>

<h2>Modified Groth Scan Results <a
  href="<%=CommonConfiguration.getWikiLocation(context)%>scan_results"
  target="_blank"><img src="../images/information_icon_svg.gif"
                       alt="Help" border="0" align="absmiddle"></a></h2>
</p>
<p>The following encounter(s) received the highest
  match values against a <%=side%>-side scan of encounter <a
    href="//<%=CommonConfiguration.getURLLocation(request)%>/encounters/encounter.jsp?number=<%=num%>"><%=num%></a>.</p>


<%
  if (xmlOK) {%>
<p><img src="../images/Crystal_Clear_action_flag.png" width="28px" height="28px" hspace="2" vspace="2" align="absmiddle">&nbsp;<strong>Saved
  scan data may be old and invalid. Check the date below and run a fresh
  scan for the latest results.</strong></p>

<p><em>Date of scan: <%=scanDate%>
</em></p>
<%}%>

<p><a href="#resultstable">See the table below for score breakdowns.</a></p>




<%
    String feedURL = "//" + CommonConfiguration.getURLLocation(request) + "/TrackerFeed?number=" + num;
    String baseURL = "/"+CommonConfiguration.getDataDirectoryName(context)+"/encounters/";

    //System.out.println("Base URL is: " + baseURL);
    if (xmlOK) {
      if ((request.getParameter("rightSide") != null) && (request.getParameter("rightSide").equals("true"))) {
        feedURL = baseURL + encSubdir + "/lastFullRightScan.xml?";
      } else {
        feedURL = baseURL + encSubdir + "/lastFullScan.xml?";
      }
    }
    String rightSA = "";
    if ((request.getParameter("rightSide") != null) && (request.getParameter("rightSide").equals("true"))) {
      rightSA = "&filePrefix=extractRight";
    }
    //System.out.println("I made it to the Flash without exception.");
/*
<matchSet scanDate="Thu Jul 22 17:42:02 EDT 2010" R="8" epsilon="0.01" Sizelim="0.9" maxTriangleRotation="30" C="0.99">
  <match points="162.0" adjustedpoints="0.34394904458598724" pointBreakdown="23 + 19 + 16 + 15 + 14 + 11 + 11 + 11 + 10 + 10 + 8 + 8 + 6 + " finalscore="55.719" logMStdDev="0.02923" evaluation="Moderate">
    <encounter number="19520090917" date="18/5/2009, 14:00" sex="unsure" assignedToShark="Unassigned" size="7.0 meters" location="Ningaloo Marine Park (Northern)" locationID="1a1">
      <spot x="173.0" y="106.00000000000001"/>
      <spot x="170.0" y="315.0"/>
      <spot x="88.0" y="190.0"/>
      <spot x="92.0" y="244.00000000000003"/>
      <spot x="253.0" y="91.0"/>
      <spot x="195.0" y="194.0"/>
      <spot x="327.0" y="227.0"/>
      <spot x="195.0" y="256.0"/>
      <spot x="88.0" y="145.0"/>
      <spot x="108.0" y="327.0"/>
      <spot x="282.0" y="297.0"/>
      <spot x="81.0" y="101.0"/>
      <spot x="339.0" y="170.0"/>
    </encounter>
    <encounter number="2272010153941"
*/
  %>

<script>
var subdirPrefix = '/<%=shepherdDataDir.getName()%>/encounters';
var xmlFile = subdirPrefix + '/<%=encSubdir%>/<%=file.getName()%>';
var xmlData = null;
var jsonData = [];
var rightSide = <%=side2.equals("right")%>;
var currentPair = 0;
$(document).ready(function() {
    $.ajax({
        url: xmlFile,
        dataType: 'xml',
        type: 'GET',
        complete: function(xhr) {
            console.info(xhr);
            if (!xhr || (xhr.status != 200) || !xhr.responseXML) {
                var errorMsg = 'Unknown error';
                if (xhr) errorMsg = xhr.status + ' - ' + xhr.statusText
                $('#spot-display').html('<h1 class="error">Unable to fetch data: ' + errorMsg + '</h1>');
            } else {
                xmlData = $(xhr.responseXML);
                spotDisplayInit(xmlData);
            }
        }
    });
});

function spotDisplayInit(xml) {
    xmlData.find('match').each(function(i, el) {
        var m = xmlAttributesToJson(el);
        m.encounters = [];
        for (var j = 0 ; j < el.children.length ; j++) {
            var e = xmlAttributesToJson(el.children[j]);
            e.imgUrl = subdirPrefix + '/' + e.number + '/extract' + (rightSide ? 'Right' : '') + e.number + '.jpg';
            e.spots = [];
            for (var i = 0 ; i < el.children[j].children.length ; i++) {
                e.spots.push(xmlAttributesToJson(el.children[j].children[i]));
            }
            m.encounters.push(e);
        }
        jsonData.push(m);
    });
    spotDisplayPair(0);
}

function xmlAttributesToJson(el) {
    var j = {};
    for (var i = 0 ; i < el.attributes.length ; i++) {
        j[el.attributes[i].name] = el.attributes[i].value;
    }
    return j;
}

function spotDisplayPair(mnum) {
    currentPair = mnum;
    if (!jsonData[mnum] || !jsonData[mnum].encounters || (jsonData[mnum].encounters.length != 2)) return;
    for (var i = 0 ; i < 2 ; i++) {
        spotDisplaySide(1 - i, jsonData[mnum].encounters[i]);
    }
    if (mnum < 1) {
        $('#match-button-prev').hide();
    } else {
        $('#match-button-prev').show();
    }
    if (mnum >= jsonData.length - 1) {
        $('#match-button-next').hide();
    } else {
        $('#match-button-next').show();
    }
    $('#match-info').html('Match score: <b>' + jsonData[mnum].finalscore + '</b> (Match ' + (mnum+1) + ' of ' + jsonData.length + ')');
}

var attrOrder = ['number', 'date', 'sex', 'assignedToShark', 'size', 'location', 'locationID'];
var attrLabel = {
    number: 'Enc ID',
    date: 'Date', 
    sex: 'Sex',
    assignedToShark: 'Assigned to',
    size: 'Size',
    location: 'Location',
    locationID: 'Location ID'
};
function spotDisplaySide(side, data) {
console.log('spotDisplaySide ==> %i %o', side, data);
    $('#match-side-' + side + ' img').prop('src', data.imgUrl);
    var h = '<div class="match-side-attributes">';
    for (var i = 0 ; i < attrOrder.length ; i++) {
        var label = attrLabel[attrOrder[i]] || attrOrder[i];
        var value = data[attrOrder[i]];
        h += '<div><div class="match-side-attribute-label">' + label + '</div>';
        h += '<div class="match-side-attribute-value">' + value + '</div></div>';
    }
    h += '</div>';
    $('#match-side-' + side + ' .match-side-info').html(h);
}

function spotDisplayButton(delta) {
    currentPair += delta;
    if (currentPair < 0) currentPair = jsonData.length;
    if (currentPair > jsonData.length - 1) currentPair = 0;
    spotDisplayPair(currentPair);
}

</script>
    
<div id="spot-display">
    <div class="match-side" id="match-side-0">
        <img />
        <div class="match-side-info"></div>
    </div>
    <div class="match-side" id="match-side-1">
        <img />
        <div class="match-side-info"></div>
    </div>
    <div id="match-controls">
        <div id="match-info"></div>
        <div style="position: relative; display: inline-block; width: 20%; height: 3em;">
            <input id="match-button-prev" type="button" value="previous" onClick="return spotDisplayButton(-1)" />
            <input id="match-button-next" type="button" value="next" onClick="return spotDisplayButton(1)" />
        </div>
    </div>
</div>

  <OBJECT id=sharkflash
          codeBase=http://download.macromedia.com/pub/shockwave/cabs/flash/swflash.cab#version=6,0,0,0
          height=450 width=800 classid=clsid:D27CDB6E-AE6D-11cf-96B8-444553540000>
    <PARAM NAME="movie"
           VALUE="tracker.swf?sessionId=<%=sessionId%>&rootURL=<%=CommonConfiguration.getURLLocation(request)%>&baseURL=<%=baseURL%>&feedurl=<%=feedURL%><%=rightSA%>">
    <PARAM NAME="qualidty" VALUE="high">
    <PARAM NAME="scale" VALUE="exactfit">
    <PARAM NAME="bgcolor" VALUE="#ddddff">
    <EMBED
      src="tracker.swf?sessionId=<%=sessionId%>&rootURL=<%=CommonConfiguration.getURLLocation(request)%>&baseURL=<%=baseURL%>&feedurl=<%=feedURL%>&time=<%=System.currentTimeMillis()%><%=rightSA%>"
      quality=high scale=exactfit bgcolor=#ddddff swLiveConnect=TRUE
      WIDTH="800" HEIGHT="450" NAME="sharkflash" ALIGN=""
      TYPE="application/x-shockwave-flash"
      PLUGINSPAGE="http://www.macromedia.com/go/getflashplayer"></EMBED>
  </OBJECT>
</p>
  
      <a name="resultstable"/>
      
      <table class="tablesorter" width="800px">
      <thead>
        <tr align="left" valign="top">
          <th><strong>Individual ID</strong></th>
          <th><strong> Encounter</strong></th>
          <th><strong>Fraction Matched Triangles </strong></th>
          <th><strong>Match Score </strong></th>
    
          <th><strong>logM std. dev.</strong></th>
          <th><strong>Confidence</strong></th>
          <th><strong>Matched Keywords</strong></th>

        </tr>
        </thead>
        <tbody>
        <%
          if (!xmlOK) {

            MatchObject[] results = new MatchObject[1];
            results = matches;
            Arrays.sort(results, new MatchComparator());
            for (int p = 0; p < results.length; p++) {
              if ((results[p].matchValue != 0) || (request.getAttribute("singleComparison") != null)) {%>
        <tr>
          <td>
            <a
                  href="//<%=CommonConfiguration.getURLLocation(request)%>/individuals.jsp?number=<%=results[p].getIndividualName()%>"><%=results[p].getIndividualName()%>
                </a>
          </td>
          <%if (results[p].encounterNumber.equals("N/A")) {%>
          <td>N/A</td>
          <%} else {%>
          <td><a
            href="//<%=CommonConfiguration.getURLLocation(request)%>/encounters/encounter.jsp?number=<%=results[p].encounterNumber%>"><%=results[p].encounterNumber%>
          </a></td>
          <%
            }
            String adjustedMatchValueString = (new Double(results[p].adjustedMatchValue)).toString();
            if (adjustedMatchValueString.length() > 5) {
              adjustedMatchValueString = adjustedMatchValueString.substring(0, 5);
            }
          %>
          <td><%=(adjustedMatchValueString)%><br>
          </td>
          <%
            String finalscore2 = (new Double(results[p].matchValue * results[p].adjustedMatchValue)).toString();

            //trim the length of finalscore
            if (finalscore2.length() > 7) {
              finalscore2 = finalscore2.substring(0, 6);
            }
          %>
          <td><%=finalscore2%>
          </td>

          <td><font size="-2"><%=results[p].getLogMStdDev()%>
          </font></td>
          <td><font size="-2"><%=results[p].getEvaluation()%>
          </font></td>

        </tr>

        <%
              //end if matchValue!=0 loop
            }
            //end for loop
          }

//or use XML output here	
        } else {
          doc = xmlReader.read(file);
          root = doc.getRootElement();

          Iterator matchsets = root.elementIterator("match");
          while (matchsets.hasNext()) {
            Element match = (Element) matchsets.next();
            List encounters = match.elements("encounter");
            Element enc1 = (Element) encounters.get(0);
            Element enc2 = (Element) encounters.get(1);
        %>
        
        <tr align="left" valign="top">
          <td>
            <a href="//<%=CommonConfiguration.getURLLocation(request)%>/individuals.jsp?number=<%=enc1.attributeValue("assignedToShark")%>">
            	<%=enc1.attributeValue("assignedToShark")%>
            </a>
          </td>
          <%if (enc1.attributeValue("number").equals("N/A")) {%>
          <td>N/A</td>
          <%} else {%>
          <td><a
            href="//<%=CommonConfiguration.getURLLocation(request)%>/encounters/encounter.jsp?number=<%=enc1.attributeValue("number")%>">Link
          </a></td>
          <%
            }
            String adjustedpoints = "No Adj.";
            adjustedpoints = match.attributeValue("adjustedpoints");
            if (adjustedpoints == null) {
              adjustedpoints = "&nbsp;";
            }
            if (adjustedpoints.length() > 5) {
              adjustedpoints = adjustedpoints.substring(0, 5);
            } else {
              adjustedpoints = adjustedpoints + "<br>";
            }
          %>
          <td><%=adjustedpoints%>
          </td>
          <%
            String finalscore = "&nbsp;";
            try {
              if (match.attributeValue("finalscore") != null) {
                finalscore = match.attributeValue("finalscore");
              }
            } catch (NullPointerException npe) {
            }

            //trim the length of finalscore
            if (finalscore.length() > 7) {
              finalscore = finalscore.substring(0, 6);
            }

          %>
          <td><%=finalscore%>
          </td>


          <td><font size="-2"><%=match.attributeValue("logMStdDev")%>
          </font></td>
          <%
            String evaluation = "No Adj.";
            evaluation = match.attributeValue("evaluation");
            if (evaluation == null) {
              evaluation = "&nbsp;";
            }

          %>
          <td><font size="-2"><%=evaluation%>
          </font></td>
          <td>
            <%
              String keywords = "";
              for (Iterator i = match.elementIterator("keywords"); i.hasNext();) {
                Element kws = (Element) i.next();
                // iterate the keywords themselves
                for (Iterator j = kws.elementIterator("keyword"); j.hasNext();) {
                  Element kws2 = (Element) j.next();
                  keywords = keywords + "<li>" + kws2.attributeValue("name") + "</li>";
                }
              }
              if (keywords.length() <= 1) {
                keywords = "&nbsp;";
              }
            %> <font size="-2">
            <ul><%=keywords%>
            </ul>
          </font></td>
        </tr>

        <%


            }
          }

        %>
</tbody>
      </table>



  <%



	//myShepherd.closeDBTransaction();
    //myShepherd = null;
    doc = null;
    root = null;
    initresults = null;
    file = null;
    xmlReader = null;
    
if ((request.getParameter("epsilon") != null) && (request.getParameter("R") != null)) {%>
      <p><font size="+1">Custom Scan</font></p>
      <%} else {%>
      <p><font size="+1">Standard Scan</font></p>
      <%}%>
      <p>For this scan, the following variables were used:</p>
      <ul>


        <li>epsilon (<%=epsilon%>)</li>
        <li>R (<%=R%>)</li>
        <li>Sizelim (<%=Sizelim%>)</li>
        <li>C (<%=C%>)</li>
        <li>Max. Triangle Rotation (<%=maxTriangleRotation%>)</li>

      </ul>
<br />
</div>
<jsp:include page="../footer.jsp" flush="true"/>

