<%@ page contentType="text/html; charset=utf-8" language="java"
import="org.ecocean.*,
org.ecocean.servlet.ServletUtilities,
java.io.IOException,
javax.servlet.jsp.JspWriter,
javax.servlet.http.HttpServletRequest,
java.nio.file.Files,
java.sql.*,
java.io.File,
java.util.ArrayList,
java.util.List,
java.util.Set,
java.util.HashSet,
java.util.Properties,
javax.jdo.Query,
org.json.JSONObject,
org.json.JSONArray,
org.ecocean.media.*
    "
%>

<%!


private static void migrateUsers(JspWriter out, Shepherd myShepherd, Connection conn) throws SQLException, IOException {
    out.println("<h2>Users</h2><ol>");
    Statement st = conn.createStatement();
    ResultSet res = st.executeQuery("SELECT * FROM \"user\"");
    int ct = 0;
    while (res.next()) {
        String guid = res.getString("guid");
        int staticRoles = res.getInt("static_roles");
        out.println("<li>" + guid + ": ");
        Set<String> roles = new HashSet<String>();
        if ((staticRoles & 0x04000) > 0) {
            roles.add("admin");
            roles.add("orgAdmin");
            roles.add("researcher");
            roles.add("rest");
            roles.add("machinelearning");
        }
        if ((staticRoles & 0x80000) > 0) roles.add("orgAdmin");
        //if ((staticRoles & 0x10000) > 0)  exporter == "N/A"
        if ((staticRoles & 0x20000) > 0) roles.add("researcher");
        if ((staticRoles & 0x40000) > 0) {
            roles.add("rest");
            roles.add("machinelearning");
        }
        User user = myShepherd.getUserByUUID(guid);
        if (user != null) {
            out.println("<i>user exists; skipping</i>");
        } else {
            user = new User(guid);
/*
 created                          | timestamp without time zone |           | not null | 
 updated                          | timestamp without time zone |           | not null | 
 viewed                           | timestamp without time zone |           | not null | 
 guid                             | uuid                        |           | not null | 
 version                          | bigint                      |           |          | 
 email                            | character varying(120)      |           | not null | 
 password                         | bytea                       |           | not null | 
 full_name                        | character varying(120)      |           | not null | 
 website                          | character varying(120)      |           |          | 
 location                         | character varying(120)      |           |          | 
 affiliation                      | character varying(120)      |           |          | 
 forum_id                         | character varying(120)      |           |          | 
 locale                           | character varying(20)       |           |          | 
 accepted_user_agreement          | boolean                     |           | not null | 
 use_usa_date_format              | boolean                     |           | not null | 
 show_email_in_profile            | boolean                     |           | not null | 
 receive_notification_emails      | boolean                     |           | not null | 
 receive_newsletter_emails        | boolean                     |           | not null | 
 shares_data                      | boolean                     |           | not null | 
 default_identification_catalogue | uuid                        |           |          | 
 profile_fileupload_guid          | uuid                        |           |          | 
 static_roles                     | integer                     |           | not null | 
 indexed                          | timestamp without time zone |           | not null | CURRENT_TIMESTAMP
 linked_accounts                  | json                        |           |          | 
 twitter_username                 | character varying           |           |          | 
*/
            String username = res.getString("email");
            user.setUsername(username);
            user.setAffiliation(res.getString("affiliation"));
            // location seems to often have value in codex
            user.setUserURL(res.getString("website"));
            user.setEmailAddress(res.getString("email"));
            user.setFullName(res.getString("full_name"));
            myShepherd.getPM().makePersistent(user);

            for (String roleName : roles) {
                Role role = new Role();
                role.setRolename(roleName);
                role.setUsername(username);
                role.setContext("context0");
                myShepherd.getPM().makePersistent(role);
            }

            // TODO Organizations

            String msg = "created user [" + ct + "] [" + String.join(",", roles) + "] " + user;
            out.println("<b>" + msg + "</b>");
            System.out.println(msg);
        }
        out.println("</li>");
        ct++;
    }
    out.println("</ol>");
}


