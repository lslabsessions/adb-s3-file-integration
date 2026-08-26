-- LIST_OBJECTS returns object metadata from the configured S3 folder URI.
-- For Amazon S3, CREATED is expected to be NULL while LAST_MODIFIED is populated.
-- CHECKSUM is the value returned by DBMS_CLOUD for the object contents.

SELECT
    object_name,
    bytes,
    checksum,
    created,
    last_modified
FROM DBMS_CLOUD.LIST_OBJECTS(
    credential_name => 'AWS_S3_CRED',
    location_uri    =>
        'https://lslabsessions-adb-s3-lab.s3.eu-central-1.amazonaws.com/inbound/'
)
ORDER BY object_name;
