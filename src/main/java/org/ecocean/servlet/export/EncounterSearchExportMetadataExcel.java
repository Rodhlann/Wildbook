package org.ecocean.servlet.export;
import javax.servlet.*;
import javax.servlet.http.*;

import java.io.*;
import java.util.*;

import org.ecocean.*;
import org.ecocean.genetics.*;
import org.ecocean.servlet.ServletUtilities;

import javax.jdo.*;

import java.lang.StringBuffer;

import jxl.write.*;
import jxl.Workbook;


public class EncounterSearchExportMetadataExcel extends HttpServlet{

  private static final int BYTES_DOWNLOAD = 1024;

  private static String cleanToString(Object obj) {
    if (obj==null) return "";
    return obj.toString();
  }


  public void init(ServletConfig config) throws ServletException {
      super.init(config);
    }


  public void doGet(HttpServletRequest request, HttpServletResponse response) throws ServletException,IOException {
      doPost(request, response);
  }



  public void doPost(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException{

    //set the response

    String context="context0";
    context=ServletUtilities.getContext(request);
    Shepherd myShepherd = new Shepherd(context);



    Vector rEncounters = new Vector();
    int numResults = 0;


    //set up the files
    String filename = "encounterSearchResults_export_" + request.getRemoteUser() + ".xls";

    //setup data dir
    String rootWebappPath = getServletContext().getRealPath("/");
    File webappsDir = new File(rootWebappPath).getParentFile();
    File shepherdDataDir = new File(webappsDir, CommonConfiguration.getDataDirectoryName(context));
    if(!shepherdDataDir.exists()){shepherdDataDir.mkdirs();}
    File encountersDir=new File(shepherdDataDir.getAbsolutePath()+"/encounters");
    if(!encountersDir.exists()){encountersDir.mkdirs();}

    File excelFile = new File(encountersDir.getAbsolutePath()+"/"+ filename);


    myShepherd.beginDBTransaction();


    try {

      //set up the output stream
      FileOutputStream fos = new FileOutputStream(excelFile);
      OutputStreamWriter outp = new OutputStreamWriter(fos);

      try{


        EncounterQueryResult queryResult = EncounterQueryProcessor.processQuery(myShepherd, request, "year descending, month descending, day descending");
        rEncounters = queryResult.getResult();

				Vector blocked = Encounter.blocked(rEncounters, request);
				if (blocked.size() > 0) {
					response.setContentType("text/html");
					PrintWriter out = response.getWriter();
					out.println(ServletUtilities.getHeader(request));
					out.println("<html><body><p><strong>Access denied.</strong></p>");
					out.println(ServletUtilities.getFooter(context));
					out.close();
					return;
				}

        int numMatchingEncounters=rEncounters.size();

       //business logic start here

        //load the optional locales
        Properties props = new Properties();
        try {
          props=ShepherdProperties.getProperties("locationIDGPS.properties", "",context);

        } catch (Exception e) {
          System.out.println("     Could not load locales.properties EncounterSearchExportExcelFile.");
          e.printStackTrace();
        }

      //let's set up some cell formats
        WritableCellFormat floatFormat = new WritableCellFormat(NumberFormats.FLOAT);
        WritableCellFormat integerFormat = new WritableCellFormat(NumberFormats.INTEGER);

      //let's write out headers for the OBIS export file
        WritableWorkbook workbookOBIS = Workbook.createWorkbook(excelFile);
        WritableSheet sheet = workbookOBIS.createSheet("Search Results", 0);

        String[] colHeaders = new String[]{
          "catalog number",
          "individual ID",
          "occurrence ID",
          "year",
          "month",
          "day",
          "hour",
          "minutes",
          "milliseconds (definitive datetime)",
          "latitude",
          "longitude",
          "locationID",
          "country",
          "other catalog numbers",
          "submitter name",
          "submitter organization",
          "sex",
          "behavior",
          "life stage",
          "group role",
          "researcher comments",
          "verbatim locality",
          "alternate ID",
          "web URL",
          "individual web URL",
          "occurrence web URL"
        };

        for (int i=0; i<colHeaders.length; i++) {
          sheet.addCell(new Label(i, 0, colHeaders[i]));
        }

        // Excel export =========================================================
        int count = 0;

         for(int i=0;i<numMatchingEncounters;i++){
            Encounter enc=(Encounter)rEncounters.get(i);
            count++;
            numResults++;

            List<Label> rowLabels = new ArrayList<Label>();

            rowLabels.add(new Label(0, count, enc.getCatalogNumber()));
            rowLabels.add(new Label(1, count, enc.getIndividualID()));
            rowLabels.add(new Label(2, count, enc.getOccurrenceID()));
            rowLabels.add(new Label(3, count, String.valueOf(enc.getYear())));
            rowLabels.add(new Label(4, count, String.valueOf(enc.getMonth())));
            rowLabels.add(new Label(5, count, String.valueOf(enc.getDay())));
            rowLabels.add(new Label(6, count, String.valueOf(enc.getHour())));
            rowLabels.add(new Label(7, count, enc.getMinutes()));
            rowLabels.add(new Label(8, count, String.valueOf(enc.getDateInMilliseconds())));
            rowLabels.add(new Label(9, count, enc.getDecimalLatitude()));
            rowLabels.add(new Label(10, count, enc.getDecimalLongitude()));

            rowLabels.add(new Label(11, count, enc.getLocationID()));
            rowLabels.add(new Label(12, count, enc.getCountry()));
            rowLabels.add(new Label(13, count, enc.getOtherCatalogNumbers()));
            rowLabels.add(new Label(14, count, enc.getSubmitterName()));
            rowLabels.add(new Label(15, count, enc.getSubmitterOrganization()));

            rowLabels.add(new Label(16, count, enc.getSex()));
            rowLabels.add(new Label(17, count, enc.getBehavior()));
            rowLabels.add(new Label(18, count, enc.getLifeStage()));
            rowLabels.add(new Label(19, count, enc.getGroupRole()));
            rowLabels.add(new Label(20, count, enc.getRComments()));
            rowLabels.add(new Label(21, count, enc.getVerbatimLocality()));
            rowLabels.add(new Label(22, count, enc.getAlternateID()));

            rowLabels.add(new Label(23, count, ServletUtilities.getEncounterUrl(enc.getCatalogNumber(),request)));
            rowLabels.add(new Label(24, count, ServletUtilities.getIndividualUrl(enc.getIndividualID(),request)));
            rowLabels.add(new Label(25, count, ServletUtilities.getOccurrenceUrl(enc.getOccurrenceID(),request)));


            for(Label lab: rowLabels) {
              sheet.addCell(lab);
            }
         } //end for loop iterating encounters

         workbookOBIS.write();
         workbookOBIS.close();

      // end Excel export =========================================================



        //business logic end here

        outp.close();
        outp=null;

      }
      catch(Exception ioe){
        ioe.printStackTrace();
        response.setContentType("text/html");
        PrintWriter out = response.getWriter();
        out.println(ServletUtilities.getHeader(request));
        out.println("<html><body><p><strong>Error encountered</strong> with file writing. Check the relevant log.</p>");
        out.println("<p>Please let the webmaster know you encountered an error at: EncounterSearchExportExcelFile servlet</p></body></html>");
        out.println(ServletUtilities.getFooter(context));
        out.close();
        outp.close();
        outp=null;
      }


    }
    catch(Exception e) {
      e.printStackTrace();
      response.setContentType("text/html");
      PrintWriter out = response.getWriter();
      out.println(ServletUtilities.getHeader(request));
      out.println("<html><body><p><strong>Error encountered</strong></p>");
        out.println("<p>Please let the webmaster know you encountered an error at: EncounterSearchExportExcelFile servlet</p></body></html>");
        out.println(ServletUtilities.getFooter(context));
        out.close();
    }

    myShepherd.rollbackDBTransaction();
    myShepherd.closeDBTransaction();

      //now write out the file
      response.setContentType("application/msexcel");
      response.setHeader("Content-Disposition","attachment;filename="+filename);
      ServletContext ctx = getServletContext();
      //InputStream is = ctx.getResourceAsStream("/encounters/"+filename);
     InputStream is=new FileInputStream(excelFile);

      int read=0;
      byte[] bytes = new byte[BYTES_DOWNLOAD];
      OutputStream os = response.getOutputStream();

      while((read = is.read(bytes))!= -1){
        os.write(bytes, 0, read);
      }
      os.flush();
      os.close();
    }

  }
