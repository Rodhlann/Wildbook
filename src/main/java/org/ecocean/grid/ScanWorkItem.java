/*
 * The Shepherd Project - A Mark-Recapture Framework
 * Copyright (C) 2011 Jason Holmberg
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

package org.ecocean.grid;

//test
//.test 2
//test 3


import com.reijns.I3S.*;
import weka.core.Instance;
import org.ecocean.Encounter;
import org.ecocean.Spot;
import org.ecocean.SuperSpot;
import java.util.*;
import com.fastdtw.dtw.*;
import org.ecocean.grid.msm.*;


/**
 * A class description...
 * More description
 *
 * @author Jason Holmberg
 * @version 1.6
 */
//public class scanWorkItem extends JPPFTask implements java.io.Serializable{
public class ScanWorkItem implements java.io.Serializable {
  static final long serialVersionUID = 1325165653077808498L;
  private EncounterLite newEncounter;
  private EncounterLite existingEncounter;
  private String uniqueNum, taskID;
  private long startTime = -1;
  private long createTime = -1;
  private boolean done;
  private Hashtable props = new Hashtable();
  private int nice = 0;
  public Double epsilon;
  public Double R;
  public Double Sizelim;
  public Double maxTriangleRotation;
  public Double C;
  private boolean secondRun;
  public boolean rightScan;
  private MatchObject result;
  //private I3SMatchObject i3sResult;
  private Double fastDTWResult;
  private int totalWorkItemsInTask;
  private int workItemsCompleteInTask;
  
  String algorithms="";
  
  public boolean reversed=false;


  /**
   * empty constructor required by JDO Enhancer. DO NOT USE.
   */
  public ScanWorkItem() {
  }

  //test comment

  public ScanWorkItem(Encounter newEnc, Encounter existingEnc, String uniqueNum, String taskID, Properties props, String algorithms) {
    this.newEncounter = new EncounterLite(newEnc);
    this.existingEncounter = new EncounterLite(existingEnc);
    
    //if available, set the dates as long
    if(newEnc.getDateInMilliseconds()!=null){newEncounter.setDateLong(newEnc.getDateInMilliseconds());}
    if(existingEnc.getDateInMilliseconds()!=null){existingEncounter.setDateLong(existingEnc.getDateInMilliseconds());}
    
    
    this.uniqueNum = uniqueNum;
    this.taskID = taskID;

    //algorithm parameter read-ins
    this.epsilon = new Double(props.getProperty("epsilon"));
    this.R = new Double(props.getProperty("R"));
    this.Sizelim = new Double(props.getProperty("Sizelim"));
    this.maxTriangleRotation = new Double(props.getProperty("maxTriangleRotation"));
    this.C = new Double(props.getProperty("C"));

    //boolean read-ins
    this.secondRun = true;
    String secondRunString = (String) props.get("secondRun");
    if (secondRunString.equals("false")) {
      secondRun = false;
    }
    this.rightScan = false;
    String rightScanString = (String) props.get("rightScan");
    if (rightScanString.equals("true")) {
      rightScan = true;
    }

    createTime = System.currentTimeMillis();
    this.algorithms=algorithms;

  }

  //public scanWorkItemResult getResult(){
  //return result;
  //}

  public String getNewEncNumber() {
    return newEncounter.getEncounterNumber();
  }

  public String getExistingEncNumber() {
    return existingEncounter.getEncounterNumber();
  }


  /**
   * Returns true if a node is currently working on this object. This state times out after 60 seconds.
   */
  public boolean isCheckedOut(long millisecondsToWait) {
    if (getStartTime() > -1) {
      long currentTime = Calendar.getInstance().getTimeInMillis();
      if ((currentTime - getStartTime()) > millisecondsToWait) {
        return false;
      } else {
        return true;
      }
    } else {
      return false;
    }
  }

  public void run() {
    setResult(execute());
  }


