/*
    an Organization contains users.  and other Organizations!
*/

package org.ecocean;

import org.ecocean.Shepherd;
import org.ecocean.User;
import org.ecocean.Util;
import org.ecocean.media.MediaAsset;
import org.json.JSONObject;
import org.json.JSONArray;
import org.joda.time.DateTime;
import java.util.List;
import java.util.Iterator;
import java.util.ArrayList;
import java.util.Set;
import java.util.HashSet;
import org.apache.commons.lang3.builder.ToStringBuilder;
/*
//import java.util.UUID;   :(
import javax.jdo.Query;
*/

public class Organization implements java.io.Serializable {

    private String id = null;
    private String name = null;
    private String description = null;
    private String url = null;
    private MediaAsset logo = null;
    private long created = -1;
    private long modified = -1;
    private List<User> members = null;
    private Organization parent = null;
    private List<Organization> children = null;
    
    public Organization() {
        this((String)null);
    }
    public Organization(String name) {
        this.id = Util.generateUUID();
        this.name = name;
        created = System.currentTimeMillis();
        this.updateModified();
    }

    public String getId() {
        return id;
    }

    public String getName() {
        return name;
    }
    public void setName(String n) {
        name = n;
        this.updateModified();
    }

    public String getUrl() {
        return url;
    }
    public void setUrl(String u) {
        url = u;
        this.updateModified();
    }

    public String getDescription() {
        return description;
    }
    public void setDescription(String d) {
        description = d;
        this.updateModified();
    }

    public MediaAsset getLogo() {
        return logo;
    }
    public void setLogo(MediaAsset ma) {
        logo = ma;
        this.updateModified();
    }

    public List<User> getMembers() {
        return members;
    }
    public void setMembers(List<User> u) {
        members = u;
        this.updateModified();
    }
    public void addMember(User u) {
        if (u == null) return;
        if (members == null) members = new ArrayList<User>();
        if (!members.contains(u)) members.add(u);
        this.updateModified();
    }
    public int addMembers(List<User> ulist) {
        int ct = 0;
        if ((ulist == null) || (ulist.size() < 1)) return 0;
        if (members == null) members = new ArrayList<User>();
        for (User mem : ulist) {
            if (!members.contains(mem)) {
                members.add(mem);
                ct++;
            }
        }
        this.updateModified();
        return ct;
    }
    public void removeMember(User u) {
        if (members != null) members.remove(u);
        this.updateModified();
    }
    public void removeMembers(List<User> ulist) {
        if (members != null) members.removeAll(ulist);
        this.updateModified();
    }
    public int removeMembersById(List<String> uids) {
        if ((uids == null) || (members == null)) return 0;
        int ct = 0;
        Iterator<User> it = members.iterator();
        while (it.hasNext()) {
            if (uids.contains(it.next().getId())) {
                it.remove();
                ct++;
            }
        }
        this.updateModified();
        return ct;
    }
    public int numMembers() {
        if (members == null) return 0;
        return members.size();
    }
    public boolean hasMembers() {
        return (numMembers() > 0);
    }

    public List<Organization> getChildren() {
        return children;
    }
    public void setChildren(List<Organization> kids) {
        children = kids;
        this.updateModified();
    }
    public List<Organization> addChild(Organization kid) {
        if (children == null) children = new ArrayList<Organization>();
        if (kid == null) return children;
        if (!children.contains(kid)) children.add(kid);
        this.updateModified();
        return children;
    }

/*  not sure if this is evil ??
    public void setParent(Organization t) {
        parent = t;
    }
*/
    public Organization getParent() {
        return parent;
    }
    public int numChildren() {
        return (children == null) ? 0 : children.size();
    }
    public boolean hasChildren() {
        return (this.numChildren() > 0);
    }

    //omg i am going to assume no looping
    public List<Organization> getLeafOrganizations() {
        List<Organization> leaves = new ArrayList<Organization>();
        if (!this.hasChildren()) {
            leaves.add(this);
            return leaves;
        }
        for (Organization kid : children) {
            leaves.addAll(kid.getLeafOrganizations());
        }
        return leaves;
    }

    public Organization getRootOrganization() {
        if (parent == null) return this;
        return parent.getRootOrganization();
    }

    //takes a bunch of tasks and returns only roots (without duplication)
    public static List<Organization> onlyRoots(List<Organization> all) {
        List<Organization> roots = new ArrayList<Organization>();
        for (Organization o : all) {
            Organization r = o.getRootOrganization();
            if (!roots.contains(r)) roots.add(r);
        }
        return roots;
    }

