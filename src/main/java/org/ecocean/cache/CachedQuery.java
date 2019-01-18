package org.ecocean.cache;

import java.io.File;
import java.io.FileInputStream;
import java.io.InputStream;
import java.lang.String;
import java.util.ArrayList;
import java.util.Collection;
import java.util.List;

import javax.jdo.Query;

import org.apache.commons.io.IOUtils;
import org.datanucleus.ExecutionContext;
import org.datanucleus.api.jdo.JDOPersistenceManager;
import org.datanucleus.api.rest.RESTUtils;
import org.ecocean.Shepherd;
import org.ecocean.ShepherdProperties;
import org.ecocean.Util;
import org.json.JSONArray;
import org.json.JSONObject;

//A non-persistent object representing a single StoredQuery. 
public class CachedQuery {
  
    public CachedQuery(StoredQuery sq){
      this.uuid=sq.getUUID();
      this.queryString=sq.getQueryString();
      this.name=sq.getName();
      this.correspondingIACacheName=sq.getCorrespondingIACacheName();
      this.expirationTimeoutDuration=sq.getExpirationTimeoutDuration();
      this.nextExpirationTimeout=sq.getNextExpirationTimeoutDuration();
    }
    
    public CachedQuery(String name,JSONObject jsonSerializedQueryResult, boolean persistAsStoredQuery, Shepherd myShepherd){
      this.name=name;
      this.jsonSerializedQueryResult=jsonSerializedQueryResult;
      
      if(persistAsStoredQuery){
        
        try{
          
          //OK, so we need to serialize out the result
          Util.writeToFile(jsonSerializedQueryResult.toString(), getCacheFile().getAbsolutePath());
          
          StoredQuery sq=new StoredQuery(name);
          myShepherd.getPM().makePersistent(sq);
          myShepherd.commitDBTransaction();
          myShepherd.beginDBTransaction();
          
          
        }
        catch(Exception e){
          e.printStackTrace();
        }
        
      }
      
    }
  
  
    //primary key, persistent, String, not null
    private String uuid;
    
    //The JDOQL representation of the query, persistent, String, not null
    private String queryString;
    
    //a human-readable name for the query, persistent, String, not null, unique
    private String name;
    
    //if this query matches an IA cache this field in the name of the cache, String, persistent
    private String correspondingIACacheName;
    
    //The time duration (diff) between create time and this queries expiration time in milliseconds, requiring a refresh of cached items.
    public long expirationTimeoutDuration = -1;
    
    //the next time this cache expires
    public long nextExpirationTimeout  = -1;
    
    public JSONObject jsonSerializedQueryResult;
    public Integer collectionQueryCount;
    


    public String getName(){return name;}

    
    public String getUUID(){return uuid;}

    
    
    public String getQueryString(){return queryString;}

    
    public String getCorrespondingIACacheName(){return correspondingIACacheName;}

    public long getExpirationTimeoutDuration(){return expirationTimeoutDuration;}

    public long getNextExpirationTimeoutDuration(){return nextExpirationTimeout;}

    public void refreshValues(String context){
      Shepherd myShepherd=new Shepherd(context);
      myShepherd.beginDBTransaction();
      StoredQuery sq=myShepherd.getStoredQuery(uuid);
      this.uuid=sq.getUUID();
      this.queryString=sq.getQueryString();
      this.name=sq.getName();
      this.correspondingIACacheName=sq.getCorrespondingIACacheName();
      this.expirationTimeoutDuration=sq.getExpirationTimeoutDuration();
      this.nextExpirationTimeout=sq.getNextExpirationTimeoutDuration();
      myShepherd.rollbackDBTransaction();
      myShepherd.closeDBTransaction();
    }
    
    public JSONObject executeCollectionQuery(Shepherd myShepherd,boolean useSerializedJSONCache){

      //first, can we use serialized cache and if so, does it exist
      if(useSerializedJSONCache){
        
        if((jsonSerializedQueryResult==null)||((expirationTimeoutDuration>-1)&&(System.currentTimeMillis()>nextExpirationTimeout))){
          //System.out.println("jsonSerializedQueryResult is null");
          //check if we have a serialized cache
          if(getCacheFile().exists() && !(System.currentTimeMillis()>nextExpirationTimeout)){
            System.out.println("cached file exists!");
            return loadCachedJSON(myShepherd);
          }
          else{
          
            System.out.println("cached file does NOT exist or has expired!");
            //run the query and set the cache
            List<Object> results=executeQuery(myShepherd);
            
            //serialize the results
            JSONObject jsonobj=serializeCollectionToJSON(results, myShepherd);
            System.out.println("finished serializing the result!");
                
            //then return the List<Object>
            return jsonobj;
          }
          
        }
        else{
          
           return jsonSerializedQueryResult;
          
        }
        
        
      }
      //just run the query
      else{
        List<Object> c=executeQuery(myShepherd);
        JSONObject jsonobj=convertToJson(c, ((JDOPersistenceManager)myShepherd.getPM()).getExecutionContext());
        return jsonobj;
        
      }
      
      
      

      
    }
    
