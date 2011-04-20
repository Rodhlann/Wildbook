<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
        <%@ page contentType="text/html; charset=utf-8" language="java" import="java.util.Properties, java.io.FileInputStream, java.io.File, java.io.FileNotFoundException, org.ecocean.*" %>
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
<title><%=CommonConfiguration.getHTMLTitle() %></title>
<meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
<meta name="Description" content="<%=CommonConfiguration.getHTMLDescription() %>" />
<meta name="Keywords" content="<%=CommonConfiguration.getHTMLKeywords() %>" />
<meta name="Author" content="<%=CommonConfiguration.getHTMLAuthor() %>" />
<link href="<%=CommonConfiguration.getCSSURLLocation(request) %>" rel="stylesheet" type="text/css" />
<link rel="shortcut icon" href="<%=CommonConfiguration.getHTMLShortcutIcon() %>" />


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
		  <h1 class="intro">Publications</h1>
		  <ul>
		  <li><a href="#brochure">Brochure</a></li>
		  <li><a href="#scipubs">Scientific publications</a></li>
		  <li><a href="#press">Past press clippings</a></li>
		  </ul>
		</div>
		
		<a name="brochure"></a><strong>Brochure</strong>
		<p>The <a href="ECOCEAN_Brochure.pdf">ECOCEAN brochure</a> provides more information about the mission of ECOCEAN.</a></p>
		
		<a name="scipubs"></a><strong>Scientific publications</strong>
		<p><em>The following reports and publications have either directly used data from the ECOCEAN Library or contributed to its ultimate development and launch in 2003.</em></p>
		<p>Catlin J, Jones T, Norman B &amp; Wood D (in press). Consolidation in a wildlife tourism industry: the changing impact of whale shark tourist expenditure in the Ningaloo Coast region. <em>International Journal of Tourism Research</em>. </p>
		<p>Catlin J, Jones R, Jones T, Norman B and Wood D (in press). Discovering Wildlife Tourism: A Whale Shark Tourism Case Study. <em>Current Issues in Tourism</em>.</p>
		<p>Jones T, Wood D, Catlin J &amp; Norman B (2009). Expenditure and ecotourism: predictors of expenditure for whale shark tour participants. <em>Journal of Ecotourism</em> Volume 8, Issue 1: 32-50.</p>
		<p>Norman B (2009) ECOCEAN Best Practice Whale Shark Ecotourism UNEP MANUAL. Technical Report (United Nations Environment Program - Regional Seas) 7pp.<br />
	      <a href="ECOCEAN%20Best%20Practice%20Whale%20Shark%20Ecotourism%20UNEP%20MANUAL.pdf">Web link</a>.		</p>
		<p>Holmberg J &amp; Norman B (2009) ECOCEAN Whale Shark Photo-identification - UNEP MANUAL. Technical Report (United Nations Environment Program - Regional Seas) 69pp.<br />
	    <a href="ECOCEAN%20Whale%20Shark%20Photo-identification%20UNEP%20MANUAL.pdf">Web link</a>.		</p>
		<p>Holmberg J, Norman B &amp; Arzoumanian Z (2009) Estimating population size, structure, and residency time for whale sharks Rhincodon typus through collaborative photo-identification. <em>Endangered Species Research, </em> (7) 39-53.<br /> 
	      <a href="http://www.int-res.com/articles/esr2009/7/n007p039.pdf">Web link</a>. </p>
		<p>Jones T, Wood D, Catlin J &amp; Norman, B (2009) Expenditure and ecotourism: predictors of expenditure for whale shark tour participants. <em>Journal of Ecotourism</em>, (8) 32-50. <a href="http://www.informaworld.com/smpp/content%7Edb=all?content=10.1080/14724040802517922"><br />
	    Web link</a>. </p>
		<p>Gleiss AC, Norman B, Liebsch N, Francis C &amp; Wilson RP (2009) A new prospect for tagging large free-swimming sharks with motion-sensitive data-loggers. <em>Fisheries Research </em>97: 11-16. <a href="http://www.sciencedirect.com/science?_ob=ArticleURL&_udi=B6T6N-4V7MSDP-1&_user=10&_coverDate=04%2F30%2F2009&_rdoc=4&_fmt=high&_orig=browse&_srch=doc-info(%23toc%235035%232009%23999029998%23980057%23FLA%23display%23Volume)&_cdi=5035&_sort=d&_docanchor=&_ct=22&_acct=C000050221&_version=1&_urlVersion=0&_userid=10&md5=3102bda502b5793b48f2b8eb52773d1c"><br />
	    Web link</a>. </p>
		<p>Holmberg J, Norman B &amp; Arzoumanian Z (2008) Robust, comparable population metrics through collaborative photo-monitoring of whale sharks <em>Rhincodon typus </em>. <em>Ecological Applications </em> 18(1): 222-223. <a href="http://www.esajournals.org/doi/abs/10.1890/07-0315.1"><br />
	    Web link</a>. </p>
		<p>Norman B. &amp; Holmberg J (2007) A Cooperative Approach for Generating Robust Population Metrics for Whale Sharks <em>Rhincodon typus. </em> In: Maldini D, Meck Maher D, Troppoli D, Studer M, and Goebel J, editors. Translating Scientific Results into Conservation Actions: New Roles, Challenges and Solutions for 21st Century Scientists. Boston : Earthwatch Institute; 2007. <a href="Norman_Holmberg_Earthwatch_2007.pdf"><br />
	    Web link</a>. </p>
		<p>Norman B &amp; Stevens J (2007) Size and maturity status of the whale shark ( <em>Rhincodon typus </em>) at Ningaloo Reef in Western Australia. <em>Fisheries Research </em>Vol. 84, Issue 1, 1-136. Whale Sharks: Science, Conservation and Management - Proceedings of the First International Whale Shark Conference, First International Whale Shark Conference Australia 09-12 May 2005. T. R. Irvine and J. K. Keesing (Eds). <a href="http://www.sciencedirect.com/science?_ob=ArticleURL&_udi=B6T6N-4MC12HB-K&_user=10&_rdoc=1&_fmt=&_orig=search&_sort=d&view=c&_acct=C000050221&_version=1&_urlVersion=0&_userid=10&md5=03c783c026ce09b67f822ae3d7341a74"><br />
	    Web link</a>. </p>
		<p>Norman B &amp; Catlin J (2007) Economic importance of conserving whale sharks. Unpublished Report for the International Fund for Animal Welfare (IFAW), Sydney 18pp. <strong></strong></p>
		<p>Arzoumanian Z, Holmberg J &amp; Norman B (2005) An astronomical pattern-matching algorithm for computer-aided identification of whale sharks <em>Rhincodon typus </em>. <em>Journal of Applied Ecology </em> 42, 999-1011. <a href="http://www3.interscience.wiley.com/journal/118735310/abstract?CRETRY=1&SRETRY=0"><br />
	    Web link</a>. </p>
		<p>Norman BM (2005) Whale shark critical habitats and movement patterns within Australian waters. <em>Technical Report (DEH Natural Heritage Trust Project) </em>46pp. </p>
		<p>Norman BM (2004) Review of the current conservation concerns for the whale shark ( <em>Rhincodon typus </em>): A regional perspective. <em>Technical Report (NHT Coast &amp; Clean Seas Project No. 2127) </em>74pp. <em></em></p>
		<p>Norman B (2002) CITES Identification Manual: Whale Shark ( <em>Rhincodon typus </em> Smith 1829). Commonwealth of Australia. <a href="http://www.environment.gov.au/coasts/publications/whale-shark-id/index.html"><br />
	    Web link</a>. </p>
		<p>Norman BM, Newbound D &amp; Knott B (2000) A new species of Pandaridae (Copepoda), from the whale shark <em>Rhincodon typus </em> (Smith) . <em>Journal of Natural History </em> 34:3, 355-366. <a href="http://www.ingentaconnect.com/content/tandf/tnah/2000/00000034/00000003/art00004?token=0044129e186720297d76253e7b2a4a467a24425e3b6b6d3f4e4b252493777d450b13"><br />
	    Web link</a>. </p>
		<p>Norman BM (2000) In: <em>2000 IUCN Red List of Threatened Species. </em> IUCN, Gland, Switzerland and Cambridge, UK. Xviii+61 pp. (Book &amp; CD). </p>
		<p>Norman BM (1999) Aspects of the biology and ecotourism industry of the whale shark <em>Rhincodon typus </em>in north-western Australia. MPhil. Thesis (Murdoch University, Western Australia). <a href="http://wwwlib.murdoch.edu.au/adt/browse/view/adt-MU20071003.121017"><br />
	    Web link</a>. </p>
		<p>Gunn JS, Stevens JD, Davis TLO &amp; Norman BM (1999) Observations on the short-term movements and behaviour of whale sharks ( <em>Rhincodon typus </em>) at Ningaloo Reef, Western Australia. <em>Mar. Biol </em>. 135: 553-559. <a href="http://www.springerlink.com/content/68mmnfxa2vprhp7a/"><br />
	    Web link</a>. </p>
		
		<p><a name="press"></a><strong>Past press clippings</strong>		    </p>
		<p><span class="caption"><strong>Maneuvering "like fighter pilots"</strong><br />
	      <br>
          <a href="http://www.esajournals.org/perlserv/?request=get-abstract&doi=10.1890%2F07-0315.1"><img src="images/news_flying.jpg" alt="Ecological Applications publication" width="77" height="77" hspace="3" vspace="3" border="0" align="left" title="Latest scientific publication" /></a> Rolex Laureates and ECOCEAN take <a href="http://www.sciencealert.com.au/news/20081706-17506-2.html">a new look at whale shark motion</a>. <br />
          </span>
	        <br />
        </p>
		<p>&nbsp;</p>
	</div>
	<!-- end maintext -->

  </div><!-- end maincol -->

<jsp:include page="footer.jsp" flush="true" />
</div>
<!-- end page -->
</div><!--end wrapper -->
</body>
</html>
