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

package org.ecocean.batch;

import java.awt.RenderingHints;
import java.awt.image.BufferedImage;
import java.io.File;
import java.io.FileNotFoundException;
import java.io.IOException;
import java.lang.reflect.Constructor;
import java.net.URL;
import java.text.MessageFormat;
import java.util.ArrayList;
import java.util.Date;
import java.util.HashMap;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.Properties;
import java.util.ResourceBundle;
import javax.jdo.JDOObjectNotFoundException;
import javax.jdo.PersistenceManager;
import javax.servlet.ServletContext;
import org.apache.sanselan.ImageReadException;
import org.ecocean.CommonConfiguration;
import org.ecocean.Encounter;
import org.ecocean.Keyword;
import org.ecocean.MarkedIndividual;
import org.ecocean.Measurement;
import org.ecocean.Shepherd;
import org.ecocean.SinglePhotoVideo;
import org.ecocean.genetics.TissueSample;
import org.ecocean.servlet.BatchUpload;
import org.ecocean.util.DataUtilities;
import org.ecocean.util.FileUtilities;
import org.ecocean.util.MediaUtilities;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

/**
 * Task to process uploaded batch data and persist it to the database.
 * Because a batch upload needs to download media from arbitrary URLs,
 * it can take a long time to complete. To handle this, this class is launched
 * via a separate thread (from {@link BatchUpload}) and reference to it placed
 * in the user's session. It can subsequently be queries for its current
 * status/progress.
 *
 * @author Giles Winstanley
 */
public final class BatchProcessor implements Runnable {
  /** SLF4J logger instance for writing log entries. */
  private static Logger log = LoggerFactory.getLogger(BatchProcessor.class);
  /** List of individuals. */
  private List<MarkedIndividual> listInd;
  /** List of encounters. */
  private List<Encounter> listEnc;
  /** List of measurements. */
  private List<Measurement> listMea;
  /** Map of media-items to batch-media used during batch processing. */
  private Map<SinglePhotoVideo, BatchMedia> mapMedia;
  /** List of samples. */
  private List<TissueSample> listSam;
  /** List of errors produced by the batch processor (fatal). */
  private List<String> errors;
  /** List of warnings produced by the batch processor (non-fatal). */
  private List<String> warnings;
  /** Location of resources for internationalization. */
  private static final String RESOURCES = "bundles";
  /** Resources for internationalization. */
  private Locale locale;
  /** Resources for internationalization. */
  private ResourceBundle bundle;
  /** Data folder for web application. */
  private File dataDir;
  /** Data folder for holding user-specific information (parent). */
  private File dataDirUsers;
  /** Data folder specific to this user (acts as temporary storage area). */
  private File dataDirUser;
  /** ServletContext for web application, to allow access to resources. */
  private ServletContext servletContext;
  /** Username of person doing batch upload (for logging in comments). */
  private String user;
  /** Maximum &quot;item&quot; count (used for progress display). */
  private int maxCount;
  /** Current &quot;item&quot; count (used for progress display). */
  private int counter;
  /** Instance of plugin to use. */
  private BatchProcessorPlugin plugin;
  /** Enumeration representing possible status values for the batch processor. */
  public enum Status { WAITING, INIT, RUNNING, FINISHED, ERROR };
  /** Enumeration representing possible processing phases. */
  public enum Phase { NONE, MEDIA_DOWNLOAD, PERSISTENCE, THUMBNAILS, PLUGIN, DONE };
  /** Current status of the batch processor. */
  private Status status = Status.WAITING;
  /** Current phase of the batch processor. */
  private Phase phase = Phase.NONE;
  /** Throwable instance produced by the batch processor (if any). */
  private Throwable thrown;

  public BatchProcessor(List<MarkedIndividual> listInd, List<Encounter> listEnc, List<String> errors, List<String> warnings, Locale locale) {
    this.listInd = listInd;
    this.listEnc = listEnc;
    this.errors = errors;
    this.warnings = warnings;
    this.locale = locale;
    this.bundle = ResourceBundle.getBundle(RESOURCES + "/batchUpload", locale);
    counter = 0;
    maxCount = 1;
    log.debug(this.toString());
  }

  public void setListMea(List<Measurement> listMea) {
    this.listMea = listMea;
  }

  public void setMapMedia(Map<SinglePhotoVideo, BatchMedia> mapMedia) {
    this.mapMedia = mapMedia;
  }

  public void setListSam(List<TissueSample> listSam) {
    this.listSam = listSam;
  }

