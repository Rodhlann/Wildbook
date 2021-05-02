<%@ page contentType="text/html; charset=iso-8859-1" language="java"
         import="org.ecocean.servlet.ServletUtilities,javax.servlet.http.HttpUtils,
org.json.JSONObject, org.json.JSONArray,
org.ecocean.media.*,
org.ecocean.CommonConfiguration,
java.util.HashMap,
org.ecocean.security.Collaboration,
org.ecocean.identity.IdentityServiceLog,
org.ecocean.servlet.IndividualAddEncounter,
org.ecocean.servlet.importer.ImportTask,
org.ecocean.SystemValue,
org.ecocean.ia.Task,
java.util.HashMap,
javax.jdo.Query,
java.util.ArrayList,org.ecocean.Annotation, org.ecocean.Encounter,
org.dom4j.Document, org.dom4j.Element,org.dom4j.io.SAXReader, org.ecocean.*, org.ecocean.grid.MatchComparator, org.ecocean.grid.MatchObject, java.io.File, java.util.Arrays, java.util.Iterator, java.util.List, java.util.Vector, java.nio.file.Files, java.nio.file.Paths, java.nio.file.Path" %>

<%!
//try to see if encounter was part of ImportTask so we can mark complete
//  note: this sets *all annots* on that encounter!  clever or stupid?  tbd!
private static void setImportTaskComplete(Shepherd myShepherd, Encounter enc) {
    if ((enc == null) || (enc.numAnnotations() < 1)) return;
    String jdoql = "SELECT FROM org.ecocean.servlet.importer.ImportTask WHERE encounters.contains(enc) && enc.catalogNumber =='" + enc.getCatalogNumber() + "'";
    Query query = myShepherd.getPM().newQuery(jdoql);
    query.setOrdering("created desc");
    List results = (List)query.execute();
    ImportTask itask = null;
    if (!Util.collectionIsEmptyOrNull(results)) itask = (ImportTask)results.get(0);
    query.closeAll();
System.out.println("setImportTaskComplete(" + enc + ") => " + itask);
    if (itask == null) return;
    String svKey = "rapid_completed_" + itask.getId();
    myShepherd.beginDBTransaction();
    JSONObject m = SystemValue.getJSONObject(myShepherd, svKey);
    if (m == null) m = new JSONObject();
    for (Annotation ann : enc.getAnnotations()) {
        m.put(ann.getId(), true);
System.out.println("setImportTaskComplete() setting true for annot " + ann.getId());
    }
    SystemValue.set(myShepherd, svKey, m);
    myShepherd.commitDBTransaction();
}

String rotationInfo(MediaAsset ma) {
    if ((ma == null) || (ma.getMetadata() == null)) return null;
    HashMap<String,String> orient = ma.getMetadata().findRecurse(".*orient.*");
    if (orient == null) return null;
    for (String k : orient.keySet()) {
        if (orient.get(k).matches(".*90.*")) return orient.get(k);
        if (orient.get(k).matches(".*270.*")) return orient.get(k);
    }
    return null;
}
%>

<%

String context = ServletUtilities.getContext(request);
String langCode = ServletUtilities.getLanguageCode(request);

org.ecocean.ShepherdPMF.getPMF(context).getDataStoreCache().evictAll();

String scoreType = request.getParameter("scoreType");
// we'll show individualScores unless the url specifies scoreType = image (aka annotation)
boolean individualScores = (scoreType==null || !"image".equals(scoreType));

Integer nResults = null;
String nResultsStr = request.getParameter("nResults");

// some logic related to generating names for individuals
Shepherd myShepherd = new Shepherd(request);
myShepherd.setAction("matchResults nameKey getter");
myShepherd.beginDBTransaction();
User user = myShepherd.getUser(request);
String currentUsername = "";
if (user!=null){	
	currentUsername = user.getUsername();
}

String nextNameKey = (user!=null) ? user.getIndividualNameKey() : null;

boolean usesAutoNames = Util.stringExists(nextNameKey);

String nextName = (usesAutoNames) ? MultiValue.nextUnusedValueForKey(nextNameKey, myShepherd) : null;

String projectIdPrefix = request.getParameter("projectIdPrefix");
String researchProjectName = null;
String researchProjectUUID = null;
String nextNameString = "";
// okay, are we going to use an incremental name from the project side?
if (Util.stringExists(projectIdPrefix)) {
	Project projectForAutoNaming = myShepherd.getProjectByProjectIdPrefix(projectIdPrefix.trim());
	if (projectForAutoNaming!=null) {
		researchProjectName = projectForAutoNaming.getResearchProjectName();
		researchProjectUUID = projectForAutoNaming.getId();
		nextNameKey = projectForAutoNaming.getProjectIdPrefix();
		nextName = projectForAutoNaming.getNextIncrementalIndividualId();
		usesAutoNames = true;
		if (usesAutoNames) {
			if (Util.stringExists(nextNameKey)) {
				nextNameString += (nextNameKey+": ");
			}
			if (Util.stringExists(nextName)) {
				nextNameString += nextName;
			}
		}
	}
}

myShepherd.rollbackAndClose();
//myShepherd.closeDBTransaction();
//System.out.println("IARESULTS: New nameKey block got key, value "+nextNameKey+", "+nextName+" for user "+user);

try {
	nResults = Integer.parseInt(nResultsStr);
} catch (Exception e) {}
int RESMAX_DEFAULT = 12;
int RESMAX = (nResults!=null) ? nResults : RESMAX_DEFAULT;

String gaveUpWaitingMsg = "Gave up trying to obtain results. Refresh page to keep waiting.";
//this is a quick hack to produce a useful set of info about an Annotation (as json) ... poor mans api?  :(
if (request.getParameter("acmId") != null) {
	String acmId = request.getParameter("acmId");
	myShepherd = new Shepherd(context);
	myShepherd.setAction("iaResults.jsp1");
	myShepherd.beginDBTransaction();
    ArrayList<Annotation> anns = null;
	JSONObject rtn = new JSONObject("{\"success\": false}");
	try {
		anns = myShepherd.getAnnotationsWithACMId(acmId);
	} catch (Exception ex) {}
	if ((anns == null) || (anns.size() < 1)) {
		rtn.put("error", "unknown error");
	} else {
		JSONArray janns = new JSONArray();
		System.out.println("trying projectIdPrefix in iaResults... "+projectIdPrefix);
		Project project = null;
		if (Util.stringExists(projectIdPrefix)) {
			project = myShepherd.getProjectByProjectIdPrefix(projectIdPrefix.trim());
		}
		String locationIdPrefix = null;
		int locationIdPrefixDigitPadding = 3; //had to pick a non-null default
        for (Annotation ann : anns) {
			if (ann.getMatchAgainst()==true) {
				JSONObject jann = new JSONObject();
				jann.put("id", ann.getId());
				jann.put("acmId", ann.getAcmId());
				Encounter enc = ann.findEncounter(myShepherd);
	 			if (enc != null) {
	 				jann.put("encounterId", enc.getCatalogNumber());
	 				jann.put("encounterLocationId", enc.getLocationID());
					locationIdPrefix = enc.getPrefixForLocationID();
					jann.put("encounterLocationIdPrefix", locationIdPrefix);
					locationIdPrefixDigitPadding = enc.getPrefixDigitPaddingForLocationID();
					jann.put("encounterLocationIdPrefixDigitPadding", locationIdPrefixDigitPadding);
					jann.put("encounterLocationNextValue", MarkedIndividual.nextNameByPrefix(locationIdPrefix, locationIdPrefixDigitPadding));

	 			}
				MediaAsset ma = ann.getMediaAsset();
				if (ma != null) {
			            JSONObject jm = Util.toggleJSONObject(ma.sanitizeJson(request, new org.datanucleus.api.rest.orgjson.JSONObject()));
                                    if (ma.getStore() instanceof TwitterAssetStore) jm.put("url", ma.webURL());
                                    jm.put("rotation", rotationInfo(ma));
			            jann.put("asset", jm);
				}
				if (project!=null) {
					try {

						if (enc!=null) {;
							System.out.println("All encs for project: "+Arrays.asList(project.getEncounters()).toString());
						}

						if (project.getEncounters()!=null&&project.getEncounters().contains(enc)) {
							System.out.println("num encounters in project: "+project.getEncounters().size());
							MarkedIndividual individual = enc.getIndividual();
							if (individual!=null) {
								List<String> projectNames = individual.getNamesList(projectIdPrefix);
								jann.put("incrementalProjectId", projectNames.get(0));
								jann.put("projectIdPrefix", projectIdPrefix);
								jann.put("projectUUID", project.getId());
							}
						} 
					} catch (Exception e) {
						e.printStackTrace();
					}
				}
				janns.put(jann);
			}
		}
	    rtn.put("success", true);
        rtn.put("annotations", janns);
	}
/*
	if ((qann != null) && (qann.getMediaAsset() != null)) {
		qMediaAssetJson = qann.getMediaAsset().sanitizeJson(request, new org.datanucleus.api.rest.orgjson.JSONObject()).toString();
        	enc = Encounter.findByAnnotation(qann, myShepherd2);
		num = enc.getCatalogNumber();
	}
*/
	myShepherd.rollbackAndClose();
	out.println(rtn.toString());
	return;
}


