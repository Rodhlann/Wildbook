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
<%@ page contentType="text/html; charset=utf-8" language="java"
         import="org.ecocean.CommonConfiguration,org.ecocean.Keyword,org.ecocean.Shepherd, javax.jdo.Extent, javax.jdo.Query" %>
<%@ page import="java.util.GregorianCalendar" %>
<%@ page import="java.util.Iterator" %>
<%@ page import="java.util.Properties" %>

<html>
<head>
  <title><%=CommonConfiguration.getHTMLTitle() %>
  </title>
  <meta http-equiv="Content-Type" content="text/html; charset=utf-8"/>
  <meta name="Description"
        content="<%=CommonConfiguration.getHTMLDescription() %>"/>
  <meta name="Keywords"
        content="<%=CommonConfiguration.getHTMLKeywords() %>"/>
  <meta name="Author" content="<%=CommonConfiguration.getHTMLAuthor() %>"/>
  <link href="<%=CommonConfiguration.getCSSURLLocation(request) %>"
        rel="stylesheet" type="text/css"/>
  <link rel="shortcut icon"
        href="<%=CommonConfiguration.getHTMLShortcutIcon() %>"/>
</head>
<%
  GregorianCalendar cal = new GregorianCalendar();
  int nowYear = cal.get(1);
  int firstYear = 1980;

  Shepherd myShepherd = new Shepherd();
  Extent allKeywords = myShepherd.getPM().getExtent(Keyword.class, true);
  Query kwQuery = myShepherd.getPM().newQuery(allKeywords);
  myShepherd.beginDBTransaction();
  try {
    firstYear = myShepherd.getEarliestSightingYear();
    nowYear = myShepherd.getLastSightingYear();
  } catch (Exception e) {
    e.printStackTrace();
  }

//let's load thumbnailSearch.properties
  String langCode = "en";
  if (session.getAttribute("langCode") != null) {
    langCode = (String) session.getAttribute("langCode");
  }

  Properties encprops = new Properties();
  encprops.load(getClass().getResourceAsStream("/bundles/" + langCode + "/thumbnailSearch.properties"));

%>

<body>
<div id="wrapper">
<div id="page">
<jsp:include page="../header.jsp" flush="true">
  <jsp:param name="isAdmin" value="<%=request.isUserInRole(\"admin\")%>" />
</jsp:include>
<div id="main">
<table width="720">
<tr>
<td>
<p>

<h1 class="intro"><%=encprops.getProperty("title")%>
</h1>
</p>
<p><em><%=encprops.getProperty("instructions")%>
</em></p>

<form action="thumbnailSearchResults.jsp" method="get" name="search"
      id="search">
<table>
<tr>
  <td>
    <table width="715" align="left">
      <tr>
        <td width="170"><strong><%=encprops.getProperty("types2search")%>
        </strong>:
        </td>
        <td width="294"><label> <input type="radio"
                                       name="enctype" value="acceptedEncounters" checked>
          <%=encprops.getProperty("unapprovedApproved")%>
        </label></td>
        <td width="235"><label> <input name="enctype" type="radio"
                                       value="allEncounters"> <%=encprops.getProperty("allEncounters")%>
        </label></td>

      </tr>
    </table>
  </td>
</tr>

<tr>
  <td>
    <table width="357" align="left">
      <tr>
        <td width="62"><strong><%=encprops.getProperty("sex")%>: </strong></td>
        <td width="76"><label> <input name="male"
                                      type="checkbox" id="male" value="male"
                                      checked> <%=encprops.getProperty("male")%>
        </label></td>

        <td width="79"><label> <input name="female"
                                      type="checkbox" id="female" value="female" checked>
          <%=encprops.getProperty("female")%>
        </label></td>
        <td width="112"><label> <input name="unknown"
                                       type="checkbox" id="unknown" value="unknown" checked>
          <%=encprops.getProperty("unknown")%>
        </label></td>
      </tr>
    </table>
  </td>
</tr>

