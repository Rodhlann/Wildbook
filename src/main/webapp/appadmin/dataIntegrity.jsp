<%@ page contentType="text/html; charset=iso-8859-1" language="java"
         import="org.ecocean.servlet.ServletUtilities,org.ecocean.*,java.util.Properties" %>



<%

String context="context0";
context=ServletUtilities.getContext(request);

String langCode=ServletUtilities.getLanguageCode(request);
Properties props = new Properties();
props = ShepherdProperties.getProperties("dataIntegrity.properties", langCode, context);

%>

<jsp:include page="../header.jsp" flush="true" />

	<div class="container maincontent">
	     
	
	      <h1><%=props.getProperty("dataIntegrity") %></h1>
	     
		<h3><%=props.getProperty("check4annots") %></h3>
		<p><%=props.getProperty("description0") %></p>
		<p><a target="_blank" href="sharedAnnotations.jsp"><%=props.getProperty("clickHere") %></a></p>      

	
	<h3>Check Annotation iaClasses and MediaAsset States by Species</h3>
<p>Old iaClasses on annotations and media assets stuck in a "pending" state can cause poor matching performance as they are ignored.</p>
<p><a target="_blank" href="iaBreakdownBySpecies.jsp">Click here to check</a></p>      

	
	</div>

<jsp:include page="../footer.jsp" flush="true"/>



