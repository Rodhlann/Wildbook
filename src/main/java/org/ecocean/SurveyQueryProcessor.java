package org.ecocean;

import java.util.ArrayList;
import java.util.Date;
import java.util.Enumeration;
import java.util.HashMap;
import java.util.Iterator;
import java.util.List;
import java.util.Map;
import java.util.Vector;
import java.io.*;

import javax.jdo.Query;
import javax.servlet.http.HttpServletRequest;

import org.ecocean.*;
import org.ecocean.servlet.ServletUtilities;
import org.ecocean.security.Collaboration;

import org.joda.time.DateTime;

public class SurveyQueryProcessor extends QueryProcessor {

  private static final String BASE_FILTER = "SELECT FROM org.ecocean.Survey WHERE \"ID\" != null && ";

  public static final String[] SIMPLE_STRING_FIELDS = new String[]{"project","organization","type","effort"};

  

  public static String queryStringBuilder(HttpServletRequest request, StringBuffer prettyPrint, Map<String, Object> paramMap){

    String filter= BASE_FILTER;
    String jdoqlVariableDeclaration = "";
    String parameterDeclaration = "";
    String context="context0";
    context=ServletUtilities.getContext(request);

    Shepherd myShepherd=new Shepherd(context);
    //myShepherd.setAction("SurveyQueryProcessor.class");
    
    ArrayList<Survey> svys = myShepherd.getAllSurveys();
    if (!svys.isEmpty()) {
      for (int i=0;i<20;i++) {
        System.out.println("Sample #"+i+" startTime "+svys.get(i).getStartTimeMilli());
      }      
    }

    //filter for id------------------------------------------
    filter = QueryProcessor.filterWithBasicStringField(filter, "id", request, prettyPrint);
    System.out.println("           beginning filter = "+filter);

    // filter for simple string fields
    for (String fieldName : SIMPLE_STRING_FIELDS) {
      System.out.println("   parsing Survey query for field "+fieldName);
      System.out.println("           current filter = "+filter);
      filter = QueryProcessor.filterWithBasicStringField(filter, fieldName, request, prettyPrint);
    }

    // GPS box
    filter = QueryProcessor.filterWithGpsBox(filter, request, prettyPrint);
    
    
    //Observations
    
    // Filter method takes a relative package argument as a means of making is adaptable for other classes.
    filter = QueryProcessor.filterObservations(filter, request, prettyPrint, "movement.Survey");
    int numObs = QueryProcessor.getNumberOfObservationsInQuery(request);
    for (int i = 1;i<=numObs;i++) {
      jdoqlVariableDeclaration = QueryProcessor.updateJdoqlVariableDeclaration(jdoqlVariableDeclaration, "org.ecocean.Observation observation" + i);      
    }
    
    // make sure no trailing ampersands
    filter = QueryProcessor.removeTrailingAmpersands(filter);
    filter += jdoqlVariableDeclaration;
    filter += parameterDeclaration;
    System.out.println("SurveyQueryProcessor filter: "+filter);
    return filter;
  }

  public static SurveyQueryResult processQuery(Shepherd myShepherd, HttpServletRequest request, String order){

    Vector<Survey> rSurveys=new Vector<Survey>();
    Iterator<Survey> allSurveys;
    String filter="";
    StringBuffer prettyPrint=new StringBuffer("");
    Map<String,Object> paramMap = new HashMap<String, Object>();

    filter=queryStringBuilder(request, prettyPrint, paramMap);
    System.out.println("SurveyQueryResult: has filter "+filter);
    Query query=myShepherd.getPM().newQuery(filter);
    System.out.println("                       got query "+query);
    System.out.println("                       has paramMap "+paramMap);
    if(!order.equals("")){query.setOrdering(order);}
    System.out.println("                 still has query "+query);
    if(!filter.trim().equals("")){
      System.out.println(" about to call myShepherd.getAllSurveys on query "+query);
      allSurveys=myShepherd.getAllSurveys(query, paramMap);
    } else {
      System.out.println(" about to call myShepherd.getAllSurveysNoQuery() ");
      allSurveys=myShepherd.getAllSurveysNoQuery();
    }
    System.out.println("               *still* has query "+query);


    if(allSurveys!=null){
      while (allSurveys.hasNext()) {
        Survey temp_dat=allSurveys.next();
        rSurveys.add(temp_dat);
      }
    }
    query.closeAll();

    System.out.println("about to return SurveyQueryResult with filter "+filter+" and nOccs="+rSurveys.size());
    return (new SurveyQueryResult(rSurveys,filter,prettyPrint.toString()));
  }
  
  public static String filterDateRanges(HttpServletRequest request, String filter) {
    String filterAddition = "";
    String endTimeFrom = null;
    String endTimeTo = null;
    String startTimeFrom = null;
    String startTimeTo = null;
    
    Enumeration<String> atts = request.getAttributeNames();
    
    try {
      filter = prepForNext(filter);
      if (request.getParameter("startTimeFrom")!=null&&request.getParameter("startTimeFrom").length()>8) {
        startTimeFrom = monthDayYearToMilli(request.getParameter("startTimeFrom"));
        // Crush date
        String addition = " (startTime >=  "+startTimeFrom+") ";
        prettyPrint.append(addition);
        filter += addition;
      }      
    } catch (NullPointerException npe) {
      npe.printStackTrace();
    }
    
    try {
      filter = prepForNext(filter);
      if (request.getParameter("startTimeTo")!=null&&request.getParameter("startTimeTo").length()>8) {
        startTimeTo = monthDayYearToMilli(request.getParameter("startTimeTo"));
        // Crush date
        String addition = " (startTime <=  "+startTimeTo+") ";
        prettyPrint.append(addition);
        filter += addition;
      }      
    } catch (NullPointerException npe) {
      npe.printStackTrace();
    }
    
    try {
      filter = prepForNext(filter);
      if (request.getParameter("endTimeFrom")!=null&&request.getParameter("endTimeFrom").length()>8) {
        endTimeFrom = monthDayYearToMilli(request.getParameter("endTimeFrom"));
        // Crush date
        String addition = " (endTime >=  "+endTimeFrom+") ";
        prettyPrint.append(addition);
        filter += addition;
      }      
    } catch (NullPointerException npe) {
      npe.printStackTrace();
    }
    
    try {
      filter = prepForNext(filter);
      if (request.getParameter("endTimeTo")!=null&&request.getParameter("endTimeFrom").length()>8) {
        endTimeTo = monthDayYearToMilli(request.getParameter("endTimeTo"));
        // Crush date
        String addition = " (startTime <=  "+endTimeTo+") ";
        prettyPrint.append(addition);
        filter += addition;
      }      
    } catch (NullPointerException npe) {
      npe.printStackTrace();
    }
    filter = prepForNext(filter);
    return filter;
  }
  
 public static String prepForNext(String filter) {
   if (!QueryProcessor.endsWithAmpersands(filter)) {
     filter = QueryProcessor.prepForCondition(filter);
   }
   return filter;
 }
 
 private static String monthDayYearToMilli(String newDate) {
   System.out.println("This is the input date: "+newDate);
   SimpleDateFormat sdf = new SimpleDateFormat("MM-dd-yyyy");
   String month = newDate.substring(0,2);
   String day = newDate.substring(3,5);
   String year = newDate.substring(6,10);
   Date dt;
   try {
     dt = sdf.parse(month+"-"+day+"-"+year);
   } catch (ParseException e) {
     e.printStackTrace();
     System.out.println("Failed to Parse String : "+month+"-"+day+"-"+year);
     return null;
   }
   return String.valueOf(dt.getTime());
 }
}



