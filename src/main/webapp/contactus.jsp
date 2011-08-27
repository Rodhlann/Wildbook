<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
        <%@ page contentType="text/html; charset=utf-8" language="java" import="java.util.Properties, java.io.FileInputStream, java.io.File, java.io.FileNotFoundException" %>
<%

//setup our Properties object to hold all properties
	Properties props=new Properties();
	String langCode="en";
	
	//check what language is requested
	if(request.getParameter("langCode")!=null){
		if(request.getParameter("langCode").equals("fr")) {langCode="fr";}
		if(request.getParameter("langCode").equals("de")) {langCode="de";}
		if(request.getParameter("langCode").equals("es")) {langCode="es";}
	}
	
	//set up the file input stream
	//FileInputStream propsInputStream=new FileInputStream(new File((new File(".")).getCanonicalPath()+"/webapps/ROOT/WEB-INF/classes/bundles/"+langCode+"/submit.properties"));
	//props.load(propsInputStream);
	props.load(getClass().getResourceAsStream("/bundles/"+langCode+"/submit.properties"));

	
	//load our variables for the submit page
	String title=props.getProperty("submit_title");
	String submit_maintext=props.getProperty("submit_maintext");
	String submit_reportit=props.getProperty("reportit");
	String submit_language=props.getProperty("language");
	String what_do=props.getProperty("what_do");
	String read_overview=props.getProperty("read_overview");
	String see_all_encounters=props.getProperty("see_all_encounters");
	String see_all_sharks=props.getProperty("see_all_sharks");
	String report_encounter=props.getProperty("report_encounter");
	String log_in=props.getProperty("log_in");
	String contact_us=props.getProperty("contact_us");
	String search=props.getProperty("search");
	String encounter=props.getProperty("encounter");
	String shark=props.getProperty("shark");
	String join_the_dots=props.getProperty("join_the_dots");
	String menu=props.getProperty("menu");
	String last_sightings=props.getProperty("last_sightings");
	String more=props.getProperty("more");
	String ws_info=props.getProperty("ws_info");
	String about=props.getProperty("about");
	String contributors=props.getProperty("contributors");
	String forum=props.getProperty("forum");
	String blog=props.getProperty("blog");
	String area=props.getProperty("area");
	String match=props.getProperty("match");
	
	//link path to submit page with appropriate language
	String submitPath="submit.jsp?langCode="+langCode;
	
%>

<html>
<head>
<title>ECOCEAN - Contact Us</title>
<meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
<meta name="Description" content="The ECOCEAN Whale Shark Photo-identification Library is a visual database of whale shark (Rhincodon typus) encounters and of individually catalogued whale sharks. The library is maintained and used by marine biologists to collect and analyse whale shark encounter data to learn more about these amazing creatures." />
<meta name="Keywords" content="whale shark,whale,shark,Rhincodon typus,requin balleine,Rhineodon,Rhiniodon,big fish,ECOCEAN,Brad Norman, fish, coral, sharks, elasmobranch, mark, recapture, photo-identification, identification, conservation, citizen science" />
<meta name="Author" content="ECOCEAN - info@ecocean.org" />
<link href="css/ecocean.css" rel="stylesheet" type="text/css" />
<link rel="shortcut icon" href="images/favicon.ico" />

</head>

<body>
<div id="wrapper">
<div id="page">
<jsp:include page="header.jsp" flush="true">
	<jsp:param name="isResearcher" value="<%=request.isUserInRole(\"researcher\")%>"/>
	<jsp:param name="isManager" value="<%=request.isUserInRole(\"manager\")%>"/>
	<jsp:param name="isReviewer" value="<%=request.isUserInRole(\"reviewer\")%>"/>
	<jsp:param name="isAdmin" value="<%=request.isUserInRole(\"admin\")%>"/>
</jsp:include>	
<div id="main">
	<div id="leftcol">
		<div id="menu">

						
			<div class="module">
				<img src="images/area.jpg" width="190" height="115" border="0" title="Area to photograph" alt="Area to photograph" />
				<p class="caption"><%=area%></p>
			</div>
						
			<div class="module">
				<img src="images/match.jpg" width="190" height="94" border="0" title="We Have A Match!" alt="We Have A Match!" />
				<p class="caption"><%=match%></p>
			</div>
						
<jsp:include page="awards.jsp" flush="true" />	
		</div><!-- end menu -->
	</div><!-- end leftcol -->
	<div id="maincol-wide">

		<div id="maintext">
		  <h1 class="intro">Contact us </h1>
		</div>
			
		<p>We welcome your comments and questions, though we are currently unable to respond to every email.</p>
		<p><strong>Media questions</strong></p>
		<p>If you are a journalist, writer or documentary filmmaker, we want to hear from you.</p>
		<p>ECOCEAN USA is always hoping for opportunities to better tell the story of whale sharks and the growing body of research and discoveries made possible by dedicated scientists, volunteers, and the general public.</p>
		<p>Please contact us at <em>media at whaleshark dot org</em>.</p>
		<p><strong>Web site questions</strong></p>
		<p>If you have technical questions about this web site, please contact <em>webmaster at whaleshark dot org</em>. </p>
		<p><strong>General questions</strong></p>
		<p>If you have general questions about whale sharks or our research, please contact <em>info at whaleshark dot org</em>.  </p>
	</div>
	<!-- end maintext -->

  </div><!-- end maincol -->

<jsp:include page="footer.jsp" flush="true" />
</div><!-- end page -->
</div><!--end wrapper -->
</body>
</html>
