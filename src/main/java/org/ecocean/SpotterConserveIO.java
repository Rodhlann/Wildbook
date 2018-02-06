package org.ecocean;

import org.json.JSONObject;
import org.json.JSONArray;
import javax.servlet.http.HttpServletRequest;
import org.ecocean.servlet.ServletUtilities;
import java.util.Properties;
import java.util.List;
import java.util.ArrayList;
import org.joda.time.DateTime;
import org.ecocean.datacollection.*;

public class SpotterConserveIO {

    public static String AUTH_USERNAME = null;
    public static String AUTH_PASSWORD = null;

    public static void init(HttpServletRequest request) {
        init(ServletUtilities.getContext(request));
    }

    public static void init(String context) {
        Properties props = ShepherdProperties.getProperties("spotter-conserve-io.properties", "", context);
        if (props == null) throw new RuntimeException("no spotter-conserve-io.properties");
        String debug = props.getProperty("debug");
        String consumerKey = props.getProperty("consumerKey");
    }


    //public SpotterConserveIO() {}

    /*
        we currently support two trip "types": Channel Island and WhaleAlert.  the prefixes ci and wa denote these flavors.
    */

    //////TODO this is an "Object" now cuz i dont have SurveyTrack here yet!  (get from colin)
    public static Object ciToSurveyTrack(JSONObject jin) {
        if (jin.optJSONArray("sightings") != null) {
            List<Occurrence> occs = new ArrayList<Occurrence>();
            JSONArray jocc = jin.getJSONArray("sightings");
            for (int i = 0 ; i < jocc.length() ; i++) {
                Occurrence occ = ciToOccurrence(jocc.optJSONObject(i));
                if (occ != null) occs.add(occ);
            }
            /////// now do something with occs!
        }

        if (jin.optJSONArray("weather") != null) {
            // maybe we make our own "weather datacollectionevent" !
            List<Observation> wths = new ArrayList<Observation>();
            JSONArray jw = jin.getJSONArray("weather");
            for (int i = 0 ; i < jw.length() ; i++) {
                Observation wth = ciToWeather(jw.optJSONObject(i));
                if (wth != null) wths.add(wth);
            }
            //.setWeather(wths);
        }
        return null;
    }