//TODO security for this stuff, obvs?
//quick hack to set id & approve
String taskId = request.getParameter("taskId");
boolean useLocation = Util.requestParameterSet(request.getParameter("useLocation"));
if ((request.getParameter("number") != null) && ((request.getParameter("individualID") != null) || useLocation)) {
	JSONObject res = new JSONObject("{\"success\": false}");
	res.put("encounterId", request.getParameter("number"));
	res.put("encounterId2", request.getParameter("enc2"));
	res.put("individualId", request.getParameter("individualID"));
        res.put("useLocation", useLocation);
	res.put("taskId", taskId);
	String projectId = null; 
	if (Util.stringExists(request.getParameter("projectId"))) {
		res.put("projectId", request.getParameter("projectId"));
		projectId = request.getParameter("projectId");
	}

	myShepherd = new Shepherd(context);
	myShepherd.setAction("iaResults.jsp2");
	myShepherd.beginDBTransaction();

	Encounter enc = myShepherd.getEncounter(request.getParameter("number"));
	if (enc == null) {
		res.put("error", "no such encounter: " + request.getParameter("number"));
		out.println(res.toString());
		myShepherd.rollbackDBTransaction();
		myShepherd.closeDBTransaction();
		return;
	}
	else if(!ServletUtilities.isUserAuthorizedForEncounter(enc, request)){
		res.put("error", "User unauthorized for encounter: " + request.getParameter("number"));
		out.println(res.toString());
		myShepherd.rollbackDBTransaction();
		myShepherd.closeDBTransaction();
		return;
	} else if (useLocation && !Util.stringExists(enc.getLocationID())) {
		res.put("error", "Empty locationID with useLocation=true for encounter: " + request.getParameter("number"));
		out.println(res.toString());
		myShepherd.rollbackDBTransaction();
		myShepherd.closeDBTransaction();
		return;
	}

	Encounter enc2 = null;
	if (request.getParameter("enc2") != null) {
		enc2 = myShepherd.getEncounter(request.getParameter("enc2"));
		myShepherd.getPM().refresh(enc2);

		if (enc2 == null) {
			res.put("error", "no such encounter: " + request.getParameter("enc2"));
			out.println(res.toString());
			myShepherd.rollbackDBTransaction();
			myShepherd.closeDBTransaction();
			return;
		}
		else if(!ServletUtilities.isUserAuthorizedForEncounter(enc2, request)){
			res.put("error", "User unauthorized for encounter: " + request.getParameter("number"));
			out.println(res.toString());
			myShepherd.rollbackDBTransaction();
			myShepherd.closeDBTransaction();
			return;
		}
	}
	/* now, making an assumption here (and the UI does as well):
	   basically, we only allow a NEW INDIVIDUAL when both encounters are unnamed;
	   otherwise, we are assuming we are naming one based on the other.  thus, we MUST
	   use an *existing* indiv in those cases (but allow a new one in the other)

            addendum via WB-1216: the NEW INDIVIDUAL case can now allow for useLocation=true option.
	*/

	// once you assign an id to one, it will still ask for input on another.

	String indyUUID = null;
	MarkedIndividual indiv = null;
	MarkedIndividual indiv2 = null;
	String individualID = null;
	try {

		individualID = request.getParameter("individualID");
		if (individualID!=null) individualID = individualID.trim();
		// from query enc
		indiv = myShepherd.getMarkedIndividual(enc);
		// from target enc
		indiv2 = myShepherd.getMarkedIndividual(enc2);
		indyUUID = request.getParameter("newIndividualUUID");
		//should take care of getting an indy stashed in the URL params
		if (indiv==null) {
			indiv = myShepherd.getMarkedIndividualQuiet(indyUUID);
		}

		System.out.println("got ID: "+indyUUID+" from header set previous match");

		System.out.println("did you get indiv? "+indiv+" did you get indiv2? "+indiv2);

		// if both have an id, throw an error. any deecision to override would be arbitrary
		// should get to MERGE option instead of getting here anyway
		if (indiv!=null&&indiv2!=null) {


			// need nuance here.. if both individuals are present but there is not a project ID allow set

			res.put("error", "Both encounters already have an ID. You must remove one or reassign from the Encounter page.");
			out.println(res.toString());
			myShepherd.rollbackDBTransaction();
			myShepherd.closeDBTransaction();
		}
	} catch (Exception e) {
		e.printStackTrace();
	}

	// allow flow either way if one or the other has an ID
	if ((indiv == null || indiv2 == null) && (enc != null) && (enc2 != null)) {

		System.out.println("indiv OR indiv2 is null, and two viable enc have been selected!");

		try {


			//enc.setState("approved");
			//enc2.setState("approved");
			
			// neither have an individual
			if (indiv==null&&indiv2==null) {
                                //note that useLocation flavor has slight race condition possible here...
                                // might be better to have way to *create* indiv with new loc-based name
                                if (useLocation) {
                                    String locPrefix = LocationID.getPrefixForLocationID(enc.getLocationID(), null);
									int prefixPadding = LocationID.getPrefixDigitPaddingForLocationID(enc.getLocationID(), null);
                                    individualID = MarkedIndividual.nextNameByPrefix(locPrefix, prefixPadding);
                                }
				if (Util.stringExists(individualID)) {
					System.out.println("CASE 1: both indy null");
					if (Util.isUUID(individualID)) {
						indiv = myShepherd.getMarkedIndividual(individualID);
					} 
					if (indiv==null) {
						indiv = new MarkedIndividual(individualID, enc);
					}
					
					

					myShepherd.getPM().makePersistent(indiv);
					//check for project to add new name with prefix
					if (projectId!=null) {
						Project project = myShepherd.getProjectByProjectIdPrefix(projectId);
						if (project!=null&&project.getNextIncrementalIndividualId().equals(individualID)) {
							project.getNextIncrementalIndividualIdAndAdvance();
							myShepherd.updateDBTransaction();
						}
						
						indiv.addNameByKey(projectId, individualID);
						res.put("newIncrementalId", indiv.getDisplayName(projectId));
					}
					myShepherd.updateDBTransaction();
					//res.put("newIndividualUUID", indiv.getId());
					res.put("individualName", indiv.getDisplayName(request, myShepherd));
					res.put("individualId", indiv.getId());
					enc.setIndividual(indiv);
					enc2.setIndividual(indiv);
					indiv.addEncounter(enc2);
					
					myShepherd.updateDBTransaction();
                                        setImportTaskComplete(myShepherd, enc);
                                        setImportTaskComplete(myShepherd, enc2);
                    indiv.refreshNamesCache();
                    
                    IndividualAddEncounter.executeEmails(myShepherd, request,indiv,true, enc2, context, langCode);
                    IndividualAddEncounter.executeEmails(myShepherd, request,indiv,true, enc, context, langCode);
                    
                    
				} else {
					res.put("error", "Please enter a new Individual ID for both encounters.");
				}
			}

			// query enc has indy, or already stashed in URL params
			if (indiv!=null&&indiv2==null) {
				System.out.println("CASE 2: query enc indy is null");
				enc2.setIndividual(indiv);
				indiv.addEncounter(enc2);
				res.put("individualName", indiv.getDisplayName(request, myShepherd));
				myShepherd.updateDBTransaction();
				IndividualAddEncounter.executeEmails(myShepherd, request,indiv,false, enc2, context, langCode);
                                setImportTaskComplete(myShepherd, enc2);
			} 	
			
			// target enc has indy
			if (indiv==null&&indiv2!=null) {
				System.out.println("CASE 3: target enc indy is null");
				enc.setIndividual(indiv2);					
				indiv2.addEncounter(enc);
				res.put("individualName", indiv2.getDisplayName(request, myShepherd));
				myShepherd.updateDBTransaction();
				
				IndividualAddEncounter.executeEmails(myShepherd, request,indiv2,false, enc, context, langCode);
                                setImportTaskComplete(myShepherd, enc);
			} 


			String matchMsg = enc.getMatchedBy();
			if ((matchMsg == null) || matchMsg.equals("Unknown")) matchMsg = "";
			matchMsg += "<p>match approved via <i>iaResults</i> (by <i>" + AccessControl.simpleUserString(request) + "</i>) " + ((taskId == null) ? "<i>unknown Task ID</i>" : "Task <b>" + taskId + "</b>") + "</p>";
			enc.setMatchedBy(matchMsg); 
			enc2.setMatchedBy(matchMsg);

			if (res.optString("error", null) == null) res.put("success", true);
			
		} catch (Exception e) {
			//enc.setState("unapproved");
			//enc2.setState("unapproved");
			e.printStackTrace();
			res.put("error", "Please enter a different Individual ID.");
		}

		//indiv.addComment(????)
		out.println(res.toString());
		myShepherd.rollbackDBTransaction();
		myShepherd.closeDBTransaction();
		return;
	} 

	if (indiv == null && indiv2 == null) {
		res.put("error", "No valid record could be found or created for name: " + individualID);
		out.println(res.toString());
		myShepherd.rollbackDBTransaction();
		myShepherd.closeDBTransaction();
		return;
	}

	if (myShepherd.getPM().currentTransaction().isActive()) {
		myShepherd.commitDBTransaction();
		myShepherd.closeDBTransaction();
	}

	res.put("error", "Unknown error setting individual " + individualID);
	out.println(res.toString());
	return;
}

// confirm no match and set next automatic name
if (request.getParameter("encId")!=null && request.getParameter("noMatch")!=null) {

	try {
		String encId = request.getParameter("encId");
		myShepherd = new Shepherd(request);
		myShepherd.setAction("iaResults.jsp - no match case");
		myShepherd.beginDBTransaction();
		JSONObject rtn = new JSONObject("{\"success\": false}");
		Encounter enc = myShepherd.getEncounter(encId);
		if (enc==null) {
			rtn.put("error", "could not find Encounter "+encId+" in the database.");
			out.println(rtn.toString());
			myShepherd.rollbackDBTransaction();
			myShepherd.closeDBTransaction();
			return;
		}
		else if(!ServletUtilities.isUserAuthorizedForEncounter(enc, request)){
			rtn.put("error", "User unauthorized for encounter: " + request.getParameter("number"));
			out.println(rtn.toString());
			myShepherd.rollbackDBTransaction();
			myShepherd.closeDBTransaction();
			return;
		}

		String useNextProjectId = request.getParameter("useNextProjectId");
		boolean validToName = false;

		System.out.println("useNextProjectId= "+useNextProjectId+" Util.stringExists(nextNameKey)="+Util.stringExists(nextNameKey)+"  Util.stringExists(nextName)= "+Util.stringExists(nextName)+"");

		if (("true".equals(useNextProjectId) || Util.stringExists(nextNameKey) ) && Util.stringExists(nextName)) {
			validToName = true;
		}

		if (!validToName) {
			rtn.put("error", "Was unable to set the next automatic name. Got key="+nextNameKey+" and val="+nextName);
			out.println(rtn.toString());
			myShepherd.rollbackDBTransaction();
			myShepherd.closeDBTransaction();
			return;
		}

		MarkedIndividual mark = enc.getIndividual();

		if (mark==null) {
			mark = new MarkedIndividual(enc);
			myShepherd.getPM().makePersistent(mark);
			myShepherd.updateDBTransaction();
			IndividualAddEncounter.executeEmails(myShepherd, request,mark,true, enc, context, langCode);
             
		}

		if (validToName&&"true".equals(useNextProjectId)) {
			System.out.println("trying to set next PROJECT automatic name.......");
			Project projectForAutoNaming = myShepherd.getProjectByProjectIdPrefix(projectIdPrefix.trim());
			mark.addIncrementalProjectId(projectForAutoNaming);
		} else {
			System.out.println("trying to set USER BASED automatic name.......");
			// old user based id
			mark.addName(nextNameKey, nextName);		
		}
		
		System.out.println("RTN for no match naming: "+rtn.toString());
		
		rtn.put("success",true);
		out.println(rtn.toString());
		myShepherd.commitDBTransaction();
		myShepherd.closeDBTransaction();
		return;

	} catch (Exception e) {
		e.printStackTrace();
	}

}



  //session.setMaxInactiveInterval(6000);

%>

<script type="text/javascript" src="javascript/ia.IBEIS.js"></script>  <!-- TODO plugin-ier -->
<script type="text/javascript" src="javascript/animatedcollapse.js"></script>

<jsp:include page="header.jsp" flush="true" />

<script src="javascript/openseadragon/openseadragon.min.js"></script>


<div id="encid" style="">

<!-- overwrites ia.IBEIS.js for testing -->

<%
%>


<div class="container maincontent">

	<div class="instructions-container">
    <h4 class="intro accordion" style="margin-bottom:0"><a
       href="javascript:animatedcollapse.toggle('instructions')" style="text-decoration:none"><span class="el el-chevron-right rotate-chevron"></span> Instructions</a></h4>
    <div class="instructions" id="instructions" style="display:none;">
			<p class="algoInstructions"><ul>
				<li>Hover mouse over results below to <b>compare candidates</b> to target.</li>
				<li>Links to <b>encounters</b> and <b>individuals</b> are next to each match score.</li>
				<li>Select <b>correct match</b> by hovering over the correct result and checking the checkbox</li>
				<li>Use the buttons below to switch between result types:<ul>
					<li><b>Image Scores:</b> computes the match score for every <em>image</em> in the database when compared to the query image</li>
					<li><b>Individual Scores:</b> computes one match score for every <em>individual</em> in the database. This is the aggregate of each image score for that individual.</li>
				</ul></li>
				<%
				if (usesAutoNames) {
					%><li><strong>Auto-naming: </strong>Your account has auto-naming set up with the name label <strong><%=nextNameKey%></strong>. Depending on the checkbox below, the next auto-generated name <strong><%=nextNameKey%>: <%=nextName%></strong> will be added to your match results.</li><%
				}
				%>
			</ul></p>
		</div>
	</div>
<style type="text/css">
/* this .search-collapse-header .rotate-chevron logic doesn't work
 because animatedcollapse.js is eating the click event (I think.).
 It's unclear atm where/whether to modify animatedcollapse.js to
 rotate this chevron.
*/
h4.intro.accordion .rotate-chevron {
    -moz-transition: transform 0.5s;
    -webkit-transition: transform 0.5s;
    transition: transform 0.5s;
}
h4.intro.accordion .rotate-chevron.down {
    -ms-transform: rotate(90deg);
    -moz-transform: rotate(90deg);
    -webkit-transform: rotate(90deg);
    transform: rotate(90deg);
}

