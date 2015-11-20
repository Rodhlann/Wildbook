package org.ecocean.media;

import java.io.File;
import java.nio.file.Path;
import java.util.Arrays;
import java.util.HashSet;
import org.ecocean.Shepherd;

import javax.jdo.*;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

public class MediaAssetFactory {
    //private static final Logger logger = LoggerFactory.getLogger(MediaAssetFactory.class);

    //public static final String TABLENAME_MEDIAASSET = "mediaasset";
    //public static final String ALIAS_MEDIAASSET = "ma";
    //public static final String PK_MEDIAASSET = "id";

    public static final int NOT_SAVED = -1;

    private MediaAssetFactory() {
        // prevent instantiation
    }


    /**
     * Fetch a single asset from the database by id.
     */
    public static MediaAsset load(final long id, Shepherd myShepherd) {
        return null;
    }

/*
    public static MediaAsset load(final Database db, final long id)
        throws DatabaseException
    {
        SqlWhereFormatter where = new SqlWhereFormatter();
        where.append(PK_MEDIAASSET, id);

        Table table = db.getTable(TABLENAME_MEDIAASSET);

        RecordSet rs = table.getRecordSet(where.getWhereClause(), 1);
        if (rs.next()) {
            return valueOf(rs);
        }
        return null;
    }
*/


    private static Path createPath(final String pathstr)
    {
        if (pathstr == null) {
            return null;
        }

        return new File(pathstr).toPath();
    }


    /**
     * Store to the given database.
     */
    public static void save(final MediaAsset ma, Shepherd myShepherd) {
        myShepherd.getPM().makePersistent(ma);
    }

    /**
     * Delete this asset and any child assets from the given database.
     * Does not delete any asset files.
     *
     * @param db Database where the asset lives.
     */
    public static void delete(final int id) {
    }

/*
    public static void delete(final Database db, final int id) throws DatabaseException {
        Table table = db.getTable(TABLENAME_MEDIAASSET);
        table.deleteRows("id = " + id);
    }
*/


    public static void deleteFromStore(final MediaAsset ma) {
        ma.store.deleteFrom(ma);
    }


}
