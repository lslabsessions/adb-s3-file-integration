SELECT
    f.file_id,
    f.file_name,
    f.file_size,
    DBMS_LOB.GETLENGTH(f.file_content) AS blob_size,
    f.status,
    f.processed_at,
    f.source_deleted_at,
    d.customer_id,
    d.name,
    d.country
FROM s3_file_store f
JOIN customer_data d
  ON d.file_id = f.file_id
WHERE f.config_code = 'CUSTOMERS'
ORDER BY
    f.file_id,
    d.customer_id;

-- After the end-to-end run, no matching customer_*.csv source should remain.
SELECT
    object_name,
    bytes,
    checksum,
    created,
    last_modified
FROM DBMS_CLOUD.LIST_OBJECTS(
    credential_name => 'AWS_S3_CRED',
    location_uri    =>
        'https://lslabsessions-adb-s3-lab.s3.eu-central-1.amazonaws.com/inbound/customer_*.csv'
)
ORDER BY object_name;

-- Other source objects remain untouched because they do not match the feed.
SELECT
    object_name,
    bytes,
    checksum,
    last_modified
FROM DBMS_CLOUD.LIST_OBJECTS(
    credential_name => 'AWS_S3_CRED',
    location_uri    =>
        'https://lslabsessions-adb-s3-lab.s3.eu-central-1.amazonaws.com/inbound/'
)
ORDER BY object_name;