    //see also hasMemberDeep()
    public boolean hasMember(User u) {
        if ((members == null) || (u == null)) return false;
        return members.contains(u);
    }
    public boolean hasMemberDeep(User u) {
        if (this.hasMember(u)) return true;
        if (!this.hasChildren()) return false;  //no sub-orgs
        for (Organization kid : this.children) {
            boolean m = kid.hasMemberDeep(u);
            if (m) return true;
        }
        return false;
    }

    //  logic basically goes like this:  (1) "admin" role can touch any group; (2) "manager" role can affect any group *they are in*
    public boolean canManage(User user, Shepherd myShepherd) {
        if (user == null) return false;
        if (user.hasRoleByName("admin", myShepherd)) return true;  //TODO maybe new role?  "orgadmin" ?
        if (!this.hasMember(user)) return false;  //TODO should this be .hasMemberDeep() ?
        return user.hasRoleByName("manager", myShepherd);
    }

    //do we recurse?  i think so... you would want a child org (member) to see what you named something
    public Set<String> getMultiValueKeys() {
        Set<String> keys = new HashSet();
        keys.add("_ORG_:" + this.id);
        if (this.hasChildren()) {
            for (Organization kid : this.children) {
                keys.addAll(kid.getMultiValueKeys());
            }
        }
        return keys;
    }


    //pass in another org and effectively take over its content.
    //  note: this doesnt kill the other org - that must be done manually (if desired)
    public int mergeFrom(Organization other) {
        int ct = this.addMembers(other.members);  //really very simple for now
        this.updateModified();
        return ct;
    }


    public void updateModified() {
        modified = System.currentTimeMillis();
    }

    public JSONObject toJSONObject() {
        return this.toJSONObject(false);
    }
    public JSONObject toJSONObject(boolean includeChildren) {
        JSONObject j = new JSONObject();
        j.put("id", id);
        j.put("name", name);
        j.put("created", created);
        j.put("modified", modified);
        j.put("createdDate", new DateTime(created));
        j.put("modifiedDate", new DateTime(modified));
        if (this.hasMembers()) {
            JSONArray jm = new JSONArray();
            for (User u : this.members) {
                JSONObject ju = new JSONObject();
                ju.put("id", u.getId());
                ju.put("username", u.getUsername());
                ju.put("fullName", u.getFullName());
                jm.put(ju);
            }
            j.put("members", jm);
        }
        if (includeChildren && this.hasChildren()) {
            JSONArray jc = new JSONArray();
            for (Organization kid : this.children) {
                jc.put(kid.toJSONObject(true));  //we once again assume no looping!  bon chance.
            }
            j.put("children", jc);
        }
        Organization parent = this.getParent();
        if (parent != null) j.put("parentId", parent.getId());
        return j;
    }

    public String toString() {
        return new ToStringBuilder(this)
                .append(id)
                .append(name)
                .append("(" + new DateTime(created) + "|" + new DateTime(modified) + ")")
                .append(numMembers() + "Mems")
                .append(numChildren() + "Kids")
                .toString();
    }

    public static Organization load(String id, Shepherd myShepherd) {
        Organization o = null;
        try {
            o = ((Organization) (myShepherd.getPM().getObjectById(myShepherd.getPM().newObjectIdInstance(Organization.class, id), true)));
        } catch (Exception ex) {};  //swallow jdo not found noise
        return o;
    }

/*
    public static List<Organization> getOrganizationsFor(Annotation ann, Shepherd myShepherd) {
        String qstr = "SELECT FROM org.ecocean.ia.Organization WHERE objectAnnotations.contains(obj) && obj.id == \"" + ann.getId() + "\" VARIABLES org.ecocean.Annotation obj";
        Query query = myShepherd.getPM().newQuery(qstr);
        query.setOrdering("created");
        return (List<Organization>) query.execute();
    }
    public static List<Organization> getRootOrganizationsFor(Annotation ann, Shepherd myShepherd) {
        return onlyRoots(getOrganizationsFor(ann, myShepherd));
    }

    public static List<Organization> getOrganizationsFor(MediaAsset ma, Shepherd myShepherd) {
        String qstr = "SELECT FROM org.ecocean.ia.Organization WHERE objectMediaAssets.contains(obj) && obj.id == " + ma.getId() + " VARIABLES org.ecocean.media.MediaAsset obj";
        Query query = myShepherd.getPM().newQuery(qstr);
        query.setOrdering("created");
        return (List<Organization>) query.execute();
    }
    public static List<Organization> getRootOrganizationsFor(MediaAsset ma, Shepherd myShepherd) {
        return onlyRoots(getOrganizationsFor(ma, myShepherd));
    }

*/
}

