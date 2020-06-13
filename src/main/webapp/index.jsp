<%@ page contentType="text/html; charset=utf-8" language="java"
     import="org.ecocean.*,
              org.ecocean.servlet.ServletUtilities,
              java.util.ArrayList,
              java.util.List,
              java.util.Map,
              java.util.Iterator,
              java.util.Properties,
              java.util.StringTokenizer,
              org.ecocean.cache.*
              "
%>



<jsp:include page="header.jsp" flush="true"/>

<%
String context=ServletUtilities.getContext(request);

//set up our Shepherd

Shepherd myShepherd=null;
myShepherd=new Shepherd(context);
myShepherd.setAction("index.jsp");

String mapKey = CommonConfiguration.getGoogleMapsKey(context);
String langCode=ServletUtilities.getLanguageCode(request);

//check for and inject a default user 'tomcat' if none exists
if (!CommonConfiguration.isWildbookInitialized(myShepherd)) {
  System.out.println("WARNING: index.jsp has determined that CommonConfiguration.isWildbookInitialized()==false!");
  %>
    <script type="text/javascript">
      console.log("Wildbook is not initialized!");
    </script>
  <%
  StartupWildbook.initializeWildbook(request, myShepherd);
}
// Make a properties object for lang support.
Properties props = new Properties();
// Grab the properties file with the correct language strings.
props = ShepherdProperties.getProperties("index.properties", langCode,context);


%>


