package org.ecocean.api;

import java.io.IOException;

import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.ServletException;

import org.ecocean.OpenSearch;
import org.ecocean.servlet.ServletUtilities;
import org.ecocean.Shepherd;
import org.ecocean.User;
import org.ecocean.Util;
import org.json.JSONArray;
import org.json.JSONObject;

public class SearchApi extends ApiBase {
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
    throws ServletException, IOException {
        String context = ServletUtilities.getContext(request);
        Shepherd myShepherd = new Shepherd(context);

        myShepherd.setAction("api.SearchApi.POST");
        myShepherd.beginDBTransaction();

        User currentUser = myShepherd.getUser(request);
        JSONObject res = new JSONObject();
        if ((currentUser == null) || (currentUser.getId() == null)) {
            response.setStatus(401);
            res.put("error", 401);
        } else {
            String arg = request.getPathInfo();
            if ((arg == null) || arg.equals("/")) {
                // for multisearch later maybe?
                response.setStatus(404);
                res.put("error", "unsupported");
            } else {
                String indexName = arg.substring(1);
                if (!OpenSearch.isValidIndexName(indexName)) {
                    response.setStatus(404);
                    res.put("error", "unknown index");
                } else {
                    String fromStr = request.getParameter("from");
                    String sizeStr = request.getParameter("size");
                    boolean deletePit = Util.requestParameterSet(request.getParameter("deletePit"));
                    int numFrom = 0;
                    int pageSize = 10;
                    try { numFrom = Integer.parseInt(fromStr); } catch (Exception ex) {}
                    try { pageSize = Integer.parseInt(sizeStr); } catch (Exception ex) {}
                    JSONObject query = ServletUtilities.jsonFromHttpServletRequest(request);
                    try {
                        JSONArray filter = query.getJSONObject("query").getJSONObject(
                            "bool").getJSONArray("filter");
                        filter.put(new JSONObject("{\"match\": {\"viewUsers\": \"" +
                            currentUser.getId() + "\"}}"));
                    } catch (Exception ex) {
                        System.out.println("SearchApi failed to find filter element: " + ex);
                    }
                    System.out.println("SearchApi query=" + query);

                    OpenSearch os = new OpenSearch();
                    try {
                        if (deletePit) os.deletePit(indexName);
                        JSONObject queryRes = os.queryPit(indexName, query, numFrom, pageSize);
                        JSONObject outerHits = queryRes.optJSONObject("hits");
                        if (outerHits == null) throw new IOException("could not find (outer) hits");
                        JSONArray hits = outerHits.optJSONArray("hits");
                        if (hits == null) throw new IOException("could not find hits");
                        int totalHits = -2;
                        if (outerHits.optJSONObject("total") != null)
                            totalHits = outerHits.getJSONObject("total").optInt("value", -1);
                        // String scrollId = outerHits.optString("_scroll_id", null);
                        JSONArray hitsArr = new JSONArray();
                        for (int i = 0; i < hits.length(); i++) {
                            JSONObject h = hits.optJSONObject(i);
                            if (h == null) throw new IOException("failed to parse hits[" + i + "]");
                            JSONObject doc = h.optJSONObject("_source");
                            if (doc == null)
                                throw new IOException("failed to parse doc in hits[" + i + "]");
                            // these are kind of noisy
                            doc.remove("viewUsers");
                            doc.remove("editUsers");
                            hitsArr.put(doc);
                        }
                        response.setHeader("X-Wildbook-Total-Hits", Integer.toString(totalHits));
                        // response.setHeader("X-Wildbook-Scroll-Id", scrollId);
                        response.setStatus(200);
                        res.put("success", true);
                        res.put("hits", hitsArr);
                    } catch (IOException ex) {
                        response.setStatus(500);
                        res.put("success", false);
                        res.put("error", "query failed");
                        ex.printStackTrace();
                    }
                }
            }
        }
        response.setHeader("Content-Type", "application/json");
        response.getWriter().write(res.toString());
        response.getWriter().close();
        myShepherd.rollbackAndClose();
    }
}