#projectDropdownSpan {
	position: absolute;
	padding-top: 25px;
}

</style>

<script>
	
	
	animatedcollapse.addDiv('instructions', 'fade=1');
	animatedcollapse.init();
	$("h4.accordion a").click(function() {
		$(this).children(".rotate-chevron").toggleClass("down");
	});
	
	//Map of the OpenSeadragon viewers
	var viewers = new Map();
	var features=new Map();
	
</script>




	<div id="result_settings" style="display: inline-block;">
      <div>
		<span id="scoreTypeSettings">
		<%

		// Here we (statically, backend) build the buttons for selecting between image and individual ranking
		String individualScoreSelected = (individualScores)  ? " selected btn-selected" : "";
		String annotationScoreSelected = (!individualScores) ? " selected btn-selected" : "";
		//String currentUrl = javax.servlet.http.HttpUtils.getRequestURL(request).toString();
		String currentUrl = request.getRequestURL().toString() + "?" + request.getQueryString(); // silly how complicated this is---TODO: ServletUtilities convenience func?
		System.out.println("Current URL = "+currentUrl);
		// linkUrl removes scoreType (which may or may not be present) then adds the opposite of the current scoreType
		String linkUrl = currentUrl;
		linkUrl = linkUrl.replace("&scoreType=image","");
		linkUrl = linkUrl.replace("&scoreType=individual","");
		if (individualScores) linkUrl += "&scoreType=image";
		else linkUrl+="&scoreType=individual";
		String individualScoreLink = (!individualScores) ? linkUrl : "";
		String annotationScoreLink = (individualScores)  ? linkUrl : "";
		// onclick events for each button (do nothing if you're already on the page)
		String individualOnClick = (!individualScores) ? "onclick=\"window.location.href = '"+individualScoreLink+"';\"" : "";
		String annotationOnClick = (individualScores) ?  "onclick=\"window.location.href = '"+annotationScoreLink+"';\"" : "";
		 %>

		<button class="scoreType <%=individualScoreSelected %>" <%=individualOnClick %> >Individual Scores</button>
		<button class="scoreType <%=annotationScoreSelected %>" <%=annotationOnClick %> >Image Scores</button>

		</span>
	</div>	
		<div id="projectDropdownDiv" style="padding: 0px 0px 0px 50px;">
			<span hidden class="control-label" id="projectDropdownSpan">
				<label>Project Selection</label>
				<select name="projectDropdown" id="projectDropdown">
				</select>
			</span> 
		</div>



		<!--TODO fix so that this isn't a form that submits but a link that gets pressed -->
		<!-- need to add javascript to update the link href on  -->
		<div id="scoreNumSettings">
				<span id="scoreNumInput">
					Num Results: <input type="text" name="nResults" id = "nResultsPicker" value=<%=RESMAX%> >
				</span>
				<button class="nResults" onclick="nResultsClicker()">set</button>
		</div>

	</div>
	
	<style>
		div#result_settings, div#projectDropdownDiv {
			
		}
		div#result_settings button:last-child, div#projectDropdownDiv {
			margin-right: 15px 15px 15px 15px;
		}
		div#result_settings span#scoreTypeSettings {
			float: left;
		}
		.enc-title .enc-link, .enc-title .indiv-link {
			margin-left: 0;
		}
		</style>

		<script>
			var nResultsClicker = function() {
				var defaultResults = <%=RESMAX%>;
				var nResults = $("#nResultsPicker").val();
				if (nResults!=defaultResults) {
					var destUrl = "<%=currentUrl%>";
					destUrl = destUrl.replace(/\&nResults=\d*/,""); // remove previoius nResults arg
					destUrl += "&nResults="+nResults;
					window.location.href = destUrl;
				}
			}
		</script>



	<div id="initial-waiter" class="waiting throbbing">
		<p>waiting for results</p>
	</div>


	<div id = "confirm-negative-dialog" style="display: none" title = "Confirm no match?" >
	</div>


</div>



<jsp:include page="footer.jsp" flush="true"/>



<script src="javascript/underscore-min.js"></script>
<script src="javascript/backbone-min.js"></script>

<link rel="stylesheet" href="css/ia.css" type="text/css" />


<style>

.location-based-checkbox {
	margin: 0 15px 0 5px !important;
}
.annot-summary-phantom {
	display: none;
}

.featurebox {
    position: absolute;
    width: 100%;
    height: 100%;
    top: 0;
    left: 0;
    outline: dashed 2px rgba(255,255,0,0.8);
    box-shadow: 0 0 0 2px rgba(0,0,0,0.6);
}

	div.mainContent {
		padding-top: 50px;
	}

	a.button, a.btn {
		background: #005589;
		border: 0;
		color: #fff;
		line-height: 2em;
		padding: 7px 13px;
		font-weight: 300;
		vertical-align: middle;
		margin-right: 10px;
		margin-top: 15px;
	}

	div div#enc-action {
		float: right;
		position: relative;
		top: 5px;
		margin-right: 40px;
	}

	div div li.noImageScoresMessage {
		display: none;
	}

	div div div.imageScores li.noImageScoresMessage {
		display: list-item;
		font-weight: bold;
	}

	ul.advancedAlgoInfo li a {
		text-decoration: underline;
	}


</style>


<script>
var serverTimestamp = <%= System.currentTimeMillis() %>;
var pageStartTimestamp = new Date().getTime();
var taskIds = [];
var tasks = {};
var jobIdMap = {};
var timers = {};

var INDIVIDUAL_SCORES = <%=individualScores%>;

var projectIdPrefix = '<%=projectIdPrefix%>';
var researchProjectName = '<%=researchProjectName%>';
var researchProjectUUID = '<%=researchProjectUUID%>';
var NONE_SELECTED = 'None Selected';
var projectData = {};
var projectACMIds = [];
var projectAnnotIds = [];
var queryAnnotId;
var annotData = {};

function toggleScoreType() {
	INDIVIDUAL_SCORES = !INDIVIDUAL_SCORES;
	$('#encounter-info').remove();
	init2();
}

var headerDefault = 'Select <b>correct match</b> from results below by <i>hovering</i> over result and checking the <i>checkbox</i>.';
// we use the same space as

function init2() {   //called from wildbook.init() when finished
	$('.nav-bar-wrapper').append('<div id="encounter-info"><div class="enc-title" /></div></div>');
	parseTaskIds();
	for (var i = 0 ; i < taskIds.length ; i++) {
		var tid = taskIds[i];
		tryTaskId(tid);
	}

	// If we don't have any ID task elements, it's reasonable to assume we are waiting for something.
	// If we don't have anything but null task types after a while, lets just reload the page and get updated info.
	// We get to this condition when the page loads too fast and you have only __NULL__ type tasks,
	// and no children to traverse.

	// removed below bc it was overwriting the scoreType settings
	//$('.maincontent').html("<div id=\"initial-waiter\" class=\"waiting throbbing\"><p>processing request</p></div>");

	var reloadTimeout = setTimeout(function(){
		var onlyNullTaskType = true;
		for (var i = 0 ; i < taskIds.length ; i++) {
			var processedTask = tasks[tid];
			console.log("Processed Task: "+JSON.stringify(processedTask));
			var type = wildbook.IA.getPluginType(processedTask);
			console.log("TYPE : "+type);
			if ((type!="__NULL__"&&type!=false)||processedTask.children) {
				onlyNullTaskType = false;
				$('#initial-waiter').remove();
			}
		}
		//console.log("-- >> What are the current tasks? : "+JSON.stringify(tasks));
		if (onlyNullTaskType==true) {
			console.log("RELOADING!");
			clearTimeout(reloadTimeout);
			location.reload(true);
		} else {
			clearTimeout(reloadTimeout);
			$('#wait-message-' + tid).html('<%=gaveUpWaitingMsg%>').removeClass('throbbing');;
			console.log("NOT RELOADING!!!!!");
		}
	},100000);
}
$(document).ready(function() { wildbook.init(function() { init2(); }); });
function parseTaskIds() {
	var a = window.location.search.substring(1).split('&');
	for (var i = 0; i < a.length ; i++) {
		if (a[i].indexOf('taskId=') == 0) taskIds.push(a[i].substring(7));
	}
}
function tryTaskId(tid) {
    wildbook.IA.fetchTaskResponse(tid, function(x) {
        if ((x.status == 200) && x.responseJSON && x.responseJSON.success && x.responseJSON.task) {
            processTask(x.responseJSON.task); //this will be json task (w/children)
	    // console.log("TRY TASK RESPONSE!!!!                "+JSON.stringify(x.responseJSON.task));
        } else {
        		// the below alert was erroneously displaying when a tid was just in the queue
            //alert('Error fetching task id=' + tid);
            console.error('tryTaskId(%s) failed: %o', tid, x);
        }
    });
}
function getCachedTask(tid) {
    return tasks[tid];
}
function cacheTaskAndChildren(task) {
    if (!task || !task.id || tasks[task.id]) return;
    tasks[task.id] = task;
    if (!wildbook.IA.hasChildren(task)) return;
    for (var i = 0 ; i < task.children.length ; i++) {
        cacheTaskAndChildren(task.children[i]);
    }
}

function processTask(task) {
    //first we populate tasks hash (for use later via getCachedTask()
    cacheTaskAndChildren(task);

    //now we get the DOM element
    //  note: this recurses, so our "one" element should have nested children element for child task(s)
    wildbook.IA.getDomResult(task, function(t, res) {
        $('.maincontent').append(res);
        grabTaskResultsAll(task);
    });
}



//calls grabTaskResult() on all appropriate nodes in tree
//  note there is no callback -- that is because this ultimately is expecting to put contents in
//  appropriate divs (e.g. id="task-XXXX")
var alreadyGrabbed = {};
function grabTaskResultsAll(task) {
console.info("grabTaskResultsAll %s", task.id);
    if (!task || !task.id || alreadyGrabbed[task.id]) return;
    if (wildbook.IA.needTaskResults(task)) {  //this magic decides "do we even have/need results for this task?"
console.info("grabTaskResultsAll %s TRYING.....", task.id);
        grabTaskResult(task.id);  //ajax, backgrounds
    }
    if (!wildbook.IA.hasChildren(task)) return;
    //now we recurse thru children....
    for (var i = 0 ; i < task.children.length ; i++) {
        grabTaskResultsAll(task.children[i]);
    }
}