    public static Occurrence ciToOccurrence(JSONObject jin) {
        Occurrence occ = new Occurrence();
        occ.setOccurrenceID(Util.generateUUID());
        occ.setDateTimeCreated(toDateTime(jin.optString("create_date", null)));
        occ.setBearing(findDouble(jin, "device_bearing"));
        occ.decimalLatitude(resolveLatLon(jin, "device_latitude", "latitude"));
        occ.decimalLongitude(resolveLatLon(jin, "device_longitude", "longitude"));

        if (jin.optJSONArray("CINMS Behavior") != null) {
            List<Instant> bhvs = new ArrayList<Instant>();
            JSONArray jb = jin.getJSONArray("CINMS Behavior");
            for (int i = 0 ; i < jb.length() ; i++) {
                Observation bhv = ciToBehavior(jb.optJSONObject(i));
                if (bhv != null) bhvs.add(bhv);
            }
            occ.behaviors(bhvs);
        }

        if (jin.optJSONArray("CINMS Photo Log") != null) {
            ArrayList<Encounter> encs = new ArrayList<Encounter>();
            JSONArray je = jin.getJSONArray("CINMS Photo Log");
            for (int i = 0 ; i < je.length() ; i++) {
                Encounter enc = ciToEncounter(je.optJSONObject(i));
                if (enc != null) encs.add(enc);
            }
            occ.setEncounters(encs);
        }
        return occ;
    }


/*
    {
        create_date: "2017-06-03 18:41:00+00:00",
        Card Number: 1,
        PID Code: "SBE",
        Image Number Start: 1583,      \__  use these to fill out some (new!) kinda placeholder Features (via Annotations)
        Image Number End: 1588,        /
        Animals Identified: 1
}
*/
    public static Encounter ciToEncounter(JSONObject jin) {
        Encounter enc = new Encounter();
        enc.setCatalogNumber(Util.generateUUID());
        //enc.setGroupSize(findInteger(jin, "Animals Identified"));
        enc.setDynamicProperty("CINMS PID Code", jin.optString("PID Code", null));
        enc.setDynamicProperty("CINMS Card Number", jin.optString("Card Number", null));
        String dc = jin.optString("create_date", null);
        if (dc != null) {
            enc.setDWCDateAdded(dc);
            DateTime dt = toDateTime(dc);
            if (dt != null) enc.setDWCDateAdded(dt.getMillis());  //sets the millis version on enc.  SIGH!!!!!!!!!!!
        }
        String tax[] = ciSpeciesSplit(jin.optString("CINMS Species", null));
        if ((tax != null) && (tax.length > 1)) {
            enc.setGenus(tax[0]);
            enc.setSpecificEpithet(tax[1]);
        }

        //since we dont have proper images, but only references to them, we create annotations with special "placeholder" features
        int imageStart = jin.optInt("Image Number Start", -1);
        int imageEnd = jin.optInt("Image Number End", -1);
        if ((imageStart < 0) || (imageEnd < 0) || (imageEnd < imageStart)) {
            System.out.println("WARNING: " + enc + " had no valid image range [" + imageStart + " - " + imageEnd + "]");
        } else {
            ArrayList<Annotation> anns = new ArrayList<Annotation>();
            for (int i = imageStart ; i <= imageEnd ; i++) {
                JSONObject params = new JSONObject();
                params.put("PID Code", jin.optString("PID Code", null));
                params.put("Card Number", jin.optString("Card Number", null));
                params.put("Image Number", i);
                params.put("description", "Image number " + i + " Card Number " + jin.optString("Card Number", "Unknown") + ", PID Code " + jin.optString("PID Code", "Unknown"));
                Feature ft = new Feature("org.ecocean.MediaAssetPlaceholder", params);
                Annotation ann = new Annotation(ciSpeciesSplit(jin.optString("CINMS Species", null)), ft);
System.out.println(enc + ": just made " + ann);
                anns.add(ann);
            }
            enc.setAnnotations(anns);
        }

System.out.println("MADE " + enc);
        return enc;
    }

    public static Instant ciToBehavior(JSONObject jin) {
        String name = jin.optString("CINMS Behavior", null);
        DateTime dt = toDateTime(jin.optString("create_date", null));
        if ((name == null) || (dt == null)) return null;
        return new Instant(name, dt, null);
    }

    //someday, SpeciesTaxonomy!  sigh  TODO
    private static String ciSpecies(String species) {  //e.g. "Blue Whale" --> "Balaenoptera musculus" ... also: may be null
        return species;  //meh. for now.
    }
    private static String[] ciSpeciesSplit(String species) { //e.g. "Foo Bar" --> ["Foo", "Bar"]
        if (species == null) return null;
        return species.split(" +");
    }


    private static Double resolveLatLon(JSONObject jin, devKey, userKey) {
        Double devVal = findDouble(jin, devKey);
        Double userVal = findDouble(jin, userKey);
        //how we decide is a bit sketchy for now.  seems like even when the "same" the values vary by precision. :(
        //    so..... i will just favor the non-human for now!  haha
        if (devVal != null) return devVal;
        return userVal;
    }


    private static Double findDouble(JSONObject jin, String key) {
        if ((jin == null) || (jin.optDouble(key, 99999.0) == 99999.0)) return null;
        return jin.getDouble(key);
    }

    private static Integer findInteger(JSONObject jin, String key) {
        if ((jin == null) || (jin.optInt(key, 99999) == 99999)) return null;
        return jin.getInt(key);
    }
    
    //2017-06-03 21:31:16+00:00 assumed input.... really just changes space to T
    public static DateTime toDateTime(String dt) {
        if (dt == null) return null;
        return new DateTime(dt.replaceAll(" ", "T"));
    }

}
