package org.ecocean.servlet;

import java.io.IOException;
import java.io.PrintWriter;
import java.text.MessageFormat;
import java.util.ArrayList;
import java.util.Enumeration;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

import javax.servlet.ServletException;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

import org.ecocean.CommonConfiguration;
import org.ecocean.Encounter;
import org.ecocean.Measurement;
import org.ecocean.Shepherd;

public class EncounterSetMeasurements extends HttpServlet {

  private static final Pattern MEASUREMENT_NAME = Pattern.compile("measurement(\\d+)\\(([^)]*)\\)");
  
  @Override
  protected void doGet(HttpServletRequest req, HttpServletResponse resp)
      throws ServletException, IOException {
    doPost(req, resp);
  }

  @Override
  protected void doPost(HttpServletRequest request, HttpServletResponse response)
      throws ServletException, IOException {
    Shepherd myShepherd=new Shepherd();
    //set up for response
    response.setContentType("text/html");
    PrintWriter out = response.getWriter();
    boolean locked=false;

    String encNum="None";

    encNum=request.getParameter("encounter");
    myShepherd.beginDBTransaction();
    if (myShepherd.isEncounter(encNum)) {
      Encounter enc=myShepherd.getEncounter(encNum);
      List<RequestEventValues> list = new ArrayList<RequestEventValues>();
      int index = 0;
      RequestEventValues requestEventValues = findRequestEventValues(request, index++);
      try {
        while (requestEventValues != null) {
          list.add(requestEventValues);
          Measurement measurement;
          if (requestEventValues.id == null || requestEventValues.id.trim().length() == 0) {
            // New Event -- the user didn't enter any values the first time.
            measurement = new Measurement(encNum, requestEventValues.type, requestEventValues.value, requestEventValues.units, requestEventValues.samplingProtocol);
            enc.addMeasurement(measurement);
          }
          else {
            measurement  = myShepherd.findDataCollectionEvent(Measurement.class, requestEventValues.id);
            measurement.setValue(requestEventValues.value);
            measurement.setSamplingProtocol(requestEventValues.samplingProtocol);
          }

          requestEventValues = findRequestEventValues(request, index++);
        }
      } catch(Exception ex) {
        ex.printStackTrace();
        locked = true;
        myShepherd.rollbackDBTransaction();
        myShepherd.closeDBTransaction();
      }
      if (!locked) {
        myShepherd.commitDBTransaction();
        myShepherd.closeDBTransaction();
        out.println(ServletUtilities.getHeader(request));
        out.println("<p><strong>Success!</strong> I have successfully set the following measurement values:");
        for (RequestEventValues requestEventValue : list) {
          out.println(MessageFormat.format("<br/>{0} set to {1}", requestEventValue.type, requestEventValue.value));
        }

        out.println("<p><a href=\"http://"+CommonConfiguration.getURLLocation(request)+"/encounters/encounter.jsp?number="+encNum+"\">Return to encounter "+encNum+"</a></p>\n");
        out.println(ServletUtilities.getFooter());
      }
      else {
        out.println(ServletUtilities.getHeader(request));
        out.println("<strong>Failure!</strong> This encounter is currently being modified by another user, or an exception occurred. Please wait a few seconds before trying to modify this encounter again.");

        out.println("<p><a href=\"http://"+CommonConfiguration.getURLLocation(request)+"/encounters/encounter.jsp?number="+encNum+"\">Return to encounter "+encNum+"</a></p>\n");
        out.println(ServletUtilities.getFooter());
      }
      
    }
    else {
      myShepherd.rollbackDBTransaction();
      out.println(ServletUtilities.getHeader(request));
      out.println("<strong>Error:</strong> I was unable to set the measurements. I cannot find the encounter that you intended in the database.");
      out.println(ServletUtilities.getFooter());

    }
    out.close();
    myShepherd.closeDBTransaction();
  } 
  
  // The parameter names are of the form "measurement0(id)", "measurement0(type)", "measurement0(value"), "measurement1(id)", "measurement1(type)", "measurement1(value)" etc.
  // All of same numbered names are part of the same measurement event.

  private RequestEventValues findRequestEventValues(HttpServletRequest request, int index) {
    String key = "measurement" + index + '(';
    final int keyLength = key.length();
    Enumeration enumeration = request.getParameterNames();
    String id = null;
    String type = null;
    Double value = null;
    String units = null;
    String samplingProtocol = null;
    while (enumeration.hasMoreElements()) {
      String paramName = (String) enumeration.nextElement();
      if (paramName.startsWith(key)) {
        String paramValue = request.getParameter(paramName);
        if (paramValue != null) {
          paramValue = paramValue.trim();
        }
        if (paramName.substring(keyLength).startsWith("id")) {
          id = paramValue;
        }
        else if (paramName.substring(keyLength).startsWith("type")) {
          type = paramValue;
        }
        else if (paramName.substring(keyLength).startsWith("value")) {
          if (paramValue != null) {
            try {
              value = Double.valueOf(paramValue);
            } catch (NumberFormatException e) {
            }
          }
        }
        else if (paramName.substring(keyLength).startsWith("units")) {
          units = paramValue;
        }
        else if (paramName.substring(keyLength).startsWith("samplingProtocol")) {
          samplingProtocol = paramValue;
        }
      }
    }
    if (id != null || type != null || value != null) {
      return new RequestEventValues(id, type, value, units, samplingProtocol);
    }
    return null;
  }

  private static class RequestEventValues {
    private String id;
    private String type;
    private Double value;
    private String units;
    private String samplingProtocol;
    public RequestEventValues(String id, String type, Double value, String units, String samplingProtocol) {
      this.id = id;
      this.type = type;
      this.value = value;
      this.units = units;
      this.samplingProtocol = samplingProtocol;
    }
  }
}
