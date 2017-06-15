<%@ page contentType="text/plain; charset=utf-8" language="java"
     import="org.ecocean.*,
java.util.List,
java.io.BufferedReader,
java.io.IOException,
java.io.InputStream,
java.io.InputStreamReader,
java.io.File,
org.joda.time.DateTime,
org.json.JSONObject,
org.json.JSONArray,
com.google.api.services.youtube.model.SearchResult,
org.ecocean.media.*,
java.util.ArrayList
              "
%>




<%

YouTube.init(request);

JSONObject rtn = new JSONObject("{\"success\": false}");

/*
Shepherd myShepherd = new Shepherd("context0");
myShepherd.beginDBTransaction();
*/

//YouTubeAssetStore yts = YouTubeAssetStore.find(myShepherd);
long sinceMS = System.currentTimeMillis() - (24 * 60 * 60 * 1000);  //i.e. 24 hours ago
try {
	sinceMS = Long.parseLong(request.getParameter("since"));
} catch (Exception ex) {}
rtn.put("since", sinceMS);
rtn.put("sinceDateTime", new DateTime(sinceMS));

ArrayList<String> phrasesToIgnoreVideo=new ArrayList<String>();
phrasesToIgnoreVideo.add("documentary");
phrasesToIgnoreVideo.add("documental");
phrasesToIgnoreVideo.add("hungry shark world");
phrasesToIgnoreVideo.add("hungry shark game");
phrasesToIgnoreVideo.add("dory");
phrasesToIgnoreVideo.add("nemo");
phrasesToIgnoreVideo.add("abyssrium");
phrasesToIgnoreVideo.add("whale shark card");
phrasesToIgnoreVideo.add("octonauts");
phrasesToIgnoreVideo.add("gta");
phrasesToIgnoreVideo.add("megalodon");
phrasesToIgnoreVideo.add("abzu");
phrasesToIgnoreVideo.add("bbc");
phrasesToIgnoreVideo.add("disney");
phrasesToIgnoreVideo.add("white shark");
phrasesToIgnoreVideo.add("top 10");
phrasesToIgnoreVideo.add("tap tap");
phrasesToIgnoreVideo.add("georgia");
phrasesToIgnoreVideo.add("nickelodeon");
phrasesToIgnoreVideo.add("attack");
phrasesToIgnoreVideo.add("paw patrol");
phrasesToIgnoreVideo.add("aliexpress");


int numPhrases=phrasesToIgnoreVideo.size();


String keyword = request.getParameter("keyword");
if (keyword == null) {
	rtn.put("error", "must supply keyword=");
} else {
	List<SearchResult> vids;
	try {
		vids = YouTube.searchByKeyword(keyword, sinceMS);
	} catch (Exception ex) {
		rtn.put("error", "exception thrown: " + ex.toString());
		out.println(rtn);
		return;
	}
	rtn.put("success", true);
	if ((vids == null) || (vids.size() < 1)) {
		rtn.put("count", 0);
	} else {
		rtn.put("count", vids.size());
		JSONArray varr = new JSONArray();
		for (SearchResult vid : vids) {
			
			//check the video for strings that indicate non-data videos (e.g., video games, documentaries, etc.)
			boolean filterMe=false;
			String consolidatedRemarks=vid.toString().toLowerCase();
			for(int i=0;i<numPhrases;i++){
				String filterString=phrasesToIgnoreVideo.get(i);
				if(consolidatedRemarks.indexOf(filterString)!=-1)filterMe=true;
			}
			
			if(!filterMe)varr.put(new JSONObject(vid.toString()));
			
			
		}
		rtn.put("videos", varr);
	}
}


out.println(rtn);



%>




