/*
 * This file is a part of Wildbook.
 * Copyright (C) 2015 WildMe
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * Foobar is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with Wildbook.  If not, see <http://www.gnu.org/licenses/>.
 */

package org.ecocean.media;

import static java.nio.file.StandardCopyOption.REPLACE_EXISTING;

import java.io.File;
import java.io.IOException;
import java.net.MalformedURLException;
import java.net.URL;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import org.json.JSONObject;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;


/**
 * LocalAssetStore references MediaAssets on the current host's
 * filesystem.
 *
 * To create a new store outside of Java, you can directly insert a
 * row into the assetstore table like so (adjusting paths as needed):
 *
 * insert into assetstore (name,type,config,writable) values ('local store', 'LOCAL', '{"root":"/filesystem/path/to/localassetstore","webroot":"http://host/web/path/to/localassetstore"}', true);
 *
 * Then ensure your webserver is configured to serve the filesystem
 * path at the webroot.
 *
 * If you have only one asset store defined, it will be considered the
 * default (see AssetStore.loadDefault()).
 */
public class LocalAssetStore extends AssetStore {
    private static final String KEY_ROOT = "root";
    private static final String KEY_WEB_ROOT = "webroot";
    private static final Logger logger = LoggerFactory.getLogger(org.ecocean.media.LocalAssetStore.class);

    private Path root;
    transient private String webRoot;


    /**
     * Create a new local filesystem asset store.
     *
     * @param name Friendly name for the store.
     *
     * @param root Filesystem path to the base of the asset directory.
     * Must not be null.
     *
     * @param webRoot Base web url under which asset paths are
     * appended.  If null, this store offers no web access to assets.
     *
     * @param wriable True if we are allowed to save files under the
     * root.
     */
    public LocalAssetStore(final String name, final Path root,
                           final String webRoot, final boolean writable)
    {
        this(null, name, makeConfig(root, webRoot), writable);
    }

    /**
     * Create a new local filesystem asset store.  Should only be used
     * internal to AssetStore.buildAssetStore().
     *
     * @param root Filesystem path to the base of the asset directory.
     * Must not be null.
     *
     * @param webRoot Base web url under which asset paths are
     * appended.  If null, this store offers no web access to assets.
     */
    LocalAssetStore(final Integer id, final String name,
                    final AssetStoreConfig config, final boolean writable)
    {
        super(id, name, AssetStoreType.LOCAL, config, writable);
    }

    /**
     * Create our config map.
     */
    private static AssetStoreConfig makeConfig(final Path root, final String webRoot) {
        AssetStoreConfig config = new AssetStoreConfig();

        if (root != null) config.put(KEY_ROOT, root);
        if (webRoot != null) config.put(KEY_WEB_ROOT, webRoot);

        return config;
    }

    public Path root() {
        if (root == null) {
            root = config.getPath(KEY_ROOT);
            logger.info("Asset Store [" + name + "] using root [" + root + "]");
        }
        return root;
    }

    private String webRoot() {
        if (webRoot == null) {
            webRoot = config.getString(KEY_WEB_ROOT);
            logger.info("Asset Store [" + name + "] using web root [" + webRoot + "]");
        }
        return webRoot;
    }

    /**
     * Create a new MediaAsset that points to an existing file under
     * our root.
     *
     * @param path Relative or absolute path to a file.  Must be under
     * the asset store root.
     *
     * @return The MediaAsset, or null if the path is invalid (not
     * under the asset root or nonexistent).
     */
    @Override
    public MediaAsset create(final JSONObject params) throws IllegalArgumentException {
        Path subpath = pathFromParameters(params, true);  //check to see if path is legit
        if (subpath == null) return null;
/*
        Path root = root();
        Path subpath = ensurePath(root, path);
System.out.println("create() has subpath = " + subpath);
*/
        params.put("path", subpath.toString());  //always store it relative, not absolute
        try {
            return new MediaAsset(this, params);
        } catch (IllegalArgumentException e) {
            logger.warn("Bad path", e);
            return null;
        }
    }


    public boolean cacheLocal(MediaAsset ma, boolean force) {
        return true;  //easy!
    }

    public Path localPath(MediaAsset ma) {
        Path subpath = pathFromParameters(ma.getParameters(), true);
        return root().resolve(subpath);
/*
System.out.println(ma.getParameters());
System.out.println(">>>> localPath path=" + path);
        if (path == null) return null;
        Path root = root();
        Path subpath = ensurePath(root, path);
        return root.resolve(subpath);
*/
    }


