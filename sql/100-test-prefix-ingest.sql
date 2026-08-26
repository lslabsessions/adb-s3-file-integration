SET SERVEROUTPUT ON;

-- Full batch entry point. Only object names matching the configured literal
-- prefix customer_ and extension .csv are processed; unrelated objects remain.

BEGIN
    pkg_s3_ingest.process_files(
        p_config_code => 'CUSTOMERS'
    );
END;
/
