SET SERVEROUTPUT ON;

DECLARE
    c_credential CONSTANT VARCHAR2(128) := 'AWS_S3_CRED';
    c_outbound_uri CONSTANT VARCHAR2(4000) :=
        'https://lslabsessions-adb-s3-lab.s3.eu-central-1.amazonaws.com/outbound/';

    PROCEDURE roundtrip_binary (
        p_source_file IN VARCHAR2,
        p_target_file IN VARCHAR2
    )
    IS
        l_original_blob   BLOB;
        l_returned_blob   BLOB;
        l_compare_result  INTEGER;
        l_original_header RAW(16);
        l_returned_header RAW(16);
    BEGIN
        SELECT file_content
          INTO l_original_blob
          FROM s3_file_store
         WHERE file_name = p_source_file;

        DBMS_CLOUD.PUT_OBJECT(
            credential_name => c_credential,
            object_uri      => c_outbound_uri || p_target_file,
            contents        => l_original_blob
        );

        l_returned_blob := DBMS_CLOUD.GET_OBJECT(
            credential_name => c_credential,
            object_uri      => c_outbound_uri || p_target_file
        );

        -- A size check is useful, but DBMS_LOB.COMPARE = 0 is the stronger
        -- byte-for-byte integrity check used by this round-trip exercise.
        l_compare_result := DBMS_LOB.COMPARE(
            lob_1 => l_original_blob,
            lob_2 => l_returned_blob
        );

        l_original_header := DBMS_LOB.SUBSTR(l_original_blob, 16, 1);
        l_returned_header := DBMS_LOB.SUBSTR(l_returned_blob, 16, 1);

        DBMS_OUTPUT.PUT_LINE('Source object : ' || p_source_file);
        DBMS_OUTPUT.PUT_LINE('Target object : ' || p_target_file);
        DBMS_OUTPUT.PUT_LINE('Original size : ' || DBMS_LOB.GETLENGTH(l_original_blob) || ' bytes');
        DBMS_OUTPUT.PUT_LINE('Returned size : ' || DBMS_LOB.GETLENGTH(l_returned_blob) || ' bytes');
        DBMS_OUTPUT.PUT_LINE('Original head : ' || RAWTOHEX(l_original_header));
        DBMS_OUTPUT.PUT_LINE('Returned head : ' || RAWTOHEX(l_returned_header));
        DBMS_OUTPUT.PUT_LINE('DBMS_LOB.COMPARE: ' || l_compare_result);

        IF l_compare_result = 0 THEN
            DBMS_OUTPUT.PUT_LINE('Result       : IDENTICAL');
        ELSE
            DBMS_OUTPUT.PUT_LINE('Result       : DIFFERENT');
        END IF;

        DBMS_OUTPUT.PUT_LINE('--------------------------------');
    END roundtrip_binary;

BEGIN
    roundtrip_binary(
        p_source_file => 'sample-document.pdf',
        p_target_file => 'sample-document-copy.pdf'
    );

    roundtrip_binary(
        p_source_file => 'lume-lab-sessions.jpeg',
        p_target_file => 'lume-lab-sessions-copy.jpeg'
    );
END;
/
