package org.ecocean;

import java.util.HashMap;
import java.util.Iterator;
import java.util.List;
import java.util.ArrayList;
import java.util.Map;
import java.util.Vector;
import java.io.*;
import org.joda.time.format.*;

import javax.jdo.Query;
import javax.servlet.http.HttpServletRequest;

import org.ecocean.*;
import org.ecocean.servlet.ServletUtilities;
import org.ecocean.security.Collaboration;

import org.joda.time.DateTime;
import org.joda.time.format.ISODateTimeFormat;

public class OccurrenceQueryProcessor extends QueryProcessor {

  //private static final String BASE_FILTER = "SELECT FROM org.ecocean.Occurrence WHERE \"OCCURRENCEID\" != null && ";
  private static final String SELECT_FROM_ORG_ECOCEAN_OCCURENCE_WHERE = "SELECT FROM org.ecocean.Occurrence WHERE encounters.contains(enc) && \"OCCURRENCEID\" != null";
  //private static final String VARIABLES_STATEMENT = " VARIABLES org.ecocean.Encounter enc";

  public static final String[] SIMPLE_STRING_FIELDS = new String[]{"fieldStudySite", "fieldSurveyCode", "sightingPlatform","seaState","observer","comments","occurrenceID"};

  public static final String[] CATEGORICAL_STRING_FIELDS = new String[]{"submitterID"};

  public static final String[] CATEGORY_DEFINED_STRING_FIELDS = new String[]{"groupBehavior","groupComposition","initialCue"};

  public static String queryStringBuilder(HttpServletRequest request, StringBuffer prettyPrint, Map<String, Object> paramMap){

    String filter = SELECT_FROM_ORG_ECOCEAN_OCCURENCE_WHERE;
    String jdoqlVariableDeclaration = "";
    String parameterDeclaration = "";
    String context = "context0";
    context = ServletUtilities.getContext(request);

    //Shepherd myShepherd = new Shepherd(context);
    //myShepherd.setAction("OccurrenceQueryProcessor.class");

    //filter for id------------------------------------------
    filter = QueryProcessor.filterWithBasicStringField(filter, "id", request, prettyPrint);
    System.out.println("           beginning filter = "+filter);
    
    // filter for simple string fields
    for (String fieldName : SIMPLE_STRING_FIELDS) {
      System.out.println("   parsing occurrence query for field "+fieldName);
      System.out.println("           current filter = "+filter);
      filter = QueryProcessor.filterWithBasicStringField(filter, fieldName, request, prettyPrint);
    }
    
    // filter for exact string fields
    for (String fieldName : CATEGORICAL_STRING_FIELDS) {
      System.out.println("   parsing occurrence query for field "+fieldName);
      System.out.println("           current filter = "+filter);
      filter = QueryProcessor.filterWithExactStringField(filter, fieldName, request, prettyPrint);
    }
    
    // GPS box
    filter = QueryProcessor.filterWithGpsBox("decimalLatitude", "decimalLongitude", filter, request, prettyPrint);
    
    //Observations
    filter = QueryProcessor.filterObservations(filter, request, prettyPrint, "Occurrence");
    int numObs = QueryProcessor.getNumberOfObservationsInQuery(request);
    for (int i = 1;i<=numObs;i++) {
      jdoqlVariableDeclaration = QueryProcessor.updateJdoqlVariableDeclaration(jdoqlVariableDeclaration, "org.ecocean.Observation observation" + i);
    }
    
    jdoqlVariableDeclaration = QueryProcessor.updateJdoqlVariableDeclaration(jdoqlVariableDeclaration, "org.ecocean.Encounter enc");

    //filter for date range
    if(Util.stringExists(request.getParameter("eventDateFrom"))&&Util.stringExists(request.getParameter("eventDateTo"))) {
      filter = filterDateRanges(request, filter, prettyPrint);
    }
    
    
    // filter for submitterOrganization------------------------------------------
    if((request.getParameter("organizationId")!=null)&&(!request.getParameter("organizationId").equals("")) && Util.isUUID(request.getParameter("organizationId"))) {
      String orgId=request.getParameter("organizationId");
      System.out.println("orgId is" + orgId);
      String variables_statement = " VARIABLES org.ecocean.Encounter enc; org.ecocean.User user; org.ecocean.Organization org";
      jdoqlVariableDeclaration = addVariables(variables_statement, filter);
      filter = "SELECT FROM org.ecocean.Occurrence WHERE encounters.contains(enc) && user.username == enc.submitterID && org.members.contains(user) && org.id == '" + orgId + "'";
      prettyPrint.append("Submitter organization contains \""+orgId+"\".<br />");
    }

    //end submitterOrganization filter--------------------------------------------------------------------------------------

    // filter for submitterOrganization------------------------------------------
      if((request.getParameter("submitterOrganization")!=null)&&(!request.getParameter("submitterOrganization").equals(""))) {
        String submitterOrgString=request.getParameter("submitterOrganization").toLowerCase().replaceAll("%20", " ").trim();

          filter=filterWithCondition(filter,"(enc.submitterOrganization.toLowerCase().indexOf('"+submitterOrgString+"') != -1)");

        prettyPrint.append("Submitter organization contains \""+submitterOrgString+"\".<br />");
      }
      //end submitterOrganization filter--------------------------------------------------------------------------------------

    //Taxonomies
    List<String> scientificNames = getScientificNames(request);
    int numTaxonomies = scientificNames.size();
    if (numTaxonomies>0) {
      filter = filterTaxonomies(filter, request, prettyPrint, scientificNames);
      jdoqlVariableDeclaration = addTaxonomyVars(jdoqlVariableDeclaration, numTaxonomies);
    }

    // make sure no trailing ampersands
    filter = QueryProcessor.removeTrailingAmpersands(filter);
    filter += jdoqlVariableDeclaration;
    filter += parameterDeclaration;
    System.out.println("OccurrenceQueryProcessor filter: "+filter);
    return filter;
  }