function grabTaskResult(tid) {
//	$("#initial-waiter").remove();
        alreadyGrabbed[tid] = true;
	var mostRecent = false;
	var gotResult = false;
//console.warn('------------------- grabTaskResult(%s)', tid);

	let paramStr = 'iaLogs.jsp?taskId=' + tid;
	console.log("do i have a projectId in grabTaskResult()????? "+projectIdPrefix);
	if (projectIdPrefix!=null&&projectIdPrefix.length>0) {
		paramStr += "&projectId="+researchProjectUUID;
	}

	$.ajax({
		url: paramStr,
		type: 'GET',
		dataType: 'json',
		success: function(d) {
		    $('#wait-message-' + tid).remove();  //in case it already exists from previous
console.info('>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> got %o on task.id=%s', d, tid);
                    $('#task-debug-' + tid).append('<br /><b>iaLogs returned:</b>\n\n' + JSON.stringify(d, null, 4));
			for (var i = 0 ; i < d.length ; i++) {
				if (d[i].serviceJobId && (d[i].serviceJobId != '-1')) {
					if (!jobIdMap[tid]) jobIdMap[tid] = { timestamp: d[i].timestamp, jobId: d[i].serviceJobId, manualAttempts: 0 };
				}
				//console.log("d[i].projectData : "+JSON.stringify(d([i].projectData));
				if (d[i].projectData) {
					projectData = d[i].projectData;
					if (d[i].projectACMIds) {
						projectACMIds = d[i].projectACMIds;
					}
					if (d[i].projectAnnotIds) {
						projectAnnotIds = d[i].projectAnnotIds;
					}
				}

				if (d[i].status && d[i].status._action == 'getJobResult') {
					
					showTaskResult(d[i], tid);
					i = d.length;
					gotResult = true;
					//console.log("removing initial waiter!");
					$("#initial-waiter").remove();

				} else {
					if (!mostRecent && d[i].status && d[i].status._action) mostRecent = d[i].status._action;
				}
			}
			if (!gotResult) {
				//console.log("Element length: "+$('#task-' + tid).length+" Element contents: "+document.getElementsByClassName("elementa")[0].innerHTML);
				if ($('#task-' + tid).length) {
					$('#initial-waiter').remove();
				}
				//$('#task-' + tid).append('<p id="wait-message-' + tid + '" title="' + (mostRecent? mostRecent : '[unknown status]') + '" class="waiting throbbing">waiting for results <span onClick="manualCallback(\'' + tid + '\')" style="float: right">*</span></p>');
				$('#task-' + tid).append('<p id="wait-message-' + tid + '" title="' + (mostRecent? mostRecent : '[unknown status]') + '" class="waiting throbbing">waiting for results</p>');
				if (jobIdMap[tid]) {
					var tooLong = 15 * 60 * 1000;
					var elapsed = approxServerTime() - jobIdMap[tid].timestamp;
					//console.warn("elapsed = %.1f min", elapsed / 60000);
					if (elapsed > tooLong) {
						if (timers[tid] && timers[tid].timeout) clearTimeout(timers[tid].timeout);
						$('#wait-message-' + tid).removeClass('throbbing').html('attempting to fetch results');
						manualCallback(tid);
					} else {
						if (!timers[tid]) timers[tid] = { attempts: 0 };
						if (timers[tid].attempts > 1000) {
							if (timers[tid] && timers[tid].timeout) clearTimeout(timers[tid].timeout);
							$('#wait-message-' + tid).html('gave up trying to obtain results').removeClass('throbbing');
						} else {
							timers[tid].attempts++;
							timers[tid].timeout = setTimeout(function() { console.info('ANOTHER %s!', tid); grabTaskResult(tid); }, 1700);
						}
					}
				} else {
                                        var latest = -1;
                                        if (d && d[0] && d[0].timestamp) latest = d[0].timestamp;
                                        var gaveUp = false;
                                        if (latest > 0) {
                                            var age = serverTimeDiff(latest);
console.info('age = %.2fmin', age / (60*1000));
                                            if (age > (12 * 60 * 1000)) {
                                                console.log('giving up on old task latest=%d -> %.2fmin', latest, age / (60*1000));
                                                if (timers && timers[tid] && timers[tid].timeout) clearTimeout(timers[tid].timeout);
                                                timers[tid] = { attempts: 9999999 };
						$('#wait-message-' + tid).html('error initiating IA job').removeClass('throbbing');;
                                                gaveUp = true;
                                            }
                                        }
                                        if (!gaveUp) {
					    if (!timers[tid]) timers[tid] = { attempts: 0 };
					    timers[tid].attempts++;
					    timers[tid].timeout = setTimeout(function() { console.info('ANOTHER %s!', tid); grabTaskResult(tid); }, 1700);
                                        }
				}
			} else {
				if (timers[tid] && timers[tid].timeout) clearTimeout(timers[tid].timeout);
				$('#initial-waiter').remove();
			}
		},
		error: function(a,b,c) {
			console.error(a, b, c);
			$("#initial-waiter").remove();
			$('#task-' + tid).append('<p class="error">there was an error with task ' + tid + '</p>');
		}
	});
}


function approxServerTime() {
	return serverTimestamp + (new Date().getTime() - pageStartTimestamp);
}

//st is a server timestamp (i.e. using its clock, like data fields set on server)
//  this returns millisec different from (approx) server time... basically its age
function serverTimeDiff(st) {
    return approxServerTime() - st;
}

function manualCallback(tid) {
console.warn('manualCallback disabled currently (tid=%s)', tid); return;
	var m = jobIdMap[tid];
	if (!m || !m.jobId) return alert('Could not find jobid for ' + tid);
	if (jobIdMap[tid].manualAttempts > 3) {
		//$('#wait-message-' + tid).html('failed to obtain results').removeClass('throbbing');
		$('#wait-message-' + tid).html('Still waiting on results. Please try again later. IA is most likely ingesting a large amount of data.').removeClass('throbbing');
		return;
	}
	jobIdMap[tid].manualAttempts++;
	$('#wait-message-' + tid).html('<i>attempting to manually query IA</i>').removeClass('throbbing');;
	console.log(m);

	$.ajax({
		url: wildbookGlobals.baseUrl + '/ia?callback&jobid=' + m.jobId,
		type: 'GET',
		dataType: 'json',
		complete: function(x, stat) {
			console.log('status = %o; xhr=%o', stat, x);
/*
			var msg = '<i>unknown results</i>';
			if (x.responseJSON && x.responseJSON.continue) {
				msg = '<b>tried to get results (<i>reload</i> to check)</b>';
			} else if (x.responseJSON && !x.responseJSON.continue) {
				msg = '<b>disallowed getting results (already tried and failed)</b>';
			}
			$('#wait-message-' + tid).html(msg + ' [returned status=<i title="' + x.responseText + '">' + stat + '</i>]');
*/
		}
	});
	$('#wait-message-' + tid).remove();
	grabTaskResult(tid);

	//$('#wait-message-' + tid).html(m.jobId);
	//alert(m.jobId);
}

// basically a static method that displays more in-depth algorithm info e.g. disclaimers for the Deepsense algorithm
function showAdvancedAlgInfo() {

	// Deepsense
	var deepsenseInfoSpan = grabAlgInfoSpan('deepsense');
	var deepsenseMsg = '<br><ul class="advancedAlgoInfo">';
	deepsenseMsg += '<li>The deepsense.ai algorithm for right whale matching works only on individuals in the <a href="http://rwcatalog.neaq.org">North Atlantic Right Whale Catalog</a> operated by the New England Aquarium. This is because it is a pre-trained algorithm that can only identify the whales in its training set.</li>'
	deepsenseMsg += '<li>The matches on this page are preliminary and must be confirmed by the New England Aquarium before they are added to the NARWC.</li>'
	// This noImageScoresMessage is shown/hidden with css using an imageScores class on the task container div
	deepsenseMsg += '<li class="noImageScoresMessage">This algorithm does not return per-image match scores, so only name scores are displayed.</li>'
	deepsenseMsg += '</ul>'
	//console.log("Showing AdvancedAlgInfo for deepsense with message: "+deepsenseMsg+" on object %o", deepsenseInfoSpan);
	deepsenseInfoSpan.html(deepsenseMsg);

}



// this method only works *after* showTaskResult has returned the task data. Returns that div
function grabAlgResultsDiv(algoName) {
	return $('div.task-content.task-type-identification.'+algoName);
}
function grabAlgInfoSpan(algoName) {
	return grabAlgResultsDiv(algoName).find('div.task-title.task-type-identification span.task-title-id span.advancedAlgoInfo');

	// span.advancedAlgoInfo');
}


var RESMAX = <%=RESMAX%>;
function showTaskResult(res, taskId) {
	console.log("RRRRRRRRRRRRRRRRRRRRRRRRRRESULT showTaskResult() %o on %s", res, res.taskId);
	if (res.status && res.status._response && res.status._response.response && res.status._response.response.json_result &&
			res.status._response.response.json_result.cm_dict) {
		var algoInfo = (res.status._response.response.json_result.query_config_dict &&
			res.status._response.response.json_result.query_config_dict.pipeline_root);
		//console.log("Algo info is "+algoInfo);
		var qannotId = res.status._response.response.json_result.query_annot_uuid_list[0]['__UUID__'];
		queryAnnotId = qannotId;  //global context

		//$('#task-' + res.taskId).append('<p>' + JSON.stringify(res.status._response.response.json_result) + '</p>');
		console.warn('json_result --> %o %o', qannotId, res.status._response.response.json_result['cm_dict'][qannotId]);

		//$('#task-' + res.taskId + ' .task-title-id').append(' (' + (isEdgeMatching ? 'edge matching' : 'pattern matching') + ')');
				var algoDesc = 'texture (HotSpotter match results)'; // default display description if no algo info given
                if (algoInfo == 'CurvRankTwoFluke') {
                    algoDesc = 'trailing edge (CurvRank v2)';
                } 
                else if (algoInfo == 'CurvRankTwoDorsal') {
                    algoDesc = 'trailing edge (CurvRank v2)';
                } 
                else if (algoInfo == 'OC_WDTW') {
                    algoDesc = 'trailing edge (OC/WDTW)';
                } 
                else if (algoInfo == 'Deepsense') {
                    algoDesc = 'Deepsense AI\'s Right Whale Matcher';
                } 
                else if (algoInfo == 'CurvRankDorsal') {
                    algoDesc = 'CurvRank dorsal fin trailing edge algorithm';
                } 
                else if (algoInfo == 'Finfindr') {
                    algoDesc = 'finFindR dorsal fin trailing edge algorithm';
                }
                else if (algoInfo == 'Pie') {
                    algoDesc = 'PIE (Pose Invariant Embeddings)';
                }
				else if (algoInfo == 'PieTwo') {
                    algoDesc = 'PIE v2 (Pose Invariant Embeddings)';
                }
                algoDesc = '<span title="' + algoInfo + '">'+algoDesc+'</span>';

console.log('algoDesc %o %s %s', res.status._response.response.json_result.query_config_dict, algoInfo, algoDesc);
		var h = 'Matches based on <b>' + algoDesc + '</b>';
		// I'd like to add an on-hover tooltip explaining the algorithm to users, but am unsure how to read a .properties file from here -Drew
		// h += ' <i class="el el-info-circle"></i>';
		if (res.timestamp) {
			var d = new Date(res.timestamp);
			h += '<span class="algoTimestamp">' + d.toLocaleString() + '</span>';
		}
    var dct = res.status._response.response.json_result.database_annot_uuid_list.length;
    h += ' <span class="matchingSetSize">' + (dct ? '<i>against ' + dct + ' candidates</i>' : '') + '</span>';

    h += '<span class="advancedAlgoInfo"> </span>'

		//h += '<span title="taskId=' + taskId + ' : qannotId=' + qannotId + '" class="algoInstructions">Hover mouse over listings below to <b>compare results</b> to target. Links to <b>encounters</b> and <b>individuals</b> given next to match score.</span>';
		$('#task-' + res.taskId + ' .task-title-id').html(h);
		var json_result = res.status._response.response.json_result;

		// we can store the algo name here bc it's part of the json_result
		var algo_name = json_result['query_config_dict']['pipeline_root'];
		var task_grabber = "#task-"+res.taskId;
		console.log("got algo_name %s, want to put this on div %s", algo_name, task_grabber);
		// now save the algo name on the task div

		if (!<%=individualScores%>) {
			// The noImageScoresMessage is defined in showAdvancedAlgInfo and shown/hidden with css using the imageScores class on the task container div
			console.log("hewwo image scores!");
			$(task_grabber).addClass('imageScores')
		}

		$(task_grabber).data("algorithm", algo_name);

		displayAnnot(res.taskId, qannotId, -1, -1, -1);

		$(task_grabber).data("algorithm", algo_name);
		$(task_grabber).addClass(algo_name)


		var sorted = score_sort(json_result['cm_dict'][qannotId], json_result['query_config_dict']['pipeline_root']);
		if (!sorted || (sorted.length < 1)) {
			//$('#task-' + res.taskId + ' .waiting').remove();  //shouldnt be here (cuz got result)
			//$('#task-' + res.taskId + ' .task-summary').append('<p class="xerror">results list was empty.</p>');
			$('#task-' + res.taskId + ' .task-summary').append('<p class="xerror">Image Analysis has returned and no match was found.</p>');
			return;
		}
		var maxToEvaluate = sorted.length;
		if (maxToEvaluate > RESMAX) maxToEvaluate = RESMAX;

		// ----- BEGIN Hotspotter IA Illustration: here we construct the illustration link URLs for each dannot -----
		// these URLs are passed-along and rendered in html by displayAnnotDetails
		var resJSON = res.status._response.response.json_result['cm_dict'][qannotId];
		// names conforming to IA args
		var extern_reference = resJSON.dannot_extern_reference;
		var query_annot_uuid = qannotId;
		var version = "heatmask";
		console.log("maxToEvaluate: "+maxToEvaluate);

		for (var i = 0 ; i < maxToEvaluate; i++) {

			
			var d = sorted[i].split(/\s/);
			if (!d) break;
			
			
			var annotId = d[1];
			
			var database_annot_uuid = d[1];
			var has_illustration = d[2];

			//console.log("in annot loop, i="+i+" maxToEvaluate="+maxToEvaluate+" this acmId: "+annotId);

			let isSelected = isProjectSelected();
			let validEnc = true;

			if (isSelected) {
				validEnc = projectACMIds.includes(annotId);
			}

			if ((isSelected&&validEnc)||!isSelected) {

				//console.log("has_illustration = "+has_illustration);

				var illustUrl;
				if (has_illustration) {
					illustUrl = "api/query/graph/match/thumb/?extern_reference="+extern_reference;
					illustUrl += "&query_annot_uuid="+query_annot_uuid;
					illustUrl += "&database_annot_uuid="+database_annot_uuid;
					illustUrl += "&version="+version;
				} else {
					illustUrl = false;
				}
				
				var adjustedScore = d[0];
				displayAnnot(res.taskId, d[1], i, adjustedScore, illustUrl);
				// ----- END Hotspotter IA Illustration-----
			} else {
				// we have skipped an annotation here due to it not being present in a project. let another through to make max possible
				if (maxToEvaluate<sorted.length) {
					maxToEvaluate++;
				}
			}

		}
		$('.annot-summary').on('mousemove', function(ev) { 
			//console.log('mouseover2 with num viewers: '+viewers.size);
			annotClick(ev); 
			var m_acmId = ev.currentTarget.getAttribute('data-acmid');
			var taskId = $(ev.currentTarget).closest('.task-content').attr('id').substring(5);
			//tell seadragon to pan to the annotation
			if(viewers.has(taskId+"+"+m_acmId )){
				//console.log("Found viewer: "+taskId+"+"+m_acmId );
				var viewer=viewers.get(taskId+"+"+m_acmId );
				var eventArgs={
					acmId: m_acmId,
					taskId: taskId
				};
				viewer.raiseEvent("switchAnnots", eventArgs);
			}
		});
		$('#task-' + res.taskId + ' .annot-wrapper-dict:first').show();

		// Add disclaimers and other alg-specific info
		showAdvancedAlgInfo();

	} else {
		$('#task-' + res.taskId).append('<p class="error">there was an error parsing results for task ' + res.taskId + '</p>');
	}
}

