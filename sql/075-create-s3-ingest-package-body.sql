create or replace PACKAGE BODY pkg_s3_ingest AS


    FUNCTION get_s3_endpoint (
        p_config_code IN VARCHAR2
    ) RETURN VARCHAR2
    IS
        l_value s3_ingest_config.s3_endpoint%TYPE;
    BEGIN
        SELECT s3_endpoint
          INTO l_value
          FROM s3_ingest_config
         WHERE config_code = p_config_code
           AND enabled_flag = 'Y';

        RETURN l_value;
    END get_s3_endpoint;


    FUNCTION get_bucket_name (
        p_config_code IN VARCHAR2
    ) RETURN VARCHAR2
    IS
        l_value s3_ingest_config.bucket_name%TYPE;
    BEGIN
        SELECT bucket_name
          INTO l_value
          FROM s3_ingest_config
         WHERE config_code = p_config_code
           AND enabled_flag = 'Y';

        RETURN l_value;
    END get_bucket_name;


    FUNCTION get_folder_name (
        p_config_code IN VARCHAR2
    ) RETURN VARCHAR2
    IS
        l_value s3_ingest_config.folder_name%TYPE;
    BEGIN
        SELECT folder_name
          INTO l_value
          FROM s3_ingest_config
         WHERE config_code = p_config_code
           AND enabled_flag = 'Y';

        RETURN l_value;
    END get_folder_name;


    FUNCTION get_credential_name (
        p_config_code IN VARCHAR2
    ) RETURN VARCHAR2
    IS
        l_value s3_ingest_config.credential_name%TYPE;
    BEGIN
        SELECT credential_name
          INTO l_value
          FROM s3_ingest_config
         WHERE config_code = p_config_code
           AND enabled_flag = 'Y';

        RETURN l_value;
    END get_credential_name;


    FUNCTION get_file_prefix (
        p_config_code IN VARCHAR2
    ) RETURN VARCHAR2
    IS
        l_value s3_ingest_config.file_prefix%TYPE;
    BEGIN
        SELECT file_prefix
          INTO l_value
          FROM s3_ingest_config
         WHERE config_code = p_config_code
           AND enabled_flag = 'Y';

        RETURN l_value;
    END get_file_prefix;


    FUNCTION get_file_extension (
        p_config_code IN VARCHAR2
    ) RETURN VARCHAR2
    IS
        l_value s3_ingest_config.file_extension%TYPE;
    BEGIN
        SELECT file_extension
          INTO l_value
          FROM s3_ingest_config
         WHERE config_code = p_config_code
           AND enabled_flag = 'Y';

        RETURN l_value;
    END get_file_extension;


    FUNCTION get_enabled_flag (
        p_config_code IN VARCHAR2
    ) RETURN VARCHAR2
    IS
        l_value s3_ingest_config.enabled_flag%TYPE;
    BEGIN
        SELECT enabled_flag
          INTO l_value
          FROM s3_ingest_config
         WHERE config_code = p_config_code;

        RETURN l_value;
    END get_enabled_flag;


    FUNCTION get_folder_uri (
        p_config_code IN VARCHAR2
    ) RETURN VARCHAR2
    IS
    BEGIN
        RETURN
              'https://'
           || get_bucket_name(p_config_code)
           || '.'
           || get_s3_endpoint(p_config_code)
           || '/'
           || TRIM(BOTH '/' FROM get_folder_name(p_config_code))
           || '/';
    END get_folder_uri;

FUNCTION get_object_uri (
    p_config_code IN VARCHAR2,
    p_object_name IN VARCHAR2
) RETURN VARCHAR2
IS
BEGIN
    RETURN get_folder_uri(p_config_code) || p_object_name;
END get_object_uri;


PROCEDURE list_matching_files (
    p_config_code IN VARCHAR2
)
IS
    l_credential_name VARCHAR2(128);
    l_folder_uri      VARCHAR2(4000);
    l_file_prefix     VARCHAR2(255);
    l_file_extension  VARCHAR2(30);
    l_count           PLS_INTEGER := 0;
