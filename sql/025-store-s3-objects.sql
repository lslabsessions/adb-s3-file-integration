SET SERVEROUTPUT ON;

DECLARE
    c_bucket_name CONSTANT VARCHAR2(255) :=
        'lslabsessions-adb-s3-lab';

    c_folder CONSTANT VARCHAR2(255) :=
        'inbound/';

    c_base_uri CONSTANT VARCHAR2(4000) :=
        'https://lslabsessions-adb-s3-lab.s3.eu-central-1.amazonaws.com/inbound/';

    c_credential CONSTANT VARCHAR2(128) :=
        'AWS_S3_CRED';

    FUNCTION get_content_type (
        p_file_name IN VARCHAR2
    ) RETURN VARCHAR2
    IS
        l_file_name VARCHAR2(1024) := LOWER(p_file_name);
    BEGIN
        IF l_file_name LIKE '%.txt' THEN
            RETURN 'text/plain';
        ELSIF l_file_name LIKE '%.csv' THEN
            RETURN 'text/csv';
        ELSIF l_file_name LIKE '%.pdf' THEN
            RETURN 'application/pdf';
        ELSIF l_file_name LIKE '%.jpg'
           OR l_file_name LIKE '%.jpeg' THEN
            RETURN 'image/jpeg';
        ELSE
            RETURN 'application/octet-stream';
        END IF;
    END get_content_type;

    FUNCTION file_already_stored (
        p_bucket_name IN VARCHAR2,
        p_object_key  IN VARCHAR2
    ) RETURN BOOLEAN
    IS
        l_count PLS_INTEGER;
    BEGIN
        SELECT COUNT(*)
          INTO l_count
          FROM s3_file_store
         WHERE bucket_name = p_bucket_name
           AND object_key  = p_object_key;

        RETURN l_count > 0;
    END file_already_stored;

BEGIN
    FOR r IN (
        SELECT
            object_name,
            bytes,
            checksum,
            last_modified
        FROM DBMS_CLOUD.LIST_OBJECTS(
            credential_name => c_credential,
            location_uri    => c_base_uri
        )
        ORDER BY object_name
    )
    LOOP
        DECLARE
            l_blob         BLOB;
            l_object_key   VARCHAR2(1024);
            l_object_uri   VARCHAR2(4000);
            l_blob_size    NUMBER;
            l_content_type VARCHAR2(100);
        BEGIN
            -- S3 object keys include their prefix. For example:
            -- inbound/sample-document.pdf
            l_object_key := c_folder || r.object_name;
            l_object_uri := c_base_uri || r.object_name;
            l_content_type := get_content_type(r.object_name);

            IF file_already_stored(
                   p_bucket_name => c_bucket_name,
                   p_object_key  => l_object_key
               )
            THEN
                DBMS_OUTPUT.PUT_LINE(
                    'Skipping already stored object: ' || l_object_key
                );
            ELSE
                l_blob := DBMS_CLOUD.GET_OBJECT(
                    credential_name => c_credential,
                    object_uri      => l_object_uri
                );

                l_blob_size := DBMS_LOB.GETLENGTH(l_blob);

                INSERT INTO s3_file_store (
                    bucket_name,
                    object_key,
                    object_uri,
                    file_name,
                    content_type,
                    file_content,
                    file_size,
                    s3_checksum,
                    status
                )
                VALUES (
                    c_bucket_name,
                    l_object_key,
                    l_object_uri,
                    r.object_name,
                    l_content_type,
                    l_blob,
                    l_blob_size,
                    r.checksum,
                    'RECEIVED'
                );

                DBMS_OUTPUT.PUT_LINE('Stored: ' || r.object_name);
                DBMS_OUTPUT.PUT_LINE('  Content type: ' || l_content_type);
                DBMS_OUTPUT.PUT_LINE('  S3 size     : ' || r.bytes || ' bytes');
                DBMS_OUTPUT.PUT_LINE('  BLOB size   : ' || l_blob_size || ' bytes');
                DBMS_OUTPUT.PUT_LINE('  Checksum    : ' || r.checksum);
                DBMS_OUTPUT.PUT_LINE('------------------------------');
            END IF;
        END;
    END LOOP;

    COMMIT;
END;
/

SELECT
    file_id,
    file_name,
    content_type,
    file_size,
    DBMS_LOB.GETLENGTH(file_content) AS blob_size,
    s3_checksum,
    status
FROM s3_file_store
ORDER BY file_id;