    public Integer executeCountQuery(Shepherd myShepherd){
      if((collectionQueryCount==null)||((expirationTimeoutDuration>-1)&&(System.currentTimeMillis()>nextExpirationTimeout))){
        try{
          System.out.println("Executing executeCountQuery");
          List<Object> c=executeQuery(myShepherd);
          collectionQueryCount=new Integer(c.size());
          nextExpirationTimeout=System.currentTimeMillis()+expirationTimeoutDuration;
        }
        catch(Exception e){e.printStackTrace();}
      }
      return collectionQueryCount;
    } 
    
    public synchronized void invalidate(){
      collectionQueryCount=null;
      jsonSerializedQueryResult=null;
      
      //delete the serialized JSON
      getCacheFile().delete();
      
    }
    
    public synchronized JSONObject getJSONSerializedQueryResult(){
      return jsonSerializedQueryResult;
    }
    
    public JSONObject convertToJson(Collection coll, ExecutionContext ec) {
      JSONArray jarr = new JSONArray();
      for (Object o : coll) {
          if (o instanceof Collection) {
              jarr.put(convertToJson((Collection)o, ec));
          } else {  //TODO can it *only* be an JSONObject-worthy object at this point?
              jarr.put(Util.toggleJSONObject(RESTUtils.getJSONObjectFromPOJO(o, ec)));
          }
      }
      JSONObject jsonobj=new JSONObject();
      jsonobj.put("result", jarr);
      return jsonobj;
  }
    
   public List<Object> executeQuery(Shepherd myShepherd){
     System.out.println("in CachedQuery. executeQuery");
     Query query=myShepherd.getPM().newQuery(queryString);
     Collection c = (Collection) (query.execute());
     ArrayList<Object> al=new ArrayList<Object>(c);
     System.out.println("Finished executeQuery with: "+al.size()+" results.");
     query.closeAll();
     return al;
   }  
   
   private JSONObject serializeCollectionToJSON(Collection c, Shepherd myShepherd){
     try{
       System.out.println("in serializeCollectionToJSON");
       JSONObject jsonobj = convertToJson((Collection)c, ((JDOPersistenceManager)myShepherd.getPM()).getExecutionContext());
       jsonSerializedQueryResult=jsonobj;
       Util.writeToFile(jsonobj.toString(), getCacheFile().getAbsolutePath());
       System.out.println("Checking does JSON file exist? "+getCacheFile().exists());
       return jsonobj;
     }
     catch(Exception e){
       e.printStackTrace();
       return null;
     }
   }
   
   public JSONObject loadCachedJSON(Shepherd myShepherd){
     //just load and return the List<Object> from the cache
     
     System.out.println("loading cached JSON: ");
     try{
       String writePath=ShepherdProperties.getProperties("cache.properties","").getProperty("cacheRootDirectory");
       if(!writePath.endsWith("/"))writePath+="/";
       writePath+=getName()+"/"+getName()+".json";
       File sFile=getCacheFile();
       System.out.println("loading cached JSON: "+sFile.getAbsolutePath());
       
       if(sFile.exists()){
         InputStream is = new FileInputStream(sFile);
         String jsonTxt = IOUtils.toString(is, "UTF-8");
         System.out.println(jsonTxt);
         JSONObject jsonobj = new JSONObject(jsonTxt);
         //RESTUtils.getObjectFromJSONObject(jsonobj, String className, ((JDOPersistenceManager)myShepherd.getPM()).getExecutionContext());
         return jsonobj;
       }
       else{return null;}
       

     }
     catch(Exception e){
       e.printStackTrace();
     }
     return null;
   }
   
   public File getCacheFile(){
     String writePath=ShepherdProperties.getProperties("cache.properties","").getProperty("cacheRootDirectory");
     if(!writePath.endsWith("/"))writePath+="/";
     writePath+=getName()+".json";
     System.out.println("Cache file path to: "+writePath);
     return new File(writePath);
   }
   

  

}

