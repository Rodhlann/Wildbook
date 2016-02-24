/*
 * This file is a part of Wildbook.
 * Copyright (C) 2015 WildMe
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * Foobar is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with Wildbook.  If not, see <http://www.gnu.org/licenses/>.
 */

package org.ecocean.media;

import org.ecocean.CommonConfiguration;
import org.ecocean.ImageAttributes;
import org.ecocean.Keyword;
import org.ecocean.Annotation;
import org.ecocean.Shepherd;
//import org.ecocean.Encounter;
import org.ecocean.identity.Feature;
import java.net.URL;
import java.nio.file.Path;
import java.nio.file.Files;
//import java.time.LocalDateTime;
import org.joda.time.DateTime;
import java.util.Date;
import org.json.JSONObject;
import org.json.JSONException;
import java.util.Set;
import java.util.HashMap;
import java.util.List;
import javax.servlet.http.HttpServletRequest;
import org.apache.commons.lang3.builder.ToStringBuilder;
import java.util.UUID;
import java.io.File;
import java.io.IOException;
import java.util.ArrayList;
//import java.io.FileInputStream;
import javax.jdo.Query;

/*
import java.awt.image.BufferedImage;
import javax.imageio.ImageIO;

import javax.imageio.ImageReader;
import javax.imageio.stream.ImageInputStream;
import java.util.Iterator;
*/

/*
import com.drew.imaging.ImageMetadataReader;
import com.drew.imaging.ImageProcessingException;
import com.drew.metadata.*;
import com.drew.metadata.exif.ExifSubIFDDirectory;
*/

/**
 * MediaAsset describes a photo or video that can be displayed or used
 * for processing and analysis.
 */
public class MediaAsset implements java.io.Serializable {
    static final long serialVersionUID = 8844223450447974780L;
    protected int id = MediaAssetFactory.NOT_SAVED;

    protected AssetStore store;
    protected JSONObject parameters;

    protected Integer parentId;

    protected long revision;

    protected JSONObject derivationMethod = null;

    protected MediaAssetMetadata metadata = null;

    protected ArrayList<String> labels;

    protected ArrayList<Feature> features;

    protected String hashCode;

    //protected MediaAssetType type;
    //protected Integer submitterid;


    //protected Set<String> tags;
    //protected Integer rootId;

    //protected AssetStore thumbStore;
    //protected Path thumbPath;
    //protected Path midPath;

    //private LocalDateTime metaTimestamp;
    //private Double metaLatitude;
    //private Double metaLongitude;


    /**
     * To be called by AssetStore factory method.
     */
/*
    public MediaAsset(final AssetStore store, final JSONObject params, final String category)
    {
        this(MediaAssetFactory.NOT_SAVED, store, params, MediaAssetType.fromFilename(path.toString()), category);
    }
*/


    public MediaAsset(final AssetStore store, final JSONObject params) {
        //this(store, params, null);
        this(MediaAssetFactory.NOT_SAVED, store, params);
    }


    public MediaAsset(final int id,
                      final AssetStore store,
                      final JSONObject params)
    {
        this.id = id;
        this.store = store;
        this.parameters = params;
        this.setRevision();
        this.setHashCode();
    }


    private URL getUrl(final AssetStore store, final Path path) {
        if (store == null) {
            return null;
        }

        return null; //store.webPath(path);
    }

    private String getUrlString(final URL url) {
        if (url == null) {
            return null;
        }

        return url.toExternalForm();
    }


    public int getId()
    {
        return id;
    }
    public void setId(int i) {
        id = i;
    }   

    //this is for Annotation mostly?  provides are reproducible uuid based on the MediaAsset id
    public String getUUID() {
        //UUID v3 seems to take an arbitrary bytearray in, so we construct one that is basically "Ma____" where "____" is the int id
        return generateUUIDv3((byte)77, (byte)97);
    }

    private String generateUUIDv3(byte b1, byte b2) {
        if (id == MediaAssetFactory.NOT_SAVED) return null;
        byte[] b = new byte[6];
        b[0] = b1;
        b[1] = b2;
        b[2] = (byte) (id >> 24);
        b[3] = (byte) (id >> 16);
        b[4] = (byte) (id >> 8);
        b[5] = (byte) (id >> 0);
        return UUID.nameUUIDFromBytes(b).toString();
    }

