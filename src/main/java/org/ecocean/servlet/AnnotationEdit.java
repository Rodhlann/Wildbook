/*
 * Wildbook - A Mark-Recapture Framework
 * Copyright (C) 2011-2018 Jason Holmberg
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License
 * as published by the Free Software Foundation; either version 2
 * of the License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
 */

package org.ecocean.servlet;

import java.io.IOException;
import java.io.PrintWriter;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;

//import javax.jdo.Query;
import javax.servlet.ServletConfig;
import javax.servlet.ServletException;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

import org.ecocean.Shepherd;
import org.ecocean.Annotation;
import org.ecocean.User;
import org.ecocean.Util;
import org.ecocean.Encounter;
import org.ecocean.MarkedIndividual;
import org.ecocean.AccessControl;
import org.json.JSONObject;

/*
import org.apache.commons.lang3.StringUtils;
import org.ecocean.MarkedIndividual;
import org.ecocean.CommonConfiguration;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
*/


public class AnnotationEdit extends HttpServlet {
    private static final long serialVersionUID = 1L;

    @Override
    public void init(final ServletConfig config) throws ServletException {
        super.init(config);
    }


    @Override
    public void doGet(final HttpServletRequest request, final HttpServletResponse response) throws ServletException, IOException {
        doPost(request, response);
    }

    @Override
    public void doPost(final HttpServletRequest request, final HttpServletResponse response) throws ServletException, IOException {
        String context = ServletUtilities.getContext(request);
        Shepherd myShepherd = new Shepherd(context);
        myShepherd.beginDBTransaction();
        JSONObject jsonIn = ServletUtilities.jsonFromHttpServletRequest(request);
        PrintWriter out = response.getWriter();

        //TODO we could make this check owner of Encounter(s) etc etc
        User user = AccessControl.getUser(request, myShepherd);
        boolean isAdmin = false;
        if (user != null) isAdmin = myShepherd.doesUserHaveRole(user.getUsername(), "admin", context);
        if (!isAdmin) {
            response.sendError(401, "access denied");
            response.setContentType("text/plain");
            out.println("access denied");
        }

        JSONObject rtn = new JSONObject("{\"success\": false}");
        String annId = jsonIn.optString("id", null);
        Annotation annot = myShepherd.getAnnotation(annId);
        if (annot == null) {
            rtn.put("error", "invalid Annotation id=" + annId);
        } else {
            String swapId = jsonIn.optString("swapIndividualId", null);
            String assignIndivId = jsonIn.optString("assignIndividualId", null);
            if (swapId != null) {
                Annotation swapAnnot = myShepherd.getAnnotation(swapId);
                if (swapId.equals(annId) || (swapAnnot == null)) {
                    rtn.put("error", "invalid swap Annotation id=" + swapId);
                } else {
                    Encounter enc1 = annot.findEncounter(myShepherd);
                    Encounter enc2 = swapAnnot.findEncounter(myShepherd);
                    if ((enc1 == null) || (enc2 == null)) {
                        rtn.put("error", "could not find both Encounters");
                    } else if (enc1.getCatalogNumber().equals(enc2.getCatalogNumber())) {
                        rtn.put("error", "both Annotations are on the same Encounter");
                    } else if (!enc1.hasMarkedIndividual() && !enc2.hasMarkedIndividual()) {
                        rtn.put("error", "both Annotations are on the unassigned Encounters");
                    } else {
                        String indivId1 = enc1.getIndividualID();
                        String indivId2 = enc2.getIndividualID();
                        if (indivId1 != null) {
                            MarkedIndividual indiv = myShepherd.getMarkedIndividualQuiet(indivId1);
                            if (indiv != null) {
                                indiv.removeEncounter(enc1, context);
                                indiv.addEncounter(enc2, context);
                            }
                        }
                        if (indivId2 != null) {
                            MarkedIndividual indiv = myShepherd.getMarkedIndividualQuiet(indivId2);
                            if (indiv != null) {
                                indiv.removeEncounter(enc2, context);
                                indiv.addEncounter(enc1, context);
                            }
                        }
                        enc2.setIndividualID(indivId1);
                        enc1.setIndividualID(indivId2);
                        System.out.println("INFO: AnnotationEdit swapped MarkedIndividual ids - enc=" + enc1.getCatalogNumber() + "[annot=" + annot.getId() + "]=>(" + enc1.getIndividualID() + "); enc=" + enc2.getCatalogNumber() + "[annot=" + swapAnnot.getId() + "]=>(" + enc2.getIndividualID() + ")");
                        rtn.put("success", true);
                        rtn.put("updatedMarkedIndividualId1", indivId2);
                        rtn.put("updatedMarkedIndividualId2", indivId1);
                    }
                }

            } else if (Util.stringExists(assignIndivId)) {
                Encounter enc = annot.findEncounter(myShepherd);
                if (enc.hasMarkedIndividual()) {
                    MarkedIndividual oldIndiv = myShepherd.getMarkedIndividualQuiet(enc.getIndividualID());
                    oldIndiv.removeEncounter(enc, context);
                }
                boolean newIndiv = false;
                MarkedIndividual indiv = myShepherd.getMarkedIndividualQuiet(assignIndivId);
                if (indiv == null) {
                    indiv = new MarkedIndividual(assignIndivId, enc);
                    newIndiv = true;
                } else {
                    indiv.addEncounter(enc, context);
                }
                enc.setIndividualID(assignIndivId);
                System.out.println("INFO: AnnotationEdit assigned " + indiv + " on " + enc + " via " + annot);
                rtn.put("success", true);
                rtn.put("newMarkedIndividual", newIndiv);

            } else {
                rtn.put("error", "unknown command");
            }
        }
        if (rtn.optBoolean("success", false)) {
            myShepherd.commitDBTransaction();
        } else {
            myShepherd.rollbackDBTransaction();
        }
        response.setContentType("text/json");
        out.println(rtn);
        out.close();
    }
}
