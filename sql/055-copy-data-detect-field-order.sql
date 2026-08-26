TRUNCATE TABLE customer_stage;

BEGIN
    -- The sample header is deliberately reordered:
    -- country,customer_id,name
    -- detectfieldorder maps these fields to CUSTOMER_STAGE by column name,
    -- not by their physical position in the file.
    DBMS_CLOUD.COPY_DATA(
        table_name      => 'CUSTOMER_STAGE',
        credential_name => 'AWS_S3_CRED',
        file_uri_list   =>
            'https://lslabsessions-adb-s3-lab.s3.eu-central-1.amazonaws.com/inbound/customers-reordered.csv',
        format          => JSON_OBJECT(
            'type'             VALUE 'csv',
            'detectfieldorder' VALUE TRUE
        )
    );
END;
/

SELECT
    customer_id,
    name,
    country
FROM customer_stage
ORDER BY customer_id;