  @Override
  public String toString() {
    StringBuilder sb = new StringBuilder();
    sb.append("BatchProcessor[");
    sb.append("maxCount:").append(maxCount).append(", ");
    sb.append("counter:").append(counter).append(", ");
    sb.append("ind:").append(listInd.size()).append(", ");
    sb.append("enc:").append(listEnc.size()).append(", ");
    if (mapMedia != null)
      sb.append("med:").append(mapMedia.size()).append(", ");
    if (listSam != null)
      sb.append("sam:").append(listSam.size()).append(", ");
    sb.setLength(sb.length() - 2);
    sb.append("]");
    return sb.toString();
  }

  public List<String> getErrors() {
    return errors;
  }

  public List<String> getWarnings() {
    return warnings;
  }

  /**
   * Sets the {@code ServletContext} to use for contextual reference,
   * which is required to access web application data files.
   * @param username name of user
   */
  public void setUser(String username) {
    if (username == null)
      throw new NullPointerException();
    if ("".equals(username.trim()))
      throw new IllegalArgumentException();
    this.user = username;
  }

  /**
   * Sets the {@code ServletContext} to use for contextual reference,
   * which is required to access web application data files.
   * @param servletContext {@code ServletContext} from calling servlet
   */
  public void setServletContext(ServletContext servletContext) {
    if (servletContext == null)
      throw new NullPointerException();
    this.servletContext = servletContext;
    try {
      this.dataDir = CommonConfiguration.getDataDirectory(servletContext);
      this.dataDirUsers = CommonConfiguration.getUsersDataDirectory(servletContext);
    }
    catch (FileNotFoundException ex) {
      throw new RuntimeException("Unable to locate data folders", ex);
    }
  }

  /**
   * @return Current status of processing.
   */
  public Status getStatus() {
    return status;
  }

  public boolean isTerminated() {
    return status == Status.FINISHED || status == Status.ERROR;
  }

  /**
   * @return Current phase of processing.
   */
  public Phase getPhase() {
    return phase;
  }

  public String getPluginPhaseMessage() {
    String s = (plugin == null) ? null : plugin.getStatusMessage();
    return (s == null) ? bundle.getString("gui.progress.status.phase.PLUGIN") : s;
  }

  /**
   * @return The {@code Throwable} instance thrown during processing, or {@code null}.
   */
  public Throwable getThrown() {
    return thrown;
  }

  /**
   * @return Current progress of the processor (between 0 and 1).
   */
  public float getProgress() {
    if (maxCount == 0)
      return 0f;
    if (plugin != null)
      return ((float)(counter + plugin.getCounter()) / (maxCount + plugin.getMaxCount()));
    else
      return ((float)counter / maxCount);
  }

  /**
   * Initializes the {@code BatchProcessorPlugin}, if specified, using reflection.
   * The plugin is specified via {@link CommonConfiguration#getBatchUploadPlugin()}.
   * @throws Exception 
   */
  private void setupPlugin() throws Exception {
    String s = CommonConfiguration.getBatchUploadPlugin();
    if (s == null || "".equals(s))
      return;
    try {
      Class<?> k = Class.forName(s);
      Class[] args = new Class[]{ List.class, List.class, List.class, List.class, Locale.class };
      Constructor<?> con = k.getDeclaredConstructor(args);
      plugin = (BatchProcessorPlugin)con.newInstance(listInd, listEnc, errors, warnings, bundle.getLocale());
      plugin.setServletContext(servletContext);
      plugin.setDataDir(dataDir);
      plugin.setListMea(listMea);
      plugin.setMapPhoto(mapMedia);
      plugin.setListSam(listSam);
    } catch (Exception ex) {
      String msg = bundle.getString("batchUpload.processError.plugin.loadFailed");
      msg = MessageFormat.format(msg, s);
      errors.add(msg);
      log.warn(msg, ex);
      throw ex;
    }
  }