BEGIN
    l_credential_name := get_credential_name(p_config_code);
    l_folder_uri      := get_folder_uri(p_config_code);
    l_file_prefix     := get_file_prefix(p_config_code);
    l_file_extension  := get_file_extension(p_config_code);

    DBMS_OUTPUT.PUT_LINE(
        'Configuration : ' || p_config_code
    );

    DBMS_OUTPUT.PUT_LINE(
        'Folder URI    : ' || l_folder_uri
    );

    DBMS_OUTPUT.PUT_LINE(
        'File prefix   : ' || l_file_prefix
    );

    DBMS_OUTPUT.PUT_LINE(
        'File extension: ' || l_file_extension
    );

    DBMS_OUTPUT.PUT_LINE(
        '----------------------------------------'
    );

    FOR r IN (
        SELECT
            object_name,
            bytes,
            checksum,
            last_modified
        FROM DBMS_CLOUD.LIST_OBJECTS(
            credential_name => l_credential_name,
            location_uri    => l_folder_uri
        )
        WHERE
            (
                l_file_prefix IS NULL
                OR SUBSTR(
                       object_name,
                       1,
                       LENGTH(l_file_prefix)
                   ) = l_file_prefix
            )
        AND (
                l_file_extension IS NULL
                OR LOWER(
                       SUBSTR(
                           object_name,
                           -LENGTH(l_file_extension)
                       )
                   ) = LOWER(l_file_extension)
            )
        ORDER BY object_name
    )
    LOOP
        l_count := l_count + 1;

        DBMS_OUTPUT.PUT_LINE(
            'Object #' || l_count || ': ' || r.object_name
        );

        DBMS_OUTPUT.PUT_LINE(
            '  Size         : ' || r.bytes || ' bytes'
        );

        DBMS_OUTPUT.PUT_LINE(
            '  Last modified: ' || r.last_modified
        );

        DBMS_OUTPUT.PUT_LINE(
            '  Checksum     : ' || r.checksum
        );

        DBMS_OUTPUT.PUT_LINE(
            '  Object URI   : '
            || get_object_uri(
                   p_config_code,
                   r.object_name
               )
        );

        DBMS_OUTPUT.PUT_LINE(
            '----------------------------------------'
        );
    END LOOP;

    DBMS_OUTPUT.PUT_LINE(
        'Matching objects: ' || l_count
    );
END list_matching_files;

PROCEDURE process_file (
    p_config_code IN VARCHAR2,
    p_object_name IN VARCHAR2
)
IS
    l_credential_name VARCHAR2(128);
    l_bucket_name     VARCHAR2(255);
    l_folder_name     VARCHAR2(1024);
    l_folder_uri      VARCHAR2(4000);
    l_object_uri      VARCHAR2(4000);
    l_object_key      VARCHAR2(1024);

    l_blob             BLOB;
    l_blob_size        NUMBER;

    l_s3_size          NUMBER;
    l_s3_checksum      VARCHAR2(512);
    l_s3_last_modified TIMESTAMP WITH TIME ZONE;

    l_file_id          s3_file_store.file_id%TYPE;
    l_status           s3_file_store.status%TYPE;

    l_existing_count   PLS_INTEGER;
    l_rows_inserted    PLS_INTEGER;
    
    l_error_msg         VARCHAR2(4000);
