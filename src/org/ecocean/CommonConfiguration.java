package org.ecocean;

import java.util.Properties;
import java.io.IOException;

public class CommonConfiguration {
	
	//class setup
	private static Properties props=new Properties();
	
	
	private static void initialize(){
		//set up the file input stream
		if(props.size()==0){
			try{
				props.load(CommonConfiguration.class.getResourceAsStream("/bundles/en/commonConfiguration.properties"));
			}
			catch(IOException ioe){ioe.printStackTrace();}
		}
	}
	
	public static boolean refresh(){
		try{
		  props=null;
			props.load(CommonConfiguration.class.getResourceAsStream("/bundles/en/commonConfiguration.properties"));
		}
		catch(IOException ioe){ioe.printStackTrace(); return false;}
		return true;
	}

	//start getter methods
	public static String getURLLocation(){initialize();return props.getProperty("urlLocation").trim();}
	public static String getMailHost(){initialize();return props.getProperty("mailHost").trim();}
	public static String getImageDirectory(){initialize();return props.getProperty("imageLocation").trim();}
	public static String getMarkedIndividualDirectory(){initialize();return props.getProperty("markedIndividualDirectoryLocation").trim();}
	public static String getAdoptionDirectory(){initialize();return props.getProperty("adoptionLocation").trim();}
	public static String getWikiLocation(){initialize();return props.getProperty("wikiLocation").trim();}
	public static String getDBLocation(){initialize();return props.getProperty("dbLocation").trim();}
	public static String getAutoEmailAddress(){initialize();return props.getProperty("autoEmailAddress").trim();}
	public static String getNewSubmissionEmail(){initialize();return props.getProperty("newSubmissionEmail").trim();}
	public static String getR(){initialize();return props.getProperty("R").trim();}
	public static String getEpsilon(){initialize();return props.getProperty("epsilon").trim();}
	public static String getSizelim(){initialize();return props.getProperty("sizelim").trim();}
	public static String getMaxTriangleRotation(){initialize();return props.getProperty("maxTriangleRotation").trim();}
	public static String getC(){initialize();return props.getProperty("C").trim();}
	public static String getHTMLDescription(){initialize();return props.getProperty("htmlDescription").trim();}
	public static String getHTMLKeywords(){initialize();return props.getProperty("htmlKeywords").trim();}
	public static String getHTMLTitle(){initialize();return props.getProperty("htmlTitle").trim();}
	public static String getCSSURLLocation(){initialize();return props.getProperty("cssURLLocation").trim();}
	public static String getHTMLAuthor(){initialize();return props.getProperty("htmlAuthor").trim();}
	public static String getHTMLShortcutIcon(){initialize();return props.getProperty("htmlShortcutIcon").trim();}

	public static String getGlobalUniqueIdentifierPrefix(){initialize();return props.getProperty("GlobalUniqueIdentifierPrefix");}
	
	public static String getURLToMastheadGraphic(){initialize();return props.getProperty("urlToMastheadGraphic");}
	
	public static String getTapirLinkURL(){initialize();return props.getProperty("tapirLinkURL");}
  
	
	public static String getURLToFooterGraphic(){initialize();return props.getProperty("urlToFooterGraphic");}
	public static String getGoogleMapsKey(){initialize();return props.getProperty("googleMapsKey");}
	public static String getGoogleSearchKey(){initialize();return props.getProperty("googleSearchKey");}
	
	public static String getProperty(String name){initialize();return props.getProperty(name);}

	public static boolean showProperty(String thisString){return true;}
	
	/**
	 * This configuration option defines whether adoptions of MarkedIndividual or encounter objects are allowed. Generally adoptions are used as a fundraising or public awareness tool.
	 * @return true if adoption functionality should be displayed. False if adoptions are not supported in this catalog.
	 */
	public static boolean allowAdoptions(){
	  boolean canAdopt = true;
	  if((props.getProperty("allowAdoptions")!=null)&&(props.getProperty("allowAdoptions").equals("false"))){
	    canAdopt=false;
	  }
	  return canAdopt;
	}
	
	/**
	 * This configuration option defines whether nicknames are allowed for MarkedIndividual entries. 
	 * @return true if nicknames are displayed for MarkedIndividual entries. False otherwise.
	 */
	 public static boolean allowNicknames(){
	    boolean canNickname = true;
	    if((props.getProperty("allowNicknames")!=null)&&(props.getProperty("allowNicknames").equals("false"))){
	      canNickname=false;
	    }
	    return canNickname;
	  }
	
	 /**
	  * This configuration option defines whether the spot pattern recognition software embedded in the framework is used for the species under study.
	  * @return true if this catalog is for a species for which the spot pattern recognition software component can be used. False otherwise.
	  */
	 public static boolean useSpotPatternRecognition(){
	    boolean useSpotPatternRecognition = true;
	    if((props.getProperty("useSpotPatternRecognition")!=null)&&(props.getProperty("useSpotPatternRecognition").equals("false"))){
	      useSpotPatternRecognition=false;
	    }
	    return useSpotPatternRecognition;
	  }
	 
	 /**
	  * This configuration option defines whether users can edit this catalog. Some studies may wish to use the framework only for data display.
	  * @return true if edits are allows. False otherwise.
	  */
   public static boolean isCatalogEditable(){
     boolean isCatalogEditable = true;
     if((props.getProperty("isCatalogEditable")!=null)&&(props.getProperty("isCatalogEditable").equals("false"))){
       isCatalogEditable=false;
     }
     return isCatalogEditable;
   }
   
   /**
    * This configuration option defines whether users can edit this catalog. Some studies may wish to use the framework only for data display.
    * @return true if edits are allows. False otherwise.
    */
   public static boolean showEXIFData(){
     boolean showEXIF = true;
     if((props.getProperty("showEXIF")!=null)&&(props.getProperty("showEXIF").equals("false"))){
       showEXIF=false;
     }
     return showEXIF;
   }
	
}