<tr>
  <td><input name="resightOnly" type="checkbox" id="resightOnly"
             value="true"> <%=encprops.getProperty("include")%> <select name="numResights"
                                                                        id="numResights">
    <option value="1" selected>1</option>
    <option value="2">2</option>
    <option value="3">3</option>
    <option value="4">4</option>
    <option value="5">5</option>
    <option value="6">6</option>
    <option value="7">7</option>
    <option value="8">8</option>
    <option value="9">9</option>
    <option value="10">10</option>
    <option value="11">11</option>
    <option value="12">12</option>
    <option value="13">13</option>
    <option value="14">14</option>
    <option value="15">15</option>
  </select> <%=encprops.getProperty("times")%>.
  </td>
</tr>
<tr>
  <td><strong><%=encprops.getProperty("lengthIs")%>: </strong> <select name="selectLength"
                                                                       size="1">
    <option value="gt">&gt;</option>
    <option value="lt">&lt;</option>
    <option value="eq">=</option>
  </select> <select name="lengthField" id="lengthField">
    <option value="skip" selected><%=encprops.getProperty("none")%>
    </option>
    <option value="1.0">1</option>
    <option value="2.0">2</option>
    <option value="3.0">3</option>
    <option value="4.0">4</option>
    <option value="5.0">5</option>
    <option value="6.0">6</option>
    <option value="7.0">7</option>
    <option value="8.0">8</option>
    <option value="9.0">9</option>
    <option value="10.0">10</option>
    <option value="11.0">11</option>
    <option value="12.0">12</option>
    <option value="13.0">13</option>
    <option value="14.0">14</option>
    <option value="15.0">15</option>
    <option value="16.0">16</option>
    <option value="17.0">17</option>
    <option value="18.0">18</option>
    <option value="19.0">19</option>
    <option value="20.0">20</option>
  </select> <%=encprops.getProperty("meters")%>
  </td>
</tr>
<tr>
  <td>
    <p><strong><%=encprops.getProperty("locationNameContains")%>:</strong> <input
      name="locationField" type="text" size="60"> <br> <em><%=encprops.getProperty("leaveBlank")%>
    </em></p>
  </td>
</tr>
<tr>
  <td>
    <p><strong><%=encprops.getProperty("locationID")%>:</strong><em>
      <input
        name="locationCodeField" type="text" id="locationCodeField"
        size="7"> <span class="para"><a
      href="<%=CommonConfiguration.getWikiLocation()%>locationID"
      target="_blank"><img src="../images/information_icon_svg.gif"
                           alt="Help" border="0" align="absmiddle"/></a></span>
      <br> <%=encprops.getProperty("locationIDExample")%>
    </em></p>
  </td>
</tr>
<tr>
  <td>
    <p><strong><%=encprops.getProperty("submitterName")%>:</strong> <input name="nameField"
                                                                           type="text" size="60">
      <br> <em><%=encprops.getProperty("namesBlank")%>
      </em></p>
  </td>
</tr>

<%

  int totalKeywords = myShepherd.getNumKeywords();
%>
<tr>
  <td><p><%=encprops.getProperty("hasKeywordPhotos")%>
  </p>
    <%

      if (totalKeywords > 0) {
    %>

    <select multiple size="<%=(totalKeywords+1) %>" name="keyword" id="keyword">
      <option value="None"></option>
      <%


        Iterator keys = myShepherd.getAllKeywords(kwQuery);
        for (int n = 0; n < totalKeywords; n++) {
          Keyword word = (Keyword) keys.next();
      %>
      <option value="<%=word.getIndexname()%>"><%=word.getReadableName()%>
      </option>
      <%
        }

      %>

    </select>
    <%
    } else {
    %>

    <p><em><%=encprops.getProperty("noKeywords")%>
    </em></p>

    <%

      }
    %>
  </td>
</tr>
<%
  myShepherd.rollbackDBTransaction();
  myShepherd.closeDBTransaction();
%>

<tr>
  <td><strong><%=encprops.getProperty("sightingDates")%>
  </strong></td>