    public AssetStore getStore()
    {
        return store;
    }

    public Integer getParentId() {
        return parentId;
    }
    public void setParentId(Integer pid) {
        parentId = pid;
    }

    public MediaAsset getParentRoot(Shepherd myShepherd) {
        Integer pid = this.getParentId();
        if (pid == null) return this;
        MediaAsset par = MediaAssetFactory.load(pid, myShepherd);
        if (par == null) return this;  //orphaned!  fail!!
        return par.getParentRoot(myShepherd);
    }

    public JSONObject getParameters() {
//System.out.println("getParameters() called -> " + parameters);
        return parameters;
    }

    public void setParameters(JSONObject p) {
//System.out.println("setParameters(" + p + ") called");
        parameters = p;
    }

    public String getParametersAsString() {
//System.out.println("getParametersAsString() called -> " + parameters);
        if (parameters == null) return null;
        return parameters.toString();
    }

    public void setParametersAsString(String p) {
//System.out.println("setParametersAsString(" + p + ") called");
        if (p == null) return;
/*  skipping this for now, cuz weirdness going on  TODO
        if (p == null) {
            parameters = null;
            return;
        }
*/
        try {
            parameters = new JSONObject(p);
        } catch (JSONException je) {
            System.out.println(this + " -- error parsing parameters json string (" + p + "): " + je.toString());
            parameters = null;
        }
    }

    public JSONObject getDerivationMethod() {
        return derivationMethod;
    }
    public void setDerivationMethod(JSONObject dm) {
        derivationMethod = dm;
    }
    public void addDerivationMethod(String k, Object val) {
        if (derivationMethod == null) derivationMethod = new JSONObject();
        derivationMethod.put(k, val);
    }

    public String getDerivationMethodAsString() {
        if (derivationMethod == null) return null;
        return derivationMethod.toString();
    }
    public void setDerivationMethodAsString(String d) {
        if (d == null) {
            derivationMethod = null;
            return;
        }
        try {
            derivationMethod = new JSONObject(d);
        } catch (JSONException je) {
            System.out.println(this + " -- error parsing parameters json string (" + d + "): " + je.toString());
            derivationMethod = null;
        }
    }

    public long setRevision() {
        this.revision = System.currentTimeMillis();
        return this.revision;
    }

    public String setHashCode() {
        if (store == null) return null;
        this.hashCode = store.hashCode(parameters);
System.out.println("hashCode on " + this + " = " + this.hashCode);
        return this.hashCode;
    }

    public ArrayList<String> getLabels() {
        return labels;
    }
    public void setLabels(ArrayList<String> l) {
        labels = l;
    }
    public void addLabel(String s) {
        if (labels == null) labels = new ArrayList<String>();
        if (!labels.contains(s)) labels.add(s);
    }

    public ArrayList<Feature> getFeatures() {
        return features;
    }
    public void setFeatures(ArrayList<Feature> f) {
        features = f;
    }
    public void addFeature(Feature f) {
        if (features == null) features = new ArrayList<Feature>();
        if (!features.contains(f)) features.add(f);
    }

    //kinda sorta really only for Encounter.findAllMediaByFeatureId()
    public boolean hasFeatures(String[] featureIds) {
        if ((features == null) || (features.size() < 1)) return false;
        for (Feature f : features) {
            for (int i = 0 ; i < featureIds.length ; i++) {
                if (f.isType(featureIds[i])) return true;   //short-circuit on first match
            }
        }
        return false;
    }

    public Path localPath()
    {
        if (store == null) return null;
        return store.localPath(this);
    }

    public boolean cacheLocal() throws Exception {
        if (store == null) return false;
        return store.cacheLocal(this, false);
    }

    public boolean cacheLocal(boolean force) throws Exception {
        if (store == null) return false;
        return store.cacheLocal(this, force);
    }

    //indisputable attributes about the image (e.g. type, dimensions, colorspaces etc)
    // this is (seemingly?) always derived from MediaAssetMetadata, so .. yeah. make sure that is set (see note by getMetadata() )
    public ImageAttributes getImageAttributes() {
        if ((metadata == null) || (metadata.getData() == null)) return null;
        JSONObject attr = metadata.getData().optJSONObject("attributes");
        if (attr == null) return null;
        double w = attr.optDouble("width", -1);
        double h = attr.optDouble("height", -1);
        String type = attr.optString("contentType");
        if ((w < 1) || (h < 1)) return null;
        return new ImageAttributes(w, h, type);
    }

