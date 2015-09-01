<%@ page contentType="text/html; charset=utf-8" language="java"
         import="org.ecocean.servlet.ServletUtilities,org.ecocean.CommonConfiguration" %>

<%

String context="context0";
context=ServletUtilities.getContext(request);
  //handle some cache-related security
  response.setHeader("Cache-Control", "no-cache"); //Forces caches to obtain a new copy of the page from the origin server
  response.setHeader("Cache-Control", "no-store"); //Directs caches not to store the page under any circumstance
  response.setDateHeader("Expires", 0); //Causes the proxy cache to see the page as "stale"
  response.setHeader("Pragma", "no-cache"); //HTTP 1.0 backward compatibility


%>

    <jsp:include page="../header.jsp" flush="true" />
    
        <div class="container maincontent">
          <table border="0">
            <tr>
              <td>
                <h1 class="intro">Delete an adoption</h1>

                <p>You are about to <strong>DELETE</strong> an adoption from the
                  database. If you choose <strong>Permanently delete</strong>, all data
                  contained within this adoption will be removed from the database<em>.
                    However, the webmaster can restore the adoption in case you
                    accidentally delete it </em>. Choose <strong>Cancel</strong> to retain the
                  adoption in the database as is.</p>
              </td>
            </tr>
            <tr>
              <td>
                <p>Do you want to reject adoption <%=request.getParameter("number")%>?</p>
                <table width="400" border="0" cellpadding="5" cellspacing="0">
                  <tr>
                    <td align="center" valign="top">
                      <form name="reject_form" method="post" action="../DeleteAdoption">
                        <input name="action" type="hidden" id="action" value="reject">
                        <input name="number" type="hidden"
                               value=<%=request.getParameter("number")%>> <input
                        name="yes" type="submit" id="yes" value="Permanently delete"></form>
                    </td>
                    <td align="left" valign="top">
                      <form name="form2" method="get" action="adoption.jsp"><input
                        name="number" type="hidden"
                        value=<%=request.getParameter("number")%>> <input name="no"
                                                                          type="submit" id="no"
                                                                          value="Cancel"></form>
                    </td>
                  </tr>
                </table>
              </td>
            </tr>
          </table>

        </div>
       
        
      <jsp:include page="../footer.jsp" flush="true"/>