</tr>
<tr>
  <td>
    <table width="720">
      <tr>
        <td width="670"><label> <em><%=encprops.getProperty("day")%>
        </em> <em>
          <select name="day1" id="day1">
            <option value="1" selected>1</option>
            <option value="2">2</option>
            <option value="3">3</option>
            <option value="4">4</option>
            <option value="5">5</option>
            <option value="6">6</option>
            <option value="7">7</option>
            <option value="8">8</option>
            <option value="9">9</option>
            <option value="10">10</option>
            <option value="11">11</option>
            <option value="12">12</option>
            <option value="13">13</option>
            <option value="14">14</option>
            <option value="15">15</option>
            <option value="16">16</option>
            <option value="17">17</option>
            <option value="18">18</option>
            <option value="19">19</option>
            <option value="20">20</option>
            <option value="21">21</option>
            <option value="22">22</option>
            <option value="23">23</option>
            <option value="24">24</option>
            <option value="25">25</option>
            <option value="26">26</option>
            <option value="27">27</option>
            <option value="28">28</option>
            <option value="29">29</option>
            <option value="30">30</option>
            <option value="31">31</option>
          </select> <%=encprops.getProperty("month")%>
        </em> <em> <select name="month1" id="month1">
          <option value="1" selected>1</option>
          <option value="2">2</option>
          <option value="3">3</option>
          <option value="4">4</option>
          <option value="5">5</option>
          <option value="6">6</option>
          <option value="7">7</option>
          <option value="8">8</option>
          <option value="9">9</option>
          <option value="10">10</option>
          <option value="11">11</option>
          <option value="12">12</option>
        </select> <%=encprops.getProperty("year")%>
        </em> <select name="year1" id="year1">
          <% for (int q = firstYear; q <= nowYear; q++) { %>
          <option value="<%=q%>"

            <%
              if (q == firstYear) {
            %>
                  selected
            <%
              }
            %>
            ><%=q%>
          </option>

          <% } %>
        </select> &nbsp;to <em>&nbsp;<%=encprops.getProperty("day")%>
        </em> <em> <select name="day2"
                           id="day2">
          <option value="1">1</option>
          <option value="2">2</option>
          <option value="3">3</option>
          <option value="4">4</option>
          <option value="5">5</option>
          <option value="6">6</option>
          <option value="7">7</option>
          <option value="8">8</option>
          <option value="9">9</option>
          <option value="10">10</option>
          <option value="11">11</option>
          <option value="12">12</option>
          <option value="13">13</option>
          <option value="14">14</option>
          <option value="15">15</option>
          <option value="16">16</option>
          <option value="17">17</option>
          <option value="18">18</option>
          <option value="19">19</option>
          <option value="20">20</option>
          <option value="21">21</option>
          <option value="22">22</option>
          <option value="23">23</option>
          <option value="24">24</option>
          <option value="25">25</option>
          <option value="26">26</option>
          <option value="27">27</option>
          <option value="28">28</option>
          <option value="29">29</option>
          <option value="30">30</option>
          <option value="31" selected>31</option>
        </select> <%=encprops.getProperty("month")%>
        </em> <em> <select name="month2" id="month2">
          <option value="1">1</option>
          <option value="2">2</option>
          <option value="3">3</option>
          <option value="4">4</option>
          <option value="5">5</option>
          <option value="6">6</option>
          <option value="7">7</option>
          <option value="8">8</option>
          <option value="9">9</option>
          <option value="10">10</option>
          <option value="11">11</option>
          <option value="12" selected>12</option>
        </select> <%=encprops.getProperty("year")%>
        </em> <select name="year2" id="year2">
          <% for (int q = nowYear; q >= firstYear; q--) { %>
          <option value="<%=q%>"

            <%
              if (q == nowYear) {
            %>
                  selected
            <%
              }
            %>
            ><%=q%>
          </option>

          <% } %>
        </select></label></td>
      </tr>
    </table>
  </td>
</tr>

<tr>
  <td>
    <p><em> <input name="submitSearch" type="submit" id="submitSearch"
                   value="<%=encprops.getProperty("goSearch")%>"></em>
  </td>
</tr>
</table>
</form>
</td>
</tr>
</table>
<br>
<jsp:include page="../footer.jsp" flush="true"/>
</div>
</div>
<!-- end page --></div>
<!--end wrapper -->

</body>
</html>


