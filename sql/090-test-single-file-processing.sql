SET SERVEROUTPUT ON;

/*
 Test the final single-object flow. In the final package, PROCESS_FILE
 preserves the original BLOB, loads the CSV business rows, commits them,
 and then calls DELETE_SOURCE_OBJECT. A successful run ends at COMPLETED.
*/
 
BEGIN
    pkg_s3_ingest.process_file(
        p_config_code => 'CUSTOMERS',
        p_object_name => 'customer_20260823_001.csv'
    );
END;
/

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
  AND f.file_name = 'customer_20260823_001.csv'
ORDER BY d.customer_id;