// Fix the acmId ---> annotID situation here.

function displayAnnot(taskId, acmId, num, score, illustrationUrl) {
console.info('%d ===> %s', num, acmId);
	let dataInd = parseInt(num) + 1;
	var h = '<div data-index="' + dataInd + '" data-acmid="' + acmId + '" class="has-data-index annot-summary annot-summary-' + acmId + '">';
	h += '<div class="annot-info"><span class="annot-info-num"></span> <b>' + score.toString().substring(0,6) + '</b></div></div>';
	var perCol = Math.ceil(RESMAX / 3);
	if (num >= 0) $('#task-' + taskId + ' .task-summary .col' + Math.floor(num / perCol)).append(h);


	//now the image guts
	h = '<div id="'+taskId+'+'+acmId+'" title="acmId=' + acmId + '"  class="annot-wrapper annot-wrapper-' + ((num < 0) ? 'query' : 'dict') + ' annot-' + acmId + '">';
	//h += '<div class="annot-info">' + (num + 1) + ': <b>' + score + '</b></div></div>';

	let paramString = 'iaResults.jsp?acmId=' + acmId;
	let projectId = getSelectedProjectIdPrefix();
	if (projectId!=""&&projectId!=undefined) {
		paramString += "&projectIdPrefix="+projectId;
	}
	
	
	var imgs = $('#task-' + taskId + ' .bonus-wrapper');
    if (!imgs.length) {
            imgs = $('<div style="height: 400px;" class="bonus-wrapper" />');
            imgs.appendTo('#task-' + taskId)
     }
     imgs.append(h);
	
	console.log("PARAMSTRING: "+paramString);
	
	$.ajax({
		url: paramString,  //hacktacular!
		type: 'GET',
		dataType: 'json',
		complete: function(d) {
			displayAnnotDetails(taskId, d, num, illustrationUrl, acmId);
		}
	});
}

