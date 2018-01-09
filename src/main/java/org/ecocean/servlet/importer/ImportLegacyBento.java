package org.ecocean.servlet.importer;

import org.json.JSONObject;

import com.opencsv.*;
import java.io.*;
import java.text.DateFormat;
import java.text.ParseException;
import java.text.SimpleDateFormat;
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
  //private String messages;
  
  private ArrayList<Survey> masterSurveyArr = new ArrayList<Survey>();
  
  
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
        processSurveyLogFile(myShepherd, surveyLogCSV);
      }
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
        processTags(myShepherd, tagCSV);
      }      
    
    } else {
      out.println("The Specified Directory Doesn't Exist.");
    }   
    myShepherd.closeDBTransaction();
    out.close();
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
  
  private void processSurveyLogFile(Shepherd myShepherd, CSVReader surveyLogCSV) {
    System.out.println(surveyLogCSV.verifyReader());
    int totalSurveys = 0;
    int totalRows = 0;
    Iterator<String[]> rows = surveyLogCSV.iterator();
    String[] columnNameArr = rows.next();
    Survey sv = null;
    
    while (rows.hasNext()) {
      totalRows += 1;
      String[] rowString = rows.next();
      sv = processSurveyLogRow(columnNameArr,rowString);
      myShepherd.beginDBTransaction();    
      
    }
    
  }
  
  public Survey processSurveyLogRow(String[] names, String[] values ) {
    Survey sv = null;
    
    return sv;
  }
  
  private void processEffortFile(Shepherd myShepherd, CSVReader effortCSV) {
    System.out.println(effortCSV.verifyReader());
    int totalSurveys = 0;
    int totalRows = 0;
    Iterator<String[]> rows = effortCSV.iterator();
    // Just grab the first one. It has all the column names, and theoretically the maximum length of each row. 
    String[] columnNameArr = rows.next();
    Survey sv = null;
    while (rows.hasNext()) {
      totalRows += 1;
      String[] rowString = rows.next();
      sv = processEffortRow(columnNameArr,rowString);
      myShepherd.beginDBTransaction();        

      try {
        myShepherd.getPM().makePersistent(sv);
        myShepherd.commitDBTransaction();
        masterSurveyArr.add(sv);
        totalSurveys += 1;
      } catch (Exception e) {
        myShepherd.rollbackDBTransaction();
        e.printStackTrace();
        out.println("Could not persist this Survey : "+Arrays.toString(rowString));
      }
    }
    out.println("Created "+totalSurveys+" surveys out of "+totalRows+" rows in EFFORT file.");
  }
  
  private Survey effortSurveyInstantiate(String date) {
    Survey sv = null;
    try {
      date = formatDate(date);           
    } catch (Exception e) {
      e.printStackTrace();
    }
    if (date!=null) {
      sv = new Survey(date);          
    } else {
      sv = new Survey();
      sv.setID(Util.generateUUID());
      sv.setDWCDateLastModified();
    }
    return sv;
  }
  
  private Survey processEffortRow(String[] names, String[] values) {
    ArrayList<String> obsColumns = new ArrayList<String>();
    Survey sv = null;
    boolean match = false;
    // Explicit column index for date is #38.
    // TODO precede with a check for match in masterArr
    if (names[38].equals("Date Created")) {
      if (!match) {
        sv = effortSurveyInstantiate(values[38]);
      }
    }
    
    for (int i=0;i<names.length;i++) {
      if (names[i]!=null) {
        if (names[i].equals("Project")&&!values[i].equals("N/A")) {
          sv.setProjectName(values[i]);
          obsColumns.remove("Project");
        }        
        if (names[i].equals("Comments")&&!values[i].equals("N/A")) {
          try {
            sv.addComments("Penguin!");            
            obsColumns.remove("Comments");
          } catch (NullPointerException npe) {
            npe.printStackTrace();
            System.out.println(values[i]);
          }          
        }        
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
  private void processTags(Shepherd myShepherd, CSVReader tagCSV) {
    System.out.println(tagCSV.verifyReader());
  }
  
  private String formatDate(String rawDate) {
    String date = null;
    DateTime dt = null;
    //out.println("Raw Date Created : "+rawDate);
    if (!rawDate.equals("N/A")&&!rawDate.equals("")) {
      if (rawDate.endsWith("AM")||(rawDate.endsWith("PM"))){
        dt = dateStringToDateTime(rawDate,"MMM d, yyyy, h:m a");
      } else if (String.valueOf(rawDate.charAt(3)).equals(" ")) {
        dt = dateStringToDateTime(rawDate,"MMM dd, yyyy, h:m");          
      } else if (String.valueOf(rawDate.charAt(4)).equals("-")) {
        dt = dateStringToDateTime(rawDate,"yyyy-MM-dd'T'kk:mm:ss"); 
      }
      date = dt.toString().substring(0,10);
    } 
    return date;
  }  
  
  private DateTime dateStringToDateTime(String verbatim, String format) {
    DateFormat fm = new SimpleDateFormat(format);
    Date d = null;
    try {
      d = (Date)fm.parse(verbatim);    
    } catch (ParseException pe) {
      pe.printStackTrace();
      out.println("Barfed Parsing a Datestring... Format : "+format+", Verbatim : "+verbatim);
    }
    DateTime dt = new DateTime(d);
    return dt;
  }
}
  
  
  
  
  
  
  
  