  public static int getNumTaxonomies(HttpServletRequest request) {
    int numTaxonomies = 0;
    while(request.getParameter("taxonomy"+numTaxonomies)!=null) {
      numTaxonomies++;
    }
    return numTaxonomies;
  }
  public static List<String> getScientificNames(HttpServletRequest request) {
    List<String> names = new ArrayList<String>();
    int numTaxonomies = 0;
    String currentName = request.getParameter("taxonomy0");
    while(Util.stringExists(currentName)) {
      names.add(Util.basicSanitize(currentName));
      numTaxonomies++;
      currentName = request.getParameter("taxonomy"+numTaxonomies);
    }
    return names;

  }

  private static String filterTaxonomies(String filter, HttpServletRequest request, StringBuffer prettyPrint, List<String> scientificNames) {
    int numTaxonomies = scientificNames.size();
    StringBuilder taxQuery = new StringBuilder();
    for (int i=0;i<numTaxonomies;i++) {
      String thisTitle = "taxonomy"+i;
      String taxName = scientificNames.get(i);
      if (!Util.stringExists(taxName)) continue;
      if (i>0) {
        taxQuery.append(" && "); // OR??
        prettyPrint.append(" and ");
      }
      taxQuery.append("(taxonomies.contains("+thisTitle+") && "+thisTitle+".scientificName == \""+taxName+"\")");
      prettyPrint.append("taxonomy "+i+" equals");
    }
    prettyPrint.append(".</br>");
    filter = filterWithCondition(filter, taxQuery.toString()); // is this ok??? should fix w jdo subfilter method
    return filter;
  }
  private static String addTaxonomyVars(String jdoqlVariableDeclaration, int numTaxonomies) {
    for (int i = 0; i < numTaxonomies; i++) {
      QueryProcessor.updateJdoqlVariableDeclaration(jdoqlVariableDeclaration, "org.ecocean.Taxonomy taxonomy" + i);
    }
    return jdoqlVariableDeclaration;
  }

  private static String addVariables(String jdoqlVariableDeclaration, String orgs) {
    QueryProcessor.updateJdoqlVariableDeclaration(jdoqlVariableDeclaration, orgs);
    return jdoqlVariableDeclaration;
  }

  public static OccurrenceQueryResult processQuery(Shepherd myShepherd, HttpServletRequest request, String order){

    Vector<Occurrence> rOccurrences=new Vector<Occurrence>();
    Iterator<Occurrence> allOccurrences;
    String filter="";
    StringBuffer prettyPrint=new StringBuffer("");
    Map<String,Object> paramMap = new HashMap<String, Object>();

    filter=queryStringBuilder(request, prettyPrint, paramMap);
    System.out.println("OccurrenceQueryResult: has filter "+filter);
    Query query=myShepherd.getPM().newQuery(filter);
    System.out.println("                       got query "+query);
    System.out.println("                       has paramMap "+paramMap);
    if(!order.equals("")){query.setOrdering(order);}
    System.out.println("                 still has query "+query);
    if(!filter.trim().equals("")){
      System.out.println(" about to call myShepherd.getAllOccurrences on query "+query);
      allOccurrences=myShepherd.getAllOccurrences(query, paramMap);
    } else {
      System.out.println(" about to call myShepherd.getAllOccurrencesNoQuery() ");
      allOccurrences=myShepherd.getAllOccurrencesNoQuery();
    }
    System.out.println("               *still* has query "+query);


    if(allOccurrences!=null){
      while (allOccurrences.hasNext()) {
        Occurrence temp_dat=allOccurrences.next();
        rOccurrences.add(temp_dat);
      }
    }
  	query.closeAll();

    System.out.println("about to return OccurrenceQueryResult with filter "+filter+" and nOccs="+rOccurrences.size());
    return (new OccurrenceQueryResult(rOccurrences,filter,prettyPrint.toString()));
  }

  public static String filterDateRanges(HttpServletRequest request, String filter, StringBuffer prettyPrint) {
    try {
      DateTimeFormatter parser = DateTimeFormat.forPattern("MM/dd/yyyy");
      DateTime eventDateFromDT = parser.parseDateTime(request.getParameter("eventDateFrom"));
      DateTime eventDateToDT = parser.parseDateTime(request.getParameter("eventDateTo"));

      long eventDateFromMillis = eventDateFromDT.getMillis();
      long eventDateToMillis = eventDateToDT.getMillis();

      if(request.getParameter("eventDateFrom").trim().equals(request.getParameter("eventDateTo").trim())){
        eventDateToMillis += (24*60*60*1000-1);
      }

      prettyPrint.append("Event Date between: "+eventDateFromDT.toString(ISODateTimeFormat.date())+" and "+eventDateToDT.toString(ISODateTimeFormat.date())+"<br />");

      if(filter.trim().endsWith("&&")) {
        filter += "((enc.dateInMilliseconds >= "+eventDateFromMillis+") && (enc.dateInMilliseconds <= "+eventDateToMillis+"))";
      } else {
        filter += " && ((enc.dateInMilliseconds >= "+eventDateFromMillis+") && (enc.dateInMilliseconds <= "+eventDateToMillis+"))";
      }

    } catch (Exception e) {
      e.printStackTrace();
    }
    return filter;
  }

 public static String prepForNext(String filter) {
   if (!QueryProcessor.endsWithAmpersands(filter)) {
     QueryProcessor.prepForCondition(filter);
   }
   return filter;
 }

}