  public void run() {
    status = Status.INIT;

    try {
      // Validate state, and abort if not configured correctly.
      if (servletContext == null)
        throw new IllegalStateException("ServletContext has not been configured");
      if (dataDir == null || dataDirUsers == null)
        throw new IllegalStateException("Data folders have not been configured");
      if (user == null)
        throw new IllegalStateException("User has not been configured");

      if (dataDirUser == null) {
        dataDirUser = new File(dataDirUsers, user);
        if (!dataDirUser.exists()) {
          if (!dataDirUser.mkdir())
            throw new RuntimeException(String.format("Unable to create user folder: %s", dataDirUser.getAbsolutePath()));
        } else if (!dataDirUser.isDirectory()) {
            throw new RuntimeException(String.format("%s isn't a folder", dataDirUser.getAbsolutePath()));
        }
      }

      // Setup progress monitoring.
      // MaxCount:
      // 1. Download of media from all encounters.
      // 2. Persistence of encounters.
      // 3. Persistence of individuals.
      // 4. Thumb for each media item of each encounter.
      // 5. Copyright-overlay thumb for each encounter.
      maxCount = listInd.size() + listEnc.size() * 2;
      for (Encounter enc : listEnc) {
        List<SinglePhotoVideo> x = enc.getSinglePhotoVideo();
        if (x != null)
          maxCount += x.size() * 2;
      }
      // Find & instantiate plugin.
      setupPlugin();

      // Start processing.
      status = Status.RUNNING;
      // Allow plugin to perform pre-processing.
      if (plugin != null) {
        try {
            plugin.preProcess();
        } catch (Exception ex) {
          String msg = bundle.getString("batchUpload.processError.plugin.preProcessError");
          msg = MessageFormat.format(msg, plugin.getClass().getName());
          errors.add(msg);
          throw ex;
        }
      }
      // Loop over encounters to download photos from specified
      // remote server(s) and save them to the local filesystem.
      // Done prior to persisting the individuals, to ensure files exist.
      phase = Phase.MEDIA_DOWNLOAD;
      if (dataDirUser != null && !dataDirUser.exists())
        dataDirUser.mkdir();
      final int MAX_SIZE = CommonConfiguration.getMaxMediaSizeInMegabytes();
      List<SinglePhotoVideo> removeAsOversized = new ArrayList<SinglePhotoVideo>();
      for (Encounter enc : listEnc) {
        if (enc.getSinglePhotoVideo() != null) {
          for (SinglePhotoVideo spv : enc.getSinglePhotoVideo()) {
            BatchMedia bm = mapMedia.get(spv);
            URL url = new URL(bm.getMediaURL());
            try {
              if (MediaUtilities.isAcceptableMediaFile(spv.getFilename())) {
                // NOTE: If file already exists the download is skipped and the
                // existing file used, which allows a simple type of resumable
                // upload. If this causes problems it will need changing.
                if (spv.getFile().exists()) {
                  log.info("Media file already exists: {}", spv.getFile().getAbsolutePath());
                } else {
                  FileUtilities.downloadUrlToFile(url, spv.getFile());
                  log.debug("Downloaded media file: {}", url);
                  // Check downloaded file size.
                  long size = spv.getFile().length() / 1000000;
                  if (size > MAX_SIZE) {
                    bm.setOversize(true);
                    removeAsOversized.add(spv);
                    String msg = bundle.getString("batchUpload.processError.mediaSize");
                    msg = MessageFormat.format(msg, mapMedia.get(spv).getMediaURL(), MAX_SIZE);
                    warnings.add(msg);
                  }
                }
                mapMedia.get(spv).setDownloaded(true);
              } else {
                String msg = bundle.getString("batchUpload.processError.mediaType");
                msg = MessageFormat.format(msg, mapMedia.get(spv).getMediaURL());
                errors.add(msg);
              }
            } catch (IOException iox) {
              String msg = bundle.getString("batchUpload.processError.mediaDownload");
              msg = MessageFormat.format(msg, mapMedia.get(spv).getMediaURL());
              errors.add(msg);
              log.warn(msg, iox);
            } finally {
              counter++;
            }
          }
          // Remove invalid/oversized media files from encounter.
          for (SinglePhotoVideo spv : removeAsOversized)
            enc.removeSinglePhotoVideo(spv);
        }
      }
      if (!errors.isEmpty()) {
        status = Status.ERROR;
        return;
      }

      phase = Phase.PERSISTENCE;
      Shepherd shepherd = new Shepherd();
      PersistenceManager pm = shepherd.getPM();
      try {
        shepherd.beginDBTransaction();

        // Find all encounters related to existing individuals, creating a map
        // of Encounter-to-IndividualID for later reference. IndividualID is
        // reset to null for initial commit to database, then reassigned to
        // the correct individual later.
        Map<Encounter, String> mapEncInd = new HashMap<Encounter, String>();
        for (Encounter enc : listEnc) {
          String iid = enc.getIndividualID();
          if (iid != null) {
            boolean found = false;
            for (MarkedIndividual mi : listInd) {
              if (iid.equals(mi.getIndividualID())) {
                found = true;
                break;
              }
            }
            if (!found) {
              mapEncInd.put(enc, iid);
              enc.setIndividualID(null);
            }
          }
        }


        // Persist all encounters (assigned/unassigned) to the database.
        // Assigned encounters must also be processed to assign unique IDs,
        // otherwise JDO barfs at primary key persistence problem.
        for (Encounter enc : listEnc) {
          // Create unique ID for encounter.
          // NOTE: Due to the UID implementation, this is double-checked
          // against the database for duplicate IDs before being used.
          String uid = null;
          Object testEnc = null;
          do {
            uid = DataUtilities.createUniqueEncounterId();
            try {
              testEnc = pm.getObjectById(pm.newObjectIdInstance(Encounter.class, uid));
              log.trace("Unable to use UID for encounter; already exists: {}", uid);
            } catch (JDOObjectNotFoundException jdox) {
//              log.trace("No existing encounter found with UID: {}", uid);
              testEnc = null;
            }
          } while (testEnc != null);
          enc.setCatalogNumber(uid);
          // Assign encounter ID to associated measurements.
          if (enc.getMeasurements() != null) {
            for (Measurement x : enc.getMeasurements()) {
              x.setCorrespondingEncounterNumber(enc.getCatalogNumber());
            }
          }
          // Assign encounter ID to associated media.
          if (enc.getSinglePhotoVideo() != null) {
            for (SinglePhotoVideo x : enc.getSinglePhotoVideo()) {
              x.setCorrespondingEncounterNumber(enc.getCatalogNumber());
            }
          }
          // Assign encounter ID to associated samples.
          if (enc.getTissueSamples() != null) {
            for (TissueSample x : enc.getTissueSamples()) {
              x.setCorrespondingEncounterNumber(enc.getCatalogNumber());
            }
          }
          // Relocate associated media into encounter folder.
          try {
            if (enc.getSinglePhotoVideo() != null)
              relocateMedia(enc);
          } catch(IOException iox) {
            log.error(iox.getMessage());
          }
          // Check for problem relocating media.
          List<SinglePhotoVideo> media = enc.getSinglePhotoVideo();
          if (media != null && !media.isEmpty()) {
            for (SinglePhotoVideo spv : media.toArray(new SinglePhotoVideo[0])) {
              BatchMedia bp = mapMedia.get(spv);
              if (!bp.isRelocated()) {
                String msg = bundle.getString("batchUpload.processError.mediaRename");
                msg = MessageFormat.format(msg, bp.getMediaURL());
                errors.add(msg);
                if (!spv.getFile().delete()) // Remove file to maintain clean data folder.
                  log.warn("Unable to delete unassigned media file: {}", spv.getFile().getAbsoluteFile());
                enc.removeSinglePhotoVideo(spv);
              } else if (!bp.isPersist()) {
                enc.removeSinglePhotoVideo(spv);
              }
            }
          }
          // Assign keywords to media.
          if (media != null && !media.isEmpty()) {
            for (SinglePhotoVideo spv : media.toArray(new SinglePhotoVideo[0])) {
              BatchMedia bp = mapMedia.get(spv);
              String[] keywords = bp.getKeywords();
              if (keywords != null && keywords.length > 0) {
                for (String kw : keywords) {
                  Keyword x = shepherd.getKeyword(kw);
                  if (x != null)
                    spv.addKeyword(x);
                }
              }
            }
          }
          // (must be done within current transaction to ensure referential integrity in database).
          // Set submitterID for later reference.
          enc.setSubmitterID(user);
          // Add comment to reflect batch upload.
          enc.addComments("<p><em>" + user + " on " + (new Date()).toString() + "</em><br>" + "Imported via batch upload.</p>");
          // Finally, if IndividualID for encounter is null, set it to "Unassigned".
          if (enc.getIndividualID() == null)
            enc.setIndividualID("Unassigned");
          // Persist encounter.
          try {
            pm.makePersistent(enc);
          } catch (Exception ex) {
            // Add error message for this encounter.
            String msg = bundle.getString("batchUpload.processError.persistEncounter");
            msg = MessageFormat.format(msg, enc.getCatalogNumber());
            errors.add(msg);
            throw ex;
          }
          counter++;
        }

        // Persist all new individuals to the database.
        for (MarkedIndividual ind : listInd) {
          try {
            pm.makePersistent(ind);
          } catch (Exception ex) {
            // Add error message for this individual.
            String msg = bundle.getString("batchUpload.processError.persistIndividual");
            msg = MessageFormat.format(msg, ind.getIndividualID());
            errors.add(msg);
            throw ex;
          }
          counter++;
        }

        // Persist encounters for existing individuals.
        // (This is not progress tracked, as should be comparatively quick.)
        for (Map.Entry<Encounter, String> me : mapEncInd.entrySet()) {
          try {
            MarkedIndividual ind = shepherd.getMarkedIndividual(me.getValue());
            ind.addEncounter(me.getKey());
            pm.makePersistent(ind);
          } catch (Exception ex) {
            String msg = bundle.getString("batchUpload.processError.assignEncounter");
            msg = MessageFormat.format(msg, me.getKey().getCatalogNumber(), me.getValue());
            errors.add(msg);
            throw ex;
          }
        }

        // Commit changes to store.
        shepherd.commitDBTransaction();

        // Allow plugin to perform media processing.
        if (plugin != null) {
          phase = Phase.PLUGIN;
          try {
              plugin.process();
          } catch (Exception ex) {
            log.warn(ex.getMessage(), ex);
            String msg = bundle.getString("batchUpload.processError.plugin.processError");
            msg = MessageFormat.format(msg, plugin.getClass().getName());
            errors.add(msg);
            throw ex;
          }
        }

        // TODO: Nasty hack to get resources from a language folder.
        // Should be using the standard ResourceBundle lookup mechanism to find
        // the appropriate language file.
        Properties props = new Properties();
        props.load(getClass().getResourceAsStream("/" + RESOURCES + "/" + locale.getLanguage() + "/encounter.properties"));
        String copyText = props.getProperty("nocopying");

        // Generate thumbnails for encounter's media.
        // This step is performed last, as it's considered optional, and just
        // a convenience to have all the thumbnail images pre-rendered.
        // If this stage fails, all data should already be in the database.
        phase = Phase.THUMBNAILS;
        long timeStart = System.currentTimeMillis();
        File encsDir = new File(dataDir, "encounters");
        for (Encounter enc : listEnc) {
          // Create folder for encounter.
          File encDir = new File(encsDir, enc.getCatalogNumber());
          if (!encDir.exists()) {
            if (!encDir.mkdirs())
              log.warn(String.format("Unable to create encounter folder: %s", encDir.getAbsoluteFile()));
          }
          // Process main thumbnail image.
          List<SinglePhotoVideo> media = enc.getSinglePhotoVideo();
          if (media != null && !media.isEmpty()) {
            // Assume first media item is one to use as thumbnail.
            // TODO: How to figure out which media item is best to use?
            File src = media.get(0).getFile();
            File dst = new File(src.getParentFile(), "thumb.jpg");
            if (dst.exists()) {
              log.warn(String.format("Thumbnail for encounter %s already exists", enc.getCatalogNumber()));
              continue;
            }
            // TODO: If video file, copy placeholder image? Just ignores and lets JSP handle it for now.
            if (MediaUtilities.isAcceptableImageFile(src)) {
              // Resize image to thumbnail & write to file.
              try {
                createThumbnail(src, dst, 100, 75);
                log.trace(String.format("Created thumbnail image for encounter %s", enc.getCatalogNumber()));
              }
              catch (Exception ex) {
                log.warn(String.format("Failed to create thumbnail correctly: %s", dst.getAbsolutePath()), ex);
              }
            }
            // Process copyright-overlaid thumbnail for each media item.
            for (SinglePhotoVideo spv : media) {
              if (!MediaUtilities.isAcceptableImageFile(spv.getFile()))
                continue;
              src = spv.getFile();
              dst = new File(src.getParentFile(), spv.getDataCollectionEventID() + ".jpg");
              if (dst.exists()) {
                log.warn(String.format("Thumbnail image %s already exists", spv.getDataCollectionEventID()));
                continue;
              }
              try {
                createThumbnailWithOverlay(src, dst, 250, 200, copyText);
//                log.trace(String.format("Created thumbnail for media item %s", spv.getDataCollectionEventID()));
              }
              catch (Exception ex) {
                log.warn(String.format("Failed to create thumbnail correctly: %s", dst.getAbsolutePath()), ex);
              }
              counter++;
            }
          } else {
            // Copy holding image in place.
            File rootPath = new File(servletContext.getRealPath("/"));
            File imgDir = new File(rootPath, "images");
            File src = new File(imgDir, "no_images.jpg");
            File dst = new File(encDir, "thumb.jpg");
            FileUtilities.copyFile(src, dst);
          }
          counter++;
        }
        long timeEnd = System.currentTimeMillis();
        long timeElapsed = (timeEnd - timeStart);
        log.debug(String.format("Time taken for media processing: %,d milliseconds", timeElapsed));
      } catch (Exception ex) {
        shepherd.rollbackDBTransaction();
        throw ex;
      } finally {
        shepherd.closeDBTransaction();
      }

      phase = Phase.DONE;
      cleanupTemporaryFiles();
      status = Status.FINISHED;
    } catch (Throwable th) {
      this.thrown = th;
      status = Status.ERROR;
      log.error(th.getMessage(), th);
    }
  }

