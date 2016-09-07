<%@ page contentType="text/html; charset=utf-8" language="java"
         import="javax.jdo.Query,org.ecocean.*,org.ecocean.servlet.ServletUtilities,java.io.File, java.util.*, org.ecocean.genetics.*, org.ecocean.security.Collaboration, org.ecocean.social.*, com.google.gson.Gson" %>


<%!
	public String cleanString(Object obj) {
		if (obj == null) return "";
		return obj.toString();
	}
%>

<%

String blocker = "";
String context="context0";
context=ServletUtilities.getContext(request);

  //handle some cache-related security
  response.setHeader("Cache-Control", "no-cache"); //Forces caches to obtain a new copy of the page from the origin server
  response.setHeader("Cache-Control", "no-store"); //Directs caches not to store the page under any circumstance
  response.setDateHeader("Expires", 0); //Causes the proxy cache to see the page as "stale"
  response.setHeader("Pragma", "no-cache"); //HTTP 1.0 backward compatibility

  //setup data dir
  String rootWebappPath = getServletContext().getRealPath("/");
  File webappsDir = new File(rootWebappPath).getParentFile();
  File shepherdDataDir = new File(webappsDir, CommonConfiguration.getDataDirectoryName(context));
  //if(!shepherdDataDir.exists()){shepherdDataDir.mkdirs();}
  File encountersDir=new File(shepherdDataDir.getAbsolutePath()+"/encounters");
  //if(!encountersDir.exists()){encountersDir.mkdirs();}
  //File thisEncounterDir = new File(encountersDir, number);

//setup our Properties object to hold all properties
  Properties props = new Properties();
  //String langCode = "en";
  String langCode=ServletUtilities.getLanguageCode(request);



  //load our variables for the submit page

  //props.load(getClass().getResourceAsStream("/bundles/" + langCode + "/occurrence.properties"));
  props = ShepherdProperties.getProperties("occurrence.properties", langCode,context);

	Properties collabProps = new Properties();
 	collabProps=ShepherdProperties.getProperties("collaboration.properties", langCode, context);

  String name = request.getParameter("number").trim();
  Shepherd myShepherd = new Shepherd(context);



  boolean isOwner = false;
  if (request.getUserPrincipal()!=null) {
    isOwner = true;
  }

%>



  <style type="text/css">
    <!--
    .style1 {
      color: #000000;
      font-weight: bold;
    }
    .col-relationships {
    	width: 170px;
    }

    .enc-filename div {
    	color: #666;
    	font-size: 0.9em;
    	width: 120px;
    	padding-left: 3px;
    	overflow-x: hidden;
    	white-space: nowrap;
    }

    .relationship-none {
    	position: relative;
    	border-radius: 4px;
    	padding: 2px 8px 2px 8px;
    	background-color: #DDD;
    	color: #AAA;
    }

    .relationship {
    	border-radius: 4px;
    	padding: 2px 8px 2px 8px;
    	background-color: #888;
    	color: #DDD;
    }
    .relationship:hover {
    	background-color: #F98;
    	color: #333;
    }

    .rel-partner {
    	background-color: #FAA;
    }

    #relationships-form {
    	width: 200px;
    	z-index: 300;
    	background-color: #FFC;
    	position: absolute;
    	left: -200px;
    	top: 3px;
    	display: none;
    	padding: 3px;
    	border: solid 2px #444;
    	border-radius: 4px;
    }
    
    div.scroll {
      height: 200px;
      overflow: auto;
      border: 1px solid #666;
      background-color: #ccc;
      padding: 8px;
    }


    -->
  </style>


  <jsp:include page="header.jsp" flush="true"/>


  <!--
    1 ) Reference to the files containing the JavaScript and CSS.
    These files must be located on your server.
  -->

  <script type="text/javascript" src="highslide/highslide/highslide-with-gallery.js"></script>
  <link rel="stylesheet" type="text/css" href="highslide/highslide/highslide.css"/>

  <!--
    2) Optionally override the settings defined at the top
    of the highslide.js file. The parameter hs.graphicsDir is important!
  -->

  <script type="text/javascript">
    hs.graphicsDir = 'highslide/highslide/graphics/';

    hs.transitions = ['expand', 'crossfade'];
    hs.outlineType = 'rounded-white';
    hs.fadeInOut = true;
    //hs.dimmingOpacity = 0.75;

    //define the restraining box
    hs.useBox = true;
    hs.width = 810;
    hs.height = 250;
    hs.align = 'auto';
  	hs.anchor = 'top';

    //block right-click user copying if no permissions available
    <%
    if(request.getUserPrincipal()==null){
    %>
    hs.blockRightClick = true;
    <%
    }
    %>

    // Add the controlbar
    hs.addSlideshow({
      //slideshowGroup: 'group1',
      interval: 5000,
      repeat: false,
      useControls: true,
      fixedControls: 'fit',
      overlayOptions: {
        opacity: 0.75,
        position: 'bottom center',
        hideOnMouseOut: true
      }
    });

  </script>

<!--  FACEBOOK LIKE BUTTON -->
<div id="fb-root"></div>
<script>(function(d, s, id) {
  var js, fjs = d.getElementsByTagName(s)[0];
  if (d.getElementById(id)) return;
  js = d.createElement(s); js.id = id;
  js.src = "//connect.facebook.net/en_US/all.js#xfbml=1";
  fjs.parentNode.insertBefore(js, fjs);
}(document, 'script', 'facebook-jssdk'));</script>

