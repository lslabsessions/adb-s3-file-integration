CREATE TABLE customer_stage (
    customer_id NUMBER,
    name        VARCHAR2(100),
    country     VARCHAR2(100)
);

CREATE TABLE customer_data (
    customer_data_id NUMBER GENERATED ALWAYS AS IDENTITY
                     CONSTRAINT customer_data_pk PRIMARY KEY,
    file_id          NUMBER NOT NULL,
    customer_id      NUMBER NOT NULL,
    name             VARCHAR2(100),
    country          VARCHAR2(100),
    created_at       TIMESTAMP WITH TIME ZONE DEFAULT SYSTIMESTAMP NOT NULL,

    CONSTRAINT customer_data_file_fk
        FOREIGN KEY (file_id)
        REFERENCES s3_file_store(file_id),

    CONSTRAINT customer_data_file_customer_uk
        UNIQUE (file_id, customer_id)
);

TRUNCATE TABLE customer_stage;

BEGIN
    -- COPY_DATA loads structured rows from the S3 object directly into the
    -- target table; it does not persist the original file in the database.
    -- detectfieldorder uses the first CSV record as field names and maps by name.
    DBMS_CLOUD.COPY_DATA(
        table_name      => 'CUSTOMER_STAGE',
        credential_name => 'AWS_S3_CRED',
        file_uri_list   =>
            'https://lslabsessions-adb-s3-lab.s3.eu-central-1.amazonaws.com/inbound/customers.csv',
        format          => JSON_OBJECT(
            'type'             VALUE 'csv',
            'detectfieldorder' VALUE TRUE
        )
    );
END;
/

DECLARE
    l_file_id s3_file_store.file_id%TYPE;
BEGIN
    SELECT file_id
      INTO l_file_id
      FROM s3_file_store
     WHERE file_name = 'customers.csv';

    DELETE FROM customer_data
     WHERE file_id = l_file_id;

    INSERT INTO customer_data (
        file_id,
        customer_id,
        name,
        country
    )
    SELECT
        l_file_id,
        customer_id,
        name,
        country
    FROM customer_stage;

    UPDATE s3_file_store
       SET status       = 'PROCESSED',
           processed_at = SYSTIMESTAMP
     WHERE file_id = l_file_id;

    COMMIT;
END;
/

SELECT
    f.file_id,
    f.file_name,
    f.file_size,
    DBMS_LOB.GETLENGTH(f.file_content) AS original_blob_bytes,
    f.status,
    d.customer_id,
    d.name,
    d.country
FROM s3_file_store f
JOIN customer_data d
  ON d.file_id = f.file_id
WHERE f.file_name = 'customers.csv'
ORDER BY d.customer_id;
