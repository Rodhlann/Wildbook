<%@ page contentType="text/html; charset=utf-8" language="java" import="org.ecocean.servlet.ServletUtilities,java.util.Properties, java.io.FileInputStream, java.io.File, java.io.FileNotFoundException, org.ecocean.*" %>
<%

//setup our Properties object to hold all properties
	
	
	String context="context0";
	context=ServletUtilities.getContext(request);
	
%>


<jsp:include page="header.jsp" flush="true"/>

<div class="container maincontent">
		  <h2>Photography Guidelines for Individual Identification with Computer Vision</h2>
	<p>Best practices can vary by species and location. For general information, see the <a href="https://wildbook.docs.wildme.org/data/photography-guidelines.html">Photography Guidelines</a>.</p>
			
	
	</div>
	

<jsp:include page="footer.jsp" flush="true" />

