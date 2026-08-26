SELECT
    pkg_s3_ingest.get_s3_endpoint('CUSTOMERS')     AS s3_endpoint,
    pkg_s3_ingest.get_bucket_name('CUSTOMERS')     AS bucket_name,
    pkg_s3_ingest.get_folder_name('CUSTOMERS')     AS folder_name,
    pkg_s3_ingest.get_credential_name('CUSTOMERS') AS credential_name,
    pkg_s3_ingest.get_file_prefix('CUSTOMERS')     AS file_prefix,
    pkg_s3_ingest.get_file_extension('CUSTOMERS')  AS file_extension,
    pkg_s3_ingest.get_enabled_flag('CUSTOMERS')    AS enabled_flag,
    pkg_s3_ingest.get_folder_uri('CUSTOMERS')      AS folder_uri
FROM dual;
