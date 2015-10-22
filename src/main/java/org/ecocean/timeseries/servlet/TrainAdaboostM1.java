package org.ecocean.timeseries.servlet;

import java.io.File;
import java.io.FileWriter;
import java.io.IOException;
import java.io.PrintWriter;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.concurrent.ThreadPoolExecutor;
import java.util.StringTokenizer;

import javax.servlet.ServletConfig;
import javax.servlet.ServletException;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpServlet;

import org.ecocean.servlet.ServletUtilities;


import org.apache.commons.math.stat.descriptive.SummaryStatistics;
import org.ecocean.CommonConfiguration;
import org.ecocean.Encounter;
import org.ecocean.Shepherd;
import org.ecocean.grid.FlukeMatchComparator;
import org.ecocean.grid.GridManager;
import org.ecocean.grid.GridManagerFactory;
import org.ecocean.grid.MatchObject;
import org.ecocean.grid.ScanTask;
import org.ecocean.grid.ScanTaskCleanupThread;
import org.ecocean.grid.ScanWorkItem;
import org.ecocean.grid.ScanWorkItemResult;
import org.ecocean.grid.SharkGridThreadExecutorService;
import org.ecocean.neural.TrainNetwork;

import com.google.gson.Gson;
import com.google.gson.GsonBuilder;
import com.google.gson.JsonArray;
import com.google.gson.JsonPrimitive;

import weka.classifiers.meta.AdaBoostM1;
import weka.classifiers.bayes.BayesNet;
import weka.core.Instance;
import weka.core.Instances;
import java.util.Enumeration;


public class TrainAdaboostM1 extends HttpServlet {
  
  public void init(ServletConfig config) throws ServletException {
    super.init(config);
  }

  public void doGet(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {
    doPost(request, response);
  }

  public void doPost(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {

    String context=ServletUtilities.getContext(request);
    
    
    //set up for response
    response.setContentType("text/html; charset=UTF-8");
    PrintWriter out = response.getWriter();
    
    StringTokenizer str=new StringTokenizer(request.getParameter("genusSpecies")," ");
    String genus=str.nextToken();
    String specificEpithet=str.nextToken();
    
    String genusSpecies=request.getParameter("genusSpecies").replaceAll(" ", "");
    
    String fullPathToInstancesFile=TrainNetwork.getAbsolutePathToInstances(genusSpecies, request);
    
    Instances instances = TrainNetwork.buildWekaInstances(request, fullPathToInstancesFile,genus,specificEpithet);
    TrainNetwork.serializeWekaInstances(request, instances, fullPathToInstancesFile);  
    String fullPathToClassifierFile=TrainNetwork.getAbsolutePathToClassifier(genusSpecies, request);
    AdaBoostM1 booster=TrainNetwork.buildAdaBoostClassifier(request,fullPathToClassifierFile,instances);
    
    //TrainNetwork.serializeWekaClassifier(request, booster, fullPathToClassifierFile);
    
    Enumeration<Instance> myEnum=instances.enumerateInstances();
   
   int numMatches=0;
   int numNonmatches=0;
   while(myEnum.hasMoreElements()){
     Instance thisInstance=myEnum.nextElement();
     if(thisInstance.stringValue(7).equals("match")){numMatches++;}
     else{numNonmatches++;}
   }
   
   out.println(ServletUtilities.getHeader(request));
   out.println("<strong>Success:</strong> I created an AdaBoost and a BayesNet classifier for species "+request.getParameter("genusSpecies")+" with "+instances.numInstances()+" training instances.");
   out.println("<ul>");
     out.println("<li>matches: "+numMatches+"</li>");
     out.println("<li>nonmatches: "+numNonmatches+"</li>");
   out.println("</ul>");
   out.println("<p><a href=\"http://" + CommonConfiguration.getURLLocation(request) + "/appadmin/scanTaskAdmin.jsp" + "\">Return to Grid Administration" + "</a></p>\n");
   out.println(ServletUtilities.getFooter(context));

  }



 
}
