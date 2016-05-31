<%@ page contentType="text/html; charset=utf-8" language="java"
     import="org.ecocean.*,
java.util.Map,
java.util.ArrayList,
java.io.BufferedReader,
java.io.IOException,
java.io.InputStream,
java.io.InputStreamReader,
java.io.File,
org.json.JSONObject,
org.json.JSONArray,
java.net.URL,
org.ecocean.servlet.ServletUtilities,
org.ecocean.identity.IBEISIA,
org.ecocean.identity.IdentityServiceLog,
org.ecocean.Annotation,
org.ecocean.media.*
              "
%>




<%

Shepherd myShepherd=null;

String context = "context0";

myShepherd = new Shepherd(context);

//String rootDir = getServletContext().getRealPath("/");
//String baseDir = ServletUtilities.dataDir("context0", rootDir);

response.setHeader("Content-type", "application/javascript");

String jobID = request.getParameter("jobid");
System.out.println("IBEIS-IA callback got jobid=" + jobID);
if ((jobID == null) || jobID.equals("")) {
//System.out.println("fake fail * * * * * * * * * *");
	out.println("{\"success\": false, \"error\": \"invalid Job ID\"}");

} else {

	runIt(jobID, myShepherd, context);
	out.println("{\"success\": true}");
System.out.println("((((all done with main thread))))");
}

%>

<%!

private void runIt(final String jobID, final Shepherd myShepherd, final String context) {
System.out.println("---<< jobID=" + jobID + ", trying spawn . . . . . . . . .. . .................................");

	Runnable r = new Runnable() {
		public void run() {
			tryToGet(jobID, myShepherd, context);
		}
	};
	new Thread(r).start();
System.out.println("((( done runIt() )))");
	return;
}
 
private void tryToGet(String jobID, Shepherd myShepherd, String context) {
System.out.println("<<<<<<<<<< tryToGet(" + jobID + ")----");
	JSONObject statusResponse = new JSONObject();
//if (jobID != null) return;

	try {
		statusResponse = IBEISIA.getJobStatus(jobID);
	} catch (Exception ex) {
System.out.println("except? " + ex.toString());
		statusResponse.put("_error", ex.toString());
		//success = !(ex instanceof java.net.SocketTimeoutException);  //for now only re-try if we had a timeout; so may *fail* for other reasons
	}

System.out.println(statusResponse.toString());
System.out.println(">>>>---");
	JSONObject jlog = new JSONObject();
	jlog.put("jobID", jobID);

	//we have to find the taskID associated with this IBEIS-IA job
	String taskID = IBEISIA.findTaskIDFromJobID(jobID, myShepherd);
	if (taskID == null) {
		jlog.put("error", "could not determine task ID from job " + jobID);
	} else {
		jlog.put("taskID", taskID);
	}

	jlog.put("_action", "getJobStatus");
	jlog.put("_response", statusResponse);


	IBEISIA.log(taskID, jobID, jlog, context);

	JSONObject all = new JSONObject();
	all.put("jobStatus", jlog);

try {
	if ((statusResponse != null) && statusResponse.has("status") &&
	    statusResponse.getJSONObject("status").getBoolean("success") &&
	    statusResponse.has("response") && statusResponse.getJSONObject("response").has("status") &&
            "ok".equals(statusResponse.getJSONObject("response").getString("status")) &&
            "completed".equals(statusResponse.getJSONObject("response").getString("jobstatus")) &&
            "ok".equals(statusResponse.getJSONObject("response").getString("exec_status"))) {
System.out.println("HEYYYYYYY i am trying to getJobResult(" + jobID + ")");
		JSONObject resultResponse = IBEISIA.getJobResult(jobID);
		JSONObject rlog = new JSONObject();
		rlog.put("jobID", jobID);
		rlog.put("_action", "getJobResult");
		rlog.put("_response", resultResponse);
		IBEISIA.log(taskID, jobID, rlog, context);
		all.put("jobResult", rlog);

		JSONObject proc = IBEISIA.processCallback(taskID, rlog, myShepherd);
System.out.println("processCallback returned --> " + proc);
	}
} catch (Exception ex) {
	System.out.println("whoops got exception: " + ex.toString());
	ex.printStackTrace();
}

	all.put("_timestamp", System.currentTimeMillis());
System.out.println("-------- >>> " + all.toString());
	return;

}



%>



