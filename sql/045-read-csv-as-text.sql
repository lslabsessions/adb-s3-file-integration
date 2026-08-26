SET SERVEROUTPUT ON;

DECLARE
    l_blob          BLOB;
    l_clob          CLOB;
    l_dest_offset   PLS_INTEGER := 1;
    l_src_offset    PLS_INTEGER := 1;
    l_lang_context  PLS_INTEGER := DBMS_LOB.DEFAULT_LANG_CTX;
    l_warning       PLS_INTEGER;
BEGIN
    SELECT file_content
      INTO l_blob
      FROM s3_file_store
     WHERE file_name = 'customers.csv';

    DBMS_LOB.CREATETEMPORARY(l_clob, TRUE);

    -- This is the file-processing path: retrieve/preserve bytes, then decode
    -- the stored object as text. COPY_DATA, shown next, is a different use case.
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

    DBMS_OUTPUT.PUT_LINE('Original BLOB size : ' || DBMS_LOB.GETLENGTH(l_blob) || ' bytes');
    DBMS_OUTPUT.PUT_LINE('CLOB length        : ' || DBMS_LOB.GETLENGTH(l_clob) || ' characters');
    DBMS_OUTPUT.PUT_LINE('Conversion warning : ' || l_warning);
    DBMS_OUTPUT.PUT_LINE('--- CSV content ---');
    DBMS_OUTPUT.PUT_LINE(DBMS_LOB.SUBSTR(l_clob, 32767, 1));

    DBMS_LOB.FREETEMPORARY(l_clob);
END;
/
