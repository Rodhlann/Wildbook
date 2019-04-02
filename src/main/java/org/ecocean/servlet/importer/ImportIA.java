package org.ecocean.servlet.importer;

import org.ecocean.*;
import org.ecocean.servlet.*;
import org.ecocean.identity.*;
import org.ecocean.media.*;

import javax.servlet.ServletConfig;
import javax.servlet.ServletException;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import java.security.NoSuchAlgorithmException;
import java.security.InvalidKeyException;

import java.net.URL;
import java.net.MalformedURLException;
import java.util.List;
import java.util.ArrayList;
import java.util.Set;
import java.util.HashSet;
import java.util.HashMap;
import org.joda.time.DateTime;


import org.json.JSONObject;
import org.json.JSONArray;

import java.io.*;

public class ImportIA extends HttpServlet {

  public void init(ServletConfig config) throws ServletException {
    super.init(config);
  }

  public void doGet(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {
    doPost(request, response);
  }


  public void doPost(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {
    String importId = Util.generateUUID();
    String context="context0";
    // a "context=context1" in the URL should be enough
    context=ServletUtilities.getContext(request);

    Shepherd myShepherd = new Shepherd(context);
    myShepherd.setAction("ImportIA");
    FeatureType.initAll(myShepherd);
    PrintWriter out = response.getWriter();

    int offset = 0;
    if (request.getParameter("offset")!=null) {
      offset = Integer.parseInt(request.getParameter("offset"));
    }

    //by default, we now will NOT create Occurrence(s) out of IA ImageSet(s) as they are fairly different things
    //  mostly cuz this makes "co-occurring" Encounters where we probably dont want them
    boolean createOccurrences = Util.requestParameterSet(request.getParameter("createOccurrences"));

    out.println("<h1>Starting ImportIA servlet | importId=" + importId + "</h1>");
    myShepherd.beginDBTransaction();

    String urlSuffix = "/api/imageset/json/?is_special=False";
    JSONObject imageSetRes = getFromIA(urlSuffix, context, out);
    JSONArray fancyImageSetUUIDS = imageSetRes.optJSONArray("response");

    if (imageSetRes==null && request.getParameter("doOnly") == null) {
      log(importId, "Error! getFromIA(\""+urlSuffix+"\", context, out) returned null!");
      return;
    } else if (fancyImageSetUUIDS==null) {
      log(importId, "Got a result from IA but failed to parse fancyImageSetUUIDS. imageSetRes = "+imageSetRes);
      return;
    }

    int testingLimit = -1;
    if (request.getParameter("testingLimit") != null) {
        try {
            testingLimit = Integer.parseInt(request.getParameter("testingLimit"));
        } catch (Exception ex) {}
    }

        String onlyOcc = null;
       if (request.getParameter("doOnly") != null) {
               onlyOcc = request.getParameter("doOnly");
               fancyImageSetUUIDS = new JSONArray();
               fancyImageSetUUIDS.put(IBEISIA.toFancyUUID(onlyOcc));
       }

//TODO add taxonomy=
    log(importId, "starting; urlSuffix=" + urlSuffix + "; testingLimit=" + testingLimit + "; doOnly=" + onlyOcc);
    log(importId, "IA source = " + IBEISIA.iaURL(context, ""));

    for (int i = 0; i < fancyImageSetUUIDS.length(); i++) {
        if ((testingLimit > 0) && (i >= testingLimit)) continue;
        JSONObject fancyID = fancyImageSetUUIDS.getJSONObject(i);
        Occurrence occ = null;
        String occID = IBEISIA.fromFancyUUID(fancyID);

      JSONObject annotRes = getFromIA("/api/imageset/annot/uuid/json/?imageset_uuid_list=[" + fancyID + "]", context, out);
      // it's a singleton list, hence [0]
      JSONArray annotFancyUUIDs = annotRes.getJSONArray("response").getJSONArray(0);

      List<String> annotUUIDs = fromFancyUUIDList(annotFancyUUIDs);
        out.println("<p>imageset has annotUUIDs.size() = <b>" + annotUUIDs.size() + "</b></p>");
        log(importId, "imageset has annotUUIDs.size() = " + annotUUIDs.size());

        //now we have to break this up a little since there are some pretty gigantic sets of annotations, it turns out.  :(
        // but ultimately we want to fill iaNamesArray and annots
        JSONArray iaNamesArray = new JSONArray();
        List<Annotation> annots = new ArrayList<Annotation>();
        int annotBatchSize = 100;

        int acount = 0;
        while (acount < annotUUIDs.size()) {

            List<String> thisBatch = new ArrayList<String>();
            JSONArray thisFancy = new JSONArray();
            while ((thisBatch.size() < annotBatchSize) && (acount < annotUUIDs.size())) {
                thisBatch.add(annotUUIDs.get(acount));
                thisFancy.put(IBEISIA.toFancyUUID(annotUUIDs.get(acount)));
                acount++;
            }
            if (thisBatch.size() > 0) {
                myShepherd.beginDBTransaction();
                //grabAnnotations() will only create new ones when necessary
                List<Annotation> these = IBEISIA.grabAnnotations(thisBatch, myShepherd);
                myShepherd.commitDBTransaction();
                annots.addAll(these);

                try {
                    JSONArray thisNames = IBEISIA.iaNamesFromAnnotUUIDs(thisFancy, context);
                    for (int ti = 0 ; ti < thisNames.length() ; ti++) {
                        iaNamesArray.put(thisNames.get(ti));
                    }
                } catch (Exception e) {
                    e.printStackTrace();
                }
            }
        }

        //at this point we should have annots and iaNamesArray filled
out.println("<p><b>iaNamesArray:</b> " + iaNamesArray + "</p>");

      List<String> uniqueNames = new ArrayList<String>();
      HashMap<String,ArrayList<Annotation>> annotGroups = new HashMap<String,ArrayList<Annotation>>();
      for (int j=0; j < iaNamesArray.length(); j++) {
        String thisName = iaNamesArray.getString(j);
        if (uniqueNames.contains(thisName)) continue;
        uniqueNames.add(thisName);
        annotGroups.put(thisName, new ArrayList<Annotation>());
      }

        log(importId, "uniqueNames -> (" + String.join(", ", uniqueNames) + ")");

      for (int j=0; j < annots.size(); j++) {
        annotGroups.get(iaNamesArray.getString(j)).add(annots.get(j));
      }

/*
    so... for now we clump into Encounter based on name.  this is probably not ideal.  but how else to do it?
    probably:  time + location, aka "Clumping" (sigh).... TODO FIXME ETC
*/
      for (String name : uniqueNames) {
        if (IBEISIA.unknownName(name)) {   // we need one encounter per annot for unknown!
            for (Annotation ann : annotGroups.get(name)) {
                Encounter enc = new Encounter(ann);
                enc.setMatchedBy("IBEIS IA");
                enc.setState("approved");
                myShepherd.beginDBTransaction();
                myShepherd.storeNewEncounter(enc, Util.generateUUID());
                myShepherd.storeNewAnnotation(ann);
                myShepherd.commitDBTransaction();
                log(importId, "created " + enc + " from " + ann);
                out.println("<p>Enc " + enc.getCatalogNumber() + " from <a href=\"obrowse.jsp?type=Annotation&id=" + ann.getId() + "\">Annot " + ann.getId() + "</a>");

                if (createOccurrences) {
                    myShepherd.beginDBTransaction();
                    if (occ == null) {
                        occ = myShepherd.getOccurrence(occID);
                        if (occ == null) occ = new Occurrence(occID, enc);
                    } else {
                        occ.addEncounter(enc);
                    }
                    myShepherd.getPM().makePersistent(occ);
                    myShepherd.commitDBTransaction();
                    out.println(" in Occ " + occ.getOccurrenceID());
                }
                out.println("</p>");
            }

        } else {
            Encounter enc = new Encounter(annotGroups.get(name));
            enc.setMatchedBy("IBEIS IA");
            enc.setState("approved");

            // here we have to check if this encounter has been added already

        /*
            note: this constructor will set the date/time on the Encounter "based upon the Annotations"
            (which currently means the .getDateTime() of the first MediaAsset -- but this algorithm may change).
            not sure if this is the desirable end result here, since we can also pull the Annotation times from IA as well.
            (see IBEISIA.iaDateTimeFromAnnotUUID() )  -- we might want to do that or fall back to that if the constructor
            fails to set something.  tho... i think jasonp said annot times just come from images, so.

            Similarly, it should also get lat/lon and species based upon IA values (if they have some).  note that IA also has sex, however,
            it is stored on the "names" (i.e. individuals) so is not sighting-based ... so only useful to us if it is a new individual.

            Age, however, we dont store anywhere "lower", so we need to get that explicitly ... however IA has that on each Annotation,
            so we just ... um.. i guess take the first one we can find?

            note also that adding encounters to individuals should(!) gracefully adjust the individual accordingly (set sex/taxonomy *if unset*)
        */
            String sex = null;
            try {
            sex = IBEISIA.iaSexFromAnnotUUID(annotGroups.get(name).get(0).getAcmId(), context);
            } catch (Exception ex) {}
            Double age = null;
            try {
                //guess this assumes we have at least one annot and it has age; could walk thru if not?
                age = IBEISIA.iaAgeFromAnnotUUID(annotGroups.get(name).get(0).getAcmId(), context);
            } catch (Exception ex) {}
            if (age != null) enc.setAge(age);
            myShepherd.beginDBTransaction();
            myShepherd.storeNewEncounter(enc, Util.generateUUID());
            myShepherd.commitDBTransaction();
            myShepherd.beginDBTransaction();

            //enc.setIndividualID(name);
            if (myShepherd.isMarkedIndividual(name)) {
                MarkedIndividual ind = myShepherd.getMarkedIndividual(name);
                if ((ind.getSex() == null) && (sex != null)) ind.setSex(sex); //only if not set already
                ind.addEncounter(enc);
            } else {
                MarkedIndividual ind = new MarkedIndividual(name, enc);
                if (sex != null) ind.setSex(sex);
                myShepherd.storeNewMarkedIndividual(ind);
                log(importId, "created new " + ind);
            }

            for (Annotation ann: annotGroups.get(name)) {
                myShepherd.storeNewAnnotation(ann);
            }
            myShepherd.commitDBTransaction();

            String annLog = "";
            String annWeb = "";
            for (Annotation a : annotGroups.get(name)) {
                annLog += " " + a;
                annWeb += " <a href=\"obrowse.jsp?type=Annotation&id=" + a.getId() + "\">Annot " + a.getId() + "</a> ";
            }
            log(importId, "name " + name + " created " + enc + " from " + annLog);
            out.println("<p><b>Name " + name + "</b> Enc " + enc.getCatalogNumber() + " from " + annWeb);

            if (createOccurrences) {
                myShepherd.beginDBTransaction();
                if (occ == null) {
                    occ = myShepherd.getOccurrence(occID);
                    if (occ == null) occ = new Occurrence(occID, enc);
                } else {
                    occ.addEncounter(enc);
                }
                myShepherd.getPM().makePersistent(occ);
                myShepherd.commitDBTransaction();
                out.println(" in Occ " + occ.getOccurrenceID());
            }

            out.println("</p>");

        }

      }

        if (occ != null) myShepherd.getPM().makePersistent(occ);
        myShepherd.commitDBTransaction();
    }

    //myShepherd.closeDBTransaction();

    log(importId, "completed");
    out.println("<p><i>completed</i></p>");

  }

  // I always swallow errors in the interest of clean code!
  private JSONObject getFromIA(String urlSuffix, String context, PrintWriter outForErrors) throws IOException {
    JSONObject res = new JSONObject();
    URL restGetString = IBEISIA.iaURL(context, urlSuffix);
    try {
      res = RestClient.get(restGetString);
    }
    catch (MalformedURLException e) {
      outForErrors.println("MalformedURLException on getFromIA()"+urlSuffix+"), which tried to GET "+restGetString);
      e.printStackTrace(outForErrors);
    }
    catch (NoSuchAlgorithmException e) {
      outForErrors.println("NoSuchAlgorithmException on getFromIA()"+urlSuffix+"), which tried to GET "+restGetString);
      e.printStackTrace(outForErrors);
    }
    catch (InvalidKeyException e) {
      outForErrors.println("InvalidKeyException on getFromIA()"+urlSuffix+"), which tried to GET "+restGetString);
      e.printStackTrace(outForErrors);
    }
    catch (IOException e) {
      outForErrors.println("IOException on getFromIA()"+urlSuffix+"), which tried to GET "+restGetString);
      e.printStackTrace(outForErrors);
    }
    if (res==null) throw new IOException("Could not get "+urlSuffix+"from server");
    return res;
  }

  private List<String> fromFancyUUIDList(JSONArray fancyUUIDs) {
    List<String> ids = new ArrayList<String>();
    for (int j = 0; j < fancyUUIDs.length(); j++) {
      ids.add(IBEISIA.fromFancyUUID(fancyUUIDs.getJSONObject(j)));
    }
    return ids;
  }

    private static void log(String importId, String message) {
        System.out.println("ImportIA [" + importId + "] " + Util.prettyPrintDateTime(new DateTime()) + " " + message);
    }

}
