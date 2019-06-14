package org.ecocean.servlet;

import org.ecocean.*;

import javax.servlet.ServletConfig;
import javax.servlet.ServletException;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import org.json.JSONObject;
import org.json.JSONArray;
import org.json.JSONException;
import org.ecocean.media.*;
import java.util.List;
import java.util.ArrayList;

import java.io.*;

public class MediaAssetAttach extends HttpServlet {

  public void init(ServletConfig config) throws ServletException {
    super.init(config);
  }

  public void doOptions(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {
      ServletUtilities.doOptions(request, response);
  }

  public void doGet(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {
    doPost(request, response);
  }

  public void doPost(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {
    response.setHeader("Access-Control-Allow-Origin", "*");
    JSONObject res = new JSONObject();


    JSONObject args = new JSONObject();

    try {
      args = ServletUtilities.jsonFromHttpServletRequest(request);
    } catch (JSONException e){
      // urgh... depending on if POSTing from Postman or $.ajax, parameters must be handled differently.
      args.put("attach",request.getParameter("attach"));
      args.put("detach",request.getParameter("detach"));
      args.put("EncounterID", request.getParameter("EncounterID"));
      args.put("MediaAssetID", request.getParameter("MediaAssetID"));
      //leave this print in case of shenanigans even though we have alternate behavior
      e.printStackTrace();
    }

    //String encID = request.getParameter("EncounterID");
    //String maID = request.getParameter("MediaAssetID");
    String encID = args.optString("EncounterID");

    //resolve all asset ids into one list
    List<String> maIds = new ArrayList<String>();
    try {
      if (args.has("MediaAssetID")&&args.get("MediaAssetID")!=null) {
        maIds.add(String.valueOf(args.get("MediaAssetID")));
      }
      JSONArray jarr = args.optJSONArray("mediaAssetIds");
      if (jarr != null) for (int i = 0 ; i < jarr.length() ; i++) {
        if (jarr.opt(i)!=null) {
          String arrId = String.valueOf(jarr.opt(i));
          if ((arrId != null) && !maIds.contains(arrId)) maIds.add(arrId);
        }
      }
    } catch (JSONException je) {
      je.printStackTrace();
    }

    System.out.println("Servlet received maIds="+maIds+" and encID="+encID);

    if (encID == null || maIds.size() < 1) {
      throw new IOException("MediaAssetAttach servlet requires both a \"MediaAssetID\" and an \"EncounterID\" argument. Servlet received maIds="+maIds+" and encID="+encID);
    }

    res.put("maIds", new JSONArray(maIds));

    String context = ServletUtilities.getContext(request);
    Shepherd myShepherd = new Shepherd(context);
    myShepherd.setAction("MediaAssetAttach.class");
    PrintWriter out = response.getWriter();
  
    try {
      myShepherd.beginDBTransaction();
      Encounter enc = myShepherd.getEncounter(encID);
      if (enc == null) throw new ServletException("No Encounter with id "+encID+" found in database.");
      
      List<MediaAsset> mas = new ArrayList<MediaAsset>();
      for (String maId : maIds) {
        MediaAsset ma = myShepherd.getMediaAsset(maId);
        if (ma == null) throw new ServletException("No MediaAsset with id "+maId+" found in database.");
        mas.add(ma);
      }
      
      // ATTACH MEDIAASSET TO ENCOUNTER
      JSONArray alreadyAttached = new JSONArray();
      if (args.optString("attach")!=null && args.optString("attach").equals("true")) {
        for (MediaAsset ma : mas) {
          
          if (enc.hasTopLevelMediaAsset(ma.getId())) {
            alreadyAttached.put(ma.getId());
          } else {
            enc.addMediaAsset(ma);
          } 
        }
        if (alreadyAttached.length() > 0) res.put("alreadyAttached", alreadyAttached);
        res.put("action","attach");
        res.put("success",true);

      } else if (args.optString("detach")!=null && args.optString("detach").equals("true")) {
      // DETACH MEDIAASSET FROM ENCOUNTER
          try {
            boolean success = false;
            for (MediaAsset ma : mas) {
                System.out.println("Trying to remove MA = "+ma.getId()+" from encounter ID = "+enc.getID());
                List<Annotation> maAnns = new ArrayList<Annotation>(ma.getAnnotations());
                List<Annotation> encAnns = new ArrayList<Annotation>(enc.getAnnotations());
                //only set annotations on the media asset that belong to this encounter to false
                encAnns.retainAll(maAnns);  
                for (Annotation ann : maAnns) {
                  ann.setMatchAgainst(false);
                } 
                enc.removeMediaAsset(ma);
    
                String undoLink = request.getScheme()+"://" + CommonConfiguration.getURLLocation(request) + "/MediaAssetAttach?attach=true&EncounterID="+encID+"&MediaAssetID="+ma.getId();
                String comments = "Detached MediaAsset " + ma.getId() + ". To undo this action, visit " + undoLink;
                enc.addComments("<p><em>" + request.getRemoteUser() + " on " + (new java.util.Date()).toString() + "</em><br>" + comments + " </p>");
                success = true;
            }
            res.put("action","detach");
            res.put("success", success);
          } catch (Exception e) {
            e.printStackTrace();
          }

      } else {
          res.put("args.optString",false);
          res.put("error", "unknown command");
          res.put("success", false);
      }
      myShepherd.commitDBTransaction();

    // DETACH MEDIAASSET FROM ENCOUNTER
    } catch (Exception e) {
      e.printStackTrace(out);
      myShepherd.rollbackDBTransaction();
    }
  finally {
    myShepherd.closeDBTransaction();
  }
  out.println(res.toString());
  out.close();

  }
}