<style type="text/css">
.full_screen_map {
position: absolute !important;
top: 0px !important;
left: 0px !important;
z-index: 1 !imporant;
width: 100% !important;
height: 100% !important;
margin-top: 0px !important;
margin-bottom: 8px !important;
</style>
<script src="//maps.google.com/maps/api/js?key=<%=mapKey%>&language=<%=langCode%>"></script>
<script src="cust/mantamatcher/js/google_maps_style_vars.js"></script>
<script src="cust/mantamatcher/js/richmarker-compiled.js"></script>
  <script type="text/javascript">
  var map;
  var mapZoom = 8;
  var center;
  var newCenter;	
//Define the overlay, derived from google.maps.OverlayView
  function Label(opt_options) {
   // Initialization
   this.setValues(opt_options);
   // Label specific
   var span = this.span_ = document.createElement('span');
   span.style.cssText = 'font-weight: bold;' +
                        'white-space: nowrap; ' +
                        'padding: 2px; z-index: 999 !important;';
   span.style.zIndex=999;
   var div = this.div_ = document.createElement('div');
   div.style.zIndex=999;
   div.appendChild(span);
   div.style.cssText = 'position: absolute; display: none;z-index: 999 !important;';
  };
  Label.prototype = new google.maps.OverlayView;
  // Implement onAdd
  Label.prototype.onAdd = function() {
   var pane = this.getPanes().overlayLayer;
   pane.appendChild(this.div_);
   // Ensures the label is redrawn if the text or position is changed.
   var me = this;
   this.listeners_ = [
     google.maps.event.addListener(this, 'position_changed',
         function() { me.draw(); }),
     google.maps.event.addListener(this, 'text_changed',
         function() { me.draw(); })
   ];
  };
  // Implement onRemove
  Label.prototype.onRemove = function() {
   this.div_.parentNode.removeChild(this.div_);
   // Label is removed from the map, stop updating its position/text.
   for (var i = 0, I = this.listeners_.length; i < I; ++i) {
     google.maps.event.removeListener(this.listeners_[i]);
   }
  };
  
  // Implement draw
  Label.prototype.draw = function() {
   var projection = this.getProjection();
   var position = projection.fromLatLngToDivPixel(this.get('position'));
   var div = this.div_;
   div.style.left = position.x + 'px';
   div.style.top = position.y + 'px';
   div.style.display = 'block';
   div.style.zIndex=999;
   this.span_.innerHTML = this.get('text').toString();
  };
  		//map
  		//var map;
  	  var bounds = new google.maps.LatLngBounds();
      function initialize() {
    	// Create an array of styles for our Google Map.
  	    //var gmap_styles = [{"stylers":[{"visibility":"off"}]},{"featureType":"water","stylers":[{"visibility":"on"},{"color":"#00c0f7"}]},{"featureType":"landscape","stylers":[{"visibility":"on"},{"color":"#005589"}]},{"featureType":"administrative","elementType":"geometry.stroke","stylers":[{"visibility":"on"},{"color":"#00c0f7"},{"weight":1}]}]
    	if($("#map_canvas").hasClass("full_screen_map")){mapZoom=3;}
		
    	if (center == null) {
	    	center = new google.maps.LatLng(0,0);
    	} else {
    		center = map.getCenter();
    	}
        map = new google.maps.Map(document.getElementById('map_canvas'), {
          zoom: mapZoom,
          center: center,
          mapTypeId: google.maps.MapTypeId.HYBRID,
          zoomControl: true,
          scaleControl: false,
          scrollwheel: false,
          disableDoubleClickZoom: true,
        });
    	  //adding the fullscreen control to exit fullscreen
    	  var fsControlDiv = document.createElement('DIV');
    	  var fsControl = new FSControl(fsControlDiv, map);
    	  fsControlDiv.index = 1;
    	  map.controls[google.maps.ControlPosition.TOP_RIGHT].push(fsControlDiv);
    	    // Create a new StyledMapType object, passing it the array of styles,
    	    // as well as the name to be displayed on the map type control.
    	    var styledMap = new google.maps.StyledMapType(gmap_styles, {name: "Styled Map"});
    	    //Associate the styled map with the MapTypeId and set it to display.
    	    map.mapTypes.set('map_style', styledMap);
    	    map.setMapTypeId('map_style');
        var markers = [];
 	    var movePathCoordinates = [];
 	    //iterate here to add points per location ID
 		var maxZoomService = new google.maps.MaxZoomService();
 		maxZoomService.getMaxZoomAtLatLng(map.getCenter(), function(response) {
 			    if (response.status == google.maps.MaxZoomStatus.OK) {
 			    	if(response.zoom < map.getZoom()){
 			    		map.setZoom(response.zoom);
 			    	}
 			    }
 		});
 		
 		// let's add map points for our locationIDs
 		<%
 		List<String> locs=CommonConfiguration.getIndexedPropertyValues("locationID", context);
 		int numLocationIDs = locs.size();
 		Properties locProps=ShepherdProperties.getProperties("locationIDGPS.properties", "", context);
 		myShepherd.beginDBTransaction();
 		try{
	 		for(int i=0;i<numLocationIDs;i++){
	 			String locID = locs.get(i);
	 			if((locProps.getProperty(locID)!=null)&&(locProps.getProperty(locID).indexOf(",")!=-1)){
	 				StringTokenizer st = new StringTokenizer(locProps.getProperty(locID), ",");
	 				String lat = st.nextToken();
	 				String longit=st.nextToken();
	 				String thisLatLong=lat+","+longit;
	 		        //now  let's calculate how many
	 		        int numSightings=myShepherd.getNumEncounters(locID);
	 		        if(numSightings>0){
	 		        	Integer numSightingsInteger=new Integer(numSightings);
	 		          %>
	 		         var latLng<%=i%> = new google.maps.LatLng(<%=thisLatLong%>);
			          bounds.extend(latLng<%=i%>);
	 		          var divString<%=i%> = "<div style=\"font-weight:bold;margin-top: 5px; text-align: center;line-height: 45px;vertical-align: middle;width:60px;height:60px;padding: 2px; background-image: url('cust/mantamatcher/img/manta-silhouette.png');background-size: cover\"><a href=\"encounters/searchResults.jsp?locationCodeField=<%=locID %>\"><%=numSightingsInteger.toString() %></a></div>";
	 		         var marker<%=i%> = new RichMarker({
	 		            position: latLng<%=i%>,
	 		            map: map,
	 		            draggable: false,
	 		           content: divString<%=i%>,
	 		           flat: true
	 		        });
	 			      markers.push(marker<%=i%>);
	 		          map.fitBounds(bounds);
	 				<%
	 			} //end if
	 			}  //end if
	 		}  //end for
 		}
 		catch(Exception e){
 			e.printStackTrace();
 		}
 		finally{
 			myShepherd.rollbackDBTransaction();
 		}
 	 	%>
    	 google.maps.event.addListener(map, 'dragend', function() {
    		var idleListener = google.maps.event.addListener(map, 'idle', function() {
    			google.maps.event.removeListener(idleListener);
    			console.log("GetCenter : "+map.getCenter());
    			mapZoom = map.getZoom();
    			newCenter = map.getCenter();
    			center = newCenter;
    			map.setCenter(map.getCenter());
    		});
    		 
 	     }); 	 
    	 
    	 google.maps.event.addDomListener(window, "resize", function() {	 
 	    	console.log("Resize Center : "+center);
 	    	google.maps.event.trigger(map, "resize");
 	  	    console.log("Resize : "+newCenter);
 	  	    map.setCenter(center);
 	     });    
 	 } // end initialize function
 	  	  
 	  	 
 	 
 	 
      function fullScreen(){
  		$("#map_canvas").addClass('full_screen_map');
  		$('html, body').animate({scrollTop:0}, 'slow');
  		initialize();
  		//hide header
  		$("#header_menu").hide();
  		if(overlaysSet){overlaysSet=false;setOverlays();}
  		//alert("Trying to execute fullscreen!");
  	}
  	function exitFullScreen() {
  		$("#header_menu").show();
  		$("#map_canvas").removeClass('full_screen_map');
  		initialize();
  		if(overlaysSet){overlaysSet=false;setOverlays();}
  		//alert("Trying to execute exitFullScreen!");
  	}
  	//making the exit fullscreen button
  	function FSControl(controlDiv, map) {
  	  // Set CSS styles for the DIV containing the control
  	  // Setting padding to 5 px will offset the control
  	  // from the edge of the map
  	  controlDiv.style.padding = '5px';
  	  // Set CSS for the control border
  	  var controlUI = document.createElement('DIV');
  	  controlUI.style.backgroundColor = '#f8f8f8';
  	  controlUI.style.borderStyle = 'solid';
  	  controlUI.style.borderWidth = '1px';
  	  controlUI.style.borderColor = '#a9bbdf';;
  	  controlUI.style.boxShadow = '0 1px 3px rgba(0,0,0,0.5)';
  	  controlUI.style.cursor = 'pointer';
  	  controlUI.style.textAlign = 'center';
  	  controlUI.title = 'Toggle the fullscreen mode';
  	  //controlDiv.appendChild(controlUI);
  	  // Set CSS for the control interior
  	  var controlText = document.createElement('DIV');
  	  controlText.style.fontSize = '12px';
  	  controlText.style.fontWeight = 'bold';
  	  controlText.style.color = '#000000';
  	  controlText.style.paddingLeft = '4px';
  	  controlText.style.paddingRight = '4px';
  	  controlText.style.paddingTop = '3px';
  	  controlText.style.paddingBottom = '2px';
  	  controlUI.appendChild(controlText);
  	  controlText.style.visibility='hidden';
  	  //toggle the text of the button
  	  if($("#map_canvas").hasClass("full_screen_map")){
  	      controlText.innerHTML = 'Exit Fullscreen';
  	  } else {
  	      controlText.innerHTML = 'Fullscreen';
  	  }
 	  google.maps.event.addDomListener(controlUI, 'click', function() {
 	 	if($("#map_canvas").hasClass("full_screen_map")){
 	  	  exitFullScreen();
 	  	} else {
 	  	  fullScreen();
 	  	}
 	  });
  	  
  	  // Setup the click event listeners: toggle the full screen
  	}
    google.maps.event.addDomListener(window, 'load', initialize);
  	
  </script>
<%


//let's quickly get the data we need from Shepherd

int numMarkedIndividualsPlains=0;
int numMarkedIndividualsGrevy=0;
int numEncounters=0;
int numDataContributors=0;
int numUsersWithRoles=0;
int numUsers=0;

QueryCache qc=QueryCacheFactory.getQueryCache(context);

myShepherd.beginDBTransaction();

//String url = "login.jsp";
//response.sendRedirect(url);
//RequestDispatcher dispatcher = getServletContext().getRequestDispatcher(url);
//dispatcher.forward(request, response);


try{


    //numMarkedIndividuals=myShepherd.getNumMarkedIndividuals();
    numMarkedIndividualsPlains=qc.getQueryByName("numMarkedIndividualsPlains").executeCountQuery(myShepherd).intValue();
    numMarkedIndividualsGrevy=qc.getQueryByName("numMarkedIndividualsGrevy").executeCountQuery(myShepherd).intValue();
    
    numEncounters=myShepherd.getNumEncounters();
    //numEncounters=qc.getQueryByName("numEncounters").executeCountQuery(myShepherd).intValue();
    //numDataContributors=myShepherd.getAllUsernamesWithRoles().size();
    numDataContributors=qc.getQueryByName("numUsersWithRoles").executeCountQuery(myShepherd).intValue();
    numUsers=qc.getQueryByName("numUsers").executeCountQuery(myShepherd).intValue();
    numUsersWithRoles = numUsers-numDataContributors;


}
catch(Exception e){
    System.out.println("INFO: *** If you are seeing an exception here (via index.jsp) your likely need to setup QueryCache");
    System.out.println("      *** This entails configuring a directory via cache.properties and running appadmin/testQueryCache.jsp");
    e.printStackTrace();
}
finally{
   myShepherd.rollbackDBTransaction();
   myShepherd.closeDBTransaction();
}
%>

<section class="hero container-fluid main-section relative">
    <div class="container relative">
        <div class="col-xs-12 col-sm-10 col-md-8 col-lg-6">
            <h2>Welcome to Wildbook for Zebras!</h2>
            <!--
            <button id="watch-movie" class="large light">
				Watch the movie
				<span class="button-icon" aria-hidden="true">
			</button>
			-->
            <a href="submit.jsp">
                <button class="large"><%= props.getProperty("reportEncounter") %><span class="button-icon" aria-hidden="true"></button>
            </a>
        </div>

	</div>


</section>

<section class="container text-center main-section">

	<h2 class="section-header">Machine Learning & Citizen Science & Conservation Research</h2>

  	<p class="lead">Wildbook for Zebras applies computer vision algorithms and deep learning to identify and track individual zebras across hundreds of thousands of photos. We help researchers collaborate with each other and citizen scientists contribute to the effort. A.I. scales and speeds research and conservation.</p>
  	
  	<h3 class="section-header">Step 1. Deep Learning Finds Animals</h3>
  	<p class="lead">We train computer vision to find individual zebras in photos and identify the species. </p>
  	<img width="500px" height="*" style="max-width: 100%;" height="*" class="lazyload" src="cust/mantamatcher/img/individual_placeholder_image.jpg" data-src="images/detectionZebra.jpg" />
		  	
  	
  	<h3 class="section-header">Step 2. Algorithms and Neural Networks Identify Individuals</h3>
  	<p class="lead">When we know where each animal is, we can identify them individually using algorithms that make digital "fingerprints" for each animal, such as identifying them by their unique stripes. We replace hours of human labor with just a few minutes of computer vision, scanning for matches across tens of thousands of photos.</p>
  	<img width="500px" height="*" style="max-width: 100%;" height="*" class="lazyload" src="cust/mantamatcher/img/individual_placeholder_image.jpg" data-src="images/matches.jpg" />
		
		
	<h3 class="section-header">Step 3. Population Dynamics Define Conservation Action</h3>
  	<p class="lead">If we can quickly track individuals in a population, we can model size and migration to generate new insights and support rapid, data-driven conservation action.</p>
  	<img width="500px" height="*" style="max-width: 100%;" height="*" class="lazyload" src="cust/mantamatcher/img/individual_placeholder_image.jpg" data-src="images/action.jpg" />



</section>

<div class="container-fluid relative data-section">

    <aside class="container main-section">
        <div class="row">

            <!-- Random user profile to select -->
            <%
            myShepherd.beginDBTransaction();
            try{
								User featuredUser=myShepherd.getRandomUserWithPhotoAndStatement();
            if(featuredUser!=null){
                String profilePhotoURL="images/empty_profile.jpg";
                if(featuredUser.getUserImage()!=null){
                	profilePhotoURL="/"+CommonConfiguration.getDataDirectoryName(context)+"/users/"+featuredUser.getUsername()+"/"+featuredUser.getUserImage().getFilename();
                }

            %>
                <section class="col-xs-12 col-sm-6 col-md-4 col-lg-4 padding focusbox">
                    <div class="focusbox-inner opec">
                        <h2><%=props.getProperty("ourContributors") %></h2>
                        <div>
                            <img src="<%=profilePhotoURL %>" width="80px" height="*" alt="" class="pull-left" />
                            <p><%=featuredUser.getFullName() %>
                                <%
                                if(featuredUser.getAffiliation()!=null){
                                %>
                                <i><%=featuredUser.getAffiliation() %></i>
                                <%
                                }
                                %>
                            </p>
                            <p><%=featuredUser.getUserStatement() %></p>
                        </div>
                        <a href="whoAreWe.jsp" title="" class="cta">Show me all the contributors</a>
                    </div>
                </section>
            <%
            } // end if

            }
            catch(Exception e){e.printStackTrace();}
            finally{

            	myShepherd.rollbackDBTransaction();
            }
            %>


            <section class="col-xs-12 col-sm-6 col-md-4 col-lg-4 padding focusbox">
                <div class="focusbox-inner opec">
                    <h2>Latest encounters</h2>
                    <ul class="encounter-list list-unstyled">

                       <%
                       List<Encounter> latestIndividuals=myShepherd.getMostRecentIdentifiedEncountersByDate(3);
                       int numResults=latestIndividuals.size();
                       myShepherd.beginDBTransaction();
                       try{
	                       for(int i=0;i<numResults;i++){
	                           Encounter thisEnc=latestIndividuals.get(i);
	                           String displayName="";
	                           if(thisEnc.getIndividual()!=null){
	                        	   displayName=thisEnc.getIndividual().getDisplayName();
	                           }
	                           %>
	                            <li>
	                                <img src="cust/mantamatcher/img/manta-silhouette.png" alt="" width="85px" height="75px" class="pull-left" />
	                                <small>
	                                    <time>
	                                        <%=thisEnc.getDate() %>
	                                        <%
	                                        if((thisEnc.getLocationID()!=null)&&(!thisEnc.getLocationID().trim().equals(""))){
	                                        %>/ <%=thisEnc.getLocationID() %>
	                                        <%
	                                           }
	                                        %>
	                                    </time>
	                                </small>
	                                <p><a href="encounters/encounter.jsp?number=<%=thisEnc.getCatalogNumber() %>" title=""><%=displayName %></a></p>


	                            </li>
	                        <%
	                        }
						}
                       catch(Exception e){e.printStackTrace();}
                       finally{
                    	   myShepherd.rollbackDBTransaction();

                       }

                        %>

                    </ul>
                    <a href="encounters/searchResults.jsp?state=approved" title="" class="cta"><%=props.getProperty("seeMoreEncs") %></a>
                </div>
            </section>
            <section class="col-xs-12 col-sm-6 col-md-4 col-lg-4 padding focusbox">
                <div class="focusbox-inner opec">
                    <h2><%=props.getProperty("topSpotters")%></h2>
                    <ul class="encounter-list list-unstyled">
                    <%
                    myShepherd.beginDBTransaction();
                    try{
	                    //System.out.println("Date in millis is:"+(new org.joda.time.DateTime()).getMillis());
                            long startTime = System.currentTimeMillis() - Long.valueOf(1000L*60L*60L*24L*30L);

	                    Map<String,Integer> spotters = myShepherd.getTopUsersSubmittingEncountersSinceTimeInDescendingOrder(startTime);
	                    int numUsersToDisplay=3;
	                    if(spotters.size()<numUsersToDisplay){numUsersToDisplay=spotters.size();}
	                    Iterator<String> keys=spotters.keySet().iterator();
	                    Iterator<Integer> values=spotters.values().iterator();
	                    while((keys.hasNext())&&(numUsersToDisplay>0)){
	                          String spotter=keys.next();
	                          int numUserEncs=values.next().intValue();
	                          if(myShepherd.getUser(spotter)!=null){
	                        	  String profilePhotoURL="images/empty_profile.jpg";
	                              User thisUser=myShepherd.getUser(spotter);
	                              if(thisUser.getUserImage()!=null){
	                              	profilePhotoURL="/"+CommonConfiguration.getDataDirectoryName(context)+"/users/"+thisUser.getUsername()+"/"+thisUser.getUserImage().getFilename();
	                              }
	                              //System.out.println(spotters.values().toString());
	                            Integer myInt=spotters.get(spotter);
	                            //System.out.println(spotters);

	                          %>
	                                <li>
	                                    <img src="<%=profilePhotoURL %>" width="80px" height="*" alt="" class="pull-left" />
	                                    <%
	                                    if(thisUser.getAffiliation()!=null){
	                                    %>
	                                    <small><%=thisUser.getAffiliation() %></small>
	                                    <%
	                                      }
	                                    %>
	                                    <p><a href="#" title=""><%=spotter %></a>, <span><%=numUserEncs %> <%=props.getProperty("encounters") %><span></p>
	                                </li>

	                           <%
	                           numUsersToDisplay--;
	                    }
	                   } //end while
                    }
                    catch(Exception e){e.printStackTrace();}
                    finally{myShepherd.rollbackDBTransaction();}

                   %>

                    </ul>
                    <a href="whoAreWe.jsp" title="" class="cta"><%=props.getProperty("allSpotters") %></a>
                </div>
            </section>
        </div>
    </aside>
</div>

<div class="container-fluid">
    <section class="container text-center  main-section">
        <div class="row">
            <section class="col-xs-12 col-sm-3 col-md-3 col-lg-3 padding">
                <p class="brand-primary"><i><span class="massive"><%=numMarkedIndividualsPlains %></span> identified Plains Zebras</i></p>
            </section>
                        <section class="col-xs-12 col-sm-3 col-md-3 col-lg-3 padding">
                <p class="brand-primary"><i><span class="massive"><%=numMarkedIndividualsGrevy %></span> identified Grevy's Zebras</i></p>
            </section>
            <section class="col-xs-12 col-sm-3 col-md-3 col-lg-3 padding">
                <p class="brand-primary"><i><span class="massive"><%=numEncounters %></span> reported sightings</i></p>
            </section>

        </div>

        <hr/>



    </section>
</div>




<jsp:include page="footer.jsp" flush="true"/>

<script>
window.addEventListener("resize", function(e) { $("#map_canvas").height($("#map_canvas").width()*0.662); });
google.maps.event.addDomListener(window, "resize", function() {
	 google.maps.event.trigger(map, "resize");
	 map.fitBounds(bounds);
	});
</script>

<%
myShepherd.closeDBTransaction();
myShepherd=null;
%>