  private void cleanupTemporaryFiles() {
    // Remove unassigned photos.
    for (Map.Entry<SinglePhotoVideo, BatchMedia> me : mapMedia.entrySet()) {
      BatchMedia bp = me.getValue();
      if (bp.isDownloaded() && !bp.isRelocated()) {
        if (me.getKey().getFile().delete())
          log.info(String.format("Deleted unused file: %s", me.getKey().getFile().getAbsoluteFile()));
        else
          log.warn(String.format("Failed to delete unused file: %s", me.getKey().getFile().getAbsoluteFile()));
      }
    }
    // Deletes temporary folder if no files found, otherwise leaves it there
    // in case it's also being used for something else.
    if (dataDirUser.listFiles().length == 0) {
      if (!dataDirUser.delete())
        log.warn(String.format("Failed to delete temporary folder: %s", dataDirUser.getAbsolutePath()));
    }
  }

  /**
   * Creates a thumbnail image from the specified image file.
   * @param src File denoting source image
   * @param dst File denoting destination image
   * @param w width of thumbnail (pixels)
   * @param h height of thumbnail (pixels)
   * @throws ImageReadException
   * @throws IOException 
   */
  private static void createThumbnail(File src, File dst, int w, int h) throws ImageReadException, IOException {
    BufferedImage img = MediaUtilities.loadImageAsSRGB(src);
    BufferedImage out = MediaUtilities.rescaleImage(img, w, h, RenderingHints.VALUE_INTERPOLATION_NEAREST_NEIGHBOR);
    MediaUtilities.saveImageJPEG(out, dst, false, 0.6f, false);
    out.flush();
    img.flush();
  }

