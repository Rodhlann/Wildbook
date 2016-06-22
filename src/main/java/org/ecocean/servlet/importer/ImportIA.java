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

    boolean firstTime = true;
    if (request.getParameter("skipInit")!=null) firstTime = false;

    String context="context0";
    context=ServletUtilities.getContext(request);
    Shepherd myShepherd = new Shepherd(context);
    PrintWriter out = response.getWriter();

    if (firstTime) initFeatureTypeAndAssetStore(myShepherd);

    int offset = 0;
    if (request.getParameter("offset")!=null) {
      offset = Integer.parseInt(request.getParameter("offset"));
    }

    out.println("\n\nStarting ImportIA servlet...");

    JSONObject imageSetRes = getFromIA("/api/imageset/json/", context, out);
    JSONArray fancyImageSetUUIDS = imageSetRes.optJSONArray("response");

    //int testingLimit = 10;

    //for (int i = 0; i < fancyImageSetUUIDS.length() && i < testingLimit; i++) {
    for (int i = 0; i < fancyImageSetUUIDS.length(); i++) {
      JSONObject fancyID = fancyImageSetUUIDS.getJSONObject(i);
      String occID = IBEISIA.fromFancyUUID(fancyID);

      JSONObject annotRes = getFromIA("/api/imageset/annot/uuids/json/?imageset_uuid_list=[" + fancyID + "]", context, out);
      // it's a singleton list, hence [0]
      JSONArray annotFancyUUIDs = annotRes.getJSONArray("response").getJSONArray(0);
      List<String> annotUUIDs = fromFancyUUIDList(annotFancyUUIDs);
      out.println("occID: " + occID + " has annotUUIDs " + annotUUIDs);
      List<Annotation> annots = IBEISIA.grabAnnotations(annotUUIDs, myShepherd);
      JSONArray iaNamesArray = null;
      try {
        iaNamesArray = IBEISIA.iaNamesFromAnnotUUIDs(annotFancyUUIDs);
      } catch (Exception e) {        e.printStackTrace(out);
      }

      List<String> uniqueNames = new ArrayList<String>();
      HashMap<String,ArrayList<Annotation>> annotGroups = new HashMap<String,ArrayList<Annotation>>();
      for (int j=0; j < iaNamesArray.length(); j++) {
        String thisName = iaNamesArray.getString(j);
        if (uniqueNames.contains(thisName)) continue;
        uniqueNames.add(thisName);
        annotGroups.put(thisName, new ArrayList<Annotation>());
      }

      for (int j=0; j < annots.size(); j++) {
        annotGroups.get(iaNamesArray.getString(j)).add(annots.get(j));
      }

      for (String uName : uniqueNames) {
        out.println("Number Annotations with "+uName+": "+annotGroups.get(uName).size());
      }

      for (String name : uniqueNames) {

        myShepherd.beginDBTransaction();

        Encounter enc = new Encounter(annotGroups.get(name));
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
          sex = IBEISIA.iaSexFromName(name);
        } catch (Exception ex) {}
        Double age = null;
        try {
            //guess this assumes we have at least one annot and it has age; could walk thru if not?
            age = IBEISIA.iaAgeFromAnnotUUID(annotGroups.get(name).get(0).getId());
        } catch (Exception ex) {}
        if (age != null) enc.setAge(age);
        myShepherd.storeNewEncounter(enc, Util.generateUUID());
        if (myShepherd.isMarkedIndividual(name)) {
          MarkedIndividual ind = myShepherd.getMarkedIndividual(name);
          if ((ind.getSex() == null) && (sex != null)) ind.setSex(sex); //only if not set already
          ind.addEncounter(enc, context);
        } else {
          MarkedIndividual ind = new MarkedIndividual(name, enc);
          if (sex != null) ind.setSex(sex);
          myShepherd.storeNewMarkedIndividual(ind);
          myShepherd.commitDBTransaction();
          myShepherd.beginDBTransaction();
        }
        for (Annotation ann: annotGroups.get(name)) {
          myShepherd.storeNewAnnotation(ann);
        }

        myShepherd.commitDBTransaction();

      }
    }

    myShepherd.closeDBTransaction();


  }

  private void initFeatureTypeAndAssetStore(Shepherd myShepherd) {
    FeatureType.initAll(myShepherd);
    String rootDir = getServletContext().getRealPath("/");
    String baseDir = ServletUtilities.dataDir("context0", rootDir);
    String assetStorePath="/data/wildbook_data_dir/encounters";
    //String rootURL="http://localhost:8080";
    String rootURL="http://52.38.106.238:8080/wildbook";
    String assetStoreURL=rootURL+"/wildbook_data_dir/encounters";



    //////////////// begin local //////////////
    LocalAssetStore as = new LocalAssetStore("Mpala-Asset-Store", new File(assetStorePath).toPath(), assetStoreURL, true);
    myShepherd.getPM().makePersistent(as);
  }

  // I always swallow errors in the interest of clean code!
  private JSONObject getFromIA(String urlSuffix, String context, PrintWriter outForErrors) throws IOException {
    JSONObject res = new JSONObject();
    try {
      res = RestClient.get(IBEISIA.iaURL("context0", urlSuffix));
    }
    catch (MalformedURLException e) {
      outForErrors.println("MalformedURLException on getFromIA()"+urlSuffix+")");
      e.printStackTrace(outForErrors);
    }
    catch (NoSuchAlgorithmException e) {
      outForErrors.println("NoSuchAlgorithmException on getFromIA()"+urlSuffix+")");
      e.printStackTrace(outForErrors);
    }
    catch (InvalidKeyException e) {
      outForErrors.println("InvalidKeyException on getFromIA()"+urlSuffix+")");
      e.printStackTrace(outForErrors);
    }
    catch (IOException e) {
      outForErrors.println("IOException on getFromIA()"+urlSuffix+")");
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

}
