SET SERVEROUTPUT ON;

DECLARE
    l_blob         BLOB;
    l_clob         CLOB;
    l_dest_offset  PLS_INTEGER := 1;
    l_src_offset   PLS_INTEGER := 1;
    l_lang_context PLS_INTEGER := DBMS_LOB.DEFAULT_LANG_CTX;
    l_warning      PLS_INTEGER;
BEGIN
    -- GET_OBJECT retrieves the original object bytes as a BLOB.
    l_blob := DBMS_CLOUD.GET_OBJECT(
        credential_name => 'AWS_S3_CRED',
        object_uri      =>
            'https://lslabsessions-adb-s3-lab.s3.eu-central-1.amazonaws.com/inbound/message.txt'
    );

    DBMS_OUTPUT.PUT_LINE(
        'BLOB size: ' || DBMS_LOB.GETLENGTH(l_blob) || ' bytes'
    );

    DBMS_LOB.CREATETEMPORARY(
        lob_loc => l_clob,
        cache   => TRUE
    );

    -- The sample file is explicitly UTF-8, so decode its bytes as AL32UTF8.
    -- BLOB length is measured in bytes; CLOB length is measured in characters.
    DBMS_LOB.CONVERTTOCLOB(
        dest_lob     => l_clob,
        src_blob     => l_blob,
        amount       => DBMS_LOB.LOBMAXSIZE,
        dest_offset  => l_dest_offset,
        src_offset   => l_src_offset,
        blob_csid    => NLS_CHARSET_ID('AL32UTF8'),
        lang_context => l_lang_context,
        warning      => l_warning
    );

    DBMS_OUTPUT.PUT_LINE('--- File content ---');
    DBMS_OUTPUT.PUT_LINE(DBMS_LOB.SUBSTR(l_clob, 32767, 1));
    DBMS_OUTPUT.PUT_LINE('--------------------');
    DBMS_OUTPUT.PUT_LINE('CLOB length: ' || DBMS_LOB.GETLENGTH(l_clob) || ' characters');
    DBMS_OUTPUT.PUT_LINE('Conversion warning: ' || l_warning);

    DBMS_LOB.FREETEMPORARY(l_clob);
END;
/