    public double getWidth() {
        ImageAttributes iattr = getImageAttributes();
        if (iattr == null) return 0;
        return iattr.getWidth();
    }
    public double getHeight() {
        ImageAttributes iattr = getImageAttributes();
        if (iattr == null) return 0;
        return iattr.getHeight();
    }


    /**
     this function resolves (how???) various difference in "when" this image was taken.  it might use different metadata (in EXIF etc) and/or
     human-input (e.g. perhaps encounter data might trump it?)   TODO wtf should we do?
    */
    public DateTime getDateTime() {
        DateTime t = null;
        return t;
    }

    /**
      like getDateTime() this is considered "definitive" -- so it must resolve differences in metadata vs other (e.g. encounter etc) values
    */
    public Double getLatitude() {
        return null;
    }
    public Double getLongitude() {
        return null;
    }

/*
    public ArrayList<Annotation> getAnnotations() {
        return annotations;
    }

    //this will create the "trivial" Annotation (dimensions of the MediaAsset) iff no Annotations exist
    public ArrayList<Annotation> getAnnotationsGenerate(String species) {
        if (annotations == null) annotations = new ArrayList<Annotation>();
        if (annotations.size() < 1) addTrivialAnnotation(species);
        return annotations;
    }

    //TODO check if it is already here?  maybe?
    public Annotation addTrivialAnnotation(String species) {
        Annotation ann = new Annotation(this, species);  //this will add it to our .annotations collection as well 
        String newId = generateUUIDv3((byte)65, (byte)110);  //set Annotation UUID relative to our ID  An___
        if (newId != null) ann.setId(newId);
        return ann;
    }

    public int getAnnotationCount() {
        if (annotations == null) return 0;
        return annotations.size();
    }

    public static MediaAsset findByAnnotation(Annotation annot, Shepherd myShepherd) {
        String queryString = "SELECT FROM org.ecocean.media.MediaAsset WHERE annotations.contains(ann) && ann.id == \"" + annot.getId() + "\"";
        Query query = myShepherd.getPM().newQuery(queryString);
        List results = (List)query.execute();
        if (results.size() < 1) return null;
        return (MediaAsset)results.get(0);
    }
*/


/*
    public Path getThumbPath()
    {
        return thumbPath;
    }

    public Path getMidPath()
    {
        return midPath;
    }
*/

/*
    public MediaAssetType getType() {
        return type;
    }
*/

    /**
     * Return a full web-accessible url to the asset, or null if the
     * asset is not web-accessible.
     */
    public URL webURL() {
        if (store == null) return null;
        return store.webURL(this);
    }

    public String webURLString() {
        return getUrlString(this.webURL());
    }

/*
    public String thumbWebPathString() {
        return getUrlString(thumbWebPath());
    }

    public String midWebPathString() {
        return getUrlString(midWebPath());
    }

    public URL thumbWebPath() {
        return getUrl(thumbStore, thumbPath);
    }

    public void setThumb(final AssetStore store, final Path path)
    {
        thumbStore = store;
        thumbPath = path;
    }

    public AssetStore getThumbstore() {
        return thumbStore;
    }

    public URL midWebPath() {
        if (midPath == null) {
            return webPath();
        }

        //
        // Just use thumb store for now.
        //
        return getUrl(thumbStore, midPath);
    }

    public void setMid(final Path path) {
        //
        // Just use thumb store for now.
        //
        this.midPath = path;
    }

*/

/*
    public Integer getSubmitterId() {
        return submitterid;
    }

    public void setSubmitterId(final Integer submitterid) {
        this.submitterid = submitterid;
    }
*/


/*
    public LocalDateTime getMetaTimestamp() {
        return metaTimestamp;
    }


    public void setMetaTimestamp(LocalDateTime metaTimestamp) {
        this.metaTimestamp = metaTimestamp;
    }


    public Double getMetaLatitude() {
        return metaLatitude;
    }


    public void setMetaLatitude(Double metaLatitude) {
        this.metaLatitude = metaLatitude;
    }


    public Double getMetaLongitude() {
        return metaLongitude;
    }


    public void setMetaLongitude(Double metaLongitude) {
        this.metaLongitude = metaLongitude;
    }
*/



/*
    public void delete() {
        MediaAssetFactory.delete(this.id);
        MediaAssetFactory.deleteFromStore(this);
    }
*/