<!-- GOOGLE PLUS-ONE BUTTON -->
<script type="text/javascript">
  (function() {
    var po = document.createElement('script'); po.type = 'text/javascript'; po.async = true;
    po.src = 'https://apis.google.com/js/plusone.js';
    var s = document.getElementsByTagName('script')[0]; s.parentNode.insertBefore(po, s);
  })();
</script>



<div class="container maincontent">

<%!
  static boolean newValEqualsOldVal(Occurrence occ, String getterName, int newVal) {
    try {
      java.lang.reflect.Method getter = occ.getClass().getMethod(getterName);
      int oldVal = (Integer) getter.invoke(occ);
      boolean result = (oldVal == newVal);
      System.out.println("OCCURRENCE.JSP: "+getterName+" = "+oldVal);
      System.out.println("              : newVal = "+newVal);
      System.out.println("              : result = "+result);
      return result;
    } catch (Exception e) {
      System.out.println("exception caught");
    } finally {
      return (false);
    }
  }
%>


<%
  myShepherd.beginDBTransaction();
  try {
    if (myShepherd.isOccurrence(name)) {


      Occurrence occ = myShepherd.getOccurrence(name);
      boolean hasAuthority = ServletUtilities.isUserAuthorizedForOccurrence(occ, request);

      Encounter[] dateSortedEncs = occ.getDateSortedEncounters(false);
      int total = dateSortedEncs.length;
      HashMap<String,Encounter> encById = new HashMap<String,Encounter>();
      for (int i = 0; i < total; i++) {
        Encounter enc = dateSortedEncs[i];
        encById.put(enc.getCatalogNumber(), enc);
      }

			List collabs = Collaboration.collaborationsForCurrentUser(request);
			boolean visible = occ.canUserAccess(request);


      String saving = request.getParameter("save");
      String saveMessage = "";


      if (saving != null) {

        ClassEditTemplate.saveUpdatedFields((Object) occ, request, myShepherd);


        System.out.println("OCCURRENCE.JSP: Saving ADDITIONAL updated info...");

        ArrayList<Encounter> changedEncs = new ArrayList<Encounter>();
        //myShepherd.beginDBTransaction();
        Enumeration en = request.getParameterNames();
        while (en.hasMoreElements()) {
          String pname = (String)en.nextElement();
          if (pname.indexOf("occ:") == 0) {
            // taken care of by ClassEditTemplate.saveUpdatedFields((Object) occ, request, myShepherd);
            /*
            String methodName = "set" + pname.substring(4,5).toUpperCase() + pname.substring(5);
            String getterName = "get" + methodName.substring(3);
            String value = request.getParameter(pname);

            ClassEditTemplate.updateObjectField(occ, methodName, value);


            //saveMessage += "<p>occ - " + methodName + "</P>";
            java.lang.reflect.Method method;
            if ((pname.indexOf("decimalL") > -1) || pname.equals("occ:distance") || pname.equals("occ:bearing")) {  //must call with Double value
              Double dbl = null;
              try {
                dbl = Double.parseDouble(value);
              } catch (Exception ex) {
                System.out.println("could not parse double from " + value + ", using null");
              }
              try {
                method = occ.getClass().getMethod(methodName, Double.class);
                method.invoke(occ, dbl);
                System.out.println("OCCURRENCE.JSP: just invoked "+methodName+" with value "+dbl);
              } catch (Exception ex) {
                System.out.println(methodName + " -> " + ex.toString());
              }
            } else if ((pname.indexOf("num") == 4) || pname.equals("occ:groupSize")) {  //int
              Integer i = null;
              boolean valueIsNew;
              try {
                i = Integer.parseInt(value);
                System.out.println("OCCURRENCE.JSP: parsed integer value "+i+" for method "+methodName);
                boolean newValSameAsOld = newValEqualsOldVal(occ, getterName, i);
                System.out.println("              : newValSameAsOld = "+newValSameAsOld);
                valueIsNew = !newValSameAsOld;
                System.out.println("              : valueIsNew = "+valueIsNew);
              } catch (Exception ex) {
                System.out.println("could not parse integer from " + value + ", using null");
              }
              try {
                method = occ.getClass().getMethod(methodName, Integer.class);
                method.invoke(occ, i);
                System.out.println("              : just invoked "+methodName+" with value "+i);
              } catch (Exception ex) {
                System.out.println(("caught exception on "+methodName+" -> "+ex.toString()));
              }
            } else {
              try {
                method = occ.getClass().getMethod(methodName, String.class);
                method.invoke(occ, value);
                System.out.println("              : just invoked "+methodName+" with value "+value);
              } catch (Exception ex) {
                System.out.println(methodName + " -> " + ex.toString());
              }
            }*/

          } // encounter-related fields
            else if (pname.indexOf(":") > -1) {
            int i = pname.indexOf(":");
            String id = pname.substring(0, i);
            String methodName = "set" + pname.substring(i+1, i+2).toUpperCase() + pname.substring(i+2);
            String value = request.getParameter(pname);
            Encounter enc = encById.get(id);
            if (enc != null) {
              java.lang.reflect.Method method;
              if (methodName.equals("set_relMother")) {  //special case - make relationship
                if ((value != null) && !value.equals("") && (enc.getIndividualID() != null)) {
                  MarkedIndividual partnerIndiv = myShepherd.getMarkedIndividual(value);
                  if (partnerIndiv != null) {
                    Relationship rel = new Relationship("familial", enc.getIndividualID(), value, "mother", "calf");  //TODO generalize, i guess
                    myShepherd.getPM().makePersistent(rel);
                  }
                }


              } else if (methodName.equals("setAgeAtFirstSighting")) {  //need a Double, sets on individual
                Double dbl = null;
                try {
                  dbl = Double.parseDouble(value);
                } catch (Exception ex) {
                  System.out.println("could not parse double from " + value + ", using null");
                }
                if ((dbl != null) && (enc.getIndividualID() != null)) {
                  MarkedIndividual ind = myShepherd.getMarkedIndividual(enc.getIndividualID());
                  if (ind != null) {
                    ind.setAgeAtFirstSighting(dbl);
                  }
                }

              }  else {  //string
                try {
                  method = enc.getClass().getMethod(methodName, String.class);
                  method.invoke(enc, value);
                  System.out.println("OCCURRENCE.JSP: just invoked "+methodName+" with value "+value);
                  if (!changedEncs.contains(enc)) changedEncs.add(enc);
                } catch (Exception ex) {
                  System.out.println(methodName + " -> " + ex.toString());
                }
                //special case: we save the sex on the individual as well, if none is set there
                if (methodName.equals("setSex") && (value != null) && !value.equals("") && !value.equals("unknown") && (enc.getIndividualID() != null)) {
                  MarkedIndividual ind = myShepherd.getMarkedIndividual(enc.getIndividualID());
                  if ((ind != null) && ((ind.getSex() == null) || ind.getSex().equals("") || ind.getSex().equals("unknown"))) {
                    ind.setSex(value);
                    System.out.println("setting sex=" + value + " on indiv " + ind.getIndividualID());
                  }
                }
              }
            }
          }
        }


        myShepherd.commitDBTransaction();
        System.out.println("OCCURRENCE.JSP: Transaction committed");
      }


			if (!visible) {
  			ArrayList<String> uids = occ.getAllAssignedUsers();
				ArrayList<String> possible = new ArrayList<String>();
				for (String u : uids) {
					Collaboration c = null;
					if (collabs != null) c = Collaboration.findCollaborationWithUser(u, collabs);
					if ((c == null) || (c.getState() == null)) {
						User user = myShepherd.getUser(u);
						String fullName = u;
						if (user.getFullName()!=null) fullName = user.getFullName();
						possible.add(u + ":" + fullName.replace(",", " ").replace(":", " ").replace("\"", " "));
					}
				}
				String cmsg = "<p>" + collabProps.getProperty("deniedMessage") + "</p>";
				cmsg = cmsg.replace("'", "\\'");

				if (possible.size() > 0) {
    			String arr = new Gson().toJson(possible);
					blocker = "<script>$(document).ready(function() { $.blockUI({ message: '" + cmsg + "' + _collaborateMultiHtml(" + arr + ") }) });</script>";
				} else {
					cmsg += "<p><input type=\"button\" onClick=\"window.history.back()\" value=\"BACK\" /></p>";
					blocker = "<script>$(document).ready(function() { $.blockUI({ message: '" + cmsg + "' }) });</script>";
				}
			}
			out.println(blocker);

%>

<table><tr>

<td valign="middle">
 <h1><strong>&nbsp;<%=props.getProperty("occurrence") %></strong> <%=occ.getOccurrenceID()%></h1>
<p class="caption"><em><%=props.getProperty("description") %></em></p>
 <table><tr valign="middle">
  <td>
    <!-- Google PLUS-ONE button -->
<g:plusone size="small" annotation="none"></g:plusone>
</td>
<td>
<!--  Twitter TWEET THIS button -->
<a href="https://twitter.com/share" class="twitter-share-button" data-count="none">Tweet</a>
<script>!function(d,s,id){var js,fjs=d.getElementsByTagName(s)[0];if(!d.getElementById(id)){js=d.createElement(s);js.id=id;js.src="//platform.twitter.com/widgets.js";fjs.parentNode.insertBefore(js,fjs);}}(document,"script","twitter-wjs");</script>
</td>
<td>
<!-- Facebook LIKE button -->
<div class="fb-like" data-send="false" data-layout="button_count" data-width="100" data-show-faces="false"></div>
</td>
</tr></table> </td></tr></table>



<p><%=props.getProperty("numMarkedIndividuals") %>: <%=occ.getMarkedIndividualNamesForThisOccurrence().size() %></p>

<!--<p><%=props.getProperty("estimatedNumMarkedIndividuals") %>:
<%
if(occ.getIndividualCount()!=null){
%>
	<%=occ.getIndividualCount() %>
<%
}
%>
-->
&nbsp; <%if (hasAuthority && CommonConfiguration.isCatalogEditable(context)) {%><a id="indies" style="color:blue;cursor: pointer;"><img align="absmiddle" width="20px" height="20px" style="border-style: none;" src="images/Crystal_Clear_action_edit.png" /></a><%}%>
</p>


<div class="row">
<div class="col-sm-12">
<form method="post" action="occurrence.jsp?number=<%=occ.getOccurrenceID()%>" id="occform">
<input name="number" type="hidden" value="<%=occ.getOccurrenceID()%>" />

<style type="text/css">
  tr.padding-below td {
    padding-bottom: 20px;
  }

  table.occurrence-field-edit td:first-child {
    padding-right: 3em;
  }
  table.occurrence-field-edit td {
    padding-right: 0px;
    padding-top: 2px;
    padding-bottom: 3px;
  }

  table.occurrence-field-edit td.undo-container {
    display: none;
  }
  table.occurrence-field-edit tr.changed-row td.undo-container {
    display: unset;
    padding: 0px;
    margin: 0px;
  }
  table.occurrence-field-edit tr.changed-row td.undo-container div {
    color: #000;
    background: inherit;
    border:none;
    margin:0px;
    padding: 6px;
    padding-bottom:6px;
    padding-top:5px;
    font: inherit;
    /*border is optional*/
    cursor: pointer;
  }

  table.occurrence-field-edit tr.changed-row td.undo-container div.undo-button:hover {
    cursor: pointer;
    font-weight: bold;
    background: #ddd;
  }

  table.occurrence-field-edit tr.padding-below td {
    padding-bottom: 10px;
  }


  table.occurrence-field-edit tr.changed-row {
    background: #ebebeb;
    border-radius: 5px;
  }



</style>

<table  class="occurrence-field-edit">

  <%
  ClassEditTemplate.printOutClassFieldModifierRow((Object) occ, "habitat", out);
  %>

  <tr class="padding-below"><td></td></tr>

  <%
  String[] groupFields = {"groupSize", "groupBehavior", "numTerMales", "numBachMales", "numLactFemales", "numNonLactFemales"};
  ClassEditTemplate.printOutClassFieldModifierRows((Object) occ, groupFields, out);
  %>

  <tr class="padding-below"><td></td></tr>

  <%
  String[] locationFields = {"locationID", "decimalLatitude", "decimalLongitude"};
  ClassEditTemplate.printOutClassFieldModifierRows((Object) occ, locationFields, out);
  %>

  <tr class="padding-below"><td></td></tr>

  <%
  ClassEditTemplate.printOutClassFieldModifierRows((Object) occ, new String[]{"distance", "bearing"}, out);
  %>

</table>


<div class="submit" style="position:relative">
<input type="submit" name="save" value="Save" />
<span class="note" style="position:absolute;bottom:9"></span>
</div>

</form>
</div>
</div> <!--row -->

<script type="text/javascript">

var occFuncs = {};
occFuncs.checkIfOldFormValue = function(changedElem) {
  return ($(changedElem).attr("name").startsWith("oldValue-"));
}
occFuncs.checkIfOldFormValue$ = function($changedElem) {
  return (changedElem.attr("name").startsWith("oldValue-"));
}

occFuncs.markFormFieldNotOld = function(changedElem) {
  if (occFuncs.checkIfOldFormValue(changedElem)) {
    $(changedElem).attr("name",$(changedElem).attr("name").substring(9));
    $(changedElem).closest('tr').addClass("changed-row");
  }
}
occFuncs.markFormFieldOld$ = function($inputElem) {
  if (!occFuncs.checkIfOldFormValue($inputElem)){
    $inputElem.attr("name","oldValue-"+$inputElem.attr("name"));
  }

}

$(document).ready(function() {

  var changedFields = {};

  $("td.undo-container div.undo-button").click(function(event) {
    event.stopPropagation();
    var changedRow = $(this).closest('tr.changed-row');
    changedRow.removeClass('changed-row');
    var original = changedRow.attr('data-original-value');
    var correspondingInput = changedRow.find('td input');
    correspondingInput.val(original);
    occFuncs.markFormFieldOld$(correspondingInput);
  });

	$('#occform input,#occform select').change(function() {
    occFuncs.markFormFieldNotOld(this);
    var str = $(this).val();
    console.log('Change handler called on elem' + $(this).attr("name") + " to new val " + str);
    changedFields[$(this).attr("name")] = str;
		$('.submit').addClass('changes-made');
		$('.submit .note').html('changes made. please save.');
    console.log('changedFields = '+JSON.stringify(changedFields));
    <%  /*out.println("WHOAH WE HAVE A CHANGE HERE");*/
        System.out.println("OCCURRENCE.JSP: change detected in form (JS)");
    %>
	});
	$('span.relationship').hover(function(ev) {
//$('tr[data-indiv="07_091"]').hide();
console.log(ev);
		var jel = $(ev.target);
		if (ev.type == 'mouseenter') {
			var p = jel.data('partner');
			$('tr[data-indiv="' + p + '"]').addClass('rel-partner');
		} else {
			$('.rel-partner').removeClass('rel-partner');
		}
	});
	$('.enc-row').each(function(i, el) {
		var eid = el.getAttribute('data-id');
		el.setAttribute('title', 'click for: ' + eid);
	});
	$('.enc-row').click(function(el) {
		var eid = el.currentTarget.getAttribute('data-id');
		var w = window.open('encounters/encounter.jsp?number=' + eid, '_blank');
		w.focus();
		return false;
	});

	$('.col-sex').each(function(i, el) {
		var p = $('<select><option value="">select sex</option><option>unknown</option><option>male</option><option>female</option></select>');
		p.click( function(ev) { ev.stopPropagation(); } );
		p.change(function() {
			columnChange(this);
		});
		p.val($(el).html());
		$(el).html(p);
		//console.log('%o: %o', i, el);
	});

	$('.col-ageAtFirstSighting').each(function(i, el) {
		if (!$(el).parent().data('indiv')) return;
		var p = $('<input style="width: 30px;" placeholder="yrs" />');
		p.click( function(ev) { ev.stopPropagation(); } );
		p.change(function() {
			columnChange(this);
		});
		p.val($(el).html());
		$(el).html(p);
	});

	$('.col-zebraClass').each(function(i, el) {
		var p = $('<select><option value="Unknown">Unknown</option><option>LF</option><option>NLF</option><option>TM</option><option>BM</option><option>JUV</option><option>FOAL</option></select>');
		p.click( function(ev) { ev.stopPropagation(); } );
		p.change(function() {
			columnChange(this);
		});
		p.val($(el).html());
		$(el).html(p);
	});


});


function columnChange(el) {
	var jel = $(el);
	var prop = jel.parent().data('prop');
	var eid = jel.parent().parent().data('id');
	$('[name="' + eid + ':' + prop + '"]').remove();  //clear exisiting
	$('<input>').attr({
		name: eid + ':' + prop,
		type: 'hidden',
		value: jel.val(),
	}).appendTo($('#occform'));

	$('.submit').addClass('changes-made');
	$('.submit .note').html('changes made. please save.');

}


var relEid = false;
function relAdd(ev) {
console.log(ev);
	var jel = $(ev.target);
	var eid = jel.parent().parent().data('id');
	relEid = eid;
	ev.stopPropagation();
	$('#relationships-form input[type="text"]').val(undefined);
	$('#relationships-form select').val(undefined);
	$('#relationships-form').appendTo(ev.target).show();
	$('#relationships-form input[type="text"]').focus();
}

function relSave(ev) {
	ev.stopPropagation();
	if (!relEid) return;

	var partner = $('#rel-child-id').val();

	$('<input>').attr({
		name: relEid + ':_relMother',
		type: 'hidden',
		value: partner,
	}).appendTo($('#occform'));
	//$('#rel-child-id').val('');

	$('#row-enc-' + relEid + ' .col-relationships').prepend('<span data-partner="' + partner + '" class="relationship relType-familial relRole-mother">' + partner + '</span>');

	relEid = false;
	$('#relationships-form').hide();
	$('.submit').addClass('changes-made');
	$('.submit .note').html('changes made. please save.');
}

function relCancel(ev) {
	ev.stopPropagation();
	relEid = false;
	$('#relationships-form').hide();
}

</script>




<div id="dialogIndies" title="<%=props.getProperty("setIndividualCount") %>" style="display:none">

<table border="1" cellpadding="1" cellspacing="0" bordercolor="#FFFFFF" >

  <tr>
    <td align="left" valign="top">
      <form name="set_individualCount" method="post" action="OccurrenceSetIndividualCount">
            <input name="number" type="hidden" value="<%=request.getParameter("number")%>" />
            <%=props.getProperty("newIndividualCount") %>:

        <input name="count" type="text" id="count" size="5" maxlength="7"></input>
        <input name="individualCountButton" type="submit" id="individualCountName" value="<%=props.getProperty("set") %>">
        </form>
    </td>
  </tr>
</table>

                         		</div>
                         		<!-- popup dialog script -->
<script>
var dlgIndies = $("#dialogIndies").dialog({
  autoOpen: false,
  draggable: false,
  resizable: false,
  width: 600
});

$("a#indies").click(function() {
  dlgIndies.dialog("open");
});
</script>


</p>
<table id="encounter_report" width="100%">
<tr>

<td align="left" valign="top">

<p><strong><%=occ.getNumberEncounters()%>
</strong>
  <%=props.getProperty("numencounters") %>
</p>

<table style="border-spacing: 0;" id="results" width="100%">
  <tr class="lineitem">
      <td class="lineitem" align="left" valign="top" bgcolor="#99CCFF"><strong><%=props.getProperty("date") %></strong></td>
      <td class="lineitem" align="left" valign="top" bgcolor="#99CCFF"><strong>File name</strong></td>
    <td class="lineitem" align="left" valign="top" bgcolor="#99CCFF"><strong><%=props.getProperty("individualID") %></strong></td>


    <td class="lineitem" align="left" valign="top" bgcolor="#99CCFF"><strong><%=props.getProperty("sex") %></strong></td>
    <td class="lineitem" align="left" valign="top" bgcolor="#99CCFF"><strong>Age first sighted</strong></td>
    <td class="lineitem" align="left" valign="top" bgcolor="#99CCFF"><strong>Class</strong></td>

 <td class="lineitem" align="left" valign="top" bgcolor="#99CCFF"><strong>Mother of</strong></td>

  </tr>
  <%

    for (int i = 0; i < total; i++) {
      Encounter enc = dateSortedEncs[i];

        Vector encImages = enc.getAdditionalImageNames();
        String imgName = "";
				String encSubdir = enc.subdir();

				MarkedIndividual indiv = null;
    		if((enc.getIndividualID()!=null)&&(!enc.getIndividualID().toLowerCase().equals("unassigned"))){
					indiv = myShepherd.getMarkedIndividual(enc.getIndividualID());
				}

          imgName = "/"+CommonConfiguration.getDataDirectoryName(context)+"/encounters/" + encSubdir + "/thumb.jpg";

  %>
  <tr id="row-enc-<%=enc.getEncounterNumber()%>" class="enc-row" data-id="<%=enc.getEncounterNumber()%>" data-indiv="<%=((indiv == null) ? "" : enc.getIndividualID())%>">
      <td class="lineitem enc-date">
<%=enc.getDate()%>
			</td>
			<td class="lineitem enc-filename">
<div title="<%=enc.getImageOriginalName()%>"><%=((enc.getImageOriginalName() == null) ? "" : enc.getImageOriginalName())%></div>
    </td>
    <td class="lineitem">
    	<%
    	if (indiv != null) {
    	%>
    	<a target="_new" onClick="event.stopPropagation(); return true;" href="individuals.jsp?number=<%=enc.getIndividualID()%>"><%=enc.getIndividualID()%></a>
    	<%
    	}
    	else{
    	%>
    	&nbsp;
    	<%
    	}
    	%>
    </td>
<!--
    <td width="100" height="32px" class="lineitem">
    	<a href="http://<%=CommonConfiguration.getURLLocation(request)%>/encounters/encounter.jsp?number=<%=enc.getEncounterNumber()%>">

    		<%
    		//if the encounter has photos, show photo folder icon
    		if((enc.getImages()!=null) && (enc.getImages().size()>0)){
    		%>
    			<img src="images/Crystal_Clear_filesystem_folder_image.png" height="32px" width="*" />
    		<%
    		}

    		//if the encounter has a tissue sample, show an icon
    		if((enc.getTissueSamples()!=null) && (enc.getTissueSamples().size()>0)){
    		%>
    			<img src="images/microscope.gif" height="32px" width="*" />
    		<%
    		}
    		//if the encounter has a measurement, show the measurement icon
    		if(enc.hasMeasurements()){
    		%>
    			<img src="images/ruler.png" height="32px" width="*" />
        	<%
    		}
    		%>

    	</a>
    </td>
    <td class="lineitem"><a
      href="http://<%=CommonConfiguration.getURLLocation(request)%>/encounters/encounter.jsp?number=<%=enc.getEncounterNumber()%><%if(request.getParameter("noscript")!=null){%>&noscript=null<%}%>"><%=enc.getEncounterNumber()%>
    </a></td>
-->

<%
String sexValue="&nbsp;";
if(enc.getSex()!=null){sexValue=enc.getSex();}
%>
    <td data-prop="sex" class="col-sex lineitem"><%=sexValue %></td>


<%
	String ageAFS = "";
	if (indiv != null) {
		ageAFS = cleanString(indiv.getAgeAtFirstSighting());
	}
%>
<td class="col-ageAtFirstSighting lineitem" data-prop="ageAtFirstSighting"><%=ageAFS%></td>

<td class="col-zebraClass lineitem" data-prop="zebraClass"><%=cleanString(enc.getZebraClass())%></td>

  <td class="col-relationships lineitem">
    <%
	String iid = enc.getIndividualID();
	if ((iid != null) && !iid.equals("") && !iid.equals("Unassigned")) {
		ArrayList<Relationship> rels = myShepherd.getAllRelationshipsForMarkedIndividual(iid);
		if ((rels != null) && (rels.size() > 0)) {
			for (Relationship r : rels) {
				String partner = r.getMarkedIndividualName1();
				String role = r.getMarkedIndividualRole2();
				String type = r.getType();
				if (partner.equals(iid)) {
					partner = r.getMarkedIndividualName2();
					role = r.getMarkedIndividualRole1();
				}
				if (!role.equals("mother")) continue;  //for lewa, only showing offspring of mother
			%><span data-partner="<%=partner%>" class="relationship relType-<%=type%> relRole-<%=role%>"><%=partner%></span> <%
  			}
		}
  //private String markedIndividualName2;
  //private String markedIndividualRole2;
			%><span class="relationship-none" title="add a relationship" onClick="return relAdd(event);">add</span><%
	}
    %>
    </td>
  </tr>
  <%

    } //end for

  %>


</table>


<!-- Start thumbnail gallery -->

<br />
<p>
  <strong><%=props.getProperty("imageGallery") %>
  </strong></p>

    <%
    String[] keywords=keywords=new String[0];
		int numThumbnails = myShepherd.getNumThumbnails(occ.getEncounters().iterator(), keywords);
		if(numThumbnails>0){
		%>

<table id="results" border="0" width="100%">
    <%


			int countMe=0;
			//Vector thumbLocs=new Vector();
			List<SinglePhotoVideo> thumbLocs=new ArrayList<SinglePhotoVideo>();

			int  numColumns=3;
			int numThumbs=0;
			  if (CommonConfiguration.allowAdoptions(context)) {
				  List adoptions = myShepherd.getAllAdoptionsForMarkedIndividual(name,context);
				  int numAdoptions = adoptions.size();
				  if(numAdoptions>0){
					  numColumns=2;
				  }
			  }

			try {


			    Query query = myShepherd.getPM().newQuery("SELECT from org.ecocean.Encounter WHERE occurrenceID == \""+occ.getOccurrenceID()+"\"");
	        //query.setFilter("SELECT "+jdoqlQueryString);
	        query.setResult("catalogNumber");
	        Collection c = (Collection) (query.execute());
	        ArrayList<String> enclist = new ArrayList<String>(c);
	        query.closeAll();
		      thumbLocs=myShepherd.getThumbnails(myShepherd,request, enclist, 1, 99999, keywords);
			    numThumbs=thumbLocs.size();

			%>

  <tr valign="top">
 <td>
 <!-- HTML Codes by Quackit.com -->
<div style="text-align:left;border:1px solid black;width:100%;height:400px;overflow-y:scroll;overflow-x:scroll;">

      <%
      						while(countMe<numThumbs){
							//for(int columns=0;columns<numColumns;columns++){
								if(countMe<numThumbs) {
									//String combined ="";
									//if(myShepherd.isAcceptableVideoFile(thumbLocs.get(countMe).getFilename())){
									//	combined = "http://" + CommonConfiguration.getURLLocation(request) + "/images/video.jpg" + "BREAK" + thumbLocs.get(countMe).getCorrespondingEncounterNumber() + "BREAK" + thumbLocs.get(countMe).getFilename();
									//}
									//else{
									//	combined= thumbLocs.get(countMe).getCorrespondingEncounterNumber() + "/" + thumbLocs.get(countMe).getDataCollectionEventID() + ".jpg" + "BREAK" + thumbLocs.get(countMe).getCorrespondingEncounterNumber() + "BREAK" + thumbLocs.get(countMe).getFilename();

									//}

									//StringTokenizer stzr=new StringTokenizer(combined,"BREAK");
									//String thumbLink=stzr.nextToken();
									//String encNum=stzr.nextToken();
									//int fileNamePos=combined.lastIndexOf("BREAK")+5;
									//String fileName=combined.substring(fileNamePos).replaceAll("%20"," ");
									String thumbLink="";
									boolean video=true;
									if(!myShepherd.isAcceptableVideoFile(thumbLocs.get(countMe).getFilename())){
										thumbLink="/"+CommonConfiguration.getDataDirectoryName(context)+"/encounters/"+Encounter.subdir(thumbLocs.get(countMe).getCorrespondingEncounterNumber())+"/"+thumbLocs.get(countMe).getDataCollectionEventID()+".jpg";
										video=false;
									}
									else{
										thumbLink="http://"+CommonConfiguration.getURLLocation(request)+"/images/video.jpg";

									}
									String link="/"+CommonConfiguration.getDataDirectoryName(context)+"/encounters/"+Encounter.subdir(thumbLocs.get(countMe).getCorrespondingEncounterNumber())+"/"+thumbLocs.get(countMe).getFilename();

							%>



      <table align="left" width="<%=100/numColumns %>%">
        <tr>
          <td valign="top">

              <%
			if(isOwner){
												%>
            <a href="<%=link%>"
            <%
            if(thumbLink.indexOf("video.jpg")==-1){
            %>
            	class="highslide" onclick="return hs.expand(this)"
            <%
            }
            %>
            >
            <%
            }
             %>
              <img src="<%=thumbLink%>" alt="photo" border="1" title="Click to enlarge"/>
              <%
                if (isOwner) {
              %>
            </a>
              <%
			}

			%>

            <div
            <%
            if(!thumbLink.endsWith("video.jpg")){
            %>
            class="highslide-caption"
            <%
            }
            %>
            >

              <table>
                <tr>
                  <td align="left" valign="top">

                    <table>
                      <%

                        int kwLength = keywords.length;
                        Encounter thisEnc = myShepherd.getEncounter(thumbLocs.get(countMe).getCorrespondingEncounterNumber());
                      %>



                      <tr>
                        <td><span
                          class="caption"><%=props.getProperty("location") %>: <%=thisEnc.getLocation() %></span>
                        </td>
                      </tr>
                      <tr>
                        <td><span
                          class="caption"><%=props.getProperty("locationID") %>: <%=thisEnc.getLocationID() %></span>
                        </td>
                      </tr>
                      <tr>
                        <td><span
                          class="caption"><%=props.getProperty("date") %>: <%=thisEnc.getDate() %></span>
                        </td>
                      </tr>
                      <tr>
                        <td><span class="caption"><%=props.getProperty("catalogNumber") %>: <a
                          href="encounters/encounter.jsp?number=<%=thisEnc.getCatalogNumber() %>"><%=thisEnc.getCatalogNumber() %>
                        </a></span></td>
                      </tr>
                        <tr>
                        <td><span class="caption"><%=props.getProperty("individualID") %>:

                        <%
                        		if((thisEnc.getIndividualID()!=null)&&(!thisEnc.getIndividualID().toLowerCase().equals("unassigned"))){
                        		%>
                        			<a href="individuals.jsp?number=<%=thisEnc.getIndividualID() %>"><%=thisEnc.getIndividualID() %></a>
                        		<%
                        		}
                        		%>

                        </span></td>
                      </tr>
                      <%
                        if (thisEnc.getVerbatimEventDate() != null) {
                      %>
                      <tr>

                        <td><span
                          class="caption"><%=props.getProperty("verbatimEventDate") %>: <%=thisEnc.getVerbatimEventDate() %></span>
                        </td>
                      </tr>
                      <%
                        }
                      %>
                      <tr>
                        <td><span class="caption">
											<%=props.getProperty("matchingKeywords") %>
											<%
											 //while (allKeywords2.hasNext()) {
					                          //Keyword word = (Keyword) allKeywords2.next();


					                          //if (word.isMemberOf(encNum + "/" + fileName)) {
											  //if(thumbLocs.get(countMe).getKeywords().contains(word)){

					                            //String renderMe = word.getReadableName();
												List<Keyword> myWords = thumbLocs.get(countMe).getKeywords();
												int myWordsSize = (myWords != null) ? myWords.size() : 0;
					                            for (int kwIter = 0; kwIter<myWordsSize; kwIter++) {
					                              //String kwParam = keywords[kwIter];
					                              //if (kwParam.equals(word.getIndexname())) {
					                              //  renderMe = "<strong>" + renderMe + "</strong>";
					                              //}
					                      		 	%>
					 								<br/><%= ("<strong>" + myWords.get(kwIter).getReadableName() + "</strong>")%>
					 								<%
					                            }




					                          //    }
					                       // }

                          %>
										</span></td>
                      </tr>
                    </table>
                    <br/>

                    <%
                      if (CommonConfiguration.showEXIFData(context)) {

            	if(!thumbLink.endsWith("video.jpg")){
           		 %>
					<span class="caption">
						<div class="scroll">
						<span class="caption">
					<%
            if ((thumbLocs.get(countMe).getFilename().toLowerCase().endsWith("jpg")) || (thumbLocs.get(countMe).getFilename().toLowerCase().endsWith("jpeg"))) {
              File exifImage = new File(encountersDir.getAbsolutePath() + "/" + Encounter.subdir(thisEnc.getCatalogNumber()) + "/" + thumbLocs.get(countMe).getFilename());
              	%>
            	<%=Util.getEXIFDataFromJPEGAsHTML(exifImage) %>
            	<%
               }
                %>


   								</span>
            </div>
   								</span>
   			<%
            	}
   			%>


                  </td>
                  <%
                    }
                  %>
                </tr>
              </table>
            </div>


</td>
</tr>

 <%
            if(!thumbLink.endsWith("video.jpg")){
 %>
<tr>
  <td><span class="caption"><%=props.getProperty("location") %>: <%=thisEnc.getLocation() %></span>
  </td>
</tr>
<tr>
  <td><span
    class="caption"><%=props.getProperty("locationID") %>: <%=thisEnc.getLocationID() %></span></td>
</tr>
<tr>
  <td><span class="caption"><%=props.getProperty("date") %>: <%=thisEnc.getDate() %></span></td>
</tr>
<tr>
  <td><span class="caption"><%=props.getProperty("catalogNumber") %>: <a
    href="encounters/encounter.jsp?number=<%=thisEnc.getCatalogNumber() %>"><%=thisEnc.getCatalogNumber() %>
  </a></span></td>
</tr>
                        <tr>
                        	<td>
                        		<span class="caption"><%=props.getProperty("individualID") %>:
                        		<%
                        		if((thisEnc.getIndividualID()!=null)&&(!thisEnc.getIndividualID().toLowerCase().equals("unassigned"))){
                        		%>
                        			<a href="individuals.jsp?number=<%=thisEnc.getIndividualID() %>"><%=thisEnc.getIndividualID() %></a>
                        		<%
                        		}
                        		%>
                        		</span>
                        	</td>
                      </tr>
<tr>
  <td><span class="caption">
											<%=props.getProperty("matchingKeywords") %>
											<%
                        //int numKeywords=myShepherd.getNumKeywords();
											 //while (allKeywords2.hasNext()) {
					                          //Keyword word = (Keyword) allKeywords2.next();


					                          //if (word.isMemberOf(encNum + "/" + fileName)) {
											  //if(thumbLocs.get(countMe).getKeywords().contains(word)){

					                            //String renderMe = word.getReadableName();
												//List<Keyword> myWords = thumbLocs.get(countMe).getKeywords();
												//int myWordsSize=myWords.size();
					                            for (int kwIter = 0; kwIter<myWordsSize; kwIter++) {
					                              //String kwParam = keywords[kwIter];
					                              //if (kwParam.equals(word.getIndexname())) {
					                              //  renderMe = "<strong>" + renderMe + "</strong>";
					                              //}
					                      		 	%>
					 								<br/><%= ("<strong>" + myWords.get(kwIter).getReadableName() + "</strong>")%>
					 								<%
					                            }




					                          //    }
					                       // }

                          %>
										</span></td>
</tr>
<%

            }
%>
</table>

<%

      countMe++;
    } //end if
  } //endFor
%>
</div>

</td>
</tr>
<%



} catch (Exception e) {
  e.printStackTrace();
%>
<tr>
  <td>
    <p><%=props.getProperty("error")%>
    </p>.
  </td>
</tr>
<%
  }
%>

</table>
</div>
<%
} else {
%>

<p><%=props.getProperty("noImages")%></p>

<%
  }
%>

</table>
<!-- end thumbnail gallery -->



<br/>



<%

  if (isOwner) {
%>
<br />


<br />
<p><img align="absmiddle" src="images/Crystal_Clear_app_kaddressbook.gif"> <strong><%=props.getProperty("researcherComments") %>
</strong>: </p>

<div style="text-align:left;border:1px solid black;width:100%;height:400px;overflow-y:scroll;overflow-x:scroll;">

<p><%=occ.getComments().replaceAll("\n", "<br>")%>
</p>
</div>
<%
  if (CommonConfiguration.isCatalogEditable(context)) {
%>
<p>

<form action="OccurrenceAddComment" method="post" name="addComments">
  <input name="user" type="hidden" value="<%=request.getRemoteUser()%>" id="user">
  <input name="number" type="hidden" value="<%=occ.getOccurrenceID()%>" id="number">
  <input name="action" type="hidden" value="comments" id="action">

  <p><textarea name="comments" cols="60" id="comments"></textarea> <br>
    <input name="Submit" type="submit" value="<%=props.getProperty("addComments") %>">
</form>
</p>
<%
    } //if isEditable


  } //if isOwner
%>


</p>


</td>
</tr>


</table>

</td>
</tr>
</table>


<br />
<table>
<tr>
<td>

      <jsp:include page="individualMapEmbed.jsp" flush="true">
        <jsp:param name="occurrence_number" value="<%=name%>"/>
      </jsp:include>
</td>
</tr>
</table>
<%

}

//could not find the specified individual!
else {



%>


<p><%=props.getProperty("matchingRecord") %>:
<br /><strong><%=request.getParameter("number")%>
</strong><br/><br />
  <%=props.getProperty("tryAgain") %>
</p>


<%
      }
	  %>
      </td>
</tr>
</table>




      <%

  } catch (Exception eSharks_jsp) {
    System.out.println("Caught and handled an exception in occurrence.jsp!");
    eSharks_jsp.printStackTrace();
  }



  myShepherd.rollbackDBTransaction();
  myShepherd.closeDBTransaction();

%>
</div><!-- end maintext -->
</div><!-- end main-wide -->

<div id="relationships-form" onClick="event.stopPropagation(); return false;">
	<div class="rel-sub">
	<b>Mother</b> of individual ID:<br />
	<input type="text" id="rel-child-id" />
	</div>

	<input type="button" value="OK" onClick="return relSave(event)" />

	<input type="button" value="cancel" onClick="return relCancel(event)" />
</div>

</div>
<jsp:include page="footer.jsp" flush="true"/>
