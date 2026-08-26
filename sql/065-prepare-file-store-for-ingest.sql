ALTER TABLE s3_file_store
ADD (
    config_code       VARCHAR2(30),
    s3_last_modified  TIMESTAMP WITH TIME ZONE
);

/*
 OBJECT_KEY alone cannot be unique in a recurring feed: the same key may be
 overwritten/re-delivered later with a new LAST_MODIFIED and/or CHECKSUM.
*/
ALTER TABLE s3_file_store
DROP CONSTRAINT s3_file_store_object_uk;

ALTER TABLE s3_file_store
ADD CONSTRAINT s3_file_store_config_fk
FOREIGN KEY (config_code)
REFERENCES s3_ingest_config(config_code);

/*
 Lab definition of the same observed S3 object occurrence:
 BUCKET + OBJECT_KEY + LAST_MODIFIED + CHECKSUM.
 This is processing idempotency, not global content deduplication: equal
 checksums on different keys or later deliveries are allowed.
*/

CREATE UNIQUE INDEX s3_file_store_occurrence_uk
ON s3_file_store (
    bucket_name,
    object_key,
    s3_last_modified,
    NVL(s3_checksum, '#NULL#')
);
