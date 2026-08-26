CREATE TABLE s3_file_text (
    file_id         NUMBER CONSTRAINT s3_file_text_pk PRIMARY KEY,
    character_set   VARCHAR2(30) NOT NULL,
    text_content    CLOB NOT NULL,
    processed_at    TIMESTAMP WITH TIME ZONE DEFAULT SYSTIMESTAMP NOT NULL,

    CONSTRAINT s3_file_text_file_fk
        FOREIGN KEY (file_id)
        REFERENCES s3_file_store(file_id)
);

SET SERVEROUTPUT ON;

DECLARE
    l_file_id       s3_file_store.file_id%TYPE;
    l_blob          BLOB;
    l_clob          CLOB;
    l_dest_offset   PLS_INTEGER := 1;
    l_src_offset    PLS_INTEGER := 1;
    l_lang_context  PLS_INTEGER := DBMS_LOB.DEFAULT_LANG_CTX;
    l_warning       PLS_INTEGER;
BEGIN
    SELECT file_id,
           file_content
      INTO l_file_id,
           l_blob
      FROM s3_file_store
     WHERE file_name = 'message.txt';

    DBMS_LOB.CREATETEMPORARY(
        lob_loc => l_clob,
        cache   => TRUE
    );

    -- Preserve the BLOB in S3_FILE_STORE and create a separate textual
    -- representation derived by explicitly decoding UTF-8 bytes.
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

    INSERT INTO s3_file_text (
        file_id,
        character_set,
        text_content
    ) VALUES (
        l_file_id,
        'AL32UTF8',
        l_clob
    );

    UPDATE s3_file_store
       SET status       = 'PROCESSED',
           processed_at = SYSTIMESTAMP
     WHERE file_id = l_file_id;

    COMMIT;

    DBMS_OUTPUT.PUT_LINE('File ID            : ' || l_file_id);
    DBMS_OUTPUT.PUT_LINE('Original BLOB size : ' || DBMS_LOB.GETLENGTH(l_blob) || ' bytes');
    DBMS_OUTPUT.PUT_LINE('CLOB length        : ' || DBMS_LOB.GETLENGTH(l_clob) || ' characters');
    DBMS_OUTPUT.PUT_LINE('Character set      : AL32UTF8');
    DBMS_OUTPUT.PUT_LINE('Conversion warning : ' || l_warning);
    DBMS_OUTPUT.PUT_LINE('--- Extracted text ---');
    DBMS_OUTPUT.PUT_LINE(DBMS_LOB.SUBSTR(l_clob, 32767, 1));

    DBMS_LOB.FREETEMPORARY(l_clob);
END;
/