function displayAnnotDetails(taskId, res, num, illustrationUrl, acmIdPassed) {
	var isQueryAnnot = (num < 0);
	if (!res || !res.responseJSON || !res.responseJSON.success || res.responseJSON.error || !res.responseJSON.annotations || !tasks[taskId] || !tasks[taskId].annotationIds) {
		console.warn('error on (task %s, acmId=%s) res = %o', taskId, acmIdPassed, res);
                $('#task-' + taskId + ' .annot-summary-' + acmIdPassed).addClass('annot-summary-phantom');
                return;
	}
        /*
            we may have gotten more than one annot back from the acmId, so we have to account for them all.  currently we handle
            this as follows:
            (a) if it is the query annot, we *should* be able to find the id of the annot by looking at task.annotationIds.
            (b) if we cannot, or if target/dict annots, then we collect data about *all* possibly annots and show that
        */

	//var encId = false;
	//var indivId = false;
	var imgInfo = '';
        var mainAnnId = false; //this is basically to set as data('annid') on our div (cuz we need one?)
        var mainAsset = false;
        var otherAnnots = [];
        var h = 'Matching results';
		var acmId;
		var incrementalProjectId;
		var projectUUID;

        for (var i = 0 ; i < res.responseJSON.annotations.length ; i++) {
            acmId = res.responseJSON.annotations[i].acmId;  //should be same for all, so lets just set it
		annotData[acmId] = res.responseJSON.annotations;
            console.info('[%d/%d] annot id=%s, acmId=%s', i, res.responseJSON.annotations.length, res.responseJSON.annotations[i].id, res.responseJSON.annotations[i].acmId);
            if (tasks[taskId].annotationIds.indexOf(res.responseJSON.annotations[i].id) >= 0) {  //got it (usually query annot)
                //console.info(' -- looks like we got a hit on %s', res.responseJSON.annotations[i].id);
                mainAnnId = res.responseJSON.annotations[i].id;
			}
			if (res.responseJSON.annotations[i].incrementalProjectId&&res.responseJSON.annotations[i].incrementalProjectId.length>0) {
				incrementalProjectId = res.responseJSON.annotations[i].incrementalProjectId;
				console.log("Got this incrementalProjectId in displayAnnotDetails() : "+incrementalProjectId);
			}
			if (res.responseJSON.annotations[i].projectUUID&&res.responseJSON.annotations[i].projectUUID.length>0) {
				projectUUID = res.responseJSON.annotations[i].projectUUID;
				console.log("Got this projectId in displayAnnotDetails() : "+incrementalProjectId);
			}
			//we "should" only need the first asset we find -- as they "should" all be identical!

            if (!res.responseJSON.annotations[i].asset) continue;  //no asset, meh continue
            if (mainAsset) {
                otherAnnots.push(res.responseJSON.annotations[i]);
            } else {
                mainAsset = res.responseJSON.annotations[i].asset;
				$('#initial-waiter').remove();
            }
        }
        if (mainAnnId) $('#task-' + taskId + ' .annot-summary-' + acmId).data('annid', mainAnnId);  //TODO what if this fails?
        if (mainAsset) {
//console.info('mainAsset -> %o', mainAsset);
//console.info('illustrationUrl '+illustrationUrl);
            var ft = findMyFeature(acmId, mainAsset);
            if (mainAsset.url) {
            	//console.log(mainAsset.url);
                
            	var img = $('<img src="' + mainAsset.url + '" />');
                //var imgLink=$('<a target="_blank" href="' + mainAsset.url + '" />');
                //imgLink.append(img);
            	
                ft.metadata = mainAsset.metadata;
                img.on('load', function(ev) { imageLoaded(ev.target, ft, mainAsset); });
                //$('#task-' + taskId + ' .annot-' + acmId).append(imgLink);
                

     
                
              		var viewer=OpenSeadragon({
                    	id: taskId+"+"+acmId,
                        tileSources: {
                            type: 'image',
                            url:  mainAsset.url,
                            buildPyramid: false,
                        },
                        showHomeControl: false,
                    	prefixUrl: 'javascript/openseadragon/images/',
                    	navigationControlAnchor: OpenSeadragon.ControlAnchor.TOP_RIGHT,
                    	visibilityRatio: 1.0,
                        constrainDuringPan: true,
                        animationTime: 0,

                	});
                	
              		//viewer.world.setAutoRefigureSizes(true);
              		
                	viewer.addHandler('open', function() {
                		var ft = features.get(viewer.id.split('+')[1]);
                		//console.log(ft);
                		var marginFactor=1;
                		var width=ft.parameters.width;
                	   	var height=ft.parameters.height;
                	   	
                	   	var scale = ft.metadata.height / viewer.world.getItemAt(0).getContentSize().y;
                        if (ft.metadata && ft.metadata.height) scale = viewer.world.getItemAt(0).getContentSize().y / ft.metadata.height;
                        var rec=viewer.world.getItemAt(0).imageToViewportRectangle(ft.parameters.x*marginFactor*scale, ft.parameters.y*marginFactor*scale, width/marginFactor*scale, height/marginFactor*scale);
                	   	viewer.viewport.fitBounds(rec);
                        var elt = document.createElement("div");
                        elt.id = "overlay-"+acmId+"-"+viewer.id;
                        elt.className = "seadragon-highlight";
                       
                        
                        viewer.addOverlay({
                            element: elt,
                            checkResize: true,
                            location: viewer.world.getItemAt(0).imageToViewportRectangle(ft.parameters.x*scale, ft.parameters.y*scale, ft.parameters.width*scale, ft.parameters.height*scale)
                        });
                	
                	});
    
                	viewer.addHandler('full-screen', event => {
                		if(event.fullPage==false){
                			var eventArgs={
								acmId: viewer.id.split('+')[1]
							};
                	    	//console.log("Trying to call switchAnnots on amId: "+);
                	    	viewer.raiseEvent("switchAnnots", eventArgs);
                	    	
                	    }
                	});
                	
                	viewer.addHandler('switchAnnots', event => {
                		//console.log("switch annots with acmId: "+event.acmId);
                		
                		var marginFactor=1.0;
                		
                		//need to get annot feature
                		var ft = features.get(viewer.id.split('+')[1]);
                		//console.log("switch annots with acmId: "+event.acmId+"("+ft.parameters.width+","+ft.parameters.height+","+ft.parameters.x+","+ft.parameters.y+")");
                		var width=ft.parameters.width;
                	   	var height=ft.parameters.height;
                	   	var scale = ft.metadata.height / viewer.world.getItemAt(0).getContentSize().y;
                        if (ft.metadata && ft.metadata.height) scale = viewer.world.getItemAt(0).getContentSize().y / ft.metadata.height;
                        var rec=viewer.world.getItemAt(0).imageToViewportRectangle(ft.parameters.x*marginFactor*scale, ft.parameters.y*marginFactor*scale, width/marginFactor*scale, height/marginFactor*scale);
                	   	viewer.viewport.fitBounds(rec);
                	});
                	

                	
                	//add this viewer to the global Map
                	viewers.set(taskId+"+"+acmId,viewer);
                	features.set(acmId, ft);
            	
            	
            	$('#task-' + taskId + ' .annot-' + acmId).addClass("seadragon");
                
                
            } else {
                $('#task-' + taskId + ' .annot-' + acmId).append('<img src="images/no_images.jpg" style="padding: 5px" />');
            }
            if (mainAsset.dateTime) {
                imgInfo += ' <b>' + mainAsset.dateTime.substring(0,16) + '</b> ';
            }
            if (mainAsset.filename) {
                var fn = mainAsset.filename;
                var j = fn.lastIndexOf('/');
                if (j > -1) fn = fn.substring(j + 1);
                imgInfo += ' ' + fn + ' ';
            }
            if (ft) {
                var encId = ft.encounterId;

                var encDisplay = encId;
                var taxonomy = ft.genus+' '+ft.specificEpithet;
                //console.log('Taxonomy: '+taxonomy);
                if (encId.trim().length == 36) encDisplay = encId.substring(0,6)+"...";
				var indivId = ft.individualId;
				
				//console.log(" ----------------------> CHECKBOX FEATURE: "+JSON.stringify(ft));
                var displayName = ft.displayName;
                if (isQueryAnnot) addNegativeButton(encId, displayName);
				
				// if the displayName isn't there, we didn't get it from the queryAnnot. Lets get it from one of the encs on the results list.
				if (typeof displayName == 'undefined' || displayName == "" || displayName == null) {
					//console.log("Did you get in the display name finder block??? Ye!");
					displayName = $('.enc-title .indiv-link').text();
				}

				console.log("indivId: "+indivId+" projectIdPrefix: "+projectIdPrefix+" incrementalProjectId: "+incrementalProjectId+" displayName: "+displayName);

				let thisResultLine = $('#task-'+taskId+' .annot-summary-'+acmId);

                if (encId) {

					thisResultLine.prop('title', 'From Encounter: '+encId);

					// make whole encounter line clickable
					thisResultLine.click(function(event) {
						let tar = $(event.target);
						if (tar.is(thisResultLine)||tar.is(thisResultLine.find('.annot-info-num')[0])||tar.is(thisResultLine.find('.annot-info')[0])) {
							window.location.href = 'encounters/encounter.jsp?number='+encId;
						}
					});

					//console.log("Main asset encId = "+encId);
                    h += ' for <a  class="enc-link" target="_new" href="encounters/encounter.jsp?number=' + encId + '" title="open encounter ' + encId + '">Encounter: '+encDisplay+'</a>';
                    //thisResultLine.append('<a class="enc-link" target="_new" href="encounters/encounter.jsp?number=' + encId + '" title="encounter ' + encId + '">Encounter LINE APPEND</a>');
                    
					if (!indivId) {
						thisResultLine.append('<span class="indiv-link-target" id="encnum'+encId+'"></span>');			
					}
				}
				
				if (isProjectSelected()) {
					console.log("trying to show project-based id for asset...(UUID: "+projectUUID+" )");
					h += ' in <a class="project-link" target="_new" href="/projects/project.jsp?id=<%=researchProjectUUID%>" title="Open Project '+researchProjectName+'">Project: ' + researchProjectName.substring(0,15) + '</a>';

					if (incrementalProjectId) {
						thisResultLine.append('<a class="indiv-link" target="_new" href="/projects/project.jsp?id='+projectUUID+'" title="Project Id: '+incrementalProjectId+'">' + incrementalProjectId.substring(0,15) + '</a>');
					}
				}
				
				if (taxonomy && taxonomy!='Eubalaena glacialis' && indivId && (incrementalProjectId!=displayName)) {
                    h += ' of <a class="indiv-link" title="open individual page" target="_new" href="individuals.jsp?number=' + indivId + '"  title="'+displayName+'">' + displayName + '</a>';
                    thisResultLine.append('<a class="indiv-link" target="_new" href="individuals.jsp?number=' + indivId + '" title="'+displayName+'">' + displayName.substring(0,15) + '</a>');
                }
                if (taxonomy && taxonomy=='Eubalaena glacialis') {
                    //h += ' <a class="indiv-link" title="open individual page" target="_new" href="http://rwcatalog.neaq.org/#/whales/' + displayName + '">'+displayName+' of NARW Cat.</a>';
                    thisResultLine.append('<a class="indiv-link" target="_new" href="http://rwcatalog.neaq.org/#/whales/' + displayName + '">Catalog #'+displayName+'</a>');
                }
				<%
				if(request.getUserPrincipal()!=null){
				%>
                if (encId || indivId) {
					thisResultLine.append('<input title="use this encounter" type="checkbox" class="annot-action-checkbox-inactive" id="annot-action-checkbox-' + mainAnnId +'" data-displayname="'+displayName+'" data-encid="' + (encId || '')+ '" data-individ="' + (indivId || '') + '" onClick="return annotCheckbox(this);" />');
                }
                <%
            	}
                %>
                h += '<div id="enc-action">' + headerDefault + '</div>';
                if (isQueryAnnot) {
                    if (h) $('#encounter-info .enc-title').html(h);
                    if (taxonomy && taxonomy!='Eubalaena glacialis' && imgInfo) imgInfo = '<span class="img-info-type">TARGET</span> ' + imgInfo;
                    var qdata = {
                        annotId: mainAnnId,
                        encId: encId,
                        indivId: indivId,
                        displayName: displayName
                    }
console.info('qdata[%s] = %o', taskId, qdata);
                        $('#task-' + taskId).data(qdata);
                } 
                else {
                    if (taxonomy && taxonomy!='Eubalaena glacialis' && imgInfo) imgInfo = '<span class="img-info-type"></span> ' + imgInfo;
                }
            }  //end if (ft) ....
            // Illustration
            if (illustrationUrl) {
            	var selector = '#task-' + taskId + ' .annot-summary-' + acmId;
            	// TODO: generify
            	var iaBase = wildbookGlobals.iaStatus.map.iaURL;
            	illustrationUrl = iaBase+illustrationUrl
				let resultIndex = $(selector).closest(".has-data-index").data("index");
				if(resultIndex <= <%=CommonConfiguration.getNumIaResultsUserCanInspect(context)%>){
					var illustrationHtml = '<span class="illustrationLink" style="float:right;"><a href="'+illustrationUrl+'" target="_blank">inspect</a></span>';
					//console.log("trying to attach illustrationHtml "+illustrationHtml+" with selector "+selector);
					$(selector).append(illustrationHtml);
				}
            }

        }  //end if (mainAsset)

    if (otherAnnots.length > 0) {
        imgInfo += '<div><i>Alternate references:</i><ul>';
        for (var i = 0 ; i < otherAnnots.length ; i++) {
            imgInfo += '<li title="Annot ' + otherAnnots[i].id + '"><b>Annot ' + otherAnnots[i].id.substring(0,12) + '</b>';
            var ft = findMyFeature(acmId, otherAnnots[i].asset);  //TODO is acmId correct here???
            if (ft) {
                var encId = ft.encounterId;
                var indivId = ft.individualId;
                var displayName = ft.displayName;
                if (encId) {
                	imgInfo += ' <a xstyle="margin-top: -6px;" class="enc-link" target="_new" href="encounters/encounter.jsp?number=' + encId + '" title="open encounter ' + encId + '">Enc ' + encId.substring(0,6) + '</a>';
                	console.log("another encId = "+encId);
                }
                if (indivId) imgInfo += ' <a class="indiv-link" title="open individual page" target="_new" href="individuals.jsp?number=' + indivId + '">' + displayName + '</a>';
            }
            imgInfo += '</li>';
        }
        imgInfo += '</ul></div>';
    }

    if (taxonomy && taxonomy!='Eubalaena glacialis' && imgInfo) $('#task-' + taskId + ' .annot-' + acmId).append('<div class="img-info">' + imgInfo + '</div>');
}

function getSelectedProjectIdPrefix() {
	let selectedValue = $("#projectDropdown option:selected").val();
	if (selectedValue==""||selectedValue==undefined||selectedValue==null||selectedValue=="null") return ""; 
	return selectedValue;
}

function annotCheckbox(el) {
	var jel = $(el);
	var taskId = jel.closest('.task-content').attr('id').substring(5);
    var task = getCachedTask(taskId);
    var queryAnnotation = jel.closest('.task-content').data();
    console.info('annotCheckbox taskId %s => %o .... queryAnnotation => %o', taskId, task, queryAnnotation);
	annotCheckboxReset();
  	if (!taskId || !task) return;
	if (!el.checked) return;
	jel.removeClass('annot-action-checkbox-inactive').addClass('annot-action-checkbox-active');
	jel.parent().addClass('annot-summary-checked');


	let selectedProjectIdPrefix = getSelectedProjectIdPrefix();
	if (selectedProjectIdPrefix==NONE_SELECTED) selectedProjectIdPrefix = '';
	let allowSyncReturn = true;

	var h = '<i>Getting next ID...</i>';
	if (!queryAnnotation.encId || !jel.data('encid')) {
		h = '<i>Insufficient encounter data for any actions</i>';
	} else if (jel.data('individ')==queryAnnotation.indivId) {
		h = 'The target and candidate are already assigned to the <b>same individual ID</b>. No further action is needed to confirm this match.'
	} else if (jel.data('individ') && queryAnnotation.indivId) {
		// construct link to merge page
		var link = "merge.jsp?individualA="+jel.data('individ')+"&individualB="+queryAnnotation.indivId;
		h = 'These encounters are already assigned to two <b>different individuals</b>.  <a href="'+link+'" class="button" > Merge Individuals</a>';
	} else if (selectedProjectIdPrefix.length>0&&!jel.data('individ')&&!queryAnnotation.indivId) {
		allowSyncReturn = false;
		let requestJSON = {};
		requestJSON['projectIdPrefix'] = selectedProjectIdPrefix;
		requestJSON['action'] = 'getNextIdForProject'; 
		$.ajax({
			url: wildbookGlobals.baseUrl + '../ProjectGet',
			type: 'POST',
			data: JSON.stringify(requestJSON),
			dataType: 'json',
			contentType: 'application/json',
			success: function(d) {
				console.info('Retrieved next incremental ID for '+selectedProjectIdPrefix+'! Got back '+JSON.stringify(d));
				let nextId = d.nextId;
				if (!nextId) {
					nextId = '';
				}
				
				h  = '<input id="autocomplete-individual-name" class="needs-autocomplete" xonChange="approveNewIndividual(this);" size="20" value="'+nextId+'" placeholder="Type new or existing name" ';
				h += ' data-query-enc-id="' + queryAnnotation.encId + '" ';
				h += ' data-match-enc-id="' + jel.data('encid') + '" ';
				h += '/>'; 
				h += '<input type="button" value="New Project ID For Both Encounters" data-projectId="'+selectedProjectIdPrefix+'" onClick="approveNewIndividual($(this.parentElement).find(\'.needs-autocomplete\')[0])" />' 

				$('#enc-action').html(h);

				setIndivAutocomplete($('#enc-action .needs-autocomplete'));
				return true;
			},
			error: function(x,y,z) {
				console.warn('%o %o %o', x, y, z);
			}
		});

	} else if (jel.data('individ')) {
		h = '<b>Confirm</b> action: &nbsp; <input onClick="approvalButtonClick(\'' + queryAnnotation.encId + '\', \'' + jel.data('individ') + '\', \'' +jel.data('encid')+ '\' , \'' + taskId + '\' , \'' + jel.data('displayname') + '\');" type="button" value="Set to individual ' +jel.data('displayname')+ '" />';
	} else if (queryAnnotation.indivId) {
		h = '<b>Confirm</b> action: &nbsp; <input onClick="approvalButtonClick(\'' + jel.data('encid') + '\', \'' + queryAnnotation.indivId + '\', \'' +queryAnnotation.encId+ '\' , \'' + taskId + '\' , \'' + jel.data('displayname') + '\');" type="button" value="Use individual ' +jel.data('displayname')+ ' for unnamed match below" />';
	} else {
		h = '';
		if (annotData[queryAnnotId] && annotData[queryAnnotId][0] && annotData[queryAnnotId][0].encounterLocationId) h += '<label for="lbcheckbox" title="' + annotData[queryAnnotId][0].encounterLocationId + '">Use next name based on location</label><input type="checkbox" class="location-based-checkbox" onClick="return locationBasedCheckbox(this, \'' + queryAnnotId + '\');" />';
		h += '<input id="new-name-input" class="needs-autocomplete" xonChange="approveNewIndividual(this);" size="20" placeholder="Type new or existing name" ';
		h += ' data-query-enc-id="' + queryAnnotation.encId + '" ';
		h += ' data-match-enc-id="' + jel.data('encid') + '" ';
		h += ' data-match-task-id="' + taskId + '" ';
		h += ' data-match-display-name="' + jel.data('displayname') + '" ';
		h += ' /> <input type="button" value="Set individual on both encounters" onClick="approveNewIndividual($(this.parentElement).find(\'.needs-autocomplete\')[0])" />';
	}

	if (allowSyncReturn) {
		$('#enc-action').html(h);
		setIndivAutocomplete($('#enc-action .needs-autocomplete'));
		return true;
	}
}

