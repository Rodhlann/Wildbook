package org.ecocean.servlet.importer;

import org.json.JSONObject;

import java.io.*;
import java.util.*;
import java.util.Map.Entry;
import java.util.concurrent.TimeUnit;

import org.ecocean.*;
import org.ecocean.servlet.*;
import org.ecocean.tag.DigitalArchiveTag;
import org.ecocean.tag.SatelliteTag;
import org.joda.time.DateTime;
import org.joda.time.format.DateTimeFormat;
import org.joda.time.format.DateTimeFormatter;
import org.ecocean.media.*;
import org.apache.commons.io.FilenameUtils;
import org.apache.poi.ss.usermodel.DataFormatter;
import org.apache.poi.xssf.usermodel.XSSFCell;
//import org.apache.poi.hssf.usermodel.*;
//import org.apache.poi.poifs.filesystem.NPOIFSFileSystem;
import org.apache.poi.xssf.usermodel.XSSFRow;
import org.apache.poi.xssf.usermodel.XSSFSheet;
import org.apache.poi.xssf.usermodel.XSSFWorkbook;

import org.apache.commons.fileupload.*;
import org.apache.commons.fileupload.disk.DiskFileItemFactory;
import org.apache.commons.fileupload.servlet.ServletFileUpload;

import javax.servlet.ServletConfig;
import javax.servlet.ServletContext;
import javax.servlet.ServletException;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

public class ImportLegacyBentoCsv extends HttpServlet {
  /**
   * 
   */
  
  private static final long serialVersionUID = 1L;
  private static PrintWriter out;
  private static String context; 

  
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
    myShepherd.setAction("ImportLegacyBentoCsv.class");
    
    out.println("Grabbing all CSV files... ");
    String dir = "/opt/dukeImport/DUML Files for Colin-NEW/Raw Data Files/tables_170303/";
    
    String name = null;
    File effortFile = grabCSVFile(name);
    
  }

  
  private File grabCSVFile(String name) {
    File file = new File(name);
    return file;
  }
  
}
  
  
  
  
  
  
  
  