  /**
   * Executes the work to be done on the remote node.
   * Make sure to setDone() when execute has completed successfully.
   */
  public MatchObject execute() {
    
    //tuned on October 8, 2015 using /TrainHolmbergIntersection
    //double allowedHolmbergIntersectionProportion = 0.18;


    //determine which spots to pass in
    SuperSpot[] newspotsTemp = new SuperSpot[0];
    SuperSpot[] oldspotsTemp = new SuperSpot[0];
    SuperSpot[] newRefSpots = new SuperSpot[0];
    
    if (!rightScan) {
      newspotsTemp = (SuperSpot[]) newEncounter.getSpots().toArray(newspotsTemp);
      oldspotsTemp = (SuperSpot[]) existingEncounter.getSpots().toArray(oldspotsTemp);
      newRefSpots=newEncounter.getLeftReferenceSpots();
    } else {
      newspotsTemp = (SuperSpot[]) newEncounter.getRightSpots().toArray(newspotsTemp);
      oldspotsTemp = (SuperSpot[]) existingEncounter.getRightSpots().toArray(oldspotsTemp);
      newRefSpots=newEncounter.getRightReferenceSpots();
    }

    //create a re-write of the new spots
    ArrayList<SuperSpot> newGrothSpots = new ArrayList<SuperSpot>();
    int spotLength = newspotsTemp.length;
    for (int t = 0; t < spotLength; t++) {
      newGrothSpots.add(new SuperSpot(new Spot(0, newspotsTemp[t].getTheSpot().getCentroidX(), newspotsTemp[t].getTheSpot().getCentroidY())));
    }

    //create a re-write of the old spots
    ArrayList<SuperSpot> existingGrothSpots = new ArrayList<SuperSpot>();
    int spotLength2 = oldspotsTemp.length;
    for (int t = 0; t < spotLength2; t++) {
      existingGrothSpots.add(new SuperSpot(new Spot(0, oldspotsTemp[t].getTheSpot().getCentroidX(), oldspotsTemp[t].getTheSpot().getCentroidY())));
    }
    
    
    
    //start DTW array creation
    
    //com.reijns.I3S.Point2D[] newEncRefSpots=newEncounter.getThreeRightFiducialPoints();
    //com.reijns.I3S.Point2D[] existingEncRefSpots=existingEncounter.getThreeRightFiducialPoints();
    
    //we need to create a 0 to 1 time series for each one using the right hand spot
    

    
    
    
    MatchObject result=new MatchObject();
    if(!reversed){
      result.encounterNumber=existingEncounter.getEncounterNumber();
      result.individualName=existingEncounter.getIndividualID();
    }
    else{
      result.encounterNumber=newEncounter.getEncounterNumber();
      result.individualName=newEncounter.getIndividualID();
    }
    if(algorithms.indexOf("ModifedGroth")>-1){
      result = existingEncounter.getPointsForBestMatch(newspotsTemp, epsilon.doubleValue(), R.doubleValue(), Sizelim.doubleValue(), maxTriangleRotation.doubleValue(), C.doubleValue(), secondRun, rightScan,newRefSpots);
    
      System.out.println("     Groth score was: "+result.getAdjustedMatchValue());
    }
    //I3S processing

    //reset the spot patterns after Groth processing
    if (!rightScan) {
      newEncounter.processLeftSpots(newGrothSpots);
      existingEncounter.processLeftSpots(existingGrothSpots);
    } else {
      newEncounter.processRightSpots(newGrothSpots);
      existingEncounter.processRightSpots(existingGrothSpots);
    }

    //adjust for scale
    double[] matrix = new double[6];
    com.reijns.I3S.Point2D[] comapare2mePoints = new com.reijns.I3S.Point2D[0];
    com.reijns.I3S.Point2D[] lookForThisEncounterPoints = new com.reijns.I3S.Point2D[0];
    I3SMatchObject newDScore=EncounterLite.improvedI3SScan(existingEncounter, newEncounter);
      newDScore.setEncounterNumber(getNewEncNumber());
      //newDScore.setIndividualID(id);
      double newScore=-1;
      if(newDScore!=null){
        newScore=newDScore.getI3SMatchValue();
        
        
        //
        if(newScore<0.0000001){newScore=2.0;}
        
        //create a Vector of Points
        Vector points = new Vector();
        
        
        //TBD_CRAP WE NEED
        TreeMap map = newDScore.getMap();
        
        
        //int treeSize=map.size();
        Iterator map_iter = map.values().iterator();
        while (map_iter.hasNext()) {
          points.add((Pair) map_iter.next());
        }
  
        //add the I3S results to the matchObject sent back
        result.setI3SValues(points, newScore);
      }
      System.out.println("     I3S score is: "+newScore);
    //}
    
   // if(algorithms.indexOf("FastDTW")>-1){
      TimeWarpInfo twi=EncounterLite.fastDTW(existingEncounter, newEncounter, 30);
      
      java.lang.Double distance = new java.lang.Double(-1);
      if(twi!=null){
        WarpPath wp=twi.getPath();
          String myPath=wp.toString();
        distance=new java.lang.Double(twi.getDistance());
      }   
      
      result.setFastDTWPath(distance.toString());
      
      //calculate FastDTW
      //Double fastDTWResult = new Double(FastDTW.compare(ts1, ts2, 10, Distances.EUCLIDEAN_DISTANCE).getDistance());
      
      //if(rightScan){
        result.setRightFastDTWResult(distance);
      //}
      //else{
        result.setLeftFastDTWResult(distance);
      //}
      
      System.out.println("     FastDTW result is: "+distance);
      
      
      
      //set proportion Value
      result.setProportionValue(EncounterLite.getFlukeProportion(existingEncounter, newEncounter));
      
      //set MSM value
      Double msmValue=MSM.getMSMDistance(existingEncounter, newEncounter);
      System.out.println("     MSM result is: "+msmValue.doubleValue());
      result.setMSMSValue(msmValue);
      
      
      //set Swale value
      double penalty=-2;
      double reward=25.0;
      double epsilon=0.0011419401589504922;

      Double swaleValue=EncounterLite.getSwaleMatchScore(existingEncounter, newEncounter, penalty, reward, epsilon);
      System.out.println("     Swale result is: "+swaleValue.doubleValue());
      result.setSwaleValue(swaleValue);
      
      double date = Instance.missingValue();
      if((newEncounter.getDateLong()!=null)&&(existingEncounter.getDateLong()!=null)){
        try{
          date=Math.abs((new Long(newEncounter.getDateLong()-existingEncounter.getDateLong())).doubleValue());
        }
        catch(Exception e){
          e.printStackTrace();
        }
      }
      
      System.out.println("Date diff is: "+date);

      
      Double numIntersections=EncounterLite.getHolmbergIntersectionScore(existingEncounter, newEncounter);
      
      System.out.println("Intersection score is: "+numIntersections);
      
      result.setIntersectionCount(numIntersections);
      result.setAnglesOfIntersections("");
      result.setDateDiff(date);
   
      System.out.println("......Done SWI and returning  MO...");
    done = true;
    return result;
  }

