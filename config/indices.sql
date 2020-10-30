-- these should all exist (and ideally will be created with package.jdo definitions)
--  BUT if you do not have them, please pick and choose.
--  NOTE: some wildbooks may already have some of these *under different names* ... ymmv

-- UGH, i guess _IDX (in caps!) should be what we standardize on.  that is what datanucleus does.
--   to make matters worse, we have some places we named them explicitely in package.jdo (but those should fix themselves?)

CREATE INDEX IF NOT EXISTS "MEDIAASSET_PARENTID_idx" ON "MEDIAASSET" ("PARENTID");
CREATE INDEX IF NOT EXISTS "MEDIAASSET_HASHCODE_idx" ON "MEDIAASSET" ("HASHCODE");

CREATE INDEX IF NOT EXISTS "ENCOUNTER_LOCATIONID_idx" ON "ENCOUNTER" ("LOCATIONID");
CREATE INDEX IF NOT EXISTS "ENCOUNTER_STATE_idx" ON "ENCOUNTER" ("STATE");
CREATE INDEX IF NOT EXISTS "ENCOUNTER_INDIVIDUALID_idx" ON "ENCOUNTER" ("INDIVIDUALID");
CREATE INDEX IF NOT EXISTS "ENCOUNTER_DATEINMILLISECONDS_idx" ON "ENCOUNTER" ("DATEINMILLISECONDS");
CREATE INDEX IF NOT EXISTS "ENCOUNTER_DECIMALLATITUDE_idx" ON "ENCOUNTER" ("DECIMALLATITUDE");
CREATE INDEX IF NOT EXISTS "ENCOUNTER_DECIMALLONGITUDE_idx" ON "ENCOUNTER" ("DECIMALLONGITUDE");
CREATE INDEX IF NOT EXISTS "ENCOUNTER_GENUS_idx" ON "ENCOUNTER" ("GENUS");
CREATE INDEX IF NOT EXISTS "ENCOUNTER_SPECIFICEPITHET_idx" ON "ENCOUNTER" ("SPECIFICEPITHET");
CREATE INDEX IF NOT EXISTS "ENCOUNTER_SUBMITTERID_idx" ON "ENCOUNTER" ("SUBMITTERID");

CREATE INDEX IF NOT EXISTS "MARKEDINDIVIDUAL_NICKNAME_idx" ON "MARKEDINDIVIDUAL" ("NICKNAME");

CREATE INDEX IF NOT EXISTS "ANNOTATION_SPECIES_idx" ON "ANNOTATION" ("SPECIES");
CREATE INDEX IF NOT EXISTS "ANNOTATION_ISEXEMPLAR_idx" ON "ANNOTATION" ("ISEXEMPLAR");
CREATE INDEX IF NOT EXISTS "ANNOTATION_MATCHAGAINST_IDX" ON "ANNOTATION" ("MATCHAGAINST");
CREATE INDEX IF NOT EXISTS "ANNOTATION_ACMID_IDX" ON "ANNOTATION" ("ACMID");
CREATE INDEX IF NOT EXISTS "ANNOTATION_IACLASS_idx" ON "ANNOTATION" ("IACLASS");

CREATE INDEX IF NOT EXISTS "IDENTITYSERVICELOG_SERVICEJOBID_idx" ON "IDENTITYSERVICELOG" ("SERVICEJOBID");
CREATE INDEX IF NOT EXISTS "IDENTITYSERVICELOG_SERVICENAME_idx" ON "IDENTITYSERVICELOG" ("SERVICENAME");
CREATE INDEX IF NOT EXISTS "IDENTITYSERVICELOG_TASKID_idx" ON "IDENTITYSERVICELOG" ("TASKID");
CREATE INDEX IF NOT EXISTS "IDENTITYSERVICELOG_TIMESTAMP_idx" ON "IDENTITYSERVICELOG" ("TIMESTAMP");
----  apparently this is bad form.  furthermore it causes grief when we have too many object IDs.
-- CREATE INDEX IF NOT EXISTS "IDENTITYSERVICELOG_OBJECTIDS_idx" ON "IDENTITYSERVICELOG" ("OBJECTIDS");

CREATE INDEX IF NOT EXISTS "ACCESSCONTROL_USERNAME_idx" ON "ACCESSCONTROL" ("USERNAME");

-- this one gets autocreated (in all caps!) so lets do this... sigh?
CREATE INDEX IF NOT EXISTS "TASK_CREATED_IDX" ON "TASK" ("CREATED");