function locationBasedCheckbox(el, qann) {
	if (!el.checked) {  //reset
		$('#new-name-input').attr('placeholder', $('#new-name-input').data('placeholder-orig')).removeAttr('disabled');
		return true;
	}
	let loc = qann && annotData[qann] && annotData[qann][0] && annotData[qann][0].encounterLocationId
	if (!loc) return;
	$('#new-name-input').data('placeholder-orig', $('#new-name-input').attr('placeholder'));
	$('#new-name-input').attr('placeholder', annotData[qann][0].encounterLocationNextValue).attr('disabled', 'disabled');
}

var nameUUIDCache = {};
function setIndivAutocomplete(el) {
	if (!el || !el.length) return;
    var args = {
		resMap: function(data) {
			var res = $.map(data, function(item) {
				if (item.type != 'individual') return null;
                let label = item.label;
				let justName = label;
				if (item.species) label += '   ( ' + item.species + ' )';
				nameUUIDCache[justName] = item.value;
				return { label: label, type: item.type, value: justName, id: item.value };
            });
            return res;
        }
    };
    wildbook.makeAutocomplete(el[0], args);
}

function annotCheckboxReset() {
	$('.annot-action-checkbox-active').removeClass('annot-action-checkbox-active').addClass('annot-action-checkbox-inactive').prop('checked', false);
	$('.annot-summary-checked').removeClass('annot-summary-checked');
	$('#enc-action').html(headerDefault);
}

function annotClick(ev) {
	//console.log(ev);
	var acmId = ev.currentTarget.getAttribute('data-acmid');
	var taskId = $(ev.currentTarget).closest('.task-content').attr('id').substring(5);
	//console.warn('%o | %o', taskId, acmId);
	$('#task-' + taskId + ' .annot-wrapper-dict').hide();
	$('#task-' + taskId + ' .annot-' + acmId).show();
	$('#task-' + taskId + ' .annot-' + acmId + ' img').trigger('load');
}

// function score_sort(cm_dict, topn) {
// console.warn('score_sort() cm_dict %o', cm_dict);
// //.score_list vs .annot_score_list ??? TODO are these the same? seem to be same values
// 	if (!cm_dict.score_list || !cm_dict.dannot_uuid_list) return;
// 	var sorta = [];
// 	if (cm_dict.score_list.length < 1) return;
// 	//for (var i = 0 ; i < cm_dict.score_list.length ; i++) {
// 	for (var i = 0 ; i < cm_dict.score_list.length ; i++) {
// 		if (cm_dict.score_list[i] < 0) continue;
// 		sorta.push(cm_dict.score_list[i] + ' ' + cm_dict.dannot_uuid_list[i]['__UUID__']);
// 	}
// 	sorta.sort().reverse();
// 	return sorta;
// }

function algHasNoImageScores(algo_name) {
	return ("Deepsense" == algo_name);
}


function score_sort(cm_dict, algo_name) {
console.warn('score_sort() cm_dict %o and algo_name %s', cm_dict, algo_name);
//.score_list vs .annot_score_list ??? TODO are these the same? seem to be same values
	if (!cm_dict.annot_score_list || !cm_dict.dannot_uuid_list) return;
	var sorta = [];

	// score_list could be either individual-scores or annotation-scores depending on the individualScores boolean global var
	var score_list = {};
	// to generalize this we can just make a list or func for algHasNoImageScores
	var noImageScores = algHasNoImageScores(algo_name);
	console.warn('score_sort() algHasNoImageScores ' + noImageScores);
	if (INDIVIDUAL_SCORES || noImageScores) {
		score_list = cm_dict.score_list;
	}
	else score_list = cm_dict.annot_score_list;

	// this tells us which annotations have illustratsions
	dannot_extern_list = cm_dict.dannot_extern_list

	if (!INDIVIDUAL_SCORES && noImageScores) {
		// display a message to the user that image scores are disabled for this alg
		var message = "The "+algo_name+" algorithm does not return per-image match scores, so only name scores are displayed."
		console.log("score_sort omitting image scores with message \"%s\"", message)
		// to display this message: talk to Jon about where we should inject the algo_name into html
	}

	if (score_list.length < 1) return;
	//for (var i = 0 ; i < cm_dict.score_list.length ; i++) {
	for (var i = 0 ; i < score_list.length ; i++) {
		if (score_list[i] < 0) continue;
		sorta.push(score_list[i] + ' ' + cm_dict.dannot_uuid_list[i]['__UUID__'] + ' ' + dannot_extern_list[i]);
	}
	sorta.sort(function(a,b) { return parseFloat(a) - parseFloat(b); }).reverse();
	return sorta;
}

function findMyFeature(annotAcmId, asset) {
//console.info('findMyFeature() wanting annotAcmId %s from features %o', annotAcmId, asset.features);
    if (!asset || !Array.isArray(asset.features) || (asset.features.length < 1)) return;
    for (var i = 0 ; i < asset.features.length ; i++) {
        if (asset.features[i].annotationAcmId == annotAcmId) return asset.features[i];
    }
    return;
}

function imageLoaded(imgEl, ft, asset) {
    if (imgEl.getAttribute('data-feature-drawn')) return;
    drawFeature(imgEl, ft, asset);
}

function drawFeature(imgEl, ft, asset) {
    if (!imgEl || !imgEl.clientHeight || !ft || !ft.parameters || (ft.type != 'org.ecocean.boundingBox')) return;
    var scale = imgEl.height / imgEl.naturalHeight;
    if (ft.metadata && ft.metadata.height) scale = imgEl.height / ft.metadata.height;
    if (asset.rotation && ft.metadata && ft.metadata.width) scale = imgEl.height / ft.metadata.width;
    var zoomFactor = imgEl.naturalHeight/ft.parameters.height;

    var f = $('<div title="' + ft.id + '" id="feature-' + ft.id + '" class="featurebox" />');
    
    
    /* values are from-top, from-right, from-bottom, from-left */
    
    //imgEl.setAttribute("style", "transform-origin: 0 0;transform: scale("+zoomFactor+");margin-left: -"+ft.parameters.x*scale*zoomFactor+";margin-top: -"+ft.parameters.y*scale*zoomFactor+"px;position: absolute;clip-path: inset("+ (ft.parameters.y)*scale + "px " + (ft.metadata.width-ft.parameters.x-ft.parameters.width)*scale + "px "+(ft.metadata.height-ft.parameters.height-ft.parameters.y)*scale + "px "+ft.parameters.x*scale + "px )");
   
    
    
    //imgEl.css("transform-origin", "0 0");
    //imgEl.css("transform", "translate(-100%, 50%) rotate(45deg) translate(100%, -50%)");
    
    
//console.info('mmmm scale=%f (ht=%d/%d)', scale, imgEl.height, imgEl.naturalHeight);
    //if (scale == 1) return;
    imgEl.setAttribute('data-feature-drawn', true);
    //f.css('width', (ft.parameters.width * scale) + 'px');
    //f.css('height', (ft.parameters.height * scale) + 'px');
    //f.css('left', (ft.parameters.x * scale) + 'px');
    //f.css('top', (ft.parameters.y * scale) + 'px');
    //if (ft.parameters.theta) $('#overlay-'+acmId).css('transform', 'rotate(' +  ft.parameters.theta + 'rad)');
//console.info('mmmm %o', f);
    //$(imgEl).parent().append(f);
}

function checkForResults() {
	jQuery.ajax({
		url: 'ia?getJobResultFromTaskID=' + taskId,
		success: function(d) {
			console.info(d);
			processResults(d);
		},
		error: function() {
			alert('error fetching results');
		},
		dataType: 'json'
	});
}

var countdown = 100;
function processResults(res) {
	if (!res || !res.queryAnnotation) {
console.info('waiting to try again...');
		$('#results').html('Waiting for results. You may leave this page.  [countdown=' + countdown + ']');
		countdown--;
		if (countdown < 0) {
			$('#results').html('Gave up waiting for results, sorry.  Reload to wait longer.');
			return;
		}
		setTimeout(function() { checkForResults(); }, 3000);
		return;
	}
	if (res.queryAnnotation.encounter && res.queryAnnotation.mediaAsset) {
		jQuery('#image-main').html('');
		addImage(fakeEncounter(res.queryAnnotation.encounter, res.queryAnnotation.mediaAsset),
			 jQuery('#image-main'));
	}
	if (!res.matchAnnotations || (res.matchAnnotations.length < 1)) {
		jQuery('#image-compare').html('<img style="width: 225px; margin: 20px 30%;" src="images/image-not-found.jpg" />');
		$('#results').html('No matches found.');
		return;
	}
	if (res.matchAnnotations.length == 1) {
		var altIDString = res.matchAnnotations[0].encounter.otherCatalogNumbers || '';
		if (altIDString && altIDString.length > 0) {
      			altIDString = ', altID '+altIDString;
    		}

		$('#results').html('One match found (<a target="_new" href="encounters/encounter.jsp?number=' +
			res.matchAnnotations[0].encounter.catalogNumber +
			'">' + res.matchAnnotations[0].encounter.catalogNumber +
			'</a> id ' + (res.matchAnnotations[0].encounter.individualID || 'unknown') + altIDString +
			') - score ' + res.matchAnnotations[0].score + approvalButtons(res.queryAnnotation, res.matchAnnotations));
		updateMatch(res.matchAnnotations[0]);
		return;
	}
	// more than one match
	res.matchAnnotations.sort(function(a,b) {
		if (!a.score || !b.score) return 0;
		return b.score - a.score;
	});
	updateMatch(res.matchAnnotations[0]);
	var h = '<p><b>' + res.matchAnnotations.length + ' matches</b></p><ul>';
	for (var i = 0 ; i < res.matchAnnotations.length ; i++) {
      // a little handling of the alternate ID
      var altIDString = res.matchAnnotations[i].encounter.otherCatalogNumbers || '';
	if (altIDString && altIDString.length > 0) {
		altIDString = ' (altID: '+altIDString+')';
	}
		h += '<li data-i="' + i + '"><a target="_new" href="encounters/encounter.jsp?number=' +
			res.matchAnnotations[i].encounter.catalogNumber + '">' +
			res.matchAnnotations[i].encounter.catalogNumber + altIDString + '</a> (' +
			(res.matchAnnotations[i].encounter.individualID || 'unidentified') + '), score = ' +
			res.matchAnnotations[i].score + '</li>';
	}
	h += '</ul><div>' + approvalButtons(res.queryAnnotation, res.matchAnnotations) + '</div>';

	$('#results').html(h);
	$('#results li').on('mouseover', function(ev) {
		var i = ev.currentTarget.getAttribute('data-i');
		updateMatch(res.matchAnnotations[i]);
		console.log("mouseover3");
	});
}

