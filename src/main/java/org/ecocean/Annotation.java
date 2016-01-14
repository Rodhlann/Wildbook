package org.ecocean;

/*
  TODO note: this is very ibeis-specific concept of "Annotation"
     we should probably consider a general version which can be manipulated into an ibeis one somehow
*/

import org.ecocean.ImageAttributes;
import org.ecocean.media.MediaAsset;
import org.ecocean.media.MediaAssetFactory;
import org.json.JSONObject;
import org.apache.commons.lang3.builder.ToStringBuilder;

//import java.time.LocalDateTime;

public class Annotation implements java.io.Serializable {
    public Annotation() {}  //empty for jdo
    private String id;  //TODO java.util.UUID ?
    private int x;
    private int y;
    private int width;
    private int height;
    private double theta;
    //*'annot_yaw': 'REAL',
    //~'annot_detect_confidence': 'REAL',
    //~'annot_exemplar_flag': 'INTEGER',
    //~'annot_note': 'TEXT',
    //~'annot_visual_uuid': 'UUID',
    //~'annot_semantic_uuid': 'UUID',
    //*'annot_quality': 'INTEGER',
    //~'annot_tags': 'TEXT',
    private String species;
    private String name;
    //private String image_uuid;  //TODO UUID?

    private MediaAsset mediaAsset = null;

    //the "trivial" Annotation - its bounding box is the same as the MediaAsset image
    public Annotation(MediaAsset ma, String species) {
        this(ma, species, ma.getImageAttributesOrNull());
    }

    public Annotation(MediaAsset ma, String species, ImageAttributes iatt) {
        this.id = org.ecocean.Util.generateUUID();
        this.x = (int) iatt.getXOffset();
        this.y = (int) iatt.getYOffset();
        this.width = (int) iatt.getWidth(); 
        this.height = (int) iatt.getHeight();
        this.theta = 0.0;  /// TODO ????
        this.species = species;
        this.setMediaAsset(ma);
        //this.name = this.annot_uuid + " on " + ma.getUUID();
    }


    public String getId() {
        return id;
    }
    public void setId(String id) {
        this.id = id;
    }

    public String getUUID() {
        return id;
    }

    public int getX() {
        return x;
    }
    public void setX(int x) {
        this.x = x;
    }

    public int getY() {
        return y;
    }
    public void setY(int y) {
        this.y = y;
    }

    public int getWidth() {
        return width;
    }
    public void setWidth(int w) {
        width = w;
    }

    public int getHeight() {
        return height;
    }
    public void setHeight(int h) {
        height = h;
    }

    public double getTheta() {
        return theta;
    }
    public void setTheta(double t) {
        theta = t;
    }
    public MediaAsset getMediaAsset() {
        return mediaAsset;
    }
    public void setMediaAsset(MediaAsset ma) {
        mediaAsset = ma;
        if ((ma.getAnnotationCount() == 0) || !ma.getAnnotations().contains(this)) {
            ma.getAnnotations().add(this);
        }
    }

    public String getSpecies() {
        return species;
    }
    public void setSpecies(String s) {
        species = s;
    }

    public String getName() {
        return name;
    }
    public void setName(String n) {
        name = n;
    }

    public int[] getBbox() {
        int[] bbox = new int[4];
        bbox[0] = x;
        bbox[1] = y;
        bbox[2] = width;
        bbox[3] = height;
        return bbox;
    }

/*  TODO should this use the IBEIS-IA attribute names or what?
    public JSONObject toJSONObject() {
        JSONObject obj = new JSONObject();
        obj.put("annot_uuid", annot_uuid);
        obj.put("annot_xtl", annot_xtl);
        obj.put("annot_ytl", annot_ytl);
        obj.put("annot_width", annot_width);
        obj.put("annot_height", annot_height);
        obj.put("annot_theta", annot_theta);
        obj.put("species_text", species_text);
        obj.put("image_uuid", this.mediaAsset.getUUID());
        obj.put("name_text", name_text);
        return obj;
    }
*/

    public String toString() {
        return new ToStringBuilder(this)
                .append("id", id)
                .append("species", species)
                .append("bbox", getBbox())
                .append("asset", mediaAsset)
                .toString();
    }


}