    //this takes contents of this MediaAsset and copies it to the target (note MediaAssets must exist with sufficient params already)
    public void copyAssetTo(MediaAsset targetMA) throws IOException {
        if (store == null) throw new IOException("copyAssetTo(): store is null on " + this);
        store.copyAssetAny(this, targetMA);
    }
/*
	public JSONObject sanitizeJson(HttpServletRequest request, boolean fullAccess) throws JSONException {
            JSONObject jobj = new JSONObject();
            jobj.put("id", id);
            //really we only "care" about MediaAsset -- for now?
            if (this.getMediaAsset() != null) jobj.put("mediaAsset", this.getMediaAsset().sanitizeJson(request, fullAccess));  //"should never" be null anyway
            return jobj;
        }
*/

        //fullAccess just gets cascaded down from Encounter -> Annotation -> us... not sure if it should win vs security(request) TODO
	public org.datanucleus.api.rest.orgjson.JSONObject sanitizeJson(HttpServletRequest request,
                org.datanucleus.api.rest.orgjson.JSONObject jobj, boolean fullAccess) throws org.datanucleus.api.rest.orgjson.JSONException {
            //if (jobj.get("parametersAsString") != null) jobj.put("parameters", new org.datanucleus.api.rest.orgjson.JSONObject(jobj.get("parametersAsString")));
            //if (jobj.get("parametersAsString") != null) jobj.put("parameters", new JSONObject(jobj.getString("parametersAsString")));
            if (jobj.get("parametersAsString") != null) jobj.put("parameters", new org.datanucleus.api.rest.orgjson.JSONObject(jobj.getString("parametersAsString")));
            jobj.remove("parametersAsString");
            //jobj.put("guid", "http://" + CommonConfiguration.getURLLocation(request) + "/api/org.ecocean.media.MediaAsset/" + id);

            //TODO something better with store?  fix .put("store", store) ???
            HashMap<String,String> s = new HashMap<String,String>();
            s.put("type", store.getType().toString());
            jobj.put("store", s);
            jobj.put("url", webURLString());
            if ((getMetadata() != null) && (getMetadata().getData() != null) && (getMetadata().getData().get("attributes") != null)) {
                //hactacular, but if it works....
                jobj.put("metadata", new org.datanucleus.api.rest.orgjson.JSONObject(getMetadata().getData().getJSONObject("attributes").toString()));
            }
            return jobj;
        }


    public String toString() {
        return new ToStringBuilder(this)
                .append("id", id)
                .append("parent", parentId)
                .append("labels", ((labels == null) ? "" : labels.toString()))
                .append("store", store.toString())
                .toString();
    }


    public void copyIn(File file) throws IOException {
        if (store == null) throw new IOException("copyIn(): store is null on " + this);
        store.copyIn(file, parameters, false);
    }

    public MediaAsset updateChild(String type, HashMap<String, Object> opts) throws IOException {
        if (store == null) throw new IOException("store is null on " + this);
        return store.updateChild(this, type, opts);
    }

    public MediaAsset updateChild(String type) throws IOException {
        return updateChild(type, null);
    }

    public ArrayList<MediaAsset> findChildren(Shepherd myShepherd) {
        if (store == null) return null;
        ArrayList<MediaAsset> all = store.findAllChildren(this, myShepherd);
        return all;
    }

    public ArrayList<MediaAsset> findChildrenByLabel(Shepherd myShepherd, String label) {
        ArrayList<MediaAsset> all = this.findChildren(myShepherd);
        if ((all == null) || (all.size() < 1)) return null;
        ArrayList<MediaAsset> matches = new ArrayList<MediaAsset>();
        for (MediaAsset ma : all) {
            if ((ma.getLabels() != null) && ma.getLabels().contains(label)) matches.add(ma);
        }
        return matches;
    }


