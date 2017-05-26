<%@ page contentType="text/plain; charset=utf-8" language="java"
     import="org.ecocean.*,
java.util.List,
java.io.BufferedReader,
java.io.IOException,
java.io.InputStream,
java.io.InputStreamReader,
java.io.File,
org.json.JSONObject,

org.ecocean.media.*
              "
%>




<%

JSONObject rtn = new JSONObject("{\"success\": false}");

Shepherd myShepherd = new Shepherd("context0");
myShepherd.setAction("ytCreate.jsp");
myShepherd.beginDBTransaction();

YouTubeAssetStore yts = YouTubeAssetStore.find(myShepherd);
if (yts == null) {
	rtn.put("error", "could not find YouTubeAssetStore");
	out.println(rtn);
	myShepherd.rollbackDBTransaction();
	myShepherd.closeDBTransaction();
	return;
}

String id = request.getParameter("id");
if (id == null) {
	rtn.put("error", "no YouTube id= passed");
	out.println(rtn);
	myShepherd.rollbackDBTransaction();
	myShepherd.closeDBTransaction();
	return;
}
rtn.put("youtubeId", id);


JSONObject p = new JSONObject();
p.put("id", id);

try{
	MediaAsset ma = yts.find(p, myShepherd);
	
	if (ma != null) {
		rtn.put("info", "MediaAsset already exists; not creating");
	
	} else {
		ma = yts.create(id);
		ma.updateMetadata();
		MediaAssetFactory.save(ma, myShepherd);
		boolean ok = yts.grabAndParse(myShepherd, ma, false);
	
		rtn.put("grabAndParse", ok);
	}
	//myShepherd.closeDBTransaction();
	
	rtn.put("success", true);
	rtn.put("assetId", ma.getId());
	rtn.put("metadata", ma.getMetadata().getData());
	
	out.println(rtn);
	myShepherd.commitDBTransaction();
}
catch(Exception e){
	myShepherd.rollbackDBTransaction();
	e.printStackTrace();
}
finally{
	
	myShepherd.closeDBTransaction();
}


%>