function updateMatch(m) {
		jQuery('#image-compare').html('');
		addImage(fakeEncounter(m.encounter, m.mediaAsset),jQuery('#image-compare'));
}

function fakeEncounter(e, ma) {
	var enc = new wildbook.Model.Encounter(e);
	enc.set('annotations', [{mediaAsset: ma}]);
	return enc;
}


/////// these are disabled now, as matching results "bar" handles actions
function approvalButtons(qann, manns) {
	return '';
	if (!manns || (manns.length < 1) || !qann || !qann.encounter) return '';
console.info(qann);
	var inds = [];
	for (var i = 0 ; i < manns.length ; i++) {
		if (!manns[i].encounter || !manns[i].encounter.individualID) continue;
		if (inds.indexOf(manns[i].encounter.individualID) > -1) continue;
		if (manns[i].encounter.individualID == qann.encounter.individualID) continue;
		inds.push(manns[i].encounter.individualID);
	}
console.warn(inds);
	if (inds.length < 1) return '';
	var h = ' <div id="approval-buttons">';
	for (var i = 0 ; i < inds.length ; i++) {
		h += '<input type="button" onClick="approvalButtonClick(\'' + qann.encounter.catalogNumber + '\', \'' +
		     inds[i] + '\',);" value="Approve as assigned to ' + inds[i] + '" />';
	}
	return h + '</div>';
}


// sends everything to java on the page and returns JSON with encounter and indy ID
function approvalButtonClick(encID, indivID, encID2, taskId, displayName, useLocation) {
console.warn(' ===> approvalButtonClick(encID=%o, indivID=%o, encID2=%o, taskId=%o, displayName=%o, useLocation=%o)', encID, indivID, encID2, taskId, displayName, useLocation);
	let loc = annotData[queryAnnotId] && annotData[queryAnnotId][0] && annotData[queryAnnotId][0].encounterLocationId;
	useLocation == useLocation && loc;
	var msgTarget = '#enc-action';  //'#approval-buttons';

	if (nameUUIDCache.hasOwnProperty(indivID)) {
		displayName = indivID;
		indivID = nameUUIDCache[indivID];
	}

	console.info('approvalButtonClick: id(%s) => %s %s taskId=%s displayName=%s', indivID, encID, encID2, taskId, displayName);
	if ((!indivID || !encID) && !useLocation) {
		jQuery(msgTarget).html('Argument errors');
		return;
	}
	jQuery(msgTarget).html('<i>saving changes...</i>');
	var url = 'iaResults.jsp?number=' + encID + '&taskId=' + taskId + '&individualID=' + indivID;
        if (useLocation) url += '&useLocation=true';
	let projectId = getSelectedProjectIdPrefix();
	if (projectId&&projectId!=NONE_SELECTED) {
		url += '&projectId='+projectId;
		console.log('adding projectId to URL for new name!!');
	}
	if (encID2) url += '&enc2=' + encID2;

	jQuery.ajax({
		url: url,
		type: 'GET',
		dataType: 'json',
		success: function(d) {
			console.warn(d);
			if (d.success) {
				jQuery(msgTarget).html('<i><b>Update successful</b></i>');
				var indivLink = ' <a class="indiv-link" title="open individual page" target="_new" href="individuals.jsp?number=' + d.individualId + '">' + d.individualName + '</a>';
				if (encID2) {
					$(".enc-title .indiv-link").remove();
					$(".enc-title #enc-action").remove();
					$(".enc-title").append('<span> of <a class="indiv-link" title="open individual page" target="_new" href="individuals.jsp?number=' + d.individualId + '">' + d.individualName + '</a></span>');
					$(".enc-title").append('<div id="enc-action"><i><b>  Update Successful</b></i></div>');
					// updates encounters in results list with name and link to indy
					$("#encnum"+d.encounterId).append(indivLink); // unlikely, should be the query encounter  
					$("#encnum"+d.encounterId2).append(indivLink); // likely, should be newly matched target encounter(s)
				}
			} else {
				console.warn('error returned: %o', d);
				jQuery(msgTarget).html('Error updating encounter: <b>' + d.error + '</b>');
			}
		},
		error: function(x,y,z) {
			console.warn('%o %o %o', x, y, z);
			jQuery(msgTarget).html('<b>Error updating encounter</b>');
		}
	});
	return true;
}


function approveNewIndividual(el) {
	// 'jel' as the input element contains the dsiplayName as a value
	var jel = $(el);
	console.info('name=%s; qe=%s, me=%s, taskId=%s, displayName=%s', jel.val(), jel.data('query-enc-id'), jel.data('match-enc-id'), jel.data('match-task-id'), jel.data('match-display-name'));
	return approvalButtonClick(jel.data('query-enc-id'), jel.val(), jel.data('match-enc-id'), jel.data('match-task-id'), jel.data('match-display-name'), jel.parent().find('.location-based-checkbox').is(':checked'));
}

function encDisplayString(encId) {
	if (encId.trim().length == 36) return encId.substring(0,6)+"...";
	return encId;
}


function negativeButtonClick(encId, oldDisplayName) {

	var confirmMsg = 'Confirm no match?\n\n';
	confirmMsg += 'By clicking \'OK\', you are confirming that there is no correct match in the results below. ';
	if (oldDisplayName&&oldDisplayName!=""&&oldDisplayName.length) {
		confirmMsg+= 'The name <%=nextNameString%> will be added to individual '+oldDisplayName;
	} else {
		confirmMsg+= 'A new individual will be created with name <%=nextNameString%> and applied to encounter '+encDisplayString(encId);
	}
	confirmMsg+= ' to record your decision.';

	let paramStr = 'encId='+encId+'&noMatch=true';
	let projectId = '<%=projectIdPrefix%>';
	if (projectId&&projectId.length) {
		paramStr += '&useNextProjectId=true&projectIdPrefix='+projectId;
	}

	console.log("paramStr for 'negativeButtonClick' : "+paramStr);

	if (confirm(confirmMsg)) {
		$.ajax({
			url: 'iaResults.jsp?' + paramStr,  //hacktacular!
			type: 'GET',
			dataType: 'json',
			complete: function(d) {
				console.log("RTN from negativeButtonClick : "+JSON.stringify(d)); 
				updateNameCallback(d, oldDisplayName); 
			}
		})
	}
}

function updateNameCallback(d, oldDisplayName) {
	console.log("Update name callback! got d="+d+" and stringify = "+JSON.stringify(d));
	alert("Success! Added name <%=nextNameKey%>: <%=nextName%> to "+oldDisplayName);
}

function addNegativeButton(encId, oldDisplayName) {
	if (<%=usesAutoNames%>) {
		console.log("Adding auto name/confirm negative button!");
		var negativeButton = '<input onclick=\'negativeButtonClick(\"'+encId+'\", \"'+oldDisplayName+'\");\' type="button" value="Confirm No Match" />';
		console.log("negativeButton = "+negativeButton);
		//var negativeButton = '<input onclick="negativeButtonClick();" type="button" value="Confirm No Match" />';
		headerDefault = negativeButton;
		//console.log("NEGATIVE BUTTON: About to attach "+negativeButton+" to "+JSON.stringify($('div#enc-action')));
		$('div#enc-action').html(negativeButton);
	} else {
		console.log("No name scheme, baby!");
	}
}

function getProjectData(currentUsername, selectedProject) {
  let requestJSON = {};
  requestJSON['participantId'] = currentUsername;
  console.log("all requestJSON for populateProjectDropdown() : "+JSON.stringify(requestJSON));
  $.ajax({
      url: wildbookGlobals.baseUrl + '../ProjectGet',
      type: 'POST',
      data: JSON.stringify(requestJSON),
      dataType: 'json',
      contentType: 'application/json',
      success: function(d) {
          console.info('Success in ProjectGet retrieving data! Got back '+JSON.stringify(d));
		  let projectsArr = d.projects;
		  if (projectsArr.length) {
			populateProjectsDropdown(projectsArr, selectedProject);
		  }
      },
      error: function(x,y,z) {
          console.warn('%o %o %o', x, y, z);
      }
  });
}

function populateProjectsDropdown(projectsArr, selectedProject) {
	$('#projectDropdownSpan').removeAttr('hidden');
	let dropdown = $('#projectDropdownSpan #projectDropdown');
	let emptyOption;
	if (!selectedProject||selectedProject==""||selectedProject||"null"||!selectedProject.length) {
		emptyOption = $('<option selected class="projectSelectOption">'+NONE_SELECTED+'</option>');
	} else {
		emptyOption = $('<option value="" class="projectSelectOption">'+NONE_SELECTED+'</option>');
	}
	dropdown.append(emptyOption); 
	for (i=0;i<projectsArr.length;i++) {
		let project = projectsArr[i];
		let selectEl;
		if (selectedProject&&selectedProject==project.projectIdPrefix) {
			selectEl = $('<option selected class="projectSelectOption" value="'+project.projectIdPrefix+'">'+project.researchProjectName+'</option>');
		} else {
			selectEl = $('<option class="projectSelectOption" value="'+project.projectIdPrefix+'">'+project.researchProjectName+'</option>');
		}
		dropdown.append(selectEl);
	}
}

$(document).ready(function(){
	let currentUsername = '<%=currentUsername%>';
	let selectedProject = '<%=projectIdPrefix%>';
	if (selectedProject=="null"||selectedProject=="") selectedProject = false;
	if (currentUsername.length) {
		getProjectData(currentUsername, selectedProject);
	}
});

function isProjectSelected() {
	let dropdownVal = $("#projectDropdown").val();
	if (dropdownVal&&dropdownVal!=""&&dropdownVal!="null"&&dropdownVal!=NONE_SELECTED) {
		return true;
	}
	return false;
}

$('#projectDropdown').on('change', function() {
	let taskId = '<%=taskId%>';
	let reloadURL = "../iaResults.jsp?taskId="+taskId;
	let selectedProject = $("#projectDropdown").val();
	// replace reserved pound sign in incremental ID's
	selectedProject = selectedProject.replaceAll("#", "%23");
	if (selectedProject&&selectedProject.length) {
		reloadURL += "&projectIdPrefix="+selectedProject;
	}
	window.location.href = reloadURL;
});

// this is messy, but i'm avoiding another database hit
var projectForEncCache = {};

function selectedProjectContainsEncounter(acmId) {
	console.log("entering selectedProjectContainsEncounte servlet for acmId"+acmId);
	let selectedProject = $("#projectDropdown").val();
	let requestJSON = {};
	requestJSON['projectIdPrefix'] = selectedProject;
	requestJSON['acmId'] = acmId;
	requestJSON['annotInProject'] = "true";

	$.ajax({
		url: wildbookGlobals.baseUrl + '../ProjectGet',
		type: 'POST',
		data: JSON.stringify(requestJSON),
		dataType: 'json',
		async: true,
		contentType: 'application/json',
		success: function(d) {
			if (d.inProject=="true"||d.inProject==true) {
				return true;
			}

		},
		error: function(x,y,z) {
			console.warn('%o %o %o', x, y, z);

			return false;

		}
	});
	return true;

}

</script>