BEGIN
    l_credential_name := get_credential_name(p_config_code);
    l_bucket_name     := get_bucket_name(p_config_code);
    l_folder_name     := TRIM(BOTH '/' FROM get_folder_name(p_config_code));
    l_folder_uri      := get_folder_uri(p_config_code);
    l_object_uri      := get_object_uri(p_config_code, p_object_name);
    l_object_key      := l_folder_name || '/' || p_object_name;


    SELECT
        bytes,
        checksum,
        last_modified
    INTO
        l_s3_size,
        l_s3_checksum,
        l_s3_last_modified
    FROM DBMS_CLOUD.LIST_OBJECTS(
        credential_name => l_credential_name,
        location_uri    => l_folder_uri
    )
    WHERE object_name = p_object_name;


    SELECT COUNT(*)
    INTO l_existing_count
    FROM s3_file_store
    WHERE bucket_name = l_bucket_name
      AND object_key = l_object_key
      AND s3_last_modified = l_s3_last_modified
      AND NVL(s3_checksum, '#NULL#')
          = NVL(l_s3_checksum, '#NULL#');


    IF l_existing_count > 0 THEN

        SELECT
            file_id,
            status
        INTO
            l_file_id,
            l_status
        FROM s3_file_store
        WHERE bucket_name = l_bucket_name
          AND object_key = l_object_key
          AND s3_last_modified = l_s3_last_modified
          AND NVL(s3_checksum, '#NULL#')
              = NVL(l_s3_checksum, '#NULL#');

        DBMS_OUTPUT.PUT_LINE(
            'Existing file   : ' || p_object_name
        );

        DBMS_OUTPUT.PUT_LINE(
            'File ID         : ' || l_file_id
        );

        DBMS_OUTPUT.PUT_LINE(
            'Current status  : ' || l_status
        );

        /*
         * Business data already exists.
         * Only retry the S3 deletion if required.
         */
        IF l_status IN ('PROCESSED', 'DELETE_PENDING') THEN
            delete_source_object(l_file_id);
            RETURN;
        END IF;

        IF l_status = 'COMPLETED' THEN
            DBMS_OUTPUT.PUT_LINE(
                'File already completed.'
            );
            RETURN;
        END IF;

    ELSE

        /*
         * Preserve the exact source object before processing it.
         */
        l_blob := DBMS_CLOUD.GET_OBJECT(
            credential_name => l_credential_name,
            object_uri      => l_object_uri
        );

        l_blob_size := DBMS_LOB.GETLENGTH(l_blob);

        IF l_blob_size <> l_s3_size THEN
            RAISE_APPLICATION_ERROR(
                -20001,
                'Size mismatch for ' || p_object_name
                || ': S3=' || l_s3_size
                || ', BLOB=' || l_blob_size
            );
        END IF;

        INSERT INTO s3_file_store (
            config_code,
            bucket_name,
            object_key,
            object_uri,
            file_name,
            content_type,
            file_content,
            file_size,
            s3_checksum,
            s3_last_modified,
            status
        )
        VALUES (
            p_config_code,
            l_bucket_name,
            l_object_key,
            l_object_uri,
            p_object_name,
            'text/csv',
            l_blob,
            l_blob_size,
            l_s3_checksum,
            l_s3_last_modified,
            'RECEIVED'
        )
        RETURNING file_id INTO l_file_id;

        COMMIT;

        DBMS_OUTPUT.PUT_LINE(
            'Original stored : ' || p_object_name
        );

        DBMS_OUTPUT.PUT_LINE(
            'File ID         : ' || l_file_id
        );
    END IF;


    /*
     * The following block covers database processing only.
     * An error here must never cause the source S3 object to
     * be deleted.
     */
    BEGIN
        UPDATE s3_file_store
           SET status        = 'PROCESSING',
               error_message = NULL
         WHERE file_id = l_file_id;

        COMMIT;


        DELETE FROM customer_stage;

        /*
         * COPY_DATA needs the staging table free from
         * uncommitted DML locks.
         */
        COMMIT;


        DBMS_CLOUD.COPY_DATA(
            table_name      => 'CUSTOMER_STAGE',
            credential_name => l_credential_name,
            file_uri_list   => l_object_uri,
            format          => JSON_OBJECT(
                'type'             VALUE 'csv',
                'detectfieldorder' VALUE TRUE
            )
        );


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

        l_rows_inserted := SQL%ROWCOUNT;


        UPDATE s3_file_store
           SET status        = 'PROCESSED',
               processed_at  = SYSTIMESTAMP,
               error_message = NULL
         WHERE file_id = l_file_id;

        COMMIT;


        DBMS_OUTPUT.PUT_LINE(
            'Processed file  : ' || p_object_name
        );

        DBMS_OUTPUT.PUT_LINE(
            'Rows extracted  : ' || l_rows_inserted
        );

        DBMS_OUTPUT.PUT_LINE(
            'Status          : PROCESSED'
        );

    EXCEPTION
        WHEN OTHERS THEN
            ROLLBACK;
            
            l_error_msg := SUBSTR(SQLERRM, 1, 4000);
             
            UPDATE s3_file_store
               SET status        = 'ERROR',
                   error_message = l_error_msg
             WHERE file_id = l_file_id;

            COMMIT;

            RAISE;
    END;


    /*
     * Only after the original BLOB and extracted business
     * data have been committed can the S3 source be removed.
     *
     * DELETE_SOURCE_OBJECT manages COMPLETED / DELETE_PENDING.
     */
    delete_source_object(l_file_id);

END process_file;

PROCEDURE delete_source_object (
    p_file_id IN NUMBER
)
IS
    l_credential_name s3_ingest_config.credential_name%TYPE;
    l_object_uri      s3_file_store.object_uri%TYPE;
    l_file_name       s3_file_store.file_name%TYPE;
    l_status          s3_file_store.status%TYPE;
    l_error_msg         VARCHAR2(4000);
