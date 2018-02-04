package org.ecocean.ai.nmt.google;


import com.google.cloud.translate.Detection;
import com.google.cloud.translate.Translate;
import com.google.cloud.translate.TranslateOptions;
import com.google.cloud.translate.Translation;
import com.google.cloud.translate.Translate.TranslateOption;

public class DetectTranslate {

  
//Depends on the system variable GOOGLE_APPLICATION_CREDENTIALS to get JSON key for service account authentication
  
  public static String translateToEnglish(String text){
    
    //String apiKey= ShepherdProperties.getProperties("googleKeys.properties","").getProperty("translate_key");
    //Translate translate = TranslateOptions.newBuilder().setApiKey(apiKey).build().getService();
    
    Translate translate = TranslateOptions.getDefaultInstance().getService();
    
    Translation translation = translate.translate(text,
    TranslateOption.targetLanguage("en"));
    //System.out.println(translation.getTranslatedText());
    text=translation.getTranslatedText();
    return text;
  }

//Depends on the system variable GOOGLE_APPLICATION_CREDENTIALS to get JSON key for service account authentication
  
  public static String detectLanguage(String text){
    //String apiKey= ShepherdProperties.getProperties("googleKeys.properties","").getProperty("translate_key");
    //Translate translate = TranslateOptions.newBuilder().setApiKey(apiKey).build().getService();
    
    Translate translate = TranslateOptions.getDefaultInstance().getService();
    
    
    Detection detection = translate.detect(text);
    String detectedLanguage = detection.getLanguage();
    System.out.println("Detected language "+detectedLanguage+" from text: "+text);
    return detectedLanguage;
  }
  
//Depends on the system variable GOOGLE_APPLICATION_CREDENTIALS to get JSON key for service account authentication
  
  public static String translateToLanguage(String text, String language, String context){
    //String apiKey= ShepherdProperties.getProperties("googleKeys.properties","").getProperty("translate_key");
    //Translate translate = TranslateOptions.newBuilder().setApiKey(apiKey).build().getService();
    
    //Depends on the system variable GOOGLE_APPLICATION_CREDENTIALS to get JSON key for service account authentication
    Translate translate = TranslateOptions.getDefaultInstance().getService();
    
    
    Translation translation = translate.translate(text, TranslateOption.targetLanguage(language));
    //System.out.println(translation.getTranslatedText());
    text=translation.getTranslatedText();
    return text;
  }

  
  
  //Legacy Methods from Stella
  /*
  public static String translate(String ytRemarks, String context){
    return translateToEnglish(ytRemarks, context);
  }

  public static String detect(String ytRemarks, String context){
    return detectLanguage(ytRemarks, context);
  }
  */

}