    //this returns the subpath relative to root
    public Path pathFromParameters(JSONObject params) {
        return pathFromParameters(params, false);  //default behavior will be not to check
    }

    public Path pathFromParameters(JSONObject params, boolean checkExists) {
        Object p = getParameter(params, "path");
        if (p == null) {
        //if ((params == null) || !params.has("path") || (params.get("path") == null)) {
            logger.warn("pathFromParameters(): Invalid parameters");
            throw new IllegalArgumentException("null path");
        }
        //Path passed = Paths.get(params.getString("path"));
        Path passed = Paths.get(p.toString());
        Path path = null;
        if (checkExists) {
            path = ensurePath(root(), passed);
        } else {
            path = checkPath(root(), passed);
/*
System.out.println("root = " + root);
System.out.println(params.getString("path") + " is .path");
            path = new File(params.getString("path")).toPath();
System.out.println("path = " + path);
            Path subpath = ensurePath(root, path);
System.out.println("subpath = " + subpath);
*/
        }
        return path;
    }

    /**
     * Create a new asset from a File. The file is
     * copied in to the store as part of this process.
     *
     * @param file File to copy in.
     *
     * @param params params.path is the (optional) subdirectory and (required) filename
     * relative to the asset store root in which to store the file.
     *
     */
    @Override
    public MediaAsset copyIn(final File file,
                             final JSONObject params)
        throws IOException
    {
        if (!this.writable) throw new IOException(this.name + " is a read-only AssetStore");
        Path subpath = pathFromParameters(params);
        if (subpath == null) throw new IOException("no path passed in parameters");
        //Path root = root();
        //Path subpath = ensurePath(root, path);
        Path fullpath = root().resolve(subpath);
        fullpath.getParent().toFile().mkdirs();
        logger.debug("copying from " + file + " to " + fullpath);
        Files.copy(file.toPath(), fullpath, REPLACE_EXISTING);
        params.put("path", subpath.toString());  //always store it relative, not absolute (in case it was passed in as such)
        return new MediaAsset(this, params);
    }


    @Override
    public void deleteFrom(final MediaAsset ma)
    {
        if (!this.writable) return;
        File file = localPath(ma).toFile();
System.out.println("LocalAssetStore attempting to delete file=" + file);
        if (!file.exists()) {
            return;
        }
        file.delete();

/*   TODO not sure if we should remove empty parent dirs?  maybe some other spaghetti depends on it?
        File parentDir = file.getParentFile();

        File[] files = parentDir.listFiles();
        if (files == null || files.length == 0) { //some JVMs return null for empty dirs
            parentDir.delete();
        }
*/
    }



    /**
     * Make sure path is under the root, either passed in as a
     * relative path or as an absolute path under the root.
     *
     * @return Subpath to the file relative to the root.
     */
    public static Path checkPath(final Path root, final Path path) {
        if (path == null) throw new IllegalArgumentException("null path");

        Path result = root.resolve(path);
        result = root.relativize(result.normalize());

        if (result.startsWith("..")) {
            throw new IllegalArgumentException("Path not under given root");
        }

        return result;
    }

    /**
     * Like checkPath(), but throws an IllegalArgumentException if the
     * resulting file doesn't exist.
     *
     * @return Subpath to the file relative to the root.
     */
    public static Path ensurePath(final Path root, final Path path) {
        Path result = checkPath(root, path);
        Path full = root.resolve(path);
        if (!full.toFile().exists())
            throw new IllegalArgumentException(full + " does not exist");

        return result;
    }

    /**
     * Return a full URL to the given MediaAsset, or null if the asset
     * is not web-accessible.
     */
    @Override
    public URL webURL(final MediaAsset ma) {
        if ((webRoot() == null) || (ma == null)) return null;
        Path path = pathFromParameters(ma.getParameters());
        if (path == null) return null;
System.out.println("webURL() path = "+path);

        try {
            URL url;
            if (! path.startsWith("/")) {
                url = new URL(webRoot() + "/" + path.toString());
            } else {
                url = new URL(webRoot() + path.toString());
            }
            logger.debug("url: " + url.toString());
            return url;

        } catch (MalformedURLException e) {
            logger.warn("Can't construct web path", e);
            return null;
        }
    }

}


