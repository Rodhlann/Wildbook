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

package org.ecocean;

import javax.jdo.JDOException;
import javax.jdo.JDOHelper;
import javax.jdo.PersistenceManagerFactory;

import java.io.File;
import java.io.FileInputStream;
import java.io.IOException;
import java.util.Enumeration;
import java.util.Properties;

import java.util.TreeMap;

import java.util.concurrent.ConcurrentHashMap;

import java.io.*;

public class ShepherdPMF {

  //private static PersistenceManagerFactory pmf;
  //private static String currentContext="context0";
  private static TreeMap<String,PersistenceManagerFactory> pmfs=new TreeMap<String,PersistenceManagerFactory>();

  private static ConcurrentHashMap<String,String> shepherds=new ConcurrentHashMap<String, String>();


  public synchronized static PersistenceManagerFactory getPMF(String context) {
    //public static PersistenceManagerFactory getPMF(String dbLocation) {
    
    if(pmfs==null){pmfs=new TreeMap<String,PersistenceManagerFactory>();}
    
    try {
      if ((!pmfs.containsKey(context))||(pmfs.get(context).isClosed())) {

        Properties dnProperties = new Properties();


        dnProperties.setProperty("javax.jdo.PersistenceManagerFactoryClass", "org.datanucleus.api.jdo.JDOPersistenceManagerFactory");

        Properties props = new Properties();
        String shepherdDataDir="shepherd_data_dir";
        
        //System.out.println("     Let's find the corresponding dataDir for context: "+context);
        if((ContextConfiguration.getDataDirForContext(context)!=null)&&(!ContextConfiguration.getDataDirForContext(context).trim().equals(""))){
          //System.out.println("     Looking up corresponding contextDir...");
          shepherdDataDir=ContextConfiguration.getDataDirForContext(context);
          
        }
        //System.out.println("ShepherdPMF: Data directory for context "+context+" is: "+shepherdDataDir);
        Properties overrideProps=loadOverrideProps(shepherdDataDir);
        //System.out.println(overrideProps);
        
        if(overrideProps.size()>0){props=overrideProps;}
        else {
          //otherwise load the embedded commonConfig
          
          try {
            //props.load(ShepherdPMF.class.getResourceAsStream("/bundles/jdoconfig.properties"));
            props=ShepherdProperties.getProperties("jdoconfig.properties", "");
          } 
          catch (Exception ioe) {
            ioe.printStackTrace();
          }
        }
        
        
        Enumeration<Object> propsNames = props.keys();
        while (propsNames.hasMoreElements()) {
          String name = (String) propsNames.nextElement();
          if (name.startsWith("datanucleus") || name.startsWith("javax.jdo")) {
              dnProperties.setProperty(name, props.getProperty(name).trim());
          }
        }

        /********************************************************************************************************************************************/
        /* This code below allows you to define the Database Connection parameters (user, password and connection URL in environment variables      */
        /* and also Docker or Kubernetes secrets.                                                                                                   */ 
        /*                                                                                                                                          */   
        /* You create a setenv.sh script containing exports for the environment variables and place the script in the $CATALINA_HOME/bin directory. */
        /* The catalina.sh script will call the setenv.sh script (if it exists) before it launches Tomcat.                                          */ 
        /* This allows you specify the Database Connection parameters: user, password and connection URL at run time instead of hardcoding them in  */ 
        /* the jdoconfig.properties file which is inside the wildbook.war file. This also makes it easy to use with Docker and Kubernetes.          */
        /* And you define the Database Connection parameters as Docker secrets or Kubernetes secrets which makes the credentials secure.            */  
        /********************************************************************************************************************************************/  
        /*                                                                                                                                          */       
        /* Example setenv.sh file                                                                                                                   */     
        /*                                                                                                                                          */
        /* #!/usr/bin/env bash                                                                                                                      */
        /* printf 'Setting Database Connection environment variables\n'                                                                             */
        /*                                                                                                                                          */
        /* export DB_USER="wildbook"                                                                                                                */
        /* # export DB_USER_FILE=/run/secrets/db-user                                                                                               */     
        /* export DB_PASSWORD="Passw0rd#"                                                                                                           */
        /* # export DB_PASSWORD_FILE=/run/secrets/db-password                                                                                       */
        /* export DB_CONNECTION_URL="jdbc:mysql://mysql-wildbook:3306/wildbook?useSSL=false&allowPublicKeyRetrieval=true"                           */
        /* # export DB_CONNECTION_URL_FILE=/run/secrets/db-connection-url                                                                           */ 
        /********************************************************************************************************************************************/
        /*                                                                                                                                          */
        /* Example docker-compose.yml file below.                                                                                                   */ 
        /*                                                                                                                                          */   
        /* Put the setenv.sh script in the directory where the docker-compose.yml file exists. Docker will mount the local setenv.sh file to        */
        /* /usr/local/tomcat/bin/setenv.sh when the docker container is started.                                                                    */
        /*                                                                                                                                          */ 
        /* version: '3.3'                                                                                                                           */
        /* configs:                                                                                                                                 */ 
        /*   setenv.sh:                                                                                                                             */ 
        /*     file: ./setenv.sh                                                                                                                    */ 
        /* services:                                                                                                                                */ 
        /*   tomcat-wildbook:                                                                                                                       */ 
        /*     image: gforghetti/tomcat-wildbook:latest                                                                                             */ 
        /*     configs:                                                                                                                             */ 
        /*       - source: setenv.sh                                                                                                                */ 
        /*         target: /usr/local/tomcat/bin/setenv.sh                                                                                          */ 
        /*                                                                                                                                          */    
        /********************************************************************************************************************************************/     

        /********************************************************************************************************************************************/ 
        /* Retrieve the Database user from an environment Variable                                                                                  */
        /********************************************************************************************************************************************/
        System.out.println("Checking for the DB_USER environment variable.");
        String dbUser = System.getenv("DB_USER");
        if (dbUser != null && !dbUser.isEmpty()) {
            System.out.println("The DB_USER environment variable was specified, will use it to connect to the Database.");
            dnProperties.setProperty("datanucleus.ConnectionUserName", dbUser.trim());
        } else {
        /********************************************************************************************************************************************/            
        /* Retrieve the Database User from a file. This allows the use of Docker Secrets and Kubernetes Secrets!                                    */
        /********************************************************************************************************************************************/
            String dbUserSecretFile = System.getenv("DB_USER_FILE");
            if (dbUserSecretFile != null && !dbUserSecretFile.isEmpty()) {
                System.out.println("The DB_USER_FILE environment variable was specified, will retrieve the value from the file and use it to connect to the Database.");
                dbUser = IO.from(new File(dbUserSecretFile)).toString();
                dnProperties.setProperty("datanucleus.ConnectionUserName", dbUser.trim());
            }
        }

        /********************************************************************************************************************************************/ 
        /* Retrieve the Database password from an environment Variable */
        /********************************************************************************************************************************************/ 
        System.out.println("Checking for the DB_PASSWORD environment variable.");
        String dbPassword = System.getenv("DB_PASSWORD");    
        if (dbPassword != null && !dbPassword.isEmpty()) {
            System.out.println("The DB_PASSWORD environment variable was specified, will use it to connect to the Database.");
            dnProperties.setProperty("datanucleus.ConnectionPassword", dbPassword.trim());
        } else {
        /********************************************************************************************************************************************/ 
        /* Retrieve the Database Password from a file. This allows the use of Docker Secrets and Kubernetes Secrets!                                */
        /********************************************************************************************************************************************/ 
            String dbPasswordSecretFile = System.getenv("DB_PASSWORD_FILE");
            if (dbPasswordSecretFile != null && !dbPasswordSecretFile.isEmpty()) {
                System.out.println("The DB_PASSWORD_FILE environment variable was specified, will retrieve the value from the file and use it to connect to the Database.");
                dbPassword = IO.from(new File(dbPasswordSecretFile)).toString();
                dnProperties.setProperty("datanucleus.ConnectionPassword", dbPassword.trim());
            }
        }

        /********************************************************************************************************************************************/ 
        /* Retrieve the Database Connection URL from an environment Variable                                                                        */
        /********************************************************************************************************************************************/ 
        System.out.println("Checking for the DB_CONNECTION_URL environment variable.");
        String dbConnectionURL = System.getenv("DB_CONNECTION_URL");
        if (dbConnectionURL != null && !dbConnectionURL.isEmpty()) {
            System.out.println("The DB_CONNECTION_URL environment variable was specified, will use it to connect to the Database.");
            dnProperties.setProperty("datanucleus.ConnectionURL", dbConnectionURL.trim());
        } else {
        /********************************************************************************************************************************************/              
        /* Retrieve the Database Connection URL from a file. This allows the use of Docker Secrets and Kubernetes Secrets!                          */
        /********************************************************************************************************************************************/         
            String dbConnectionURLFile = System.getenv("DB_PASSWORD_FILE");
            if (dbConnectionURLFile != null && !dbConnectionURLFile.isEmpty()) {
                System.out.println("The DB_CONNECTION_URL_FILE environment variable was specified, will retrieve the value from the file and use it to connect to the Database.");
                dbConnectionURL = IO.from(new File(dbConnectionURLFile)).toString();
                dnProperties.setProperty("datanucleus.ConnectionURL", dbConnectionURL.trim());
            }
        }    
        
        //make sure to close an old PMF if switching
        //if(pmf!=null){pmf.close();}

        pmfs.put(context, JDOHelper.getPersistenceManagerFactory(dnProperties));
        return pmfs.get(context);

      }
      else{
        
        return pmfs.get(context);
        
      }
      
    } catch (JDOException jdo) {
      jdo.printStackTrace();
      System.out.println("I couldn't instantiate a PMF.");
      return null;
    }
  }
  
