package org.ecocean.servlet.importer;

import org.json.JSONObject;

import com.opencsv.*;
import java.io.*;
import java.util.*;
import java.util.Map.Entry;
import java.util.concurrent.TimeUnit;

import org.ecocean.*;
import org.ecocean.servlet.*;
import org.joda.time.DateTime;
import org.joda.time.format.DateTimeFormat;
import org.joda.time.format.DateTimeFormatter;
import org.ecocean.media.*;
import org.apache.commons.io.FilenameUtils;
import org.apache.poi.ss.usermodel.DataFormatter;

import org.apache.commons.fileupload.*;
import org.apache.commons.fileupload.disk.DiskFileItemFactory;
import org.apache.commons.fileupload.servlet.ServletFileUpload;

import javax.servlet.ServletConfig;
import javax.servlet.ServletContext;
import javax.servlet.ServletException;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;


public class ImportLegacyBento extends HttpServlet {
  /**
   * 
   */
  
  private static final long serialVersionUID = 1L;
  private static PrintWriter out;
  private static String context; 
  private String messages;
  
  
  public void init(ServletConfig config) throws ServletException {
    super.init(config);
  }

  public void doGet(HttpServletRequest request,  HttpServletResponse response) throws ServletException,  IOException {
    doPost(request,  response);
  }
  
  public void doPost(HttpServletRequest request, HttpServletResponse response) throws ServletException,  IOException { 
    out = response.getWriter();
    context = ServletUtilities.getContext(request);
    out.println("=========== Preparing to import legacy bento CSV file. ===========");
    Shepherd myShepherd = new Shepherd(context);
    myShepherd.setAction("ImportLegacyBento.class");
    
    out.println("Grabbing all CSV files... ");
    // Grab each CSV file, make switches similar to access import.
    // Stub a method for each one. 
    // Find the DUML equivalent -or- start with surveys. 
    String dir = "/opt/dukeImport/DUML Files for Colin-NEW/Raw Data files/tables_170303/";
    File rootFile = new File(dir);
  
    if (rootFile.exists()) {
      out.println("File path: "+rootFile.getAbsolutePath());
    
      CSVReader effortCSV = grabReader(new File (rootFile, "efforttable_final.csv"));
      CSVReader biopsyCSV = grabReader(new File (rootFile, "biopsytable_final.csv"));
      CSVReader followsCSV = grabReader(new File (rootFile, "followstable_final.csv"));
      CSVReader sightingsCSV = grabReader(new File (rootFile, "sightingstable_final.csv"));
      CSVReader surveyLogCSV = grabReader(new File (rootFile, "surveylogtable_final.csv"));
      CSVReader tagCSV = grabReader(new File (rootFile, "tagtable_final.csv"));
      
      if (true) {
        processEffortFile(myShepherd, effortCSV);
      }
      if (true) {
        processBiopsy(myShepherd, biopsyCSV);
      }
      if (true) {
        processFollows(myShepherd, followsCSV);
      }
      if (true) {
        processSightings(myShepherd, sightingsCSV);
      }
      if (true) {
        processSurveyLog(myShepherd, surveyLogCSV);
      }
      if (true) {
        processTags(myShepherd, tagCSV);
      }      
    
    } else {
      out.println("The Specified Directory Doesn't Exist.");
    }   
  }
 
  private CSVReader grabReader(File file) {
    CSVReader reader = null;
    try {
      reader = new CSVReader(new FileReader(file));
    } catch (FileNotFoundException e) {
      System.out.println("Failed to retrieve CSV file at "+file.getPath());
      e.printStackTrace();
    }
    return reader;
  }
  
  private void processEffortFile(Shepherd myShepherd, CSVReader effortCSV) {
    System.out.println(effortCSV.verifyReader());
    Iterator<String[]> rows = effortCSV.iterator();
    // Just grab the first one. It has all the column names, and theoretically the maximum length of each row. 
    String[] columnNameArr = rows.next();
    int numColumns = columnNameArr.length;
    while (rows.hasNext()) {
      String[] rowString = rows.next();
      Survey sv = processEffortRow(columnNameArr,rowString);
    }
    out.println(Arrays.toString(rows.next()));
  }
  
  private Survey processEffortRow(String[] names, String[] values) {
    Survey sv = new Survey();
    for (int i=0;i<names.length;i++) {
      
      if (names[i].equals("Date Created")) {
        out.println("Date Created : "+values[i]);
      }
    
    }
    return sv;
  }
  

  private void processFollows(Shepherd myShepherd, CSVReader followsCSV) {
    System.out.println(followsCSV.verifyReader());
    
  }
  private void processBiopsy(Shepherd myShepherd, CSVReader biopsyCSV) {
    System.out.println(biopsyCSV.verifyReader());
    
  }
  private void processSightings(Shepherd myShepherd, CSVReader sightingsCSV) {
    System.out.println(sightingsCSV.verifyReader());
  
  }
  private void processSurveyLog(Shepherd myShepherd, CSVReader surveyLogCSV) {
    System.out.println(surveyLogCSV.verifyReader());
  }
  private void processTags(Shepherd myShepherd, CSVReader tagCSV) {
    System.out.println(tagCSV.verifyReader());
  }
  
}
  
  
  
  
  
  
  
  