  /**
   * Creates a thumbnail image with copyright overlay from the specified image file.
   * @param src File denoting source image
   * @param dst File denoting destination image
   * @param w width of thumbnail (pixels)
   * @param h height of thumbnail (pixels)
   * @param text to overlay on the image
   * @throws ImageReadException
   * @throws IOException
   */
  private static void createThumbnailWithOverlay(File src, File dst, int w, int h, String text) throws ImageReadException, IOException {
    BufferedImage img = MediaUtilities.loadImageAsSRGB(src);
    BufferedImage out = MediaUtilities.rescaleImageWithTextOverlay(img, w, h, text);
    MediaUtilities.saveImageJPEG(out, dst, false, 0.6f, false);
    out.flush();
    img.flush();
  }

  /**
   * Relocates the media for the specified encounter,
   * from the base data folder to the sub-folder specific to this encounter.
   * @param enc Encounter for which to move images
   * @throws IOException if unable to create required folder hierarchy or rename file
   */
  private void relocateMedia(Encounter enc) throws IOException {
    for (SinglePhotoVideo spv : enc.getSinglePhotoVideo()) {
      BatchMedia bp = mapMedia.get(spv);
      if (bp.isDownloaded() && !bp.isOversize()) {
        File encDir = new File(new File(dataDir, "encounters"), enc.getCatalogNumber());
        if (!encDir.exists()) {
          if (!encDir.mkdirs())
            throw new IOException("Unable to create folder for encounter " + enc.getCatalogNumber());
        }
        File src = spv.getFile();
        File dst = new File(encDir, src.getName());
        if (dst.exists()) {
          throw new IOException("Destination encounter image already exists: " + dst.getAbsolutePath());
        } else if (!src.renameTo(dst)) {
          throw new IOException("Unable to rename image for encounter " + spv.getFullFileSystemPath());
        } else {
          bp.setRelocated(true);
        }
        spv.setFullFileSystemPath(dst.getAbsolutePath());
        spv.setFilename(dst.getName());
      }
    }
  }
}