BEGIN
    SELECT
        get_credential_name(f.config_code),
        f.object_uri,
        f.file_name,
        f.status
    INTO
        l_credential_name,
        l_object_uri,
        l_file_name,
        l_status
    FROM s3_file_store f
    WHERE f.file_id = p_file_id;


    IF l_status = 'COMPLETED' THEN
        DBMS_OUTPUT.PUT_LINE(
            'Source already deleted: ' || l_file_name
        );

        RETURN;
    END IF;


    IF l_status NOT IN ('PROCESSED', 'DELETE_PENDING') THEN
        RAISE_APPLICATION_ERROR(
            -20002,
            'File ' || p_file_id ||
            ' cannot be deleted while status is ' || l_status
        );
    END IF;


    BEGIN
        DBMS_CLOUD.DELETE_OBJECT(
            credential_name => l_credential_name,
            object_uri      => l_object_uri
        );

        UPDATE s3_file_store
           SET status            = 'COMPLETED',
               source_deleted_at = SYSTIMESTAMP,
               error_message     = NULL
         WHERE file_id = p_file_id;

        COMMIT;

        DBMS_OUTPUT.PUT_LINE(
            'Deleted from S3 : ' || l_file_name
        );

        DBMS_OUTPUT.PUT_LINE(
            'Status          : COMPLETED'
        );

    EXCEPTION
        WHEN OTHERS THEN
            ROLLBACK;
            l_error_msg := SUBSTR(SQLERRM, 1, 4000);
            UPDATE s3_file_store
               SET status        = 'DELETE_PENDING',
                   error_message = l_error_msg
             WHERE file_id = p_file_id;

            COMMIT;

            DBMS_OUTPUT.PUT_LINE(
                'S3 delete failed: ' || l_file_name
            );

            DBMS_OUTPUT.PUT_LINE(
                'Status           : DELETE_PENDING'
            );

            RAISE;
    END;
END delete_source_object;

PROCEDURE process_files (
    p_config_code IN VARCHAR2
)
IS
    l_credential_name VARCHAR2(128);
    l_folder_uri      VARCHAR2(4000);
    l_file_prefix     VARCHAR2(255);
    l_file_extension  VARCHAR2(30);

    l_found_count      PLS_INTEGER := 0;
    l_success_count    PLS_INTEGER := 0;
    l_error_count      PLS_INTEGER := 0;
BEGIN
    l_credential_name := get_credential_name(p_config_code);
    l_folder_uri      := get_folder_uri(p_config_code);
    l_file_prefix     := get_file_prefix(p_config_code);
    l_file_extension  := get_file_extension(p_config_code);

    DBMS_OUTPUT.PUT_LINE(
        'Processing configuration: ' || p_config_code
    );

    DBMS_OUTPUT.PUT_LINE(
        'Folder URI              : ' || l_folder_uri
    );

    DBMS_OUTPUT.PUT_LINE(
        'File prefix             : ' || l_file_prefix
    );

    DBMS_OUTPUT.PUT_LINE(
        'File extension          : ' || l_file_extension
    );

    DBMS_OUTPUT.PUT_LINE(
        '========================================'
    );


    FOR r IN (
        SELECT object_name
        FROM DBMS_CLOUD.LIST_OBJECTS(
            credential_name => l_credential_name,
            location_uri    => l_folder_uri
        )
        WHERE (
                l_file_prefix IS NULL
                OR SUBSTR(
                       object_name,
                       1,
                       LENGTH(l_file_prefix)
                   ) = l_file_prefix
              )
          AND (
                l_file_extension IS NULL
                OR LOWER(
                       SUBSTR(
                           object_name,
                           -LENGTH(l_file_extension)
                       )
                   ) = LOWER(l_file_extension)
              )
        ORDER BY object_name
    )
    LOOP
        l_found_count := l_found_count + 1;

        DBMS_OUTPUT.PUT_LINE(
            'Processing object #' || l_found_count
            || ': ' || r.object_name
        );

        BEGIN
            process_file(
                p_config_code => p_config_code,
                p_object_name => r.object_name
            );

            l_success_count := l_success_count + 1;

        EXCEPTION
            WHEN OTHERS THEN
                l_error_count := l_error_count + 1;

                DBMS_OUTPUT.PUT_LINE(
                    'ERROR processing '
                    || r.object_name
                    || ': '
                    || SQLERRM
                );
        END;

        DBMS_OUTPUT.PUT_LINE(
            '----------------------------------------'
        );
    END LOOP;


    DBMS_OUTPUT.PUT_LINE(
        'Matching objects : ' || l_found_count
    );

    DBMS_OUTPUT.PUT_LINE(
        'Successful       : ' || l_success_count
    );

    DBMS_OUTPUT.PUT_LINE(
        'Errors           : ' || l_error_count
    );
END process_files;

END pkg_s3_ingest;
/