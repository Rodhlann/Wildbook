<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN"
        "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<%@ page contentType="text/html; charset=utf-8" language="java" import="org.joda.time.LocalDateTime,
org.joda.time.format.DateTimeFormatter,
org.joda.time.format.ISODateTimeFormat,java.net.*,
org.ecocean.grid.*,
org.ecocean.servlet.ServletUtilities,
java.io.*,java.util.*,
java.io.FileInputStream,
java.io.File,
java.io.FileNotFoundException,
org.ecocean.*,
org.ecocean.servlet.*,
javax.jdo.*,
java.lang.StringBuffer,
java.util.Vector,
java.util.Iterator,
java.lang.NumberFormatException"%>

<%
String context="context0";
context=ServletUtilities.getContext(request);
Shepherd myShepherd=new Shepherd(context);
User currentUser = null;
myShepherd.setAction("myUsers.jsp");
myShepherd.beginDBTransaction();
int numFixes=0;
String urlLoc = "//" + CommonConfiguration.getURLLocation(request);
//TODO which of the above not needed?
%>
<jsp:include page="../header.jsp" flush="true"/>
<link rel="stylesheet" href="<%=urlLoc %>/cust/mantamatcher/css/manta.css"/>
<style type="text/css">
  #candidate-block {
    color: #000;
    border-bottom: 1px solid #CDCDCD;
    margin: 12px 0px 0px 0px;
    padding: 0px;
    z-index: 1;
    padding-left: 10px
  }

</style>
<%
try{
  currentUser = AccessControl.getUser(request, myShepherd);
  %>
  <div class="container maincontent">
    <div id="content-container">
      <!-- js-generated html goes here -->
    </div>
    <script>
    let txt = getText("myUsers.properties");
    $(document).ready(function() {
      let userDuplicateJsonRequest = {};
      userDuplicateJsonRequest['username'] = '<%= currentUser.getUsername()%>';
      console.log("userDuplicateJsonRequest is: ")
      console.log(userDuplicateJsonRequest);
      if(userDuplicateJsonRequest){
        populatePage();
        doAjaxForDuplicateUsers(userDuplicateJsonRequest);
      }
    });

    function doAjaxForDuplicateUsers(userDuplicateJsonRequest){
      $.ajax({
      url: wildbookGlobals.baseUrl + '../UserConsolidate',
      type: 'POST',
      data: JSON.stringify(userDuplicateJsonRequest),
      dataType: 'json',
      contentType: 'application/json',
      success: function(data) {
          console.log("data coming back is:");
          console.log(data);
          let users = data.users;
          if(users && users.length>0){
            for(let i=0; i<users.length; i++){
              populateCandidateUser(users[i].username, users[i].email,users[i].fullname);
            }
          }
          // incrementalIdResults = data.incrementalIdArr;
          // if(incrementalIdResults && incrementalIdResults.length>0){
          //   if(countOfIncrementalIdRowPopulated > 22){
          //   }
          //   populateEncounterRowWithIncrementalId(incrementalIdResults, encounters, currentEncounterIndex);
          //   if(countOfIncrementalIdRowPopulated == encounters.length){
          //     //everything is populated! -MF
          //     $('#progress-div').hide();
          //     $('#table-div').show();
          //   }
          // }
          },
          error: function(x,y,z) {
              console.warn('%o %o %o', x, y, z);
          }
      });
    }

    function populateCandidateUser(username, email, fullname){
      let candidateHtml = '';
      candidateHtml += '<div class="candidate-block">';
      candidateHtml += '<p><strong>';
      candidateHtml += txt.username;
      candidateHtml += '</strong> ';
      if(username){
        candidateHtml += username;
      }else{
        candidateHtml += '-';
      }
      candidateHtml += '</p>';
      candidateHtml += '<p><strong>';
      candidateHtml += txt.email;
      candidateHtml += '</strong> ';
      if(email){
        candidateHtml += email;
      }else{
        candidateHtml += '-';
      }
      candidateHtml += '</p>';
      candidateHtml += '<p><strong>';
      candidateHtml += txt.name;
      candidateHtml += '</strong> ';
      if(fullname){
        candidateHtml += fullname;
      }else{
        candidateHtml += '-';
      }
      candidateHtml += '</p>';
      candidateHtml += '</div>';
      $('#content-container').append(candidateHtml);
    }

    function populatePage(){
      console.log("got here 2");
      $('#title').html(txt.title);
      let pageHtml = '';
      pageHtml += '<p>Hi</p>';
      pageHtml += '<div id="candidate-users-container">';
      pageHtml += '</div>';
      // pageHtml += '<p>';
      // pageHtml += txt.username;
      // pageHtml += '</p>';
      // pageHtml += '<p>';
      // pageHtml += txt.email;
      // pageHtml += '</p>';
      // pageHtml += '<p>';
      // pageHtml += txt.name;
      // pageHtml += '</p>';
      $('#content-container').empty();
      $('#content-container').append(pageHtml);
    }
    </script>

  </div>
  <%
}
catch(Exception e){
  myShepherd.rollbackDBTransaction();
}
finally{
  myShepherd.closeDBTransaction();
}
%>
<jsp:include page="../footer.jsp" flush="true"/>
