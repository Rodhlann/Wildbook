package org.ecocean.servlet;

import org.ecocean.*;
import org.ecocean.media.*;

import javax.servlet.ServletConfig;
import javax.servlet.ServletException;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

/*import java.io.IOException;
import java.io.PrintWriter;
import java.io.InputStream;
import java.io.Writer;*/
import java.io.*;
import java.util.StringTokenizer;
import java.util.List;
import java.util.Map;

//import JSONObject;
//import JSONArray;

// UGH -- we use two different JSON libraries!
import org.datanucleus.api.rest.orgjson.JSONObject;
import org.datanucleus.api.rest.orgjson.JSONArray;
import org.datanucleus.api.rest.orgjson.JSONException;

/**
 * Takes a mongo-like JS query from the UI (on any MediaAsset-containing-class),
 * and returns an array of all MediaAssets from those objects that matched the query.
 * <pre><code> // note that the tags to the left simply delimit the example
 * var args = {class: 'org.ecocean.media.MediaAsset', query: {}, range: 100};
 * // var args = {class: 'org.ecocean.Encounter', query: {sex: {$ne: "male"}}, range: 15};
 * // var args = {class: 'org.ecocean.Encounter', query: {}};
 * $.post( "TranslateQuery", args, function( data ) {
 *   $(".results").append( "Data Loaded: " + data );
 * });
 * </code></pre>
 * @requestParameter class a string naming a Wildbook class, e.g. org.ecocean.Encounter or org.ecocean.media.MediaAsset. Note this is the only required argument.
 * @requestParameter query a mongo-query-syntax JSON object defining the search on 'class'.
 * @requestParameter rangeMin the start index of the results. E.g. rangeMin=10 returns search
 * results starting with the 10th entry. Default 0. Note that sorting options are required (TODO)
 * for this to be as useful as we'd like, as results are currently returned in whatever order JDOQL needs.
 * @requestParameter range the end index of the results, similarly to rangeMin. Defaults to 100 because the server is slow on anything longer, and it's hard to imagine a UI call that would need so many objects.
 * @returns a 2-item JSONObject: {assets: <JSONArray of MediaAssets>, queryMetadata: <JSONObject for populating UI fields e.g. captions>}
 */
public class TranslateQuery extends HttpServlet {

  public void init(ServletConfig config) throws ServletException {
    super.init(config);
  }


  /**
   * From stackOverflow http://stackoverflow.com/a/7085652
   **/
  public static JSONObject requestParamsToJSON(HttpServletRequest req) throws JSONException {
    JSONObject jsonObj = new JSONObject();
    Map<String,String[]> params = req.getParameterMap();
    for (Map.Entry<String,String[]> entry : params.entrySet()) {
      String v[] = entry.getValue();
      Object o = (v.length == 1) ? v[0] : v;
      jsonObj.put(entry.getKey(), o);
    }
    return jsonObj;
  }

  public void doOptions(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {
      response.setHeader("Access-Control-Allow-Origin", "*");
      response.setHeader("Access-Control-Allow-Methods", "GET, POST");
      if (request.getHeader("Access-Control-Request-Headers") != null) response.setHeader("Access-Control-Allow-Headers", request.getHeader("Access-Control-Request-Headers"));
      //response.setContentType("text/plain");
  }

  public void doGet(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {
    doPost(request, response);
  }

  public void doPost(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {
    response.setHeader("Access-Control-Allow-Origin", "*");  //allow us stuff from localhost

    try {
    JSONObject res = new JSONObject("{\"success\": false, \"error\": \"unknown\"}");
    String getOut = "";

    String context="context0";
    context=ServletUtilities.getContext(request);
    Shepherd myShepherd = new Shepherd(context);

    // set up response type: should this be JSON?
    response.setContentType("text/plain");
    PrintWriter out = response.getWriter();

    org.datanucleus.api.rest.orgjson.JSONArray resultArray = new org.datanucleus.api.rest.orgjson.JSONArray();
    org.datanucleus.api.rest.orgjson.JSONObject resultMetadata = new org.datanucleus.api.rest.orgjson.JSONObject();

    try {

      JSONObject json = requestParamsToJSON(request);
      System.out.println("Starting TranslateQuery with request-as-JSON= "+json.toString());

      if (json.optString("class").isEmpty()) {
        throw new IOException("TranslateQuery argument requires a \"class\" field, which could not be parsed from your input.");
      }
      if (json.optString("query")==null) {
        json.put("query", new JSONObject());
      }

      WBQuery wbq = new WBQuery(json);
      List<Object> queryResult = wbq.doQuery(myShepherd);
      int nResults = queryResult.size();
      String[] queryResultStrings = new String[nResults];
      String queryClass = wbq.getCandidateClass().getName();
      //out.println("</br>queryClass = "+queryClass);

      // hackey debug mode
      if (request.getParameter("debug")!=null) {
        String translatedQuery = wbq.toJDOQL();
        out.println("{debug: {JDOQL: \""+translatedQuery+"\" }}, ");
      }
      switch (queryClass) {

        case "org.ecocean.Encounter":
          boolean printedAResYet = false;
          for (int i=0;i<nResults;i++) {
            Encounter enc = (Encounter) queryResult.get(i);
            Util.concatJsonArrayInPlace(resultArray, enc.sanitizeMedia(request));
          }
          break;

        case "org.ecocean.Annotation":
          for (int i=0;i<nResults;i++) {
            Annotation ann = (Annotation) queryResult.get(i);
            resultArray.put(ann.sanitizeMedia(request));
          }
          break;

        case "org.ecocean.media.MediaAsset":
          for (int i=0;i<nResults;i++) {
            MediaAsset ma = (MediaAsset) queryResult.get(i);
            resultArray.put(ma.sanitizeJson(request, new JSONObject()));
          }
          break;

        case "org.ecocean.media.MediaAssetSet":
          for (int i=0;i<nResults;i++) {
            MediaAssetSet maSet = (MediaAssetSet) queryResult.get(i);
            res = maSet.sanitizeJson(request, new JSONObject());
            if (res.optJSONArray("assets")!=null) {
              Util.concatJsonArrayInPlace(resultArray, res.getJSONArray("assets"));
            }
          }
          break;

        case "org.ecocean.MarkedIndividual":
        for (int i=0;i<nResults;i++) {
            MarkedIndividual mi = (MarkedIndividual) queryResult.get(i);
            Util.concatJsonArrayInPlace(resultArray, mi.sanitizeMedia(request));
          }
          break;
      } // end switch(queryClass)

      org.datanucleus.api.rest.orgjson.JSONObject fullResults = new org.datanucleus.api.rest.orgjson.JSONObject();
      fullResults.put("assets", resultArray);
      fullResults.put("queryMetadata", resultMetadata);
      out.print(fullResults.toString());

    }
    catch (Exception e) {
      StringWriter sw = new StringWriter();
      PrintWriter pw = new PrintWriter(sw);
      e.printStackTrace(pw);
      res.put("error", sw.toString());
      out.println(res.toString());
      myShepherd.rollbackDBTransaction();
      response.setStatus(HttpServletResponse.SC_INTERNAL_SERVER_ERROR);
    }

    out.close();
    myShepherd.closeDBTransaction();

  }
  catch (JSONException e) {
    // hmmm how do we handle this
  }
  } // end doPost
}
