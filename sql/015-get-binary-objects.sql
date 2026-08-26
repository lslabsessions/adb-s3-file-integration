SET SERVEROUTPUT ON;

DECLARE
    PROCEDURE print_object_info (
        p_object_name IN VARCHAR2
    )
    IS
        l_blob   BLOB;
        l_header RAW(16);
        l_uri    VARCHAR2(4000);
    BEGIN
        l_uri :=
            'https://lslabsessions-adb-s3-lab.s3.eu-central-1.amazonaws.com/inbound/'
            || p_object_name;

        l_blob := DBMS_CLOUD.GET_OBJECT(
            credential_name => 'AWS_S3_CRED',
            object_uri      => l_uri
        );

        -- Inspect the first bytes instead of trusting the filename extension.
        -- PDF starts with 25 50 44 46, which is ASCII "%PDF".
        -- A JPEG normally starts with FF D8 FF; the sample also contains JFIF.
        l_header := DBMS_LOB.SUBSTR(
            lob_loc => l_blob,
            amount  => 16,
            offset  => 1
        );

        DBMS_OUTPUT.PUT_LINE('Object: ' || p_object_name);
        DBMS_OUTPUT.PUT_LINE(
            'BLOB size: ' || DBMS_LOB.GETLENGTH(l_blob) || ' bytes'
        );
        DBMS_OUTPUT.PUT_LINE(
            'First bytes (hex): ' || RAWTOHEX(l_header)
        );
        DBMS_OUTPUT.PUT_LINE('------------------------------');
    END print_object_info;

BEGIN
    print_object_info('sample-document.pdf');
    print_object_info('lume-lab-sessions.jpeg');
END;
/
