
package org.ecocean;

import java.util.List;
import java.util.ArrayList;
import org.json.JSONObject;
import org.json.JSONArray;
import org.apache.commons.lang3.builder.ToStringBuilder;
import javax.servlet.http.HttpServletRequest;

public class Resolver implements java.io.Serializable {
    public static String STATUS_PENDING = "pending";  //needs review
    public static String STATUS_APPROVED = "approved";
    public static String STATUS_ERROR = "error";

    public static String TYPE_RETIRE = "retire";
    public static String TYPE_SPLIT = "split";
    public static String TYPE_MERGE = "merge";
    public static String TYPE_NEW = "new";

    private int id;
    private long modified;
    private String parameters;
    private String results;
    private String status;
    private String type;

    private Resolver parent;
    private List<Resolver> children;

    private List<Object> resultObjects;



    public Resolver() { }

    public Resolver(String type) {
        if (!validType(type)) throw new RuntimeException("Invalid Resolver type " + type);
        this.type = type;
        this.modified = System.currentTimeMillis();
    }

    public int getId() {
        return id;
    }
    public void setId(int i) {
        id = i;
    }
    public void setParameters(String p) {
        parameters = p;
    }
    public void setParameters(JSONObject jp) {
        if (jp == null) {
            parameters = null;
        } else {
            parameters = jp.toString();
        }
    }
    public JSONObject getParameters() {
        return Util.stringToJSONObject(this.parameters);
    }

    public void setResults(String r) {
        results = r;
    }
    public void setResults(JSONObject jr) {
        if (jr == null) {
            results = null;
        } else {
            results = jr.toString();
        }
    }
    public JSONObject getResults() {
        return Util.stringToJSONObject(this.results);
    }

    public Resolver getParent() {
        return parent;
    }
    public void setParent(Resolver r) {
        parent = r;
    }
    public List<Resolver> getChildren() {
        return children;
    }
    public void setChildren(List<Resolver> c) {
        children = c;
    }
    public List<Resolver> addChild(Resolver c) {
        if (children == null) children = new ArrayList<Resolver>();
        if (!children.contains(c)) {
            children.add(c);
            c.setParent(this);
        }
        return children;
    }

    public List<Object> addResultObject(Object obj) {
        if (resultObjects == null) resultObjects = new ArrayList<Object>();
        resultObjects.add(obj);
        return resultObjects;
    }
/*   will we ever want this?
    public List<Object> getResultObjects() {
        return resultObjects;
    }
*/
    public List<MarkedIndividual> getResultMarkedIndividuals() {
        List<MarkedIndividual> list = new ArrayList<MarkedIndividual>();
        if ((resultObjects == null) || (resultObjects.size() < 1)) return list;
        for (Object obj : resultObjects) {
            if (obj instanceof MarkedIndividual) list.add((MarkedIndividual)obj);
        }
        return list;
    }
    public List<Encounter> getResultEncounters() {
        List<Encounter> list = new ArrayList<Encounter>();
        if ((resultObjects == null) || (resultObjects.size() < 1)) return list;
        for (Object obj : resultObjects) {
            if (obj instanceof Encounter) list.add((Encounter)obj);
        }
        return list;
    }

    public static boolean validType(String t) {
        if (t == null) return false;
        return (t.equals(TYPE_RETIRE) || t.equals(TYPE_SPLIT) || t.equals(TYPE_MERGE) || t.equals(TYPE_NEW));
    }

    public static Resolver retireMarkedIndividual(MarkedIndividual indiv, HttpServletRequest request, Shepherd myShepherd) {
        if (indiv == null) throw new RuntimeException("null MarkedIndividual passed to Resolver.retireMarkedIndividual()");
        Resolver res = new Resolver(TYPE_RETIRE);

        JSONObject jp = new JSONObject();
        jp.put("individualId", indiv.getIndividualID());
        jp.put("user", AccessControl.simpleUserString(request));
        res.setParameters(jp);

        JSONObject jr = new JSONObject();
        jr.put("snapshot", snapshotMarkedIndividual(indiv));
        res.setResults(jr);

        myShepherd.getPM().makePersistent(res);
        return res;
    }

    public static Resolver mergeMarkedIndividuals(List<MarkedIndividual> indivs, HttpServletRequest request, Shepherd myShepherd) {
        Resolver res = new Resolver(TYPE_MERGE);
        return res;
    }

    public static Resolver splitMarkedIndividuals(List<MarkedIndividual> indivs, HttpServletRequest request, Shepherd myShepherd) {
        Resolver res = new Resolver(TYPE_SPLIT);
        return res;
    }

    public static Resolver addNewMarkedIndividuals(MarkedIndividual indiv, HttpServletRequest request, Shepherd myShepherd) {
        Resolver res = new Resolver(TYPE_NEW);
        return res;
    }


    public static JSONObject snapshotMarkedIndividual(MarkedIndividual indiv) {
        if (indiv == null) return null;
        JSONObject snap = new JSONObject();
        snap.put("timestamp", System.currentTimeMillis());
        return snap;
    }



    public String toString() {
        return new ToStringBuilder(this)
                .append("id", id)
                .append("type", type)
                .append("parent", ((parent == null) ? "" : parent.getId()))
                .append("status", status)
                .append("modified", modified)
                .toString();
    }

}
