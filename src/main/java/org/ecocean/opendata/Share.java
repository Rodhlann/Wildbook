/*
    optimistically named "Open Data" package will be for real-time sharing of data (e.g. OBIS, GBIF, etc)
*/

package org.ecocean.opendata;

import org.ecocean.Shepherd;
import org.ecocean.CommonConfiguration;
import java.util.Properties;
import org.ecocean.ShepherdProperties;
import org.ecocean.Util;
/*
import org.ecocean.Annotation;
import org.ecocean.Taxonomy;
import org.ecocean.media.MediaAsset;
import org.ecocean.media.MediaAssetFactory;
import org.ecocean.identity.IBEISIA;
import org.ecocean.servlet.ServletUtilities;
import java.util.List;
import java.util.Arrays;
import java.util.ArrayList;
import org.json.JSONObject;
import org.json.JSONArray;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import java.io.PrintWriter;
*/

public abstract class Share {
    private static final String PROP_FILE = "opendata.properties";
    protected String context = null;

    protected Share(final String context) {
        if (context == null) throw new IllegalArgumentException("need context");
        this.context = context;
    }

    public abstract void init();

    //public abstract String typeCode();  //this designates type, used in properties file etc.
    public String typeCode() {
        return this.getClass().getSimpleName();
    }

    public boolean isEnabled() {
        return Util.booleanNotFalse(getProperty("enabled", "false"));
    }

    public String getProperty(String label) {  //no-default
        return getProperty(label, (String)null);
    }
    public String getProperty(String label, String def) {
        Properties p = getProperties();
        if (p == null) {
            System.out.println("Share.getProperty(" + label + ") has no properties; opendata.properties unavailable?");
            return null;
        }
        return p.getProperty(typeCode() + "." + label, def);
    }
    private Properties getProperties() {
        if (context == null) throw new IllegalArgumentException("must have context set");
        try {
            return ShepherdProperties.getProperties(PROP_FILE, "", context);
        } catch (Exception ex) {
            return null;
        }
    }

    public void log(String msg) {
        System.out.println(new org.joda.time.DateTime() + " [" + this.typeCode() + "] " + msg);
    }

}
