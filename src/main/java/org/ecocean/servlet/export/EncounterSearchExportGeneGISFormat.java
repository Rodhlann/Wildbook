package org.ecocean.servlet.export;
import javax.servlet.*;
import javax.servlet.http.*;
import java.io.*;
import java.util.*;
import org.ecocean.*;
import org.ecocean.genetics.*;
import org.ecocean.servlet.ServletUtilities;

import javax.jdo.*;
//import com.poet.jdo.*;
import java.lang.StringBuffer;


//adds spots to a new encounter
public class EncounterSearchExportGeneGISFormat extends HttpServlet{
  
  private static final int BYTES_DOWNLOAD = 1024;

  
  public void init(ServletConfig config) throws ServletException {
      super.init(config);
    }

  
  public void doGet(HttpServletRequest request, HttpServletResponse response) throws ServletException,IOException {
      doPost(request, response);
  }
    


  public void doPost(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException{
    
    //set the response
    
    
    Shepherd myShepherd = new Shepherd();
    

    
    Vector rEncounters = new Vector();
    
    //setup data dir
    String rootWebappPath = getServletContext().getRealPath("/");
    File webappsDir = new File(rootWebappPath).getParentFile();
    File shepherdDataDir = new File(webappsDir, CommonConfiguration.getDataDirectoryName());
    if(!shepherdDataDir.exists()){shepherdDataDir.mkdir();}
    File encountersDir=new File(shepherdDataDir.getAbsolutePath()+"/encounters");
    if(!encountersDir.exists()){encountersDir.mkdir();}
    
    //set up the files
    String gisFilename = "geneGIS_export_" + request.getRemoteUser() + ".csv";
    File gisFile = new File(encountersDir.getAbsolutePath()+"/" + gisFilename);


    myShepherd.beginDBTransaction();
    
    
    try {
      
      //set up the output stream
      FileOutputStream fos = new FileOutputStream(gisFile);
      OutputStreamWriter outp = new OutputStreamWriter(fos);
      
      try{
      
      
        EncounterQueryResult queryResult = EncounterQueryProcessor.processQuery(myShepherd, request, "year descending, month descending, day descending");
        rEncounters = queryResult.getResult();
      
        int numMatchingEncounters=rEncounters.size();
      
        //build the CSV file header
        StringBuffer locusString=new StringBuffer("");
        int numLoci=2; //most covered species will be loci
        try{
          numLoci=(new Integer(CommonConfiguration.getProperty("numLoci"))).intValue();
        }
        catch(Exception e){System.out.println("numPloids configuration value did not resolve to an integer.");e.printStackTrace();}
      
        for(int j=0;j<numLoci;j++){
          locusString.append(",Locus"+(j+1)+" A1,Locus"+(j+1)+" A2");
        
        }
        //out.println("<html><body>");
        //out.println("Individual ID,Other ID 1,Date,Time,Latitude,Longitude,Area,Sub Area,Sex,Haplotype"+locusString.toString());
      
        outp.write("Individual ID,Other ID 1,Date,Time,Latitude,Longitude,Area,Sub Area,Sex,Haplotype"+locusString.toString()+"\n");
      
        for(int i=0;i<numMatchingEncounters;i++){
        
          Encounter enc=(Encounter)rEncounters.get(i);
          String assembledString="";
          if(enc.getIndividualID()!=null){assembledString+=enc.getIndividualID();}
          if(enc.getAlternateID()!=null){assembledString+=","+enc.getAlternateID();}
          else{assembledString+=",";}
        
          String dateString=",";
          if(enc.getYear()>0){
            dateString+=enc.getYear();
            if(enc.getMonth()>0){
              dateString+=("-"+enc.getMonth());
              if(enc.getDay()>0){dateString+=("-"+enc.getDay());}
            }
          }
          assembledString+=dateString;
        
          String timeString=",";
          if(enc.getHour()>-1){timeString+=enc.getHour()+":"+enc.getMinutes();}
          assembledString+=timeString;
        
        
        
          if((enc.getDecimalLatitude()!=null)&&(enc.getDecimalLongitude()!=null)){
            assembledString+=","+enc.getDecimalLatitude();
            assembledString+=","+enc.getDecimalLongitude();
          }
          else{assembledString+=",,";}
        
          assembledString+=","+enc.getVerbatimLocality();
          assembledString+=","+enc.getLocationID();
          assembledString+=","+enc.getSex();
        
          //find and print the haplotype
          String haplotypeString=",";
          if(enc.getHaplotype()!=null){haplotypeString+=enc.getHaplotype();}
        
          //find and print the ms markers
          String msMarkerString="";
          List<TissueSample> samples=enc.getTissueSamples();
          int numSamples=samples.size();
          boolean foundMsMarkers=false;
          for(int k=0;k<numSamples;k++){
            if(!foundMsMarkers){
              TissueSample t=samples.get(k);
              List<GeneticAnalysis> analyses=t.getGeneticAnalyses();
              int aSize=analyses.size();
              for(int l=0;l<aSize;l++){
                GeneticAnalysis ga=analyses.get(l);
                if(ga.getAnalysisType().equals("MicrosatelliteMarkers")){
                  foundMsMarkers=true;
                  MicrosatelliteMarkersAnalysis ga2=(MicrosatelliteMarkersAnalysis)ga;
                  List<Locus> loci=ga2.getLoci();
                  int localLoci=loci.size();
                  for(int m=0;m<localLoci;m++){
                    Locus locus=loci.get(m);
                    if(locus.getAllele0()!=null){msMarkerString+=","+locus.getAllele0();}
                    else{msMarkerString+=",";}
                    if(locus.getAllele1()!=null){msMarkerString+=","+locus.getAllele1();}
                    else{msMarkerString+=",";}
                  }
              
                }
              }
            }
          }
        
          //out.println("<p>"+assembledString+haplotypeString+msMarkerString+"</p>");
          outp.write(assembledString+haplotypeString+msMarkerString+"\n");

        }
        outp.close();
        outp=null;
        
        //now write out the file
        response.setContentType("text/csv");
        response.setHeader("Content-Disposition","attachment;filename="+gisFilename);
        ServletContext ctx = getServletContext();
        //InputStream is = ctx.getResourceAsStream("/encounters/"+gisFilename);
       InputStream is=new FileInputStream(gisFile);
        
        
        int read=0;
        byte[] bytes = new byte[BYTES_DOWNLOAD];
        OutputStream os = response.getOutputStream();
       
        while((read = is.read(bytes))!= -1){
          os.write(bytes, 0, read);
        }
        os.flush();
        os.close(); 
        
        
      }
      catch(Exception ioe){
        ioe.printStackTrace();
        response.setContentType("text/html");
        PrintWriter out = response.getWriter();
        out.println(ServletUtilities.getHeader(request));
        out.println("<html><body><p><strong>Error encountered</strong> with file writing. Check the relevant log.</p>");
        out.println("<p>Please let the webmaster know you encountered an error at: EncounterSearchExportGeneGISFormat servlet</p></body></html>");
        out.println(ServletUtilities.getFooter());
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
        out.println("<p>Please let the webmaster know you encountered an error at: EncounterSearchExportGeneGISFormat servlet</p></body></html>");
        out.println(ServletUtilities.getFooter());
        out.close();
    }
    myShepherd.rollbackDBTransaction();
    myShepherd.closeDBTransaction();

      
    }

  
  }