private static void migrateMediaAssets(JspWriter out, Shepherd myShepherd, Connection conn, HttpServletRequest request, File assetGroupDir) throws SQLException, IOException {
    out.println("<h2>MediaAssets</h2><ol>");
    Statement st = conn.createStatement();
    ResultSet res = st.executeQuery("SELECT * FROM asset ORDER BY git_store_guid, guid");
    AssetStore targetStore = AssetStore.getDefault(myShepherd);
    List<Integer> maIds = new ArrayList<Integer>();
    int ct = 0;

    while (res.next()) {
        ct++;
        if (ct > 5) break;
        String guid = res.getString("guid");
        out.println("<li>" + guid + ": ");
        MediaAsset ma = MediaAssetFactory.loadByUuid(guid, myShepherd);
        if (ma != null) {
            out.println("<i>asset exists; skipping</i>");
        } else {
            String ext = "unknown";
            String mimeType = res.getString("mime_type");
            if ((mimeType != null) && mimeType.contains("/")) ext = mimeType.split("\\/")[1];
            if ("jpeg".equals(ext)) ext = "jpg";
            String assetGroupGuid = res.getString("git_store_guid");
            File sourceFile = new File(assetGroupDir, assetGroupGuid + "/_assets/" + guid + "." + ext);
            String userFilename = res.getString("path");
            if (!Util.stringExists(userFilename)) userFilename = guid + "." + ext;
            //out.println(sourceFile.toString());
            if (!sourceFile.exists()) {
                out.println("<b>" + sourceFile + " does not exist</b>");
                break;
            }
            File tmpFile = new File("/tmp", guid + "." + ext);
            Files.copy(sourceFile.toPath(), tmpFile.toPath(), java.nio.file.StandardCopyOption.REPLACE_EXISTING);
            String grouping = Util.hashDirectories(assetGroupGuid, File.separator);
            JSONObject params = targetStore.createParameters(tmpFile, grouping);
            params.put("userFilename", userFilename);
            params.put("_codexMigration", System.currentTimeMillis());
            ma = targetStore.create(params);
            try {
                ma.copyIn(sourceFile);
            } catch (Exception ex) {
                out.println("<b>failed to copyIn " + sourceFile + " => " + ex.toString() + "</b>");
                break;
            }
            ma.setUUID(guid);
            // TODO revision from codex?
            ma.setAcmId(res.getString("content_guid"));
            ma.updateMetadata();
            ma.addLabel("_original");
            ma.setAccessControl(request);
            MediaAssetFactory.save(ma, myShepherd);
            maIds.add(ma.getId());
            String msg = "created [" + ct + "] " + ma;
            out.println("<b>" + msg + "</b>");
            System.out.println(msg);
        }
        out.println("</li>");
    }
    //MediaAsset.updateStandardChildrenBackground(context, maIds);
    out.println("</ol>");
}


private static void migrateAnnotations(JspWriter out, Shepherd myShepherd, Connection conn) throws SQLException, IOException {
    out.println("<h2>Annotations</h2><ol>");
    Statement st = conn.createStatement();
    ResultSet res = st.executeQuery("SELECT * FROM annotation ORDER BY guid");
    FeatureType.initAll(myShepherd);
    int ct = 0;

    while (res.next()) {
        ct++;
        if (ct > 5) break;
        String guid = res.getString("guid");
        Annotation ann = myShepherd.getAnnotation(guid);
        if (ann != null) {
            out.println("<li>" + guid + ": <i>annotation exists; skipping</i>");
        } else {
            String maId = res.getString("asset_guid");
            MediaAsset ma = MediaAssetFactory.loadByUuid(maId, myShepherd);
            if (ma == null) {
                //out.println("<b>" + guid + ": failed due to missing MediaAsset id=" + maId + "</b>");
                //System.out.println(guid + " failed due to missing MediaAsset id=" + maId);
                ct--;
                continue;
            }
            out.println("<li>" + guid + ": ");
            String bstr = res.getString("bounds");
            if (bstr.substring(0,1).equals("\"")) bstr = bstr.substring(1, bstr.length() - 1);
            bstr = bstr.replaceAll("\\\\", "");
System.out.println("bstr=>" + bstr);
            JSONObject bounds = new JSONObject(bstr);
            JSONArray rect = bounds.getJSONArray("rect");
            JSONObject params = new JSONObject();
            params.put("theta", bounds.optDouble("theta"));
            params.put("x", rect.optInt(0, 0));
            params.put("y", rect.optInt(1, 0));
            params.put("width", rect.optInt(2, 0));
            params.put("height", rect.optInt(3, 0));
            Feature feat = new Feature("org.ecocean.boundingBox", params);
            ma.addFeature(feat);
            // 99.9% sure species doesnt matter any more, so setting as null
            ann = new Annotation(null, feat, res.getString("ia_class"));
            ann.setId(guid);
            // TODO id status?
            ann.setAcmId(res.getString("content_guid"));
            ann.setViewpoint(res.getString("viewpoint"));
            ann.setMatchAgainst(true);
            myShepherd.getPM().makePersistent(ann);

            String msg = "created annot [" + ct + "] " + ann;
            out.println("<b>" + msg + "</b>");
            System.out.println(msg);
        }
        out.println("</li>");
    }
    out.println("</ol>");
}

%>


<%


String context = ServletUtilities.getContext(request);
Shepherd myShepherd = new Shepherd(context);
myShepherd.beginDBTransaction();

Properties props = ShepherdProperties.getProperties("codexMigration.properties", "", context);
String dbUrl = props.getProperty("codexDbUrl", context);
String dbUsername = props.getProperty("codexDbUsername", context);
String dbPassword = props.getProperty("codexDbPassword", context);

// this is under data-dir
String assetGroupDir = props.getProperty("assetGroupDir", context);
File dataDir = CommonConfiguration.getDataDirectory(getServletContext(), context);


Connection conn = DriverManager.getConnection(dbUrl, dbUsername, dbPassword);

migrateUsers(out, myShepherd, conn);

migrateMediaAssets(out, myShepherd, conn, request, new File(dataDir, assetGroupDir));

migrateAnnotations(out, myShepherd, conn);

myShepherd.commitDBTransaction();
myShepherd.closeDBTransaction();

%>



