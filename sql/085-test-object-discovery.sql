SET SERVEROUTPUT ON;

BEGIN
    pkg_s3_ingest.list_matching_files(
        p_config_code => 'CUSTOMERS'
    );
END;
/

-- LIST_OBJECTS can also filter directly in LOCATION_URI with * and ? wildcards.
-- Note that '_' is literal here (unlike SQL LIKE), so customer_*.csv is safe.
SELECT object_name,
       bytes,
       checksum,
       last_modified
FROM DBMS_CLOUD.LIST_OBJECTS(
    credential_name => 'AWS_S3_CRED',
    location_uri    =>
        'https://lslabsessions-adb-s3-lab.s3.eu-central-1.amazonaws.com/inbound/customer_*.csv'
)
ORDER BY object_name;
