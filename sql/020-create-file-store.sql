-- Store every source file as its original byte stream first.
-- Even text files are persisted as BLOBs here so that processing never replaces the exact object received from S3.

CREATE TABLE s3_file_store (
    file_id           NUMBER GENERATED ALWAYS AS IDENTITY
                      CONSTRAINT s3_file_store_pk PRIMARY KEY,

    bucket_name       VARCHAR2(255)  NOT NULL,
    object_key        VARCHAR2(1024) NOT NULL,
    object_uri        VARCHAR2(4000) NOT NULL,

    file_name         VARCHAR2(255)  NOT NULL,
    content_type      VARCHAR2(100),

    file_content      BLOB           NOT NULL,
    file_size         NUMBER         NOT NULL,
    s3_checksum       VARCHAR2(512),

    status            VARCHAR2(30) DEFAULT 'RECEIVED' NOT NULL,
    received_at       TIMESTAMP WITH TIME ZONE DEFAULT SYSTIMESTAMP NOT NULL,
    processed_at      TIMESTAMP WITH TIME ZONE,
    source_deleted_at TIMESTAMP WITH TIME ZONE,
    error_message     VARCHAR2(4000),

    CONSTRAINT s3_file_store_status_ck
        CHECK (
            status IN (
                'RECEIVED',
                'PROCESSING',
                'PROCESSED',
                'DELETE_PENDING',
                'COMPLETED',
                'ERROR'
            )
        )
);

-- This simple constraint is sufficient for the introductory storage exercise.
-- It is deliberately replaced in 065-prepare-file-store-for-ingest.sql because a production-style feed may legitimately deliver a new object using the same key.
ALTER TABLE s3_file_store
ADD CONSTRAINT s3_file_store_object_uk
UNIQUE (bucket_name, object_key);
