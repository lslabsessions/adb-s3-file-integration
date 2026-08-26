SET SERVEROUTPUT ON;

/*
 PROCESS_FILE already deletes the source after successful processing in the
 final package. Calling DELETE_SOURCE_OBJECT again demonstrates that deletion
 is safe to retry for a file already marked COMPLETED.
*/

DECLARE
    l_file_id s3_file_store.file_id%TYPE;
BEGIN
    SELECT MAX(file_id)
      INTO l_file_id
      FROM s3_file_store
     WHERE config_code = 'CUSTOMERS'
       AND file_name = 'customer_20260823_001.csv';

    pkg_s3_ingest.delete_source_object(
        p_file_id => l_file_id
    );
END;
/

SELECT
    file_id,
    file_name,
    file_size,
    DBMS_LOB.GETLENGTH(file_content) AS blob_size,
    status,
    processed_at,
    source_deleted_at
FROM s3_file_store
WHERE config_code = 'CUSTOMERS'
  AND file_name = 'customer_20260823_001.csv'
ORDER BY file_id DESC;