  /**
   * Returns the unique number for this workItem.
   */
  public String getUniqueNumber() {
    return uniqueNum;
  }


  public String getTaskIdentifier() {
    return taskID;
  }


  /**
   * Returns the startTime of the workItem. This value is used to determine timeouts.
   */
  public long getStartTime() {
    return startTime;
  }

  ;

  /**
   * Sets the startTime of this workItem. This value is used to determine timeouts.
   */
  public void setStartTime(long newStartTime) {
    this.startTime = newStartTime;
  }


  public boolean isDone() {
    return done;
  }

  public void setDone(boolean finished) {
    this.done = finished;
  }


  //returns the priority of this task
  public int getNice() {
    return nice;
  }

  //sets the nice value for this task
  public void setNice(int nice) {
    this.nice = nice;
  }

  public MatchObject getResult() {
    return result;
  }


  public void setResult(MatchObject newResult) {
    newResult.setTaskID(this.taskID);
    newResult.setWorkItemUniqueNumber(this.uniqueNum);
    result = newResult;
  }

  public EncounterLite getNewEncounterLite() {
    return newEncounter;
  }

  public EncounterLite getExistingEncounterLite() {
    return existingEncounter;
  }

  public long getCreateTime() {
    return createTime;
  }

  public int getTotalWorkItemsInTask() {
    return totalWorkItemsInTask;
  }

  public void setTotalWorkItemsInTask(int num) {
    totalWorkItemsInTask = num;
  }

  public int getWorkItemsCompleteInTask() {
    return workItemsCompleteInTask;
  }

  public void setWorkItemsCompleteInTask(int num) {
    workItemsCompleteInTask = num;
  }

  public boolean isRightScan() {
    return rightScan;
  }

  public void setExistingEncounter(EncounterLite el) {
    this.existingEncounter = el;
  }

  public void setNewEncounter(EncounterLite el) {
    this.newEncounter = el;
  }
  
  public Double getFastDTWResult(){return fastDTWResult;}
  
  public void setReversed(boolean myVal){this.reversed=myVal;}
  
}
	