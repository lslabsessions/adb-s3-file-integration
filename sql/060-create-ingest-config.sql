/*
 One row describes one inbound feed/process. 
 The package reads each property through an individual getter so endpoint, bucket, folder, credential, prefix, and extension are not hardcoded in the ingestion logic.
 */

CREATE TABLE s3_ingest_config (
    config_code       VARCHAR2(30)
                      CONSTRAINT s3_ingest_config_pk PRIMARY KEY,
    s3_endpoint       VARCHAR2(255)  NOT NULL,
    bucket_name       VARCHAR2(255)  NOT NULL,
    folder_name       VARCHAR2(1024) NOT NULL,
    credential_name   VARCHAR2(128)  NOT NULL,
    file_prefix       VARCHAR2(255),
    file_extension    VARCHAR2(30),
    enabled_flag      CHAR(1) DEFAULT 'Y' NOT NULL,
    created_at        TIMESTAMP WITH TIME ZONE DEFAULT SYSTIMESTAMP NOT NULL,

    CONSTRAINT s3_ingest_config_enabled_ck
        CHECK (enabled_flag IN ('Y', 'N'))
);

INSERT INTO s3_ingest_config (
    config_code,
    s3_endpoint,
    bucket_name,
    folder_name,
    credential_name,
    file_prefix,
    file_extension,
    enabled_flag
) VALUES (
    'CUSTOMERS',
    's3.eu-central-1.amazonaws.com',
    'lslabsessions-adb-s3-lab',
    'inbound',
    'AWS_S3_CRED',
    'customer_',
    '.csv',
    'Y'
);

COMMIT;