    // NOTE: these currrently do not recurse.  this makes a big assumption that one only wants children of _original
    //   (e.g. on an encounter) and will *probably* need to change in the future.    TODO?
    public static MediaAsset findOneByLabel(ArrayList<MediaAsset> mas, Shepherd myShepherd, String label) {
        ArrayList<MediaAsset> all = findAllByLabel(mas, myShepherd, label, true);
        if ((all == null) || (all.size() < 1)) return null;
        return all.get(0);
    }
    public static ArrayList<MediaAsset> findAllByLabel(ArrayList<MediaAsset> mas, Shepherd myShepherd, String label) {
        return findAllByLabel(mas, myShepherd, label, false);
    }
    private static ArrayList<MediaAsset> findAllByLabel(ArrayList<MediaAsset> mas, Shepherd myShepherd, String label, boolean onlyOne) {
        if ((mas == null) || (mas.size() < 1)) return null;
        ArrayList<MediaAsset> found = new ArrayList<MediaAsset>();
        for (MediaAsset ma : mas) {
            if ((ma.getLabels() != null) && ma.getLabels().contains(label)) {
                found.add(ma);
                if (onlyOne) return found;
            }
            ArrayList<MediaAsset> kids = ma.findChildrenByLabel(myShepherd, label);
            if ((kids != null) && (kids.size() > 0)) {
                if (onlyOne) {
                    found.add(kids.get(0));
                    return found;
                } else {
                    found.addAll(kids);
                }
            }
        }
        return found;
    }


    //creates the "standard" derived children for a MediaAsset (thumb, mid, etc) -- TODO some day have this site-defined?
    public ArrayList<MediaAsset> updateStandardChildren() {
        ArrayList<MediaAsset> mas = new ArrayList<MediaAsset>();
        String[] types = new String[]{"thumb", "mid", "watermark"};
        for (int i = 0 ; i < types.length ; i++) {
            MediaAsset c = null;
            try {
                c = this.updateChild(types[i]);
            } catch (IOException ex) {
                System.out.println("updateStandardChildren() failed on " + this + " with " + ex.toString());
            }
            if (c != null) mas.add(c);
        }
        return mas;
    }
    //as above, but saves them too
    public ArrayList<MediaAsset> updateStandardChildren(Shepherd myShepherd) {
        ArrayList<MediaAsset> mas = updateStandardChildren();
        for (MediaAsset ma : mas) {
            MediaAssetFactory.save(ma, myShepherd);
        }
        return mas;
    }

    //TODO until we get keywords migrated to MediaAsset
    public List<Keyword> getKeywords() {
        return new ArrayList<Keyword>();
    }
 

    //if we dont have the Annotation... which kinda sucks but okay
    public String toHtmlElement(HttpServletRequest request, Shepherd myShepherd) {
        return toHtmlElement(request, myShepherd, null);
    }

    public String toHtmlElement(HttpServletRequest request, Shepherd myShepherd, Annotation ann) {
        if (store == null) return "<!-- ERROR: MediaAsset.toHtmlElement() has no .store value for " + this.toString() + " -->";
        return store.mediaAssetToHtmlElement(this, request, myShepherd, ann);
    }



    //note: we are going to assume Metadata "will just be there" so no magical updates. if it is null, it is null.
    // this implies basically that it is set once when the MediaAsset is created, so make sure that happens, *cough*
    public MediaAssetMetadata getMetadata() {
        return metadata;
    }
    public MediaAssetMetadata updateMetadata() throws IOException {  //TODO should this overwrite existing, or append?
        if (store == null) return null;
        metadata = store.extractMetadata(this);
        return metadata;
    }

    //only gets the "attributes" portion -- which is usually all we need for derived images
    public MediaAssetMetadata updateMinimalMetadata() {
        if (store == null) return null;
        try {
            metadata = store.extractMetadata(this, true);  //true means "attributes" only
        } catch (IOException ioe) {  //we silently eat IOExceptions, but will return null
            System.out.println("WARNING: updateMinimalMetadata() on " + this + " got " + ioe.toString() + "; failed to set");
            return null;
        }
        return metadata;
    }

    //handy cuz we dont need the actual file (if we have these values from elsewhere) and usually the only stuff we "need"
    public MediaAssetMetadata setMinimalMetadata(int width, int height, String contentType) {
        //note, this will overwrite existing "attributes" value if it exists
        if (metadata == null) metadata = new MediaAssetMetadata();
        metadata.getData().put("width", width);
        metadata.getData().put("height", height);
        metadata.getData().put("contentType", contentType);
        return metadata;
    }


}