  public static Properties loadOverrideProps(String shepherdDataDir) {
    //System.out.println("     Starting loadOverrideProps");
    Properties myProps=new Properties();
    File configDir = new File("webapps/"+shepherdDataDir+"/WEB-INF/classes/bundles");
    //System.out.println("     In dir: "+configDir.getAbsolutePath());
    //sometimes this ends up being the "bin" directory of the J2EE container
    //we need to fix that
    if((configDir.getAbsolutePath().contains("/bin/")) || (configDir.getAbsolutePath().contains("\\bin\\"))){
      String fixedPath=configDir.getAbsolutePath().replaceAll("/bin", "").replaceAll("\\\\bin", "");
      configDir=new File(fixedPath);
      //System.out.println("     Fixing the bin issue in Shepherd PMF. ");
      //System.out.println("     The fix abs path is: "+configDir.getAbsolutePath());
    }
     //System.out.println("     Looking in: "+configDir.getAbsolutePath());
    if(!configDir.exists()){configDir.mkdirs();}
    File configFile = new File(configDir, "jdoconfig.properties");
    if (configFile.exists()) {
      //System.out.println("     Overriding default properties with " + configFile.getAbsolutePath());
      FileInputStream fileInputStream = null;
      try {
        fileInputStream = new FileInputStream(configFile);
        myProps.load(fileInputStream);
      } catch (Exception e) {
        e.printStackTrace();
      }
      finally {
        if (fileInputStream != null) {
          try {
            fileInputStream.close();
          } catch (Exception e2) {
            e2.printStackTrace();
          }
        }
      }
    }
    return myProps;
  }
  
  public static void setShepherdState(String shepherdID, String state){
    if(shepherds==null) shepherds=new ConcurrentHashMap<String, String>();

    shepherds.put(shepherdID, state);
  }
  
  public static void removeShepherdState(String shepherdID){
    if(shepherds==null) shepherds=new ConcurrentHashMap<String, String>();

    shepherds.remove(shepherdID);
  }
  
  public static String getShepherdState(String shepherdID){
    if(shepherds==null) shepherds=new ConcurrentHashMap<String, String>();

    return shepherds.get(shepherdID);
  }
  
  public static ConcurrentHashMap<String,String> getAllShepherdStates(){
    if(shepherds==null) shepherds=new ConcurrentHashMap<String, String>();
    return shepherds;
  }
  

}
